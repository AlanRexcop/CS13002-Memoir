import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/screens/person_detail_screen.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';

class MockAppNotifier extends AppNotifier {
  MockAppNotifier(AppState state) : super.initial(state);
}

void main() {
  group('Note-related test cases', () {
    late Person person;
    late MockAppNotifier mockNotifier;

    setUp(() {
      final note1 = Note(
        path: 'info-note',
        title: 'Main Info',
        creationDate: DateTime(2023, 1, 1),
        lastModified: DateTime(2023, 1, 2),
        tags: ['bio'],
      );

      final note2 = Note(
        path: 'note-1',
        title: 'Meeting Notes',
        creationDate: DateTime(2023, 2, 1),
        lastModified: DateTime(2023, 2, 2),
        tags: ['meeting'],
      );

      final note3 = Note(
        path: 'note-2',
        title: 'Vacation Plan',
        creationDate: DateTime(2023, 3, 1),
        lastModified: DateTime(2023, 3, 2),
        tags: ['travel'],
      );

      person = Person(info: note1, notes: [note2, note3], path: 'person-1');
      final appState = AppState(persons: [person]);
      mockNotifier = MockAppNotifier(appState);
    });

    testWidgets('TC1: View all notes of a contact', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('info-note')), findsOneWidget);
      expect(find.text('Meeting Notes'), findsOneWidget);
      expect(find.text('Vacation Plan'), findsOneWidget);
    });

    //   testWidgets('TC2: Create note', (WidgetTester tester) async {
    //     await tester.pumpWidget(
    //       ProviderScope(
    //         overrides: [appProvider.overrideWith((ref) => mockNotifier)],
    //         child: MaterialApp(home: PersonDetailScreen(person: person)),
    //       ),
    //     );

    //     await tester.pumpAndSettle();

    //     // Nhấn nút Add note (giả sử dùng icon + hoặc 'Add')
    //     final addButton = find.byIcon(Icons.add);
    //     expect(addButton, findsOneWidget);
    //     await tester.tap(addButton);
    //     await tester.pumpAndSettle();

    //     // Nhập tiêu đề note mới
    //     await tester.enterText(find.byType(TextField).first, 'New Note');
    //     await tester.pump();

    //     // Nhấn nút Save (giả định là text 'Save')
    //     final saveButton = find.text('Save');
    //     expect(saveButton, findsOneWidget);
    //     await tester.tap(saveButton);
    //     await tester.pumpAndSettle();

    //     // Kiểm tra note mới xuất hiện
    //     expect(find.text('New Note'), findsOneWidget);
    //   });

    //   testWidgets('TC3: Cancel create note', (WidgetTester tester) async {
    //     await tester.pumpWidget(
    //       ProviderScope(
    //         overrides: [appProvider.overrideWith((ref) => mockNotifier)],
    //         child: MaterialApp(home: PersonDetailScreen(person: person)),
    //       ),
    //     );

    //     await tester.pumpAndSettle();

    //     // Nhấn nút Add
    //     final addButton = find.byIcon(Icons.add);
    //     expect(addButton, findsOneWidget);
    //     await tester.tap(addButton);
    //     await tester.pumpAndSettle();

    //     // Nhập text vào ô nhập liệu
    //     await tester.enterText(find.byType(TextField).first, 'Temporary Note');
    //     await tester.pump();

    //     // Nhấn Cancel
    //     final cancelButton = find.text('Cancel');
    //     expect(cancelButton, findsOneWidget);
    //     await tester.tap(cancelButton);
    //     await tester.pumpAndSettle();

    //     // Đảm bảo note chưa được thêm
    //     expect(find.text('Temporary Note'), findsNothing);
    //   });
  });
}
