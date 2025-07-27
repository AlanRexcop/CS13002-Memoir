import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/recovery_password_screen.dart';
import 'package:memoir/screens/recycle_bin_screen.dart';

import '../widgets/setting_group.dart';
import '../widgets/setting_item.dart';
import 'account_screen.dart';
import 'backup_sync_screen.dart';
import 'feedback_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can watch the provider to display the current path.
    // final currentPath = ref.watch(appProvider).storagePath ?? "Not set";
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   onPressed: () {
        //     Navigator.of(context).pop();
        //   },
        //   icon: Icon(Icons.chevron_left_outlined, size: 30,),
        // ),
        // leadingWidth: 50,
        // backgroundColor: colorScheme.primaryContainer,
        // elevation: 0,
        title: Text('Setting'),
      ),
      body: ListView(
        children: [
          SizedBox(height: 20,),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 4,
                      color: Colors.white,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        spreadRadius: 2,
                        blurRadius: 10,
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                      )
                    ],
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: AssetImage("assets/avatar.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyen Gia Huy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'giahuyhcmus@gmail.com',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          SizedBox(height: 20,),
          SettingGroup(
            title: 'Account & Security',
            children: [
              SettingItem(
                  title: 'Account info',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    );
                  }
              ),
              SettingItem(
                  title: 'Change password',
                  icon: Icons.lock_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecoveryPasswordScreen(),
                      ),
                    );
                  }
              ),
            ],
          ),
          SettingGroup(
            title: 'Storage',
            children: [
              SettingItem(
                  title: 'Back up & Cloud sync',
                  icon: Icons.cloud_sync_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupSyncScreen(),
                      ),
                    );
                  }
              ),
              SettingItem(
                  title: 'Recycle bin',
                  icon: Icons.restore_from_trash_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecycleBinScreen(),
                      ),
                    );
                  }
              ),
              SettingItem(
                  title: 'Storage location',
                  icon: Icons.folder_open_outlined,
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
                  }
                },
              )
            ],
          ),
          SettingGroup(
            title: 'Improve the app',
            children: [
              SettingItem(
                  title: 'Feedback & bug report',
                  icon: Icons.feedback_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    );
                  }
              ),
            ],
          ),
          SizedBox(height: 30,),
          Center(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(
                  color: colorScheme.primary,
                  width: 1.75,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}