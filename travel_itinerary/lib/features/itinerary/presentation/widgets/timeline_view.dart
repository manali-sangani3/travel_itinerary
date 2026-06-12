import 'package:flutter/material.dart';
import '../bloc/itinerary_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TimelineView extends StatelessWidget {
  final List<ItineraryItem> items;
  const TimelineView({super.key, required this.items});

  static const _hours = 24;
  static const _hourH = 60.0;

  int _timeToMinutes(String? t) {
    if (t == null) return 0;
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: _hours * _hourH,
        child: Stack(
          children: [
            // Hour grid
            ...List.generate(_hours, (h) => Positioned(
              top: h * _hourH,
              left: 0, right: 0,
              child: Row(
                children: [
                  SizedBox(width: 44, child: Text('${h.toString().padLeft(2, '0')}:00', style: AppTextStyles.caption)),
                  Expanded(child: Container(height: 1, color: AppColors.divider)),
                ],
              ),
            )),
            // Activity blocks
            ...items.map((item) {
              final start = _timeToMinutes(item.startTime);
              final end = item.endTime != null ? _timeToMinutes(item.endTime) : start + 60;
              final top = start / 60 * _hourH;
              final height = (end - start) / 60 * _hourH;
              return Positioned(
                top: top,
                left: 52,
                right: 8,
                height: height.clamp(32, double.infinity),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (item.location != null && height > 40)
                        Text(item.location!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }),
            // Current time indicator
            Positioned(
              top: (TimeOfDay.now().hour * 60 + TimeOfDay.now().minute) / 60 * _hourH,
              left: 44,
              right: 0,
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                  Expanded(child: Container(height: 1.5, color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
