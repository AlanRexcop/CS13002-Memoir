// lib/screens/local_vault_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/providers/local_vault_provider.dart';

class LocalVaultBrowserScreen extends ConsumerWidget {
  const LocalVaultBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localNotesAsync = ref.watch(localVaultNotifierProvider);
    final allCloudFilesAsync = ref.watch(allCloudFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Vault Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Sync Status',
            onPressed: () {
              ref.invalidate(localVaultNotifierProvider);
              ref.invalidate(allCloudFilesProvider);
            },
          )
        ],
      ),
      body: localNotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading local notes:\n$err', textAlign: TextAlign.center),
          ),
        ),
        data: (localNotes) {
          return allCloudFilesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading cloud files sync status:\n$err')),
            data: (cloudFiles) {
              final cloudPaths = cloudFiles.map((cf) => cf.cloudPath).toSet();
              
              if (localNotes.isEmpty) {
                return const Center(child: Text('No local notes found.'));
              }

              return ListView.builder(
                itemCount: localNotes.length,
                itemBuilder: (context, index) {
                  final note = localNotes[index];
                  final normalizedLocalPath = note.path.replaceAll(r'\', '/');
                  final isSynced = cloudPaths.any((cp) => cp?.endsWith(normalizedLocalPath) ?? false);
                  
                  return NoteSyncTile(
                    note: note,
                    isSynced: isSynced,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NoteSyncTile extends ConsumerStatefulWidget {
  final Note note;
  final bool isSynced;

  const NoteSyncTile({
    super.key,
    required this.note,
    required this.isSynced,
  });

  @override
  ConsumerState<NoteSyncTile> createState() => _NoteSyncTileState();
}

class _NoteSyncTileState extends ConsumerState<NoteSyncTile> {
  bool _isUploading = false;
  bool _isDeleting = false;

  Future<void> _upload() async {
    setState(() => _isUploading = true);
    final success = await ref.read(localVaultNotifierProvider.notifier).uploadNote(widget.note);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Upload successful for ${widget.note.title}' : 'Upload failed for ${widget.note.title}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() => _isUploading = false);
    }
  }

  Future<void> _unsync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unsync'),
        content: Text('Are you sure you want to remove "${widget.note.title}" from the cloud? The local file will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unsync', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    final success = await ref.read(cloudNotifierProvider.notifier).deleteFileByRelativePath(widget.note.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Successfully unsynced ${widget.note.title}' : 'Failed to unsync ${widget.note.title}'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
      // Invalidate the providers to force a UI refresh with the new sync status
      ref.invalidate(localVaultNotifierProvider);
      ref.invalidate(allCloudFilesProvider);
    }

    if(mounted) {
       setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget trailingWidget;

    if (_isUploading || _isDeleting) {
      trailingWidget = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (widget.isSynced) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Tooltip(message: 'Synced', child: Icon(Icons.check_circle, color: Colors.green)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.cloud_off_outlined),
            color: Colors.red.shade600,
            tooltip: 'Unsync from Cloud',
            onPressed: _unsync,
          ),
        ],
      );
    } else {
      trailingWidget = IconButton(
        icon: const Icon(Icons.cloud_upload_outlined),
        tooltip: 'Upload to Cloud',
        onPressed: _upload,
      );
    }
    
    return ListTile(
      title: Text(widget.note.title),
      subtitle: Text(widget.note.path, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: trailingWidget,
    );
  }
}