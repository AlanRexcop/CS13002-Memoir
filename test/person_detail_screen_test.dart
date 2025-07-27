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

    testWidgets('TC2: Create note with valid title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );

      await tester.pumpAndSettle();

      // Nhấn nút Add note (icon là Icons.note_add)
      final addButton = find.byIcon(Icons.note_add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Nhập tiêu đề note mới
      await tester.enterText(find.byType(TextField).first, 'New Note');
      await tester.pump();

      // Nhấn nút Create (không phải Save)
      final createButton = find.text('Create');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Kiểm tra note mới xuất hiện
      expect(find.text('New Note'), findsOneWidget);
    });
    testWidgets('TC3: Create note with existing title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );

      await tester.pumpAndSettle();

      final addButton = find.byIcon(Icons.note_add);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Nhập tiêu đề trùng
      await tester.enterText(find.byType(TextField).first, 'Meeting Notes');
      await tester.pump();

      final createButton = find.text('Create');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Kiểm tra có 2 note cùng tên
      expect(find.text('Meeting Notes'), findsNWidgets(2));
    });

    testWidgets('TC4: Invalid note creation with empty or whitespace title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );
      await tester.pumpAndSettle();

      final addButton = find.byIcon(Icons.note_add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      expect(textField, findsOneWidget);

      // Test nhập tiêu đề chỉ chứa khoảng trắng
      await tester.enterText(textField, '   ');
      await tester.pump();

      final createButton = find.text('Create');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Dialog vẫn còn, không bị pop
      expect(find.byType(AlertDialog), findsOneWidget);

      // Sau đó test tiêu đề rỗng
      await tester.enterText(textField, '');
      await tester.pump();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Vẫn không được tạo, dialog vẫn hiển thị
      expect(find.byType(AlertDialog), findsOneWidget);

      expect(find.text('   '), findsNothing);
      expect(find.text(''), findsNothing);
    });
    testWidgets('TC5: Cancel create note', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );

      await tester.pumpAndSettle();

      // Nhấn nút Add note (icon là Icons.note_add)
      final addButton = find.byIcon(Icons.note_add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Nhập tiêu đề note tạm
      await tester.enterText(find.byType(TextField).first, 'Temporary Note');
      await tester.pump();

      // Nhấn Cancel
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Đợi thêm một frame để đảm bảo UI được cập nhật
      await tester.pump();

      // Kiểm tra dialog đã đóng
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('TC6: Delete note which exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );
      await tester.pumpAndSettle();

      // Kéo ghi chú "Vacation Plan" để hiện nút xoá
      final noteTile = find.byKey(ValueKey('note-2'));
      expect(noteTile, findsOneWidget);

      await tester.drag(noteTile, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Chọn Delete trong dialog xác nhận
      final deleteButton = find.text('Delete');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Kiểm tra ghi chú đã biến mất
      expect(find.text('Vacation Plan'), findsNothing);
    });

    testWidgets('TC7: Cancel delete note', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );
      await tester.pumpAndSettle();

      // Kéo ghi chú "Meeting Notes" sang trái để hiển thị xác nhận xoá
      final noteTile = find.byKey(ValueKey('note-1'));
      expect(noteTile, findsOneWidget);

      await tester.drag(noteTile, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Khi dialog xác nhận hiện ra → chọn Cancel
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Ghi chú vẫn tồn tại
      expect(find.text('Meeting Notes'), findsOneWidget);
    });
    testWidgets('TC8: Attempt to delete note which does not exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => mockNotifier)],
          child: MaterialApp(home: PersonDetailScreen(person: person)),
        ),
      );
      await tester.pumpAndSettle();

      // Tạo ghi chú giả không có thật
      final fakeNote = Note(
        path: 'ghost-note',
        title: 'Ghost Note',
        creationDate: DateTime(2024, 4, 1),
        lastModified: DateTime(2024, 4, 2),
        tags: ['ghost'],
      );

      // Gọi hàm xoá trực tiếp từ mockNotifier
      final result = await mockNotifier.deleteNote(fakeNote);

      // Kỳ vọng xoá thất bại → trả về false
      expect(result, false);

      // Kiểm tra danh sách ghi chú vẫn còn nguyên
      expect(find.text('Meeting Notes'), findsOneWidget);
      expect(find.text('Vacation Plan'), findsOneWidget);
    });
  });
}
