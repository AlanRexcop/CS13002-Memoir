// C:\dev\memoir\lib\services\sync_service.dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart'; 
import 'package:memoir/services/cloud_file_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  final Ref _ref;

  SyncService(this._ref);

  /// Helper to find a CloudFile by its local relative path.
  Future<CloudFile?> _findCloudFileByPath(String relativePath) async {
    try {
      await _ref.refresh(allCloudFilesProvider.future);
      final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
      final normalizedLocalPath = relativePath.replaceAll(r'\', '/');
      
      return allCloudFiles.firstWhere(
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
      
      return allCloudFiles.firstWhere(
        (cf) => (cf.cloudPath?.endsWith(normalizedLocalPath) ?? false) && cf.isFolder,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> autoUpload(Note note, String vaultRoot) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; 

    final cloudState = _ref.read(cloudNotifierProvider);
    final userRootPath = cloudState.userRootPath;
    if (userRootPath == null) return;

    final localStorage = _ref.read(localStorageServiceProvider);
    final cloudService = _ref.read(cloudFileServiceProvider);

    try {
      // 1. Upload the main note file if it exists in the cloud, otherwise it's a new file.
      // This logic assumes a note is only auto-uploaded if it has a corresponding cloud entry.
      // A more robust system might create the entry if it's missing.
      final cloudFile = await _findCloudFileByPath(note.path);
      if (cloudFile?.cloudPath != null) {
        print('Auto-sync: Uploading changes for ${note.path}');
        final fileBytes = await localStorage.readRawFileByte(vaultRoot, note.path);
        await cloudService.uploadFile(path: cloudFile!.cloudPath!, fileBytes: fileBytes);
        print('Auto-sync: Upload complete for ${note.path}');
      }

      // 2. Sync associated images
      if (note.images.isNotEmpty) {
        await _ref.refresh(allCloudFilesProvider.future);
        final allCloudFiles = await _ref.read(allCloudFilesProvider.future);

        for (final relativeImagePath in note.images) {
          final cloudImagePath = '$userRootPath/${relativeImagePath.replaceAll(r'\', '/')}';
          final cloudFileExists = allCloudFiles.any((cf) => cf.cloudPath == cloudImagePath);

          if (!cloudFileExists) {
            print('Auto-sync: Uploading new image: $relativeImagePath');
            final imageBytes = await localStorage.readRawFileByte(vaultRoot, relativeImagePath);
            await cloudService.uploadFile(path: cloudImagePath, fileBytes: imageBytes);
          }
        }
      }
      
      _ref.invalidate(allCloudFilesProvider);

    } catch (e) {
      print('Auto-sync: Failed to upload changes for ${note.path}. Error: $e');
    }
  }

  Future<void> autoTrash(Note note) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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

  // NEW: Trashes an entire folder recursively using its relative path.
  Future<void> autoTrashByPath(String relativePath) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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

  // NEW: Restores an entire folder recursively using its relative path.
  Future<void> autoRestoreByPath(String relativePath) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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