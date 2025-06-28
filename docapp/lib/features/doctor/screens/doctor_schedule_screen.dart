import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/schedule.dart';

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
      _schedules = scheduleData.map((json) => Schedule.fromJson(json)).toList();

      // Sort schedules by day order
      _schedules.sort((a, b) {
        return _weekDays.indexOf(a.fullDayName).compareTo(_weekDays.indexOf(b.fullDayName));
      });
    } else {
      throw Exception(scheduleResponse['message'] ?? 'Failed to load schedule');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
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
        // Header Info
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Weekly Schedule Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Note: You cannot modify days with existing appointments.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Schedule List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _schedules.length,
            itemBuilder: (context, index) {
              final schedule = _schedules[index];
              final hasAppointments =
                  _dayHasAppointments[schedule.fullDayName] ?? false;

              return _buildScheduleCard(schedule, hasAppointments);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Schedule schedule, bool hasAppointments) {
    final isUpdating = _updatingDay == schedule.day;
    final canEdit = !hasAppointments && !isUpdating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: hasAppointments
                ? Colors.orange.withValues(alpha: 0.3)
                : Colors.green.withValues(alpha: 0.3),
            width: 2),
        boxShadow: [
          BoxShadow(
            color: (hasAppointments ? Colors.orange : Colors.green)
                .withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (hasAppointments
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (hasAppointments
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDayIcon(schedule.day),
                    size: 24,
                    color: hasAppointments
                        ? Colors.orange.shade600
                        : Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.fullDayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: hasAppointments
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                      Text(
                        hasAppointments
                            ? 'Has appointments - Cannot modify'
                            : 'Available for editing',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              (hasAppointments ? Colors.orange : Colors.green)
                                  .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAppointments)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
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
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Current Schedule Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Working Hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            schedule.timeRange,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '${schedule.calculatedSlots} slots',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                schedule.status == 'available'
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: schedule.status == 'available'
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                schedule.status == 'available'
                                    ? 'Available'
                                    : 'Not Available',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: schedule.status == 'available'
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: schedule.status == 'available',
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                            onChanged: (hasAppointments || isUpdating)
                                ? null
                                : (_) => _toggleStatus(schedule.day),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canEdit ? () => _editSchedule(schedule) : null,
                    icon: isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            hasAppointments ? Icons.lock : Icons.edit,
                            size: 18,
                          ),
                    label: Text(
                      isUpdating
                          ? 'Updating...'
                          : hasAppointments
                              ? 'Cannot Edit (Has Appointments)'
                              : 'Edit Schedule',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canEdit ? Colors.green : Colors.grey.shade400,
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
          ),
        ],
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
      title: Text('Edit ${widget.schedule.fullDayName} Schedule'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Time
            ListTile(
              leading: Icon(Icons.schedule, color: Colors.green.shade600),
              title: const Text('Start Time'),
              subtitle: Text(_formatTime(_startTime)),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (time != null) {
                  setState(() {
                    _startTime = time;
                  });
                  _validateTimes();
                }
              },
            ),

            // End Time
            ListTile(
              leading: Icon(Icons.schedule_send, color: Colors.green.shade600),
              title: const Text('End Time'),
              subtitle: Text(_formatTime(_endTime)),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (time != null) {
                  setState(() {
                    _endTime = time;
                  });
                  _validateTimes();
                }
              },
            ),

            const SizedBox(height: 16),

            // Slots Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Available Slots: ${_calculateSlots()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Each slot is 30 minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
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
          child: const Text('Cancel'),
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
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
