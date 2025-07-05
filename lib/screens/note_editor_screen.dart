// C:\dev\memoir\lib\screens\note_editor_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/widgets/tag_editor.dart';

final noteProvider = FutureProvider.family<Note, String>((ref, path) {
  final appState = ref.watch(appProvider);
  final persons = appState.persons;
  for (final person in persons) {
    if (person.info.path == path) {
      return person.info;
    }
    try {
      return person.notes.firstWhere((n) => n.path == path);
    } catch (e) {/* Not in this person, continue searching */}
  }
  throw Exception("Note with path $path not found in the vault.");
});

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String notePath;

  const NoteEditorScreen({super.key, required this.notePath});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  Timer? _debounce;
  bool _isSaving = false;
  String _lastSavedStatus = "Loading...";

  String _initialTitle = '';
  late List<String> _currentTags;
  String _initialBody = '';
  late List<String> _initialTags;

  bool _isContentLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _currentTags = [];
    _initialTags = [];
  }

  bool get _hasUnsavedChanges {
    if (!_isContentLoaded) return false;
    final titleChanged = _titleController.text != _initialTitle;
    final tagsChanged = !listEquals(_currentTags, _initialTags);
    final bodyChanged = _bodyController.text != _initialBody;
    return titleChanged || tagsChanged || bodyChanged;
  }

  void _onNoteContentChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (!_isSaving && _hasUnsavedChanges) {
      setState(() {
        _lastSavedStatus = "Unsaved changes...";
      });
    }
    _debounce = Timer(const Duration(seconds: 2), _autoSaveNote);
  }

  Future<void> _autoSaveNote() async {
    if (_hasUnsavedChanges) {
      await _performSave();
    }
  }

  Future<void> _performSave() async {
    if (_isSaving || !_isContentLoaded) return;

    if (mounted) setState(() => _isSaving = true);
    
    final originalNoteAsync = ref.read(noteProvider(widget.notePath));
    originalNoteAsync.whenData((originalNote) async {
      try {
        final service = ref.read(localStorageServiceProvider);

        final updatedNote = Note(
          path: originalNote.path,
          title: _titleController.text.trim(),
          creationDate: originalNote.creationDate,
          lastModified: DateTime.now(),
          tags: _currentTags,
        );

        await service.writeNote(
          path: widget.notePath, 
          note: updatedNote, 
          markdownBody: _bodyController.text
        );
        
        _initialTitle = _titleController.text.trim();
        _initialBody = _bodyController.text;
        _initialTags = List<String>.from(_currentTags);

        await ref.read(appProvider.notifier).updateNote(widget.notePath);
        
        ref.refresh(rawNoteContentProvider(widget.notePath));
        ref.refresh(noteProvider(widget.notePath));
        
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
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _debounce?.cancel();
    if (_hasUnsavedChanges) {
       await _performSave();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final asyncNote = ref.watch(noteProvider(widget.notePath));
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Editor"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: _isSaving ? const LinearProgressIndicator() : const SizedBox.shrink(),
          ),
        ),
        body: asyncNote.when(
          data: (note) {
            final asyncRawContent = ref.watch(rawNoteContentProvider(widget.notePath));
            return asyncRawContent.when(
              data: (rawContent) {
                if (!_isContentLoaded) {
                  _titleController.text = note.title;
                  _initialTitle = note.title;

                  _currentTags = List<String>.from(note.tags);
                  _initialTags = List<String>.from(note.tags);

                  final body = rawContent.startsWith('---') 
                    ? rawContent.split('---').sublist(2).join('---').trim() 
                    : rawContent;
                  _bodyController.text = body;
                  _initialBody = body;
                  _isContentLoaded = true;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _lastSavedStatus = "All changes saved");
                  });
                }
                
                // --- FIX: Wrap the Column in a LayoutBuilder and SingleChildScrollView ---
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight( // Ensures Column takes up necessary height
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: TextField(
                                  controller: _titleController,
                                  onChanged: (_) => _onNoteContentChanged(),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Note Title...',
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              TagEditor(
                                initialTags: _initialTags,
                                onTagsChanged: (newTags) {
                                  setState(() => _currentTags = newTags);
                                  _onNoteContentChanged();
                                }
                              ),
                              // Use Expanded to make the body take up the remaining space
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: TextField(
                                    controller: _bodyController,
                                    onChanged: (_) => _onNoteContentChanged(),
                                    expands: true,
                                    maxLines: null,
                                    minLines: null,
                                    keyboardType: TextInputType.multiline,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Start writing...',
                                    ),
                                  ),
                                ),
                              ),
                              // The status bar is now outside the scroll view, always visible
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      ),
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}