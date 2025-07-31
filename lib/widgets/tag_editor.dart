// C:\dev\memoir\lib\widgets\tag_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/widgets/tag.dart';

// NEW: An enum to define the widget's behavior and appearance.
enum TagInputPurpose { edit, filter }

class TagEditor extends ConsumerStatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;
  // NEW: Add the purpose parameter, defaulting to 'edit' for backward compatibility.
  final TagInputPurpose purpose;

  const TagEditor({
    super.key,
    required this.initialTags,
    required this.onTagsChanged,
    this.purpose = TagInputPurpose.edit,
  });

  @override
  ConsumerState<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<TagEditor> {
  late List<String> _tags;
  TextEditingController? _autocompleteController;

  @override
  void initState() {
    super.initState();
    // Use a copy of the tags so we can modify it.
    _tags = List<String>.from(widget.initialTags);
  }

  // NEW: This ensures that if the initialTags from the parent widget change,
  // our local state updates to reflect it. This is crucial for filtering.
  @override
  void didUpdateWidget(covariant TagEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTags != oldWidget.initialTags) {
      setState(() {
        _tags = List<String>.from(widget.initialTags);
      });
    }
  }

  void _addTag(String tag) {
    tag = tag.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      widget.onTagsChanged(_tags);
    }
  }

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.remove(tagToRemove);
    });
    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final allPersons = ref.watch(appProvider).persons;
    final uniqueTags = <String>{};
    for (final person in allPersons) {
      for (final note in [person.info, ...person.notes]) {
        uniqueTags.addAll(note.tags);
      }
    }
    final allAvailableTags = uniqueTags.toList()..sort();

    final isEditMode = widget.purpose == TagInputPurpose.edit;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isEditMode ? 12.0 : 0.0,
        vertical: 0.0,
      ),
      decoration: isEditMode
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // if (isEditMode) ...[
          //   const Icon(Icons.label_outline, size: 20),
          //   const SizedBox(width: 8),
          //   const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
          //   const SizedBox(width: 16),
          // ],
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // ..._tags.map((tag) => Chip(
                //       label: Text(tag),
                //       labelPadding: const EdgeInsets.only(left: 8.0),
                //       deleteIcon: const Icon(Icons.close, size: 14),
                //       onDeleted: () => _removeTag(tag),
                //       visualDensity: VisualDensity.compact,
                //     )),
                ..._tags.map((tag) => Tag(
                  label: tag,
                  onDeleted: () => _removeTag(tag),
                )),
                SizedBox(
                  width: 150,
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.toLowerCase();
                      // if (query.isEmpty) {
                      //   return allAvailableTags.where((tag) => !_tags.contains(tag));
                      // }
                      if (query.isEmpty) {
                        return const <String>[];
                      }
                      return allAvailableTags.where((tag) {
                        final isAlreadyAdded = _tags.contains(tag);
                        final matchesQuery = tag.toLowerCase().contains(query);
                        return !isAlreadyAdded && matchesQuery;
                      });
                    },
                    onSelected: (String selection) {
                      _addTag(selection);
                      _autocompleteController?.clear();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      _autocompleteController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                          border: InputBorder.none,
                          hintText: isEditMode ? 'Add a tag...' : 'Filter by tag...',
                        ),
                        onSubmitted: (String value) {
                          onFieldSubmitted();
                          _addTag(value);
                          controller.clear();
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return _ScrollableOptionsView(
                        options: options,
                        onSelected: onSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollableOptionsView extends StatefulWidget {
  final Iterable<String> options;
  final AutocompleteOnSelected<String> onSelected;

  const _ScrollableOptionsView({
    required this.options,
    required this.onSelected,
  });

  @override
  State<_ScrollableOptionsView> createState() => _ScrollableOptionsViewState();
}

class _ScrollableOptionsViewState extends State<_ScrollableOptionsView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 8.0,
            radius: const Radius.circular(4.0),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.options.length,
              itemBuilder: (BuildContext context, int index) {
                final String option = widget.options.elementAt(index);
                return InkWell(
                  onTap: () {
                    widget.onSelected(option);
                  },
                  child: ListTile(
                    title: Text(option),
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}