import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/di/injection.dart';

class AddExpensePage extends StatefulWidget {
  final String tripId;
  const AddExpensePage({super.key, required this.tripId});
  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _form = GlobalKey<FormState>();
  String _category = 'food';
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'INR');
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _amount.dispose(); _currency.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await sl<ApiClient>().post('/trips/${widget.tripId}/budget/expenses', data: {
        'id': const Uuid().v4(),
        'category': _category,
        'amount': double.parse(_amount.text),
        'currency': _currency.text.trim().toUpperCase(),
        'note': _note.text.trim(),
      });
      if (mounted) context.go('/trips/${widget.tripId}/budget');
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Expense'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}/budget')),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: AppConstants.budgetCategories.map((c) => ChoiceChip(
                  label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c),
                )).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 90, child: AppTextField(label: 'Currency', hint: 'INR', controller: _currency)),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(label: 'Amount', hint: '0.00', controller: _amount, keyboardType: TextInputType.number, validator: Validators.amount)),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Note (optional)', hint: 'e.g. Dinner at Le Jules Verne', controller: _note, maxLines: 2),
              const SizedBox(height: 32),
              AppButton(label: 'Log Expense', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
