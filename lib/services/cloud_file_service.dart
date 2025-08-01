// lib/services/cloud_file_service.dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseBucket = 'user-files';

class CloudFileService {
  final SupabaseClient _supabaseClient;

  CloudFileService(this._supabaseClient);

  /// Fetches the user's profile (usage, limits, etc.).
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    return await _supabaseClient
        .from('profiles')
        .select() // Selects all columns from the row
        .eq('id', userId)
        .single();
  }

  /// Fetches the contents of a specific folder.
  Future<List<Map<String, dynamic>>> getFolderContents(String? folderId) async {
    final result = await _supabaseClient.rpc(
      'get_folder_contents',
      params: {'p_folder_id': folderId},
    );
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Fetches a flat list of ALL files for the currently authenticated user.
  Future<List<Map<String, dynamic>>> getAllFiles() async {
    final result = await _supabaseClient.rpc('get_user_files');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getUserRootFolder(String userId) async {
    final response = await _supabaseClient
        .from('files')
        .select('id, path')
        .eq('user_id', userId)
        .isFilter('parent_id', null)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getFolderPath(String folderId) async {
    final result = await _supabaseClient.rpc(
      'get_folder_path',
      params: {'p_folder_id': folderId},
    );
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> uploadFile({
    required String path,
    required Uint8List fileBytes,
    FileOptions? fileOptions,
  }) async {
    await _supabaseClient.storage.from(supabaseBucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: fileOptions ?? const FileOptions(upsert: true),
        );
  }

  Future<Uint8List> downloadFile({required String path}) async {
    return await _supabaseClient.storage.from(supabaseBucket).download(path);
  }

  Future<void> deleteFile({required String path}) async {
    await _supabaseClient.storage.from(supabaseBucket).remove([path]);
  }

  Future<void> trashFile({required String fileId}) async {
    await _supabaseClient.rpc('trash_file', params: {'p_file_id': fileId});
  }

  Future<void> restoreFile({required String fileId}) async {
    await _supabaseClient.rpc('restore_file', params: {'p_file_id': fileId});
  }
}

final cloudFileServiceProvider = Provider<CloudFileService>((ref) {
  return CloudFileService(Supabase.instance.client);
});