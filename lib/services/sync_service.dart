// lib/services/sync_service.dart
import 'dart:io'; // Import for File
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/services/local_storage_service.dart'; // Import LocalStorageService

class SyncService {
  final Ref _ref;

  SyncService(this._ref);

  // Helper to find a CloudFile by its local relative path.
  Future<CloudFile?> _findCloudFileByPath(String relativePath) async {
    try {
      await _ref.refresh(allCloudFilesProvider.future);
      final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
      final normalizedLocalPath = relativePath.replaceAll(r'\', '/');

      return allCloudFiles.firstWhereOrNull(
        (cf) => (cf.cloudPath?.endsWith(normalizedLocalPath) ?? false) && !cf.isFolder,
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper to find a CloudFolder by its local relative path.
  Future<CloudFile?> _findCloudFolderByPath(String relativePath) async {
    try {
      await _ref.refresh(allCloudFilesProvider.future);
      final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
      // Folder paths in the cloud won't have a trailing slash
      final normalizedLocalPath = relativePath.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');

      return allCloudFiles.firstWhereOrNull(
        (cf) => (cf.cloudPath?.endsWith(normalizedLocalPath) ?? false) && cf.isFolder,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> performInitialSync() async {
    final appState = _ref.read(appProvider);
    final user = appState.currentUser;

    if (user == null || appState.storagePath == null) {
      print('Initial Sync: Aborting. Pre-conditions not met (user, storagePath).');
      return;
    }

    final cloudNotifier = _ref.read(cloudNotifierProvider.notifier);
    await cloudNotifier.initializationComplete;
    final cloudState = _ref.read(cloudNotifierProvider);
    if (cloudState.userRootPath == null) {
      print('Initial Sync: Aborting. Cloud root path not available.');
      return;
    }

    print('Initial Sync: Starting...');
    _ref.read(appProvider.notifier).setSyncLoading(true);

    try {
      final vaultRoot = appState.storagePath!;
      final userRootPath = cloudState.userRootPath!;

      // 1. Get current local and cloud states
      final allLocalNotes = appState.persons.expand((p) => [p.info, ...p.notes]).toList();
      final localPaths = allLocalNotes.map((n) => n.path.replaceAll(r'\', '/')).toSet();

      await _ref.refresh(allCloudFilesProvider.future);
      final allCloudFiles = await _ref.read(allCloudFilesProvider.future);

      final cloudFilesMap = {
        for (var cf in allCloudFiles)
          if (cf.cloudPath != null && !cf.isFolder)
            cf.cloudPath!.replaceFirst(userRootPath, '').replaceFirst(RegExp(r'^/'), ''): cf
      };
      final cloudPaths = cloudFilesMap.keys.toSet();

      // 2. Find files existing in both places and resolve conflicts
      final commonPaths = localPaths.intersection(cloudPaths);
      for (final path in commonPaths) {
        final localNote = allLocalNotes.firstWhere((n) => n.path.replaceAll(r'\', '/') == path);
        final cloudFile = cloudFilesMap[path]!;

        if (cloudFile.isDeleted) continue;

        final localTimestamp = localNote.lastModified;
        final cloudTimestamp = cloudFile.updatedAt;
        final difference = localTimestamp.difference(cloudTimestamp).inSeconds.abs();

        if (difference > 2) {
          // Use absolute difference to catch either direction
          if (localTimestamp.isAfter(cloudTimestamp)) {
            print('Initial Sync: Local is newer for "$path". Uploading.');
            await cloudNotifier.uploadNote(localNote, vaultRoot);
          } else {
            print('Initial Sync: Cloud is newer for "$path". Downloading.');
            // triggers the entire fix: download -> update YAML -> update state
            await cloudNotifier.downloadNoteAndImages(cloudFile, vaultRoot);
          }
        }
      }
    } catch (e) {
      print('Initial Sync: An error occurred: $e');
    } finally {
      print('Initial Sync: Finished.');
      _ref.read(appProvider.notifier).setSyncLoading(false);
    }
  }

  Future<void> autoUpload(Note note, String vaultRoot) async {
    final user = _ref.read(appProvider).currentUser;
    if (user == null) return;

    final localStorage = _ref.read(localStorageServiceProvider);

    try {
      final cloudFile = await _findCloudFileByPath(note.path);
      bool shouldUpload = false;

      if (cloudFile == null) {
        // File doesn't exist in the cloud, it's a new file.
        print('Auto-sync: New file "${note.path}". Uploading.');
        shouldUpload = true;
      } else {
        // File exists, compare timestamps to avoid overwriting newer cloud data.
        final localTimestamp = note.lastModified;
        final cloudTimestamp = cloudFile.updatedAt;
        final difference = localTimestamp.difference(cloudTimestamp).inSeconds;

        // Only upload if the local file is significantly newer (e.g., > 2 seconds).
        if (difference > 2) {
          print('Auto-sync: Local is newer for "${note.path}". Uploading.');
          shouldUpload = true;
        } else {
          print('Auto-sync: Skipping upload for "${note.path}", cloud version is same or newer.');
        }
      }

      if (shouldUpload) {
        // First, upload the note
        final uploadSuccessful = await _ref.read(cloudNotifierProvider.notifier).uploadNote(note, vaultRoot);

        if (uploadSuccessful) {
          // If the upload was successful, update the local modified timestamp
          final localFile = File('$vaultRoot/${note.path}');
          // Set the local file's modified time to the current time (or cloud's updated time if available)
          await localStorage.updateNoteLastModified(localFile.path, DateTime.now()); // or cloudFile.updatedAt
          print('Auto-sync: Upload task complete for ${note.path}, local timestamp updated.');
        } else {
          print('Auto-sync: Upload failed, local timestamp not updated.');
        }
      }
    } catch (e) {
      print('Auto-sync: Failed to upload changes for ${note.path}. Error: $e');
    }
  }

  Future<void> autoTrash(Note note) async {
    // FIX: Get user from appProvider.
    final user = _ref.read(appProvider).currentUser;
    if (user == null) {
      print('Auto-sync: Aborting trash, no authenticated user.');
      return;
    }

    try {
      final cloudFile = await _findCloudFileByPath(note.path);

      if (cloudFile?.id != null) {
        print('Auto-sync: Trashing ${cloudFile!.cloudPath} in cloud storage.');
        final cloudService = _ref.read(cloudFileServiceProvider);

        await cloudService.trashFile(fileId: cloudFile.id!);
        print('Auto-sync: Cloud trash complete for ${cloudFile.cloudPath}.');

        _ref.invalidate(allCloudFilesProvider);
      }
    } catch (e) {
      print('Auto-sync: Failed to trash cloud file for ${note.path}. Error: $e');
    }
  }

  Future<void> autoRestore(Note note) async {
    // FIX: Get user from appProvider.
    final user = _ref.read(appProvider).currentUser;
    if (user == null) {
      print('Auto-sync: Aborting restore, no authenticated user.');
      return;
    }

    try {
      final cloudFile = await _findCloudFileByPath(note.path);

      if (cloudFile?.id != null) {
        print('Auto-sync: Restoring ${cloudFile!.cloudPath} from cloud trash.');
        final cloudService = _ref.read(cloudFileServiceProvider);

        await cloudService.restoreFile(fileId: cloudFile.id!);
        print('Auto-sync: Cloud restore complete for ${cloudFile.cloudPath}.');

        _ref.invalidate(allCloudFilesProvider);
      }
    } catch (e) {
      print('Auto-sync: Failed to restore cloud file for ${note.path}. Error: $e');
    }
  }

  Future<void> autoDeletePermanently(Note note) async {
    // FIX: Get user from appProvider.
    final user = _ref.read(appProvider).currentUser;
    if (user == null) {
      print('Auto-sync: Aborting permanent delete, no authenticated user.');
      return;
    }

    try {
      final cloudFile = await _findCloudFileByPath(note.path);

      if (cloudFile?.cloudPath != null) {
        print('Auto-sync: Deleting ${cloudFile!.cloudPath} from cloud storage.');
        final cloudService = _ref.read(cloudFileServiceProvider);

        await cloudService.deleteFile(path: cloudFile.cloudPath!);
        print('Auto-sync: Cloud deletion complete for ${cloudFile.cloudPath}.');

        _ref.invalidate(allCloudFilesProvider);
      }
    } catch (e) {
      print('Auto-sync: Failed to delete cloud file for ${note.path}. Error: $e');
    }
  }

  Future<void> autoTrashByPath(String relativePath) async {
    // FIX: Get user from appProvider.
    final user = _ref.read(appProvider).currentUser;
    if (user == null) {
      print('Auto-sync: Aborting trash by path, no authenticated user.');
      return;
    }

    try {
      final cloudFolder = await _findCloudFolderByPath(relativePath);
      if (cloudFolder?.id != null) {
        print('Auto-sync: Recursively trashing folder ${cloudFolder!.cloudPath}');
        final cloudService = _ref.read(cloudFileServiceProvider);
        await cloudService.trashFile(fileId: cloudFolder.id!);
        _ref.invalidate(allCloudFilesProvider);
      }
    } catch (e) {
      print('Auto-sync: Failed to trash folder for path $relativePath. Error: $e');
    }
  }

  Future<void> autoRestoreByPath(String relativePath) async {
    // FIX: Get user from appProvider.
    final user = _ref.read(appProvider).currentUser;
    if (user == null) {
      print('Auto-sync: Aborting restore by path, no authenticated user.');
      return;
    }

    try {
      final cloudFolder = await _findCloudFolderByPath(relativePath);
      if (cloudFolder?.id != null) {
        print('Auto-sync: Recursively restoring folder ${cloudFolder!.cloudPath}');
        final cloudService = _ref.read(cloudFileServiceProvider);
        await cloudService.restoreFile(fileId: cloudFolder.id!);
        _ref.invalidate(allCloudFilesProvider);
      }
    } catch (e) {
      print('Auto-sync: Failed to restore folder for path $relativePath. Error: $e');
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});