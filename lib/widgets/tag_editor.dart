// C:\dev\memoir\lib\widgets\tag_editor.dart
import 'package:flutter/material.dart';

class TagEditor extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagEditor({
    super.key,
    required this.initialTags,
    required this.onTagsChanged,
  });

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  late final List<String> _tags;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the initial tags
    _tags = List<String>.from(widget.initialTags);
  }

  void _addTag(String tag) {
    tag = tag.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      widget.onTagsChanged(_tags); // Notify parent widget
      _textController.clear();
    }
    // Always request focus back to the input field
    _focusNode.requestFocus();
  }

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.remove(tagToRemove);
    });
    widget.onTagsChanged(_tags); // Notify parent widget
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.label_outline, size: 20),
            const SizedBox(width: 8),
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ..._tags.map((tag) => Chip(
                        label: Text(tag),
                        labelPadding: const EdgeInsets.only(left: 8.0),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeTag(tag),
                        visualDensity: VisualDensity.compact,
                      )),
                  // The TextField is part of the Wrap so it flows correctly
                  SizedBox(
                    width: 150, // Give it a reasonable width
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                        border: InputBorder.none,
                        hintText: 'Add a tag...',
                      ),
                      onSubmitted: _addTag,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}