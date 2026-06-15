import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/trips_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection.dart';

class TripDetailPage extends StatelessWidget {
  final String tripId;
  const TripDetailPage({super.key, required this.tripId});

  static const _modules = [
    {'icon': Icons.calendar_month_outlined, 'label': 'Itinerary', 'route': 'itinerary', 'color': AppColors.primary},
    {'icon': Icons.confirmation_number_outlined, 'label': 'Bookings', 'route': 'bookings', 'color': Color(0xFF0E9F6E)},
    {'icon': Icons.folder_outlined, 'label': 'Documents', 'route': 'documents', 'color': Color(0xFF9061F9)},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Budget', 'route': 'budget', 'color': Color(0xFFFF8A4C)},
    {'icon': Icons.people_outline_rounded, 'label': 'Collaborate', 'route': 'collaboration', 'color': Color(0xFF1A56DB)},
    {'icon': Icons.book_outlined, 'label': 'Journal', 'route': 'journal', 'color': Color(0xFFE02424)},
    {'icon': Icons.checklist_rounded, 'label': 'Packing', 'route': 'packing', 'color': Color(0xFF6366F1)},
    {'icon': Icons.currency_exchange_rounded, 'label': 'Currency', 'route': 'currency', 'color': Color(0xFF10B981)},
    {'icon': Icons.access_time_rounded, 'label': 'Time Zone', 'route': 'timezone', 'color': Color(0xFF8B5CF6)},
  ];

  void _showCurrencyDialog(BuildContext context) {
    final amountCtrl = TextEditingController(text: '100');
    String base = 'USD';
    String target = 'INR';
    String result = '';
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Currency Converter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: base,
                        items: ['USD', 'INR', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setDlgState(() => base = v!),
                        decoration: const InputDecoration(labelText: 'From'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: target,
                        items: ['USD', 'INR', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setDlgState(() => target = v!),
                        decoration: const InputDecoration(labelText: 'To'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (loading) const CircularProgressIndicator(),
                if (result.isNotEmpty) ...[
                  Text(result, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: loading ? null : () async {
                  setDlgState(() => loading = true);
                  try {
                    final res = await sl<ApiClient>().get('/currency/convert', params: {
                      'base': base,
                      'target': target,
                      'amount': amountCtrl.text
                    });
                    setDlgState(() {
                      result = '${amountCtrl.text} $base = ${(res['amount'] as num).toStringAsFixed(2)} $target\nRate: ${(res['rate'] as num).toStringAsFixed(4)}';
                      loading = false;
                    });
                  } catch (e) {
                    setDlgState(() {
                      result = 'Error converting: $e';
                      loading = false;
                    });
                  }
                },
                child: const Text('Convert'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTimezoneDialog(BuildContext context) {
    String fromZone = 'America/New_York';
    String toZone = 'Asia/Kolkata';
    String result = '';
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Time Zone Calculator'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: fromZone,
                  items: ['America/New_York', 'Europe/London', 'Asia/Kolkata', 'UTC', 'Asia/Singapore', 'Australia/Sydney'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDlgState(() => fromZone = v!),
                  decoration: const InputDecoration(labelText: 'From Timezone'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toZone,
                  items: ['America/New_York', 'Europe/London', 'Asia/Kolkata', 'UTC', 'Asia/Singapore', 'Australia/Sydney'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDlgState(() => toZone = v!),
                  decoration: const InputDecoration(labelText: 'To Timezone'),
                ),
                const SizedBox(height: 16),
                if (loading) const CircularProgressIndicator(),
                if (result.isNotEmpty) ...[
                  Text(result, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: loading ? null : () async {
                  setDlgState(() => loading = true);
                  try {
                    final res = await sl<ApiClient>().get('/timezone/diff', params: {
                      'from': fromZone,
                      'to': toZone
                    });
                    setDlgState(() {
                      result = 'Difference: ${res['offsetDiff']} hours\nLocal Time (To): ${res['toLocalTime']}';
                      loading = false;
                    });
                  } catch (e) {
                    setDlgState(() {
                      result = 'Error: $e';
                      loading = false;
                    });
                  }
                },
                child: const Text('Calculate'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsBloc, TripsState>(
      builder: (context, state) {
        final trip = state is TripsLoaded ? state.trips.where((t) => t.id == tripId).firstOrNull : null;
        return Scaffold(
          appBar: AppBar(
            title: Text(trip?.destination ?? 'Trip'),
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips')),
            actions: [
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Trip')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Trip', style: TextStyle(color: AppColors.error))),
                ],
                onSelected: (v) {
                  if (v == 'delete') {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: const Text('Delete Trip'),
                      content: const Text('This will permanently delete the trip and all its data.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () { context.read<TripsBloc>().add(TripDeleteRequested(tripId)); Navigator.pop(context); context.go('/trips'); },
                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ));
                  }
                },
              ),
            ],
          ),
          body: trip == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusBadge(trip.status),
                            const SizedBox(height: 12),
                            Text(trip.destination, style: AppTextStyles.h1.copyWith(color: AppColors.textInverse)),
                            const SizedBox(height: 6),
                            Text(AppDateUtils.dateRange(trip.startDate, trip.endDate), style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _chip(Icons.calendar_today_outlined, '${AppDateUtils.tripDuration(trip.startDate, trip.endDate)} days'),
                                const SizedBox(width: 12),
                                if (trip.purpose.isNotEmpty) _chip(Icons.work_outline_rounded, trip.purpose),
                                const SizedBox(width: 12),
                                if (trip.companions.isNotEmpty) _chip(Icons.people_outline_rounded, '${trip.companions.length} travellers'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Modules grid
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip Tools', style: AppTextStyles.h3),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1),
                              itemCount: _modules.length,
                              itemBuilder: (_, i) {
                                final m = _modules[i];
                                return AppCard(
                                  onTap: () {
                                    if (m['route'] == 'currency') {
                                      _showCurrencyDialog(context);
                                    } else if (m['route'] == 'timezone') {
                                      _showTimezoneDialog(context);
                                    } else {
                                      context.go('/trips/$tripId/${m['route']}');
                                    }
                                  },
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                        child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 22),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(m['label'] as String, style: AppTextStyles.labelMedium, textAlign: TextAlign.center),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Companions
                            if (trip.companions.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text('Companions', style: AppTextStyles.h3),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: trip.companions.map((c) => Chip(
                                  avatar: CircleAvatar(backgroundColor: AppColors.primaryLight, child: Text(c[0].toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary))),
                                  label: Text(c),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
      ],
    ),
  );
}
