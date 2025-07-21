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

Future<void> openCreateDialog(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  expect(find.text('Create New Person'), findsOneWidget);
}

void main() {
  testWidgets('Create and delete a contact', (WidgetTester tester) async {
    // Create fake test data with two Person instances.
    final testPersons = [
      Person(
        info: Note(
          path: 'path1',
          title: 'Alice',
          creationDate: DateTime.now(),
          lastModified: DateTime.now(),
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
          creationDate: DateTime.now(),
          lastModified: DateTime.now(),
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

    await tester.pumpAndSettle();

    // Verify the app bar title is displayed
    expect(find.text('Persons'), findsOneWidget);
    // Verify the person names are shown in the list (check TC: View contact list)
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    // Cancel Create
    await openCreateDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Create New Person'), findsNothing);
    expect(mockNotifier.wasCreatePersonCalled, isFalse);

    // Create a contact
    await openCreateDialog(tester);
    await tester.enterText(find.byType(TextField).last, 'Charlie');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Confirm that createNewPerson was called
    expect(mockNotifier.wasCreatePersonCalled, isTrue);
    expect(find.textContaining('created successfully'), findsOneWidget);

    // DELETE A CONTACT
    // Cancel deleting a contact
    final tile = find.byKey(ValueKey('path1'));
    expect(tile, findsOneWidget);
    await tester.drag(tile, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Deletion'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete Alice? This action cannot be undone.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Deletion'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
    expect(mockNotifier.wasDeletePersonCalled, isFalse);

    // delete a contact
    await tester.drag(tile, const Offset(-500.0, 0.0)); // Vuốt trái
    await tester.pumpAndSettle();

    //  Xác minh dialog xác nhận xóa
    expect(find.text('Confirm Deletion'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete Alice? This action cannot be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(mockNotifier.wasDeletePersonCalled, isTrue);
    expect(find.text('Alice'), findsNothing);
  });
}
