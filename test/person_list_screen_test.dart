import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';

// create mock notifier to control create, delete behavior
class MockAppNotifier extends AppNotifier {
  MockAppNotifier(AppState state) : super.initial(state);

  // check if the functions are called or not
  bool wasCreatePersonCalled = false;
  bool wasDeletePersonCalled = false;

  @override
  Future<bool> createNewPerson(String name) async {
    wasCreatePersonCalled = true;
    return true; // simulate success
  }

  @override
  Future<bool> deletePerson(Person person) async {
    wasDeletePersonCalled = true;
    return true; // simulate success
  }
}

void main() {
  testWidgets('Displays and interacts with PersonListScreen', (
    WidgetTester tester,
  ) async {
    // Create fake test data with two Person instances.
    final testPersons = [
      Person(
        info: Note(
          path: 'path1',
          title: 'Alice',
          creationDate: DateTime(2023, 1, 1),
          lastModified: DateTime(2023, 1, 2),
          tags: ['friend'],
          events: [],
          images: [],
          mentions: [],
          locations: [],
        ),
        notes: [],
        path: 'path1',
      ),
      Person(
        info: Note(
          path: 'path2',
          title: 'Bob',
          creationDate: DateTime(2023, 1, 3),
          lastModified: DateTime(2023, 1, 4),
          tags: ['colleague'],
          events: [],
          images: [],
          mentions: [],
          locations: [],
        ),
        notes: [],
        path: 'path2',
      ),
    ];

    // Set up the initial application state with predefined persons and empty search.
    final appState = AppState(
      persons: testPersons,
      searchQuery: (text: '', tags: []),
    );

    // Inject mock notifier with test state.
    final mockNotifier = MockAppNotifier(appState);

    // Render the widget with overridden provider using mockNotifier.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => mockNotifier)],
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );

    // Verify the app bar title is displayed
    expect(find.text('Persons'), findsOneWidget);

    // Verify the person names are shown in the list (check TC: View contact list)
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    // Tap the FAB to open the "Create Person" dialog (check TC: create contact)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    //  Verify the dialog title is shown
    expect(find.text('Create New Person'), findsOneWidget);

    // Enter a name and tap the "Create" button
    await tester.enterText(find.byType(TextField).last, 'Charlie');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Confirm that createNewPerson was called
    expect(mockNotifier.wasCreatePersonCalled, isTrue);
    // Check for success feedback after create new contact
    expect(find.textContaining('created successfully'), findsOneWidget);
  });
}
