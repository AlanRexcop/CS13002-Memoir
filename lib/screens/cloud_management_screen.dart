// lib/screens/cloud_management_screen.dart
import 'package:flutter/material.dart';
import 'package:memoir/screens/cloud_file_browser_screen.dart';
import 'package:memoir/screens/local_vault_browser_screen.dart';

class CloudManagementScreen extends StatelessWidget {
  const CloudManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Browse Cloud Files'),
            subtitle: const Text('View and download files from the cloud.'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CloudFileBrowserScreen(),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Upload Local Notes'),
            subtitle: const Text('Check sync status and upload local-only notes.'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LocalVaultBrowserScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}