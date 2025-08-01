// C:\dev\memoir\lib\screens\person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/custom_search_bar.dart';
import 'package:memoir/widgets/primary_button.dart';
import 'package:memoir/widgets/tag_editor.dart';
import '../widgets/custom_float_button.dart';
import '../widgets/note_card.dart';
import '../widgets/tag.dart';


class PersonDetailScreen extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const PersonDetailScreen({super.key, required this.person, this.purpose = ScreenPurpose.view});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> with SingleTickerProviderStateMixin{

  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == widget.person.path,
          orElse: () => widget.person,
        );
    final colorScheme = Theme.of(context).colorScheme;
    const int maxTagsToShow = 3;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_outlined, size: 30,),
        ),
        // title: Text(widget.purpose == ScreenPurpose.select ? 'Select Note' : updatedPerson.info.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 45,
                          color: colorScheme.primary,
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updatedPerson.info.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (updatedPerson.info.tags.isNotEmpty)
                              Wrap(
                                spacing: 4.0,
                                runSpacing: 4.0,
                                children: [
                                  ...(updatedPerson.info.tags.length > maxTagsToShow
                                      ? updatedPerson.info.tags.sublist(0, maxTagsToShow)
                                      : updatedPerson.info.tags)
                                      .map((tag) => Tag(label: _formatTagName(tag)))
                                      .toList(),
                                  if (updatedPerson.info.tags.length > maxTagsToShow)
                                    Tag(label: '+${updatedPerson.info.tags.length - maxTagsToShow}'),
                                ],
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle publish action
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          elevation: 5,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('publish', style: TextStyle(color: Colors.white, fontSize: 17),),
                      ),
                    ]
                ),
            ),
            const SizedBox(height: 15,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.grey.shade300,
                dividerHeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 3.0,
                  ),
                ),

                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu, size: 30,),
                        SizedBox(width: 8),
                        Text('Info'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_sharp, size: 30,),
                        SizedBox(width: 8),
                        Text('Notes'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(person: updatedPerson),
                  _NotesTab(
                    person: updatedPerson,
                    purpose: widget.purpose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ========================= INFO TAB ===========================
class _InfoTab extends ConsumerStatefulWidget {
  final Person person;
  const _InfoTab({required this.person});

  @override
  ConsumerState<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<_InfoTab> {
  late final TextEditingController _firstMetOnController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // final personInfo = widget.person.info;

    _firstMetOnController = TextEditingController(text: 'dd/mm/yyyy');
    _birthdayController = TextEditingController(text: 'dd/mm/yyyy');
    _phoneController = TextEditingController(text: '09xxxxxx03');
    _addressController = TextEditingController(text: 'Ho Chi Minh');
  }

  @override
  void dispose() {
    _firstMetOnController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate != null) {
      controller.text = _dateFormatter.format(selectedDate);
    }
  }

  void _saveChanges() {
    // TODO: Implement the logic to save the updated info

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Changes saved"), backgroundColor: Colors.green)
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _InfoTextField(
            controller: _firstMetOnController,
            icon: Icons.favorite,
            label: 'First met on',
            readOnly: true,
            trailingIcon: Icons.calendar_today,
            onTrailingIconTap: () => _selectDate(context, _firstMetOnController),
          ),
          const SizedBox(height: 16),
          _InfoTextField(
            controller: _birthdayController,
            icon: Icons.cake,
            label: 'Birthday',
            readOnly: true,
            trailingIcon: Icons.calendar_today,
            onTrailingIconTap: () => _selectDate(context, _birthdayController),
          ),
          const SizedBox(height: 16),
          _InfoTextField(
            controller: _phoneController,
            icon: Icons.phone,
            label: 'Phone',
          ),
          const SizedBox(height: 16),
          _InfoTextField(
            controller: _addressController,
            icon: Icons.location_on,
            label: 'Address',
            trailingIcon: Icons.edit_location_alt,
            onTrailingIconTap: () { /* TODO: Logic to open a location picker */ },
          ),
          const SizedBox(height: 40),

          PrimaryButton(text: 'Save changes', background: Theme.of(context).colorScheme.primary, onPress: _saveChanges)
        ],
      ),
    );
  }
}


class _InfoTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconTap;
  final bool readOnly;

  const _InfoTextField({
    required this.controller,
    required this.icon,
    required this.label,
    this.trailingIcon,
    this.onTrailingIconTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            suffixIcon: trailingIcon != null
                ? IconButton(
              icon: Icon(trailingIcon, color: colorScheme.primary),
              onPressed: onTrailingIconTap,
            ) : null,
            filled: true,
            fillColor: const Color(0xFFFEF4FF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
          ),
        ),
      ],
    );
  }
}



// ========================= NOTE TAB ===========================
class _NotesTab extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const _NotesTab({required this.person, required this.purpose});

  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}


class _NotesTabState extends ConsumerState<_NotesTab> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  bool _isSearchExpanded = false;
  bool _isFilterExpanded = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _isSearchExpanded) {
        setState(() {
          _isSearchExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }


  Widget _buildSearchAndFilterControls() {
    if (_isSearchExpanded) {
      return Container(
        key: const ValueKey('search_bar_wrapper'),
        child: Row(
          children: [
            Expanded(
              child: CustomSearchBar(
                focusNode: _searchFocusNode,
                onChange: (value) => _updateSearch(text: value),
                hintText: 'Search notes by title...',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close Search',
              onPressed: () {
                setState(() {
                  _isSearchExpanded = false;
                  _updateSearch(text: "");
                });
              },
            ),
          ],
        ),
      );
    }
    else if (_isFilterExpanded) {
      return Container(
        key: const ValueKey('filter_bar'),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0,),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TagEditor(
                  purpose: TagInputPurpose.filter,
                  initialTags: ref.read(detailSearchProvider).tags,
                  onTagsChanged: (newTags) {
                    _updateSearch(tags: newTags);
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close Filter',
              onPressed: () {
                _updateSearch(tags: []);
                setState(() {
                  _isFilterExpanded = false;
                });
              },
            ),
          ],
        ),
      );
    }
    else {
      return Row(
        key: const ValueKey('icons_row'),
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              setState(() {
                _isSearchExpanded = true;
                _isFilterExpanded = false;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchFocusNode.requestFocus();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Tags',
            onPressed: () {
              setState(() {
                _isFilterExpanded = true;
                _isSearchExpanded = false;
              });
            },
          ),
        ],
      );
    }
  }


  void _toggleSelection(String notePath) {
    final isInfoNote = notePath == widget.person.info.path;
    if (isInfoNote) return;

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
          content: Text(
              "Are you sure you want to delete ${_selectedItems.length} selected item(s)?"),
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

    final notesToDelete = allNotes
        .where((note) => _selectedItems.contains(note.path))
        .toList();

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
          content: Text(
              "Deleted $successCount out of ${notesToDelete.length} items."),
          backgroundColor: successCount == notesToDelete.length
              ? Colors.green[700]
              : Colors.orange[700],
        ),
      );
    }

    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

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

  Widget _buildSelectionToolbar(ColorScheme colorScheme, List<Note> displayNotes) {
    final totalSelectableItems = displayNotes.length - 1;
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

    final displayNotes = [updatedPerson.info, ...filteredNotes];

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // const SizedBox(height: 25,),
          if (_isSelectionMode)
            _buildSelectionToolbar(colorScheme, displayNotes)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      child: child,
                    ),
                  );
                },
                child: _buildSearchAndFilterControls(),
              ),
            ),
          // const Divider(height: 1, thickness: 2, color: Colors.grey),
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