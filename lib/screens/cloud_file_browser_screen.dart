// C:\dev\memoir\lib\screens\cloud_file_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:path/path.dart' as p;

typedef _CloudPerson = ({
  String name,
  String folderName,
  bool hasInfoMd,
  String pathPrefix,
  int noteCount,
  List<CloudFile> notes
});

class CloudFileBrowserScreen extends ConsumerStatefulWidget {
  const CloudFileBrowserScreen({super.key});

  @override
  ConsumerState<CloudFileBrowserScreen> createState() =>
      _CloudFileBrowserScreenState();
}

class _CloudFileBrowserScreenState extends ConsumerState<CloudFileBrowserScreen> {
  _CloudPerson? _selectedPerson;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloudFilesAsync = ref.watch(allCloudFilesProvider);
    final cloudNotifier = ref.read(cloudNotifierProvider.notifier);
    final vaultRoot = ref.watch(appProvider).storagePath;

    ref.listen<CloudState>(cloudNotifierProvider, (previous, current) {
      if (current.errorMessage != null &&
          current.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(current.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: _selectedPerson != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedPerson = null),
              )
            : null,
        title: Text(_selectedPerson?.name ?? 'Cloud People'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allCloudFilesProvider);
              if (_selectedPerson != null) {
                setState(() {
                  _selectedPerson = null;
                });
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allCloudFilesProvider);
          if (_selectedPerson != null) {
            setState(() {
              _selectedPerson = null;
            });
          }
        },
        child: cloudFilesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading cloud files: $err')),
          data: (allFiles) {
            if (allFiles.isEmpty) {
              return const Center(child: Text("No cloud files found."));
            }

            final people = _processFilesIntoPeople(allFiles);

            if (_selectedPerson == null) {
              final filteredPeople = people.where((person) {
                return person.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search people...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildPeopleList(filteredPeople),
                  ),
                ],
              );
            } else {
              final updatedPerson = people.firstWhere(
                (p) => p.pathPrefix == _selectedPerson!.pathPrefix,
                orElse: () => _selectedPerson!,
              );
              return _buildNotesList(updatedPerson, vaultRoot, cloudNotifier);
            }
          },
        ),
      ),
    );
  }

  List<_CloudPerson> _processFilesIntoPeople(List<CloudFile> allFiles) {
    final Map<String, ({String? name, List<CloudFile> notes})> peopleData = {};
    final personFolderRegex = RegExp(r'(.*/people/[^/]+/)');

    for (final file in allFiles) {
      if (file.cloudPath == null) continue;

      final match = personFolderRegex.firstMatch(file.cloudPath!);
      if (match == null) continue;

      final personPathPrefix = match.group(0)!;
      peopleData.putIfAbsent(
          personPathPrefix, () => (name: null, notes: []));

      if (file.cloudPath!.endsWith('info.md')) {
        peopleData[personPathPrefix] = (
          name: file.name,
          notes: peopleData[personPathPrefix]!.notes
        );
      }

      if (!file.isFolder) {
        peopleData[personPathPrefix]!.notes.add(file);
      }
    }

    final List<_CloudPerson> result = [];
    peopleData.forEach((pathPrefix, data) {
      final bool hasInfoMd = data.name != null;

      String folderName = 'Unknown';
      final pathParts = pathPrefix.split('/');
      if (pathParts.length >= 3) {
        folderName = pathParts[pathParts.length - 2];
      }

      final String personName = hasInfoMd ? data.name! : folderName;
      final int noteCount = data.notes.length;

      result.add((
        name: personName,
        folderName: folderName,
        hasInfoMd: hasInfoMd,
        pathPrefix: pathPrefix,
        noteCount: noteCount,
        notes: data.notes
      ));
    });

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Widget _buildPeopleList(List<_CloudPerson> people) {
    if (people.isEmpty) {
      return const Center(child: Text("No matching people found."));
    }

    return ListView.builder(
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        final subtitleText = person.hasInfoMd
            ? '${person.folderName}\n${person.noteCount} note(s) synced'
            : '${person.noteCount} note(s) synced';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.person_outline, size: 40),
            title: Text(person.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitleText),
            isThreeLine: person.hasInfoMd,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _selectedPerson = person;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesList(
    _CloudPerson person,
    String? vaultRoot,
    CloudNotifier cloudNotifier,
  ) {
    if (person.notes.isEmpty) {
      return Center(child: Text("No notes found for ${person.name}."));
    }

    person.notes.sort((a, b) {
      bool aIsInfo = a.cloudPath?.endsWith('info.md') ?? false;
      bool bIsInfo = b.cloudPath?.endsWith('info.md') ?? false;
      if (aIsInfo != bIsInfo) {
        return aIsInfo ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return ListView.builder(
      itemCount: person.notes.length,
      itemBuilder: (context, index) {
        final item = person.notes[index];
        final isInfoNote = item.cloudPath?.endsWith('info.md') ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading:
                Icon(isInfoNote ? Icons.info_outline : Icons.description_outlined),
            title: Text(item.name),
            subtitle: Text(
              p.basename(item.cloudPath ?? ''),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isInfoNote)
                  const Chip(
                      label: Text('Info'), visualDensity: VisualDensity.compact),
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Download',
                  onPressed: () async {
                    if (vaultRoot == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Local vault path not set!')),
                      );
                      return;
                    }
                    final success =
                        await cloudNotifier.downloadFile(item, vaultRoot);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Downloaded: ${item.name}'
                              : 'Download failed!'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) {
                        ref.read(appProvider.notifier).refreshVault();
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever_outlined,
                      color: Colors.red.shade700),
                  tooltip: 'Delete from Cloud',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                            'Are you sure you want to permanently delete "${item.name}" from the cloud? This action cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final success = await cloudNotifier.deleteFile(item);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'File deleted from cloud.'
                                : 'Failed to delete file.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                        if (success) {
                          ref.invalidate(allCloudFilesProvider);
                        }
                      }
                    }
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}