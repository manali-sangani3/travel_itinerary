import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/trips_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

class CreateTripPage extends StatefulWidget {
  final String? tripId;
  const CreateTripPage({super.key, this.tripId});
  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _form = GlobalKey<FormState>();
  final _destination = TextEditingController();
  final _purpose = TextEditingController();
  final _companion = TextEditingController();
  DateTime? _startDate, _endDate;
  String _status = 'planning';
  final List<String> _companions = [];

  @override
  void dispose() { _destination.dispose(); _purpose.dispose(); _companion.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => isStart ? _startDate = d : _endDate = d);
  }

  void _addCompanion() {
    if (_companion.text.trim().isEmpty) return;
    setState(() { _companions.add(_companion.text.trim()); _companion.clear(); });
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select travel dates')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date')));
      return;
    }
    context.read<TripsBloc>().add(TripCreateRequested({
      'destination': _destination.text.trim(),
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'purpose': _purpose.text.trim(),
      'companions': _companions,
      'status': _status,
    }));
    context.go('/trips');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/trips')),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Destination',
                hint: 'e.g. Paris, France',
                controller: _destination,
                validator: (v) => Validators.required(v, 'Destination'),
                prefix: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Date range
              Text('Travel Dates', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _DateBox(label: 'Start', date: _startDate, onTap: () => _pickDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateBox(label: 'End', date: _endDate, onTap: () => _pickDate(false))),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Purpose',
                hint: 'e.g. Vacation, Business, Honeymoon',
                controller: _purpose,
                prefix: const Icon(Icons.work_outline_rounded, size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Status
              Text('Trip Status', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.tripStatuses.map((s) => ChoiceChip(
                  label: Text(s),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Companions
              Text('Travel Companions', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _companion,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(hintText: 'Add companion name'),
                    onFieldSubmitted: (_) => _addCompanion(),
                  )),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _addCompanion, icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(backgroundColor: AppColors.primary)),
                ],
              ),
              if (_companions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _companions.map((c) => Chip(
                    label: Text(c),
                    onDeleted: () => setState(() => _companions.remove(c)),
                    deleteIconColor: AppColors.textSecondary,
                  )).toList(),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(label: 'Create Trip', onPressed: _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateBox({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: date != null ? AppColors.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: date != null ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(date != null ? DateFormat('dd MMM yyyy').format(date!) : 'Select', style: AppTextStyles.bodySmall.copyWith(color: date != null ? AppColors.textPrimary : AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
