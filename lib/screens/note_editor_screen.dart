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
  
  // This will hold the content of the last successful save.
  // It's our source of truth for checking if changes have been made.
  String _lastKnownSavedContent = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  /// This method is called by the TextField's `onChanged` callback.
  /// It debounces the input to trigger an auto-save.
  void _onNoteTextChanged(String currentText) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), _autoSaveNote);
    
    if (!_isSaving) {
      setState(() {
        _lastSavedStatus = "Unsaved changes...";
      });
    }
  }

  /// This is for the debounced auto-save. It checks for changes before saving.
  Future<void> _autoSaveNote() async {
    // Only auto-save if the content has actually changed.
    if (_controller.text != _lastKnownSavedContent) {
      await _performSave();
    }
  }

  /// This is the core save logic, callable from multiple places.
  Future<void> _performSave() async {
    if (_isSaving) return;
    
    if (mounted) setState(() => _isSaving = true);
    
    final textToSave = _controller.text;
    
    try {
      final service = ref.read(localStorageServiceProvider);
      await service.writeNoteToFile(widget.notePath, textToSave);
      
      // After a successful save, update our source of truth.
      _lastKnownSavedContent = textToSave;
      
      // Invalidate providers so other screens get the fresh data.
      ref.invalidate(appProvider);
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
    // The dispose method is now clean and synchronous.
    // It only cleans up controllers and timers.
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// This is the clean "save-on-exit" handler, called by WillPopScope.
  Future<bool> _onWillPop() async {
    // Cancel any pending auto-save since we are doing a final save now.
    _debounce?.cancel();
    
    // Only perform the final save if there are unsaved changes.
    if (_controller.text != _lastKnownSavedContent) {
       await _performSave();
    }
    
    // Return true to allow the screen to be popped by the navigator.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the initial content for the note.
    final asyncContent = ref.watch(rawNoteContentProvider(widget.notePath));
    
    // Wrap the entire Scaffold in WillPopScope to intercept back navigation.
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
                  // This flag ensures we only populate the controller once.
                  if (!_isContentLoaded) {
                    _controller.text = initialContent;
                    _lastKnownSavedContent = initialContent; // Store the initial state
                    _isContentLoaded = true;
                    // Update the UI status after the first build frame.
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
            // Status bar at the bottom for user feedback.
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