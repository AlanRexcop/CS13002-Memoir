// lib/screens/cloud_file_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/viewmodels/cloud_viewmodel.dart';

class CloudFileBrowserScreen extends ConsumerWidget {
  const CloudFileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudState = ref.watch(cloudViewModelProvider);
    final cloudViewModel = ref.read(cloudViewModelProvider.notifier);
    final vaultRoot = ref.watch(appProvider).storagePath;

    // Listen for errors and show a snackbar
    ref.listen<CloudState>(cloudViewModelProvider, (previous, current) {
      if (current.errorMessage != null && current.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(current.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Browser'),
      ),
      body: Column(
        children: [
          _buildBreadcrumbs(context, cloudState, cloudViewModel),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => cloudViewModel.refreshCurrentFolder(),
              child: Stack(
                children: [
                  if (cloudState.isLoading && cloudState.items.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (cloudState.items.isEmpty && !cloudState.isLoading)
                    const Center(child: Text("This folder is empty."))
                  else
                    ListView.builder(
                      itemCount: cloudState.items.length,
                      itemBuilder: (context, index) {
                        final item = cloudState.items[index];
                        return ListTile(
                          leading: Icon(item.isFolder ? Icons.folder_outlined : Icons.description_outlined),
                          title: Text(item.name),
                          onTap: item.isFolder
                              ? () => cloudViewModel.navigateToFolder(item.id)
                              : null,
                          trailing: item.isFolder
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.download_outlined),
                                  onPressed: () async {
                                    if (vaultRoot == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Local vault path not set!')),
                                      );
                                      return;
                                    }
                                    final success = await cloudViewModel.downloadFile(item, vaultRoot);
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Downloaded: ${item.name}' : 'Download failed!'),
                                          backgroundColor: success ? Colors.green : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                        );
                      },
                    ),
                  if (cloudState.isLoading && cloudState.items.isNotEmpty)
                    Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, CloudState state, CloudViewModel viewModel) {
    if (state.breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey.shade200,
      width: double.infinity,
      child: Wrap(
        spacing: 4.0,
        alignment: WrapAlignment.start,
        children: state.breadcrumbs.map((crumb) {
          final isLast = crumb == state.breadcrumbs.last;
          return InkWell(
            onTap: isLast ? null : () => viewModel.navigateToFolder(crumb['id'] as String?),
            child: Text(
              isLast ? '${crumb['name']}' : '${crumb['name']} > ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast ? Colors.black : Colors.blue.shade700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}