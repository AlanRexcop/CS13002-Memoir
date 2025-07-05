// C:\dev\memoir\lib\widgets\note_metadata_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';

class NoteMetadataCard extends StatelessWidget {
  final Note note;

  const NoteMetadataCard({super.key, required this.note});
  
  // Helper to build a consistent row for each metadata item
  Widget _buildMetadataRow(BuildContext context, {required IconData icon, required String label, required Widget value}) {
    final labelStyle = TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.0, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100, // Fixed width for alignment
            child: Text(label, style: labelStyle),
          ),
          const SizedBox(width: 12),
          Expanded(child: value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(16).copyWith(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show the Tags row if there are any tags
            if (note.tags.isNotEmpty)
              _buildMetadataRow(
                context,
                icon: Icons.label_outline,
                label: 'Tags',
                value: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: note.tags.map((tag) => Chip(
                    label: Text(tag),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),
            
            // Creation Date
            _buildMetadataRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Created',
              value: Text(
                DateFormat.yMMMd().add_jm().format(note.creationDate.toLocal()),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            
            // Last Modified Date
             _buildMetadataRow(
              context,
              icon: Icons.edit_calendar_outlined,
              label: 'Modified',
              value: Text(
                DateFormat.yMMMd().add_jm().format(note.lastModified.toLocal()),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}