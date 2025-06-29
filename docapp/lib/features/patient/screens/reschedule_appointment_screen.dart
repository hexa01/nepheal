import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  final int appointmentId;
  final int doctorId;
  final String currentDate;
  final String currentSlot;
  final String doctorName;

  const RescheduleAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.currentDate,
    required this.currentSlot,
    required this.doctorName,
  });

  @override
  State<RescheduleAppointmentScreen> createState() => _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState extends State<RescheduleAppointmentScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isRescheduling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Parse current date for comparison
    try {
      _selectedDate = DateTime.parse(widget.currentDate);
      _selectedSlot = widget.currentSlot;
      _loadAvailableSlots();
    } catch (e) {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current appointment info
            _buildCurrentAppointmentCard(),
            const SizedBox(height: 24),

            // New date selection
            _buildDateSelection(),
            const SizedBox(height: 24),

            // Time slots
            if (_selectedDate != null) ...[
              _buildTimeSlotSelection(),
              const SizedBox(height: 24),
            ],

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Reschedule button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canReschedule() ? _rescheduleAppointment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRescheduling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Reschedule',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAppointmentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Current Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                CompactProfileAvatar(
                  imageUrl: null,
                  initials: "Doctor red"
                      .split(' ')
                      .map((n) => n[0])
                      .take(2)
                      .join()
                      .toUpperCase(),
                  size: 70,
                  backgroundColor: Colors.blue.shade100,
                  textColor: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.currentDate),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(widget.currentSlot),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select New Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!)
                        : 'Choose new appointment date',
                    style: TextStyle(
                      color: _selectedDate != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select New Time Slot',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingSlots) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_availableSlots.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No slots available for this date. Please select another date.',
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableSlots.map((slot) {
              final isSelected = _selectedSlot == slot;
              final isCurrent = slot == widget.currentSlot && 
                              _selectedDate != null &&
                              DateFormat('yyyy-MM-dd').format(_selectedDate!) == widget.currentDate;
              
              return InkWell(
                onTap: () => setState(() => _selectedSlot = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.blue.shade600 
                        : isCurrent
                            ? Colors.orange.shade100
                            : Colors.white,
                    border: Border.all(
                      color: isSelected 
                          ? Colors.blue.shade600 
                          : isCurrent
                              ? Colors.orange.shade300
                              : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(slot),
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : isCurrent
                                  ? Colors.orange.shade700
                                  : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          if (_hasChanges()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New appointment details:',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(DateFormat('yyyy-MM-dd').format(_selectedDate!))} at ${_formatTime(_selectedSlot!)}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
        _availableSlots = [];
        _error = null;
      });
      await _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final response = await ApiService.getAvailableSlots(
        doctorId: widget.doctorId,
        appointmentDate: dateStr,
      );

      if (response['success']) {
        final data = response['data'];
        List<String> slots = [];

        if (data is List) {
          slots = data.map((item) => item.toString()).toList();
        } else if (data is Map) {
          slots = data.values.map((item) => item.toString()).toList();
        }

        // If we're on the same date as current appointment, include the current slot
        if (dateStr == widget.currentDate && !slots.contains(widget.currentSlot)) {
          slots.add(widget.currentSlot);
          slots.sort();
        }

        setState(() {
          _availableSlots = slots;
          // If we're on the same date, auto-select current slot
          if (dateStr == widget.currentDate && _selectedSlot == null) {
            _selectedSlot = widget.currentSlot;
          }
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load available slots';
          _availableSlots = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _availableSlots = [];
      });
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  bool _canReschedule() {
    return _selectedDate != null && 
           _selectedSlot != null && 
           !_isRescheduling && 
           _hasChanges();
  }

  bool _hasChanges() {
    if (_selectedDate == null || _selectedSlot == null) return false;
    
    final newDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    return newDateStr != widget.currentDate || _selectedSlot != widget.currentSlot;
  }

  Future<void> _rescheduleAppointment() async {
    if (!_canReschedule()) return;

    setState(() {
      _isRescheduling = true;
      _error = null;
    });

    try {
      final response = await ApiService.rescheduleAppointment(
        appointmentId: widget.appointmentId,
        appointmentDate: _selectedDate!,
        slot: _selectedSlot!,
      );

      if (response['success']) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment rescheduled successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Go back to previous screen
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to reschedule appointment';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isRescheduling = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String time24) {
    try {
      String timeStr = time24.trim();
      if (timeStr.contains(':') && timeStr.split(':').length == 3) {
        final parts = timeStr.split(':');
        timeStr = '${parts[0]}:${parts[1]}';
      }
      final time = DateFormat('HH:mm').parse(timeStr);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return time24;
    }
  }
}