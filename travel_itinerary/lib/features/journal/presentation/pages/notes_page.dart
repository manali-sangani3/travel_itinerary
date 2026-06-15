import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/di/injection.dart';

class NotesPage extends StatefulWidget {
  final String tripId;
  const NotesPage({super.key, required this.tripId});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  final _contentCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _contentCtrl.dispose(); _locationCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/notes') as List;
      setState(() { _notes = data.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _addNote() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    try {
      await sl<ApiClient>().post('/trips/${widget.tripId}/notes', data: {
        'content': _contentCtrl.text.trim(),
        'locationTag': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim()
      });
      _contentCtrl.clear();
      _locationCtrl.clear();
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await sl<ApiClient>().delete('/trips/${widget.tripId}/notes/$id');
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Notes & Memories'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}/journal')),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Create note panel
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add reflection or memory', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentCtrl,
                  maxLines: 3,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'What are you reflecting on right now?')
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Location tag (optional)', prefixIcon: Icon(Icons.location_on_outlined, size: 20))
                ),
                const SizedBox(height: 12),
                AppButton(label: 'Save Memory', onPressed: _addNote),
              ],
            ),
          ),
          const Divider(height: 1),
          // Notes list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const EmptyState(icon: Icons.note_alt_outlined, title: 'No reflections yet', subtitle: 'Capture your thoughts, ideas, and memories about this trip')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final note = _notes[i];
                          final created = note['created_at']?.toString().split(' ')[0] ?? '';
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (note['location_tag'] != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(note['location_tag'], style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                                        ],
                                      )
                                    else
                                      const SizedBox(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      onPressed: () => _deleteNote(note['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(note['content'] ?? '', style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(created, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
