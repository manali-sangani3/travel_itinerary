import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/di/injection.dart';

class CollaborationPage extends StatefulWidget {
  final String tripId;
  const CollaborationPage({super.key, required this.tripId});
  @override
  State<CollaborationPage> createState() => _CollaborationPageState();
}

class _CollaborationPageState extends State<CollaborationPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _collaborators = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _splits = [];
  bool _loading = true;
  final _emailCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();
  String _shareRole = 'viewer';

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); _emailCtrl.dispose(); _taskCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await sl<ApiClient>().get('/trips/${widget.tripId}/collaborators') as List? ?? [];
      final t = await sl<ApiClient>().get('/trips/${widget.tripId}/tasks') as List? ?? [];
      final s = await sl<ApiClient>().get('/trips/${widget.tripId}/splits') as List? ?? [];
      setState(() { _collaborators = c.cast(); _tasks = t.cast(); _splits = s.cast(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _share() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    try {
      await sl<ApiClient>().post('/trips/${widget.tripId}/collaborators', data: {'email': _emailCtrl.text.trim(), 'role': _shareRole});
      _emailCtrl.clear();
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _addTask() async {
    if (_taskCtrl.text.trim().isEmpty) return;
    await sl<ApiClient>().post('/trips/${widget.tripId}/tasks', data: {'title': _taskCtrl.text.trim()});
    _taskCtrl.clear();
    _load();
  }

  Future<void> _removeCollaborator(String userId) async {
    await sl<ApiClient>().delete('/trips/${widget.tripId}/collaborators/$userId');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborate'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}')),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Members'), Tab(text: 'Tasks'), Tab(text: 'Splits')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_membersTab(), _tasksTab(), _splitsTab()],
            ),
    );
  }

  Widget _membersTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite Member', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: AppTextStyles.bodyMedium, decoration: const InputDecoration(hintText: 'Enter email address', prefixIcon: Icon(Icons.email_outlined, size: 20))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Role:', style: AppTextStyles.labelLarge)),
                  ...AppConstants.collaboratorRoles.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(label: Text(r), selected: _shareRole == r, onSelected: (_) => setState(() => _shareRole = r)),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              AppButton(label: 'Send Invite', onPressed: _share),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Members (${_collaborators.length})'),
        const SizedBox(height: 12),
        if (_collaborators.isEmpty)
          const EmptyState(icon: Icons.people_outline_rounded, title: 'No collaborators', subtitle: 'Invite people to plan together')
        else
          ..._collaborators.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: AppColors.primaryLight, child: Text((c['email'] as String)[0].toUpperCase(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['email'] ?? '', style: AppTextStyles.labelLarge),
                  ])),
                  StatusBadge(c['role'] ?? 'viewer'),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.error), onPressed: () => _removeCollaborator(c['user_id'])),
                ],
              ),
            ),
          )),
      ],
    ),
  );

  Widget _tasksTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: TextFormField(controller: _taskCtrl, style: AppTextStyles.bodyMedium, decoration: const InputDecoration(hintText: 'Add a planning task...'))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _addTask, icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(backgroundColor: AppColors.primary)),
          ],
        ),
      ),
      Expanded(
        child: _tasks.isEmpty
            ? const EmptyState(icon: Icons.checklist_rounded, title: 'No tasks', subtitle: 'Add planning tasks and assign them')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final task = _tasks[i];
                  final done = task['completed'] == 1;
                  return AppCard(
                    child: Row(
                      children: [
                        Checkbox(
                          value: done,
                          onChanged: (_) async {
                            await sl<ApiClient>().put('/trips/${widget.tripId}/tasks/${task['id']}', data: {'completed': done ? 0 : 1});
                            _load();
                          },
                        ),
                        Expanded(child: Text(task['title'] ?? '', style: AppTextStyles.bodyMedium.copyWith(decoration: done ? TextDecoration.lineThrough : null))),
                        if (task['assigned_to'] != null) const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );

  Widget _splitsTab() => _splits.isEmpty
      ? const EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No shared expenses', subtitle: 'Log group expenses to calculate splits')
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _splits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final s = _splits[i];
            final owes = (s['owes'] as num).toDouble();
            return AppCard(
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: AppColors.primaryLight, child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['user_id'] ?? '', style: AppTextStyles.labelLarge),
                    Text('Paid: ₹${(s['paid'] as num).toStringAsFixed(0)}', style: AppTextStyles.bodySmall),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: owes > 0 ? AppColors.errorLight : AppColors.successLight, borderRadius: BorderRadius.circular(20)),
                    child: Text(owes > 0 ? 'Owes ₹${owes.toStringAsFixed(0)}' : 'Gets ₹${(-owes).toStringAsFixed(0)}',
                      style: AppTextStyles.labelSmall.copyWith(color: owes > 0 ? AppColors.error : AppColors.success)),
                  ),
                ],
              ),
            );
          },
        );
}
