import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import 'api_service.dart';

class AppointmentService extends ChangeNotifier {
  // Cache storage
  Map<String, List<Map<String, dynamic>>> _categorizedAppointments = {
    'pending': [],
    'booked': [],
    'completed': [],
    'missed': [],
  };
  
  Map<String, dynamic> _appointmentStats = {};
  List<Map<String, dynamic>> _completedAppointmentsForMessages = []; // For doctors
  
  // Loading states
  bool _isLoadingAppointments = false;
  bool _isLoadingStats = false;
  bool _isLoadingCompleted = false;
  
  // Cache timestamps
  DateTime? _appointmentsLastLoaded;
  DateTime? _statsLastLoaded;
  DateTime? _completedLastLoaded;
  
  // Cache validity duration (3 minutes for appointments as they change more frequently)
  static const Duration _cacheValidDuration = Duration(minutes: 3);
  static const Duration _statsValidDuration = Duration(minutes: 5);

  // Getters
  Map<String, List<Map<String, dynamic>>> get categorizedAppointments => 
      Map.unmodifiable(_categorizedAppointments);
  Map<String, dynamic> get appointmentStats => Map.unmodifiable(_appointmentStats);
  List<Map<String, dynamic>> get completedAppointmentsForMessages => 
      List.unmodifiable(_completedAppointmentsForMessages);
  
  bool get isLoadingAppointments => _isLoadingAppointments;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingCompleted => _isLoadingCompleted;
  
  bool get hasCachedAppointments => _categorizedAppointments.values.any((list) => list.isNotEmpty);
  bool get hasCachedStats => _appointmentStats.isNotEmpty;
  bool get hasCachedCompleted => _completedAppointmentsForMessages.isNotEmpty;

  // Check if cache is still valid
  bool get isAppointmentsCacheValid {
    if (_appointmentsLastLoaded == null) return false;
    return DateTime.now().difference(_appointmentsLastLoaded!) < _cacheValidDuration;
  }

  bool get isStatsCacheValid {
    if (_statsLastLoaded == null) return false;
    return DateTime.now().difference(_statsLastLoaded!) < _statsValidDuration;
  }

  bool get isCompletedCacheValid {
    if (_completedLastLoaded == null) return false;
    return DateTime.now().difference(_completedLastLoaded!) < _cacheValidDuration;
  }

  /// Load initial appointment data after login (background operation)
  Future<void> loadInitialData(String userRole) async {
    try {
      // Load different data based on user role
      if (userRole == 'patient') {
        unawaited(_loadPatientAppointments());
        unawaited(_loadAppointmentStats());
      } else if (userRole == 'doctor') {
        unawaited(_loadDoctorAppointments());
        unawaited(_loadCompletedAppointments());
      }
    } catch (e) {
      debugPrint('Error loading initial appointment data: $e');
    }
  }

  /// Get appointments with caching
  Future<Map<String, List<Map<String, dynamic>>>> getAppointments({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and no force refresh
    if (!forceRefresh && hasCachedAppointments && isAppointmentsCacheValid) {
      return _categorizedAppointments;
    }

    // Load fresh data
    await _loadPatientAppointments();
    return _categorizedAppointments;
  }

  /// Get appointment statistics
  Future<Map<String, dynamic>> getAppointmentStats({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCachedStats && isStatsCacheValid) {
      return _appointmentStats;
    }

    await _loadAppointmentStats();
    return _appointmentStats;
  }

  /// Get completed appointments for doctor messages
  Future<List<Map<String, dynamic>>> getCompletedAppointments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCachedCompleted && isCompletedCacheValid) {
      return _completedAppointmentsForMessages;
    }

    await _loadCompletedAppointments();
    return _completedAppointmentsForMessages;
  }

  /// Update appointment status and refresh cache
  Future<bool> updateAppointmentStatus(int appointmentId, String status) async {
    try {
      final response = await ApiService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      if (response['success']) {
        // Refresh appointments after status update
        await _loadPatientAppointments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }

  /// Cancel appointment and refresh cache
  Future<bool> cancelAppointment(int appointmentId) async {
    try {
      final response = await ApiService.cancelAppointment(appointmentId);

      if (response['success']) {
        // Remove from cache immediately for better UX
        _removeAppointmentFromCache(appointmentId);
        notifyListeners();
        
        // Then refresh from server
        unawaited(_loadPatientAppointments());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error canceling appointment: $e');
      return false;
    }
  }

  /// Reschedule appointment and refresh cache
  Future<bool> rescheduleAppointment({
    required int appointmentId,
    required DateTime appointmentDate,
    required String slot,
  }) async {
    try {
      final response = await ApiService.rescheduleAppointment(
        appointmentId: appointmentId,
        appointmentDate: appointmentDate,
        slot: slot,
      );

      if (response['success']) {
        // Refresh appointments after reschedule
        await _loadPatientAppointments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      return false;
    }
  }

  /// Create new appointment and refresh cache
  Future<Map<String, dynamic>?> createAppointment({
    required int doctorId,
    required DateTime appointmentDate,
    required String slot,
  }) async {
    try {
      final response = await ApiService.createAppointment(
        doctorId: doctorId,
        appointmentDate: appointmentDate,
        slot: slot,
      );

      if (response['success']) {
        // Refresh appointments after creation
        unawaited(_loadPatientAppointments());
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      return null;
    }
  }

  /// Private method to load patient appointments
  Future<void> _loadPatientAppointments() async {
    if (_isLoadingAppointments) return;
    
    _isLoadingAppointments = true;
    notifyListeners();

    try {
      final response = await ApiService.getAppointmentsByStatus();

      if (response['success']) {
        _categorizedAppointments = ApiService.parseCategorizedAppointments(response);
        _appointmentsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading patient appointments: $e');
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  /// Private method to load doctor appointments (for doctor dashboard)
  Future<void> _loadDoctorAppointments() async {
    if (_isLoadingAppointments) return;
    
    _isLoadingAppointments = true;
    notifyListeners();

    try {
      final response = await ApiService.getAppointments(); // Doctor appointments endpoint

      if (response['success']) {
        // Parse doctor appointments format
        final data = response['data'] as List<dynamic>? ?? [];
        _categorizedAppointments = _categorizeDoctorAppointments(data);
        _appointmentsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading doctor appointments: $e');
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  /// Private method to load appointment statistics
  Future<void> _loadAppointmentStats() async {
    if (_isLoadingStats) return;
    
    _isLoadingStats = true;
    notifyListeners();

    try {
      final response = await ApiService.getAppointmentStats();

      if (response['success']) {
        _appointmentStats = response['data'] ?? {};
        _statsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading appointment stats: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Private method to load completed appointments for doctor messages
  Future<void> _loadCompletedAppointments() async {
    if (_isLoadingCompleted) return;
    
    _isLoadingCompleted = true;
    notifyListeners();

    try {
      final response = await ApiService.getCompletedAppointments();

      if (response['success']) {
        _completedAppointmentsForMessages = 
            List<Map<String, dynamic>>.from(response['data'] ?? []);
        _completedLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading completed appointments: $e');
    } finally {
      _isLoadingCompleted = false;
      notifyListeners();
    }
  }

  /// Helper method to categorize doctor appointments
  Map<String, List<Map<String, dynamic>>> _categorizeDoctorAppointments(List<dynamic> appointments) {
    final categorized = {
      'pending': <Map<String, dynamic>>[],
      'booked': <Map<String, dynamic>>[],
      'completed': <Map<String, dynamic>>[],
      'missed': <Map<String, dynamic>>[],
    };

    for (final appointment in appointments) {
      final appointmentMap = Map<String, dynamic>.from(appointment);
      final status = appointmentMap['status']?.toString().toLowerCase() ?? '';
      
      if (categorized.containsKey(status)) {
        categorized[status]!.add(appointmentMap);
      }
    }

    return categorized;
  }

  /// Helper method to remove appointment from cache
  void _removeAppointmentFromCache(int appointmentId) {
    for (final category in _categorizedAppointments.values) {
      category.removeWhere((appointment) => appointment['id'] == appointmentId);
    }
  }

  /// Force refresh all appointment data
  Future<void> refreshAllData(String userRole) async {
    _clearCache();
    await loadInitialData(userRole);
  }

  /// Clear all cached data
  void _clearCache() {
    _categorizedAppointments = {
      'pending': [],
      'booked': [],
      'completed': [],
      'missed': [],
    };
    _appointmentStats.clear();
    _completedAppointmentsForMessages.clear();
    _appointmentsLastLoaded = null;
    _statsLastLoaded = null;
    _completedLastLoaded = null;
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