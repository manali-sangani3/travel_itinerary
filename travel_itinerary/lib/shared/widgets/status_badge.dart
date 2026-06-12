import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  static const _map = {
    'planning': (AppColors.planning, Color(0xFFEDE9FE)),
    'active': (AppColors.active, AppColors.secondaryLight),
    'completed': (AppColors.completed, AppColors.surfaceVariant),
    'viewer': (AppColors.textSecondary, AppColors.surfaceVariant),
    'editor': (AppColors.primary, AppColors.primaryLight),
    'admin': (AppColors.accent, AppColors.accentLight),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _map[status] ?? (AppColors.textSecondary, AppColors.surfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colors.$2, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: AppTextStyles.labelSmall.copyWith(color: colors.$1)),
    );
  }
}
