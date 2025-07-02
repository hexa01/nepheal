import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/specialization.dart';
import 'doctors_list_screen.dart';
import 'patient_profile_screen.dart';
import 'my_appointments_screen.dart';
import '../../../shared/widgets/exit_wrapper_widget.dart';
import 'patient_messages_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    // Add bounds checking to prevent RangeError
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  List<Widget> get _screens => [
        PatientHomeScreen(onNavigate: _changeTab),
        const DoctorsListScreen(),
        const MyAppointmentsScreen(),
        const PatientMessagesScreen(),
        const PatientProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return ExitWrapper(
      child: Scaffold(
        body: _currentIndex < _screens.length
            ? _screens[_currentIndex]
            : _screens[0],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: _changeTab,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 10,
            unselectedFontSize: 9,
            iconSize: 20,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: 'Doctors'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: 'Appointments'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.message), label: 'Messages'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const PatientHomeScreen({super.key, required this.onNavigate});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  List<Specialization> _specializations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  Future<void> _loadSpecializations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getSpecializations();
      if (response['success']) {
        final specializationsData = response['data'] as List<dynamic>;
        setState(() {
          _specializations = specializationsData
              .map((data) => Specialization.fromJson(data))
              .toList();
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load specializations';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade500,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Nepheal',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your health, our priority',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
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
                  // Quick Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Quick Action Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildActionCard(
                        Icons.search,
                        'Find Doctors',
                        'Browse specialists',
                        Colors.blue,
                        () => widget.onNavigate(1),
                      ),
                      _buildActionCard(
                        Icons.calendar_today,
                        'Appointments',
                        'Manage bookings',
                        Colors.green,
                        () => widget.onNavigate(2),
                      ),
                      _buildActionCard(
                        Icons.rate_review,
                        'Reviews',
                        'Your feedback',
                        Colors.purple,
                        () => widget.onNavigate(3),
                      ),
                      _buildActionCard(
                        Icons.person,
                        'Profile',
                        'Account settings',
                        Colors.orange,
                        () => widget.onNavigate(4),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Medical Specializations Section
                  const Text(
                    'Medical Specializations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specializations Horizontal List
                  SizedBox(
                    height: 100,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? _buildStaticSpecializationsList()
                            : _specializations.isEmpty
                                ? _buildStaticSpecializationsList()
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.only(right: 8),
                                    itemCount: _specializations.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: _buildSpecializationCard(
                                            _specializations[index].name),
                                      );
                                    },
                                  ),
                  ),
                  const SizedBox(height: 20),

                  // Health Tip Section
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb,
                                color: Colors.green.shade600, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Health Tip of the Day',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Regular health check-ups can help detect issues early. Don\'t forget to share your experiences by writing reviews for your doctors!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticSpecializationsList() {
    final staticSpecs = [
      'General Medicine',
      'Cardiology',
      'Neurology',
      'Orthopedics',
      'Pediatrics',
      'Dermatology',
      'Ophthalmology',
      'ENT'
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 8),
      itemCount: staticSpecs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildSpecializationCard(staticSpecs[index]),
        );
      },
    );
  }

  Widget _buildSpecializationCard(String name) {
    final color = _getSpecializationColor(name);
    final icon = _getSpecializationIcon(name);

    return InkWell(
      onTap: () => widget.onNavigate(1), // Navigate to Find Doctors
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSpecializationColor(String name) {
    switch (name.toLowerCase()) {
      case 'cardiology':
        return Colors.red;
      case 'neurology':
        return Colors.purple;
      case 'orthopedics':
        return Colors.orange;
      case 'pediatrics':
        return Colors.pink;
      case 'dermatology':
        return Colors.amber;
      case 'ophthalmology':
      case 'eye care':
      case 'eye':
        return Colors.blue;
      case 'ent':
      case 'nose':
      case 'ear':
        return Colors.teal;
      case 'general medicine':
      case 'general':
        return Colors.green;
      case 'gynecology':
        return Colors.purple;
      case 'psychiatry':
        return Colors.indigo;
      case 'radiology':
        return Colors.cyan;
      case 'anesthesiology':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  IconData _getSpecializationIcon(String name) {
    switch (name.toLowerCase()) {
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
      case 'general medicine':
      case 'general':
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
