import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';

class MockAppNotifier extends AppNotifier {
  MockAppNotifier(AppState state) : super.initial(state);

  bool wasCreatePersonCalled = false;
  bool wasDeletePersonCalled = false;

  @override
  Future<bool> createNewPerson(String name) async {
    wasCreatePersonCalled = true;
    return true; // giả lập thành công
  }

  @override
  Future<bool> deletePerson(Person person) async {
    wasDeletePersonCalled = true;
    return true;
  }
}

void main() {
  testWidgets('Displays and interacts with PersonListScreen', (
    WidgetTester tester,
  ) async {
    // Khởi tạo AppState giả
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

    final appState = AppState(
      persons: testPersons,
      searchQuery: (text: '', tags: []),
    );

    final mockNotifier = MockAppNotifier(appState);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => mockNotifier)],
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );

    // ✅ Kiểm tra tiêu đề
    expect(find.text('Persons'), findsOneWidget);

    // ✅ Hiển thị danh sách
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    // ✅ Mở dialog tạo mới
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create New Person'), findsOneWidget);

    // ✅ Nhập tên và nhấn "Create"
    await tester.enterText(find.byType(TextField).last, 'Charlie');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // ✅ Kiểm tra gọi hàm tạo mới
    expect(mockNotifier.wasCreatePersonCalled, isTrue);
    expect(find.textContaining('created successfully'), findsOneWidget);
  });
}
