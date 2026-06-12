import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../bloc/trips_bloc.dart';
import '../../../../core/utils/date_utils.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  const TripCard({super.key, required this.trip});

  static const _destinationImages = {
    'italy': 'https://images.unsplash.com/photo-1534445867742-43195f401b6c?w=600&q=80',
    'amalfi': 'https://images.unsplash.com/photo-1534445867742-43195f401b6c?w=600&q=80',
    'positano': 'https://images.unsplash.com/photo-1534445867742-43195f401b6c?w=600&q=80',
    'paris': 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=600&q=80',
    'india': 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=600&q=80',
    'bali': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600&q=80',
    'japan': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600&q=80',
    'default': 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=600&q=80',
  };

  String _imageUrl() {
    final d = trip.destination.toLowerCase();
    for (final key in _destinationImages.keys) {
      if (d.contains(key)) return _destinationImages[key]!;
    }
    return _destinationImages['default']!;
  }

  Color _accentColor() {
    switch (trip.status) {
      case 'active': return const Color(0xFF059669);
      case 'planning': return const Color(0xFF6B7280);
      case 'completed': return const Color(0xFF6B7280);
      default: return const Color(0xFF059669);
    }
  }

  String _statusLabel() {
    switch (trip.status) {
      case 'active': return 'Fully Booked';
      case 'planning': return 'Planning';
      case 'completed': return 'Completed';
      default: return trip.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/trips/${trip.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    _imageUrl(),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.image_outlined, size: 40, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: trip.status == 'active'
                          ? const Color(0xFF059669)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trip.status == 'active' ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  // Colored left accent bar
                  Container(
                    width: 3,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accentColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.destination,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              AppDateUtils.dateRange(trip.startDate, trip.endDate),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 22, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
