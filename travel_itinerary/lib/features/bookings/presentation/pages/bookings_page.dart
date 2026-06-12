import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/di/injection.dart';

class BookingsPage extends StatefulWidget {
  final String tripId;
  const BookingsPage({super.key, required this.tripId});
  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await sl<ApiClient>().get('/trips/${widget.tripId}/bookings') as List;
      setState(() { _bookings = data.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _delete(String id) async {
    await sl<ApiClient>().delete('/trips/${widget.tripId}/bookings/$id');
    _load();
  }

  static const _typeIcons = {
    'flight': Icons.flight_rounded,
    'hotel': Icons.hotel_outlined,
    'car_rental': Icons.directions_car_outlined,
    'activity': Icons.local_activity_outlined,
  };
  static const _typeColors = {
    'flight': AppColors.primary,
    'hotel': AppColors.secondary,
    'car_rental': AppColors.warning,
    'activity': AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? EmptyState(
                  icon: Icons.confirmation_number_outlined,
                  title: 'No bookings yet',
                  subtitle: 'Add flights, hotels, and more',
                  actionLabel: 'Add Booking',
                  onAction: () => context.go('/trips/${widget.tripId}/bookings/add'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildBookingList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/trips/${widget.tripId}/bookings/add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<Widget> _buildBookingList() {
    const types = ['flight', 'hotel', 'car_rental', 'activity'];
    final result = <Widget>[];
    for (final type in types) {
      final filtered = _bookings.where((b) => b['type'] == type).toList();
      if (filtered.isEmpty) continue;
      result.add(SectionHeader(title: _typeLabel(type)));
      result.add(const SizedBox(height: 8));
      for (final b in filtered) {
        result.add(_BookingCard(
          booking: b,
          icon: _typeIcons[type] ?? Icons.bookmark_outlined,
          color: _typeColors[type] ?? AppColors.primary,
          onDelete: () => _delete(b['id']),
        ));
      }
      result.add(const SizedBox(height: 20));
    }
    return result;
  }

  String _typeLabel(String t) => {'flight': 'Flights', 'hotel': 'Hotels', 'car_rental': 'Car Rentals', 'activity': 'Activities'}[t] ?? t;
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final IconData icon;
  final Color color;
  final VoidCallback onDelete;
  const _BookingCard({required this.booking, required this.icon, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final details = booking['details'] is Map ? Map<String, dynamic>.from(booking['details']) : <String, dynamic>{};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking['type'].toString().replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: color)),
                  const SizedBox(height: 2),
                  Text(booking['reference_number'] ?? 'No reference', style: AppTextStyles.labelLarge),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(details.entries.take(2).map((e) => '${e.key}: ${e.value}').join(' • '), style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
