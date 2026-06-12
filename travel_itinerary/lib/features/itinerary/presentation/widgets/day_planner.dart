import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/itinerary_bloc.dart';
import 'activity_tile.dart';
import 'timeline_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';

class DayPlanner extends StatefulWidget {
  final String tripId;
  final int dayIndex;
  final List<ItineraryItem> items;
  const DayPlanner({super.key, required this.tripId, required this.dayIndex, required this.items});
  @override
  State<DayPlanner> createState() => _DayPlannerState();
}

class _DayPlannerState extends State<DayPlanner> with SingleTickerProviderStateMixin {
  late TabController _viewTabs;

  @override
  void initState() { super.initState(); _viewTabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _viewTabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return EmptyState(
        icon: Icons.event_note_outlined,
        title: 'No activities yet',
        subtitle: 'Tap + to add activities for Day ${widget.dayIndex + 1}',
      );
    }
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _viewTabs,
            tabs: const [Tab(text: 'List View'), Tab(text: 'Timeline')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _viewTabs,
            children: [
              // LIST / DRAG-DROP VIEW
              ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.items.length,
                onReorder: (oldIdx, newIdx) {
                  if (newIdx > oldIdx) newIdx--;
                  context.read<ItineraryBloc>().add(ItineraryItemReordered(widget.tripId, widget.dayIndex, oldIdx, newIdx));
                },
                itemBuilder: (_, i) => ActivityTile(
                  key: ValueKey(widget.items[i].id),
                  item: widget.items[i],
                  tripId: widget.tripId,
                  isFirst: i == 0,
                  isLast: i == widget.items.length - 1,
                ),
              ),
              // TIMELINE VIEW
              TimelineView(items: widget.items),
            ],
          ),
        ),
      ],
    );
  }
}
