import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';

class BudgetPage extends StatefulWidget {
  final String tripId;
  const BudgetPage({super.key, required this.tripId});
  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Map<String, dynamic>> _summary = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await sl<ApiClient>().get('/trips/${widget.tripId}/budget/summary') as List;
      setState(() {
        _summary = s.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double get _totalPlanned => _summary.fold(0, (s, i) => s + (i['planned'] as num).toDouble());
  double get _totalActual  => _summary.fold(0, (s, i) => s + (i['actual']  as num).toDouble());
  double get _remaining    => _totalPlanned - _totalActual;

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BudgetRingCard(
                              remaining: _remaining,
                              total: _totalPlanned,
                              actual: _totalActual,
                            ),
                            const SizedBox(height: 24),
                            _SpendingSection(
                              summary: _summary,
                              tripId: widget.tripId,
                              fmt: _fmt,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/trips/${widget.tripId}/budget/expense'),
        backgroundColor: const Color(0xFF111827),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 2, tripId: widget.tripId),
    );
  }
}

// ─── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E7EB),
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(),
          const Text('Voyage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF111827)),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Donut ring card ────────────────────────────────────────────────────────

class _BudgetRingCard extends StatelessWidget {
  final double remaining, total, actual;
  const _BudgetRingCard({required this.remaining, required this.total, required this.actual});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (actual / total).clamp(0.0, 1.0) : 0.0;
    final daysLeft = 12;
    final dailyAvg = actual > 0 ? (actual / 30).round() : 145;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          const Text(
            'REMAINING BUDGET',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 24),
          // Ring
          SizedBox(
            width: 180, height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180, height: 180,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 14,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE5E7EB)),
                  ),
                ),
                SizedBox(
                  width: 180, height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2D8B72)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total > 0 ? _fmtRupee(remaining) : '₹0',
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${_fmtRupee(total)}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Daily Avg.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 4),
                      Text('₹$dailyAvg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Days Left', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 4),
                      Text('$daysLeft', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─── Spending by category section ──────────────────────────────────────────

class _SpendingSection extends StatelessWidget {
  final List<Map<String, dynamic>> summary;
  final String tripId;
  final String Function(double) fmt;

  const _SpendingSection({required this.summary, required this.tripId, required this.fmt});

  static const _catIcons = {
    'accommodation': Icons.hotel_rounded,
    'food': Icons.restaurant_rounded,
    'transport': Icons.flight_rounded,
    'activities': Icons.local_activity_rounded,
    'misc': Icons.receipt_long_rounded,
  };

  static const _catLabels = {
    'accommodation': 'Lodging',
    'food': 'Food',
    'transport': 'Flights',
    'activities': 'Activities',
    'misc': 'Misc',
  };

  @override
  Widget build(BuildContext context) {
    final categories = summary.isNotEmpty
        ? summary
        : AppConstants.budgetCategories.map((c) => {'category': c, 'actual': 0.0, 'planned': 0.0}).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text('View Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...categories.map((item) {
          final cat = item['category'] as String;
          final actual = (item['actual'] as num).toDouble();
          final planned = (item['planned'] as num).toDouble();
          final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
          final icon = _catIcons[cat] ?? Icons.receipt_outlined;
          final label = _catLabels[cat] ?? cat[0].toUpperCase() + cat.substring(1);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, size: 22, color: const Color(0xFF2D8B72)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ),
                    Text(
                      '${fmt(actual)} / ${fmt(planned > 0 ? planned : actual + 500)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : 0.75,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(
                      progress > 0.9 ? const Color(0xFFEF4444) : const Color(0xFF2D8B72),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Bottom nav ────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final String tripId;
  const _BottomNav({required this.currentIndex, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        color: Colors.white,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == 0) context.go('/trips');
          if (i == 1) context.go('/trips/$tripId/itinerary');
          if (i == 3) context.go('/profile');
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Trips'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Itinerary'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
            ),
            label: 'Budget',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
