import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/di/injection.dart';

class PhotoGalleryPage extends StatefulWidget {
  final String tripId;
  const PhotoGalleryPage({super.key, required this.tripId});
  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;
  bool _uploading = false;
  final _picker = ImagePicker();
  String _groupBy = 'date'; // 'date' or 'location'

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/photos') as List;
      setState(() { _photos = data.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _pickAndUpload() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    // Ask location tag via small dialog
    final tagController = TextEditingController();
    final String? locationTag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location Tag'),
        content: TextFormField(
          controller: tagController,
          decoration: const InputDecoration(hintText: 'e.g. Louvre Museum'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
          TextButton(onPressed: () => Navigator.pop(context, tagController.text.trim()), child: const Text('Add')),
        ],
      ),
    );

    setState(() => _uploading = true);
    try {
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(image.path, filename: image.name),
        if (locationTag != null && locationTag.isNotEmpty) 'locationTag': locationTag,
      });
      await sl<ApiClient>().upload('/trips/${widget.tripId}/photos', form);
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error));
    } finally { setState(() => _uploading = false); }
  }

  Future<void> _deletePhoto(String photoId) async {
    try {
      await sl<ApiClient>().delete('/trips/${widget.tripId}/photos/$photoId');
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error));
    }
  }

  void _viewPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}/journal')),
        actions: [
          IconButton(
            icon: Icon(_groupBy == 'date' ? Icons.map_outlined : Icons.calendar_month_outlined),
            onPressed: () => setState(() => _groupBy = _groupBy == 'date' ? 'location' : 'date'),
            tooltip: _groupBy == 'date' ? 'Group by Location' : 'Group by Date',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const EmptyState(icon: Icons.photo_library_outlined, title: 'No photos yet', subtitle: 'Upload memories from your trip')
              : Column(
                  children: [
                    if (_uploading) const LinearProgressIndicator(color: AppColors.primary),
                    Expanded(child: _photoGrid()),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _pickAndUpload,
        backgroundColor: const Color(0xFF111827),
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
    );
  }

  Widget _photoGrid() {
    // Group photos based on toggle
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final p in _photos) {
      final key = _groupBy == 'date'
          ? (p['date_taken']?.toString().split(' ')[0] ?? 'Unknown Date')
          : (p['location_tag'] ?? 'Unassigned Location');
      groups.putIfAbsent(key, () => []).add(p);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, idx) {
        final groupTitle = sortedKeys[idx];
        final items = groups[groupTitle]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(groupTitle, style: AppTextStyles.h4),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final photo = items[i];
                final url = "${AppConstants.baseUrl}/${photo['file_path']}";
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _viewPhoto(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 14),
                          onPressed: () => _deletePhoto(photo['id']),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
