// Fixed book_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/doctor.dart';
import 'payment_screen.dart';
import 'my_appointments_screen.dart';
import '../../../shared/widgets/exit_wrapper_widget.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info card
            _buildDoctorCard(),
            const SizedBox(height: 24),

            // Date selection
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

            // Book appointment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDate != null &&
                        _selectedSlot != null &&
                        !_isBooking
                    ? _bookAppointment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Book Appointment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.doctor.specializationName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${(widget.doctor.hourlyRate / 2).toStringAsFixed(0)}/session',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
          'Select Date',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        ? _formatDate(_selectedDate!)
                        : 'Select appointment date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey.shade600,
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
        _availableSlots = [];
      });
      await _loadAvailableSlots();
    }
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_isLoadingSlots)
          const Center(child: CircularProgressIndicator())
        else if (_availableSlots.isEmpty)
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
                    'No available slots for this date',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return InkWell(
                onTap: () => setState(() => _selectedSlot = slot),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _formatTime(slot),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
      _error = null;
    });

    try {
      final response = await ApiService.getAvailableSlots(
        doctorId: widget.doctor.id,
        appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );

      if (response['success']) {
        final data = response['data'];
if (data is List) {
  setState(() {
    _availableSlots = List<String>.from(data);
    _error = null;
  });
} else if (data is Map) {
  setState(() {
    _availableSlots = data.values.map((e) => e.toString()).toList();
    _error = null;
  });
}
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

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedSlot == null) return;

    setState(() {
      _isBooking = true;
      _error = null;
    });

    try {
      final response = await ApiService.createAppointment(
        doctorId: widget.doctor.id,
        appointmentDate: _selectedDate!,
        slot: _selectedSlot!,
      );

      if (response['success']) {
        final appointmentData = response['data']['appointment'];
        final paymentData = response['data']['payment'];

        if (mounted) {
          // Show booking success and payment options
          await _showBookingSuccessDialog(appointmentData, paymentData);
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to book appointment';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  Future<void> _showBookingSuccessDialog(
      Map<String, dynamic> appointment, Map<String, dynamic> payment) async {
    final bool? wantsToPay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Appointment Booked!',
              style: TextStyle(
                fontSize: 16, // 👈 Decreased font size
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your appointment has been successfully booked.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Date: ${_formatDate(_selectedDate!)}'),
                  Text('Time: ${_formatTime(_selectedSlot!)}'),
                  Text('Amount: Rs. ${payment['amount'].toString()}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Status: Pending (Payment required to confirm)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to complete the payment now to confirm your appointment?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Pay Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (wantsToPay == true && mounted) {
      // Navigate to payment screen
      final paymentResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            appointmentId: appointment['id'] as int,
            amount: (payment['amount'] as num).toDouble(),
            doctorName: widget.doctor.name,
            appointmentDate: appointment['date'].toString(),
            appointmentSlot: appointment['slot'].toString(),
          ),
        ),
      );

      if (paymentResult == true && mounted) {
        // Payment successful - Navigate to My Appointments (Booked section)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed! Your appointment is confirmed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to MyAppointments screen and switch to booked tab
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyAppointmentsScreen(
                initialTabIndex: 1), // 1 = booked tab
          ),
        );
      } else if (mounted) {
        // Payment cancelled or failed, but appointment still exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Appointment booked. You can pay later from My Appointments.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to MyAppointments screen and switch to pending tab
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyAppointmentsScreen(
                initialTabIndex: 0), // 0 = pending tab
          ),
        );
      }
    } else if (mounted) {
      // User chose to pay later
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked! Complete payment to confirm.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to MyAppointments screen and switch to pending tab
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              const MyAppointmentsScreen(initialTabIndex: 0), // 0 = pending tab
        ),
      );
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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }
}
