import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_editor_screen.dart';

class NoteViewScreen extends ConsumerStatefulWidget {
  final Note note;

  const NoteViewScreen({super.key, required this.note});

  @override
  ConsumerState<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends ConsumerState<NoteViewScreen> {
  // We manage the TocController's lifecycle within the state.
  final TocController tocController = TocController();

  @override
  void dispose() {
    // It's crucial to dispose of the controller to prevent memory leaks.
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
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Note',
            onPressed: () {
              // Use pushReplacement so the user doesn't build up a stack
              // of view/edit pages by toggling back and forth.
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NoteEditorScreen(notePath: widget.note.path)),
              );
            },
          )
        ],
      ),
      // The body directly loads and displays the Markdown content.
      body: Consumer(
        builder: (context, ref, child) {
          // Use the provider to fetch the raw markdown string from the file.
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
              // The MarkdownWidget is the main body. It manages its own
              // internal scrolling, which is what allows the TOC to work correctly.
              return MarkdownWidget(
                data: content,
                tocController: tocController,
                padding: const EdgeInsets.all(16.0),
              );
            },
          );
        },
      ),
      // The FloatingActionButton is now the single, consistent way to
      // access the Table of Contents on all screen sizes.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show the TOC in a modal bottom sheet, which is a great mobile-first pattern.
          showModalBottomSheet(
            context: context,
            // Give the sheet a max height for better appearance on large screens.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            isScrollControlled: true, // Allows the sheet to be taller
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              // The TocWidget automatically builds the list of headers.
              // Tapping an item will now correctly scroll the MarkdownWidget above.
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