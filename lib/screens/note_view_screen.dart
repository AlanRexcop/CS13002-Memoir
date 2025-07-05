// C:\dev\memoir\lib\screens\note_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/graph_view_screen.dart';
import 'package:memoir/screens/note_editor_screen.dart';
import 'package:memoir/services/markdown_analyzer_service.dart';
import 'package:memoir/widgets/custom_markdown_elements.dart';
import 'package:memoir/widgets/note_metadata_card.dart'; // Import the new widget

class NoteViewScreen extends ConsumerStatefulWidget {
  final Note note;

  const NoteViewScreen({super.key, required this.note});

  @override
  ConsumerState<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends ConsumerState<NoteViewScreen> {
  final TocController tocController = TocController();

  @override
  void dispose() {
    tocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Watch the provider to get the most up-to-date note object ---
    // This ensures that when we come back from editing, the metadata card is also updated.
    final latestNote = ref.watch(appProvider.select((state) {
      for (final person in state.persons) {
        if (person.info.path == widget.note.path) return person.info;
        try {
          return person.notes.firstWhere((n) => n.path == widget.note.path);
        } catch (e) { /* not in this person */ }
      }
      return widget.note; // Fallback
    }));


    return Scaffold(
      appBar: AppBar(
        title: Text(latestNote.title), // Use latestNote title
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'View Local Graph',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphViewScreen(rootNotePath: latestNote.path),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Note',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NoteEditorScreen(notePath: latestNote.path)),
              );
            },
          )
        ],
      ),
      // --- UPDATED BODY STRUCTURE ---
      // We use a SingleChildScrollView with a Column to place our widgets.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The beautiful metadata card
            NoteMetadataCard(note: latestNote),

            // 2. The markdown content
            Consumer(
              builder: (context, ref, child) {
                final asyncContent = ref.watch(rawNoteContentProvider(latestNote.path));
                
                return asyncContent.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  )),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading note content:\n$err'),
                    ),
                  ),
                  data: (content) {
                    final markdownBuildContext = MarkdownBuildContext(context, ref);
                    final generator = MarkdownGenerator(
                      inlineSyntaxList: [
                        MentionSyntax(),
                        LocationSyntax(),
                        CalendarSyntax(),
                      ],

                      generators: [
                        mentionGenerator(markdownBuildContext),
                        locationGenerator(markdownBuildContext),
                        eventGenerator(markdownBuildContext),
                      ],
                    );
                    
                    // We need to pass the raw content to the MarkdownWidget
                    final mainContent = content.startsWith('---') 
                      ? content.split('---').sublist(2).join('---').trim() 
                      : content;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      // We can no longer use the main TocController here because the
                      // MarkdownWidget is inside another scroll view. But this layout is
                      // much cleaner. For simplicity, we remove the TOC for now.
                      child: MarkdownWidget(
                        data: mainContent,
                        shrinkWrap: true, // Important for nesting
                        physics: const NeverScrollableScrollPhysics(), // Important for nesting
                        markdownGenerator: generator,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}