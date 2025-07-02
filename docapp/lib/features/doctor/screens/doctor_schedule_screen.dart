import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/schedule.dart';
import '../../../shared/widgets/exit_wrapper_widget.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  List<Schedule> _schedules = [];
  Map<String, bool> _dayHasAppointments = {};
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  String? _updatingDay;

  final List<String> _weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Start both futures without awaiting yet
      final scheduleFuture = ApiService.getDoctorSchedule();
      final appointmentsFuture = ApiService.getDaysWithAppointments();

      // Wait for both to complete in parallel
      final results = await Future.wait([scheduleFuture, appointmentsFuture]);

      final scheduleResponse = results[0];
      final appointmentsResponse = results[1];

      if (scheduleResponse['success']) {
        final scheduleData = scheduleResponse['data'] as List;
        _schedules =
            scheduleData.map((json) => Schedule.fromJson(json)).toList();

        // Sort schedules by day order
        _schedules.sort((a, b) {
          return _weekDays
              .indexOf(a.fullDayName)
              .compareTo(_weekDays.indexOf(b.fullDayName));
        });
      } else {
        throw Exception(
            scheduleResponse['message'] ?? 'Failed to load schedule');
      }

      if (appointmentsResponse['success']) {
        final daysData = appointmentsResponse['data'] as Map<String, dynamic>;
        Map<String, bool> hasAppointments = {};
        for (String day in _weekDays) {
          final dayData = daysData[day] as Map<String, dynamic>?;
          hasAppointments[day] = dayData?['has_appointments'] ?? false;
        }
        _dayHasAppointments = hasAppointments;
      } else {
        // If appointments API fails, default to no appointments
        _dayHasAppointments = {for (var day in _weekDays) day: false};
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAppointmentsForAllDays() async {
    try {
      final response = await ApiService.getDaysWithAppointments();

      if (response['success']) {
        final daysData = response['data'] as Map<String, dynamic>;
        Map<String, bool> hasAppointments = {};

        for (String day in _weekDays) {
          final dayData = daysData[day] as Map<String, dynamic>?;
          hasAppointments[day] = dayData?['has_appointments'] ?? false;
        }

        setState(() {
          _dayHasAppointments = hasAppointments;
        });
      }
    } catch (e) {
      print('Error checking appointments: $e');
      // If API fails, default to allowing all edits
      Map<String, bool> defaultStatus = {};
      for (String day in _weekDays) {
        defaultStatus[day] = false;
      }
      setState(() {
        _dayHasAppointments = defaultStatus;
      });
    }
  }

  Future<void> _toggleStatus(String day) async {
    setState(() {
      _isUpdating = true;
      _updatingDay = day;
    });

    try {
      final response = await ApiService.toggleScheduleStatus(dayName: day);

      if (response['success']) {
        // Parse updated schedule from API response
        final updatedJson = response['data']['schedule'];
        final updatedSchedule = Schedule.fromJson(updatedJson);

        setState(() {
          final index =
              _schedules.indexWhere((s) => s.day == updatedSchedule.day);
          if (index != -1) {
            _schedules[index] = updatedSchedule;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Toggled availability for $day'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to toggle status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
        _updatingDay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExitWrapper(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'My Schedule',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadSchedule,
              tooltip: 'Refresh Schedule',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadSchedule,
                    child: _buildScheduleContent(),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSchedule,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    return Column(
      children: [
        // Header Info Card - Consistent with your app theme
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Schedule Management',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You cannot modify days with existing appointments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Schedule List - Compact Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _schedules.length,
            itemBuilder: (context, index) {
              final schedule = _schedules[index];
              final hasAppointments =
                  _dayHasAppointments[schedule.fullDayName] ?? false;

              return _buildCompactScheduleCard(schedule, hasAppointments);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactScheduleCard(Schedule schedule, bool hasAppointments) {
    final isUpdating = _updatingDay == schedule.day;
    final canEdit = !hasAppointments && !isUpdating;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasAppointments ? Colors.orange.shade200 : Colors.green.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canEdit ? () => _editSchedule(schedule) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Day Icon & Name
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasAppointments
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getDayIcon(schedule.day),
                        size: 20,
                        color: hasAppointments
                            ? Colors.orange.shade600
                            : Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.fullDayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            hasAppointments
                                ? 'Has appointments'
                                : 'Available for editing',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasAppointments
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Toggle or Lock Icon
                    if (canEdit)
                      Switch(
                        value: schedule.status == 'available',
                        onChanged: (value) => _toggleStatus(schedule.day),
                        activeColor: Colors.green.shade600,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          'LOCKED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Time & Slots Row
                Row(
                  children: [
                    // Time Range
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${schedule.startTime} - ${schedule.endTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Slots Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '${schedule.calculatedSlots} slots',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: schedule.status == 'available'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: schedule.status == 'available'
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: schedule.status == 'available'
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.status == 'available' ? 'Active' : 'Off',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: schedule.status == 'available'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Loading Indicator
                if (isUpdating) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDayIcon(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return Icons.work;
      case 'tuesday':
        return Icons.business_center;
      case 'wednesday':
        return Icons.laptop;
      case 'thursday':
        return Icons.assignment;
      case 'friday':
        return Icons.celebration;
      case 'saturday':
        return Icons.weekend;
      case 'sunday':
        return Icons.home;
      default:
        return Icons.calendar_today;
    }
  }

  Future<void> _editSchedule(Schedule schedule) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ScheduleEditDialog(schedule: schedule),
    );

    if (result != null) {
      await _updateSchedule(
        schedule.day,
        result['startTime']!,
        result['endTime']!,
      );
    }
  }

  Future<void> _updateSchedule(
      String day, String startTime, String endTime) async {
    setState(() {
      _isUpdating = true;
      _updatingDay = day;
    });

    try {
      final response = await ApiService.updateDoctorSchedule(
        dayName: day,
        startTime: startTime,
        endTime: endTime,
      );

      if (response['success']) {
        final updatedJson = response['data']['schedule'];
        final updatedSchedule = Schedule.fromJson(updatedJson);

        setState(() {
          final index =
              _schedules.indexWhere((s) => s.day == updatedSchedule.day);
          if (index != -1) {
            _schedules[index] = updatedSchedule;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Schedule updated for $day'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update schedule');
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
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
        _updatingDay = null;
      });
    }
  }
}

class _ScheduleEditDialog extends StatefulWidget {
  final Schedule schedule;

  const _ScheduleEditDialog({required this.schedule});

  @override
  State<_ScheduleEditDialog> createState() => _ScheduleEditDialogState();
}

class _ScheduleEditDialogState extends State<_ScheduleEditDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.schedule.startTime);
    _endTime = _parseTime(widget.schedule.endTime);
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _calculateSlots() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return ((endMinutes - startMinutes) / 30).floor();
  }

  bool _validateTimes() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      setState(() {
        _error = 'End time must be after start time';
      });
      return false;
    }

    if ((endMinutes - startMinutes) < 120) {
      setState(() {
        _error = 'Minimum duration is 120 minutes';
      });
      return false;
    }

    setState(() {
      _error = null;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit ${widget.schedule.fullDayName}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Start Time
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Time',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (time != null) {
                                  setState(() => _startTime = time);
                                  _validateTimes();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  _startTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // End Time
                  Row(
                    children: [
                      Icon(Icons.access_time_filled,
                          color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Time',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (time != null) {
                                  setState(() => _endTime = time);
                                  _validateTimes();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  _endTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Slots Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Available Slots: ${_calculateSlots()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _error == null && _validateTimes()
              ? () {
                  Navigator.of(context).pop({
                    'startTime': _formatTime(_startTime),
                    'endTime': _formatTime(_endTime),
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
