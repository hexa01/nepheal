import 'package:flutter/material.dart';
import '../../../shared/models/review.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/review_card_widget.dart';
import '../../../shared/widgets/rating_widget.dart';
import 'create_review_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Review> _myReviews = [];
  List<ReviewableAppointment> _reviewableAppointments = [];
  bool _isLoadingReviews = true;
  bool _isLoadingAppointments = true;
  String? _reviewsError;
  String? _appointmentsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyReviews(),
      _loadReviewableAppointments(),
    ]);
  }

  Future<void> _loadMyReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final response = await ApiService.getPatientReviews();

      if (response['success']) {
        final reviewsData = response['data']['reviews'] as List;
        setState(() {
          _myReviews =
              reviewsData.map((json) => Review.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _reviewsError = response['message'] ?? 'Failed to load your reviews';
        });
      }
    } catch (e) {
      setState(() {
        _reviewsError = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadReviewableAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    try {
      final response = await ApiService.getReviewableAppointments();

      if (response['success']) {
        final appointmentsData = response['data']['appointments'] as List;
        setState(() {
          _reviewableAppointments = appointmentsData
              .map((json) => ReviewableAppointment.fromJson(json))
              .toList();
        });
      } else {
        setState(() {
          _appointmentsError =
              response['message'] ?? 'Failed to load appointments';
        });
      }
    } catch (e) {
      setState(() {
        _appointmentsError = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoadingAppointments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'My Reviews'),
            Tab(text: 'Write Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyReviewsTab(),
          _buildWriteReviewTab(),
        ],
      ),
    );
  }

  Widget _buildMyReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyReviews,
      child: _isLoadingReviews
          ? const Center(child: CircularProgressIndicator())
          : _reviewsError != null
              ? _buildErrorState(
                  error: _reviewsError!,
                  onRetry: _loadMyReviews,
                )
              : _myReviews.isEmpty
                  ? _buildEmptyReviewsState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myReviews.length,
                      itemBuilder: (context, index) {
                        final review = _myReviews[index];
                        return ReviewCard(
                          review: review,
                          showDoctorName: true,
                          showActions: true,
                          onEdit: () => _editReview(review),
                          onDelete: () => _deleteReview(review),
                        );
                      },
                    ),
    );
  }

  Widget _buildWriteReviewTab() {
    return RefreshIndicator(
      onRefresh: _loadReviewableAppointments,
      child: _isLoadingAppointments
          ? const Center(child: CircularProgressIndicator())
          : _appointmentsError != null
              ? _buildErrorState(
                  error: _appointmentsError!,
                  onRetry: _loadReviewableAppointments,
                )
              : _reviewableAppointments.isEmpty
                  ? _buildNoAppointmentsState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviewableAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _reviewableAppointments[index];
                        return _buildReviewableAppointmentCard(appointment);
                      },
                    ),
    );
  }

  Widget _buildEmptyReviewsState() {
    return EmptyReviewsWidget(
      title: 'No Reviews Yet',
      subtitle:
          'You haven\'t written any reviews.\nComplete appointments to write reviews.',
      icon: Icons.rate_review,
      actionText: 'Find Doctors',
      onAction: () {
        // Navigate to find doctors
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildNoAppointmentsState() {
    return EmptyReviewsWidget(
      title: 'No Appointments to Review',
      subtitle:
          'Complete appointments with doctors to write reviews about your experience.',
      icon: Icons.assignment_turned_in,
      actionText: 'Book Appointment',
      onAction: () {
        // Navigate to find doctors
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
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
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
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

  Widget _buildReviewableAppointmentCard(ReviewableAppointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.blue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Icon(
                    Icons.rate_review,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Share your experience',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '#${appointment.id}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Doctor Info
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade200],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          appointment.doctor.specialization,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Appointment Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(appointment.appointmentDate)} at ${_formatTime(appointment.slot)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Write Review Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _writeReview(appointment),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'Write Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.blue.withValues(alpha: 0.3),
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  Future<void> _writeReview(ReviewableAppointment appointment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(appointment: appointment),
      ),
    );

    // Refresh data if review was successfully submitted
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _editReview(Review review) async {
    // Show edit dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditReviewDialog(review: review),
    );

    if (result != null) {
      try {
        final response = await ApiService.updateReview(
          reviewId: review.id,
          rating: result['rating'],
          comment: result['comment'],
        );

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Review updated successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          await _loadMyReviews();
        } else {
          throw Exception(response['message'] ?? 'Failed to update review');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Review'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your review for Dr. ${review.doctorName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteReview(review.id);

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Review deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          await _loadMyReviews();
        } else {
          throw Exception(response['message'] ?? 'Failed to delete review');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

class _EditReviewDialog extends StatefulWidget {
  final Review review;

  const _EditReviewDialog({required this.review});

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _commentController =
        TextEditingController(text: widget.review.comment ?? '');
    _rating = widget.review.rating;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Review'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InteractiveRatingWidget(
              initialRating: _rating,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
              size: 32,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: 'Update your review...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0
              ? () {
                  Navigator.of(context).pop({
                    'rating': _rating,
                    'comment': _commentController.text.trim().isEmpty
                        ? null
                        : _commentController.text.trim(),
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
