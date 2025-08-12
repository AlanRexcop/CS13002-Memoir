// lib/widgets/note_metadata_card.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/widgets/tag.dart';

import '../screens/graph_view_screen.dart';

class NoteMetadataCard extends ConsumerStatefulWidget {
  final Note note;

  const NoteMetadataCard({super.key, required this.note});

  @override
  ConsumerState<NoteMetadataCard> createState() => _NoteMetadataCardState();
}

class _NoteMetadataCardState extends ConsumerState<NoteMetadataCard> {
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final metadataTextStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 14,
    );
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final cloudFilesAsync = ref.watch(allCloudFilesProvider);

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
                  widget.note.title,
                  style: GoogleFonts.inter(
                      fontSize: 25,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 10),
              if (_isPublishing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                )
              else
                cloudFilesAsync.when(
                  data: (cloudFiles) {
                    final normalizedPath = widget.note.path.replaceAll(r'\', '/');
                    final cloudFile = cloudFiles.firstWhereOrNull((cf) => cf.cloudPath?.endsWith(normalizedPath) ?? false);

                    // If the file isn't synced to the cloud, don't show a button.
                    if (cloudFile == null) {
                      return const SizedBox.shrink();
                    }

                    final isPublic = cloudFile.isPublic;
                    return OutlinedButton(
                      onPressed: () async {
                        setState(() => _isPublishing = true);
                        final notifier = ref.read(cloudNotifierProvider.notifier);
                        
                        // Call the appropriate method based on the current public status
                        final success = isPublic
                            ? await notifier.makeFilePrivate(cloudFile)
                            : await notifier.makeNotePublic(widget.note, cloudFile);

                        if (mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Visibility updated successfully.' : 'Failed to update visibility.'),
                                backgroundColor: success ? Colors.blue : Colors.red,
                              ),
                            );
                          setState(() => _isPublishing = false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        // Change color based on public status for better feedback
                        side: BorderSide(color: isPublic ? Colors.grey : Theme.of(context).colorScheme.primary),
                      ),
                      child: Text(
                        isPublic ? 'Unpublish' : 'Publish',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPublic ? Colors.grey[700] : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(), // Don't show anything while loading file list
                  error: (e, s) => const SizedBox.shrink(), // Or if there's an error
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.note.tags.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: widget.note.tags.map((tag) {
                      return Tag(label: tag);
                    }).toList(),
                  ),
                ),
              ],
            ),
          if (widget.note.tags.isNotEmpty) const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created: ${formatter.format(widget.note.creationDate.toLocal())}',
                    style: metadataTextStyle,
                  ),
                  Text(
                    'Modified: ${formatter.format(widget.note.lastModified.toLocal())}',
                    style: metadataTextStyle,
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GraphViewScreen(rootNotePath: widget.note.path),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hub_outlined, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Graph',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.chevron_right, size: 22),
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