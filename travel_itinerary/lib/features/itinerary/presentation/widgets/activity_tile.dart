import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/itinerary_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ActivityTile extends StatelessWidget {
  final ItineraryItem item;
  final String tripId;
  final bool isFirst, isLast;
  const ActivityTile({super.key, required this.item, required this.tripId, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline connector
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Expanded(child: Container(width: 2, color: isFirst ? Colors.transparent : AppColors.divider)),
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : AppColors.divider)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppTextStyles.labelLarge),
                          if (item.location != null && item.location!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(item.location!, style: AppTextStyles.bodySmall),
                            ]),
                          ],
                          if (item.startTime != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text('${item.startTime}${item.endTime != null ? ' – ${item.endTime}' : ''}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    // Drag handle + actions
                    Column(
                      children: [
                        const Icon(Icons.drag_handle_rounded, color: AppColors.textHint, size: 20),
                        const SizedBox(height: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                          ],
                          onSelected: (v) {
                            if (v == 'delete') context.read<ItineraryBloc>().add(ItineraryItemDeleted(tripId, item.id));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
