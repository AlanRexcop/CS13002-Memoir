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
  // Made _currentUser nullable to support the unauthenticated state gracefully
  final User? _currentUser;
  final Ref _ref;
  late final Future<void> initializationComplete;

  CloudNotifier(this._cloudService, this._currentUser, this._ref) : super(const CloudState()) {
    // Only initialize if we have a user
    if (_currentUser != null) {
      initializationComplete = initialize();
    } else {
      // If no user, complete immediately with an empty state
      initializationComplete = Future.value();
    }
  }

  Future<void> initialize() async {
    // Guard against running initialization without a user
    if (_currentUser == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rootFolder = await _cloudService.getUserRootFolder(_currentUser!.id);
      final rootFolderId = rootFolder['id'] as String;
      final rootPath = rootFolder['path'] as String; 
      state = state.copyWith(userRootPath: rootPath);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load root folder. It may not exist yet.');
    }
  }

  /// Uses the CloudFileService to get a file's data by its ID and returns the cloud path.
  /// Returns null if the file is not found or an error occurs.
  Future<String?> getCloudPathById(String fileId) async {
    try {
      final fileData = await _cloudService.getFileById(fileId);
      final cloudPath = fileData['path'] as String?;
      return cloudPath;
    } catch (e) {
      print('Error fetching cloud path for file ID $fileId: $e');
     
      state = state.copyWith(errorMessage: 'Failed to retrieve file details.');
      return null;
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
      
      if (file.cloudPath!.endsWith('.md')) {
        final localStorage = _ref.read(localStorageServiceProvider);
        await localStorage.updateNoteLastModified(localPath, file.updatedAt);

        // Immediately update the app's in-memory state.
        await _ref.read(appProvider.notifier).updateSingleNoteInState(relativePath);
      }
      
      return true;
    } catch (e) {
      print('Error downloading file ${file.cloudPath}: $e');
      return false;
    }
  }

  Future<bool> downloadNoteAndImages(CloudFile noteFile, String vaultRoot) async {
    if (noteFile.cloudPath == null || state.userRootPath == null) return false;
    try {
      // 1. Download the main note file. The downloadFile method now handles everything.
      await downloadFile(noteFile, vaultRoot);

      // 2. Read the newly downloaded note to get its image list
      final localStorage = _ref.read(localStorageServiceProvider);
      final relativeNotePath = noteFile.cloudPath!.replaceFirst(state.userRootPath!, '');
      final localNoteFile = File(p.join(vaultRoot, relativeNotePath));
      final note = await localStorage.readNoteFromFile(localNoteFile, vaultRoot);

      // 3. Download missing images
      if (note.images.isNotEmpty) {
        await _ref.refresh(allCloudFilesProvider.future);
        final allCloudFiles = await _ref.read(allCloudFilesProvider.future);

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
    // --- ADD THIS DEBUGGING LINE ---
    print('DEBUG: Attempting upload for user: ${Supabase.instance.client.auth.currentUser?.id}');
    // ---------------------------------

    await initializationComplete; // Wait for initialization
    if (state.userRootPath == null) {
      // --- ADD THIS DEBUGGING LINE ---
      print('DEBUG: Upload failed. Reason: User root path is null.');
      // ---------------------------------
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
    final vaultRoot = _ref.read(appProvider).storagePath;
    if (state.userRootPath == null || vaultRoot == null) {
      state = state.copyWith(errorMessage: 'User root path or vault not available. Cannot upload avatar.');
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cloudPath = '${state.userRootPath!}profile/avatar.png';
      final fileBytes = await imageFile.readAsBytes();

      // Perform the upload
      await _cloudService.uploadFile(
        path: cloudPath,
        fileBytes: fileBytes,
        fileOptions: const FileOptions(cacheControl: '0', upsert: true),
      );

      // --- THE FIX ---
      // Optimistically update local cache to avoid a re-download
      await _ref.read(localStorageServiceProvider).saveLocalAvatar(vaultRoot, fileBytes);
      
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
    final vaultRoot = _ref.read(appProvider).storagePath;
    if (state.userRootPath == null || vaultRoot == null) {
      state = state.copyWith(errorMessage: 'User root path or vault not available. Cannot upload background.');
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cloudPath = '${state.userRootPath!}profile/background.png';
      final fileBytes = await imageFile.readAsBytes();

      // Perform the upload
      await _cloudService.uploadFile(
        path: cloudPath,
        fileBytes: fileBytes,
        fileOptions: const FileOptions(cacheControl: '0', upsert: true),
      );

      // --- THE FIX ---
      // Optimistically update local cache to avoid a re-download
      await _ref.read(localStorageServiceProvider).saveLocalBackground(vaultRoot, fileBytes);
      
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
  final user = ref.watch(appProvider.select((s) => s.currentUser));

  // The notifier is now created correctly whether a user exists or not.
  // The internal logic of CloudNotifier will handle the unauthenticated state.
  return CloudNotifier(cloudService, user, ref);
});

final allCloudFilesProvider = FutureProvider<List<CloudFile>>((ref) async {
  final currentUser = ref.watch(appProvider.select((s) => s.currentUser));

  // If there's no user logged in, return an empty list immediately.
  // This clears the state from the previous user.
  if (currentUser == null) {
    return [];
  }

  // The provider will re-execute this code when currentUser changes.
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

  final appState = ref.watch(appProvider);
  final currentUser = appState.currentUser;
  final vaultRoot = appState.storagePath;

  if (currentUser == null || vaultRoot == null) {
    return null;
  }
  
  final localStorage = ref.read(localStorageServiceProvider);
  final file = await localStorage.getLocalAvatarFile(vaultRoot);

  if (await file.exists()) {
    return await file.readAsBytes();
  }
  
  return null;
});

final localBackgroundProvider = FutureProvider<Uint8List?>((ref) async {
  ref.watch(backgroundVersionProvider);

  final appState = ref.watch(appProvider);
  final currentUser = appState.currentUser;
  final vaultRoot = appState.storagePath;
  
  if (currentUser == null || vaultRoot == null) {
    return null;
  }
  
  final localStorage = ref.read(localStorageServiceProvider);
  final file = await localStorage.getLocalBackgroundFile(vaultRoot);

  if (await file.exists()) {
    return await file.readAsBytes();
  }
  
  return null;
});