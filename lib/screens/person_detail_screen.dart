// C:\dev\memoir\lib\screens\person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/tag_editor.dart';
import '../widgets/custom_float_button.dart';
import '../widgets/tag.dart'; // Import for the enum


class PersonDetailScreen extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const PersonDetailScreen({super.key, required this.person, this.purpose = ScreenPurpose.view});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> with SingleTickerProviderStateMixin { // SingleTickerProviderStateMixin for animations
  // _tabController: manage tab bar state
  late TabController _tabController;
  // _tagController: controller for tag input
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _tagController = TextEditingController();
  }

  // _searchTags: list to hold search tags
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

  void _showCreateNoteDialog(BuildContext context, WidgetRef ref, Person currentPerson) {
    final nameController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
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
              style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop();
                final success = await ref.read(appProvider.notifier).createNewNoteForPerson(currentPerson, name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Note "$name" created.' : 'Failed to create note. Name might already exist.'),
                      backgroundColor: success ? Colors.green[700] : colorScheme.error,
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

  @override
  void dispose() {
    _tabController.dispose();    
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
      backgroundColor: colorScheme.surface,
      floatingActionButton: _tabController.index == 1 && widget.purpose == ScreenPurpose.view
          ? FloatingActionButton(
              onPressed: () => _showCreateNoteDialog(context, ref, updatedPerson),
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Nút Back
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            
            // 2. Header của contact (đã được chuyển vào đây)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _ContactHeader(
                person: updatedPerson,
                onAddTag: () => {}
              ),
            ),
            const SizedBox(height: 16),

            // 3. Thanh TabBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('Info'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined),
                        SizedBox(width: 8),
                        Text('Notes'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. Nội dung của các Tab
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

// ===================================================================
// WIDGET PHẦN HEADER CHUNG
// ===================================================================
class _ContactHeader extends StatelessWidget {
  final Person person;
  final VoidCallback onAddTag;

  const _ContactHeader({
    required this.person,
    required this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
  
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2.1.1 Avatar and change picture button
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary,
                child: Icon(Icons.person, color: colorScheme.onPrimary, size: 35),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    // Sử dụng primaryContainer cho màu nền viền nhẹ
                    color: colorScheme.primaryContainer.withOpacity(1.0), 
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, size: 16, color: colorScheme.primary),
                ),
              ),
            ]
          ),
          const SizedBox(width: 12),
          // 2.1.2 Contact Name and tags list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2.1.2.1. Contact Name
                Text(
                  person.info.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                // 2.1.2.2. Tags list and add tag button
                Row(
                  children: [
                    // Show first 3 tags
                    ...person.info.tags.take(3).map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Tag(label: tag, backgroundColor: colorScheme.secondary, textColor: colorScheme.onSecondary),
                        )),
                    // Add tag
                    GestureDetector(
                      onTap: onAddTag,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.primary),
                        ),
                        child: Icon(Icons.add, size: 14, color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 2.2 Publish button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Publish contact: ${person.info.title} successfully!'))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)
              ),
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// TAB 1: INFO
// ===================================================================

class _InfoTab extends StatelessWidget {
  final Person person;
  const _InfoTab({required this.person});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 4. First met on
        _InfoTextField(
          icon: Icons.favorite,
          label: 'First met on',
          initialValue: 'dd/mm/yyyy',
          trailingIcon: Icons.calendar_today,
          onTrailingIconTap: () { /* Logic mở date picker */ },
        ),
        const SizedBox(height: 16),
        // 5. Birthday
        _InfoTextField(
          icon: Icons.cake,
          label: 'Birthday',
          initialValue: 'dd/mm/yyyy',
          trailingIcon: Icons.calendar_today,
          onTrailingIconTap: () { /* Logic mở date picker */ },
        ),
        const SizedBox(height: 16),
        // 6. Phone
        _InfoTextField(
          icon: Icons.phone,
          label: 'Phone',
          initialValue: '0xxxxxxxxx', 
        ),
        const SizedBox(height: 16),
        // 7. Address
        _InfoTextField(
          icon: Icons.location_on,
          label: 'Address',
          initialValue: 'adding adress...',
          trailingIcon: Icons.edit_location_alt,
          onTrailingIconTap: () { /* Logic mở location picker */ },
        ),
      ],
    );
  }
}

// WIDGET: InfoTextField for Contact Info
class _InfoTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String initialValue;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconTap;

  const _InfoTextField({
    required this.icon,
    required this.label,
    required this.initialValue,
    this.trailingIcon,
    this.onTrailingIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: initialValue,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                // Thêm logic on-the-fly editing và auto-save ở đây
              ),
            ],
          ),
        ),
        if (trailingIcon != null)
          IconButton(
            icon: Icon(trailingIcon, color: colorScheme.primary),
            onPressed: onTrailingIconTap,
          ),
      ],
    );
  }
}

// ===================================================================
// TAB 2: NOTES
// ===================================================================
enum _SortBy { newest, oldest, az, za }

class _NotesTab extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const _NotesTab({required this.person, required this.purpose});

  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<_NotesTab> {
  final Set<String> _selectedNotePaths = {};
  _SortBy _currentSort = _SortBy.newest;
  List<String> _activeFilterTags = [];

  void _toggleNoteSelection(String notePath) {
    setState(() {
      if (_selectedNotePaths.contains(notePath)) {
        _selectedNotePaths.remove(notePath);
      } else {
        _selectedNotePaths.add(notePath);
      }
    });
  }
  
  void _toggleSelectAll(List<Note> allNotes) {
    setState(() {
      if (_selectedNotePaths.length == allNotes.length) {
        _selectedNotePaths.clear();
      } else {
        _selectedNotePaths.addAll(allNotes.map((n) => n.path));
      }
    });
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete ${_selectedNotePaths.length} selected note(s)?"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final notesToDelete = widget.person.notes.where((note) => _selectedNotePaths.contains(note.path)).toList();
      
      final futures = notesToDelete.map((note) => ref.read(appProvider.notifier).deleteNote(note));
      await Future.wait(futures);

      setState(() {
        _selectedNotePaths.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${notesToDelete.length} note(s) deleted."), backgroundColor: Colors.green[700]),
        );
      }
    }
  }

  void _showSortOptions(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<_SortBy>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: _SortBy.newest, child: Text('Newest first')),
        PopupMenuItem(value: _SortBy.oldest, child: Text('Oldest first')),
        PopupMenuItem(value: _SortBy.az, child: Text('Sort A-Z')),
        PopupMenuItem(value: _SortBy.za, child: Text('Sort Z-A')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _currentSort = value;
        });
      }
    });
  }

  void _showFilterDialog() {
    // Lấy tất cả các tag duy nhất từ danh sách note
    final allTags = widget.person.notes.expand((note) => note.tags).toSet().toList();
    allTags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    showDialog(
      context: context,
      builder: (context) {
        // Sử dụng StatefulBuilder để quản lý trạng thái của dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Tags'),
              content: allTags.isEmpty 
                ? const Text("No tags available to filter.")
                : SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    children: allTags.map((tag) {
                      final isSelected = _activeFilterTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              _activeFilterTags.add(tag);
                            } else {
                              _activeFilterTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Cập nhật lại UI chính khi dialog đóng
                    setState(() {}); 
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = widget.person.notes;

    List<Note> displayedNotes = List.from(widget.person.notes);

    // 1. Filter
    if (_activeFilterTags.isNotEmpty) {
      displayedNotes = displayedNotes.where((note) {
        final noteTags = note.tags.toSet();
        return _activeFilterTags.every((filterTag) => noteTags.contains(filterTag));
      }).toList();
    }

    // 2. Sort
    displayedNotes.sort((a, b) {
      switch (_currentSort) {
        case _SortBy.newest:
          return b.lastModified.compareTo(a.lastModified);
        case _SortBy.oldest:
          return a.lastModified.compareTo(b.lastModified);
        case _SortBy.az:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case _SortBy.za:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // 4.  Total Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.5)),
              ),
              child: Row(
                children: [
                  // Checkbox (select all)
                  Checkbox(
                    value: _selectedNotePaths.isNotEmpty && _selectedNotePaths.length == notes.length,
                    onChanged: (val) => _toggleSelectAll(notes),
                    activeColor: colorScheme.primary,
                  ),

                  // Count number of notes
                  Expanded(
                    child: Text(
                      _selectedNotePaths.isEmpty
                          ? "All ${widget.person.info.title}'s notes (${notes.length})"
                          : "Selected notes (${_selectedNotePaths.length})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // get context for showMenu
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.swap_vert, color: colorScheme.primary),
                      onPressed: () => _showSortOptions(context),
                    ),
                  ),
                  // Filter icon
                  IconButton(
                    icon: Icon(Icons.filter_list, color: colorScheme.primary),
                    onPressed: _showFilterDialog,
                  ),
                  // Delete button (only when there is a selected note)
                  if (_selectedNotePaths.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: _showDeleteConfirmationDialog,
                    ),
                ],
              ),
            ),
          ),

          // 5. Notes list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: displayedNotes.length,
              itemBuilder: (context, index) {
                final note = displayedNotes[index];
                final isSelected = _selectedNotePaths.contains(note.path);
                
                return _NoteCard(
                  note: note,
                  isSelected: isSelected,
                  onTap: () {
                    if (_selectedNotePaths.isNotEmpty) {
                      _toggleNoteSelection(note.path);
                    } else {
                       Navigator.of(context).push(MaterialPageRoute(builder: (context) => NoteViewScreen(note: note)));
                    }
                  },
                  onLongPress: () {
                    _toggleNoteSelection(note.path);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET: NOTE CARD
class _NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard({
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  // build a row to show create date, modify date
  Widget _buildDateRow(BuildContext context, {required IconData icon, required String label, required DateTime date}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: textTheme.bodySmall?.color?.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          '$label: ${DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())}',
          style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.7)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxTagsToShow = 3;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.8),
              offset: const Offset(4, 4),
              blurRadius: 0,
            )
          ] : [],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : Theme.of(context).dividerColor,
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // note title
                Text(
                  note.title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // date create
                _buildDateRow(
                  context,
                  icon: Icons.add_circle_outline,
                  label: 'Created',
                  date: note.creationDate,
                ),
                const SizedBox(height: 4),
                // date modify
                _buildDateRow(
                  context,
                  icon: Icons.edit_calendar_outlined,
                  label: 'Modified',
                  date: note.lastModified,
                ),
                const SizedBox(height: 12),

                // tags list
                if(note.tags.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      ...note.tags.take(maxTagsToShow).map((tag) => Tag(
                            label: tag,
                            backgroundColor: colorScheme.surface,
                            textColor: colorScheme.primary,
                            borderColor: Theme.of(context).dividerColor,
                          )),
                      if (note.tags.length > maxTagsToShow)
                        Tag(
                          label: '+${note.tags.length - maxTagsToShow}',
                          backgroundColor: colorScheme.surface,
                          textColor: colorScheme.primary,
                          borderColor: Theme.of(context).dividerColor,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
