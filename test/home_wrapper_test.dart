// C:\dev\memoir\test\home_wrapper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/home_wrapper.dart';
import 'package:memoir/screens/main_app_shell.dart';
import 'package:memoir/screens/storage_selection_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockAppNotifier extends StateNotifier<AppState> with Mock implements AppNotifier {
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

void main() {
  late MockAppNotifier mockAppNotifier;
  late MockAppState mockAppState;

  setUp(() {
    mockAppState = MockAppState();
    mockAppNotifier = MockAppNotifier(mockAppState);

    // Complete default stubbing
    when(() => mockAppState.persons).thenReturn([]);
    when(() => mockAppState.filteredPersons).thenReturn([]);
    when(() => mockAppState.currentUser).thenReturn(FakeUser());
    when(() => mockAppState.isSignedIn).thenReturn(true);
  });

  Future<void> pumpHomeWrapper(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appProvider.overrideWith((ref) => mockAppNotifier),
          localAvatarProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const MaterialApp(home: HomeWrapper()),
      ),
    );
  }

  testWidgets('Displays CircularProgressIndicator when loading', (tester) async {
    when(() => mockAppState.isLoading).thenReturn(true);
    when(() => mockAppState.isStorageSet).thenReturn(false);

    await pumpHomeWrapper(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Displays MainAppShell when storage is set and not loading', (tester) async {
    when(() => mockAppState.isLoading).thenReturn(false);
    when(() => mockAppState.isStorageSet).thenReturn(true);

    await pumpHomeWrapper(tester);
    await tester.pumpAndSettle();

    expect(find.byType(MainAppShell), findsOneWidget);
    expect(find.byType(StorageSelectionScreen), findsNothing);
  });

  testWidgets('Displays StorageSelectionScreen when storage is not set and not loading', (tester) async {
    when(() => mockAppState.isLoading).thenReturn(false);
    when(() => mockAppState.isStorageSet).thenReturn(false);

    await pumpHomeWrapper(tester);
    await tester.pumpAndSettle();

    expect(find.byType(StorageSelectionScreen), findsOneWidget);
    expect(find.byType(MainAppShell), findsNothing);
  });
}