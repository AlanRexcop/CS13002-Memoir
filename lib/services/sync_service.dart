// lib/services/sync_service.dart
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
    // Read necessary providers within the method
    final user = _ref.read(supabaseProvider).auth.currentUser;
    if (user == null) return; // Not signed in, do nothing

    try {
      final cloudFile = await _findCloudFileByPath(note.path);

      // If the note exists in the cloud, upload the new version
      if (cloudFile?.cloudPath != null) {
        print('Auto-sync: Uploading changes for ${note.path}');
        final cloudService = _ref.read(cloudFileServiceProvider);
        
        final localStorage = _ref.read(localStorageServiceProvider);
        final fileBytes = await localStorage.readRawFileByte(vaultRoot, note.path);
        
        await cloudService.uploadFile(path: cloudFile!.cloudPath!, fileBytes: fileBytes);
        print('Auto-sync: Upload complete for ${note.path}');
      }
    } catch (e) {
      print('Auto-sync: Failed to upload changes for ${note.path}. Error: $e');
    }
  }

  Future<void> autoTrash(Note note) async {
    final user = _ref.read(supabaseProvider).auth.currentUser;
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
    final user = _ref.read(supabaseProvider).auth.currentUser;
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
    final user = _ref.read(supabaseProvider).auth.currentUser;
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
    final user = _ref.read(supabaseProvider).auth.currentUser;
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
    final user = _ref.read(supabaseProvider).auth.currentUser;
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

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});