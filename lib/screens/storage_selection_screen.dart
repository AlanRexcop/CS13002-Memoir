import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';

class StorageSelectionScreen extends ConsumerWidget {
  const StorageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Select a directory to store your memoir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Select Directory'),
              onPressed: () => ref.read(appProvider.notifier).selectAndSetStorage(),
            ),
          ],
        ),
      ),
    );
  }
}