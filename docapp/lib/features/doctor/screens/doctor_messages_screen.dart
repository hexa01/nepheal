// features/doctor/screens/doctor_messages_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/models/message.dart';
import '../../../shared/services/api_service.dart';
import 'compose_message_screen.dart';
import '../../../shared/widgets/exit_wrapper_widget.dart';

class DoctorMessagesScreen extends StatefulWidget {
  const DoctorMessagesScreen({super.key});

  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  Map<String, List<CompletedAppointment>> _groupedAppointments = {};
  bool _isLoading = true;
  String? _error;
  Set<String> _expandedPatients = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCompletedAppointments();
  }

  Future<void> _loadCompletedAppointments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService.getCompletedAppointments();

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final List<CompletedAppointment> appointments = [];

        for (var json in data) {
          try {
            final appointment = CompletedAppointment.fromJson(json);
            appointments.add(appointment);
          } catch (e) {
            continue;
          }
        }

        final Map<String, List<CompletedAppointment>> grouped = {};
        for (var appointment in appointments) {
          try {
            final patientKey =
                '${appointment.patient.id}_${appointment.patient.name}';
            if (!grouped.containsKey(patientKey)) {
              grouped[patientKey] = [];
            }
            grouped[patientKey]!.add(appointment);
          } catch (e) {
            continue;
          }
        }

        grouped.forEach((key, appointmentList) {
          try {
            appointmentList.sort((a, b) {
              try {
                return DateTime.parse(b.appointmentDate)
                    .compareTo(DateTime.parse(a.appointmentDate));
              } catch (e) {
                return 0;
              }
            });
          } catch (e) {
            // Continue with unsorted list
          }
        });

        setState(() {
          _groupedAppointments = grouped;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load appointments');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAppointments() async {
    await _loadCompletedAppointments();
  }

  void _togglePatientExpansion(String patientKey) {
    setState(() {
      if (_expandedPatients.contains(patientKey)) {
        _expandedPatients.remove(patientKey);
      } else {
        _expandedPatients.add(patientKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExitWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Patient Messages'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshAppointments,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groupedAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Completed Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete appointments to send messages to patients',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAppointments,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedAppointments.length,
        itemBuilder: (context, index) {
          final patientKey = _groupedAppointments.keys.elementAt(index);
          final patientAppointments = _groupedAppointments[patientKey]!;
          final patient = patientAppointments.first.patient;
          final isExpanded = _expandedPatients.contains(patientKey);

          return _buildPatientCard(
              patientKey, patient, patientAppointments, isExpanded);
        },
      ),
    );
  }

  Widget _buildPatientCard(String patientKey, PatientInfo patient,
      List<CompletedAppointment> appointments, bool isExpanded) {
    final totalMessages =
        appointments.where((apt) => apt.hasMessage == true).length;
    final totalAppointments = appointments.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _togglePatientExpansion(patientKey),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green[100],
                    child: Text(
                      _getPatientInitial(patient.name),
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (patient.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            patient.phone!,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalMessages/$totalAppointments',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointments & Messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...appointments
                      .map((appointment) => _buildAppointmentItem(appointment))
                      .toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(CompletedAppointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateShort(appointment.appointmentDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  appointment.slot,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointment.hasMessage) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Message Sent',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (appointment.message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getMessagePreview(appointment.message!.doctorMessage),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.pending,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'No Message',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: () => _navigateToComposeMessage(appointment),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                appointment.hasMessage ? Icons.edit : Icons.send,
                color: Colors.green[700],
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToComposeMessage(CompletedAppointment appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeMessageScreen(appointment: appointment),
      ),
    );

    if (result == true) {
      _refreshAppointments();
    }
  }

  String _getPatientInitial(String name) {
    try {
      if (name.isEmpty) return '?';
      return name.substring(0, 1).toUpperCase();
    } catch (e) {
      return '?';
    }
  }

  String _getMessagePreview(String message) {
    try {
      if (message.isEmpty) return 'No message content';
      return message.length > 50 ? '${message.substring(0, 50)}...' : message;
    } catch (e) {
      return 'Message preview unavailable';
    }
  }

  String _formatDateShort(String dateString) {
    try {
      if (dateString.isEmpty) return 'N/A';
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateString.isNotEmpty ? dateString : 'Invalid Date';
    }
  }
}
