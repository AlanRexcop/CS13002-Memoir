// lib/screens/local_vault_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/viewmodels/cloud_viewmodel.dart';
import 'package:memoir/viewmodels/local_vault_viewmodel.dart';

enum SyncStatus { local, synced, unknown }

class LocalVaultBrowserScreen extends ConsumerWidget {
  const LocalVaultBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localNotesAsync = ref.watch(localVaultViewModelProvider);
    final allCloudFilesAsync = ref.watch(allCloudFilesProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Local Vault Sync Status'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(localVaultViewModelProvider);
                ref.invalidate(allCloudFilesProvider);
              },
            )
          ],
        ),
        body: localNotesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading local notes: $err')),
          data: (localNotes) {
            return allCloudFilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading cloud files: $err')),
              data: (cloudFiles) {
                if (localNotes.isEmpty) {
                  return const Center(child: Text("No local notes found in the vault."));
                }
                
                return ListView.builder(
                  itemCount: localNotes.length,
                  itemBuilder: (context, index) {
                    final note = localNotes[index];
                    
                    final normalizedLocalPath = note.path.replaceAll(r'\', '/');

                    // 2. Check if ANY cloud file's path ends with the normalized local path.
                    // This correctly matches 'user-id/people/info.md' with 'people/info.md'.
                    final isSynced = cloudFiles.any(
                        (cf) => cf.cloudPath?.endsWith(normalizedLocalPath) ?? false);
                    
                    final status = isSynced ? SyncStatus.synced : SyncStatus.local;

                    return ListTile(
                      leading: Icon(
                        status == SyncStatus.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                        color: status == SyncStatus.synced ? Colors.green : Colors.orange,
                      ),
                      title: Text(note.title),
                      subtitle: Text(note.path, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: status == SyncStatus.local
                          ? ElevatedButton(
                              child: const Text('Upload'),
                              onPressed: () async {
                                final success = await ref.read(localVaultViewModelProvider.notifier).uploadNote(note);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Upload successful!' : 'Upload failed.'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                  // Refresh cloud file list after successful upload
                                  if (success) {
                                    ref.invalidate(allCloudFilesProvider);
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                );
              },
            );
          },
        ));
  }
}