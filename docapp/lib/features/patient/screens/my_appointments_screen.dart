import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'payment_screen.dart';
import 'reschedule_appointment_screen.dart';
import '../../../shared/services/appointment_service.dart';
import '../../../shared/models/review.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import 'create_review_screen.dart';
import 'my_reviews_screen.dart';
import '../../../shared/widgets/exit_wrapper_widget.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final int initialTabIndex;

  const MyAppointmentsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final appointmentService =
        Provider.of<AppointmentService>(context, listen: false);

    try {
      await Future.wait([
        appointmentService.getAppointments(),
        appointmentService.getAppointmentStats(),
      ]);
    } catch (e) {
      // Error handling moved to Consumer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        final categorizedAppointments =
            appointmentService.categorizedAppointments;
        final isLoading = appointmentService.isLoadingAppointments &&
            !appointmentService.hasCachedAppointments;
        final stats = appointmentService.appointmentStats;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Appointments'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  text: 'Pending',
                  icon: Badge(
                    label: Text(
                        '${categorizedAppointments['pending']?.length ?? 0}'),
                    child: const Icon(Icons.schedule),
                  ),
                ),
                Tab(
                  text: 'Booked',
                  icon: Badge(
                    label: Text(
                        '${categorizedAppointments['booked']?.length ?? 0}'),
                    child: const Icon(Icons.check_circle),
                  ),
                ),
                Tab(
                  text: 'Completed',
                  icon: Badge(
                    label: Text(
                        '${categorizedAppointments['completed']?.length ?? 0}'),
                    child: const Icon(Icons.check_circle_outline),
                  ),
                ),
                Tab(
                  text: 'Missed',
                  icon: Badge(
                    label: Text(
                        '${categorizedAppointments['missed']?.length ?? 0}'),
                    child: const Icon(Icons.cancel),
                  ),
                ),
              ],
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsList('pending', categorizedAppointments),
                    _buildAppointmentsList('booked', categorizedAppointments),
                    _buildAppointmentsList(
                        'completed', categorizedAppointments),
                    _buildAppointmentsList('missed', categorizedAppointments),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAppointmentsList(String category,
      Map<String, List<Map<String, dynamic>>> categorizedAppointments) {
    final appointments = categorizedAppointments[category] ?? [];

    if (appointments.isEmpty) {
      return _buildEmptyState(category);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final appointmentService =
            Provider.of<AppointmentService>(context, listen: false);
        await appointmentService.getAppointments(forceRefresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment, category);
        },
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    String message;
    IconData icon;

    switch (category) {
      case 'pending':
        message = 'No pending appointments';
        icon = Icons.schedule;
        break;
      case 'booked':
        message = 'No confirmed appointments';
        icon = Icons.check_circle;
        break;
      case 'completed':
        message = 'No completed appointments';
        icon = Icons.check_circle_outline;
        break;
      case 'missed':
        message = 'No missed appointments';
        icon = Icons.cancel;
        break;
      default:
        message = 'No appointments';
        icon = Icons.event_note;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
      Map<String, dynamic> appointment, String category) {
    final statusConfig = _getStatusConfig(category);
    final canModify = category == 'pending';
    final canPayNow = category == 'pending' &&
        appointment['payment_status'] != null &&
        appointment['payment_status'] == 'unpaid';

    // Check if review has been written
    final hasReview = appointment['has_review'] == true;
    final canWriteReview = category == 'completed' && !hasReview;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header with doctor info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusConfig.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        statusConfig.icon,
                        size: 20,
                        color: statusConfig.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusConfig.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: statusConfig.color,
                          ),
                        ),
                        Text(
                          statusConfig.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusConfig.color.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Doctor and appointment details
            Row(
              children: [
                CompactProfileAvatar(
                  imageUrl: appointment['profile_photo_url'],
                  initials: appointment['doctor_name']
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
                        appointment['doctor_name']?.toString() ??
                            'Unknown Doctor',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(appointment['date']?.toString() ?? ''),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(appointment['slot']?.toString() ?? ''),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Rs. ${appointment['amount']?.toString() ?? '300'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // Payment status for pending appointments
            if (canPayNow) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment pending - Complete payment to confirm',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            if (canPayNow) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _payNow(appointment),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (canModify) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rescheduleAppointment(appointment),
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Add review button for completed appointments
            if (canWriteReview) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _createReview(appointment),
                  icon: const Icon(Icons.rate_review, size: 18),
                  label: const Text('Write Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Show review completed message
            if (category == 'completed' && hasReview) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thank you for your review!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
      if (dateStr.isEmpty) return 'Unknown date';
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr.isEmpty ? 'Unknown date' : dateStr;
    }
  }

  String _formatTime(String time24) {
    try {
      if (time24.isEmpty) return 'Unknown time';
      String timeStr = time24.trim();
      if (timeStr.contains(':') && timeStr.split(':').length == 3) {
        final parts = timeStr.split(':');
        timeStr = '${parts[0]}:${parts[1]}';
      }
      final time = DateFormat('HH:mm').parse(timeStr);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return time24.isEmpty ? 'Unknown time' : time24;
    }
  }

  Future<void> _payNow(Map<String, dynamic> appointment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          appointmentId: appointment['id'] ?? 0,
          amount: appointment['amount']?.toDouble() ?? 0.0,
          doctorName:
              appointment['doctor_name']?.toString() ?? 'Unknown Doctor',
          appointmentDate: appointment['date']?.toString() ?? '',
          appointmentSlot: appointment['slot']?.toString() ?? '',
        ),
      ),
    );

    if (result == true) {
      final appointmentService =
          Provider.of<AppointmentService>(context, listen: false);
      await appointmentService.getAppointments(forceRefresh: true);

      if (mounted) {
        _tabController.animateTo(1); // Switch to booked tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAppointment(Map<String, dynamic> appointment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RescheduleAppointmentScreen(
          appointmentId: appointment['id'] ?? 0,
          currentDate: appointment['date']?.toString() ?? '',
          currentSlot: appointment['slot']?.toString() ?? '',
          doctorId: appointment['doctor_id'] ?? 0,
          doctorName:
              appointment['doctor_name']?.toString() ?? 'Unknown Doctor',
        ),
      ),
    );

    if (result == true) {
      final appointmentService =
          Provider.of<AppointmentService>(context, listen: false);
      await appointmentService.getAppointments(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final appointmentService =
        Provider.of<AppointmentService>(context, listen: false);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await appointmentService.cancelAppointment(appointment['id'] ?? 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Appointment cancelled successfully'
                : 'Failed to cancel appointment'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createReview(Map<String, dynamic> appointment) async {
    try {
      // Convert the appointment data to ReviewableAppointment format
      final reviewableAppointment = ReviewableAppointment(
        id: appointment['id'] ?? 0,
        appointmentDate: DateTime.parse(appointment['date']?.toString() ??
            DateTime.now().toIso8601String()),
        slot: appointment['slot']?.toString() ?? '',
        doctor: DoctorInfo(
          id: appointment['doctor_id'] ?? 0,
          name: appointment['doctor_name']?.toString() ?? 'Unknown Doctor',
          specialization:
              appointment['specialization']?.toString() ?? 'General',
          profilePhoto: appointment['profile_photo']?.toString() ?? '',
          profilePhotoUrl: appointment['profile_photo_url']?.toString() ?? '',
        ),
      );

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => CreateReviewScreen(
            appointment: reviewableAppointment,
          ),
        ),
      );

      // Refresh appointments if review was successfully created
      if (result == true) {
        final appointmentService =
            Provider.of<AppointmentService>(context, listen: false);
        await appointmentService.getAppointments(forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening review screen: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
