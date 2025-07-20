// C:\dev\memoir\lib\screens\person_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
// import 'package:memoir/screens/calendar_screen.dart';
// import 'package:memoir/screens/image_gallery_screen.dart';
// import 'package:memoir/screens/map_screen.dart';
import 'package:memoir/screens/person_detail_screen.dart';

import '../widgets/tag.dart';
// import 'package:memoir/screens/graph_view_screen.dart';
// import 'package:memoir/screens/settings_screen.dart';

enum ScreenPurpose { view, select }

class PersonListScreen extends ConsumerStatefulWidget {
  final ScreenPurpose purpose;

  const PersonListScreen({super.key, this.purpose = ScreenPurpose.view});

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
    final appState = ref.watch(appProvider);
    final filteredPersons = appState.filteredPersons;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.purpose == ScreenPurpose.select ? 'Select Person' : 'Persons'),
      // ),
      // bottomNavigationBar: widget.purpose == ScreenPurpose.view
      //     ? NavigationBar(
      //   onDestinationSelected: (int index) {
      //     _onItemTapped(index);
      //   },
      //   selectedIndex: 0,
      //   destinations: const <Widget>[
      //     NavigationDestination(
      //       selectedIcon: Icon(Icons.people), // Icon khi được chọn
      //       icon: Icon(Icons.people_outline),
      //       label: 'Persons',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.photo_library_outlined),
      //       label: 'Gallery',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.hub_outlined),
      //       label: 'Graph',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.map_outlined),
      //       label: 'Map',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.calendar_month),
      //       label: 'Calendar',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.settings_outlined),
      //       label: 'Settings',
      //     ),
      //   ],
      // )
      //     : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                    image: const DecorationImage(
                      image: AssetImage("assets/avatar.png"),
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
                        'Nguyen Gia Huy',
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
                  icon: Icon(
                    Icons.notifications_none_outlined,
                    color: colorScheme.primary,
                    size: 30,
                  ),
                  tooltip: 'Notifications',
                  onPressed: () {
                    // TODO:
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(appProvider.notifier).refreshVault(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.deepPurple[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ), contentPadding: const EdgeInsets.symmetric(vertical: 10.0)
                ),
                onChanged: (value) => _updateSearch(text: value),
              ),
            ),


            const SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement sort action.
                    },
                    child: Icon(Icons.swap_vert, color: Colors.deepPurple.shade300, size: 24),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement filter action.
                    },
                    child: Icon(Icons.sort, color: Colors.deepPurple.shade300, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Contacts (${filteredPersons.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Theme.of(context).dividerColor),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: Row(
            //       children: [
            //         const Icon(Icons.label_outline, size: 20),
            //         const SizedBox(width: 8),
            //         Expanded(
            //           child: Wrap(
            //             spacing: 8.0,
            //             runSpacing: 4.0,
            //             children: [
            //               ..._searchTags.map((tag) => Chip(
            //                     label: Text(tag),
            //                     onDeleted: () {
            //                       setState(() => _searchTags.remove(tag));
            //                       _updateSearch(tags: _searchTags);
            //                     },
            //                     visualDensity: VisualDensity.compact,
            //                   )),
            //               SizedBox(
            //                 width: 150,
            //                 child: TextField(
            //                   controller: _tagController,
            //                   decoration: const InputDecoration(
            //                     isDense: true,
            //                     contentPadding: EdgeInsets.symmetric(vertical: 8.0),
            //                     border: InputBorder.none,
            //                     hintText: 'Filter by tag...',
            //                   ),
            //                   onSubmitted: (tag) {
            //                     tag = tag.trim();
            //                     if (tag.isNotEmpty && !_searchTags.contains(tag)) {
            //                       setState(() => _searchTags.add(tag));
            //                       _tagController.clear();
            //                       _updateSearch(tags: _searchTags);
            //                     }
            //                   },
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  const int maxTagsToShow = 1;
                  return Dismissible(
                    key: ValueKey(person.path),
                    direction: widget.purpose == ScreenPurpose.view ? DismissDirection.endToStart : DismissDirection.none,
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
                    // child: Card(
                    //   margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    //   child: ListTile(
                    //     leading: const Icon(Icons.person_outline, size: 40),
                    //     title: Text(person.info.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    //     subtitle: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Text('${person.notes.length} associated notes'),
                    //         const SizedBox(height: 4),
                    //         if (person.info.tags.isNotEmpty)
                    //           Wrap(
                    //             spacing: 4.0,
                    //             runSpacing: 4.0,
                    //             children: person.info.tags.map((tag) => Chip(
                    //               label: Text(tag),
                    //               padding: EdgeInsets.zero,
                    //               visualDensity: VisualDensity.compact,
                    //               labelStyle: const TextStyle(fontSize: 10),
                    //             )).toList(),
                    //           ),
                    //       ],
                    //     ),
                    //     onTap: () async {
                    //       if (widget.purpose == ScreenPurpose.select) {
                    //         final result = await Navigator.of(context).push<Map<String, String>>(
                    //           MaterialPageRoute(
                    //             builder: (context) => PersonDetailScreen(
                    //               person: person,
                    //               purpose: ScreenPurpose.select, // Pass the purpose down
                    //             ),
                    //           ),
                    //         );
                    //         if (result != null && context.mounted) {
                    //           Navigator.of(context).pop(result); // Pass the result up
                    //         }
                    //       } else {
                    //         ref.read(detailSearchProvider.notifier).state = (text: '', tags: const []);
                    //         Navigator.of(context).push(
                    //           MaterialPageRoute(
                    //             builder: (context) => PersonDetailScreen(person: person),
                    //           ),
                    //         );
                    //       }
                    //     },
                    //   ),
                    // ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.primary,
                            ),
                          ),


                          title: Text(person.info.title, style: const TextStyle(fontWeight: FontWeight.bold)),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('${person.notes.length} notes', style: TextStyle(fontSize: 14),),
                              const SizedBox(width: 8),
                              // if (person.info.tags.isNotEmpty)
                              //   Wrap(
                              //     spacing: 4.0,
                              //     runSpacing: 4.0,
                              //     children: person.info.tags.map((tag) => Chip(
                              //       label: Text(tag),
                              //       padding: EdgeInsets.zero,
                              //       visualDensity: VisualDensity.compact,
                              //       labelStyle: const TextStyle(fontSize: 10),
                              //     )).toList(),
                              //   ),
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
                                          .toList(),
                                      if (person.info.tags.length > maxTagsToShow)
                                        Tag(label: '+${person.info.tags.length - maxTagsToShow}'),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // Container(
                              //   width: 12,
                              //   height: 12,
                              //   decoration: BoxDecoration(
                              //     color: Colors.pink[200],
                              //     shape: BoxShape.circle,
                              //   ),
                              // ),
                              // const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.deepPurple),
                            ],
                          ),
                          onTap: () async {
                            if (widget.purpose == ScreenPurpose.select) {
                              final result = await Navigator.of(context).push<Map<String, String>>(
                                MaterialPageRoute(
                                  builder: (context) => PersonDetailScreen(
                                    person: person,
                                    purpose: ScreenPurpose.select, // Pass the purpose down
                                  ),
                                ),
                              );
                              if (result != null && context.mounted) {
                                Navigator.of(context).pop(result); // Pass the result up
                              }
                            } else {
                              ref.read(detailSearchProvider.notifier).state = (text: '', tags: const []);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PersonDetailScreen(person: person),
                                ),
                              );
                            }
                          },
                        ),

                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 10,
                          endIndent: 16,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.purpose == ScreenPurpose.view ? FloatingActionButton(
        onPressed: () => _showCreatePersonDialog(context, ref),
        tooltip: 'Add Person',
        backgroundColor: Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: colorScheme.primary,
            width: 4.0,
          ),
        ),
        child: Icon(
          Icons.add,
          color: colorScheme.primary,
          size: 36,
        ),
      ) : null,
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