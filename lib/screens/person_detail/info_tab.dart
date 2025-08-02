// C:\dev\memoir\lib\screens\person_detail\info_tab.dart
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart' hide ImageViewer;
import 'package:memoir/models/note_model.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/graph_view_screen.dart';
import 'package:memoir/screens/note_editor_screen.dart';
import 'package:memoir/services/markdown_analyzer_service.dart';
import 'package:memoir/widgets/custom_float_button.dart';
import 'package:memoir/widgets/custom_markdown_elements.dart';
import 'package:memoir/widgets/image_viewer.dart';
import 'package:path/path.dart' as p;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

class InfoTab extends ConsumerStatefulWidget {
  final Person person;
  const InfoTab({super.key, required this.person});

  @override
  ConsumerState<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<InfoTab> {
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

    if (confirmed != true || !mounted) return;

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

  void _showImage(BuildContext context, Widget child) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => ImageViewer(child: child),
    ));
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

  @override
  Widget build(BuildContext context) {
    final infoNote = widget.person.info;
    final appState = ref.watch(appProvider);
    final vaultRoot = appState.storagePath;
    final isSignedIn = appState.isSignedIn;
    final cloudFilesAsync = ref.watch(allCloudFilesProvider);
    final metadataTextStyle = TextStyle(color: Colors.grey[700], fontSize: 12);
    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return Scaffold(
      body: Column(
        children: [
          // Custom Header with Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Created: ${formatter.format(infoNote.creationDate.toLocal())}', style: metadataTextStyle),
                      Text('Modified: ${formatter.format(infoNote.lastModified.toLocal())}', style: metadataTextStyle),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.hub_outlined, size: 20),
                  label: const Text('Graph'),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => GraphViewScreen(rootNotePath: infoNote.path),
                    ));
                  },
                ),
                const SizedBox(width: 8),
                if (_isSyncing)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                else if (isSignedIn)
                  cloudFilesAsync.when(
                    data: (cloudFiles) {
                      final normalizedLocalPath = infoNote.path.replaceAll(r'\', '/');
                      final isSynced = cloudFiles.any((cf) => (cf.cloudPath?.endsWith(normalizedLocalPath) ?? false) && !cf.isFolder);
                      return IconButton(
                        icon: Icon(isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined, color: isSynced ? Colors.green : null),
                        tooltip: isSynced ? 'Unsync from Cloud' : 'Upload to Cloud',
                        onPressed: () {
                          if (isSynced) {
                            _handleUnsync(infoNote);
                          } else if (vaultRoot != null) {
                            _handleUpload(infoNote, vaultRoot);
                          }
                        },
                      );
                    },
                    loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    error: (e, s) => IconButton(icon: const Icon(Icons.error_outline, color: Colors.orange), onPressed: () => ref.invalidate(allCloudFilesProvider)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Info',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NoteEditorScreen(notePath: infoNote.path)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Markdown Content
          Expanded(
            child: Consumer(
                builder: (context, ref, child) {
                  final asyncContent = ref.watch(rawNoteContentProvider(infoNote.path));

                  return asyncContent.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error loading note: $err')),
                      data: (content) {
                        final markdownBuildContext = MarkdownBuildContext(context, ref);
                        final generator = MarkdownGenerator(
                          inlineSyntaxList: [ MentionSyntax(), LocationSyntax(), EventSyntax() ],
                          generators: [ mentionGenerator(markdownBuildContext), locationGenerator(markdownBuildContext), eventGenerator(markdownBuildContext) ],
                        );
                        final imgConfig = ImgConfig(builder: _imageBuilder);
                        final markdownConfig = MarkdownConfig.defaultConfig.copy(
                          configs: [
                            imgConfig,
                            const PConfig(textStyle: TextStyle(fontSize: 16, height: 1.5, color: Colors.black)),
                          ],
                        );
                        final mainContent = content.startsWith('---') ? content.split('---').sublist(2).join('---').trim() : content;

                        final markdownWidgets = generator.buildWidgets(
                            mainContent,
                            config: markdownConfig,
                            onTocList: (tocList) {
                              // Post-frame callback to avoid setState during build
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  tocController.setTocList(tocList);
                                }
                              });
                            }
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
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                                          if (indexTreeSet.isNotEmpty && mounted) {
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
                      }
                  );
                }
            ),
          ),
        ],
      ),
      floatingActionButton: CustomFloatButton(
        icon: Icons.format_list_bulleted,
        tooltip: 'Table of Contents',
        onTap: () {
          showModalBottomSheet(
            context: context,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (context) => TocWidget(controller: tocController),
          );
        },
      ),
    );
  }
}