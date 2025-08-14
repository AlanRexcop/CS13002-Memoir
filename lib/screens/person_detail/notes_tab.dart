// C:\dev\memoir\lib\screens\person_detail\notes_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/custom_float_button.dart';
import 'package:memoir/widgets/note_card.dart';
import 'package:memoir/widgets/tag.dart';

class NotesTab extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const NotesTab({super.key, required this.person, required this.purpose});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  FocusNode? _searchFocusNode;
  final _searchController = TextEditingController();
  List<String> _selectedTags = [];
  TextEditingController? _autocompleteController;

  @override
  void initState() {
    super.initState();
    // Initialize search state from the provider
    final initialQuery = ref.read(detailSearchProvider);
    _searchController.text = initialQuery.text;
    _selectedTags = List.from(initialQuery.tags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch({String? text, List<String>? tags}) {
    final currentQuery = ref.read(detailSearchProvider);
    ref.read(detailSearchProvider.notifier).state = (text: text ?? currentQuery.text, tags: tags ?? currentQuery.tags);
  }

  Widget _buildUnifiedSearchField() {
    final allNotes = widget.person.notes;
    final uniqueTags = <String>{};
    for (final note in allNotes) {
      uniqueTags.addAll(note.tags);
    }
    final allAvailableTags = uniqueTags.toList()..sort();
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        _searchFocusNode?.requestFocus();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.primary, size: 30,),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap( // This Wrap is for the tags themselves
                spacing: 6.0,
                runSpacing: 4.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._selectedTags.map((tag) => Tag(
                    label: '#$tag',
                    onDeleted: () {
                      setState(() { _selectedTags.remove(tag); });
                      _updateSearch(tags: _selectedTags);
                    },
                  )),
                  // This is the structure from your MR file, using an Expanded TextField
                  // inside the Wrap. This is less common but we will adhere to it.
                  SizedBox(
                    width: 200, // Giving it a width to prevent layout errors
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase();
                        if (!query.startsWith('#') || query.length <= 1) {
                          return const <String>[];
                        }

                        final tagQuery = query.substring(1);
                        return allAvailableTags.where((tag) {
                          final isAlreadySelected = _selectedTags.contains(tag);
                          final matchesQuery = tag.toLowerCase().contains(tagQuery);
                          return !isAlreadySelected && matchesQuery;
                        });
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _selectedTags.add(selection);
                        });
                        _autocompleteController?.clear();
                        _updateSearch(tags: _selectedTags);
                        _searchFocusNode?.requestFocus();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        _searchFocusNode = focusNode;
                        _autocompleteController = controller;

                        final currentSearchText = ref.watch(detailSearchProvider).text;
                        if (controller.text != currentSearchText && !controller.text.startsWith('#')) {
                          controller.text = currentSearchText;
                        }

                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: _selectedTags.isEmpty && _searchController.text.isEmpty ? 'Search by name or #tag...' : '... or add another',
                          ),
                          onChanged: (value) {
                            if (!value.contains('#')) {
                              _searchController.text = value;
                              _updateSearch(text: value);
                            }
                          },
                          onSubmitted: (value) {
                            final trimmedValue = value.trim();
                            if (trimmedValue.startsWith('#') && trimmedValue.length > 1) {
                              onFieldSubmitted();
                            } else {
                              _searchController.text = trimmedValue;
                              _updateSearch(text: trimmedValue);
                            }
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: ListTile(title: Text(option), dense: true),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _toggleSelection(String notePath) {
    if (notePath == widget.person.info.path) return;

    setState(() {
      if (_selectedItems.contains(notePath)) {
        _selectedItems.remove(notePath);
      } else {
        _selectedItems.add(notePath);
      }
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll(List<Note> displayNotes) {
    setState(() {
      for (final note in displayNotes) {
        if (note.path != widget.person.info.path) {
          _selectedItems.add(note.path);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelectedItems() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete ${_selectedItems.length} selected item(s)?"),
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

    if (confirm != true) return;

    final allNotes = widget.person.notes;

    final notesToDelete = allNotes.where((note) => _selectedItems.contains(note.path)).toList();

    int successCount = 0;
    for (final note in notesToDelete) {
      final success = await ref.read(appProvider.notifier).deleteNote(note);
      if (success) {
        successCount++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted $successCount out of ${notesToDelete.length} items."),
          backgroundColor: successCount == notesToDelete.length ? Colors.green[700] : Colors.orange[700],
        ),
      );
    }

    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
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

  Widget _buildSelectionToolbar(ColorScheme colorScheme, List<Note> displayNotes) {
    final totalSelectableItems = displayNotes.where((n) => n.path != widget.person.info.path).length;
    final areAllItemsSelected = _selectedItems.length == totalSelectableItems && totalSelectableItems > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0,),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 0.0),
            child: Row(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _deselectAll,
                    ),
                    Text(
                      '${_selectedItems.length} selected',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete selected items',
                      onPressed: _selectedItems.isNotEmpty ? _deleteSelectedItems : null,
                    ),
                    IconButton(
                      icon: Icon(areAllItemsSelected ? Icons.deselect_sharp : Icons.select_all_rounded),
                      tooltip: areAllItemsSelected ? 'Deselect All' : 'Select All',
                      onPressed: areAllItemsSelected ? _deselectAll : () => _selectAll(displayNotes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == widget.person.path,
      orElse: () => widget.person,
    );

    final searchQuery = ref.watch(detailSearchProvider);
    final allNotes = updatedPerson.notes;

    final filteredNotes = allNotes.where((note) {
      if (searchQuery.text.isEmpty && searchQuery.tags.isEmpty) return true;
      final lowerCaseTitle = note.title.toLowerCase();
      final lowerCaseTags = note.tags.map((t) => t.toLowerCase()).toList();

      final textMatch = searchQuery.text.isEmpty || lowerCaseTitle.contains(searchQuery.text.toLowerCase());
      final tagsMatch = searchQuery.tags.isEmpty || searchQuery.tags.every((searchTag) => lowerCaseTags.contains(searchTag.toLowerCase()));

      return textMatch && tagsMatch;
    }).toList();

    final List<Note> displayNotes;
    if (widget.purpose == ScreenPurpose.select) {
      displayNotes = [updatedPerson.info, ...filteredNotes];
    } else {
      displayNotes = filteredNotes;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          if (_isSelectionMode)
            _buildSelectionToolbar(colorScheme, displayNotes)
          else
            _buildUnifiedSearchField(),
          const SizedBox(height: 5,),
          Expanded(
            child: ListView.builder(
              itemCount: displayNotes.length,
              itemBuilder: (context, index) {
                final note = displayNotes[index];
                final isInfoNote = note.path == updatedPerson.info.path;
                final isSelected = _selectedItems.contains(note.path);

                return Dismissible(
                  key: ValueKey(note.path),
                  direction: widget.purpose == ScreenPurpose.view && !isInfoNote && !_isSelectionMode
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
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
                  child: NoteCard(
                    note: note,
                    isInfoNote: isInfoNote,
                    isSelected: isSelected,
                    isSelectionMode: _isSelectionMode,
                    onToggleSelection: () => _toggleSelection(note.path),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(note.path);
                      } else if (widget.purpose == ScreenPurpose.select) {
                        _showMentionInfoDialog(context, note);
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => NoteViewScreen(note: note)));
                      }
                    },
                    onLongPress: () {
                      if (widget.purpose == ScreenPurpose.view && !isInfoNote) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedItems.add(note.path);
                        });
                      }
                    },
                  )
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
                // if (name.isEmpty) return;
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