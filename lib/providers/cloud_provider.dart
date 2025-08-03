// C:\dev\memoir\lib\providers\cloud_provider.dart
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

@immutable
class CloudState {
  final List<CloudFile> items;
  final List<Map<String, dynamic>> breadcrumbs;
  final bool isLoading;
  final String? errorMessage;
  final String? currentFolderId;
  final String? userRootPath; 

  const CloudState({
    this.items = const [],
    this.breadcrumbs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentFolderId,
    this.userRootPath,
  });

  CloudState copyWith({
    List<CloudFile>? items,
    List<Map<String, dynamic>>? breadcrumbs,
    bool? isLoading,
    String? errorMessage,
    String? currentFolderId,
    String? userRootPath,
  }) {
    return CloudState(
      items: items ?? this.items,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      userRootPath: userRootPath ?? this.userRootPath,
    );
  }
}

class CloudNotifier extends StateNotifier<CloudState> {
  final CloudFileService _cloudService;
  final User _currentUser;
  final Ref _ref;

  CloudNotifier(this._cloudService, this._currentUser, this._ref) : super(const CloudState()) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rootFolder = await _cloudService.getUserRootFolder(_currentUser.id);
      final rootFolderId = rootFolder['id'] as String;
      final rootPath = rootFolder['path'] as String; 
      state = state.copyWith(userRootPath: rootPath);
      await _fetchFolderContents(rootFolderId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load root folder. It may not exist yet.');
    }
  }

  Future<void> _fetchFolderContents(String? folderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, currentFolderId: folderId);
    try {
      if (folderId == null) {
        await initialize();
        return;
      }
      
      final contentsFuture = _cloudService.getFolderContents(folderId);
      final pathFuture = _cloudService.getFolderPath(folderId);

      final results = await Future.wait([contentsFuture, pathFuture]);
      
      final items = (results[0])
          .map((data) => CloudFile.fromSupabase(data))
          .toList();
      items.sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      final breadcrumbs = results[1];
      if (breadcrumbs.isNotEmpty) {
        breadcrumbs[0]['name'] = 'root';
      }
      state = state.copyWith(
        items: items,
        breadcrumbs: breadcrumbs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error fetching folder contents: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> navigateToFolder(String? folderId) async {
    try {
      await _fetchFolderContents(folderId);
    } catch (e) {
      await refreshCurrentFolder();
    }
  }

  Future<void> refreshCurrentFolder() async {
    final folderIdToRefresh = state.currentFolderId;
    if (folderIdToRefresh == null) {
      await initialize();
      return;
    }

    try {
      await _fetchFolderContents(folderIdToRefresh);
    } catch (e) {
      final parentFolders = state.breadcrumbs.sublist(0, state.breadcrumbs.length - 1).reversed.toList();
      for (final parentCrumb in parentFolders) {
        final parentId = parentCrumb['id'] as String?;
        try {
          await _fetchFolderContents(parentId);
          return;
        } catch (innerError) {
        }
      }
      await initialize();
    }
  }

  Future<bool> deleteFile(CloudFile file) async {
    if (file.cloudPath == null) {
      state = state.copyWith(errorMessage: 'File has no valid cloud path to delete.');
      return false;
    }
    try {
      await _cloudService.deleteFile(path: file.cloudPath!);
      await refreshCurrentFolder(); 
      _ref.invalidate(allCloudFilesProvider);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting file: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteFileByRelativePath(String relativePath) async {
    if (state.userRootPath == null) {
      state = state.copyWith(errorMessage: 'User root path not available. Cannot delete file.');
      return false;
    }
    try {
      final normalizedPath = relativePath.replaceAll(r'\', '/');
      final fullCloudPath = '${state.userRootPath!}$normalizedPath';

      await _cloudService.deleteFile(path: fullCloudPath);
      
      _ref.invalidate(allCloudFilesProvider);
      await refreshCurrentFolder(); 
      
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting file: ${e.toString()}');
      print(e);
      return false;
    }
  }

  Future<bool> downloadFile(CloudFile file, String vaultRoot) async {
    if (file.cloudPath == null || state.userRootPath == null) return false;
    try {
      final fullCloudPath = file.cloudPath!;
      final relativePath = fullCloudPath.replaceFirst(state.userRootPath!, '');
      final localPath = p.join(vaultRoot, relativePath);
      final fileBytes = await _cloudService.downloadFile(path: fullCloudPath);
      
      final localFile = File(localPath);
      final parentDir = Directory(p.dirname(localPath));

      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await localFile.writeAsBytes(fileBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> downloadNoteAndImages(CloudFile noteFile, String vaultRoot) async {
    if (noteFile.cloudPath == null || state.userRootPath == null) return false;
    try {
      // 1. Download the main note file
      await downloadFile(noteFile, vaultRoot);

      // 2. Read the newly downloaded note to get its image list
      final localStorage = _ref.read(localStorageServiceProvider);
      final relativeNotePath = noteFile.cloudPath!.replaceFirst(state.userRootPath!, '');
      final localNoteFile = File(p.join(vaultRoot, relativeNotePath));
      final note = await localStorage.readNoteFromFile(localNoteFile, vaultRoot);

      // 3. Download missing images
      if (note.images.isNotEmpty) {
        // --- FIX: Refresh the cloud file list to ensure we have the latest data ---
        await _ref.refresh(allCloudFilesProvider.future);
        final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
        // --- END FIX ---

        for (final relativeImagePath in note.images) {
          final localImageExists = await localStorage.imageExists(vaultRoot, relativeImagePath);
          if (!localImageExists) {
            final cloudImagePath = '${state.userRootPath!}${relativeImagePath.replaceAll(r'\', '/')}';
            final cloudImageFile = allCloudFiles.firstWhereOrNull((f) => f.cloudPath == cloudImagePath);
            if (cloudImageFile != null) {
              print('Downloading missing image: $relativeImagePath');
              await downloadFile(cloudImageFile, vaultRoot);
            } else {
              print('Could not find cloud file for image: $relativeImagePath');
            }
          }
        }
      }
      return true;
    } catch (e) {
      print('Error downloading note and images: $e');
      return false;
    }
  }

  Future<bool> uploadNote(Note note, String vaultRoot) async {
    if (state.userRootPath == null) {
      state = state.copyWith(errorMessage: 'User root path not available. Cannot upload file.');
      return false;
    }
    try {
      final localStorage = _ref.read(localStorageServiceProvider);
      
      // 1. Upload the main note file
      final localRelativePath = note.path;
      final cloudPath = '${state.userRootPath!}${localRelativePath.replaceAll(r'\', '/')}';
      final fileBytes = await localStorage.readRawFileByte(vaultRoot, localRelativePath);

      await _cloudService.uploadFile(path: cloudPath, fileBytes: fileBytes);

      // 2. Upload any associated images that don't exist in the cloud
      if (note.images.isNotEmpty) {
        // Get an up-to-date list of all cloud files
        await _ref.refresh(allCloudFilesProvider.future);
        final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
        
        for (final relativeImagePath in note.images) {
          final cloudImagePath = '${state.userRootPath!}${relativeImagePath.replaceAll(r'\', '/')}';
          final cloudFileExists = allCloudFiles.any((cf) => cf.cloudPath == cloudImagePath);

          if (!cloudFileExists) {
            print('Uploading new image: $relativeImagePath');
            final imageBytes = await localStorage.readRawFileByte(vaultRoot, relativeImagePath);
            await _cloudService.uploadFile(path: cloudImagePath, fileBytes: imageBytes);
          }
        }
      }

      _ref.invalidate(allCloudFilesProvider);
      await refreshCurrentFolder();

      return true;
    } catch(e) {
      print("Upload failed for note ${note.path}: $e");
      state = state.copyWith(errorMessage: 'Upload failed: ${e.toString()}');
      return false;
    }
  }
}

final cloudNotifierProvider = StateNotifierProvider<CloudNotifier, CloudState>((ref) {
  final cloudService = ref.watch(cloudFileServiceProvider);
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    throw Exception("CloudNotifier requires an authenticated user.");
  }
  return CloudNotifier(cloudService, user, ref);
});

final allCloudFilesProvider = FutureProvider<List<CloudFile>>((ref) async {
  final cloudService = ref.read(cloudFileServiceProvider);
  final fileMaps = await cloudService.getAllFiles();
  return fileMaps.map((data) => CloudFile.fromSupabase(data)).toList();
});