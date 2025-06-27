import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

class PersonDetailScreen extends ConsumerWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get the most up-to-date version of the person,
    // which is important after a note is deleted.
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == person.path,
          orElse: () => person, // Fallback if the person was just deleted
        );
    final allNotes = [updatedPerson.info, ...updatedPerson.notes];

    return Scaffold(
      appBar: AppBar(
        title: Text(updatedPerson.info.title),
      ),
      body: ListView.builder(
        itemCount: allNotes.length,
        itemBuilder: (context, index) {
          final note = allNotes[index];
          final isInfoNote = note.path == updatedPerson.info.path;

          return Dismissible(
            key: ValueKey(note.path),
            // IMPORTANT: Prevent the main info.md note from being deleted.
            direction: isInfoNote ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              color: Colors.red[800],
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: Text("Are you sure you want to delete the note '${note.title}'?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              ) ?? false;
            },
            onDismissed: (direction) async {
              final success = await ref.read(appProvider.notifier).deleteNote(note);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Deleted ${note.title}" : "Failed to delete note."),
                    backgroundColor: success ? Colors.green[700] : Colors.red[700],
                  ),
                );
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(isInfoNote ? Icons.info_outline : Icons.description_outlined),
                title: Text(note.title),
                subtitle: Text('Last modified: ${note.lastModified.toLocal()}'),
                trailing: isInfoNote ? const Chip(label: Text('Info'), visualDensity: VisualDensity.compact) : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => NoteViewScreen(note: note)),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateNoteDialog(context, ref, updatedPerson),
        tooltip: 'Add Note',
        child: const Icon(Icons.note_add),
      ),
    );
  }

  void _showCreateNoteDialog(BuildContext context, WidgetRef ref, Person currentPerson) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Note'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Note Title (e.g., 'Meeting Notes')"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.of(context).pop();

                final success = await ref.read(appProvider.notifier).createNewNoteForPerson(currentPerson, name);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Note "$name" created.' : 'Failed to create note. Name might already exist.'),
                      backgroundColor: success ? Colors.green[700] : Colors.red[700],
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}