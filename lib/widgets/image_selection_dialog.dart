// C:\dev\memoir\lib\widgets\image_selection_dialog.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:path/path.dart' as p;

class ImageSelectionDialog extends ConsumerStatefulWidget {
  final void Function(String relativePath) onImageSelected;

  const ImageSelectionDialog({super.key, required this.onImageSelected});

  @override
  ConsumerState<ImageSelectionDialog> createState() => _ImageSelectionDialogState();
}

class _ImageSelectionDialogState extends ConsumerState<ImageSelectionDialog> {
  final List<String> _supportedExtensions = const [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'avif', 'heic', 'heif'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.refresh(vaultImagesProvider));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Image'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.photo_library_outlined), text: 'From Vault'),
              Tab(icon: Icon(Icons.upload_file_outlined), text: 'Upload New'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVaultImagesTab(context, ref),
            _buildUploadTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultImagesTab(BuildContext context, WidgetRef ref) {
    final asyncImages = ref.watch(vaultImagesProvider);
    final vaultRoot = ref.watch(appProvider.select((s) => s.storagePath));

    return asyncImages.when(
      data: (images) {
        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          // --- FIX: Make the callback async and await the refresh ---
          onRefresh: () async {
            ref.refresh(vaultImagesProvider);
          },
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
                child: InkWell(
                  onTap: () {
                    if (vaultRoot != null) {
                      final relativePath = p.relative(imageFile.path, from: vaultRoot);
                      widget.onImageSelected(relativePath);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
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

  Widget _buildUploadTab(BuildContext context, WidgetRef ref) {
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
              widget.onImageSelected(newRelativePath);
              if (context.mounted) Navigator.of(context).pop();
            } catch (e) {
              if(context.mounted) {
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