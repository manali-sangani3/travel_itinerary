import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/trips_bloc.dart';
import '../widgets/trip_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';

class TripsListPage extends StatefulWidget {
  const TripsListPage({super.key});
  @override
  State<TripsListPage> createState() => _TripsListPageState();
}

class _TripsListPageState extends State<TripsListPage> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<TripsBloc>().add(TripsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 20),
            _CreateTripButton(),
            const SizedBox(height: 28),
            Expanded(child: _TripsList()),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 0) { setState(() => _navIndex = 0); return; }
          if (i == 3) { context.go('/profile'); return; }
          // Itinerary / Budget tabs need a trip — navigate to first available trip
          final state = context.read<TripsBloc>().state;
          if (state is TripsLoaded && state.trips.isNotEmpty) {
            final tripId = state.trips.first.id;
            if (i == 1) context.go('/trips/$tripId/itinerary');
            if (i == 2) context.go('/trips/$tripId/budget');

          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create a trip first to view itinerary')),
            );
          }
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Voyage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
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

class _CreateTripButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello, Traveller.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where are we going next?',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/trips/new'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'CREATE NEW TRIP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsBloc, TripsState>(
      builder: (context, state) {
        if (state is TripsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TripsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(state.message, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.read<TripsBloc>().add(TripsLoadRequested()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is TripsLoaded) {
          final upcoming = state.trips.where((t) => t.status != 'completed').toList();
          if (upcoming.isEmpty) {
            return const EmptyState(
              icon: Icons.flight_outlined,
              title: 'No trips yet',
              subtitle: 'Tap CREATE NEW TRIP to get started',
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Trips',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => context.read<TripsBloc>().add(TripsLoadRequested()),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: upcoming.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => TripCard(trip: upcoming[i]),
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        color: Colors.white,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: currentIndex == 0 ? const Color(0xFF059669) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.explore_rounded,
                color: currentIndex == 0 ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
            label: 'Trips',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
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
