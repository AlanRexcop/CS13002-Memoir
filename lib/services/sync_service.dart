// lib/services/sync_service.dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart'; // CORRECTED: Was cloud_viewmodel.dart
import 'package:memoir/services/cloud_file_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  final Ref _ref;

  SyncService(this._ref);

  Future<void> autoUpload(Note note, String vaultRoot) async {
    // Read necessary providers within the method
    final user = _ref.read(supabaseProvider).auth.currentUser;
    if (user == null) return; // Not signed in, do nothing

    try {
      // Refresh the list to ensure it's up-to-date before checking
      await _ref.refresh(allCloudFilesProvider.future);
      final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
      final normalizedLocalPath = note.path.replaceAll(r'\', '/');
      final isSynced = allCloudFiles.any((cf) => cf.cloudPath?.endsWith(normalizedLocalPath) ?? false);

      // If the note exists in the cloud, upload the new version
      if (isSynced) {
        print('Auto-sync: Uploading changes for ${note.path}');
        final cloudService = _ref.read(cloudFileServiceProvider);
        
        final rootFolder = await cloudService.getUserRootFolder(user.id);
        final userRootPath = rootFolder['path'] as String;
        final cloudPath = '$userRootPath/$normalizedLocalPath';

        final localStorage = _ref.read(localStorageServiceProvider);
        final fileContent = await localStorage.readRawFileContent(vaultRoot, note.path);
        final fileBytes = Uint8List.fromList(fileContent.codeUnits);
        
        await cloudService.uploadFile(path: cloudPath, fileBytes: fileBytes);
        print('Auto-sync: Upload complete for ${note.path}');
      }
    } catch (e) {
      print('Auto-sync: Failed to upload changes for ${note.path}. Error: $e');
    }
  }

  Future<void> autoDelete(Note note) async {
    final user = _ref.read(supabaseProvider).auth.currentUser;
    if (user == null) return; // Not signed in, do nothing

    try {
      // Refresh the list to ensure it's up-to-date before checking
      await _ref.refresh(allCloudFilesProvider.future);
      final allCloudFiles = await _ref.read(allCloudFilesProvider.future);
      final normalizedLocalPath = note.path.replaceAll(r'\', '/');
      
      final cloudFile = allCloudFiles.firstWhere(
        (cf) => cf.cloudPath?.endsWith(normalizedLocalPath) ?? false,
        orElse: () => CloudFile(name: '', size: 0, lastModified: DateTime.now()), // Dummy
      );

      if (cloudFile.cloudPath != null) {
        print('Auto-sync: Deleting ${cloudFile.cloudPath} from cloud storage.');
        final cloudService = _ref.read(cloudFileServiceProvider);
        
        await cloudService.deleteFile(path: cloudFile.cloudPath!);
        print('Auto-sync: Cloud deletion complete for ${cloudFile.cloudPath}.');
        
        // Invalidate the provider so the UI shows the correct status on the next build
        _ref.invalidate(allCloudFilesProvider);
      }
    } catch (e) {
      print('Auto-sync: Failed to delete cloud file for ${note.path}. Error: $e');
    }
  }
}

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});