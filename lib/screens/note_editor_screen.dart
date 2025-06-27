import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String notePath;

  const NoteEditorScreen({super.key, required this.notePath});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _isSaving = false;
  // A flag to prevent the controller from being overwritten by the provider on rebuilds
  bool _isContentLoaded = false; 

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), _saveNote);
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    if (mounted) setState(() => _isSaving = true);
    
    final service = ref.read(localStorageServiceProvider);
    await service.writeNoteToFile(widget.notePath, _controller.text);
    
    // Invalidate the main provider to force a refresh of all persons,
    // as the note's metadata might have changed. This is very important.
    ref.invalidate(appProvider);
    
    if(mounted) setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveNote(); // Final save on exit
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the new, correct provider.
    final asyncContent = ref.watch(rawNoteContentProvider(widget.notePath));
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Editing Note"),
        // Close button takes you back. The "back" button is implicit.
        // leading: IconButton(
        //   icon: Icon(Icons.close),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: _isSaving ? const LinearProgressIndicator() : const SizedBox.shrink(),
        ),
      ),
      body: asyncContent.when(
        data: (initialContent) {
          // Only set the controller's text ONCE when content is first loaded.
          if (!_isContentLoaded) {
            _controller.text = initialContent;
            _isContentLoaded = true;
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start writing...',
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}