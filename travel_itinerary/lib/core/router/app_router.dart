import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/trips/presentation/pages/trips_list_page.dart';
import '../../features/trips/presentation/pages/create_trip_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_page.dart';
import '../../features/bookings/presentation/pages/bookings_page.dart';
import '../../features/bookings/presentation/pages/add_booking_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/budget/presentation/pages/budget_page.dart';
import '../../features/budget/presentation/pages/add_expense_page.dart';
import '../../features/collaboration/presentation/pages/collaboration_page.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/journal_entry_page.dart';
import '../../features/journal/presentation/pages/notes_page.dart';
import '../../features/journal/presentation/pages/photo_gallery_page.dart';
import '../../features/packing/presentation/pages/packing_page.dart';
import '../constants/app_constants.dart';

const _publicRoutes = ['/login', '/register'];

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.accessTokenKey);
      final isPublic = _publicRoutes.contains(state.matchedLocation);
      if (token == null && !isPublic) return '/login';
      if (token != null && isPublic) return '/trips';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/profile',  builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/trips',    builder: (_, __) => const TripsListPage()),
      GoRoute(path: '/trips/new', builder: (_, __) => const CreateTripPage()),
      GoRoute(
        path: '/trips/:id',
        builder: (_, s) => TripDetailPage(tripId: s.pathParameters['id']!),
        routes: [
          GoRoute(path: 'itinerary',      builder: (_, s) => ItineraryPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'bookings',       builder: (_, s) => BookingsPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'bookings/add',   builder: (_, s) => AddBookingPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'documents',      builder: (_, s) => DocumentsPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'budget',         builder: (_, s) => BudgetPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'budget/expense', builder: (_, s) => AddExpensePage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'collaboration',  builder: (_, s) => CollaborationPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'journal',        builder: (_, s) => JournalPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'journal/entry',  builder: (_, s) => JournalEntryPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'journal/notes',  builder: (_, s) => NotesPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'journal/gallery', builder: (_, s) => PhotoGalleryPage(tripId: s.pathParameters['id']!)),
          GoRoute(path: 'packing',        builder: (_, s) => PackingPage(tripId: s.pathParameters['id']!)),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
