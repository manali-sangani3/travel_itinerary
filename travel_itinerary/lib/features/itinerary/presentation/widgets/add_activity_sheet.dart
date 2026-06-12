import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/itinerary_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';

class AddActivitySheet extends StatefulWidget {
  final String tripId;
  final int dayIndex;
  const AddActivitySheet({super.key, required this.tripId, required this.dayIndex});
  @override
  State<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<AddActivitySheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  TimeOfDay? _startTime, _endTime;

  @override
  void dispose() { _title.dispose(); _location.dispose(); super.dispose(); }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => isStart ? _startTime = t : _endTime = t);
  }

  String _fmt(TimeOfDay? t) => t == null ? 'Pick time' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<ItineraryBloc>().add(ItineraryItemAdded(widget.tripId, {
      'title': _title.text.trim(),
      'location': _location.text.trim(),
      'day_index': widget.dayIndex,
      'order_index': 999,
      'start_time': _startTime != null ? _fmt(_startTime) : null,
      'end_time': _endTime != null ? _fmt(_endTime) : null,
    }));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Activity — Day ${widget.dayIndex + 1}', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Activity Name',
              hint: 'e.g. Eiffel Tower Visit',
              controller: _title,
              validator: (v) => Validators.required(v, 'Activity name'),
              prefix: const Icon(Icons.event_outlined, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Location',
              hint: 'e.g. Champ de Mars, Paris',
              controller: _location,
              prefix: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text('Time Slot', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _TimeBtn(label: 'Start', value: _fmt(_startTime), onTap: () => _pickTime(true))),
                const SizedBox(width: 12),
                Expanded(child: _TimeBtn(label: 'End', value: _fmt(_endTime), onTap: () => _pickTime(false))),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Add Activity', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _TimeBtn({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
          ]),
        ],
      ),
    ),
  );
}
