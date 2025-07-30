// C:\dev\memoir\lib\screens\recycle_bin_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:path/path.dart' as p;

// A model to represent a unified item in the recycle bin list.
class RecycleBinItem {
  final String personName;
  final String personPath;
  final bool isPersonDeleted;
  final Note? personInfoNote; // only for deleted persons
  final List<Note> deletedNotes; // only for active persons with deleted notes

  RecycleBinItem({
    required this.personName,
    required this.personPath,
    this.isPersonDeleted = false,
    this.personInfoNote,
    this.deletedNotes = const [],
  });
}

class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final allPersons = appState.persons;
    final deletedNotes = appState.deletedNotes;
    final deletedPersonsInfoNotes = appState.deletedPersonsInfoNotes;
    final colorScheme = Theme.of(context).colorScheme;

    // --- Logic to build the unified list ---

    final List<RecycleBinItem> items = [];

    // 1. Add fully deleted persons to the list
    for (final infoNote in deletedPersonsInfoNotes) {
      items.add(RecycleBinItem(
        personName: infoNote.title,
        personPath: p.dirname(infoNote.path),
        isPersonDeleted: true,
        personInfoNote: infoNote,
      ));
    }

    // 2. Group deleted notes by their parent person
    final notesByPersonPath = groupBy(deletedNotes, (note) => p.dirname(p.dirname(note.path)));

    // 3. Create items for active persons who have deleted notes
    notesByPersonPath.forEach((personPath, notes) {
      final person = allPersons.firstWhereOrNull((p) => p.path == personPath);
      if (person != null) { // Ensure the person is still active
        items.add(RecycleBinItem(
          personName: person.info.title,
          personPath: person.path,
          isPersonDeleted: false,
          deletedNotes: notes,
        ));
      }
    });

    // Sort the final list for consistency, maybe by name
    items.sort((a,b) => a.personName.compareTo(b.personName));


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
      body: items.isEmpty
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
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: item.isPersonDeleted
                      ? _buildDeletedPersonTile(context, ref, item)
                      : _buildActivePersonWithDeletedNotesTile(context, item),
                );
              },
            ),
    );
  }

  ListTile _buildDeletedPersonTile(BuildContext context, WidgetRef ref, RecycleBinItem item) {
    final note = item.personInfoNote!;
    return ListTile(
      leading: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 40),
      title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Person deleted on: ${DateFormat.yMd().add_jm().format(note.deletedDate!)}'),
      trailing: _buildActionButtons(
        context: context,
        ref: ref,
        onRestore: () => ref.read(appProvider.notifier).restorePerson(note),
        onDelete: () => ref.read(appProvider.notifier).deletePersonPermanently(note),
        restoreTooltip: 'Restore Person',
        deleteTooltip: 'Delete Person Permanently',
        // popOnRestoreSuccess is false by default, so we stay on this screen.
      ),
    );
  }
  
  ListTile _buildActivePersonWithDeletedNotesTile(BuildContext context, RecycleBinItem item) {
    return ListTile(
      leading: const Icon(Icons.folder_delete_outlined, size: 40),
      title: Text(item.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${item.deletedNotes.length} deleted note(s) inside'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DeletedNotesListScreen(
            personName: item.personName,
            deletedNotes: item.deletedNotes,
          ),
        ));
      },
    );
  }
}

// Helper widget for the list of deleted notes for a specific person
class DeletedNotesListScreen extends ConsumerWidget {
  final String personName;
  final List<Note> deletedNotes;

  const DeletedNotesListScreen({
    super.key,
    required this.personName,
    required this.deletedNotes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get the latest list of deleted notes for this person
    final currentDeletedNotes = ref.watch(appProvider.select(
      (s) => s.deletedNotes.where((n) => p.dirname(p.dirname(n.path)) == p.dirname(p.dirname(deletedNotes.first.path))).toList()
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('Deleted Notes for $personName'),
      ),
      body: currentDeletedNotes.isEmpty
      ? Center(
        child: Text('All notes for $personName have been restored.'),
      )
      : ListView.builder(
        itemCount: currentDeletedNotes.length,
        itemBuilder: (context, index) {
          final note = currentDeletedNotes[index];
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
              trailing: _buildActionButtons(
                context: context,
                ref: ref,
                onRestore: () => ref.read(appProvider.notifier).restoreNote(note),
                onDelete: () => ref.read(appProvider.notifier).deleteNotePermanently(note),
                restoreTooltip: 'Restore Note',
                deleteTooltip: 'Delete Note Permanently',
                popOnRestoreSuccess: true, // Pop this screen when a note is restored
              ),
            ),
          );
        },
      ),
    );
  }
}

// Reusable action buttons for restore/delete
Widget _buildActionButtons({
  required BuildContext context,
  required WidgetRef ref,
  required Future<bool> Function() onRestore,
  required Future<bool> Function() onDelete,
  required String restoreTooltip,
  required String deleteTooltip,
  bool popOnRestoreSuccess = false, // The new parameter
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.restore_from_trash, color: Colors.green),
        tooltip: restoreTooltip,
        onPressed: () async {
          final success = await onRestore();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Item restored.' : 'Failed to restore item.'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
            // MODIFIED: Only pop if the flag is true
            if (success && popOnRestoreSuccess && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
      IconButton(
        icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
        tooltip: deleteTooltip,
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
            final success = await onDelete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Item permanently deleted.' : 'Failed to delete item.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          }
        },
      ),
    ],
  );
}