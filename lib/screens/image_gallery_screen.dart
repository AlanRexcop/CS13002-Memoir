// C:\dev\memoir\lib\screens\image_gallery_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/widgets/image_viewer.dart';
import 'package:path/path.dart' as p;

class ImageGalleryScreen extends ConsumerStatefulWidget {
  final ScreenPurpose purpose;

  const ImageGalleryScreen({super.key, this.purpose = ScreenPurpose.view});

  @override
  ConsumerState<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends ConsumerState<ImageGalleryScreen> with SingleTickerProviderStateMixin {
  final List<String> _supportedExtensions = const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'avif', 'heic', 'heif'];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.refresh(vaultImagesProvider));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showImageViewer(BuildContext context, File imageFile) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => ImageViewer(heroTag: imageFile.path, child: Image.file(imageFile)),
    ));
  }

  Future<void> _deleteImage(File imageFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('Are you sure you want to permanently delete this image from your vault? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final vaultRoot = ref.read(appProvider).storagePath;
      if (vaultRoot == null) return;
      final relativePath = p.relative(imageFile.path, from: vaultRoot);
      final success = await ref.read(appProvider.notifier).deleteImage(relativePath);
      if (context.mounted) {
        if (success) {
          ref.refresh(vaultImagesProvider);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted.'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete image.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == ScreenPurpose.select ? 'Select Image' : 'Image Vault'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Vault Images'),
            Tab(icon: Icon(Icons.upload_file_outlined), text: 'Upload New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVaultImagesTab(),
          _buildUploadTab(),
        ],
      ),
    );
  }

  Widget _buildVaultImagesTab() {
    final asyncImages = ref.watch(vaultImagesProvider);
    final vaultRoot = ref.watch(appProvider.select((s) => s.storagePath));

    return asyncImages.when(
      data: (images) {
        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No images found in vault.'),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.refresh(vaultImagesProvider),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(vaultImagesProvider),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageFile = images[index];
              return GridTile(
                footer: widget.purpose == ScreenPurpose.view ? GridTileBar(
                  backgroundColor: Colors.black45,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'Delete Image',
                    onPressed: () => _deleteImage(imageFile),
                  ),
                ) : null,
                child: InkWell(
                  onTap: () {
                    if (widget.purpose == ScreenPurpose.select) {
                       if (vaultRoot != null) {
                          final relativePath = p.relative(imageFile.path, from: vaultRoot);
                          Navigator.of(context).pop(relativePath);
                       }
                    } else {
                      _showImageViewer(context, imageFile);
                    }
                  },
                  child: Hero(
                    tag: imageFile.path,
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildUploadTab() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Pick Image from Device'),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: _supportedExtensions,
          );

          if (result != null && result.files.single.path != null) {
            final file = File(result.files.single.path!);
            try {
              final newRelativePath = await ref.read(appProvider.notifier).saveImageToVault(file);
              ref.refresh(vaultImagesProvider);
              if (context.mounted) {
                if(widget.purpose == ScreenPurpose.select) {
                  Navigator.of(context).pop(newRelativePath);
                } else {
                  _tabController.animateTo(0);
                }
              }
            } catch (e) {
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save image: $e')),
                );
              }
            }
          }
        },
      ),
    );
  }
}