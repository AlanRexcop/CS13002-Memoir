// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/account_screen.dart'; // Import the new screen
import 'package:memoir/screens/auth_screen.dart';
import 'package:memoir/screens/cloud_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: appState.isSignedIn 
        ? _buildSignedInView(context, ref, appState.currentUser!, appState.storagePath)
        : _buildSignedOutView(context, ref, appState.storagePath),
    );
  }

  Widget _buildSignedOutView(BuildContext context, WidgetRef ref, String? currentPath) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildStorageLocationTile(context, ref, currentPath),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud_queue_outlined),
          title: const Text('Sign In to Cloud Storage'),
          subtitle: const Text('Back up and sync your vault across devices.'),
          onTap: () {
             Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSignedInView(BuildContext context, WidgetRef ref, User user, String? currentPath) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Account'),
          subtitle: Text('Signed in as ${user.email}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
          },
        ),
        const Divider(),
        _buildStorageLocationTile(context, ref, currentPath),
        const Divider(),
         ListTile(
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Cloud Storage Management'),
          subtitle: const Text('Browse cloud files or upload local notes.'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CloudManagementScreen()),
            );
          },
        ),
        // Note: The Sign Out button is now on the AccountScreen for better UX.
        // We can remove the standalone sign out button from this list.
      ],
    );
  }

  Widget _buildStorageLocationTile(BuildContext context, WidgetRef ref, String? currentPath) {
    return ListTile(
      leading: const Icon(Icons.folder_open_outlined),
      title: const Text('Storage Location'),
      subtitle: Text(
        currentPath ?? "Not set",
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () async {
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

        if (shouldChange == true) {
          await ref.read(appProvider.notifier).changeStorageLocation();
          if(context.mounted) {
              Navigator.of(context).pop();
          }
        }
      },
    );
  }
}