// C:\dev\memoir\lib\providers\cloud_provider.dart
import 'dart:io';
import 'dart:typed_data';

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
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load root folder. It may not exist yet.');
    }
  }



  Future<bool> deleteFile(CloudFile file) async {
    if (file.cloudPath == null) {
      state = state.copyWith(errorMessage: 'File has no valid cloud path to delete.');
      return false;
    }
    try {
      await _cloudService.deleteFile(path: file.cloudPath!);
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
      
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting file: ${e.toString()}');
      print(e);
      return false;
    }
  }

  /// Makes a note and all its referenced images public.
  Future<bool> makeNotePublic(Note note, CloudFile noteCloudFile) async {
    await initializationComplete;
    if (noteCloudFile.id == null) return false;
    
    try {
      // 1. Make the main note file public
      await _cloudService.publicFile(fileId: noteCloudFile.id!);
      
      // 2. Make associated images public
      if (note.images.isNotEmpty && state.userRootPath != null) {
        // Get an up-to-date list of all cloud files to find the image IDs
        await _ref.refresh(allCloudFilesProvider.future);
        final allCloudFiles = await _ref.read(allCloudFilesProvider.future);

        for (final relativeImagePath in note.images) {
          final cloudImagePath = '${state.userRootPath!}${relativeImagePath.replaceAll(r'\', '/')}';
          final cloudImageFile = allCloudFiles.firstWhereOrNull((f) => f.cloudPath == cloudImagePath);

          if (cloudImageFile?.id != null) {
            print('Making image public: $relativeImagePath');
            await _cloudService.publicFile(fileId: cloudImageFile!.id!);
          } else {
            print('Could not find cloud file for image to make public: $relativeImagePath');
          }
        }
      }
      
      _ref.invalidate(allCloudFilesProvider);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error making note public: ${e.toString()}');
      return false;
    }
  }

  Future<bool> makeFilePrivate(CloudFile file) async {
    if (file.id == null) {
      state = state.copyWith(errorMessage: 'File has no valid ID to make private.');
      return false;
    }
    try {
      await _cloudService.privateFile(fileId: file.id!);
      _ref.invalidate(allCloudFilesProvider);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error making note private: ${e.toString()}');
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
    await initializationComplete; // Wait for initialization
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