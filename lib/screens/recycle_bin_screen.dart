// C:\dev\memoir\lib\screens\recycle_bin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedNotes = ref.watch(appProvider).deletedNotes;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_outlined, size: 30),
        ),
        leadingWidth: 50,
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        title: Text(
          'Recycle bin',
          style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: deletedNotes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Recycle bin is empty.'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: deletedNotes.length,
              itemBuilder: (context, index) {
                final note = deletedNotes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(note.title),
                    subtitle: Text('Deleted on: ${DateFormat.yMd().add_jm().format(note.deletedDate!)}'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NoteViewScreen(note: note),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore_from_trash, color: Colors.green),
                          tooltip: 'Restore',
                          onPressed: () async {
                             final success = await ref.read(appProvider.notifier).restoreNote(note);
                             if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                      content: Text(success ? 'Note restored.' : 'Failed to restore note.'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                             }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: colorScheme.error),
                          tooltip: 'Delete Permanently',
                          onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Permanently?'),
                                  content: const Text('This action cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                final success = await ref.read(appProvider.notifier).deleteNotePermanently(note);
                                if (context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                        content: Text(success ? 'Note permanently deleted.' : 'Failed to delete note.'),
                                        backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}