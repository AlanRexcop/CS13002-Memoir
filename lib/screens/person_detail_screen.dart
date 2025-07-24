// C:\dev\memoir\lib\screens\person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';

import '../widgets/custom_float_button.dart';
import '../widgets/tag.dart'; // Import for the enum

class PersonDetailScreen extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const PersonDetailScreen({super.key, required this.person, this.purpose = ScreenPurpose.view});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  final _tagController = TextEditingController();
  final List<String> _searchTags = [];

  void _updateSearch({String? text, List<String>? tags}) {
    final currentQuery = ref.read(detailSearchProvider);
    ref.read(detailSearchProvider.notifier).state = (
      text: text ?? currentQuery.text,
      tags: tags ?? currentQuery.tags
    );
  }

  Future<void> _showMentionInfoDialog(BuildContext context, Note selectedNote) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mention Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are mentioning:\n"${selectedNote.title}"', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Display Text',
                hintText: 'e.g., "this related document"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text.trim()),
            child: const Text('Insert Mention'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final displayText = result.isEmpty ? selectedNote.title : result;
      Navigator.of(context).pop({
        'text': displayText,
        'path': selectedNote.path,
      });
    }
  }

  String _formatTagName(String tag) {
    const int maxLength = 10;
    const int charsToKeep = 5;

    if (tag.length > maxLength) {
      return '${tag.substring(0, charsToKeep)}...';
    }
    return tag;
  }


  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == widget.person.path,
          orElse: () => widget.person,
        );
    
    final searchQuery = ref.watch(detailSearchProvider);
    final allNotes = [updatedPerson.info, ...updatedPerson.notes];

    final filteredNotes = allNotes.where((note) {
      if (searchQuery.text.isEmpty && searchQuery.tags.isEmpty) return true;
      final lowerCaseTitle = note.title.toLowerCase();
      final lowerCaseTags = note.tags.map((t) => t.toLowerCase()).toList();

      final textMatch = searchQuery.text.isEmpty || lowerCaseTitle.contains(searchQuery.text.toLowerCase());
      final tagsMatch = searchQuery.tags.isEmpty || searchQuery.tags.every((searchTag) => lowerCaseTags.contains(searchTag.toLowerCase()));
      
      return textMatch && tagsMatch;
    }).toList();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == ScreenPurpose.select ? 'Select Note' : updatedPerson.info.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search notes by title...',
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
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                final isInfoNote = note.path == updatedPerson.info.path;
                final maxTagsToShow = 4;
                return Dismissible(
                  key: ValueKey(note.path),
                  direction: widget.purpose == ScreenPurpose.view && !isInfoNote ? DismissDirection.endToStart : DismissDirection.none,
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
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
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
                    color: colorScheme.secondary,
                    child: ListTile(
                      // leading: Icon(isInfoNote ? Icons.info_outline : Icons.description_outlined, size: 40),
                      title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month, size: 16,),
                              const SizedBox(width: 10,),
                              Text(
                                DateFormat('yyyy-MM-dd').format(note.lastModified.toLocal()),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          if (note.tags.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...(note.tags.length > maxTagsToShow
                                      ? note.tags.sublist(0, maxTagsToShow)
                                      : note.tags)
                                      .map((tag) => Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Tag(label: _formatTagName(tag)),
                                  ))
                                      .toList(),
                                  if (note.tags.length > maxTagsToShow)
                                    Tag(label: '+${note.tags.length - maxTagsToShow}'),
                                ],
                              ),
                            ),
                        ],
                      ),

                      trailing: isInfoNote ? const Chip(label: Text('Info'), visualDensity: VisualDensity.compact) : null,
                      onTap: () {
                        if (widget.purpose == ScreenPurpose.select) {
                          _showMentionInfoDialog(context, note);
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => NoteViewScreen(note: note)));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.purpose == ScreenPurpose.view ? CustomFloatButton(
        icon: Icons.add,
        tooltip: 'Add note',
        onTap: () => _showCreateNoteDialog(context, ref, updatedPerson),
      ) : null,
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