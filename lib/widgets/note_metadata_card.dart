import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/widgets/tag.dart';

import '../screens/graph_view_screen.dart';

class NoteMetadataCard extends StatelessWidget {
  final Note note;

  const NoteMetadataCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final metadataTextStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 14,
    );

    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: GoogleFonts.inter(
                    fontSize: 25,
                    color: Colors.black,
                    fontWeight: FontWeight.w500
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                  onPressed: () => {},
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)
                ),
                  child: Text('Publish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              )
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: note.tags.map((tag) {
                    return Tag(label: tag);
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created: ${formatter.format(note.creationDate.toLocal())}',
                    style: metadataTextStyle,
                  ),
                  Text(
                    'Modified: ${formatter.format(note.lastModified.toLocal())}',
                    style: metadataTextStyle,
                  ),
                ],
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GraphViewScreen(rootNotePath: note.path),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Icon(Icons.hub_outlined, size: 20),
                    const SizedBox(width: 4),
                    const Text(
                      'Graph',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.chevron_right, size: 22),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 1,
            thickness: 1,
          )
        ],
      ),
    );
  }
}