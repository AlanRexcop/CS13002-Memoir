import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/calendar_screen.dart';
import 'package:memoir/screens/person_detail_screen.dart';

class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final filteredPersons = appState.filteredPersons;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'View Calendar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or tag...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => ref.read(appProvider.notifier).setSearchTerm(value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPersons.length,
              itemBuilder: (context, index) {
                final person = filteredPersons[index];
                return Dismissible(
                  // A unique key is required for Dismissible to work correctly in a list.
                  key: ValueKey(person.path),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red[800],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  // This callback shows a confirmation dialog before deleting.
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm Deletion"),
                          content: Text("Are you sure you want to delete ${person.info.title}? This will delete all associated notes and cannot be undone."),
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
                    ) ?? false; // Return false if the dialog is dismissed.
                  },
                  // This is called after the user confirms and the item is swiped away.
                  onDismissed: (direction) async {
                    final success = await ref.read(appProvider.notifier).deletePerson(person);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? "Deleted ${person.info.title}" : "Failed to delete person."),
                          backgroundColor: success ? Colors.green[700] : Colors.red[700],
                        ),
                      );
                    }
                  },
                  // The actual UI for the list item.
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(person.info.title),
                      subtitle: Text('${person.notes.length} notes'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PersonDetailScreen(person: person),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePersonDialog(context, ref),
        tooltip: 'Add Person',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePersonDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Person'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Person's Name"),
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

                final success = await ref.read(appProvider.notifier).createNewPerson(name);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Person "$name" created.' : 'Failed to create person. Name might already exist.'),
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