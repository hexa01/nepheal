import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/review_service.dart';
import '../../../shared/models/review.dart';

class DoctorReviewsScreen extends StatefulWidget {
  const DoctorReviewsScreen({super.key});

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  // UI filter state variables
  int? _selectedRating;
  String _sortBy = 'newest';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  // Local data storage
  List<Review> _allDoctorReviews = [];
  List<Review> _filteredReviews = [];
  
  // Current doctor data
  int? _currentDoctorId;
  bool _isInitialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
    });

    try {
      // Get current doctor's ID first
      final doctorProfile = await ApiService.getDoctorProfile();
      final doctorId = doctorProfile['data']['doctor']['doctor_id'];
      
      setState(() {
        _currentDoctorId = doctorId;
      });

      if (mounted) {
        final reviewService = Provider.of<ReviewService>(context, listen: false);
        
        // Load reviews and rating stats
        final reviews = await reviewService.getDoctorReviews(doctorId: doctorId);
        await reviewService.loadDoctorRating(doctorId);

        setState(() {
          _allDoctorReviews = reviews;
        });

        // Apply filters after loading
        _applyFilters();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading reviews: $e';
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReviews = _allDoctorReviews.where((review) {
        // Rating filter
        if (_selectedRating != null && review.rating != _selectedRating) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final comment = review.comment?.toLowerCase() ?? '';
          final patientName = review.patientName?.toLowerCase() ?? '';
          
          if (!comment.contains(query) && !patientName.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      switch (_sortBy) {
        case 'newest':
          _filteredReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'oldest':
          _filteredReviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'highest_rating':
          _filteredReviews.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'lowest_rating':
          _filteredReviews.sort((a, b) => a.rating.compareTo(b.rating));
          break;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedRating = null;
      _searchQuery = '';
      _searchController.clear();
      _sortBy = 'newest';
      _showFilters = false;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('My Reviews'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('My Reviews'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReviews,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<ReviewService>(
      builder: (context, reviewService, child) {
        final isLoading = reviewService.isLoadingDoctorReviews;
        final ratingStats = _currentDoctorId != null 
            ? reviewService.getDoctorRating(_currentDoctorId!)
            : null;
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('My Reviews'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Compact Stats Header
              _buildCompactStats(ratingStats),
              
              // Filters Section
              _buildFiltersSection(),
              
              // Reviews List
              Expanded(
                child: _buildReviewsList(isLoading),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStats(DoctorRatingStats? ratingStats) {
    final averageRating = ratingStats?.averageRating ?? 0.0;
    final totalReviews = ratingStats?.totalReviews ?? 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Average Rating',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          // Total Reviews
          Expanded(
            child: Column(
              children: [
                Text(
                  totalReviews.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          // Filtered Count
          Expanded(
            child: Column(
              children: [
                Text(
                  _filteredReviews.length.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Showing',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar with Filter Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reviews...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Filter Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: _showFilters ? Colors.green : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showFilters ? Colors.green : Colors.grey.shade300,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _showFilters ? Colors.white : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  tooltip: 'Filters',
                ),
              ),
            ],
          ),
          
          // Collapsible Filter Options
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters ? Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Rating Filter
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedRating,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Rating',
                          prefixIcon: Icon(Icons.star, size: 16, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All', overflow: TextOverflow.ellipsis),
                          ),
                          ...List.generate(5, (index) {
                            final rating = 5 - index;
                            return DropdownMenuItem<int?>(
                              value: rating,
                              child: Text('$rating★', overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRating = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Sort Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Sort',
                          prefixIcon: Icon(Icons.sort, size: 16, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'newest', 
                            child: Text('Newest', overflow: TextOverflow.ellipsis)
                          ),
                          DropdownMenuItem(
                            value: 'oldest', 
                            child: Text('Oldest', overflow: TextOverflow.ellipsis)
                          ),
                          DropdownMenuItem(
                            value: 'highest_rating', 
                            child: Text('High★', overflow: TextOverflow.ellipsis)
                          ),
                          DropdownMenuItem(
                            value: 'lowest_rating', 
                            child: Text('Low★', overflow: TextOverflow.ellipsis)
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Filter Actions
                Row(
                  children: [
                    // Active Filters Indicator
                    if (_selectedRating != null || _searchQuery.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, size: 16, color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Showing ${_filteredReviews.length} of ${_allDoctorReviews.length} reviews',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                    
                    const SizedBox(width: 8),
                    
                    // Clear Filters Button
                    if (_selectedRating != null || _searchQuery.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(bool isLoading) {
    if (isLoading && _filteredReviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedRating != null
                  ? 'No reviews match your filters'
                  : 'No reviews yet',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_searchQuery.isNotEmpty || _selectedRating != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final reviewService = Provider.of<ReviewService>(context, listen: false);
        if (_currentDoctorId != null) {
          final reviews = await reviewService.getDoctorReviews(
            doctorId: _currentDoctorId!, 
            forceRefresh: true
          );
          await reviewService.loadDoctorRating(_currentDoctorId!);
          
          setState(() {
            _allDoctorReviews = reviews;
          });
          _applyFilters();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredReviews.length,
        itemBuilder: (context, index) {
          final review = _filteredReviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    review.patientInitials ?? 'P',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.patientName ?? 'Anonymous Patient',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(review.rating).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        review.rating.toString(),
                        style: TextStyle(
                          color: _getRatingColor(review.rating),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: _getRatingColor(review.rating),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            
            // Action Row
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  onPressed: () {
                    _showReplyDialog(review);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    _showOptionsMenu(review);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  void _showReplyDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Review'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your professional reply...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply feature coming soon!')),
              );
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(Review review) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Review'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Details'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}