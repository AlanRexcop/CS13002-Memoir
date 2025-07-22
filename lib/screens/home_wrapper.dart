import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/screens/storage_selection_screen.dart';

import 'main_app_shell.dart';

class HomeWrapper extends ConsumerWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);

    if (appState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (appState.isStorageSet) {
      return const MainAppShell();
    } else {
      return const StorageSelectionScreen();
    }
  }
}