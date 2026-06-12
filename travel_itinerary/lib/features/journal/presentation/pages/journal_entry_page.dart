import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/di/injection.dart';

class JournalEntryPage extends StatefulWidget {
  final String tripId;
  const JournalEntryPage({super.key, required this.tripId});
  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _body = TextEditingController();
  DateTime _date = DateTime.now();
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void dispose() { _body.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _photos.add(img));
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty && _photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something or add a photo')));
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await sl<ApiClient>().post('/trips/${widget.tripId}/journal', data: {
        'entry_date': DateFormat('yyyy-MM-dd').format(_date),
        'body': _body.text.trim(),
      });
      final entryId = res['id'];
      for (final photo in _photos) {
        final form = FormData.fromMap({'photo': await MultipartFile.fromFile(photo.path, filename: photo.name)});
        await sl<ApiClient>().upload('/trips/${widget.tripId}/journal/$entryId/photos', form);
      }
      if (mounted) context.go('/trips/${widget.tripId}/journal');
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}/journal')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(DateFormat('EEEE, dd MMMM yyyy').format(_date), style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Write about your day',
              hint: 'What did you do today? What did you feel? What will you remember?',
              controller: _body,
              maxLines: 8,
            ),
            const SizedBox(height: 20),

            // Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Photos', style: AppTextStyles.h4),
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Add Photo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photos.isEmpty)
              InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity, height: 120,
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider, style: BorderStyle.solid)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    Text('Tap to add photos', style: AppTextStyles.bodySmall),
                  ]),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    if (i == _photos.length) return InkWell(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 90, height: 110,
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                        child: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
                      ),
                    );
                    return Stack(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(width: 90, height: 110, color: AppColors.primaryLight, child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 36))),
                        Positioned(top: 4, right: 4, child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 16, color: Colors.white)),
                        )),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
            AppButton(label: 'Save Entry', loading: _saving, onPressed: _save),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
