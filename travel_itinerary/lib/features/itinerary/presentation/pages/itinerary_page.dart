import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/itinerary_bloc.dart';
import '../widgets/add_activity_sheet.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;
  final String? startDate;
  final int? totalDays;
  const ItineraryPage({super.key, required this.tripId, this.startDate, this.totalDays});
  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  int _selectedDay = 0;
  static const _totalDays = 5;

  // Base date for the day strip (Oct 12 style)
  DateTime get _baseDate {
    if (widget.startDate != null) {
      try { return DateTime.parse(widget.startDate!); } catch (_) {}
    }
    return DateTime(2024, 10, 12);
  }

  @override
  void initState() {
    super.initState();
    context.read<ItineraryBloc>().add(ItineraryLoadRequested(widget.tripId));
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddActivitySheet(tripId: widget.tripId, dayIndex: _selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(),
            const SizedBox(height: 20),
            _DateStrip(
              baseDate: _baseDate,
              totalDays: _totalDays,
              selectedDay: _selectedDay,
              onDaySelected: (d) => setState(() => _selectedDay = d),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<ItineraryBloc, ItineraryState>(
                builder: (context, state) {
                  if (state is ItineraryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ItineraryLoaded) {
                    final dayItems = state.items
                        .where((i) => i.dayIndex == _selectedDay)
                        .toList()
                      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
                    return _TimelineList(
                      tripId: widget.tripId,
                      items: dayItems,
                      dayIndex: _selectedDay,
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFF111827),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
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
                image: NetworkImage('https://i.pravatar.cc/150?img=12'),
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

// ─── Date strip ────────────────────────────────────────────────────────────

class _DateStrip extends StatelessWidget {
  final DateTime baseDate;
  final int totalDays;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const _DateStrip({
    required this.baseDate,
    required this.totalDays,
    required this.selectedDay,
    required this.onDaySelected,
  });

  static const _months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: totalDays,
        itemBuilder: (_, i) {
          final date = baseDate.add(Duration(days: i));
          final isSelected = selectedDay == i;
          return GestureDetector(
            onTap: () => onDaySelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 72,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _months[date.month - 1],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF111827),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Timeline list ─────────────────────────────────────────────────────────

class _TimelineList extends StatelessWidget {
  final String tripId;
  final List<ItineraryItem> items;
  final int dayIndex;

  const _TimelineList({required this.tripId, required this.items, required this.dayIndex});

  static const _activityIcons = {
    'food': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_rounded,
    'hotel': Icons.hotel_rounded,
    'accommodation': Icons.hotel_rounded,
    'museum': Icons.museum_rounded,
    'tour': Icons.tour_rounded,
    'landmark': Icons.account_balance_rounded,
    'shopping': Icons.shopping_bag_outlined,
    'transport': Icons.directions_bus_rounded,
    'default': Icons.location_on_rounded,
  };

  static const _transitIcons = [
    Icons.directions_walk_rounded,
    Icons.directions_car_rounded,
    Icons.directions_bus_rounded,
  ];

  static const _transitTexts = [
    '12 min walk to next stop',
    '15 min via Uber to next stop',
    '22 min via RER C to next stop',
  ];

  IconData _iconForItem(ItineraryItem item) {
    final t = (item.title + (item.location ?? '')).toLowerCase();
    for (final key in _activityIcons.keys) {
      if (t.contains(key)) return _activityIcons[key]!;
    }
    return _activityIcons['default']!;
  }

  String _formatTime(String? t) {
    if (t == null || t.isEmpty) return '';
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour:$m $period';
    } catch (_) { return t; }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No activities yet', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Tap + to add your first activity',
                style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final hasTransit = i < items.length - 1;
        final transitText = _transitTexts[i % _transitTexts.length];
        final transitIcon = _transitIcons[i % _transitIcons.length];
        final timeStr = _formatTime(item.startTime);
        final isHighlighted = i == 2; // teal border on 3rd card as accent

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time label + icon
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_iconForItem(item), color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
              ],
            ),
            // Vertical line + card
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline line
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(width: 31),
                  // Activity card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: _ActivityCard(item: item, highlighted: isHighlighted),
                    ),
                  ),
                ],
              ),
            ),
            // Transit info between stops
            if (hasTransit)
              Padding(
                padding: const EdgeInsets.only(left: 52, bottom: 8),
                child: Row(
                  children: [
                    Icon(transitIcon, size: 16, color: const Color(0xFFD1D5DB)),
                    const SizedBox(width: 8),
                    Text(
                      transitText,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Activity card ─────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final ItineraryItem item;
  final bool highlighted;

  const _ActivityCard({required this.item, this.highlighted = false});

  static const _destinationImages = {
    'louvre': 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=200&q=80',
    'eiffel': 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=200&q=80',
    'colosseum': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=200&q=80',
    'taj': 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=200&q=80',
  };

  String? _imageUrl() {
    final t = (item.title + (item.location ?? '')).toLowerCase();
    for (final key in _destinationImages.keys) {
      if (t.contains(key)) return _destinationImages[key]!;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = _imageUrl();
    final tags = _parseTags(item.title);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlighted
            ? Border.all(color: const Color(0xFF059669), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imgUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imgUrl,
                width: 80, height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    // Confirmed badge (show for first item)
                    if (item.orderIndex == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.location != null && item.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Extract bracket tags like [Level 2 Access][Fast Track] from title
  List<String> _parseTags(String title) {
    final regex = RegExp(r'\[([^\]]+)\]');
    return regex.allMatches(title).map((m) => m.group(1)!).toList();
  }
}

// ─── Bottom nav ────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

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
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Colors.white),
            ),
            label: 'Itinerary',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Budget',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
