import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/appointment_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../../shared/widgets/exit_wrapper_widget.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final int? initialTabIndex;

  const DoctorAppointmentsScreen({super.key, this.initialTabIndex});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _upcomingTabController;
  late TabController _pastTabController;

  final ScrollController _scrollController = ScrollController();

  // Pagination for completed/missed appointments
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex ?? 0);
    _upcomingTabController = TabController(length: 2, vsync: this);
    _pastTabController = TabController(length: 3, vsync: this);

    _scrollController.addListener(_onScroll);
    _loadAppointments();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreAppointments();
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _upcomingTabController.dispose();
    _pastTabController.dispose();
    _scrollController.dispose();
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

  Future<void> _loadMoreAppointments() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Simulate loading more appointments
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Separate appointments by date with pagination for past appointments
  Map<String, List<Map<String, dynamic>>> _separateAppointmentsByDate(
      Map<String, List<Map<String, dynamic>>> categorizedAppointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Map<String, dynamic>> upcomingPending = [];
    List<Map<String, dynamic>> upcomingBooked = [];
    List<Map<String, dynamic>> pastToUpdate = [];
    List<Map<String, dynamic>> pastCompleted = [];
    List<Map<String, dynamic>> pastMissed = [];

    // Process each category
    for (var appointment in categorizedAppointments['pending'] ?? []) {
      final dateStr =
          appointment['appointment_date'] ?? appointment['date'] ?? '';
      if (_isUpcomingOrToday(dateStr, today)) {
        upcomingPending.add(appointment);
      }
    }

    for (var appointment in categorizedAppointments['booked'] ?? []) {
      final dateStr =
          appointment['appointment_date'] ?? appointment['date'] ?? '';
      if (_isUpcomingOrToday(dateStr, today)) {
        upcomingBooked.add(appointment);
      } else {
        pastToUpdate.add(appointment);
      }
    }

    // For completed and missed, implement pagination
    final completedList = categorizedAppointments['completed'] ?? [];
    final missedList = categorizedAppointments['missed'] ?? [];

    // Sort by date (most recent first) and paginate
    completedList.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['appointment_date'] ?? a['date'] ?? '') ??
              DateTime.now();
      final dateB =
          DateTime.tryParse(b['appointment_date'] ?? b['date'] ?? '') ??
              DateTime.now();
      return dateB.compareTo(dateA);
    });

    missedList.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['appointment_date'] ?? a['date'] ?? '') ??
              DateTime.now();
      final dateB =
          DateTime.tryParse(b['appointment_date'] ?? b['date'] ?? '') ??
              DateTime.now();
      return dateB.compareTo(dateA);
    });

    // Paginate completed and missed
    final completedPaginated =
        completedList.take(_currentPage * _itemsPerPage).toList();
    final missedPaginated =
        missedList.take(_currentPage * _itemsPerPage).toList();

    pastCompleted.addAll(completedPaginated);
    pastMissed.addAll(missedPaginated);

    // Sort upcoming by date and time
    upcomingPending.sort((a, b) => _compareDates(a, b));
    upcomingBooked.sort((a, b) => _compareDates(a, b));
    pastToUpdate.sort((a, b) => _compareDates(b, a)); // Most recent first

    return {
      'upcoming_pending': upcomingPending,
      'upcoming_booked': upcomingBooked,
      'past_to_update': pastToUpdate,
      'past_completed': pastCompleted,
      'past_missed': pastMissed,
    };
  }

  bool _isUpcomingOrToday(String dateStr, DateTime today) {
    try {
      final appointmentDate = DateTime.parse(dateStr);
      final appointmentDay = DateTime(
          appointmentDate.year, appointmentDate.month, appointmentDate.day);
      return appointmentDay.isAfter(today) ||
          appointmentDay.isAtSameMomentAs(today);
    } catch (e) {
      return false;
    }
  }

  int _compareDates(Map<String, dynamic> a, Map<String, dynamic> b) {
    final dateA = DateTime.tryParse(a['appointment_date'] ?? a['date'] ?? '') ??
        DateTime.now();
    final dateB = DateTime.tryParse(b['appointment_date'] ?? b['date'] ?? '') ??
        DateTime.now();
    return dateA.compareTo(dateB);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        final categorizedAppointments =
            appointmentService.categorizedAppointments;
        final isLoading = appointmentService.isLoadingAppointments &&
            !appointmentService.hasCachedAppointments;
        final separatedAppointments =
            _separateAppointmentsByDate(categorizedAppointments);

        final upcomingPendingCount =
            separatedAppointments['upcoming_pending']?.length ?? 0;
        final upcomingBookedCount =
            separatedAppointments['upcoming_booked']?.length ?? 0;
        final pastToUpdateCount =
            separatedAppointments['past_to_update']?.length ?? 0;
        final pastCompletedCount =
            separatedAppointments['past_completed']?.length ?? 0;
        final pastMissedCount =
            separatedAppointments['past_missed']?.length ?? 0;

        return ExitWrapper(
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: const Text('My Appointments'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _mainTabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Badge(
                          label: Text(
                              '${upcomingPendingCount + upcomingBookedCount}'),
                          child: const Icon(Icons.schedule, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text('Upcoming', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Badge(
                          label: Text(
                              '${pastToUpdateCount + pastCompletedCount + pastMissedCount}'),
                          child: const Icon(Icons.history, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text('Past', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                : Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _mainTabController,
                          children: [
                            _buildUpcomingTab(separatedAppointments),
                            _buildPastTab(separatedAppointments),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingTab(
      Map<String, List<Map<String, dynamic>>> separatedAppointments) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _upcomingTabController,
            labelColor: Colors.green.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.green.shade600,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions, size: 16),
                    const SizedBox(width: 4),
                    Text(
                        'Pending (${separatedAppointments['upcoming_pending']?.length ?? 0})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 4),
                    Text(
                        'Booked (${separatedAppointments['upcoming_booked']?.length ?? 0})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _upcomingTabController,
            children: [
              _buildAppointmentsList(
                  separatedAppointments['upcoming_pending'] ?? [],
                  'Pending Payment',
                  'New bookings awaiting payment will appear here.',
                  Icons.schedule,
                  Colors.orange),
              _buildAppointmentsList(
                  separatedAppointments['upcoming_booked'] ?? [],
                  'Confirmed Appointments',
                  'Paid appointments will appear here.',
                  Icons.check_circle,
                  Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPastTab(
      Map<String, List<Map<String, dynamic>>> separatedAppointments) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TabBar(
            controller: _pastTabController,
            labelColor: Colors.green.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.green.shade600,
            isScrollable: true,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.update, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text(
                        'To Update (${separatedAppointments['past_to_update']?.length ?? 0})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                        'Completed (${separatedAppointments['past_completed']?.length ?? 0})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text(
                        'Missed (${separatedAppointments['past_missed']?.length ?? 0})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _pastTabController,
            children: [
              _buildAppointmentsList(
                  separatedAppointments['past_to_update'] ?? [],
                  'Appointments to Update',
                  'Past appointments needing status updates will appear here.',
                  Icons.edit,
                  Colors.orange,
                  showActions: true),
              _buildPaginatedList(
                  separatedAppointments['past_completed'] ?? [],
                  'Completed Appointments',
                  'Finished appointments will appear here.',
                  Icons.check_circle,
                  Colors.green),
              _buildPaginatedList(
                  separatedAppointments['past_missed'] ?? [],
                  'Missed Appointments',
                  'No-show appointments will appear here.',
                  Icons.cancel,
                  Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments,
      String emptyTitle, String emptyMessage, IconData icon, Color color,
      {bool showActions = false}) {
    if (appointments.isEmpty) {
      return _buildEmptyState(emptyTitle, emptyMessage, icon, color);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final appointmentService =
            Provider.of<AppointmentService>(context, listen: false);
        await appointmentService.getAppointments(forceRefresh: true);
      },
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index],
              showActions: showActions);
        },
      ),
    );
  }

  Widget _buildPaginatedList(List<Map<String, dynamic>> appointments,
      String emptyTitle, String emptyMessage, IconData icon, Color color) {
    if (appointments.isEmpty) {
      return _buildEmptyState(emptyTitle, emptyMessage, icon, color);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final appointmentService =
            Provider.of<AppointmentService>(context, listen: false);
        await appointmentService.getAppointments(forceRefresh: true);
      },
      color: Colors.teal,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < appointments.length) {
            return _buildCompactAppointmentCard(appointments[index]);
          } else {
            return const Padding(
              padding: EdgeInsets.all(16),
              child:
                  Center(child: CircularProgressIndicator(color: Colors.teal)),
            );
          }
        },
      ),
    );
  }

  Widget _buildCompactAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? '';
    final statusInfo = _getStatusInfo(status);
    final patient = appointment['patient'] as Map<String, dynamic>?;
    final patientUser = patient?['user'] as Map<String, dynamic>?;
    final patientName = patientUser?['name'] ??
        appointment['patient_name'] ??
        'Unknown Patient';
    final appointmentDate =
        appointment['appointment_date'] ?? appointment['date'] ?? '';
    final slot = appointment['slot'] ?? '';
    final profilePhotoUrl = appointment['profile_photo_url'];
    final patientInitials = patientName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CompactProfileAvatar(
          imageUrl: profilePhotoUrl,
          initials: patientInitials,
          size: 40,
          backgroundColor: statusInfo.color.withOpacity(0.1),
          textColor: statusInfo.color,
        ),
        title: Text(
          patientName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDateShort(appointmentDate)} • ${_formatTime(slot)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusInfo.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusInfo.icon, size: 14, color: statusInfo.color),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment,
      {bool showActions = false}) {
    final status = appointment['status'] ?? '';
    final statusInfo = _getStatusInfo(status);
    final patient = appointment['patient'] as Map<String, dynamic>?;
    final patientUser = patient?['user'] as Map<String, dynamic>?;
    final patientName = patientUser?['name'] ??
        appointment['patient_name'] ??
        'Unknown Patient';
    final patientEmail =
        patientUser?['email'] ?? appointment['patient_email'] ?? '';
    final appointmentDate =
        appointment['appointment_date'] ?? appointment['date'] ?? '';
    final slot = appointment['slot'] ?? '';
    final profilePhotoUrl = appointment['profile_photo_url'];
    final patientInitials = patientName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final isToday = _isToday(appointmentDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? Colors.orange.shade300
                : statusInfo.color.withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with patient info and status
              Row(
                children: [
                  CompactProfileAvatar(
                    imageUrl: profilePhotoUrl,
                    initials: patientInitials,
                    size: 48,
                    backgroundColor: statusInfo.color.withOpacity(0.1),
                    textColor: statusInfo.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        if (patientEmail.isNotEmpty)
                          Text(
                            patientEmail,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: statusInfo.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo.icon,
                            size: 14, color: statusInfo.color),
                        const SizedBox(width: 4),
                        Text(
                          statusInfo.title.toUpperCase(),
                          style: TextStyle(
                            color: statusInfo.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Date and Time Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
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
                              Text('Date',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_formatDate(appointmentDate),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.grey.shade300),
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
                              Text('Time',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_formatTime(slot),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Today indicator
              if (isToday) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.today,
                          size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Appointment',
                        style: TextStyle(
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              // Action buttons for appointments that need updating
              if (showActions && status == 'booked') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateAppointmentStatus(appointment, 'completed'),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Mark Completed',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _updateAppointmentStatus(appointment, 'missed'),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Mark Missed',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      String title, String message, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return StatusInfo(
          color: Colors.orange,
          icon: Icons.schedule,
          title: 'Pending',
        );
      case 'booked':
        return StatusInfo(
          color: Colors.blue,
          icon: Icons.check_circle,
          title: 'Confirmed',
        );
      case 'completed':
        return StatusInfo(
          color: Colors.green,
          icon: Icons.check_circle,
          title: 'Completed',
        );
      case 'missed':
        return StatusInfo(
          color: Colors.red,
          icon: Icons.cancel,
          title: 'Missed',
        );
      default:
        return StatusInfo(
          color: Colors.grey,
          icon: Icons.help,
          title: 'Unknown',
        );
    }
  }

  bool _isToday(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (e) {
      return false;
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

  String _formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String time24) {
    try {
      final time = DateFormat('HH:mm').parse(time24);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return time24;
    }
  }

  Future<void> _updateAppointmentStatus(
      Map<String, dynamic> appointment, String newStatus) async {
    final appointmentService =
        Provider.of<AppointmentService>(context, listen: false);
    final statusText = newStatus == 'completed' ? 'Completed' : 'Missed';
    final patient = appointment['patient'] as Map<String, dynamic>?;
    final patientUser = patient?['user'] as Map<String, dynamic>?;
    final patientName =
        patientUser?['name'] ?? appointment['patient_name'] ?? 'Patient';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              newStatus == 'completed' ? Icons.check_circle : Icons.cancel,
              color: newStatus == 'completed' ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('Mark as $statusText'),
          ],
        ),
        content: Text(
          'Are you sure you want to mark the appointment with $patientName as $statusText?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'completed' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Mark $statusText'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await appointmentService.updateAppointmentStatus(
          appointment['id'] ?? 0, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Appointment marked as ${newStatus == 'completed' ? 'completed' : 'missed'}'
                : 'Failed to update appointment'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class StatusInfo {
  final Color color;
  final IconData icon;
  final String title;

  StatusInfo({
    required this.color,
    required this.icon,
    required this.title,
  });
}
