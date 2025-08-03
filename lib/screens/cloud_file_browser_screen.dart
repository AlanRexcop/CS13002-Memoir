// C:\dev\memoir\lib\screens\cloud_file_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

enum _ViewMode { people, images }

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
  _ViewMode _currentView = _ViewMode.people;

  final _imageExtensions = const ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'];

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

  void _toggleView() {
    setState(() {
      _currentView = _currentView == _ViewMode.people ? _ViewMode.images : _ViewMode.people;
      // Reset selections and search when switching views
      _selectedPerson = null;
      _searchController.clear();
    });
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

    final String appBarTitle;
    if (_currentView == _ViewMode.images) {
      appBarTitle = 'Cloud Images';
    } else if (_selectedPerson != null) {
      appBarTitle = _selectedPerson!.name;
    } else {
      appBarTitle = 'Cloud People';
    }

    return Scaffold(
      appBar: AppBar(
        leading: _selectedPerson != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedPerson = null),
              )
            : null,
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: Icon(_currentView == _ViewMode.people ? Icons.image_outlined : Icons.people_outline),
            tooltip: _currentView == _ViewMode.people ? 'View Images' : 'View People',
            onPressed: _toggleView,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allCloudFilesProvider);
              if (_selectedPerson != null) {
                setState(() => _selectedPerson = null);
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
            if (_currentView == _ViewMode.images) {
              return _buildImageView(allFiles, vaultRoot, cloudNotifier);
            }
            return _buildPeopleView(allFiles, vaultRoot, cloudNotifier);
          },
        ),
      ),
    );
  }

  Widget _buildPeopleView(List<CloudFile> allFiles, String? vaultRoot, CloudNotifier cloudNotifier) {
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
  }

  Widget _buildImageView(List<CloudFile> allFiles, String? vaultRoot, CloudNotifier cloudNotifier) {
    final images = allFiles.where((file) {
      if (file.cloudPath == null) return false;
      final extension = p.extension(file.cloudPath!).toLowerCase();
      return _imageExtensions.contains(extension);
    }).toList();

    if (images.isEmpty) {
      return const Center(child: Text("No cloud images found."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageFile = images[index];
        
        // --- FIX: Use a FutureBuilder to download image data directly ---
        return FutureBuilder(
          future: Supabase.instance.client.storage
              .from('user-files')
              .download(imageFile.cloudPath!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Icon(Icons.broken_image);
            }

            final imageData = snapshot.data!;
            return GridTile(
              footer: GridTileBar(
                backgroundColor: Colors.black45,
                leading: IconButton(
                  icon: const Icon(Icons.download_outlined, color: Colors.white),
                  tooltip: 'Download Image',
                  onPressed: () => _downloadSingleFile(imageFile, vaultRoot, cloudNotifier),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  tooltip: 'Delete Image',
                  onPressed: () => _deleteSingleFile(imageFile, cloudNotifier),
                ),
              ),
              child: InkWell(
                onTap: () { /* Could open a full-screen preview here */ },
                child: Image.memory(
                  imageData,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      },
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
        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          color: colorScheme.secondary,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(25),
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(5),
            ),
            side: BorderSide(color: colorScheme.outline, width: 2),
          ),
          child: ListTile(
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

  Future<void> _downloadSingleFile(CloudFile item, String? vaultRoot, CloudNotifier cloudNotifier) async {
    if (vaultRoot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local vault path not set!')));
      return;
    }

    final isMarkdown = item.cloudPath?.endsWith('.md') ?? false;
    final bool success;
    if (isMarkdown) {
      success = await cloudNotifier.downloadNoteAndImages(item, vaultRoot);
    } else {
      success = await cloudNotifier.downloadFile(item, vaultRoot);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Downloaded: ${item.name}' : 'Download failed!'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        ref.read(appProvider.notifier).refreshVault();
      }
    }
  }

  Future<void> _deleteSingleFile(CloudFile item, CloudNotifier cloudNotifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete "${item.name}" from the cloud? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await cloudNotifier.deleteFile(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'File deleted from cloud.' : 'Failed to delete file.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          ref.invalidate(allCloudFilesProvider);
        }
      }
    }
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
        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          color: colorScheme.secondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(25),
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(5),
            ),
            side: BorderSide(color: colorScheme.outline, width: 2),
          ),
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
                  onPressed: () => _downloadSingleFile(item, vaultRoot, cloudNotifier),
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever_outlined,
                      color: Colors.red.shade700),
                  tooltip: 'Delete from Cloud',
                  onPressed: () => _deleteSingleFile(item, cloudNotifier),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}