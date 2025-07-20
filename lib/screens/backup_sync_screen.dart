import 'package:flutter/material.dart';

import '../widgets/info_item.dart';
import '../widgets/storage_info.dart';



class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.chevron_left_outlined, size: 30,),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            InfoItem(
                icon: Icons.key,
                label: 'Last sync',
                value: '28 Jun 2025, 22:11'
            ),
            InfoItem(
                icon: Icons.key,
                label: 'Sync status',
                value: 'Succes'
            ),
            StorageInfo(

            ),
            InfoItem(
                icon: Icons.access_time,
                label: 'File to back up',
                value: '28 files'
            ),

            const SizedBox(height: 32),
            const Divider(color: Colors.black26),
            const SizedBox(height: 32),

            _buildActionItem(
              icon: Icons.upload_outlined,
              label: 'Upload from Local to Cloud',
            ),
            const SizedBox(height: 24),
            _buildActionItem(
              icon: Icons.download_outlined,
              label: 'Download from Cloud to Local',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        
      },
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
          ],
        ),
      ),
    );
  }
}
