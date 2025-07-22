import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';

// Mock notifier
class MockAppNotifier extends AppNotifier {
  MockAppNotifier(AppState state) : super.initial(state);

  bool wasCreatePersonCalled = false;
  bool wasDeletePersonCalled = false;

  @override
  Future<bool> createNewPerson(String name) async {
    wasCreatePersonCalled = true;
    return true;
  }

  @override
  Future<bool> deletePerson(Person person) async {
    wasDeletePersonCalled = true;
    return true;
  }
}

Future<void> launchApp(
  WidgetTester tester,
  MockAppNotifier mockNotifier,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appProvider.overrideWith((ref) => mockNotifier)],
      child: const MaterialApp(home: PersonListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openCreateDialog(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

MockAppNotifier buildMockNotifier() {
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

  return MockAppNotifier(
    AppState(persons: testPersons, searchQuery: (text: '', tags: [])),
  );
}

void main() {
  testWidgets('TC1: View contact list', (WidgetTester tester) async {
    final mockNotifier = buildMockNotifier();
    await launchApp(tester, mockNotifier);

    expect(find.text('Persons'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('TC2: Cancel creating a contact', (WidgetTester tester) async {
    final mockNotifier = buildMockNotifier();
    await launchApp(tester, mockNotifier);

    await openCreateDialog(tester);
    expect(find.text('Create New Person'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Person'), findsNothing);
    expect(mockNotifier.wasCreatePersonCalled, isFalse);
  });

  testWidgets('TC3: Create a new contact', (WidgetTester tester) async {
    final mockNotifier = buildMockNotifier();
    await launchApp(tester, mockNotifier);

    await openCreateDialog(tester);
    await tester.enterText(find.byType(TextField).last, 'Charlie');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(mockNotifier.wasCreatePersonCalled, isTrue);
    expect(find.textContaining('created successfully'), findsOneWidget);
  });

  testWidgets('TC4: Cancel deleting a contact', (WidgetTester tester) async {
    final mockNotifier = buildMockNotifier();
    await launchApp(tester, mockNotifier);

    final tile = find.byKey(ValueKey('path1'));
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
    expect(mockNotifier.wasDeletePersonCalled, isFalse);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('TC5: Delete a contact', (WidgetTester tester) async {
    final mockNotifier = buildMockNotifier();
    await launchApp(tester, mockNotifier);

    final tile = find.byKey(ValueKey('path1'));
    await tester.drag(tile, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Deletion'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(mockNotifier.wasDeletePersonCalled, isTrue);
    expect(find.text('Alice'), findsNothing);
  });
}
