import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/review.dart';
import 'create_review_screen.dart';
import 'my_reviews_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  Set<int> _reviewedAppointments = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load appointments first
      final appointmentsResponse = await ApiService.getAppointments();

      if (appointmentsResponse['success']) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(
              appointmentsResponse['data']['appointments'] ?? []);
        });
      } else {
        setState(() {
          _error =
              appointmentsResponse['message'] ?? 'Failed to load appointments';
        });
        return;
      }

      // Load reviews separately - don't let this break appointments
      try {
        final reviewsResponse = await ApiService.getPatientReviews();

        if (reviewsResponse['success']) {
          final reviewsData = reviewsResponse['data'];

          if (reviewsData != null && reviewsData['reviews'] != null) {
            final reviews = reviewsData['reviews'] as List;

            // Convert appointment IDs to consistent type and create set
            Set<int> reviewedIds = {};
            for (var review in reviews) {
              if (review['appointment_id'] != null) {
                try {
                  int appointmentId;
                  if (review['appointment_id'] is String) {
                    appointmentId = int.parse(review['appointment_id']);
                  } else {
                    appointmentId = review['appointment_id'] as int;
                  }
                  reviewedIds.add(appointmentId);
                } catch (e) {
                  // Skip this review if appointment_id can't be parsed
                  continue;
                }
              }
            }

            setState(() {
              _reviewedAppointments = reviewedIds;
            });
          } else {
            setState(() {
              _reviewedAppointments = {};
            });
          }
        } else {
          setState(() {
            _reviewedAppointments = {};
          });
        }
      } catch (e) {
        // Continue without review tracking - appointments still work
        setState(() {
          _reviewedAppointments = {};
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load appointments. Please try again.';
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
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const MyReviewsScreen(),
                    ),
                  )
                  .then((_) => _loadAppointments());
            },
            tooltip: 'My Reviews',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _appointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAppointments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return _buildEnhancedAppointmentCard(appointment);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Appointments Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first appointment with a doctor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to find doctors
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Doctors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'unknown';
    final date = appointment['date'] ?? '';
    final slot = appointment['slot'] ?? '';
    final doctorName = appointment['doctor_name'] ?? 'Unknown Doctor';
    final doctorSpecialization =
        appointment['doctor_specialization'] ?? 'General';
    final appointmentId = appointment['id'];
    final doctorId = appointment['doctor_id'];

    // Convert appointmentId to int for consistent comparison
    int? aptId;
    try {
      if (appointmentId is String) {
        aptId = int.parse(appointmentId);
      } else {
        aptId = appointmentId as int;
      }
    } catch (e) {
      aptId = appointmentId;
    }

    final statusConfig = _getStatusConfig(status);
    final appointmentDate = DateTime.tryParse(date);
    final isUpcoming =
        appointmentDate != null && appointmentDate.isAfter(DateTime.now());
    final isCompleted = status == 'completed';
    final hasBeenReviewed = _reviewedAppointments.contains(aptId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: statusConfig.color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusConfig.color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Status - FIXED OVERFLOW
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusConfig.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                // First row: Status info and appointment ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusConfig.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              statusConfig.icon,
                              size: 20,
                              color: statusConfig.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusConfig.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: statusConfig.color,
                                  ),
                                ),
                                Text(
                                  statusConfig.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusConfig.color
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$aptId',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Second row: Review status (only for completed appointments)
                if (isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasBeenReviewed
                              ? Colors.amber.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasBeenReviewed
                                ? Colors.amber.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasBeenReviewed ? Icons.star : Icons.star_border,
                              size: 14,
                              color: hasBeenReviewed
                                  ? Colors.amber.shade600
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasBeenReviewed ? 'Reviewed' : 'Not reviewed',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasBeenReviewed
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Doctor Info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.blue.shade200],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: Colors.blue.shade300, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              doctorSpecialization,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date and Time
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(slot),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Write Review Button for completed appointments that haven't been reviewed
                if (isCompleted && !hasBeenReviewed) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade50, Colors.amber.shade100],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rate_review,
                                color: Colors.amber.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Share Your Experience',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help other patients by writing a review about your appointment with Dr. $doctorName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _writeReview(appointment),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text(
                              'Write Review',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: Colors.amber.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Show "Already Reviewed" for completed and reviewed appointments
                if (isCompleted && hasBeenReviewed) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Thank you for your review!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyReviewsScreen(),
                                  ),
                                )
                                .then((_) => _loadAppointments());
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'View Review',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cancel/Reschedule buttons for pending appointments
                if (status == 'pending') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelAppointment(appointment),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Reschedule functionality
                          },
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text('Reschedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Time indicators for upcoming appointments
                if (isUpcoming && status == 'booked') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeUntilAppointment(appointmentDate!),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _writeReview(Map<String, dynamic> appointment) async {
    final reviewableAppointment = ReviewableAppointment(
      id: appointment['id'],
      appointmentDate: DateTime.parse(appointment['date']),
      slot: appointment['slot'],
      doctor: DoctorInfo(
        id: appointment['doctor_id'],
        name: appointment['doctor_name'],
        specialization: appointment['doctor_specialization'],
      ),
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateReviewScreen(appointment: reviewableAppointment),
      ),
    );

    // Refresh appointments if review was successfully submitted
    if (result == true) {
      await _loadAppointments();
    }
  }

  StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return StatusConfig(
          color: Colors.orange,
          icon: Icons.schedule,
          title: 'Pending',
          subtitle: 'Waiting for payment',
        );
      case 'booked':
        return StatusConfig(
          color: Colors.blue,
          icon: Icons.check_circle,
          title: 'Confirmed',
          subtitle: 'Appointment booked',
        );
      case 'completed':
        return StatusConfig(
          color: Colors.green,
          icon: Icons.check_circle_outline,
          title: 'Completed',
          subtitle: 'Visit finished',
        );
      case 'missed':
        return StatusConfig(
          color: Colors.red,
          icon: Icons.cancel,
          title: 'Missed',
          subtitle: 'Appointment missed',
        );
      default:
        return StatusConfig(
          color: Colors.grey,
          icon: Icons.help,
          title: 'Unknown',
          subtitle: 'Status unclear',
        );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String time24) {
    try {
      // Handle both "HH:mm:ss" and "HH:mm" formats
      String timeStr = time24.trim();

      // If the time includes seconds, remove them
      if (timeStr.contains(':') && timeStr.split(':').length == 3) {
        // Convert "14:00:00" to "14:00"
        final parts = timeStr.split(':');
        timeStr = '${parts[0]}:${parts[1]}';
      }

      final time = DateFormat('HH:mm').parse(timeStr);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return time24;
    }
  }

  String _getTimeUntilAppointment(DateTime appointmentDate) {
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);

    if (difference.inDays > 1) {
      return 'In ${difference.inDays} days';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inHours > 1) {
      return 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else {
      return 'Starting soon';
    }
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Cancel Appointment'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this appointment with ${appointment['doctor_name']}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.cancelAppointment(appointment['id']);

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Appointment cancelled successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          _loadAppointments();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? 'Failed to cancel appointment'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class StatusConfig {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  StatusConfig({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
