import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/screens/account_screen.dart';
import 'package:memoir/screens/cloud_management_screen.dart';

import '../widgets/info_item.dart';
import '../widgets/storage_info.dart';

// Changed to a ConsumerWidget to access Riverpod state
class BackupSyncScreen extends ConsumerWidget {
  const BackupSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // Watch the same provider used by the account screen to get profile data
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_outlined, size: 30,),
        ),
        leadingWidth: 50,
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        title: Text(
          'Back up & Cloud sync',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userProfileProvider),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // These items are placeholders for now, can be made dynamic later
            const InfoItem(
                icon: Icons.update,
                label: 'Last sync',
                value: 'N/A'
            ),
            const InfoItem(
                icon: Icons.sync,
                label: 'Sync status',
                value: 'Idle'
            ),
            
            // This now dynamically builds based on the provider's state
            profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
              data: (profileData) {
                final storageUsed = profileData['storage_used'] as int? ?? 0;
                final storageLimit = profileData['storage_limit'] as int? ?? 1;
                // Pass the real data to the StorageInfo widget
                return StorageInfo(
                  usedStorage: storageUsed,
                  storageLimit: storageLimit,
                );
              },
            ),

            const InfoItem(
                icon: Icons.description_outlined,
                label: 'File count',
                value: 'N/A' // Placeholder
            ),

            const SizedBox(height: 32),
            const Divider(color: Colors.black26),
            const SizedBox(height: 32),

            // This action now navigates to the functional Cloud Management screen
            _buildActionItem(
              context: context,
              icon: Icons.cloud_sync_outlined, // <-- CORRECTED ICON
              label: 'Manage Cloud Storage',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CloudManagementScreen(),
                ));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(
                label,
                style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500
                )
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}