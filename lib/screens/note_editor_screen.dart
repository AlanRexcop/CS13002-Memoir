// C:\dev\memoir\lib\screens\note_editor_screen.dart
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
  String _lastSavedStatus = "Loading...";
  bool _isContentLoaded = false;
  
  String _lastKnownSavedContent = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void _onNoteTextChanged(String currentText) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), _autoSaveNote);
    
    if (!_isSaving) {
      setState(() {
        _lastSavedStatus = "Unsaved changes...";
      });
    }
  }

  Future<void> _autoSaveNote() async {
    if (_controller.text != _lastKnownSavedContent) {
      await _performSave();
    }
  }

  Future<void> _performSave() async {
    if (_isSaving) return;
    
    if (mounted) setState(() => _isSaving = true);
    
    final textToSave = _controller.text;
    
    try {
      final service = ref.read(localStorageServiceProvider);
      await service.writeNoteToFile(widget.notePath, textToSave);
      
      _lastKnownSavedContent = textToSave;
      
      // --- OPTIMIZATION ---
      // Instead of invalidating the whole app, we now call the targeted update method.
      // This is much more performant.
      await ref.read(appProvider.notifier).updateNote(widget.notePath);
      
      // We still invalidate the raw content provider so this screen and the
      // view screen will get the fresh text content if they need it.
      ref.invalidate(rawNoteContentProvider(widget.notePath));
      
      if (mounted) {
        setState(() => _lastSavedStatus = "All changes saved");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastSavedStatus = "Error: Could not save.");
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _debounce?.cancel();
    
    if (_controller.text != _lastKnownSavedContent) {
       await _performSave();
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final asyncContent = ref.watch(rawNoteContentProvider(widget.notePath));
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Editing Note"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: _isSaving ? const LinearProgressIndicator() : const SizedBox.shrink(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: asyncContent.when(
                data: (initialContent) {
                  if (!_isContentLoaded) {
                    _controller.text = initialContent;
                    _lastKnownSavedContent = initialContent;
                    _isContentLoaded = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _lastSavedStatus = "All changes saved");
                    });
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onNoteTextChanged,
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
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Theme.of(context).bottomAppBarTheme.color,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_lastSavedStatus, style: Theme.of(context).textTheme.bodySmall)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}