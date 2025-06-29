import 'package:flutter/material.dart';
import '../../../shared/models/review.dart';
import '../../../shared/models/doctor.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/rating_widget.dart';
import '../../../shared/widgets/review_card_widget.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

class DoctorReviewsScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorReviewsScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  List<Review> _reviews = [];
  DoctorRatingStats? _ratingStats;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreReviews = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMoreReviews) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both reviews and rating stats
      final futures = await Future.wait([
        ApiService.getDoctorReviews(doctorId: widget.doctor.id, page: 1),
        ApiService.getDoctorRatingStats(widget.doctor.id),
      ]);

      final reviewsResponse = futures[0];
      final statsResponse = futures[1];

      if (reviewsResponse['success']) {
        final reviewsData = reviewsResponse['data']['reviews'] as List;
        setState(() {
          _reviews = reviewsData.map((json) => Review.fromJson(json)).toList();
          _hasMoreReviews = reviewsData.length >= 10; // Assuming 10 per page
          _currentPage = 1;
        });
      }

      if (statsResponse['success']) {
        setState(() {
          _ratingStats = DoctorRatingStats.fromJson(statsResponse['data']);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load reviews. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMoreReviews) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.getDoctorReviews(
        doctorId: widget.doctor.id,
        page: nextPage,
      );

      if (response['success']) {
        final newReviews = (response['data']['reviews'] as List)
            .map((json) => Review.fromJson(json))
            .toList();

        setState(() {
          _reviews.addAll(newReviews);
          _currentPage = nextPage;
          _hasMoreReviews = newReviews.length >= 10;
        });
      }
    } catch (e) {
      // Show error but don't block the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load more reviews'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.doctor.name} Reviews'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Doctor Header
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Doctor Info
                                Row(
                                  children: [
                                    CompactProfileAvatar(
                                      imageUrl:
                                          widget.doctor.user?.profilePhotoUrl,
                                      initials: widget.doctor.user?.initials ??
                                          widget.doctor.name
                                              .split(' ')
                                              .map((n) => n[0])
                                              .take(2)
                                              .join()
                                              .toUpperCase(),
                                      size: 70,
                                      backgroundColor: Colors.blue.shade100,
                                      textColor: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.doctor.name,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              widget.doctor.specializationName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Rating Summary
                                if (_ratingStats != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            // Overall Rating
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  Text(
                                                    _ratingStats!.averageRating
                                                        .toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 48,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  RatingWidget(
                                                    rating: _ratingStats!
                                                        .averageRating,
                                                    size: 20,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '${_ratingStats!.totalReviews} reviews',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.9),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Rating Breakdown
                                            Expanded(
                                              flex: 2,
                                              child: RatingBreakdownWidget(
                                                ratingBreakdown: _ratingStats!
                                                    .ratingBreakdown,
                                                totalReviews:
                                                    _ratingStats!.totalReviews,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Reviews Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Patient Reviews',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_reviews.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    '${_reviews.length} shown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Reviews List
                      if (_reviews.isEmpty)
                        SliverFillRemaining(
                          child: EmptyReviewsWidget(
                            title: 'No Reviews Yet',
                            subtitle:
                                'Be the first to review Dr. ${widget.doctor.name}',
                            icon: Icons.star_border,
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index < _reviews.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  child: ReviewCard(
                                    review: _reviews[index],
                                    showDoctorName: false,
                                  ),
                                );
                              } else if (_isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (!_hasMoreReviews &&
                                  _reviews.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'All reviews loaded',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            childCount:
                                _reviews.length + (_isLoadingMore ? 1 : 1),
                          ),
                        ),

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                    ],
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
              'Unable to Load Reviews',
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
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
}
