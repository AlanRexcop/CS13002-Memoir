// C:\dev\memoir\test\person_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockAppNotifier extends StateNotifier<AppState>
    with Mock
    implements AppNotifier {
  MockAppNotifier(super.initialState);
}

class MockAppState extends Mock implements AppState {}

// --- FIX: Implement all required getters in FakeUser ---
class FakeUser extends Fake implements User {
  @override
  Map<String, dynamic> get userMetadata => {'username': 'Test User'};

  @override
  String? get email => 'test@example.com';
}

class FakePerson extends Fake implements Person {}

void main() {
  late MockAppNotifier mockAppNotifier;
  late MockAppState mockAppState;
  late List<Person> testPersons;

  setUpAll(() {
    registerFallbackValue(FakePerson());
    registerFallbackValue((text: '', tags: <String>[]));
  });

  setUp(() {
    mockAppState = MockAppState();
    mockAppNotifier = MockAppNotifier(mockAppState);

    testPersons = [
      Person(
        path: 'people/path1',
        info: Note(
          path: 'people/path1/info.md',
          title: 'Alice',
          creationDate: DateTime.now(),
          lastModified: DateTime.now(),
          tags: ['friend'],
        ),
      ),
      Person(
        path: 'people/path2',
        info: Note(
          path: 'people/path2/info.md',
          title: 'Bob',
          creationDate: DateTime.now(),
          lastModified: DateTime.now(),
          tags: ['colleague'],
        ),
      ),
    ];

    // Default stubs
    when(() => mockAppState.filteredPersons).thenReturn(testPersons);
    when(() => mockAppState.persons).thenReturn(testPersons);
    when(() => mockAppState.currentUser).thenReturn(FakeUser());
    when(
      () => mockAppNotifier.createNewPerson(any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockAppNotifier.deletePerson(any()),
    ).thenAnswer((_) async => true);
    when(() => mockAppNotifier.setSearchQuery(any())).thenAnswer((_) {});
  });

  Future<void> pumpPersonListScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appProvider.overrideWith((ref) => mockAppNotifier),
          localAvatarProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('TC1: View contact list', (WidgetTester tester) async {
    await pumpPersonListScreen(tester);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('TC2: Cancel creating a contact', (WidgetTester tester) async {
    await pumpPersonListScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Create New Person'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Person'), findsNothing);
    verifyNever(() => mockAppNotifier.createNewPerson(any()));
  });

  testWidgets('TC3: Create a new contact with a valid name', (
    WidgetTester tester,
  ) async {
    await pumpPersonListScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Charlie');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    verify(() => mockAppNotifier.createNewPerson('Charlie')).called(1);
    expect(find.text('Create New Person'), findsNothing);
    expect(find.textContaining('created successfully'), findsOneWidget);
  });

  testWidgets('TC4: Create a new contact with an empty name', (
    WidgetTester tester,
  ) async {
    await pumpPersonListScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    verify(() => mockAppNotifier.createNewPerson('')).called(1);
    expect(find.textContaining('created successfully'), findsOneWidget);
  });

  testWidgets('TC5: Create a new contact with a space-only name', (
    WidgetTester tester,
  ) async {
    await pumpPersonListScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '   ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    verify(() => mockAppNotifier.createNewPerson('')).called(1);
    expect(find.textContaining('created successfully'), findsOneWidget);
  });

  testWidgets('TC6: Cancel deleting a contact', (WidgetTester tester) async {
    await pumpPersonListScreen(tester);

    final tile = find.widgetWithText(Dismissible, 'Alice');
    await tester.drag(tile, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Deletion'), findsOneWidget);
    expect(
      find.textContaining('Are you sure you want to delete Alice?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Deletion'), findsNothing);
    verifyNever(() => mockAppNotifier.deletePerson(any()));
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('TC7: Delete a contact', (WidgetTester tester) async {
    await pumpPersonListScreen(tester);

    final tile = find.widgetWithText(Dismissible, 'Alice');
    await tester.drag(tile, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Deletion'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => mockAppNotifier.deletePerson(captureAny()),
    ).captured;
    expect((captured.first as Person).info.title, 'Alice');
    expect(find.textContaining('Deleted Alice'), findsOneWidget);
  });
}
