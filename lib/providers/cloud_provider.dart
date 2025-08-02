// lib/providers/cloud_provider.dart
import 'dart:io';
import 'dart:typed_data';

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
  late final Future<void> initializationComplete;

  CloudNotifier(this._cloudService, this._currentUser, this._ref) : super(const CloudState()) {
    initializationComplete = initialize();
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
    await initializationComplete; // Wait for initialization
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

  Future<bool> uploadNote(Note note, String vaultRoot) async {
    await initializationComplete; // Wait for initialization
    if (state.userRootPath == null) {
      state = state.copyWith(errorMessage: 'User root path not available. Cannot upload file.');
      return false;
    }
    try {
      final localStorage = _ref.read(localStorageServiceProvider);
      
      final localRelativePath = note.path;
      final cloudPath = '${state.userRootPath!}/${localRelativePath.replaceAll(r'\', '/')}';
      final fileBytes = await localStorage.readRawFileByte(vaultRoot, localRelativePath);

      await _cloudService.uploadFile(path: cloudPath, fileBytes: fileBytes);
      
      _ref.invalidate(allCloudFilesProvider);
      await refreshCurrentFolder();

      return true;
    } catch(e) {
      print("Upload failed for note ${note.path}: $e");
      state = state.copyWith(errorMessage: 'Upload failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    await initializationComplete; // Wait for initialization
    if (state.userRootPath == null) {
      state = state.copyWith(errorMessage: 'User root path not available. Cannot upload avatar.');
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cloudPath = '${state.userRootPath!}profile/avatar.png';
      final fileBytes = await imageFile.readAsBytes();

      await _cloudService.uploadFile(
        path: cloudPath,
        fileBytes: fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Optimistically update local cache to avoid a re-download
      await _ref.read(localStorageServiceProvider).saveLocalAvatar(fileBytes);
      
      // Trigger the version provider to force UI to reload the new avatar
      _ref.read(avatarVersionProvider.notifier).update((s) => s + 1);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print("Avatar upload failed: $e");
      state = state.copyWith(isLoading: false, errorMessage: 'Avatar upload failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> uploadBackground(File imageFile) async {
    await initializationComplete; // Wait for initialization
    if (state.userRootPath == null) {
      state = state.copyWith(errorMessage: 'User root path not available. Cannot upload background.');
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cloudPath = '${state.userRootPath!}profile/background.png';
      final fileBytes = await imageFile.readAsBytes();

      await _cloudService.uploadFile(
        path: cloudPath,
        fileBytes: fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Optimistically update local cache to avoid a re-download
      // NOTE: Assumes `saveLocalBackground` exists in LocalStorageService.
      await _ref.read(localStorageServiceProvider).saveLocalBackground(fileBytes);
      
      // Trigger the version provider to force UI to reload the new background
      _ref.read(backgroundVersionProvider.notifier).update((s) => s + 1);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print("Background upload failed: $e");
      state = state.copyWith(isLoading: false, errorMessage: 'Background upload failed: ${e.toString()}');
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

/// A simple provider that acts as a version counter or trigger.
/// When its value changes, dependent providers will refetch.
final avatarVersionProvider = StateProvider<int>((ref) => 0);

/// A version provider for the user's background image.
final backgroundVersionProvider = StateProvider<int>((ref) => 0);

final localAvatarProvider = FutureProvider<Uint8List?>((ref) async {
  // Depend on the version provider. When it changes, this provider re-runs.
  ref.watch(avatarVersionProvider);

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) {
    return null;
  }
  
  final localStorage = ref.read(localStorageServiceProvider);
  // Get the file with the CORRECT path (no query parameters)
  final file = await localStorage.getLocalAvatarFile();

  if (await file.exists()) {
    // Read the file's raw bytes and return them.
    return await file.readAsBytes();
  }
  
  return null;
});

/// Fetches the locally cached background image.
///
/// This provider re-runs whenever [backgroundVersionProvider] changes,
/// ensuring the UI can be updated with a new background after an upload.
final localBackgroundProvider = FutureProvider<Uint8List?>((ref) async {
  // Depend on the version provider. When it changes, this provider re-runs.
  ref.watch(backgroundVersionProvider);

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) {
    return null;
  }
  
  final localStorage = ref.read(localStorageServiceProvider);
  // NOTE: Assumes `getLocalBackgroundFile` exists in LocalStorageService.
  final file = await localStorage.getLocalBackgroundFile();

  if (await file.exists()) {
    // Read the file's raw bytes and return them.
    return await file.readAsBytes();
  }
  
  return null;
});