// lib/widgets/note_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/widgets/tag.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isInfoNote;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelection;

  const NoteCard({
    super.key,
    required this.note,
    this.isInfoNote = false,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelection,
  });

  String _formatTagName(String tag) {
    const int maxLength = 10;
    const int charsToKeep = 5;

    if (tag.length > maxLength) {
      return '${tag.substring(0, charsToKeep)}...';
    }
    return tag;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const int maxTagsToShow = 4;
    final sortedTags = note.tags.toList()..sort();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: isSelected
          ? colorScheme.outline
          : note.title.trim().isEmpty
            ? const Color(0x80F3E8F5)
            : colorScheme.secondary,
      elevation: isSelected ? 5 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(25),
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(5),
        ),
        side: BorderSide(color: note.title.trim().isEmpty ? Colors.transparent :colorScheme.outline, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListTile(
          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('yyyy-MM-dd').format(note.lastModified.toLocal()),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (sortedTags.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...(sortedTags.length > maxTagsToShow
                          ? sortedTags.sublist(0, maxTagsToShow)
                          : sortedTags)
                          .map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Tag(label: _formatTagName(tag)),
                      ))
                          .toList(),
                      if (sortedTags.length > maxTagsToShow)
                        Tag(label: '+${sortedTags.length - maxTagsToShow}'),
                    ],
                  ),
                ),
            ],
          ),
          trailing: isSelectionMode && !isInfoNote
              ? Checkbox(
            value: isSelected,
            onChanged: (bool? value) => onToggleSelection(),
            activeColor: colorScheme.primary,
            checkColor: Colors.white,
            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.primary;
              }
              return Colors.grey.shade300;
            }),
            side: WidgetStateBorderSide.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(width: 2, color: colorScheme.primary);
              }
              return BorderSide(width: 2, color: Colors.grey.shade300);
            }),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const CircleBorder(),
          )
              : (isInfoNote ? const Chip(label: Text('Info'), visualDensity: VisualDensity.compact) : null),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}