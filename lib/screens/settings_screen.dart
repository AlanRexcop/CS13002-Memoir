import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can watch the provider to display the current path.
    final currentPath = ref.watch(appProvider).storagePath ?? "Not set";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Storage Location'),
            subtitle: Text(
              currentPath,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            onTap: () async {
              // Show a confirmation dialog before proceeding.
              final bool? shouldChange = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Change Storage Location?'),
                  content: const Text(
                    'This will close your current vault and ask you to select a new one. Are you sure you want to continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Continue', style: TextStyle(color: Colors.amber)),
                    ),
                  ],
                ),
              );

              // If the user confirmed, call the provider method.
              if (shouldChange == true) {
                await ref.read(appProvider.notifier).changeStorageLocation();
                // After the action, if the context is still valid, pop the settings screen.
                if(context.mounted) {
                   Navigator.of(context).pop();
                }
              }
            },
          ),
          const Divider(),
          // You can add more settings options here in the future
          // e.g., ListTile for Theme, About, etc.
        ],
      ),
    );
  }
}