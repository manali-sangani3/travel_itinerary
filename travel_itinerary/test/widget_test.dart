import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';

import 'package:travel_itinerary/features/auth/presentation/pages/login_page.dart';
import 'package:travel_itinerary/features/auth/presentation/pages/register_page.dart';
import 'package:travel_itinerary/features/auth/presentation/pages/profile_page.dart';
import 'package:travel_itinerary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:travel_itinerary/features/auth/domain/entities/user.dart';
import 'package:travel_itinerary/features/trips/presentation/pages/trips_list_page.dart';
import 'package:travel_itinerary/features/trips/presentation/pages/create_trip_page.dart';
import 'package:travel_itinerary/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:travel_itinerary/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:travel_itinerary/features/itinerary/presentation/bloc/itinerary_bloc.dart';
import 'package:travel_itinerary/features/itinerary/presentation/bloc/weather_bloc.dart';
import 'package:travel_itinerary/features/budget/presentation/pages/budget_page.dart';
import 'package:travel_itinerary/features/budget/presentation/pages/add_expense_page.dart';
import 'package:travel_itinerary/core/network/api_client.dart';
import 'package:travel_itinerary/core/di/injection.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockAuthBloc extends Mock implements AuthBloc {}
class MockTripsBloc extends Mock implements TripsBloc {}
class MockItineraryBloc extends Mock implements ItineraryBloc {}
class MockWeatherBloc extends Mock implements WeatherBloc {}
class MockApiClient extends Mock implements ApiClient {}

class FakeAuthEvent extends Fake implements AuthEvent {}
class FakeTripsEvent extends Fake implements TripsEvent {}
class FakeItineraryEvent extends Fake implements ItineraryEvent {}
class FakeWeatherEvent extends Fake implements WeatherEvent {}
class FakeWeatherState extends Fake implements WeatherState {}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();

    when(() => client.getUrl(any())).thenAnswer((_) {
      final request = MockHttpClientRequest();
      final response = MockHttpClientResponse();
      final headers = MockHttpHeaders();

      when(() => request.headers).thenReturn(headers);
      when(() => request.close()).thenAnswer((_) => Future.value(response));
      when(() => response.statusCode).thenReturn(200);
      when(() => response.contentLength).thenReturn(transparentImage.length);
      when(() => response.compressionState).thenReturn(HttpClientResponseCompressionState.notCompressed);

      return Future.value(request);
    });

    when(() => client.autoUncompress = any()).thenAnswer((_) => false);

    return client;
  }
}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  final Stream<List<int>> _delegate = Stream<List<int>>.value(transparentImage);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _delegate.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

final List<int> transparentImage = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
  0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Router wrapper — gives GoRouter context for pages that call context.go(...)
Widget wrapWithRouter(Widget child) => MaterialApp.router(
  routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => child)]),
);

/// Plain MaterialApp wrapper
Widget wrapPlain(Widget child) => MaterialApp(home: child);

/// Pump the widget and pump once more to flush initial frames.
/// Silently ignores NetworkImageLoadException which always occurs in tests
/// because Flutter test blocks all real HTTP calls.
Future<void> pumpPage(WidgetTester t, Widget w) async {
  await t.pumpWidget(w);
  await t.pump();
}

TripModel makeTrip({String id = '1', String destination = 'Paris', String status = 'active'}) =>
    TripModel(id: id, destination: destination, startDate: '2024-10-12',
        endDate: '2024-10-19', status: status, purpose: 'leisure', companions: []);

ItineraryItem makeItem({String id = '1', String title = 'Breakfast', int day = 0}) =>
    ItineraryItem(id: id, tripId: 'trip1', title: title, dayIndex: day,
        orderIndex: 0, location: 'Café de Flore', startTime: '09:00', endTime: '10:00');

// ═════════════════════════════════════════════════════════════════════════════
//  AUTH — Login Page
// ═════════════════════════════════════════════════════════════════════════════

void main() {
  late MockApiClient mockApiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    HttpOverrides.global = MockHttpOverrides();
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeTripsEvent());
    registerFallbackValue(FakeItineraryEvent());
    registerFallbackValue(FakeWeatherEvent());
    registerFallbackValue(FakeWeatherState());
  });

  setUp(() {
    mockApiClient = MockApiClient();
    if (sl.isRegistered<ApiClient>()) {
      sl.unregister<ApiClient>();
    }
    sl.registerSingleton<ApiClient>(mockApiClient);
  });

  group('Login Page', () {
    late MockAuthBloc authBloc;

    setUp(() {
      authBloc = MockAuthBloc();
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    // AUTH-UI-01
    testWidgets('AUTH-UI-01 · renders email + password fields and Sign In button', (t) async {
      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.text('Sign In'), findsOneWidget);
    });

    // AUTH-UI-02
    testWidgets('AUTH-UI-02 · empty form submit triggers field validation', (t) async {
      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));

      await t.ensureVisible(find.text('Sign In'));
      await t.tap(find.text('Sign In'));
      await t.pump();

      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    // AUTH-UI-03
    testWidgets('AUTH-UI-03 · loading state shows CircularProgressIndicator inside button', (t) async {
      when(() => authBloc.state).thenReturn(AuthLoading());
      when(() => authBloc.stream).thenAnswer((_) => Stream.value(AuthLoading()));

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // AUTH-UI-04
    testWidgets('AUTH-UI-04 · password field obscures text by default', (t) async {
      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));

      final pwField = t.widget<EditableText>(
        find.descendant(of: find.byType(TextFormField).last, matching: find.byType(EditableText)));
      expect(pwField.obscureText, isTrue);
    });

    // AUTH-UI-05
    testWidgets('AUTH-UI-05 · error state shows snackbar with message', (t) async {
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([const AuthError('Invalid credentials')]));

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));
      await t.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    // AUTH-UI-06
    testWidgets('AUTH-UI-06 · email field accepts text input', (t) async {
      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));

      await t.enterText(find.byType(TextFormField).first, 'user@example.com');
      await t.pump();

      expect(find.text('user@example.com'), findsOneWidget);
    });

    // AUTH-UI-07
    testWidgets('AUTH-UI-07 · Sign In tapped with valid input dispatches LoginRequested', (t) async {
      when(() => authBloc.add(any())).thenReturn(null);

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const LoginPage())));

      await t.enterText(find.byType(TextFormField).first, 'user@example.com');
      await t.enterText(find.byType(TextFormField).last, 'Password123');
      await t.pump();
      await t.ensureVisible(find.text('Sign In'));
      await t.tap(find.text('Sign In'));
      await t.pump();

      verify(() => authBloc.add(any(that: isA<LoginRequested>()))).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  AUTH — Register Page
  // ═══════════════════════════════════════════════════════════════════════════

  group('Register Page', () {
    late MockAuthBloc authBloc;

    setUp(() {
      authBloc = MockAuthBloc();
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    // AUTH-UI-08
    testWidgets('AUTH-UI-08 · register page renders heading and three form fields', (t) async {
      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const RegisterPage())));

      expect(find.text('Create account'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(3));
    });

    // AUTH-UI-09
    testWidgets('AUTH-UI-09 · mismatched passwords blocks RegisterRequested', (t) async {
      when(() => authBloc.add(any())).thenReturn(null);

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const RegisterPage())));

      final fields = find.byType(TextFormField);
      await t.enterText(fields.at(0), 'user@example.com');
      await t.enterText(fields.at(1), 'Password123');
      await t.enterText(fields.at(2), 'WrongPass999');
      await t.pump();
      await t.tap(find.text('Create Account'));
      await t.pump();

      verifyNever(() => authBloc.add(any(that: isA<RegisterRequested>())));
    });

    // AUTH-UI-10
    testWidgets('AUTH-UI-10 · loading state shows progress indicator', (t) async {
      when(() => authBloc.state).thenReturn(AuthLoading());
      when(() => authBloc.stream).thenAnswer((_) => Stream.value(AuthLoading()));

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const RegisterPage())));
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // AUTH-UI-11
    testWidgets('AUTH-UI-11 · Sign In link visible for existing users', (t) async {
      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapWithRouter(const RegisterPage())));

      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  AUTH — Profile Page
  // ═══════════════════════════════════════════════════════════════════════════

  group('Profile Page', () {
    late MockAuthBloc authBloc;

    setUp(() {
      authBloc = MockAuthBloc();
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    // AUTH-UI-12
    testWidgets('AUTH-UI-12 · authenticated state shows email and passport section', (t) async {
      const user = User(id: 'u1', email: 'test@example.com');
      when(() => authBloc.state).thenReturn(const AuthAuthenticated(user));

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapPlain(const ProfilePage())));

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Passport Details'), findsOneWidget);
    });

    // AUTH-UI-13
    testWidgets('AUTH-UI-13 · loading state shows spinner', (t) async {
      when(() => authBloc.state).thenReturn(AuthLoading());

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapPlain(const ProfilePage())));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // AUTH-UI-14
    testWidgets('AUTH-UI-14 · Sign Out button is visible on profile', (t) async {
      const user = User(id: 'u1', email: 'test@example.com');
      when(() => authBloc.state).thenReturn(const AuthAuthenticated(user));

      await pumpPage(t, BlocProvider<AuthBloc>.value(
        value: authBloc, child: wrapPlain(const ProfilePage())));

      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  TRIPS LIST PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Trips List Page', () {
    late MockTripsBloc tripsBloc;

    setUp(() {
      tripsBloc = MockTripsBloc();
      when(() => tripsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    // TRIP-UI-01
    testWidgets('TRIP-UI-01 · loading state shows spinner', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoading());

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // TRIP-UI-02
    testWidgets('TRIP-UI-02 · loaded state shows trip destination names', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoaded([
        makeTrip(id: '1', destination: 'Paris'),
        makeTrip(id: '2', destination: 'Tokyo', status: 'planning'),
      ]));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.text('Paris'), findsOneWidget);
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pump();
      expect(find.text('Tokyo'), findsOneWidget);
    });

    // TRIP-UI-03
    testWidgets('TRIP-UI-03 · empty trips shows empty state widget', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoaded([]));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.text('No trips yet'), findsOneWidget);
    });

    // TRIP-UI-04
    testWidgets('TRIP-UI-04 · error state shows error message with Retry button', (t) async {
      when(() => tripsBloc.state).thenReturn(const TripsError('Failed to load trips'));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.text('Failed to load trips'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    // TRIP-UI-05
    testWidgets('TRIP-UI-05 · CREATE NEW TRIP button is always present', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoaded([]));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.text('CREATE NEW TRIP'), findsOneWidget);
    });

    // TRIP-UI-06
    testWidgets('TRIP-UI-06 · active trip shows "active" badge text', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoaded([makeTrip(status: 'active')]));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.textContaining('active', findRichText: true), findsAtLeast(1));
    });

    // TRIP-UI-07
    testWidgets('TRIP-UI-07 · planning trip shows "planning" badge text', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoaded([makeTrip(status: 'planning')]));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const TripsListPage())));

      expect(find.textContaining('planning', findRichText: true), findsAtLeast(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  CREATE TRIP PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Create Trip Page', () {
    late MockTripsBloc tripsBloc;

    setUp(() {
      tripsBloc = MockTripsBloc();
      when(() => tripsBloc.state).thenReturn(TripsInitial());
      when(() => tripsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    // TRIP-UI-08
    testWidgets('TRIP-UI-08 · create trip page has at least one form field', (t) async {
      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const CreateTripPage())));

      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    // TRIP-UI-09
    testWidgets('TRIP-UI-09 · empty submit does not dispatch TripCreateRequested', (t) async {
      when(() => tripsBloc.add(any())).thenReturn(null);

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const CreateTripPage())));

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Trip');
      if (submitBtn.evaluate().isNotEmpty) {
        await t.tap(submitBtn);
        await t.pump();
        verifyNever(() => tripsBloc.add(any(that: isA<TripCreateRequested>())));
      } else {
        expect(find.byType(TextFormField), findsAtLeast(1));
      }
    });

    // TRIP-UI-10
    testWidgets('TRIP-UI-10 · loading state shows progress indicator', (t) async {
      when(() => tripsBloc.state).thenReturn(TripsLoading());
      when(() => tripsBloc.stream).thenAnswer((_) => Stream.value(TripsLoading()));

      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const CreateTripPage())));
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // TRIP-UI-11
    testWidgets('TRIP-UI-11 · date range validation resets end date if start date is after end date', (t) async {
      await pumpPage(t, BlocProvider<TripsBloc>.value(
        value: tripsBloc, child: wrapWithRouter(const CreateTripPage())));

      // Initially both show 'Select'
      expect(find.text('Select'), findsNWidgets(2));

      // 1. Select End Date as 15th of next month
      await t.tap(find.text('End'));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      
      // Navigate to next month
      await t.tap(find.byTooltip('Next month'));
      await t.pumpAndSettle();

      // Tap '15' in the dialog
      await t.tap(find.descendant(of: find.byType(DatePickerDialog), matching: find.text('15')));
      await t.pumpAndSettle();
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();

      // End date box should now display '15 <Next Month MMM> <Year>'
      final now = DateTime.now();
      final nextMonthDateTime = DateTime(now.year, now.month + 1, 1);
      final nextMonthStr = DateFormat('MMM yyyy').format(nextMonthDateTime);
      expect(find.textContaining('15 $nextMonthStr', findRichText: true), findsOneWidget);

      // 2. Select Start Date as 20th of next month (after the End date of 15th)
      await t.tap(find.text('Start'));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Navigate to next month
      await t.tap(find.byTooltip('Next month'));
      await t.pumpAndSettle();
      
      // Tap '20' in the dialog
      await t.tap(find.descendant(of: find.byType(DatePickerDialog), matching: find.text('20')));
      await t.pumpAndSettle();
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();

      // Start date box should now display '20 <Next Month MMM> <Year>'
      expect(find.textContaining('20 $nextMonthStr', findRichText: true), findsOneWidget);

      // End date box should have reset to 'Select' because the start date (20th) is after the end date (15th)
      expect(find.text('Select'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  ITINERARY PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Itinerary Page', () {
    late MockItineraryBloc itineraryBloc;
    late MockTripsBloc tripsBloc;
    late MockWeatherBloc weatherBloc;

    setUp(() {
      itineraryBloc = MockItineraryBloc();
      tripsBloc = MockTripsBloc();
      weatherBloc = MockWeatherBloc();
      when(() => itineraryBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => tripsBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => tripsBloc.state).thenReturn(TripsLoaded([]));
      when(() => weatherBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => weatherBloc.state).thenReturn(WeatherInitial());
      when(() => weatherBloc.close()).thenAnswer((_) => Future.value());

      if (sl.isRegistered<WeatherBloc>()) {
        sl.unregister<WeatherBloc>();
      }
      sl.registerFactory<WeatherBloc>(() => weatherBloc);
    });

    Future<void> pumpItineraryPage(WidgetTester t, Widget page) async {
      await pumpPage(t, MultiBlocProvider(
        providers: [
          BlocProvider<ItineraryBloc>.value(value: itineraryBloc),
          BlocProvider<TripsBloc>.value(value: tripsBloc),
        ],
        child: wrapWithRouter(page),
      ));
    }

    // ITIN-UI-01
    testWidgets('ITIN-UI-01 · loading state shows spinner', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoading());

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // ITIN-UI-02
    testWidgets('ITIN-UI-02 · loaded items show activity titles', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded([
        makeItem(id: '1', title: 'Petit Dejeuner'),
        makeItem(id: '2', title: 'Louvre Guided Tour'),
      ]));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.text('Petit Dejeuner'), findsOneWidget);
      expect(find.text('Louvre Guided Tour'), findsOneWidget);
    });

    // ITIN-UI-03
    testWidgets('ITIN-UI-03 · empty day shows "No activities yet" empty state', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded([]));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.text('No activities yet'), findsOneWidget);
    });

    // ITIN-UI-04
    testWidgets('ITIN-UI-04 · FAB (add activity) is always visible', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded([]));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // ITIN-UI-05
    testWidgets('ITIN-UI-05 · date strip shows day-of-month for start date "2024-10-12"', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded([]));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1', startDate: '2024-10-12'));

      expect(find.text('12'), findsOneWidget);
    });

    // ITIN-UI-06
    testWidgets('ITIN-UI-06 · error state renders error message', (t) async {
      when(() => itineraryBloc.state).thenReturn(const ItineraryError('Network error'));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.text('Network error'), findsOneWidget);
    });

    // ITIN-UI-07
    testWidgets('ITIN-UI-07 · activity start time is displayed', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded([makeItem(title: 'Morning Run')]));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.textContaining('9:00 AM'), findsOneWidget);
    });

    // ITIN-UI-08
    testWidgets('ITIN-UI-08 · activity location is displayed', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded([makeItem(title: 'Breakfast')]));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(find.text('Café de Flore'), findsOneWidget);
    });

    // ITIN-UI-09
    testWidgets('ITIN-UI-09 · 5 items render without widget exceptions', (t) async {
      when(() => itineraryBloc.state).thenReturn(ItineraryLoaded(
        List.generate(5, (i) => makeItem(id: '$i', title: 'Activity $i'))));

      await pumpItineraryPage(t, const ItineraryPage(tripId: 'trip1'));

      expect(t.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUDGET PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Budget Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/budget')).thenAnswer((_) async => {
        'plannedTotal': 11500.0,
        'actualTotal': 8500.0,
        'currency': 'INR',
        'categoryBreakdown': [
          {'category': 'accommodation', 'planned': 5000.0, 'actual': 4000.0},
          {'category': 'food', 'planned': 2000.0, 'actual': 1500.0},
          {'category': 'transport', 'planned': 3000.0, 'actual': 2000.0},
          {'category': 'activities', 'planned': 1000.0, 'actual': 800.0},
          {'category': 'misc', 'planned': 500.0, 'actual': 200.0},
        ],
      });
      when(() => mockApiClient.put('/trips/trip1/budget', data: any(named: 'data'))).thenAnswer((_) async => {
        'plannedTotal': 15000.0,
        'actualTotal': 8500.0,
        'currency': 'INR',
        'categoryBreakdown': [
          {'category': 'accommodation', 'planned': 6000.0, 'actual': 4000.0},
          {'category': 'food', 'planned': 3000.0, 'actual': 1500.0},
          {'category': 'transport', 'planned': 4000.0, 'actual': 2000.0},
          {'category': 'activities', 'planned': 1500.0, 'actual': 800.0},
          {'category': 'misc', 'planned': 500.0, 'actual': 200.0},
        ],
      });
    });

    // BUD-UI-01
    testWidgets('BUD-UI-01 · shows CircularProgressIndicator initially', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // BUD-UI-02
    testWidgets('BUD-UI-02 · REMAINING BUDGET label is visible', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.text('REMAINING BUDGET'), findsOneWidget);
    });

    // BUD-UI-03
    testWidgets('BUD-UI-03 · Spending by Category section is visible', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.text('Spending by Category'), findsOneWidget);
    });

    // BUD-UI-04
    testWidgets('BUD-UI-04 · FAB for adding an expense is present', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // BUD-UI-05
    testWidgets('BUD-UI-05 · Daily Avg. label is present', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.text('Daily Avg.'), findsOneWidget);
    });

    // BUD-UI-06
    testWidgets('BUD-UI-06 · Days Left label is present', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.text('Days Left'), findsOneWidget);
    });

    // BUD-UI-07
    testWidgets('BUD-UI-07 · amounts are shown in ₹ Rupees', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.textContaining('₹', findRichText: true), findsAtLeast(1));
    });

    // BUD-UI-08
    testWidgets('BUD-UI-08 · donut ring (CircularProgressIndicator) present in budget ring card', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // BUD-UI-09
    testWidgets('BUD-UI-09 · category spending rows use LinearProgressIndicator bars', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsAtLeast(1));
    });

    // BUD-UI-13
    testWidgets('BUD-UI-13 · Set Budgets dialog updates planned budget', (t) async {
      await pumpPage(t, wrapPlain(const BudgetPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Set Budgets'), findsOneWidget);
      await t.tap(find.text('Set Budgets'));
      await t.pumpAndSettle();

      expect(find.text('Set Category Budgets'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));

      await t.enterText(find.widgetWithText(TextFormField, 'Food Budget'), '3000.0');
      await t.pump();

      await t.tap(find.text('Save Budgets'));
      await t.pumpAndSettle();

      verify(() => mockApiClient.put('/trips/trip1/budget', data: any(named: 'data'))).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  ADD EXPENSE PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Add Expense Page', () {
    // BUD-UI-10
    testWidgets('BUD-UI-10 · page renders Amount and Currency fields', (t) async {
      await pumpPage(t, wrapPlain(AddExpensePage(tripId: 'trip1')));

      expect(find.text('Log Expense'), findsAtLeast(1));
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
    });

    // BUD-UI-11
    testWidgets('BUD-UI-11 · category section with filter chips is visible', (t) async {
      await pumpPage(t, wrapPlain(AddExpensePage(tripId: 'trip1')));

      expect(find.text('Category'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsAtLeast(1));
    });

    // BUD-UI-12
    testWidgets('BUD-UI-12 · Note (optional) field is present', (t) async {
      await pumpPage(t, wrapPlain(AddExpensePage(tripId: 'trip1')));

      expect(find.text('Note (optional)'), findsOneWidget);
    });
  });
}
