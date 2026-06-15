import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/di/injection.dart';

class DocumentsPage extends StatefulWidget {
  final String tripId;
  const DocumentsPage({super.key, required this.tripId});
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<Map<String, dynamic>> _docs = [];
  List<Map<String, dynamic>> _checklist = [];
  bool _loading = true;
  bool _checklistLoading = true;
  bool _uploading = false;
  String _selectedType = 'confirmation';

  @override
  void initState() {
    super.initState();
    _load();
    _loadChecklist();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/documents') as List;
      setState(() { _docs = data.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _loadChecklist() async {
    setState(() => _checklistLoading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/checklist/documents') as List;
      setState(() { _checklist = data.cast<Map<String, dynamic>>(); _checklistLoading = false; });
    } catch (_) { setState(() => _checklistLoading = false); }
  }

  Future<void> _toggleChecklist(String itemId, bool checked) async {
    try {
      await sl<ApiClient>().put('/trips/${widget.tripId}/checklist/documents', data: {
        'itemId': itemId,
        'checked': checked
      });
      _loadChecklist();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp']);
    if (result == null || result.files.single.path == null) return;
    setState(() => _uploading = true);
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(result.files.single.path!, filename: result.files.single.name),
        'doc_type': _selectedType,
      });
      await sl<ApiClient>().upload('/trips/${widget.tripId}/documents', form);
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error));
    } finally { setState(() => _uploading = false); }
  }

  Future<void> _delete(String id) async {
    await sl<ApiClient>().delete('/trips/${widget.tripId}/documents/$id');
    _load();
  }

  static const _docIcons = {
    'confirmation': Icons.confirmation_number_outlined,
    'passport': Icons.badge_outlined,
    'insurance': Icons.health_and_safety_outlined,
    'other': Icons.attach_file_rounded,
  };
  static const _docColors = {
    'confirmation': AppColors.primary,
    'passport': AppColors.accent,
    'insurance': AppColors.secondary,
    'other': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Documents'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}')),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Files'),
              Tab(text: 'Checklist'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _filesTab(),
            _checklistTab(),
          ],
        ),
      ),
    );
  }

  Widget _filesTab() => Column(
        children: [
          // Upload bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document Type', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.docTypes.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(t), selected: _selectedType == t, onSelected: (_) => setState(() => _selectedType = t)),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _pick,
                  icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload_file_rounded),
                  label: Text(_uploading ? 'Uploading...' : 'Upload Document'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _docs.isEmpty
                    ? const EmptyState(icon: Icons.folder_outlined, title: 'No documents', subtitle: 'Upload confirmation emails, passport copies, and insurance documents')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final doc = _docs[i];
                          final type = doc['doc_type'] ?? 'other';
                          return AppCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: (_docColors[type] ?? AppColors.textSecondary).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(_docIcons[type] ?? Icons.attach_file_rounded, color: _docColors[type] ?? AppColors.textSecondary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc['original_name'] ?? 'Document', style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(type, style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20), onPressed: () => _delete(doc['id'])),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      );

  Widget _checklistTab() => _checklistLoading
      ? const Center(child: CircularProgressIndicator())
      : _checklist.isEmpty
          ? const EmptyState(icon: Icons.checklist_rounded, title: 'No checklist', subtitle: 'Checklist not initialized')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _checklist.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = _checklist[i];
                final done = item['checked'] == 1;
                return AppCard(
                  child: CheckboxListTile(
                    title: Text(item['label'] ?? '', style: AppTextStyles.labelLarge.copyWith(decoration: done ? TextDecoration.lineThrough : null)),
                    value: done,
                    onChanged: (val) => _toggleChecklist(item['id'], val ?? false),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            );
}
