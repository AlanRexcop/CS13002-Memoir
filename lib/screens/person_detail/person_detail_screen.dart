// C:\dev\memoir\lib\screens\person_detail\person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/tag.dart';
import 'info_tab.dart';
import 'notes_tab.dart';

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

  // NEW: Function to handle mentioning the person directly
  void _mentionThisPerson() {
    final person = widget.person;
    // Prepare the result map that the note editor expects
    final result = {
      'text': person.info.title,
      'path': person.info.path,
    };
    // Pop the screen and return the result
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final updatedPerson = ref.watch(appProvider).persons.firstWhere(
          (p) => p.path == widget.person.path,
          orElse: () => widget.person,
        );
    final colorScheme = Theme.of(context).colorScheme;

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
                  // MODIFIED: Conditionally show buttons based on the purpose
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