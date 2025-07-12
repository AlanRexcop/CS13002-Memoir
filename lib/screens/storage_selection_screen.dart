// C:\dev\memoir\lib\screens\storage_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- Import the package

class StorageSelectionScreen extends ConsumerWidget {
  const StorageSelectionScreen({super.key});

  // New method to handle permission request
  Future<void> _requestStoragePermission(WidgetRef ref) async {
    // This permission is only available on Android.
    if (Theme.of(ref.context).platform == TargetPlatform.android) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        // This will open a new screen where the user can grant the permission.
        await Permission.manageExternalStorage.request();
      }
    }
  }

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
              onPressed: () async {
                await _requestStoragePermission(ref);
                var isGranted = await Permission.manageExternalStorage.isGranted;
                if (isGranted) {
                  ref.read(appProvider.notifier).selectAndSetStorage();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage permission is required.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}