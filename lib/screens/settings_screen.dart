import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/account_screen.dart';
import 'package:memoir/screens/auth_screen.dart';
import 'package:memoir/screens/change_password_screen.dart';
import 'package:memoir/screens/cloud_file_browser_screen.dart';
import 'package:memoir/screens/feedback_screen.dart';
import 'package:memoir/screens/local_vault_browser_screen.dart';
import 'package:memoir/screens/recycle_bin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Widgets from HEAD branch's UI style
import '../widgets/setting_group.dart';
import '../widgets/setting_item.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(appProvider.notifier).signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign Out Error: ${e.toString()}')),
          );
        }
      }
    }
  }

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
      children: [
        const SizedBox(height: 20),
        SettingGroup(
          title: 'Account',
          children: [
            SettingItem(
              title: 'Sign In to Cloud',
              icon: Icons.cloud_queue_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
        SettingGroup(
          title: 'Storage',
          children: [
            // MODIFIED: Added Recycle Bin to the signed-out view
            SettingItem(
              title: 'Recycle bin',
              icon: Icons.restore_from_trash_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecycleBinScreen())),
            ),
            _buildStorageLocationItem(context, ref),
          ],
        ),
      ],
    );
  }

  Widget _buildSignedInView(BuildContext context, WidgetRef ref, User user, String? currentPath) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 20),
        // Profile Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  border: Border.all(width: 4, color: Colors.white),
                  boxShadow: const [BoxShadow(spreadRadius: 2, blurRadius: 10, color: Color.fromRGBO(0, 0, 0, 0.1))],
                  shape: BoxShape.circle,
                  image: const DecorationImage(image: AssetImage("assets/avatar.png"), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.userMetadata?['username'] ?? 'User',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 20),
                    ),
                    Text(
                      user.email ?? 'No email',
                      style: TextStyle(fontWeight: FontWeight.normal, color: colorScheme.onSurfaceVariant, fontSize: 16),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingGroup(
          title: 'Account & Security',
          children: [
            SettingItem(
              title: 'Account info',
              icon: Icons.person_outline,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen())),
            ),
            SettingItem(
              title: 'Change password',
              icon: Icons.lock_outline,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen())),
            ),
          ],
        ),
        SettingGroup(
          title: 'Storage',
          children: [
            // MODIFICATION: Replaced 'Cloud Management' with two direct buttons.
            SettingItem(
              title: 'Browse Cloud Files',
              icon: Icons.cloud_download_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CloudFileBrowserScreen())),
            ),
            SettingItem(
              title: 'Upload Local Notes',
              icon: Icons.cloud_upload_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalVaultBrowserScreen())),
            ),
            SettingItem(
              title: 'Recycle bin',
              icon: Icons.restore_from_trash_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecycleBinScreen())),
            ),
            _buildStorageLocationItem(context, ref),
          ],
        ),
        SettingGroup(
          title: 'Improve the app',
          children: [
            SettingItem(
              title: 'Feedback & bug report',
              icon: Icons.feedback_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen())),
            ),
          ],
        ),
        const SizedBox(height: 30),
        // Sign out button
        Center(
          child: OutlinedButton(
            onPressed: () => _signOut(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.75),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Sign Out'),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStorageLocationItem(BuildContext context, WidgetRef ref) {
    return SettingItem(
      title: 'Storage location',
      icon: Icons.folder_open_outlined,
      onTap: () async {
        final bool? shouldChange = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Change Storage Location?'),
            content: const Text('This will close your current vault and ask you to select a new one. Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue', style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        );
        if (shouldChange == true) {
          await ref.read(appProvider.notifier).changeStorageLocation();
        }
      },
    );
  }
}