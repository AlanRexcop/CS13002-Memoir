// C:\dev\memoir\lib\widgets\search_input.dart
import 'package:flutter/material.dart';

// Use the same record type for consistency
typedef SearchQuery = ({String text, List<String> tags});

class SearchInput extends StatefulWidget {
  final ValueChanged<SearchQuery> onChanged;
  final String hintText;

  const SearchInput({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final _textController = TextEditingController();
  final List<String> _tags = [];
  String _liveText = '';

  void _onSubmitted(String value) {
    final term = value.trim();
    if (term.isEmpty) return;

    // Add the submitted term as a tag and clear the text field
    setState(() {
      if (!_tags.contains(term)) {
        _tags.add(term);
      }
      _liveText = '';
      _textController.clear();
    });
    _notifyParent();
  }

  void _onTextChanged(String value) {
    setState(() {
      _liveText = value;
    });
    _notifyParent();
  }
  
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _notifyParent();
  }

  void _notifyParent() {
    // The query now consists of the live text and the finalized tags
    widget.onChanged((text: _liveText.trim(), tags: _tags));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 4.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.search, size: 20, color: Colors.grey),
          
          // Display the search tags as chips
          ..._tags.map((tag) => Chip(
            label: Text(tag),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onDeleted: () => _removeTag(tag),
            visualDensity: VisualDensity.compact,
            deleteIcon: const Icon(Icons.close, size: 14),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          )),

          // The text input field
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150),
            child: IntrinsicWidth(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: _tags.isEmpty ? widget.hintText : 'add another...',
                ),
                onSubmitted: _onSubmitted,
                onChanged: _onTextChanged,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}