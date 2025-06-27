import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color? color;
  final bool showRating;
  final String? label;
  final MainAxisAlignment alignment;

  const RatingWidget({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 16,
    this.color,
    this.showRating = false,
    this.label,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.amber;

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(starCount, (index) {
            return Icon(
              index < rating.floor()
                  ? Icons.star
                  : index < rating
                      ? Icons.star_half
                      : Icons.star_border,
              color: effectiveColor,
              size: size,
            );
          }),
        ),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingWidget extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final int starCount;
  final double size;
  final Color? color;
  final String? label;

  const InteractiveRatingWidget({
    super.key,
    required this.onRatingChanged,
    this.initialRating = 0,
    this.starCount = 5,
    this.size = 32,
    this.color,
    this.label,
  });

  @override
  State<InteractiveRatingWidget> createState() =>
      _InteractiveRatingWidgetState();
}

class _InteractiveRatingWidgetState extends State<InteractiveRatingWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Colors.amber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.starCount, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = index + 1;
                });
                widget.onRatingChanged(_currentRating);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  index < _currentRating ? Icons.star : Icons.star_border,
                  color: index < _currentRating
                      ? effectiveColor
                      : Colors.grey.shade400,
                  size: widget.size,
                ),
              ),
            );
          }),
        ),
        if (_currentRating > 0) ...[
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(_currentRating),
            style: TextStyle(
              fontSize: 14,
              color: effectiveColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

class RatingBreakdownWidget extends StatelessWidget {
  final Map<int, int> ratingBreakdown;
  final int totalReviews;
  final double maxBarWidth;

  const RatingBreakdownWidget({
    super.key,
    required this.ratingBreakdown,
    required this.totalReviews,
    this.maxBarWidth = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return const Text(
        'No reviews yet',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index; // Show 5 stars first, then 4, 3, 2, 1
        final count = ratingBreakdown[rating] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$rating',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
