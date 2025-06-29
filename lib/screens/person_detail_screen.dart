import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

class PersonDetailScreen extends ConsumerWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // To see updates immediately, we watch the provider to get the latest
    // version of our person after an action (like delete or create).
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == person.path,
          orElse: () => person, // Fallback to the initial person object
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
            direction: isInfoNote ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              color: Colors.red[800],
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: Text("Are you sure you want to delete ${note.title}?"),
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
              );
            },
            onDismissed: (direction) async {
              await ref.read(appProvider.notifier).deleteNote(note);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(isInfoNote ? Icons.info_outline : Icons.description_outlined, size: 40),
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modified: ${DateFormat('yyyy-MM-dd HH:mm').format(note.lastModified.toLocal())}',
                    ),
                    const SizedBox(height: 4),
                    // Only show the Wrap widget if there are tags.
                    if (note.tags.isNotEmpty)
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: note.tags.map((tag) => Chip(
                          label: Text(tag),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 10),
                        )).toList(),
                      ),
                  ],
                ),
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
            decoration: const InputDecoration(hintText: "Note Title"),
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