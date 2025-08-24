// C:\dev\memoir\test\person_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/person_detail/notes_tab.dart'; // Import NotesTab
import 'package:memoir/screens/person_detail/person_detail_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockAppNotifier extends StateNotifier<AppState>
    with Mock
    implements AppNotifier {
  MockAppNotifier(super.initialState);
}

class MockAppState extends Mock implements AppState {}

class FakeUser extends Fake implements User {
  @override
  Map<String, dynamic> get userMetadata => {'username': 'Test User'};
  @override
  String? get email => 'test@example.com';
}

class FakeNote extends Fake implements Note {}

class FakePerson extends Fake implements Person {}

void main() {
  late MockAppNotifier mockAppNotifier;
  late MockAppState mockAppState;
  late Person testPerson;
  late Note note1, note2, note3;

  setUpAll(() {
    registerFallbackValue(FakePerson());
    registerFallbackValue(FakeNote());
  });

  setUp(() {
    mockAppState = MockAppState();
    mockAppNotifier = MockAppNotifier(mockAppState);

    // Setup test data
    note1 = Note(
      path: 'people/person-1/info.md',
      title: 'Main Info',
      creationDate: DateTime(2023, 1, 1),
      lastModified: DateTime(2023, 1, 2),
      tags: ['bio'],
    );
    note2 = Note(
      path: 'people/person-1/notes/note-2.md',
      title: 'Meeting Notes',
      creationDate: DateTime(2023, 2, 1),
      lastModified: DateTime(2023, 2, 2),
      tags: ['meeting'],
    );
    note3 = Note(
      path: 'people/person-1/notes/note-3.md',
      title: 'Vacation Plan',
      creationDate: DateTime(2023, 3, 1),
      lastModified: DateTime(2023, 3, 2),
      tags: ['travel'],
    );

    testPerson = Person(
      path: 'people/person-1',
      info: note1,
      notes: [note2, note3],
    );

    // Complete stubs for AppState
    when(() => mockAppState.persons).thenReturn([testPerson]);
    when(() => mockAppState.currentUser).thenReturn(FakeUser());
    when(() => mockAppState.isSignedIn).thenReturn(true);
    when(() => mockAppState.storagePath).thenReturn('/fake/path');

    // Default stubs for AppNotifier methods
    when(
      () => mockAppNotifier.createNewNoteForPerson(any(), any()),
    ).thenAnswer((_) async => true);
    when(() => mockAppNotifier.deleteNote(any())).thenAnswer((_) async => true);
  });

  Future<void> pumpPersonDetailScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appProvider.overrideWith((ref) => mockAppNotifier),
          allCloudFilesProvider.overrideWith((ref) => Future.value([])),
          detailSearchProvider.overrideWith(
            (ref) => (text: '', tags: const []),
          ),
          rawNoteContentProvider.overrideWith(
            (ref, path) => Future.value('# Fake Markdown Content'),
          ),
        ],
        child: MaterialApp(home: PersonDetailScreen(person: testPerson)),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Helper to switch to the Notes tab
  Future<void> switchToNotesTab(WidgetTester tester) async {
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
  }

  group('PersonDetailScreen Note Management', () {
    testWidgets('TC1: View all notes of a contact in the Notes tab', (
      tester,
    ) async {
      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      final notesTabFinder = find.byType(NotesTab);
      expect(notesTabFinder, findsOneWidget);

      expect(
        find.descendant(of: notesTabFinder, matching: find.text('Main Info')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: notesTabFinder,
          matching: find.text('Meeting Notes'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: notesTabFinder,
          matching: find.text('Vacation Plan'),
        ),
        findsOneWidget,
      );

      // --- FIX: Settle any pending timers before the test ends ---
      await tester.pumpAndSettle();
    });

    testWidgets('TC2: Create note with a valid title', (tester) async {
      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'New Note Title');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      verify(
        () => mockAppNotifier.createNewNoteForPerson(
          testPerson,
          'New Note Title',
        ),
      ).called(1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('created'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('TC3: Create note with an existing title (should be allowed)', (
      tester,
    ) async {
      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Meeting Notes');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      verify(
        () =>
            mockAppNotifier.createNewNoteForPerson(testPerson, 'Meeting Notes'),
      ).called(1);
      expect(find.textContaining('created'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('TC4: Create note with empty title shows success snackbar', (
      tester,
    ) async {
      when(
        () => mockAppNotifier.createNewNoteForPerson(any(), ''),
      ).thenAnswer((_) async => true); // success

      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, ''); // Empty title
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Note "" created.'), findsOneWidget);
      verify(
        () => mockAppNotifier.createNewNoteForPerson(testPerson, ''),
      ).called(1);

      await tester.pumpAndSettle();
    });

    testWidgets(
      'TC5: Create note with space-only title shows success snackbar',
      (tester) async {
        when(
          () => mockAppNotifier.createNewNoteForPerson(any(), ''),
        ).thenAnswer((_) async => true); // success

        await pumpPersonDetailScreen(tester);
        await switchToNotesTab(tester);

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).last,
          '   ',
        ); // Space-only
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.textContaining('Note "" created.'), findsOneWidget);
        verify(
          () => mockAppNotifier.createNewNoteForPerson(testPerson, ''),
        ).called(1);

        await tester.pumpAndSettle();
      },
    );

    testWidgets('TC6: Cancel note creation', (tester) async {
      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Temporary Note');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockAppNotifier.createNewNoteForPerson(any(), any()));

      await tester.pumpAndSettle();
    });

    testWidgets('TC7: Delete an existing note', (tester) async {
      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      final noteToDeleteFinder = find.widgetWithText(
        Dismissible,
        'Vacation Plan',
      );
      expect(noteToDeleteFinder, findsOneWidget);

      await tester.drag(noteToDeleteFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Deletion'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockAppNotifier.deleteNote(note3)).called(1);

      await tester.pumpAndSettle();
    });

    testWidgets('TC8: Cancel deleting a note', (tester) async {
      await pumpPersonDetailScreen(tester);
      await switchToNotesTab(tester);

      final noteToKeepFinder = find.widgetWithText(
        Dismissible,
        'Meeting Notes',
      );
      expect(noteToKeepFinder, findsOneWidget);

      await tester.drag(noteToKeepFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Deletion'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockAppNotifier.deleteNote(any()));

      await tester.pumpAndSettle();
    });
  });
}
