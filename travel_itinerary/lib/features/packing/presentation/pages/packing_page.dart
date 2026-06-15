import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/di/injection.dart';

class PackingPage extends StatefulWidget {
  final String tripId;
  const PackingPage({super.key, required this.tripId});
  @override
  State<PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends State<PackingPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final _labelCtrl = TextEditingController();
  final _catCtrl = TextEditingController();

  static const _presets = {
    'Essentials': ['Passport', 'Phone charger', 'Power bank', 'Travel adaptor', 'Wallet', 'ID proof'],
    'Clothing': ['T-shirts', 'Trousers', 'Socks', 'Underwear', 'Jacket', 'Comfortable shoes'],
    'Toiletries': ['Toothbrush', 'Toothpaste', 'Shampoo', 'Sunscreen', 'Deodorant'],
    'Health': ['Medicines', 'First aid kit', 'Hand sanitizer', 'Face masks'],
  };

  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadTemplates();
  }
  @override
  void dispose() { _labelCtrl.dispose(); _catCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/packing') as List;
      setState(() { _items = data.cast(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _loadTemplates() async {
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/packing/templates') as List;
      setState(() { _templates = data.cast(); });
    } catch (_) {}
  }

  Future<void> _generateFromTemplate(String templateId) async {
    setState(() => _loading = true);
    try {
      await sl<ApiClient>().post('/trips/${widget.tripId}/packing/generate', data: {'templateId': templateId});
      _load();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failed: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showTemplatesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate from Template'),
        content: _templates.isEmpty
            ? const Text('No templates available.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _templates.length,
                  itemBuilder: (context, i) {
                    final t = _templates[i];
                    return ListTile(
                      title: Text(t['name'] ?? ''),
                      subtitle: Text('${(t['items'] as List).length} items'),
                      onTap: () {
                        Navigator.pop(context);
                        _generateFromTemplate(t['id']);
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _add(String label, String? category) async {
    await sl<ApiClient>().post('/trips/${widget.tripId}/packing', data: {'label': label, 'category': category});
    _load();
  }

  Future<void> _toggle(String id, bool checked) async {
    await sl<ApiClient>().put('/trips/${widget.tripId}/packing/$id', data: {'checked': checked ? 1 : 0});
    _load();
  }

  Future<void> _delete(String id) async {
    await sl<ApiClient>().delete('/trips/${widget.tripId}/packing/$id');
    _load();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Item', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextFormField(controller: _labelCtrl, autofocus: true, style: AppTextStyles.bodyMedium, decoration: const InputDecoration(hintText: 'Item name', prefixIcon: Icon(Icons.check_box_outline_blank_rounded, size: 20))),
            const SizedBox(height: 12),
            TextFormField(controller: _catCtrl, style: AppTextStyles.bodyMedium, decoration: const InputDecoration(hintText: 'Category (optional)', prefixIcon: Icon(Icons.category_outlined, size: 20))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (_labelCtrl.text.trim().isNotEmpty) { _add(_labelCtrl.text.trim(), _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim()); _labelCtrl.clear(); _catCtrl.clear(); }
                Navigator.pop(context);
              },
              child: const Text('Add Item'),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checked = _items.where((i) => i['checked'] == 1).length;
    final cats = _items.map((i) => i['category'] as String?).where((c) => c != null).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing List'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}')),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _showTemplatesDialog,
            tooltip: 'Generate list',
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => _presets.keys.map((k) => PopupMenuItem(value: k, child: Text('Add $k preset'))).toList(),
            onSelected: (cat) { for (final label in _presets[cat]!) _add(label, cat); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$checked / ${_items.length} packed', style: AppTextStyles.labelLarge),
                            Text('${_items.isNotEmpty ? (checked / _items.length * 100).toStringAsFixed(0) : 0}%', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _items.isNotEmpty ? checked / _items.length : 0,
                          backgroundColor: AppColors.divider,
                          valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: _items.isEmpty
                      ? EmptyState(
                          icon: Icons.luggage_outlined,
                          title: 'Packing list is empty',
                          subtitle: 'Add items manually or use presets (top right menu)',
                          actionLabel: 'Add Item',
                          onAction: _showAddSheet,
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Uncategorized
                            ..._renderGroup(null, 'General'),
                            // By category
                            ...cats.map((cat) => _renderGroup(cat, cat!)).expand((w) => w),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddSheet, child: const Icon(Icons.add_rounded)),
    );
  }

  List<Widget> _renderGroup(String? cat, String label) {
    final items = _items.where((i) => i['category'] == cat).toList();
    if (items.isEmpty) return [];
    return [
      SectionHeader(title: label),
      const SizedBox(height: 8),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            children: [
              Checkbox(
                value: item['checked'] == 1,
                onChanged: (v) => _toggle(item['id'], v ?? false),
                activeColor: AppColors.secondary,
              ),
              Expanded(child: Text(item['label'] ?? '', style: AppTextStyles.bodyMedium.copyWith(decoration: item['checked'] == 1 ? TextDecoration.lineThrough : null, color: item['checked'] == 1 ? AppColors.textSecondary : AppColors.textPrimary))),
              IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textHint), onPressed: () => _delete(item['id'])),
            ],
          ),
        ),
      )),
      const SizedBox(height: 16),
    ];
  }
}
