// C:\dev\memoir\lib\screens\person_detail\person_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/image_viewer.dart';
import 'package:memoir/widgets/tag.dart';
import 'info_tab.dart';
import 'notes_tab.dart';
import 'package:path/path.dart' as p;

class PersonDetailScreen extends ConsumerStatefulWidget {
  final Person person;
  final ScreenPurpose purpose;

  const PersonDetailScreen({super.key, required this.person, this.purpose = ScreenPurpose.view});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> with SingleTickerProviderStateMixin {
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

  void _mentionThisPerson() {
    final person = widget.person;
    final result = {
      'text': person.info.title,
      'path': person.info.path,
    };
    Navigator.of(context).pop(result);
  }

  void _showImageViewer(BuildContext context, Widget imageWidget, String heroTag) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => ImageViewer(heroTag: heroTag, child: imageWidget),
    ));
  }


  @override
  Widget build(BuildContext context) {
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == widget.person.path,
          orElse: () => widget.person,
        );
    final colorScheme = Theme.of(context).colorScheme;
    final vaultRoot = ref.watch(appProvider).storagePath;
    final infoNote = updatedPerson.info;
    
    File? avatarFile;
    if (vaultRoot != null && infoNote.images.isNotEmpty) {
      final decodedPath = Uri.decodeFull(infoNote.images.first);
      final file = File(p.join(vaultRoot, decodedPath));
      if (file.existsSync()) {
        avatarFile = file;
      }
    }

    Widget avatarDisplay;
    if (avatarFile != null) {
      avatarDisplay = CircleAvatar(
        radius: 25,
        backgroundImage: FileImage(avatarFile),
      );
    } else {
      avatarDisplay = CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white,
        child: Icon(
          infoNote.images.isNotEmpty ? Icons.broken_image : Icons.person,
          size: 30,
          color: colorScheme.primary
        ),
      );
    }
    
    // Create the tappable avatar widget
    Widget interactiveAvatar = GestureDetector(
      onTap: () {
        if (avatarFile != null) {
          _showImageViewer(context, Image.file(avatarFile), avatarFile.path);
        }
      },
      child: avatarDisplay,
    );


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_outlined, size: 30),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use the Hero widget only if we have a valid avatar file
                  avatarFile != null 
                    ? Hero(tag: avatarFile.path, child: interactiveAvatar) 
                    : interactiveAvatar,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updatedPerson.info.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (updatedPerson.info.tags.isNotEmpty)
                          Wrap(
                            spacing: 4.0,
                            runSpacing: 4.0,
                            children: updatedPerson.info.tags
                                .map((tag) => Tag(label: tag))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  if (widget.purpose == ScreenPurpose.select)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.alternate_email, size: 18),
                      label: const Text('Mention'),
                      onPressed: _mentionThisPerson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        // Handle publish action
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        elevation: 5,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('publish', style: TextStyle(fontSize: 17)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),
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
                        Icon(Icons.menu, size: 30),
                        SizedBox(width: 8),
                        Text('Info'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_sharp, size: 30),
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
                  InfoTab(person: updatedPerson),
                  NotesTab(
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