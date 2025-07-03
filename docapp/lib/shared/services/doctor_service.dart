import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import '../models/specialization.dart';
import '../models/review.dart';
import 'api_service.dart';

class DoctorService extends ChangeNotifier {
  // Cache storage
  List<Doctor> _allDoctors = [];
  List<Specialization> _specializations = [];
  Map<int, DoctorRatingStats> _doctorRatings = {};
  
  // Loading states
  bool _isDoctorsLoading = false;
  bool _isSpecializationsLoading = false;
  bool _isRatingsLoading = false;
  
  // Cache timestamps for refresh logic
  DateTime? _doctorsLastLoaded;
  DateTime? _specializationsLastLoaded;
  
  // Cache validity duration (5 minutes)
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<Doctor> get allDoctors => List.unmodifiable(_allDoctors);
  List<Specialization> get specializations => List.unmodifiable(_specializations);
  Map<int, DoctorRatingStats> get doctorRatings => Map.unmodifiable(_doctorRatings);
  
  bool get isDoctorsLoading => _isDoctorsLoading;
  bool get isSpecializationsLoading => _isSpecializationsLoading;
  bool get isRatingsLoading => _isRatingsLoading;
  
  bool get hasCachedDoctors => _allDoctors.isNotEmpty;
  bool get hasCachedSpecializations => _specializations.isNotEmpty;

  // Check if cache is still valid
  bool get isDoctorsCacheValid {
    if (_doctorsLastLoaded == null) return false;
    return DateTime.now().difference(_doctorsLastLoaded!) < _cacheValidDuration;
  }

  bool get isSpecializationsCacheValid {
    if (_specializationsLastLoaded == null) return false;
    return DateTime.now().difference(_specializationsLastLoaded!) < _cacheValidDuration;
  }

  /// Load initial data after login (background operation)
  Future<void> loadInitialData() async {
    try {
      // Load in parallel but don't await to keep it non-blocking
      unawaited(_loadDoctors());
      unawaited(loadSpecializations());
    } catch (e) {
      debugPrint('Error loading initial doctor data: $e');
    }
  }

  /// Get doctors with optional filtering (uses cache if available)
  Future<List<Doctor>> getDoctors({
    int? specializationId,
    String? search,
    bool forceRefresh = false,
  }) async {
    // If no filters and cache is valid, return cached data
    if (!forceRefresh && 
        specializationId == null && 
        (search?.isEmpty ?? true) && 
        hasCachedDoctors && 
        isDoctorsCacheValid) {
      return _allDoctors;
    }

    // If filters are applied or cache is invalid, fetch from API
    return await _loadDoctors(
      specializationId: specializationId,
      search: search,
    );
  }

  /// Get doctor rating stats (uses cache if available)
  DoctorRatingStats? getDoctorRating(int doctorId) {
    return _doctorRatings[doctorId];
  }

  /// Load doctor rating for specific doctor
  Future<DoctorRatingStats?> loadDoctorRating(int doctorId) async {
    if (_doctorRatings.containsKey(doctorId)) {
      return _doctorRatings[doctorId];
    }

    try {
      final response = await ApiService.getDoctorRatingStats(doctorId);
      if (response['success']) {
        final rating = DoctorRatingStats.fromJson(response['data']);
        _doctorRatings[doctorId] = rating;
        notifyListeners();
        return rating;
      }
    } catch (e) {
      debugPrint('Error loading rating for doctor $doctorId: $e');
    }
    return null;
  }

  /// Load ratings for multiple doctors
  Future<void> loadDoctorRatings(List<int> doctorIds) async {
    if (_isRatingsLoading) return;
    
    _isRatingsLoading = true;
    notifyListeners();

    try {
      // Load ratings in batches of 3 to avoid overwhelming the server
      for (int i = 0; i < doctorIds.length; i += 3) {
        final batch = doctorIds.skip(i).take(3);
        final futures = batch.map((doctorId) => _loadSingleDoctorRating(doctorId));
        await Future.wait(futures);
      }
    } catch (e) {
      debugPrint('Error loading doctor ratings: $e');
    } finally {
      _isRatingsLoading = false;
      notifyListeners();
    }
  }

  /// Load specializations (public method)
  Future<void> loadSpecializations() async {
    await _loadSpecializations();
  }

  /// Private method to load doctors from API
  Future<List<Doctor>> _loadDoctors({
    int? specializationId,
    String? search,
  }) async {
    if (_isDoctorsLoading) return _allDoctors;
    
    _isDoctorsLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getDoctors(
        specializationId: specializationId,
        search: search,
      );

      if (response['success']) {
        final doctorsData = response['data'] as List;
        final doctors = doctorsData.map((json) => Doctor.fromListJson(json)).toList();
        
        // Only cache if no filters applied
        if (specializationId == null && (search?.isEmpty ?? true)) {
          _allDoctors = doctors;
          _doctorsLastLoaded = DateTime.now();
          
          // Load ratings for these doctors in background
          final doctorIds = doctors.map((d) => d.id).toList();
          unawaited(loadDoctorRatings(doctorIds));
        }
        
        notifyListeners();
        return doctors;
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    } finally {
      _isDoctorsLoading = false;
      notifyListeners();
    }

    return _allDoctors;
  }

  /// Private method to load specializations from API
  Future<void> _loadSpecializations() async {
    if (_isSpecializationsLoading || isSpecializationsCacheValid) return;
    
    _isSpecializationsLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getSpecializations();
      if (response['success']) {
        final specializationsData = response['data'] as List;
        _specializations = specializationsData
            .map((json) => Specialization.fromJson(json))
            .toList();
        _specializationsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading specializations: $e');
    } finally {
      _isSpecializationsLoading = false;
      notifyListeners();
    }
  }

  /// Private method to load single doctor rating
  Future<void> _loadSingleDoctorRating(int doctorId) async {
    if (_doctorRatings.containsKey(doctorId)) return;

    try {
      final response = await ApiService.getDoctorRatingStats(doctorId);
      if (response['success']) {
        _doctorRatings[doctorId] = DoctorRatingStats.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error loading rating for doctor $doctorId: $e');
    }
  }

  /// Force refresh all cached data
  Future<void> refreshAllData() async {
    _clearCache();
    await loadInitialData();
  }

  /// Clear all cached data
  void _clearCache() {
    _allDoctors.clear();
    _specializations.clear();
    _doctorRatings.clear();
    _doctorsLastLoaded = null;
    _specializationsLastLoaded = null;
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