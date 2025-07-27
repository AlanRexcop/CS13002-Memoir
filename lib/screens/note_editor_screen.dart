// C:\dev\memoir\lib\screens\note_editor_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/event_creation_screen.dart';
import 'package:memoir/screens/image_gallery_screen.dart';
import 'package:memoir/screens/map_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/markdown_toolbar.dart';
import 'package:memoir/widgets/tag_editor.dart';
import 'package:path/path.dart' as p;

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
  late final FocusNode _bodyFocusNode;
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
    _bodyFocusNode = FocusNode();
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

  void _wrapSelectionWithSyntax({required String prefix, String suffix = ''}) {
    _bodyFocusNode.requestFocus();
    final currentText = _bodyController.text;
    final selection = _bodyController.selection;
    
    if (selection.isCollapsed) {
      final newText = currentText.substring(0, selection.start) +
                    prefix +
                    suffix +
                    currentText.substring(selection.end);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + prefix.length),
      );
    } else {
      final selectedText = currentText.substring(selection.start, selection.end);
      final newText = currentText.substring(0, selection.start) +
                    prefix +
                    selectedText +
                    suffix +
                    currentText.substring(selection.end);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.fromPosition(TextPosition(offset: selection.start + prefix.length + selectedText.length + suffix.length)),
      );
    }
    _onNoteContentChanged();
  }
  
  void _insertBlockSyntax(String block) {
    _bodyFocusNode.requestFocus();
    final currentText = _bodyController.text;
    final selection = _bodyController.selection;
    
    final prefix = (selection.start == 0 || currentText.isEmpty || currentText[selection.start - 1] == '\n') ? '' : '\n\n';
    final suffix = '\n';
    final textToInsert = prefix + block + suffix;

    final newText = currentText.replaceRange(selection.start, selection.end, textToInsert);
    
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + textToInsert.length),
    );
    _onNoteContentChanged();
  }

  void _prefixSelectionWithSyntax(String prefix) {
    _bodyFocusNode.requestFocus();
    final currentText = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.isCollapsed) {
        final needsNewline = selection.start > 0 && currentText[selection.start - 1] != '\n';
        final textToInsert = (needsNewline ? '\n' : '') + prefix;
        final newText = currentText.substring(0, selection.start) + textToInsert + currentText.substring(selection.end);
        _bodyController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: selection.start + textToInsert.length),
        );
    } else {
        final selectedText = currentText.substring(selection.start, selection.end);
        final lines = selectedText.split('\n');
        final prefixedLines = lines.map((line) => line.isEmpty ? '' : prefix + line).join('\n');
        
        final newText = currentText.substring(0, selection.start) + prefixedLines + currentText.substring(selection.end);
        _bodyController.value = TextEditingValue(
            text: newText,
            selection: TextSelection(baseOffset: selection.start, extentOffset: selection.start + prefixedLines.length),
        );
    }
    _onNoteContentChanged();
  }

  void _onImageSelectedForInsertion(String relativePath) {
    final altText = p.basenameWithoutExtension(relativePath);
    final encodedPath = Uri.encodeFull(relativePath.replaceAll(r'\', '/'));
    final textToInsert = '![$altText]($encodedPath)';
    _insertBlockSyntax(textToInsert);
  }

  Future<void> _showLinkDialog() async {
      _bodyFocusNode.requestFocus();
      final selection = _bodyController.selection;
      final selectedText = selection.isCollapsed ? '' : _bodyController.text.substring(selection.start, selection.end);

      final urlController = TextEditingController();
      final url = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('Insert Link'),
              content: TextField(
                  controller: urlController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'URL'),
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.of(context).pop(urlController.text),
                      child: const Text('Insert'),
                  ),
              ],
          ),
      );

      if (url != null && url.isNotEmpty) {
          final linkText = selectedText.isEmpty ? 'link text' : selectedText;
          final textToInsert = '[$linkText]($url)';
          
          final newText = _bodyController.text.replaceRange(selection.start, selection.end, textToInsert);
          _bodyController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: selection.start + textToInsert.length),
          );
          _onNoteContentChanged();
      }
  }

  Future<void> _showMentionFlow() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => const PersonListScreen(purpose: ScreenPurpose.select),
      ),
    );

    if (result != null && result['text'] != null && result['path'] != null) {
      final displayText = result['text']!;
      final notePath = result['path']!.replaceAll(r'\', '/');
      final textToInsert = ' {mention}[$displayText]($notePath) ';
      _wrapSelectionWithSyntax(prefix: textToInsert);
    }
  }

  void _showImageGalleryForSelection() async {
    final relativePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ImageGalleryScreen(purpose: ScreenPurpose.select),
      ),
    );

    if (relativePath != null && relativePath.isNotEmpty) {
      _onImageSelectedForInsertion(relativePath);
    }
  }

  void _showLocationSelection() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const MapScreen(purpose: ScreenPurpose.select)),
    );

    if (result != null) {
      final text = result['text'];
      final lat = result['lat'];
      final lng = result['lng'];
      final textToInsert = ' {location}[$text]($lat,$lng) ';
      _wrapSelectionWithSyntax(prefix: textToInsert);
    }
  }

  Future<void> _showEventCreationFlow() async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Event'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Event Description'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(titleController.text.trim()),
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty && mounted) {
      final markdownToInsert = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => EventCreationScreen(eventTitle: title),
        ),
      );
      if (markdownToInsert != null && markdownToInsert.isNotEmpty) {
        _wrapSelectionWithSyntax(prefix: markdownToInsert);
      }
    }
  }

  Future<void> _autoSaveNote() async {
    if (_hasUnsavedChanges) {
      await _performSave();
    }
  }

  Future<void> _performSave() async {
    if (_isSaving || !_isContentLoaded) return;

    final vaultRoot = ref.read(appProvider).storagePath;
    if (vaultRoot == null) {
      if (mounted) setState(() => _lastSavedStatus = "Error: Storage path not found.");
      return;
    }

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

        final absolutePath = p.join(vaultRoot, widget.notePath);
        await service.writeNote(
          path: absolutePath, 
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
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _debounce?.cancel();
    if (_hasUnsavedChanges) {
       await _performSave();
    }
    return true;
  }

  void _handleMarkdownAction(MarkdownAction action) {
    const tableTemplate = '| Header 1 | Header 2 |\n'
                        '| :--- | :--- |\n'
                        '| Cell 1   | Cell 2   |\n'
                        '| Cell 3   | Cell 4   |';
    
    switch (action) {
      case MarkdownAction.bold:
        _wrapSelectionWithSyntax(prefix: '**', suffix: '**');
        break;
      case MarkdownAction.italic:
        _wrapSelectionWithSyntax(prefix: '*', suffix: '*');
        break;
      case MarkdownAction.strikethrough:
        _wrapSelectionWithSyntax(prefix: '~~', suffix: '~~');
        break;
      case MarkdownAction.inlineCode:
        _wrapSelectionWithSyntax(prefix: '`', suffix: '`');
        break;
      case MarkdownAction.codeBlock:
        _wrapSelectionWithSyntax(prefix: '\n```\n', suffix: '\n```');
        break;
      case MarkdownAction.h1:
        _prefixSelectionWithSyntax('# ');
        break;
      case MarkdownAction.h2:
        _prefixSelectionWithSyntax('## ');
        break;
      case MarkdownAction.h3:
        _prefixSelectionWithSyntax('### ');
        break;
      case MarkdownAction.ul:
        _prefixSelectionWithSyntax('- ');
        break;
      case MarkdownAction.ol:
        _prefixSelectionWithSyntax('1. ');
        break;
      case MarkdownAction.checkbox:
        _prefixSelectionWithSyntax('- [ ] ');
        break;
      case MarkdownAction.quote:
        _prefixSelectionWithSyntax('> ');
        break;
      case MarkdownAction.link:
        _showLinkDialog();
        break;
      case MarkdownAction.image:
        _showImageGalleryForSelection();
        break;
      case MarkdownAction.hr:
        _insertBlockSyntax('---');
        break;
      case MarkdownAction.table:
        _insertBlockSyntax(tableTemplate);
        break;
      case MarkdownAction.mention:
        _showMentionFlow();
        break;
      case MarkdownAction.location:
        _showLocationSelection();
        break;
      case MarkdownAction.event:
        _showEventCreationFlow();
        break;
    }
  }

  void _showAddContentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return MarkdownToolbar(onAction: _handleMarkdownAction);
      },
    );
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
                    if (mounted) {
                      setState(() => _lastSavedStatus = "All changes saved");
                      _bodyFocusNode.requestFocus();
                    }
                  });
                }
                
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: TextField(
                                    focusNode: _bodyFocusNode,
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
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add content',
          child: const Icon(Icons.add),
          onPressed: () => _showAddContentMenu(context),
        ),
      ),
    );
  }
}