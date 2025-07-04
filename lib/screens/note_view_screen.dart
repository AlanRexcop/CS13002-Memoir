// C:\dev\memoir\lib\screens\note_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/graph_view_screen.dart';
import 'package:memoir/screens/note_editor_screen.dart';
import 'package:memoir/services/markdown_analyzer_service.dart'; // Import custom syntax
import 'package:memoir/widgets/custom_markdown_elements.dart'; // Import custom elements

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'View Local Graph',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphViewScreen(rootNotePath: widget.note.path),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Note',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NoteEditorScreen(notePath: widget.note.path)),
              );
            },
          )
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final asyncContent = ref.watch(rawNoteContentProvider(widget.note.path));
          
          return asyncContent.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading note content:\n$err'),
              ),
            ),
            data: (content) {
              // --- NEW: Configure the MarkdownGenerator ---
              final markdownBuildContext = MarkdownBuildContext(context, ref);
              final generator = MarkdownGenerator(
                // 1. Tell the parser to recognize our custom syntax
                inlineSyntaxList: [
                  MentionSyntax(),
                  LocationSyntax(),
                  CalendarSyntax(),
                ],
                // 2. Tell the renderer how to build widgets for our custom tags
                generators: [
                  mentionGenerator(markdownBuildContext),
                  locationGenerator(markdownBuildContext),
                  eventGenerator(markdownBuildContext),
                ],
              );
              // --- END NEW ---

              return MarkdownWidget(
                data: content,
                tocController: tocController,
                padding: const EdgeInsets.all(16.0),
                // Pass our custom generator to the widget
                markdownGenerator: generator,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return TocWidget(controller: tocController);
            },
          );
        },
        tooltip: 'Table of Contents',
        child: const Icon(Icons.list_alt_outlined),
      ),
    );
  }
}