// C:\dev\memoir\lib\screens\person_list_screen.dart
import 'dart:io';
import 'package:memoir/screens/image_gallery_screen.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/notification_screen.dart';
import 'package:memoir/screens/person_detail/person_detail_screen.dart';
import '../providers/cloud_provider.dart';
import '../widgets/custom_float_button.dart';
import '../widgets/tag.dart';
import 'package:memoir/screens/graph_view_screen.dart';

enum ScreenPurpose { view, select }

class PersonListScreen extends ConsumerStatefulWidget {
  final ScreenPurpose purpose;

  const PersonListScreen({super.key, this.purpose = ScreenPurpose.view});

  @override
  ConsumerState<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends ConsumerState<PersonListScreen> {
  final _tagController = TextEditingController();
  final _searchController = TextEditingController();
  final List<String> _selectedTags = [];
  FocusNode? _searchFocusNode;
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};
  TextEditingController? _autocompleteController;

  void _updateSearch() {
    ref.read(appProvider.notifier).setSearchQuery(
        (
        text: _searchController.text.trim(),
        tags: _selectedTags,
        )
    );
  }

  Widget _buildUnifiedSearchField() {
    final allPersons = ref.watch(appProvider).persons;
    final uniqueTags = <String>{};
    for (final person in allPersons) {
      for (final note in [person.info, ...person.notes]) {
        uniqueTags.addAll(note.tags);
      }
    }
    final allAvailableTags = uniqueTags.toList()..sort();
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        _searchFocusNode?.requestFocus();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.primary, size: 30,),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                spacing: 6.0,
                // runSpacing: 4.0,
                // crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._selectedTags.map((tag) => Tag(
                    label: '#$tag',
                    onDeleted: () {
                      setState(() { _selectedTags.remove(tag); });
                      _updateSearch();
                    },
                  )),
                  Expanded(
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
                        _updateSearch();
                        _searchFocusNode?.requestFocus();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        _searchFocusNode = focusNode;
                        _autocompleteController = controller;

                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(

                            isDense: true,
                            border: InputBorder.none,
                            hintText: _selectedTags.isEmpty ? 'Search by name or #tag...' : '... or add another',
                          ),
                          onChanged: (value) {
                            if (!value.contains('#')) {
                              _searchController.text = value;
                              _updateSearch();
                            }
                          },
                          onSubmitted: (value) {
                            final trimmedValue = value.trim();
                            if (trimmedValue.startsWith('#') && trimmedValue.length > 1) {
                              onFieldSubmitted();
                            } else {
                              _searchController.text = trimmedValue;
                              _updateSearch();
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
                                    child: ListTile(title: Text(option, style: TextStyle(fontSize: 14),), dense: true),
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
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String personPath) {
    setState(() {
      if (_selectedItems.contains(personPath)) {
        _selectedItems.remove(personPath);
      } else {
        _selectedItems.add(personPath);
      }
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _deleteSelectedItems() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete ${_selectedItems.length} selected item(s)? This action cannot be undone."),
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
    final allPersons = ref.read(appProvider).filteredPersons;
    final personsToDelete = allPersons.where((p) => _selectedItems.contains(p.path)).toList();

    int successCount = 0;
    for (final person in personsToDelete) {
      final success = await ref.read(appProvider.notifier).deletePerson(person);
      if (success) {
        successCount++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted $successCount out of ${personsToDelete.length} items."),
          backgroundColor: successCount == personsToDelete.length ? Colors.green[700] : Colors.orange[700],
        ),
      );
    }


    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    if (_isSelectionMode) {
      return AppBar(
        title: Text('${_selectedItems.length} selected'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedItems.clear();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete selected items',
            onPressed: _selectedItems.isNotEmpty ? _deleteSelectedItems : null,
          ),
        ],
      );
    }

    if (widget.purpose == ScreenPurpose.select) {
      return AppBar(
        title: const Text('Select Person'),
      );
    }
    final avatarAsync = ref.watch(localAvatarProvider);
    final avatarImage = avatarAsync.when(
      data: (bytes) => (bytes != null)
          ? MemoryImage(bytes) as ImageProvider
          : const AssetImage('assets/avatar.png'),
      loading: () => const AssetImage('assets/avatar.png'),
      error: (_, __) => const AssetImage('assets/avatar.png'),
    );

    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 4,
                    color: Colors.white,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      spreadRadius: 2,
                      blurRadius: 10,
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                    )
                  ],
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: avatarImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.watch(appProvider).currentUser?.userMetadata?['username'] ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'How are you today?',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageGalleryScreen()));
                },
                icon: Icon(Icons.photo_library_outlined, color: colorScheme.primary, size: 25),
                tooltip: 'Image Vault',
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GraphViewScreen()
                      ));
                },
                icon: Icon(Icons.hub_outlined, color: colorScheme.primary, size: 25),
                tooltip: 'Graph View',
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: colorScheme.primary,
                  size: 30,
                ),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationScreen()
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final filteredPersons = appState.filteredPersons;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _buildAppBar(colorScheme),
      body: RefreshIndicator(
        onRefresh: () => widget.purpose == ScreenPurpose.view
            ? ref.read(appProvider.notifier).refreshVault()
            : Future.value(),
        child: Column(
          children: [
            _buildUnifiedSearchField(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Text(
                    'Contacts (${filteredPersons.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),

                  const Spacer(),

                  if (_isSelectionMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: filteredPersons.isNotEmpty && _selectedItems.length == filteredPersons.length,
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedItems.addAll(filteredPersons.map((p) => p.path));
                              } else {
                                _selectedItems.clear();
                              }
                            });
                          },
                        ),
                        const Text('Select All', style: TextStyle(fontSize: 14),),
                      ],
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  const int maxTagsToShow = 2;
                  final isSelected = _selectedItems.contains(person.path);

                  // --- AVATAR LOGIC ---
                  final vaultRoot = appState.storagePath;
                  final infoNote = person.info;
                  Widget avatarWidget;

                  if (vaultRoot != null && infoNote.images.isNotEmpty) {
                    final decodedPath = Uri.decodeFull(infoNote.images.first);
                    final avatarFile = File(p.join(vaultRoot, decodedPath));

                    if (avatarFile.existsSync()) {
                      avatarWidget = CircleAvatar(
                        backgroundImage: FileImage(avatarFile),
                      );
                    } else {
                      avatarWidget = CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.broken_image, color: colorScheme.primary),
                      );
                    }
                  } else {
                    avatarWidget = CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.primary,
                      ),
                    );
                  }
                  // --- END AVATAR LOGIC ---

                  return Dismissible(
                    key: ValueKey(person.path),
                    direction: (widget.purpose == ScreenPurpose.view && !_isSelectionMode)
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
                    child: ListTile(
                      tileColor: isSelected ? colorScheme.secondary.withOpacity(0.3) : null,
                      leading: _isSelectionMode
                          ? Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleSelection(person.path);
                        },
                      )
                          : avatarWidget,
                      title: Text(person.info.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('${person.notes.length} notes', style: const TextStyle(fontSize: 14),),
                          const SizedBox(width: 8),
                          if (person.info.tags.isNotEmpty)
                            Flexible(
                              child: Wrap(
                                spacing: 4.0,
                                runSpacing: 4.0,
                                children: [
                                  ...(person.info.tags.length > maxTagsToShow
                                      ? person.info.tags.sublist(0, maxTagsToShow)
                                      : person.info.tags)
                                      .map((tag) => Tag(label: _formatTagName(tag)))
                                      ,
                                  if (person.info.tags.length > maxTagsToShow)
                                    Tag(label: '+${person.info.tags.length - maxTagsToShow}'),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.deepPurple),
                        ],
                      ),
                      onTap: () async {
                        if (_isSelectionMode) {
                          _toggleSelection(person.path);
                        } else if (widget.purpose == ScreenPurpose.select) {
                          await Future.delayed(const Duration(milliseconds: 1));
                          final result = await Navigator.of(context).push<Map<String, String>>(

                            MaterialPageRoute(
                              builder: (context) => PersonDetailScreen(
                                person: person,
                                purpose: ScreenPurpose.select,
                              ),
                            ),
                          );
                          if (result != null && context.mounted) {
                            Navigator.of(context).pop(result);
                          }
                        } else {
                          ref.read(detailSearchProvider.notifier).state = (text: '', tags: const []);
                        await Future.delayed(const Duration(milliseconds: 1));
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PersonDetailScreen(person: person),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (widget.purpose == ScreenPurpose.view && !_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedItems.add(person.path);
                          });
                        }
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 10,
                    endIndent: 16,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.purpose == ScreenPurpose.view
          ? CustomFloatButton(
          icon: Icons.add,
          tooltip: 'Add person',
          onTap: () => _showCreatePersonDialog(context, ref)
      )
          : null
      ,
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