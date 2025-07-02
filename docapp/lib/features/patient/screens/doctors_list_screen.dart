import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/doctor.dart';
import '../../../shared/models/review.dart';
import '../../../shared/models/specialization.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import 'book_appointment_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  List<Doctor> _doctors = [];
  List<Doctor> _allDoctors = [];
  List<Specialization> _specializations = [];
  Map<int, DoctorRatingStats> _doctorRatings = {}; // Cache for ratings
  bool _isLoading = true;
  bool _isFilterLoading = false;
  String? _error;
  int? _selectedSpecializationId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both doctors and specializations
      final futures = await Future.wait([
        ApiService.getDoctors(),
        ApiService.getSpecializations(),
      ]);

      final doctorsResponse = futures[0];
      final specializationsResponse = futures[1];

      if (doctorsResponse['success'] && specializationsResponse['success']) {
        final doctorsData = doctorsResponse['data'] as List;
        final specializationsData = specializationsResponse['data'] as List;

        setState(() {
          _allDoctors =
              doctorsData.map((json) => Doctor.fromListJson(json)).toList();
          _doctors = List.from(_allDoctors);

          _specializations = specializationsData
              .map((json) => Specialization.fromJson(json))
              .toList();
        });

        // Load ratings for all doctors
        await _loadDoctorRatings();
      } else {
        setState(() {
          _error = 'Failed to load data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please check your internet.';
      });
      print('Load initial data error: $e'); // Debug log
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDoctorRatings() async {
    // Load ratings for all doctors in parallel, but limit concurrent requests
    final ratingsMap = <int, DoctorRatingStats>{};

    for (int i = 0; i < _doctors.length; i += 3) {
      final batch = _doctors.skip(i).take(3);
      final futures = batch.map((doctor) => _loadSingleDoctorRating(doctor.id));

      try {
        final results = await Future.wait(futures);
        for (int j = 0; j < results.length; j++) {
          final doctorId = batch.elementAt(j).id;
          if (results[j] != null) {
            ratingsMap[doctorId] = results[j]!;
          }
        }
      } catch (e) {
        print('Error loading batch ratings: $e');
      }
    }

    if (mounted) {
      setState(() {
        _doctorRatings = ratingsMap;
      });
    }
  }

  Future<DoctorRatingStats?> _loadSingleDoctorRating(int doctorId) async {
    try {
      final response = await ApiService.getDoctorRatingStats(doctorId);
      if (response['success']) {
        return DoctorRatingStats.fromJson(response['data']);
      }
    } catch (e) {
      print('Error loading rating for doctor $doctorId: $e');
    }
    return null;
  }

  Future<void> _filterDoctors() async {
    setState(() {
      _isFilterLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getDoctors(
        specializationId: _selectedSpecializationId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (response['success']) {
        // Handle both empty and populated results successfully
        final data = response['data'] as List;
        final filteredDoctors =
            data.map((json) => Doctor.fromListJson(json)).toList();

        setState(() {
          _doctors = filteredDoctors;
        });

        // Load ratings for filtered doctors
        if (filteredDoctors.isNotEmpty) {
          await _loadDoctorRatings();
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to filter doctors';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again.';
      });
      print('Filter doctors error: $e'); // Debug log
    } finally {
      setState(() {
        _isFilterLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecializationId = null;
      _searchQuery = '';
      _searchController.clear();
      _doctors = List.from(_allDoctors);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search doctors by name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _filterDoctors();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchQuery == value) {
                        _filterDoctors();
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Specialization Filter & Clear Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedSpecializationId,
                            hint: Row(
                              children: [
                                Icon(Icons.medical_services,
                                    color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                const Text('All Specializations'),
                              ],
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(Icons.all_inclusive,
                                        color: Colors.grey.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('All Specializations'),
                                  ],
                                ),
                              ),
                              ..._specializations.map((specialization) {
                                return DropdownMenuItem<int?>(
                                  value: specialization.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                          _getSpecializationIcon(
                                              specialization.name),
                                          color: Colors.blue.shade600,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text(specialization.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSpecializationId = value;
                              });
                              _filterDoctors();
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Clear Filters Button
                    if (_selectedSpecializationId != null ||
                        _searchQuery.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: IconButton(
                          onPressed: _clearFilters,
                          icon:
                              Icon(Icons.clear_all, color: Colors.red.shade600),
                          tooltip: 'Clear filters',
                        ),
                      ),
                  ],
                ),

                // Active Filters Display
                if (_selectedSpecializationId != null ||
                    _searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.filter_list,
                          size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Active filters:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedSpecializationId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _specializations
                                .firstWhere(
                                    (s) => s.id == _selectedSpecializationId)
                                .name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Search: "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Loading indicator for filtering
          if (_isFilterLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtering doctors...',
                    style: TextStyle(color: Colors.blue.shade600),
                  ),
                ],
              ),
            ),

          // Doctors List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error,
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInitialData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _doctors.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedSpecializationId != null ||
                                          _searchQuery.isNotEmpty
                                      ? 'No doctors found'
                                      : 'No doctors available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedSpecializationId != null ||
                                          _searchQuery.isNotEmpty
                                      ? 'Try adjusting your filters or search'
                                      : 'Check back later for available doctors',
                                  style: TextStyle(color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                                if (_selectedSpecializationId != null ||
                                    _searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Clear Filters'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadInitialData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _doctors.length,
                              itemBuilder: (context, index) {
                                final doctor = _doctors[index];
                                final rating = _doctorRatings[doctor.id];
                                return _buildDoctorCard(doctor, rating);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor, DoctorRatingStats? ratingStats) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.blue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(
                doctor: doctor,
                existingRatingStats: ratingStats, // Pass the cached rating data
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CompactProfileAvatar(
                    imageUrl: doctor.user?.profilePhotoUrl,
                    initials: doctor.user?.initials ??
                        doctor.name
                            .split(' ')
                            .map((n) => n[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                    size: 70,
                    backgroundColor: Colors.blue.shade100,
                    textColor: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Name with Rating in same row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doctor.name.isNotEmpty
                                    ? doctor.name
                                    : 'Unknown Doctor',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Compact Rating Display
                            if (ratingStats != null &&
                                ratingStats.totalReviews > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 15,
                                      color: Colors.amber.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      ratingStats.averageRating
                                          .toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'New',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSpecializationIcon(
                                    doctor.specializationName),
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  doctor.specializationName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Availability Status
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Available Today',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Info
              if (doctor.phone != null && doctor.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      doctor.phone!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              if (doctor.address != null && doctor.address!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctor.address!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 8),

              // Action Buttons
              Row(
                children: [
                  // View Profile Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DoctorProfileScreen(
                              doctor: doctor,
                              existingRatingStats:
                                  ratingStats, // Pass cached rating
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Book Appointment Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BookAppointmentScreen(
                              doctor: doctor,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.blue.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSpecializationIcon(String specialization) {
    switch (specialization.toLowerCase().trim()) {
      case 'cardiology':
        return Icons.favorite;
      case 'neurology':
        return Icons.psychology;
      case 'orthopedics':
        return Icons.healing;
      case 'pediatrics':
        return Icons.child_care;
      case 'dermatology':
        return Icons.face;
      case 'ophthalmology':
      case 'eye care':
      case 'eye':
        return Icons.visibility;
      case 'ent':
      case 'nose':
      case 'ear':
        return Icons.hearing;
      case 'general':
      case 'general medicine':
        return Icons.local_hospital;
      case 'gynecology':
        return Icons.woman;
      case 'psychiatry':
        return Icons.psychology_alt;
      case 'radiology':
        return Icons.medical_information;
      case 'anesthesiology':
        return Icons.medication;
      default:
        return Icons.medical_services;
    }
  }
}
