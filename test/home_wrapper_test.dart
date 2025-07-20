import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoir/screens/home_wrapper.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/screens/storage_selection_screen.dart';

// Mock AppNotifier to use in test
class MockAppNotifier extends AppNotifier {
  MockAppNotifier(AppState state) : super.initial(state);
}

void main() {
  testWidgets('Display CircularProgressIndicator when loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appProvider.overrideWith(
            (ref) =>
                MockAppNotifier(AppState(isLoading: true, storagePath: null)),
          ),
        ],
        child: const MaterialApp(home: HomeWrapper()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Display PersonListScreen when isStorageSet = true', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appProvider.overrideWith(
            (ref) => MockAppNotifier(
              AppState(isLoading: false, storagePath: '/fake/path'),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeWrapper()),
      ),
    );

    expect(find.byType(PersonListScreen), findsOneWidget);
  });

  testWidgets('Display StorageSelectionScreen when isStorageSet = false', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appProvider.overrideWith(
            (ref) =>
                MockAppNotifier(AppState(isLoading: false, storagePath: null)),
          ),
        ],
        child: const MaterialApp(home: HomeWrapper()),
      ),
    );

    expect(find.byType(StorageSelectionScreen), findsOneWidget);
  });
}
