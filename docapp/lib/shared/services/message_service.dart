import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'api_service.dart';

class MessageService extends ChangeNotifier {
  // Cache storage
  List<PatientMessage> _patientMessages = [];
  Map<String, List<PatientMessage>> _groupedMessages = {};
  List<Map<String, dynamic>> _completedAppointmentsForMessages = [];
  
  // Loading states
  bool _isLoadingPatientMessages = false;
  bool _isLoadingCompletedAppointments = false;
  bool _isSendingMessage = false;
  
  // Cache timestamps
  DateTime? _patientMessagesLastLoaded;
  DateTime? _completedAppointmentsLastLoaded;
  
  // Cache validity duration (2 minutes for messages as they're real-time)
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  // Getters
  List<PatientMessage> get patientMessages => List.unmodifiable(_patientMessages);
  Map<String, List<PatientMessage>> get groupedMessages => Map.unmodifiable(_groupedMessages);
  List<Map<String, dynamic>> get completedAppointmentsForMessages => 
      List.unmodifiable(_completedAppointmentsForMessages);
  
  bool get isLoadingPatientMessages => _isLoadingPatientMessages;
  bool get isLoadingCompletedAppointments => _isLoadingCompletedAppointments;
  bool get isSendingMessage => _isSendingMessage;
  
  bool get hasCachedPatientMessages => _patientMessages.isNotEmpty;
  bool get hasCachedCompletedAppointments => _completedAppointmentsForMessages.isNotEmpty;

  // Check if cache is still valid
  bool get isPatientMessagesCacheValid {
    if (_patientMessagesLastLoaded == null) return false;
    return DateTime.now().difference(_patientMessagesLastLoaded!) < _cacheValidDuration;
  }

  bool get isCompletedAppointmentsCacheValid {
    if (_completedAppointmentsLastLoaded == null) return false;
    return DateTime.now().difference(_completedAppointmentsLastLoaded!) < _cacheValidDuration;
  }

  /// Load initial message data after login (background operation)
  Future<void> loadInitialData(String userRole) async {
    try {
      if (userRole == 'patient') {
        unawaited(_loadPatientMessages());
      } else if (userRole == 'doctor') {
        unawaited(_loadCompletedAppointments());
      }
    } catch (e) {
      debugPrint('Error loading initial message data: $e');
    }
  }

  /// Get patient messages with caching
  Future<List<PatientMessage>> getPatientMessages({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and no force refresh
    if (!forceRefresh && hasCachedPatientMessages && isPatientMessagesCacheValid) {
      return _patientMessages;
    }

    // Load fresh data
    await _loadPatientMessages();
    return _patientMessages;
  }

  /// Get grouped patient messages with caching
  Future<Map<String, List<PatientMessage>>> getGroupedPatientMessages({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCachedPatientMessages && isPatientMessagesCacheValid) {
      return _groupedMessages;
    }

    await _loadPatientMessages();
    return _groupedMessages;
  }

  /// Get completed appointments for doctor to send messages
  Future<List<Map<String, dynamic>>> getCompletedAppointments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCachedCompletedAppointments && isCompletedAppointmentsCacheValid) {
      return _completedAppointmentsForMessages;
    }

    await _loadCompletedAppointments();
    return _completedAppointmentsForMessages;
  }

  /// Send message to patient and refresh cache
  Future<bool> sendMessage({
    required int appointmentId,
    required String doctorMessage,
  }) async {
    if (_isSendingMessage) return false;
    
    _isSendingMessage = true;
    notifyListeners();

    try {
      final response = await ApiService.sendMessage(
        appointmentId: appointmentId,
        doctorMessage: doctorMessage,
      );

      if (response['success']) {
        // Refresh completed appointments to update message status
        unawaited(_loadCompletedAppointments());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Update existing message and refresh cache
  Future<bool> updateMessage({
    required int messageId,
    required String doctorMessage,
  }) async {
    if (_isSendingMessage) return false;
    
    _isSendingMessage = true;
    notifyListeners();

    try {
      final response = await ApiService.updateMessage(
        messageId: messageId,
        doctorMessage: doctorMessage,
      );

      if (response['success']) {
        // Refresh completed appointments
        unawaited(_loadCompletedAppointments());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating message: $e');
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Delete message and refresh cache
  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await ApiService.deleteMessage(messageId);

      if (response['success']) {
        // Remove from cache immediately for better UX
        _removeMessageFromCache(messageId);
        notifyListeners();
        
        // Then refresh from server
        unawaited(_loadCompletedAppointments());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Private method to load patient messages
  Future<void> _loadPatientMessages() async {
    if (_isLoadingPatientMessages) return;
    
    _isLoadingPatientMessages = true;
    notifyListeners();

    try {
      final response = await ApiService.getPatientMessages();

      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        final List<PatientMessage> messages = [];

        for (var json in data) {
          try {
            final message = PatientMessage.fromJson(json);
            messages.add(message);
          } catch (e) {
            debugPrint('Error parsing message: $e');
            continue;
          }
        }

        _patientMessages = messages;
        _groupedMessages = _groupMessagesByDoctor(messages);
        _patientMessagesLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading patient messages: $e');
    } finally {
      _isLoadingPatientMessages = false;
      notifyListeners();
    }
  }

  /// Private method to load completed appointments for doctor
  Future<void> _loadCompletedAppointments() async {
    if (_isLoadingCompletedAppointments) return;
    
    _isLoadingCompletedAppointments = true;
    notifyListeners();

    try {
      final response = await ApiService.getCompletedAppointments();

      if (response['success']) {
        _completedAppointmentsForMessages = 
            List<Map<String, dynamic>>.from(response['data'] ?? []);
        _completedAppointmentsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading completed appointments: $e');
    } finally {
      _isLoadingCompletedAppointments = false;
      notifyListeners();
    }
  }

  /// Helper method to group messages by doctor
  Map<String, List<PatientMessage>> _groupMessagesByDoctor(List<PatientMessage> messages) {
    final Map<String, List<PatientMessage>> grouped = {};
    
    for (var message in messages) {
      try {
        final doctorKey = '${message.appointment.doctor.name}_${message.appointment.doctor.specialization}';
        if (!grouped.containsKey(doctorKey)) {
          grouped[doctorKey] = [];
        }
        grouped[doctorKey]!.add(message);
      } catch (e) {
        debugPrint('Error grouping message: $e');
        continue;
      }
    }

    // Sort messages within each group by date (newest first)
    grouped.forEach((key, messageList) {
      try {
        messageList.sort((a, b) {
          try {
            return b.createdAt.compareTo(a.createdAt);
          } catch (e) {
            return 0;
          }
        });
      } catch (e) {
        debugPrint('Error sorting messages for $key: $e');
      }
    });

    return grouped;
  }

  /// Helper method to remove message from cache
  void _removeMessageFromCache(int messageId) {
    _patientMessages.removeWhere((message) => message.id == messageId);
    
    // Rebuild grouped messages
    _groupedMessages = _groupMessagesByDoctor(_patientMessages);
    
    // Remove from completed appointments if it has message
    _completedAppointmentsForMessages.removeWhere((appointment) {
      final messages = appointment['messages'] as List<dynamic>? ?? [];
      return messages.any((msg) => msg['id'] == messageId);
    });
  }

  /// Get message count for a specific doctor
  int getMessageCountForDoctor(String doctorKey) {
    return _groupedMessages[doctorKey]?.length ?? 0;
  }

  /// Get latest message for a specific doctor
  PatientMessage? getLatestMessageForDoctor(String doctorKey) {
    final messages = _groupedMessages[doctorKey];
    return messages?.isNotEmpty == true ? messages!.first : null;
  }

  /// Check if appointment has existing message
  bool appointmentHasMessage(int appointmentId) {
    for (final appointment in _completedAppointmentsForMessages) {
      if (appointment['id'] == appointmentId) {
        final messages = appointment['messages'] as List<dynamic>? ?? [];
        return messages.isNotEmpty;
      }
    }
    return false;
  }

  /// Get existing message for appointment
  Map<String, dynamic>? getMessageForAppointment(int appointmentId) {
    for (final appointment in _completedAppointmentsForMessages) {
      if (appointment['id'] == appointmentId) {
        final messages = appointment['messages'] as List<dynamic>? ?? [];
        return messages.isNotEmpty ? messages.first : null;
      }
    }
    return null;
  }

  /// Force refresh all message data
  Future<void> refreshAllData(String userRole) async {
    _clearCache();
    await loadInitialData(userRole);
  }

  /// Clear all cached data
  void _clearCache() {
    _patientMessages.clear();
    _groupedMessages.clear();
    _completedAppointmentsForMessages.clear();
    _patientMessagesLastLoaded = null;
    _completedAppointmentsLastLoaded = null;
    notifyListeners();
  }

  /// Clear cache when user logs out
  void clearCache() {
    _clearCache();
  }
}

// Helper function for non-blocking async calls
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('Unawaited future error: $error');
  });
}