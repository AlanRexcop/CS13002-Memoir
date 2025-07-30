// C:\dev\memoir\lib\screens\note_view_screen.dart
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/graph_view_screen.dart';
import 'package:memoir/screens/note_editor_screen.dart';
import 'package:memoir/services/markdown_analyzer_service.dart';
import 'package:memoir/widgets/custom_float_button.dart';
import 'package:memoir/widgets/custom_markdown_elements.dart';
import 'package:memoir/widgets/note_metadata_card.dart';
import 'package:path/path.dart' as p;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NoteViewScreen extends ConsumerStatefulWidget {
  final Note note;

  const NoteViewScreen({super.key, required this.note});

  @override
  ConsumerState<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends ConsumerState<NoteViewScreen> {
  final TocController tocController = TocController();
  final AutoScrollController scrollController = AutoScrollController();
  
  final indexTreeSet = SplayTreeSet<int>((a, b) => a - b);
  bool isForward = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    tocController.jumpToIndexCallback = (index) {
      scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
    };
  }

  @override
  void dispose() {
    tocController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleUnsync(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unsync'),
        content: Text('Are you sure you want to remove "${note.title}" from the cloud? The local file will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unsync', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);
    final success = await ref.read(cloudNotifierProvider.notifier).deleteFileByRelativePath(note.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Successfully unsynced from cloud.' : 'Failed to unsync.'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleUpload(Note note, String vaultRoot) async {
     setState(() => _isSyncing = true);
     final success = await ref.read(cloudNotifierProvider.notifier).uploadNote(note, vaultRoot);
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Note synced to cloud.' : 'Upload failed.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      setState(() => _isSyncing = false);
    }
  }


  Widget _imageBuilder(String url, Map<String, String> attributes) {
    final vaultPath = ref.read(appProvider).storagePath;

    if (vaultPath != null && !url.startsWith('http')) {
      try {
        final decodedUrl = Uri.decodeFull(url);
        final file = File(p.join(vaultPath, decodedUrl));
        
        if (file.existsSync()) {
          final imageWidget = Image.file(file);
          
          return Center(
            child: InkWell(
              onTap: () => _showImage(context, imageWidget),
              child: Hero(
                tag: imageWidget.hashCode,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: imageWidget,
                ),
              ),
            ),
          );
        }
      } catch (e) {
        print("Error loading local image: $e");
      }
    }
    
    if (url.startsWith('http')) {
      final imageWidget = Image.network(url);

      return Center(
        child: InkWell(
          onTap: () => _showImage(context, imageWidget),
          child: Hero(
            tag: imageWidget.hashCode,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: imageWidget,
            ),
          ),
        ),
      );
    }
    
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  void _showImage(BuildContext context, Widget child) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => ImageViewer(child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final latestNote = ref.watch(appProvider.select((state) {
      for (final person in state.persons) {
        if (person.info.path == widget.note.path) return person.info;
        try {
          return person.notes.firstWhere((n) => n.path == widget.note.path);
        } catch (e) { }
      }
      return widget.note; 
    }));

    final appState = ref.watch(appProvider);
    final vaultRoot = appState.storagePath;
    final isSignedIn = appState.isSignedIn;
    final cloudFilesAsync = ref.watch(allCloudFilesProvider);


    return Scaffold(
      appBar: AppBar(
        title: Text(latestNote.title),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
            )
          else if (!isSignedIn)
            IconButton(
              icon: const Icon(Icons.cloud_off_outlined),
              tooltip: 'Offline: Sign in to sync',
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign in via the Settings screen to enable cloud sync.')),
                  );
              },
            )
          else
            cloudFilesAsync.when(
              data: (cloudFiles) {
                final normalizedLocalPath = latestNote.path.replaceAll(r'\', '/');
                final isSynced = cloudFiles.any((cf) => cf.cloudPath?.endsWith(normalizedLocalPath) ?? false);
                
                if (isSynced) {
                  return IconButton(
                    icon: const Icon(Icons.cloud_done_outlined, color: Colors.greenAccent),
                    tooltip: 'Note is Synced. Click to unsync.',
                    onPressed: () => _handleUnsync(latestNote),
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    tooltip: 'Upload to Cloud',
                    onPressed: () {
                      if (vaultRoot != null) {
                        _handleUpload(latestNote, vaultRoot);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error: Local vault path not found.')),
                        );
                      }
                    },
                  );
                }
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
              ),
              error: (err, stack) => IconButton(
                icon: const Icon(Icons.error_outline, color: Colors.orange),
                tooltip: 'Error checking sync status. Tap to retry.',
                onPressed: () => ref.invalidate(allCloudFilesProvider),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'View Local Graph',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphViewScreen(rootNotePath: latestNote.path),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Note',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NoteEditorScreen(notePath: latestNote.path)),
              );
            },
          )
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final asyncContent = ref.watch(rawNoteContentProvider(latestNote.path));
          
          return asyncContent.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading note content:\n$err'),
              ),
            ),
            data: (content) {
              final markdownBuildContext = MarkdownBuildContext(context, ref);
              
              final generator = MarkdownGenerator(
                inlineSyntaxList: [ MentionSyntax(), LocationSyntax(), EventSyntax() ],
                generators: [ mentionGenerator(markdownBuildContext), locationGenerator(markdownBuildContext), eventGenerator(markdownBuildContext) ],
              );
              
              final imgConfig = ImgConfig(builder: _imageBuilder);
              final markdownConfig = MarkdownConfig.defaultConfig.copy(configs: [imgConfig]);
              
              final mainContent = content.startsWith('---') 
                ? content.split('---').sublist(2).join('---').trim() 
                : content;
              
              final markdownWidgets = generator.buildWidgets(
                mainContent,
                config: markdownConfig,
                onTocList: (tocList) => tocController.setTocList(tocList),
              );
              
              return NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  final ScrollDirection direction = notification.direction;
                  isForward = direction == ScrollDirection.forward;
                  return true;
                },
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                      sliver: SliverToBoxAdapter(child: NoteMetadataCard(note: latestNote)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return VisibilityDetector(
                              key: ValueKey(index.toString()),
                              onVisibilityChanged: (VisibilityInfo info) {
                                final visibleFraction = info.visibleFraction;
                                if (isForward) {
                                  visibleFraction == 0 ? indexTreeSet.remove(index) : indexTreeSet.add(index);
                                } else {
                                  visibleFraction == 1.0 ? indexTreeSet.add(index) : indexTreeSet.remove(index);
                                }
                                if (indexTreeSet.isNotEmpty) {
                                  tocController.onIndexChanged(indexTreeSet.first);
                                }
                              },
                              child: AutoScrollTag(
                                key: Key(index.toString()),
                                controller: scrollController,
                                index: index,
                                child: markdownWidgets[index],
                              ),
                            );
                          },
                          childCount: markdownWidgets.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: CustomFloatButton(
          icon: Icons.add,
          tooltip: 'Add note',
          onTap: () => {
          showModalBottomSheet(
                context: context,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                builder: (context) => TocWidget(controller: tocController),
              )
          },
      ),
    );
  }
}