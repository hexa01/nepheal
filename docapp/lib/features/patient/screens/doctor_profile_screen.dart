import 'package:flutter/material.dart';
import '../../../shared/models/doctor.dart';
import '../../../shared/models/user.dart';
import '../../../shared/models/specialization.dart';
import '../../../shared/models/review.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/rating_widget.dart';
import '../../../shared/widgets/review_card_widget.dart';
import 'book_appointment_screen.dart';
import 'doctor_reviews_screen.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  final DoctorRatingStats? existingRatingStats; // Accept cached rating data

  const DoctorProfileScreen({
    super.key,
    required this.doctor,
    this.existingRatingStats, // Optional cached rating
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Doctor? _detailedDoctor;
  DoctorRatingStats? _ratingStats;
  List<Review> _recentReviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Show existing rating immediately if available
    if (widget.existingRatingStats != null) {
      _ratingStats = widget.existingRatingStats;
    }
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      _isLoading = true;
      _isLoadingReviews = true;
      _error = null;
    });

    try {
      // Create futures list - only load rating if not already provided
      List<Future> futures = [
        ApiService.getDoctorById(widget.doctor.id),
        ApiService.getDoctorReviews(
            doctorId: widget.doctor.id, page: 1, perPage: 3),
      ];

      // Only load rating stats if we don't have them already
      if (widget.existingRatingStats == null) {
        futures.add(ApiService.getDoctorRatingStats(widget.doctor.id));
      }

      final results = await Future.wait(futures);

      final doctorResponse = results[0];
      final reviewsResponse = results[1];
      final statsResponse = results.length > 2 ? results[2] : null;

      // Process doctor details
      if (doctorResponse['success']) {
        final data = doctorResponse['data'];
        setState(() {
          _detailedDoctor = Doctor(
            id: data['id'],
            userId: data['user']['id'] ?? 0,
            specializationId: data['specialization_id'],
            hourlyRate:
                double.tryParse(data['hourly_rate']?.toString() ?? '0') ?? 0.0,
            bio: data['bio'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: User(
              id: data['user']['id'] ?? 0,
              name: data['user']['name'] ?? 'Unknown Doctor',
              email: data['user']['email'] ?? '',
              role: data['user']['role'] ?? 'doctor',
              address: data['user']['address'],
              phone: data['user']['phone'],
              gender: data['user']['gender'],
              profilePhoto: data['user']['profile_photo'],
              profilePhotoUrl: data['user']['profile_photo_url'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            specialization: Specialization(
              id: data['specialization_id'] ?? 0,
              name: data['user']['specialization'] ?? 'General',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        });
      } else {
        setState(() {
          _detailedDoctor = widget.doctor;
        });
      }

      // Process rating stats only if not provided initially
      if (widget.existingRatingStats == null &&
          statsResponse != null &&
          statsResponse['success']) {
        setState(() {
          _ratingStats = DoctorRatingStats.fromJson(statsResponse['data']);
        });
      }

      // Process recent reviews
      if (reviewsResponse['success']) {
        final reviewsData = reviewsResponse['data']['reviews'] as List;
        setState(() {
          _recentReviews =
              reviewsData.map((json) => Review.fromJson(json)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _detailedDoctor = widget.doctor;
      });
      print('Error loading doctor data: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _detailedDoctor ?? widget.doctor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Doctor Info
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade400,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Avatar
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
                                  Text(
                                    doctor.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getSpecializationIcon(
                                              doctor.specializationName),
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          doctor.specializationName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Availability Indicator with Instant Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                const SizedBox(width: 8),
                                const Text(
                                  'Available Today',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            // Show rating immediately from cache or API
                            if (_ratingStats != null &&
                                _ratingStats!.totalReviews > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      _ratingStats!.averageRating
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${_ratingStats!.totalReviews})',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'No reviews',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Cards - Now with instant data
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star,
                          title:
                              _ratingStats?.averageRating.toStringAsFixed(1) ??
                                  'New',
                          subtitle: _ratingStats != null &&
                                  _ratingStats!.totalReviews > 0
                              ? '${_ratingStats!.totalReviews} reviews'
                              : 'No reviews',
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people,
                          title: '150+',
                          subtitle: 'Patients',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.work,
                          title: '8+',
                          subtitle: 'Years',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Contact Information
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (doctor.email.isNotEmpty)
                    _buildContactItem(
                      icon: Icons.email,
                      title: 'Email',
                      value: doctor.email,
                      color: Colors.blue,
                    ),

                  if (doctor.phone != null && doctor.phone!.isNotEmpty)
                    _buildContactItem(
                      icon: Icons.phone,
                      title: 'Phone',
                      value: doctor.phone!,
                      color: Colors.green,
                    ),

                  if (doctor.address != null && doctor.address!.isNotEmpty)
                    _buildContactItem(
                      icon: Icons.location_on,
                      title: 'Address',
                      value: doctor.address!,
                      color: Colors.red,
                    ),

                  const SizedBox(height: 24),

                  // About Section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getSpecializationIcon(doctor.specializationName),
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Specialist in ${doctor.specializationName}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doctor.bio ??
                              'Dr. ${doctor.name} is a dedicated ${doctor.specializationName.toLowerCase()} specialist with extensive experience in providing comprehensive medical care. Committed to patient well-being and utilizing the latest medical practices.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Consultation Fee
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: Colors.green.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Fee',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${doctor.hourlyRate.toInt()}/session',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Patient Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Patient Reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_ratingStats != null &&
                          _ratingStats!.totalReviews > 0)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    DoctorReviewsScreen(doctor: doctor),
                              ),
                            );
                          },
                          child: Text(
                            'See All (${_ratingStats!.totalReviews})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rating Summary Card - Instant Data
                  if (_ratingStats != null &&
                      _ratingStats!.totalReviews > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade50, Colors.amber.shade100],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          // Overall Rating
                          Column(
                            children: [
                              Text(
                                _ratingStats!.averageRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              RatingWidget(
                                rating: _ratingStats!.averageRating,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_ratingStats!.totalReviews} reviews',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Rating Breakdown (Compact)
                          Expanded(
                            child: Column(
                              children: List.generate(3, (index) {
                                final rating = 5 - index; // Show 5, 4, 3 stars
                                final count =
                                    _ratingStats!.ratingBreakdown[rating] ?? 0;
                                final percentage =
                                    _ratingStats!.totalReviews > 0
                                        ? count / _ratingStats!.totalReviews
                                        : 0.0;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$rating',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.star,
                                          size: 10, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: percentage,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Recent Reviews - Load after page loads
                  if (_isLoadingReviews)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_recentReviews.isNotEmpty) ...[
                    // Show up to 3 recent reviews
                    ...(_recentReviews.take(3).map((review) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ReviewCard(
                            review: review,
                            showDoctorName: false,
                          ),
                        ))),

                    if (_ratingStats != null &&
                        _ratingStats!.totalReviews > 3) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    DoctorReviewsScreen(doctor: doctor),
                              ),
                            );
                          },
                          icon: const Icon(Icons.reviews, size: 18),
                          label: Text(
                              'View All ${_ratingStats!.totalReviews} Reviews'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ] else if (_ratingStats == null ||
                      _ratingStats!.totalReviews == 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No reviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to review Dr. ${doctor.name}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Book Appointment Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
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
                        elevation: 4,
                        shadowColor: Colors.blue.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Book Appointment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
