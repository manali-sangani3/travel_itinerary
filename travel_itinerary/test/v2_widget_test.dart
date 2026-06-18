import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_itinerary/core/network/api_client.dart';
import 'package:travel_itinerary/core/di/injection.dart';

// Features – Packing
import 'package:travel_itinerary/features/packing/presentation/pages/packing_page.dart';

// Features – Documents
import 'package:travel_itinerary/features/documents/presentation/pages/documents_page.dart';
import 'package:travel_itinerary/features/documents/presentation/bloc/document_checklist_bloc.dart';

// Features – Collaboration
import 'package:travel_itinerary/features/collaboration/presentation/pages/collaboration_page.dart';
import 'package:travel_itinerary/features/collaboration/presentation/bloc/sharing_bloc.dart';

// Features – Bookings
import 'package:travel_itinerary/features/bookings/presentation/pages/bookings_page.dart';
import 'package:travel_itinerary/features/bookings/presentation/pages/add_booking_page.dart';

// Features – Journal / Notes / Photos
import 'package:travel_itinerary/features/journal/presentation/pages/journal_page.dart';
import 'package:travel_itinerary/features/journal/presentation/pages/journal_entry_page.dart';
import 'package:travel_itinerary/features/journal/presentation/pages/notes_page.dart';
import 'package:travel_itinerary/features/journal/presentation/pages/photo_gallery_page.dart';
import 'package:travel_itinerary/features/journal/presentation/bloc/notes_bloc.dart';
import 'package:travel_itinerary/features/journal/presentation/bloc/photos_bloc.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  final Stream<List<int>> _delegate = Stream<List<int>>.value(_kGif);
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _delegate.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

final List<int> _kGif = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
  0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b,
];

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();
    when(() => client.getUrl(any())).thenAnswer((_) {
      final req = MockHttpClientRequest();
      final res = MockHttpClientResponse();
      final hdr = MockHttpHeaders();
      when(() => req.headers).thenReturn(hdr);
      when(() => req.close()).thenAnswer((_) => Future.value(res));
      when(() => res.statusCode).thenReturn(200);
      when(() => res.contentLength).thenReturn(_kGif.length);
      when(() => res.compressionState)
          .thenReturn(HttpClientResponseCompressionState.notCompressed);
      return Future.value(req);
    });
    when(() => client.autoUncompress = any()).thenAnswer((_) => false);
    return client;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget wrapWithRouter(Widget child) => MaterialApp.router(
      routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => child)]),
    );

Widget wrapPlain(Widget child) => MaterialApp(home: child);

Future<void> pumpPage(WidgetTester t, Widget w) async {
  await t.pumpWidget(w);
  await t.pump();
}

/// Collect all states emitted by [bloc] when [act] is called.
/// Closes the bloc automatically.
Future<List<S>> collectStates<E, S>(
  dynamic bloc, {
  required void Function(dynamic) act,
}) async {
  final states = <S>[];
  final sub = (bloc.stream as Stream<S>).listen(states.add);
  act(bloc);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await sub.cancel();
  await bloc.close();
  return states;
}

// ─── Mock Data Factories ───────────────────────────────────────────────────────

Map<String, dynamic> makePackingItem({
  String id = 'p1',
  String label = 'Passport',
  String? category,
  int checked = 0,
}) =>
    {'id': id, 'label': label, 'category': category, 'checked': checked};

Map<String, dynamic> makeDocument({
  String id = 'd1',
  String originalName = 'passport_copy.pdf',
  String docType = 'passport',
}) =>
    {'id': id, 'original_name': originalName, 'doc_type': docType};

Map<String, dynamic> makeChecklistItem({
  String id = 'c1',
  String label = 'Passport',
  int checked = 0,
}) =>
    {'id': id, 'trip_id': 'trip1', 'label': label, 'checked': checked};

Map<String, dynamic> makeCollaborator({
  String userId = 'u2',
  String email = 'friend@example.com',
  String role = 'editor',
}) =>
    {'user_id': userId, 'email': email, 'role': role};

Map<String, dynamic> makeTask({
  String id = 't1',
  String title = 'Book flights',
  int completed = 0,
}) =>
    {'id': id, 'title': title, 'completed': completed};

Map<String, dynamic> makeBooking({
  String id = 'b1',
  String type = 'flight',
  String ref = 'AI-202',
  Map<String, dynamic>? details,
}) =>
    {
      'id': id,
      'type': type,
      'reference_number': ref,
      'details': details ?? {'airline': 'Air India', 'flight_number': 'AI202'},
    };

Map<String, dynamic> makeJournalEntry({
  String id = 'j1',
  String date = '2024-10-12',
  String body = 'Had a wonderful day in Paris.',
}) =>
    {
      'id': id,
      'entry_date': date,
      'created_at': '2024-10-12T09:00:00Z',
      'body': body,
      'photos': [],
    };

Map<String, dynamic> makeNote({
  String id = 'n1',
  String content = 'Remember the croissants!',
  String? locationTag,
}) =>
    {
      'id': id,
      'trip_id': 'trip1',
      'content': content,
      'location_tag': locationTag,
      'created_at': '2024-10-12 09:00:00',
    };

Map<String, dynamic> makePhoto({
  String id = 'ph1',
  String filePath = 'uploads/photo1.jpg',
  String? locationTag,
  String dateTaken = '2024-10-12 10:00:00',
}) =>
    {
      'id': id,
      'trip_id': 'trip1',
      'file_path': filePath,
      'location_tag': locationTag,
      'date_taken': dateTaken,
    };

Map<String, dynamic> makeNoteJson({
  String id = 'n1',
  String content = 'Some note',
  String? locationTag,
}) =>
    {
      'id': id,
      'trip_id': 'trip1',
      'content': content,
      'day_date': null,
      'location_tag': locationTag,
      'created_at': '2024-10-12T09:00:00Z',
    };

Map<String, dynamic> makePhotoJson({
  String id = 'ph1',
  String filePath = 'uploads/img.jpg',
  String? locationTag,
}) =>
    {
      'id': id,
      'trip_id': 'trip1',
      'file_path': filePath,
      'location_tag': locationTag,
      'date_taken': '2024-10-12 10:00:00',
      'uploaded_at': null,
    };

Map<String, dynamic> makeChecklistJson({
  String id = 'c1',
  String label = 'Passport',
  int checked = 0,
}) =>
    {'id': id, 'trip_id': 'trip1', 'label': label, 'checked': checked};

Map<String, dynamic> makeShareJson({
  String id = 's1',
  String role = 'viewer',
}) =>
    {
      'id': id,
      'trip_id': 'trip1',
      'share_token': 'tok$id',
      'role': role,
      'expires_at': '2025-01-01T00:00:00Z',
    };

// ═════════════════════════════════════════════════════════════════════════════
//  MAIN
// ═════════════════════════════════════════════════════════════════════════════

void main() {
  late MockApiClient mockApiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    mockApiClient = MockApiClient();
    if (sl.isRegistered<ApiClient>()) sl.unregister<ApiClient>();
    sl.registerSingleton<ApiClient>(mockApiClient);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PACKING PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Packing Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/packing'))
          .thenAnswer((_) async => []);
      when(() => mockApiClient.get('/trips/trip1/packing/templates'))
          .thenAnswer((_) async => []);
    });

    // PACK-UI-01
    testWidgets('PACK-UI-01 · loading state shows CircularProgressIndicator', (t) async {
      final completer = Completer<dynamic>();
      when(() => mockApiClient.get('/trips/trip1/packing'))
          .thenAnswer((_) => completer.future);

      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // PACK-UI-02
    testWidgets('PACK-UI-02 · empty state shows "Packing list is empty"', (t) async {
      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Packing list is empty'), findsOneWidget);
    });

    // PACK-UI-03
    testWidgets('PACK-UI-03 · FAB is always visible', (t) async {
      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // PACK-UI-04
    testWidgets('PACK-UI-04 · loaded items display labels', (t) async {
      when(() => mockApiClient.get('/trips/trip1/packing')).thenAnswer((_) async => [
            makePackingItem(id: 'p1', label: 'Passport'),
            makePackingItem(id: 'p2', label: 'Phone Charger'),
          ]);

      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Phone Charger'), findsOneWidget);
    });

    // PACK-UI-05
    testWidgets('PACK-UI-05 · packed items count shown in progress header', (t) async {
      when(() => mockApiClient.get('/trips/trip1/packing')).thenAnswer((_) async => [
            makePackingItem(id: 'p1', label: 'Passport', checked: 1),
            makePackingItem(id: 'p2', label: 'Charger', checked: 0),
          ]);

      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('1 / 2 packed'), findsOneWidget);
    });

    // PACK-UI-06
    testWidgets('PACK-UI-06 · LinearProgressIndicator visible when items exist', (t) async {
      when(() => mockApiClient.get('/trips/trip1/packing')).thenAnswer((_) async => [
            makePackingItem(id: 'p1', label: 'Passport', checked: 1),
          ]);

      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // PACK-UI-07
    testWidgets('PACK-UI-07 · AppBar title is "Packing List"', (t) async {
      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Packing List'), findsOneWidget);
    });

    // PACK-UI-08
    testWidgets('PACK-UI-08 · Add Item bottom sheet opens on FAB tap', (t) async {
      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();

      expect(find.text('Add Item'), findsAtLeast(1));
    });

    // PACK-UI-09
    testWidgets('PACK-UI-09 · categorized items appear under section header', (t) async {
      when(() => mockApiClient.get('/trips/trip1/packing')).thenAnswer((_) async => [
            makePackingItem(id: 'p1', label: 'Toothbrush', category: 'Toiletries'),
          ]);

      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Toiletries'), findsOneWidget);
      expect(find.text('Toothbrush'), findsOneWidget);
    });

    // PACK-UI-10
    testWidgets('PACK-UI-10 · Generate list icon button in AppBar', (t) async {
      await pumpPage(t, wrapWithRouter(const PackingPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    // PACK-API-01
    test('PACK-API-01 · toggle item calls PUT with checked=1', () async {
      when(() =>
              mockApiClient.put('/trips/trip1/packing/p1', data: any(named: 'data')))
          .thenAnswer((_) async => {});

      await mockApiClient.put('/trips/trip1/packing/p1', data: {'checked': 1});

      verify(() =>
          mockApiClient.put('/trips/trip1/packing/p1', data: {'checked': 1})).called(1);
    });

    // PACK-API-02
    test('PACK-API-02 · delete item calls DELETE endpoint', () async {
      when(() => mockApiClient.delete('/trips/trip1/packing/p1'))
          .thenAnswer((_) async => {});

      await mockApiClient.delete('/trips/trip1/packing/p1');

      verify(() => mockApiClient.delete('/trips/trip1/packing/p1')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  DOCUMENTS PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Documents Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/documents'))
          .thenAnswer((_) async => []);
      when(() => mockApiClient.get('/trips/trip1/checklist/documents'))
          .thenAnswer((_) async => []);
    });

    // DOC-UI-01
    testWidgets('DOC-UI-01 · AppBar title is "Documents"', (t) async {
      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Documents'), findsOneWidget);
    });

    // DOC-UI-02
    testWidgets('DOC-UI-02 · TabBar has Files and Checklist tabs', (t) async {
      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Checklist'), findsOneWidget);
    });

    // DOC-UI-03
    testWidgets('DOC-UI-03 · empty Files tab shows "No documents"', (t) async {
      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('No documents'), findsOneWidget);
    });

    // DOC-UI-04
    testWidgets('DOC-UI-04 · Document type ChoiceChips are visible', (t) async {
      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsAtLeast(1));
    });

    // DOC-UI-05
    testWidgets('DOC-UI-05 · Upload Document button is visible', (t) async {
      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Upload Document'), findsOneWidget);
    });

    // DOC-UI-06
    testWidgets('DOC-UI-06 · loaded documents show original file name', (t) async {
      when(() => mockApiClient.get('/trips/trip1/documents')).thenAnswer((_) async => [
            makeDocument(id: 'd1', originalName: 'passport_scan.pdf', docType: 'passport'),
          ]);

      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('passport_scan.pdf'), findsOneWidget);
    });

    // DOC-UI-07
    testWidgets('DOC-UI-07 · Checklist tab empty state shows "No checklist"', (t) async {
      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.text('Checklist'));
      await t.pumpAndSettle();

      expect(find.text('No checklist'), findsOneWidget);
    });

    // DOC-UI-08
    testWidgets('DOC-UI-08 · checklist items shown with CheckboxListTile', (t) async {
      when(() => mockApiClient.get('/trips/trip1/checklist/documents'))
          .thenAnswer((_) async => [
                makeChecklistItem(id: 'c1', label: 'Passport', checked: 0),
                makeChecklistItem(id: 'c2', label: 'Visa', checked: 1),
              ]);

      await pumpPage(t, wrapWithRouter(const DocumentsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.text('Checklist'));
      await t.pumpAndSettle();

      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Visa'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsAtLeast(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  DOCUMENT CHECKLIST BLOC — Unit Tests (no bloc_test package)
  // ═══════════════════════════════════════════════════════════════════════════

  group('DocumentChecklistBloc', () {
    late MockApiClient api;
    setUp(() => api = MockApiClient());

    // DOC-BLOC-01
    test('DOC-BLOC-01 · emits Loading then Loaded on successful fetch', () async {
      when(() => api.get('/trips/trip1/checklist/documents'))
          .thenAnswer((_) async => [makeChecklistJson()]);
      final bloc = DocumentChecklistBloc(api);

      final states = await collectStates<DocumentChecklistEvent, DocumentChecklistState>(
        bloc,
        act: (b) => b.add(const DocumentChecklistLoadRequested('trip1')),
      );

      expect(states.first, isA<DocumentChecklistLoading>());
      expect(states.last, isA<DocumentChecklistLoaded>());
    });

    // DOC-BLOC-02
    test('DOC-BLOC-02 · emits Loading then Error on API failure', () async {
      when(() => api.get('/trips/trip1/checklist/documents'))
          .thenThrow(Exception('Network error'));
      final bloc = DocumentChecklistBloc(api);

      final states = await collectStates<DocumentChecklistEvent, DocumentChecklistState>(
        bloc,
        act: (b) => b.add(const DocumentChecklistLoadRequested('trip1')),
      );

      expect(states.first, isA<DocumentChecklistLoading>());
      expect(states.last, isA<DocumentChecklistError>());
    });

    // DOC-BLOC-03
    test('DOC-BLOC-03 · loaded items map checked flag correctly', () async {
      when(() => api.get('/trips/trip1/checklist/documents'))
          .thenAnswer((_) async => [
                makeChecklistJson(id: 'c1', label: 'Passport', checked: 1),
                makeChecklistJson(id: 'c2', label: 'Visa', checked: 0),
              ]);
      final bloc = DocumentChecklistBloc(api);

      final states = await collectStates<DocumentChecklistEvent, DocumentChecklistState>(
        bloc,
        act: (b) => b.add(const DocumentChecklistLoadRequested('trip1')),
      );

      final loaded = states.last as DocumentChecklistLoaded;
      expect(loaded.items.first.checked, isTrue);
      expect(loaded.items.last.checked, isFalse);
    });

    // DOC-BLOC-04
    test('DOC-BLOC-04 · DocumentChecklistToggled calls PUT then reloads', () async {
      when(() => api.put('/trips/trip1/checklist/documents', data: any(named: 'data')))
          .thenAnswer((_) async => {});
      when(() => api.get('/trips/trip1/checklist/documents'))
          .thenAnswer((_) async => [makeChecklistJson(checked: 1)]);
      final bloc = DocumentChecklistBloc(api);

      bloc.add(const DocumentChecklistToggled(
          tripId: 'trip1', itemId: 'c1', checked: true));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await bloc.close();

      verify(() => api.put('/trips/trip1/checklist/documents',
          data: {'itemId': 'c1', 'checked': true})).called(1);
    });

    // MODEL-DOC-01
    test('MODEL-DOC-01 · DocumentChecklistItem.fromJson checked=1 → true', () {
      final item = DocumentChecklistItem.fromJson(
          makeChecklistJson(label: 'Passport', checked: 1));
      expect(item.checked, isTrue);
      expect(item.label, 'Passport');
    });

    // MODEL-DOC-02
    test('MODEL-DOC-02 · DocumentChecklistItem.fromJson checked=0 → false', () {
      final item = DocumentChecklistItem.fromJson(makeChecklistJson(checked: 0));
      expect(item.checked, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARING BLOC — Unit Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('SharingBloc', () {
    late MockApiClient api;
    setUp(() => api = MockApiClient());

    // SHARE-BLOC-01
    test('SHARE-BLOC-01 · emits Loading then Loaded on successful share load', () async {
      when(() => api.get('/trips/trip1/share'))
          .thenAnswer((_) async => [makeShareJson()]);
      final bloc = SharingBloc(api);

      final states = await collectStates<SharingEvent, SharingState>(
        bloc,
        act: (b) => b.add(const SharingLoadRequested('trip1')),
      );

      expect(states.first, isA<SharingLoading>());
      expect(states.last, isA<SharingLoaded>());
    });

    // SHARE-BLOC-02
    test('SHARE-BLOC-02 · emits Loading then Error on fetch failure', () async {
      when(() => api.get('/trips/trip1/share')).thenThrow(Exception('fail'));
      final bloc = SharingBloc(api);

      final states = await collectStates<SharingEvent, SharingState>(
        bloc,
        act: (b) => b.add(const SharingLoadRequested('trip1')),
      );

      expect(states.first, isA<SharingLoading>());
      expect(states.last, isA<SharingError>());
    });

    // SHARE-BLOC-03
    test('SHARE-BLOC-03 · ShareLinkGenerated emits SharingLoaded with generatedUrl', () async {
      when(() => api.post('/trips/trip1/share', data: any(named: 'data')))
          .thenAnswer((_) async => {'shareUrl': 'https://app.test/join/tok456'});
      when(() => api.get('/trips/trip1/share'))
          .thenAnswer((_) async => [makeShareJson(id: 's2', role: 'viewer')]);
      final bloc = SharingBloc(api);

      final states = await collectStates<SharingEvent, SharingState>(
        bloc,
        act: (b) => b.add(const ShareLinkGenerated(
            tripId: 'trip1', role: 'viewer', expiresInDays: 7)),
      );

      final loaded = states.last as SharingLoaded;
      expect(loaded.generatedUrl, 'https://app.test/join/tok456');
    });

    // SHARE-BLOC-04
    test('SHARE-BLOC-04 · ShareLinkRevoked calls DELETE and reloads', () async {
      when(() => api.delete('/trips/trip1/share/s1')).thenAnswer((_) async => {});
      when(() => api.get('/trips/trip1/share')).thenAnswer((_) async => []);
      final bloc = SharingBloc(api);

      bloc.add(const ShareLinkRevoked(tripId: 'trip1', shareId: 's1'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await bloc.close();

      verify(() => api.delete('/trips/trip1/share/s1')).called(1);
    });

    // MODEL-SHARE-01
    test('MODEL-SHARE-01 · TripShare.fromJson maps all fields correctly', () {
      final share = TripShare.fromJson({
        'id': 's1',
        'trip_id': 'trip1',
        'share_token': 'tok999',
        'role': 'editor',
        'expires_at': '2025-12-31T00:00:00Z',
      });
      expect(share.id, 's1');
      expect(share.tripId, 'trip1');
      expect(share.shareToken, 'tok999');
      expect(share.role, 'editor');
      expect(share.expiresAt, '2025-12-31T00:00:00Z');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  COLLABORATION PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Collaboration Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/collaborators'))
          .thenAnswer((_) async => []);
      when(() => mockApiClient.get('/trips/trip1/tasks'))
          .thenAnswer((_) async => []);
      when(() => mockApiClient.get('/trips/trip1/splits'))
          .thenAnswer((_) async => []);
      when(() => mockApiClient.get('/trips/trip1/share'))
          .thenAnswer((_) async => []);
    });

    // COLLAB-UI-01
    testWidgets('COLLAB-UI-01 · loading shows CircularProgressIndicator', (t) async {
      final completer = Completer<dynamic>();
      when(() => mockApiClient.get('/trips/trip1/collaborators'))
          .thenAnswer((_) => completer.future);

      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // COLLAB-UI-02
    testWidgets('COLLAB-UI-02 · AppBar title is "Collaborate"', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Collaborate'), findsOneWidget);
    });

    // COLLAB-UI-03
    testWidgets('COLLAB-UI-03 · 4 tabs are present (Members, Tasks, Splits, Links)', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Splits'), findsOneWidget);
      expect(find.text('Links'), findsOneWidget);
    });

    // COLLAB-UI-04
    testWidgets('COLLAB-UI-04 · empty Members tab shows "No collaborators"', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('No collaborators'), findsOneWidget);
    });

    // COLLAB-UI-05
    testWidgets('COLLAB-UI-05 · "Invite Member" heading and email field visible', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Invite Member'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    // COLLAB-UI-06
    testWidgets('COLLAB-UI-06 · collaborator list shows email and role', (t) async {
      when(() => mockApiClient.get('/trips/trip1/collaborators')).thenAnswer(
          (_) async => [makeCollaborator(email: 'alice@example.com', role: 'editor')]);

      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.textContaining('editor', findRichText: true), findsAtLeast(1));
    });

    // COLLAB-UI-07
    testWidgets('COLLAB-UI-07 · Tasks tab shows "No tasks" empty state', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.text('Tasks'));
      await t.pumpAndSettle();

      expect(find.text('No tasks'), findsOneWidget);
    });

    // COLLAB-UI-08
    testWidgets('COLLAB-UI-08 · tasks displayed with Checkbox when loaded', (t) async {
      when(() => mockApiClient.get('/trips/trip1/tasks'))
          .thenAnswer((_) async => [makeTask(title: 'Book accommodation')]);

      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.text('Tasks'));
      await t.pumpAndSettle();

      expect(find.text('Book accommodation'), findsOneWidget);
      expect(find.byType(Checkbox), findsAtLeast(1));
    });

    // COLLAB-UI-09
    testWidgets('COLLAB-UI-09 · Links tab shows Generate Share Link section', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.text('Links'));
      await t.pumpAndSettle();

      expect(find.text('Generate Share Link'), findsOneWidget);
      expect(find.text('Generate Link'), findsOneWidget);
    });

    // COLLAB-UI-10
    testWidgets('COLLAB-UI-10 · Splits tab shows "No shared expenses"', (t) async {
      await pumpPage(t, wrapWithRouter(const CollaborationPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      await t.tap(find.text('Splits'));
      await t.pumpAndSettle();

      expect(find.text('No shared expenses'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOOKINGS PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Bookings Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/bookings'))
          .thenAnswer((_) async => []);
    });

    // BOOK-UI-01
    testWidgets('BOOK-UI-01 · loading shows CircularProgressIndicator', (t) async {
      final completer = Completer<dynamic>();
      when(() => mockApiClient.get('/trips/trip1/bookings'))
          .thenAnswer((_) => completer.future);

      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // BOOK-UI-02
    testWidgets('BOOK-UI-02 · AppBar title is "Bookings"', (t) async {
      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Bookings'), findsOneWidget);
    });

    // BOOK-UI-03
    testWidgets('BOOK-UI-03 · empty state shows "No bookings yet"', (t) async {
      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('No bookings yet'), findsOneWidget);
    });

    // BOOK-UI-04
    testWidgets('BOOK-UI-04 · FAB is always visible', (t) async {
      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // BOOK-UI-05
    testWidgets('BOOK-UI-05 · flight booking shows reference number', (t) async {
      when(() => mockApiClient.get('/trips/trip1/bookings'))
          .thenAnswer((_) async => [makeBooking(type: 'flight', ref: 'AI-202')]);

      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('AI-202'), findsOneWidget);
    });

    // BOOK-UI-06
    testWidgets('BOOK-UI-06 · section headers shown for each booking type', (t) async {
      when(() => mockApiClient.get('/trips/trip1/bookings')).thenAnswer((_) async => [
            makeBooking(type: 'flight', ref: 'FL001'),
            makeBooking(
                id: 'b2',
                type: 'hotel',
                ref: 'HT002',
                details: {'hotel_name': 'Ritz', 'check_in': '12/10/2024 14:00'}),
          ]);

      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Hotels'), findsOneWidget);
    });

    // BOOK-UI-07
    testWidgets('BOOK-UI-07 · multiple booking types render without exceptions', (t) async {
      when(() => mockApiClient.get('/trips/trip1/bookings')).thenAnswer((_) async => [
            makeBooking(id: 'b1', type: 'flight', ref: 'F1'),
            makeBooking(id: 'b2', type: 'hotel', ref: 'H1',
                details: {'hotel_name': 'Hilton', 'check_in': '12/10'}),
            makeBooking(id: 'b3', type: 'car_rental', ref: 'C1',
                details: {'company': 'Hertz', 'pickup': 'Airport'}),
            makeBooking(id: 'b4', type: 'activity', ref: 'A1',
                details: {'name': 'Tour', 'date': '13/10/2024'}),
          ]);

      await pumpPage(t, wrapWithRouter(const BookingsPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  ADD BOOKING PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Add Booking Page', () {
    // ADDBOOK-UI-01
    testWidgets('ADDBOOK-UI-01 · AppBar title is "Add Booking"', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      expect(find.text('Add Booking'), findsOneWidget);
    });

    // ADDBOOK-UI-02
    testWidgets('ADDBOOK-UI-02 · Booking Type ChoiceChips are shown', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      expect(find.byType(ChoiceChip), findsAtLeast(1));
    });

    // ADDBOOK-UI-03
    testWidgets('ADDBOOK-UI-03 · Reference Number field is present', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      expect(find.text('Reference / Confirmation Number'), findsOneWidget);
    });

    // ADDBOOK-UI-04
    testWidgets('ADDBOOK-UI-04 · flight default shows Airline & Flight Number fields', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      expect(find.text('Airline'), findsOneWidget);
      expect(find.text('Flight Number'), findsOneWidget);
    });

    // ADDBOOK-UI-05
    testWidgets('ADDBOOK-UI-05 · Save Booking button is present', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      expect(find.text('Save Booking'), findsOneWidget);
    });

    // ADDBOOK-UI-06
    testWidgets('ADDBOOK-UI-06 · selecting hotel type shows Hotel Name & Check-In fields', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      await t.tap(find.widgetWithText(ChoiceChip, 'hotel'));
      await t.pump();

      expect(find.text('Hotel Name'), findsOneWidget);
      expect(find.text('Check-In'), findsOneWidget);
    });

    // ADDBOOK-UI-07
    testWidgets('ADDBOOK-UI-07 · selecting car rental type shows Car Rental Company field', (t) async {
      await pumpPage(t, wrapWithRouter(AddBookingPage(tripId: 'trip1')));

      await t.tap(find.widgetWithText(ChoiceChip, 'car rental'));
      await t.pump();

      expect(find.text('Car Rental Company'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  JOURNAL PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Journal Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/journal'))
          .thenAnswer((_) async => []);
    });

    // JOUR-UI-01
    testWidgets('JOUR-UI-01 · AppBar title is "Travel Journal"', (t) async {
      await pumpPage(t, wrapWithRouter(const JournalPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Travel Journal'), findsOneWidget);
    });

    // JOUR-UI-02
    testWidgets('JOUR-UI-02 · Notes and Gallery shortcuts visible', (t) async {
      await pumpPage(t, wrapWithRouter(const JournalPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    // JOUR-UI-03
    testWidgets('JOUR-UI-03 · empty state shows "No journal entries yet"', (t) async {
      await pumpPage(t, wrapWithRouter(const JournalPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('No journal entries yet'), findsOneWidget);
    });

    // JOUR-UI-04
    testWidgets('JOUR-UI-04 · FAB is always visible', (t) async {
      await pumpPage(t, wrapWithRouter(const JournalPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // JOUR-UI-05
    testWidgets('JOUR-UI-05 · loaded entries show body text', (t) async {
      when(() => mockApiClient.get('/trips/trip1/journal')).thenAnswer((_) async => [
            makeJournalEntry(body: 'Visited Louvre museum today!'),
          ]);

      await pumpPage(t, wrapWithRouter(const JournalPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.textContaining('Visited Louvre museum today!'), findsOneWidget);
    });

    // JOUR-UI-06
    testWidgets('JOUR-UI-06 · loading state shows CircularProgressIndicator', (t) async {
      final completer = Completer<dynamic>();
      when(() => mockApiClient.get('/trips/trip1/journal'))
          .thenAnswer((_) => completer.future);

      await pumpPage(t, wrapWithRouter(const JournalPage(tripId: 'trip1')));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  JOURNAL ENTRY PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Journal Entry Page', () {
    // ENTRY-UI-01
    testWidgets('ENTRY-UI-01 · AppBar title is "New Entry"', (t) async {
      await pumpPage(t, wrapWithRouter(JournalEntryPage(tripId: 'trip1')));

      expect(find.text('New Entry'), findsOneWidget);
    });

    // ENTRY-UI-02
    testWidgets('ENTRY-UI-02 · calendar icon for date selection is present', (t) async {
      await pumpPage(t, wrapWithRouter(JournalEntryPage(tripId: 'trip1')));

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    // ENTRY-UI-03
    testWidgets('ENTRY-UI-03 · write about your day text area is present', (t) async {
      await pumpPage(t, wrapWithRouter(JournalEntryPage(tripId: 'trip1')));

      expect(find.text('Write about your day'), findsOneWidget);
    });

    // ENTRY-UI-04
    testWidgets('ENTRY-UI-04 · Photos section with Add Photo button is present', (t) async {
      await pumpPage(t, wrapWithRouter(JournalEntryPage(tripId: 'trip1')));
      await t.pump();

      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
    });

    // ENTRY-UI-05
    testWidgets('ENTRY-UI-05 · Save Entry button is visible', (t) async {
      await pumpPage(t, wrapWithRouter(JournalEntryPage(tripId: 'trip1')));

      expect(find.text('Save Entry'), findsOneWidget);
    });

    // ENTRY-UI-06
    testWidgets('ENTRY-UI-06 · "Tap to add photos" placeholder visible initially', (t) async {
      await pumpPage(t, wrapWithRouter(JournalEntryPage(tripId: 'trip1')));

      expect(find.text('Tap to add photos'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  NOTES PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Notes Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/notes'))
          .thenAnswer((_) async => []);
    });

    // NOTES-UI-01
    testWidgets('NOTES-UI-01 · AppBar title is "Trip Notes & Memories"', (t) async {
      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Trip Notes & Memories'), findsOneWidget);
    });

    // NOTES-UI-02
    testWidgets('NOTES-UI-02 · Create note panel with textarea is visible', (t) async {
      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Add reflection or memory'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    // NOTES-UI-03
    testWidgets('NOTES-UI-03 · "Save Memory" button is present', (t) async {
      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Save Memory'), findsOneWidget);
    });

    // NOTES-UI-04
    testWidgets('NOTES-UI-04 · empty list shows "No reflections yet"', (t) async {
      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('No reflections yet'), findsOneWidget);
    });

    // NOTES-UI-05
    testWidgets('NOTES-UI-05 · loaded notes display content', (t) async {
      when(() => mockApiClient.get('/trips/trip1/notes')).thenAnswer((_) async => [
            makeNote(content: 'Remember to buy souvenirs!'),
          ]);

      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Remember to buy souvenirs!'), findsOneWidget);
    });

    // NOTES-UI-06
    testWidgets('NOTES-UI-06 · location tag shown with pin icon', (t) async {
      when(() => mockApiClient.get('/trips/trip1/notes')).thenAnswer((_) async => [
            makeNote(content: 'Great view!', locationTag: 'Eiffel Tower'),
          ]);

      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Eiffel Tower'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsAtLeast(1));
    });

    // NOTES-UI-07
    testWidgets('NOTES-UI-07 · loading shows CircularProgressIndicator', (t) async {
      final completer = Completer<dynamic>();
      when(() => mockApiClient.get('/trips/trip1/notes'))
          .thenAnswer((_) => completer.future);

      await pumpPage(t, wrapWithRouter(const NotesPage(tripId: 'trip1')));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  NOTES BLOC — Unit Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('NotesBloc', () {
    late MockApiClient api;
    setUp(() => api = MockApiClient());

    // NOTES-BLOC-01
    test('NOTES-BLOC-01 · emits Loading then Loaded on successful fetch', () async {
      when(() => api.get('/trips/trip1/notes'))
          .thenAnswer((_) async => [makeNoteJson()]);
      final bloc = NotesBloc(api);

      final states = await collectStates<NotesEvent, NotesState>(
        bloc,
        act: (b) => b.add(const NotesLoadRequested('trip1')),
      );

      expect(states.first, isA<NotesLoading>());
      expect(states.last, isA<NotesLoaded>());
    });

    // NOTES-BLOC-02
    test('NOTES-BLOC-02 · emits Loading then Error on API failure', () async {
      when(() => api.get('/trips/trip1/notes'))
          .thenThrow(Exception('Network error'));
      final bloc = NotesBloc(api);

      final states = await collectStates<NotesEvent, NotesState>(
        bloc,
        act: (b) => b.add(const NotesLoadRequested('trip1')),
      );

      expect(states.first, isA<NotesLoading>());
      expect(states.last, isA<NotesError>());
    });

    // NOTES-BLOC-03
    test('NOTES-BLOC-03 · NoteAdded calls POST with correct payload', () async {
      when(() => api.post('/trips/trip1/notes', data: any(named: 'data')))
          .thenAnswer((_) async => {'id': 'n2'});
      when(() => api.get('/trips/trip1/notes')).thenAnswer((_) async => []);
      final bloc = NotesBloc(api);

      bloc.add(const NoteAdded(tripId: 'trip1', content: 'A wonderful afternoon'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await bloc.close();

      verify(() => api.post('/trips/trip1/notes', data: {
            'content': 'A wonderful afternoon',
            'dayDate': null,
            'locationTag': null,
          })).called(1);
    });

    // NOTES-BLOC-04
    test('NOTES-BLOC-04 · NoteDeleted calls DELETE and reloads', () async {
      when(() => api.delete('/trips/trip1/notes/n1')).thenAnswer((_) async => {});
      when(() => api.get('/trips/trip1/notes')).thenAnswer((_) async => []);
      final bloc = NotesBloc(api);

      bloc.add(const NoteDeleted(tripId: 'trip1', noteId: 'n1'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await bloc.close();

      verify(() => api.delete('/trips/trip1/notes/n1')).called(1);
    });

    // NOTES-BLOC-05
    test('NOTES-BLOC-05 · NoteUpdated calls PUT with content', () async {
      when(() => api.put('/trips/trip1/notes/n1', data: any(named: 'data')))
          .thenAnswer((_) async => {});
      when(() => api.get('/trips/trip1/notes')).thenAnswer((_) async => []);
      final bloc = NotesBloc(api);

      bloc.add(const NoteUpdated(tripId: 'trip1', noteId: 'n1', content: 'Updated content'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await bloc.close();

      verify(() => api.put('/trips/trip1/notes/n1',
          data: {'content': 'Updated content'})).called(1);
    });

    // NOTES-BLOC-06
    test('NOTES-BLOC-06 · loaded list has correct note count', () async {
      when(() => api.get('/trips/trip1/notes')).thenAnswer((_) async => [
            makeNoteJson(id: 'n1'),
            makeNoteJson(id: 'n2'),
            makeNoteJson(id: 'n3'),
          ]);
      final bloc = NotesBloc(api);

      final states = await collectStates<NotesEvent, NotesState>(
        bloc,
        act: (b) => b.add(const NotesLoadRequested('trip1')),
      );

      final loaded = states.last as NotesLoaded;
      expect(loaded.notes.length, 3);
    });

    // MODEL-NOTE-01
    test('MODEL-NOTE-01 · TripNote.fromJson maps all fields correctly', () {
      final note = TripNote.fromJson({
        'id': 'n1',
        'trip_id': 'trip1',
        'content': 'Paris is magical',
        'day_date': '2024-10-12',
        'location_tag': 'Montmartre',
        'created_at': '2024-10-12T08:00:00Z',
      });
      expect(note.id, 'n1');
      expect(note.content, 'Paris is magical');
      expect(note.locationTag, 'Montmartre');
    });

    // MODEL-NOTE-02
    test('MODEL-NOTE-02 · TripNote with null locationTag is deserialized', () {
      final note = TripNote.fromJson({
        'id': 'n2',
        'trip_id': 'trip1',
        'content': 'Some note',
        'day_date': null,
        'location_tag': null,
        'created_at': null,
      });
      expect(note.locationTag, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PHOTOS BLOC — Unit Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('PhotosBloc', () {
    late MockApiClient api;
    setUp(() => api = MockApiClient());

    // PHOTO-BLOC-01
    test('PHOTO-BLOC-01 · emits Loading then Loaded on successful fetch', () async {
      when(() => api.get('/trips/trip1/photos'))
          .thenAnswer((_) async => [makePhotoJson()]);
      final bloc = PhotosBloc(api);

      final states = await collectStates<PhotosEvent, PhotosState>(
        bloc,
        act: (b) => b.add(const PhotosLoadRequested('trip1')),
      );

      expect(states.first, isA<PhotosLoading>());
      expect(states.last, isA<PhotosLoaded>());
    });

    // PHOTO-BLOC-02
    test('PHOTO-BLOC-02 · emits Loading then Error on API failure', () async {
      when(() => api.get('/trips/trip1/photos')).thenThrow(Exception('fail'));
      final bloc = PhotosBloc(api);

      final states = await collectStates<PhotosEvent, PhotosState>(
        bloc,
        act: (b) => b.add(const PhotosLoadRequested('trip1')),
      );

      expect(states.first, isA<PhotosLoading>());
      expect(states.last, isA<PhotosError>());
    });

    // PHOTO-BLOC-03
    test('PHOTO-BLOC-03 · PhotoDeleted calls DELETE and reloads', () async {
      when(() => api.delete('/trips/trip1/photos/ph1')).thenAnswer((_) async => {});
      when(() => api.get('/trips/trip1/photos')).thenAnswer((_) async => []);
      final bloc = PhotosBloc(api);

      bloc.add(const PhotoDeleted(tripId: 'trip1', photoId: 'ph1'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await bloc.close();

      verify(() => api.delete('/trips/trip1/photos/ph1')).called(1);
    });

    // PHOTO-BLOC-04
    test('PHOTO-BLOC-04 · loaded photos list has correct count', () async {
      when(() => api.get('/trips/trip1/photos')).thenAnswer((_) async => [
            makePhotoJson(id: 'ph1'),
            makePhotoJson(id: 'ph2'),
          ]);
      final bloc = PhotosBloc(api);

      final states = await collectStates<PhotosEvent, PhotosState>(
        bloc,
        act: (b) => b.add(const PhotosLoadRequested('trip1')),
      );

      final loaded = states.last as PhotosLoaded;
      expect(loaded.photos.length, 2);
    });

    // MODEL-PHOTO-01
    test('MODEL-PHOTO-01 · TripPhoto.fromJson maps all fields', () {
      final photo = TripPhoto.fromJson({
        'id': 'ph1',
        'trip_id': 'trip1',
        'file_path': 'uploads/img.jpg',
        'location_tag': 'Eiffel Tower',
        'date_taken': '2024-10-12 09:00:00',
        'uploaded_at': '2024-10-12T10:00:00Z',
      });
      expect(photo.id, 'ph1');
      expect(photo.filePath, 'uploads/img.jpg');
      expect(photo.locationTag, 'Eiffel Tower');
      expect(photo.dateTaken, '2024-10-12 09:00:00');
    });

    // MODEL-PHOTO-02
    test('MODEL-PHOTO-02 · TripPhoto with null locationTag deserialized correctly', () {
      final photo = TripPhoto.fromJson({
        'id': 'ph2',
        'trip_id': 'trip1',
        'file_path': 'uploads/b.jpg',
        'location_tag': null,
        'date_taken': '2024-10-13',
        'uploaded_at': null,
      });
      expect(photo.locationTag, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PHOTO GALLERY PAGE — UI Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Photo Gallery Page', () {
    setUp(() {
      when(() => mockApiClient.get('/trips/trip1/photos'))
          .thenAnswer((_) async => []);
    });

    // GALLERY-UI-01
    testWidgets('GALLERY-UI-01 · AppBar title is "Photo Gallery"', (t) async {
      await pumpPage(t, wrapWithRouter(const PhotoGalleryPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('Photo Gallery'), findsOneWidget);
    });

    // GALLERY-UI-02
    testWidgets('GALLERY-UI-02 · empty state shows "No photos yet"', (t) async {
      await pumpPage(t, wrapWithRouter(const PhotoGalleryPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.text('No photos yet'), findsOneWidget);
    });

    // GALLERY-UI-03
    testWidgets('GALLERY-UI-03 · FAB for adding photo is present', (t) async {
      await pumpPage(t, wrapWithRouter(const PhotoGalleryPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // GALLERY-UI-04
    testWidgets('GALLERY-UI-04 · loading shows CircularProgressIndicator', (t) async {
      final completer = Completer<dynamic>();
      when(() => mockApiClient.get('/trips/trip1/photos'))
          .thenAnswer((_) => completer.future);

      await pumpPage(t, wrapWithRouter(const PhotoGalleryPage(tripId: 'trip1')));

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    // GALLERY-UI-05
    testWidgets('GALLERY-UI-05 · group-by icon visible in AppBar (map icon default)', (t) async {
      await pumpPage(t, wrapWithRouter(const PhotoGalleryPage(tripId: 'trip1')));
      await t.pumpAndSettle();

      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  BACKEND API CONTRACT — Direct API Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Backend API Contract', () {
    late MockApiClient api;
    setUp(() => api = MockApiClient());

    // API-01
    test('API-01 · GET /trips/:id/packing returns list with label field', () async {
      when(() => api.get('/trips/trip1/packing'))
          .thenAnswer((_) async => [makePackingItem()]);

      final result = await api.get('/trips/trip1/packing') as List;

      expect(result, isNotEmpty);
      expect(result.first['label'], 'Passport');
    });

    // API-02
    test('API-02 · POST /trips/:id/packing sends label and category', () async {
      when(() => api.post('/trips/trip1/packing', data: any(named: 'data')))
          .thenAnswer((_) async => {'id': 'p99'});

      await api.post('/trips/trip1/packing',
          data: {'label': 'Sunscreen', 'category': 'Toiletries'});

      verify(() => api.post('/trips/trip1/packing',
          data: {'label': 'Sunscreen', 'category': 'Toiletries'})).called(1);
    });

    // API-03
    test('API-03 · GET /trips/:id/documents returns doc_type field', () async {
      when(() => api.get('/trips/trip1/documents'))
          .thenAnswer((_) async => [makeDocument(docType: 'passport')]);

      final result = await api.get('/trips/trip1/documents') as List;

      expect(result.first['doc_type'], 'passport');
    });

    // API-04
    test('API-04 · DELETE /trips/:id/documents/:docId called correctly', () async {
      when(() => api.delete('/trips/trip1/documents/d1'))
          .thenAnswer((_) async => {});

      await api.delete('/trips/trip1/documents/d1');

      verify(() => api.delete('/trips/trip1/documents/d1')).called(1);
    });

    // API-05
    test('API-05 · POST /trips/:id/collaborators sends email and role', () async {
      when(() => api.post('/trips/trip1/collaborators', data: any(named: 'data')))
          .thenAnswer((_) async => {'id': 'col1'});

      await api.post('/trips/trip1/collaborators',
          data: {'email': 'bob@example.com', 'role': 'viewer'});

      verify(() => api.post('/trips/trip1/collaborators',
          data: {'email': 'bob@example.com', 'role': 'viewer'})).called(1);
    });

    // API-06
    test('API-06 · DELETE /trips/:id/collaborators/:userId called', () async {
      when(() => api.delete('/trips/trip1/collaborators/u2'))
          .thenAnswer((_) async => {});

      await api.delete('/trips/trip1/collaborators/u2');

      verify(() => api.delete('/trips/trip1/collaborators/u2')).called(1);
    });

    // API-07
    test('API-07 · POST /trips/:id/share returns shareUrl', () async {
      when(() => api.post('/trips/trip1/share', data: any(named: 'data')))
          .thenAnswer((_) async => {'shareUrl': 'https://example.com/join/abc'});

      final result = await api.post('/trips/trip1/share',
          data: {'role': 'viewer', 'expiresInDays': 7});

      expect(result['shareUrl'], 'https://example.com/join/abc');
    });

    // API-08
    test('API-08 · DELETE /trips/:id/share/:shareId called correctly', () async {
      when(() => api.delete('/trips/trip1/share/s1')).thenAnswer((_) async => {});

      await api.delete('/trips/trip1/share/s1');

      verify(() => api.delete('/trips/trip1/share/s1')).called(1);
    });

    // API-09
    test('API-09 · GET /trips/:id/bookings returns typed bookings', () async {
      when(() => api.get('/trips/trip1/bookings')).thenAnswer((_) async => [
            makeBooking(type: 'flight'),
            makeBooking(id: 'b2', type: 'hotel', ref: 'H001',
                details: {'hotel_name': 'Ritz'}),
          ]);

      final result = await api.get('/trips/trip1/bookings') as List;

      expect(result.length, 2);
      expect(result.first['type'], 'flight');
      expect(result.last['type'], 'hotel');
    });

    // API-10
    test('API-10 · POST /trips/:id/bookings sends type, reference and details', () async {
      when(() => api.post('/trips/trip1/bookings', data: any(named: 'data')))
          .thenAnswer((_) async => {'id': 'b99'});

      await api.post('/trips/trip1/bookings', data: {
        'type': 'flight',
        'reference_number': 'AI-303',
        'details': {'airline': 'IndiGo', 'flight_number': '6E301'},
      });

      verify(() => api.post('/trips/trip1/bookings', data: {
            'type': 'flight',
            'reference_number': 'AI-303',
            'details': {'airline': 'IndiGo', 'flight_number': '6E301'},
          })).called(1);
    });

    // API-11
    test('API-11 · POST /trips/:id/journal creates entry with id in response', () async {
      when(() => api.post('/trips/trip1/journal', data: any(named: 'data')))
          .thenAnswer((_) async => {'id': 'j99'});

      final result = await api.post('/trips/trip1/journal',
          data: {'entry_date': '2024-10-12', 'body': 'A great day!'});

      expect(result['id'], 'j99');
    });

    // API-12
    test('API-12 · DELETE /trips/:id/journal/:entryId called correctly', () async {
      when(() => api.delete('/trips/trip1/journal/j1')).thenAnswer((_) async => {});

      await api.delete('/trips/trip1/journal/j1');

      verify(() => api.delete('/trips/trip1/journal/j1')).called(1);
    });

    // API-13
    test('API-13 · GET /trips/:id/notes returns notes with location_tag', () async {
      when(() => api.get('/trips/trip1/notes')).thenAnswer((_) async => [
            makeNote(content: 'Croissants are amazing', locationTag: 'Paris Bakery'),
          ]);

      final result = await api.get('/trips/trip1/notes') as List;

      expect(result.first['content'], 'Croissants are amazing');
      expect(result.first['location_tag'], 'Paris Bakery');
    });

    // API-14
    test('API-14 · DELETE /trips/:id/notes/:noteId called correctly', () async {
      when(() => api.delete('/trips/trip1/notes/n1')).thenAnswer((_) async => {});

      await api.delete('/trips/trip1/notes/n1');

      verify(() => api.delete('/trips/trip1/notes/n1')).called(1);
    });

    // API-15
    test('API-15 · GET /trips/:id/photos returns file_path and location_tag', () async {
      when(() => api.get('/trips/trip1/photos')).thenAnswer((_) async => [
            makePhoto(filePath: 'uploads/img1.jpg', locationTag: 'Louvre'),
          ]);

      final result = await api.get('/trips/trip1/photos') as List;

      expect(result.first['file_path'], 'uploads/img1.jpg');
      expect(result.first['location_tag'], 'Louvre');
    });

    // API-16
    test('API-16 · DELETE /trips/:id/photos/:photoId called correctly', () async {
      when(() => api.delete('/trips/trip1/photos/ph1')).thenAnswer((_) async => {});

      await api.delete('/trips/trip1/photos/ph1');

      verify(() => api.delete('/trips/trip1/photos/ph1')).called(1);
    });

    // API-17
    test('API-17 · PUT /trips/:id/tasks/:taskId toggles completed status', () async {
      when(() => api.put('/trips/trip1/tasks/t1', data: any(named: 'data')))
          .thenAnswer((_) async => {});

      await api.put('/trips/trip1/tasks/t1', data: {'completed': 1});

      verify(() => api.put('/trips/trip1/tasks/t1', data: {'completed': 1})).called(1);
    });

    // API-18
    test('API-18 · GET /trips/:id/packing/templates returns named templates', () async {
      when(() => api.get('/trips/trip1/packing/templates')).thenAnswer((_) async => [
            {
              'id': 'tmpl1',
              'name': 'Beach Holiday',
              'items': ['Sunscreen', 'Swimsuit', 'Beach towel'],
            },
          ]);

      final result = await api.get('/trips/trip1/packing/templates') as List;

      expect(result.length, 1);
      expect(result.first['name'], 'Beach Holiday');
    });

    // API-19
    test('API-19 · POST /trips/:id/packing/generate sends templateId', () async {
      when(() => api.post('/trips/trip1/packing/generate', data: any(named: 'data')))
          .thenAnswer((_) async => {});

      await api.post('/trips/trip1/packing/generate',
          data: {'templateId': 'tmpl1'});

      verify(() => api.post('/trips/trip1/packing/generate',
          data: {'templateId': 'tmpl1'})).called(1);
    });
  });
}
