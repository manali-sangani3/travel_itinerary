import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/di/injection.dart';

class JournalPage extends StatefulWidget {
  final String tripId;
  const JournalPage({super.key, required this.tripId});
  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/journal') as List;
      setState(() { _entries = data.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _delete(String id) async {
    await sl<ApiClient>().delete('/trips/${widget.tripId}/journal/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Journal'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}')),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppCard(
                    onTap: () => context.go('/trips/${widget.tripId}/journal/notes'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Notes', style: AppTextStyles.labelLarge),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    onTap: () => context.go('/trips/${widget.tripId}/journal/gallery'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Gallery', style: AppTextStyles.labelLarge),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? EmptyState(
                        icon: Icons.book_outlined,
                        title: 'No journal entries yet',
                        subtitle: 'Write about your travel experiences and upload photos',
                        actionLabel: 'Write Entry',
                        onAction: () => context.go('/trips/${widget.tripId}/journal/entry'),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      final photos = List<dynamic>.from(e['photos'] ?? []);
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                  child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(AppDateUtils.formatDayShort(DateTime.tryParse(e['entry_date'] ?? '') ?? DateTime.now()), style: AppTextStyles.labelLarge),
                                  Text(AppDateUtils.timeAgo(DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now()), style: AppTextStyles.bodySmall),
                                ])),
                                PopupMenuButton(
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                  ],
                                  onSelected: (v) { if (v == 'delete') _delete(e['id']); },
                                ),
                              ],
                            ),
                            if (e['body'] != null && e['body'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(e['body'], style: AppTextStyles.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                            ],
                            if (photos.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 80,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (_, pi) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 80, height: 80,
                                      color: AppColors.primaryLight,
                                      child: const Icon(Icons.image_outlined, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/trips/${widget.tripId}/journal/entry'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
