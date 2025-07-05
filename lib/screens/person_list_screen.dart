// C:\dev\memoir\lib\screens\person_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/calendar_screen.dart';
import 'package:memoir/screens/map_screen.dart';
import 'package:memoir/screens/person_detail_screen.dart';
import 'package:memoir/screens/graph_view_screen.dart';
import 'package:memoir/screens/settings_screen.dart';

class PersonListScreen extends ConsumerStatefulWidget {
  const PersonListScreen({super.key});

  @override
  ConsumerState<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends ConsumerState<PersonListScreen> {
  final _tagController = TextEditingController();
  final List<String> _searchTags = [];

  void _updateSearch({String? text, List<String>? tags}) {
    final currentQuery = ref.read(appProvider).searchQuery;
    ref.read(appProvider.notifier).setSearchQuery(
      (
        text: text ?? currentQuery.text,
        tags: tags ?? currentQuery.tags,
      )
    );
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final filteredPersons = appState.filteredPersons;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persons'),
        actions: [
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GraphViewScreen())), icon: const Icon(Icons.hub_outlined), tooltip: 'View Graph'),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MapScreen())), icon: const Icon(Icons.map_outlined), tooltip: 'View Map'),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CalendarScreen())), icon: const Icon(Icons.calendar_month), tooltip: 'View Calendar'),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())), icon: const Icon(Icons.settings_outlined), tooltip: 'Settings'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(appProvider.notifier).refreshVault(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                ),
                onChanged: (value) => _updateSearch(text: value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.label_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          ..._searchTags.map((tag) => Chip(
                                label: Text(tag),
                                onDeleted: () {
                                  setState(() => _searchTags.remove(tag));
                                  _updateSearch(tags: _searchTags);
                                },
                                visualDensity: VisualDensity.compact,
                              )),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                                border: InputBorder.none,
                                hintText: 'Filter by tag...',
                              ),
                              onSubmitted: (tag) {
                                tag = tag.trim();
                                if (tag.isNotEmpty && !_searchTags.contains(tag)) {
                                  setState(() => _searchTags.add(tag));
                                  _tagController.clear();
                                  _updateSearch(tags: _searchTags);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  return Dismissible(
                    key: ValueKey(person.path),
                    direction: DismissDirection.endToStart,
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
                            content: Text("Are you sure you want to delete ${person.info.title}? This action cannot be undone."),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          );
                        },
                      );
                    },
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
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, size: 40),
                        title: Text(person.info.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${person.notes.length} associated notes'),
                            const SizedBox(height: 4),
                            if (person.info.tags.isNotEmpty)
                              Wrap(
                                spacing: 4.0,
                                runSpacing: 4.0,
                                children: person.info.tags.map((tag) => Chip(
                                  label: Text(tag),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  labelStyle: const TextStyle(fontSize: 10),
                                )).toList(),
                              ),
                          ],
                        ),
                        // --- FIX: Reset the provider state before navigating ---
                        onTap: () {
                          ref.read(detailSearchProvider.notifier).state = (text: '', tags: const []);
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
                      content: Text(success ? 'Person "$name" created successfully.' : 'Failed to create person. Name might already exist.'),
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