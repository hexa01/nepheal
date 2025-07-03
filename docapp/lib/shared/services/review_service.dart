import 'package:flutter/foundation.dart';
import '../models/review.dart';
import 'api_service.dart';

class ReviewService extends ChangeNotifier {
  // Cache storage
  List<Review> _patientReviews = [];
  List<ReviewableAppointment> _reviewableAppointments = [];
  Map<int, DoctorRatingStats> _doctorRatings = {};
  Map<int, List<Review>> _doctorReviews = {}; // Reviews for specific doctors
  
  // Loading states
  bool _isLoadingPatientReviews = false;
  bool _isLoadingReviewableAppointments = false;
  bool _isLoadingDoctorReviews = false;
  bool _isSubmittingReview = false;
  
  // Cache timestamps
  DateTime? _patientReviewsLastLoaded;
  DateTime? _reviewableAppointmentsLastLoaded;
  Map<int, DateTime> _doctorReviewsLastLoaded = {};
  
  // Cache validity duration (5 minutes for reviews as they don't change frequently)
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<Review> get patientReviews => List.unmodifiable(_patientReviews);
  List<ReviewableAppointment> get reviewableAppointments => List.unmodifiable(_reviewableAppointments);
  Map<int, DoctorRatingStats> get doctorRatings => Map.unmodifiable(_doctorRatings);
  
  bool get isLoadingPatientReviews => _isLoadingPatientReviews;
  bool get isLoadingReviewableAppointments => _isLoadingReviewableAppointments;
  bool get isLoadingDoctorReviews => _isLoadingDoctorReviews;
  bool get isSubmittingReview => _isSubmittingReview;
  
  bool get hasCachedPatientReviews => _patientReviews.isNotEmpty;
  bool get hasCachedReviewableAppointments => _reviewableAppointments.isNotEmpty;

  // Check if cache is still valid
  bool get isPatientReviewsCacheValid {
    if (_patientReviewsLastLoaded == null) return false;
    return DateTime.now().difference(_patientReviewsLastLoaded!) < _cacheValidDuration;
  }

  bool get isReviewableAppointmentsCacheValid {
    if (_reviewableAppointmentsLastLoaded == null) return false;
    return DateTime.now().difference(_reviewableAppointmentsLastLoaded!) < _cacheValidDuration;
  }

  bool isDoctorReviewsCacheValid(int doctorId) {
    final lastLoaded = _doctorReviewsLastLoaded[doctorId];
    if (lastLoaded == null) return false;
    return DateTime.now().difference(lastLoaded) < _cacheValidDuration;
  }

  /// Load initial review data after login (background operation)
  Future<void> loadInitialData(String userRole) async {
    try {
      if (userRole == 'patient') {
        unawaited(_loadPatientReviews());
        unawaited(_loadReviewableAppointments());
      }
      // Doctors don't need initial review data loaded
    } catch (e) {
      debugPrint('Error loading initial review data: $e');
    }
  }

  /// Get patient's own reviews with caching
  Future<List<Review>> getPatientReviews({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and no force refresh
    if (!forceRefresh && hasCachedPatientReviews && isPatientReviewsCacheValid) {
      return _patientReviews;
    }

    // Load fresh data
    await _loadPatientReviews();
    return _patientReviews;
  }

  /// Get reviewable appointments with caching
  Future<List<ReviewableAppointment>> getReviewableAppointments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCachedReviewableAppointments && isReviewableAppointmentsCacheValid) {
      return _reviewableAppointments;
    }

    await _loadReviewableAppointments();
    return _reviewableAppointments;
  }

  /// Get reviews for a specific doctor with caching
  Future<List<Review>> getDoctorReviews({
    required int doctorId,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and no force refresh (only for first page)
    if (!forceRefresh && page == 1 && _doctorReviews.containsKey(doctorId) && isDoctorReviewsCacheValid(doctorId)) {
      return _doctorReviews[doctorId]!;
    }

    // Load fresh data
    await _loadDoctorReviews(doctorId: doctorId, page: page, perPage: perPage);
    return _doctorReviews[doctorId] ?? [];
  }

  /// Get doctor rating stats with caching
  DoctorRatingStats? getDoctorRating(int doctorId) {
    return _doctorRatings[doctorId];
  }

  /// Load doctor rating stats
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

  /// Create new review and refresh cache
  Future<bool> createReview({
    required int appointmentId,
    required int rating,
    String? comment,
  }) async {
    if (_isSubmittingReview) return false;
    
    _isSubmittingReview = true;
    notifyListeners();

    try {
      final response = await ApiService.createReview(
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
      );

      if (response['success']) {
        // Remove appointment from reviewable appointments
        _removeReviewableAppointment(appointmentId);
        
        // Refresh patient reviews and reviewable appointments
        unawaited(_loadPatientReviews());
        unawaited(_loadReviewableAppointments());
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating review: $e');
      return false;
    } finally {
      _isSubmittingReview = false;
      notifyListeners();
    }
  }

  /// Update existing review and refresh cache
  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    if (_isSubmittingReview) return false;
    
    _isSubmittingReview = true;
    notifyListeners();

    try {
      final response = await ApiService.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );

      if (response['success']) {
        // Update review in cache immediately for better UX
        _updateReviewInCache(reviewId, rating, comment);
        
        // Then refresh from server
        unawaited(_loadPatientReviews());
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating review: $e');
      return false;
    } finally {
      _isSubmittingReview = false;
      notifyListeners();
    }
  }

  /// Delete review and refresh cache
  Future<bool> deleteReview(int reviewId) async {
    try {
      final response = await ApiService.deleteReview(reviewId);

      if (response['success']) {
        // Remove from cache immediately for better UX
        _removeReviewFromCache(reviewId);
        notifyListeners();
        
        // Then refresh from server
        unawaited(_loadPatientReviews());
        unawaited(_loadReviewableAppointments());
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Check if appointment can be reviewed
  bool canReviewAppointment(int appointmentId) {
    return _reviewableAppointments.any((appointment) => appointment.id == appointmentId);
  }

  /// Get reviewable appointment by ID
  ReviewableAppointment? getReviewableAppointment(int appointmentId) {
    try {
      return _reviewableAppointments.firstWhere((appointment) => appointment.id == appointmentId);
    } catch (e) {
      return null;
    }
  }

  /// Private method to load patient reviews
  Future<void> _loadPatientReviews() async {
    if (_isLoadingPatientReviews) return;
    
    _isLoadingPatientReviews = true;
    notifyListeners();

    try {
      final response = await ApiService.getPatientReviews();

      if (response['success']) {
        final reviewsData = response['data']['reviews'] as List? ?? [];
        _patientReviews = reviewsData.map((json) => Review.fromJson(json)).toList();
        _patientReviewsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading patient reviews: $e');
    } finally {
      _isLoadingPatientReviews = false;
      notifyListeners();
    }
  }

  /// Private method to load reviewable appointments
  Future<void> _loadReviewableAppointments() async {
    if (_isLoadingReviewableAppointments) return;
    
    _isLoadingReviewableAppointments = true;
    notifyListeners();

    try {
      final response = await ApiService.getReviewableAppointments();

      if (response['success']) {
        final appointmentsData = response['data']['appointments'] as List? ?? [];
        _reviewableAppointments = appointmentsData
            .map((json) => ReviewableAppointment.fromJson(json))
            .toList();
        _reviewableAppointmentsLastLoaded = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading reviewable appointments: $e');
    } finally {
      _isLoadingReviewableAppointments = false;
      notifyListeners();
    }
  }

  /// Private method to load doctor reviews
  Future<void> _loadDoctorReviews({
    required int doctorId,
    int page = 1,
    int perPage = 10,
  }) async {
    if (_isLoadingDoctorReviews) return;
    
    _isLoadingDoctorReviews = true;
    notifyListeners();

    try {
      final response = await ApiService.getDoctorReviews(
        doctorId: doctorId,
        page: page,
        perPage: perPage,
      );

      if (response['success']) {
        final reviewsData = response['data']['reviews'] as List? ?? [];
        final reviews = reviewsData.map((json) => Review.fromJson(json)).toList();
        
        if (page == 1) {
          // Replace cache for first page
          _doctorReviews[doctorId] = reviews;
          _doctorReviewsLastLoaded[doctorId] = DateTime.now();
        } else {
          // Append for additional pages
          _doctorReviews[doctorId] = (_doctorReviews[doctorId] ?? [])..addAll(reviews);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading doctor reviews: $e');
    } finally {
      _isLoadingDoctorReviews = false;
      notifyListeners();
    }
  }

  /// Helper method to remove reviewable appointment from cache
  void _removeReviewableAppointment(int appointmentId) {
    _reviewableAppointments.removeWhere((appointment) => appointment.id == appointmentId);
  }

  /// Helper method to update review in cache
  void _updateReviewInCache(int reviewId, int rating, String? comment) {
    final reviewIndex = _patientReviews.indexWhere((review) => review.id == reviewId);
    if (reviewIndex != -1) {
      final oldReview = _patientReviews[reviewIndex];
      // Create updated review (you'll need to add a copyWith method to Review model)
      // For now, we'll just reload from server
    }
  }

  /// Helper method to remove review from cache
  void _removeReviewFromCache(int reviewId) {
    _patientReviews.removeWhere((review) => review.id == reviewId);
    
    // Also remove from doctor reviews cache if present
    _doctorReviews.forEach((doctorId, reviews) {
      reviews.removeWhere((review) => review.id == reviewId);
    });
  }

  /// Get review count for patient
  int getPatientReviewCount() {
    return _patientReviews.length;
  }

  /// Get average rating given by patient
  double getPatientAverageRating() {
    if (_patientReviews.isEmpty) return 0.0;
    
    final totalRating = _patientReviews.fold<int>(0, (sum, review) => sum + review.rating);
    return totalRating / _patientReviews.length;
  }

  /// Get reviewable appointments count
  int getReviewableAppointmentsCount() {
    return _reviewableAppointments.length;
  }

  /// Force refresh all review data
  Future<void> refreshAllData(String userRole) async {
    _clearCache();
    await loadInitialData(userRole);
  }

  /// Clear all cached data
  void _clearCache() {
    _patientReviews.clear();
    _reviewableAppointments.clear();
    _doctorRatings.clear();
    _doctorReviews.clear();
    _doctorReviewsLastLoaded.clear();
    _patientReviewsLastLoaded = null;
    _reviewableAppointmentsLastLoaded = null;
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