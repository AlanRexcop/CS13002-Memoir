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
    final result = await _supabaseClient.rpc('get_all_user_files');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Fetches the user's root folder ID and path.
  Future<Map<String, dynamic>> getUserRootFolder(String userId) async {
    final response = await _supabaseClient
        .from('files')
        .select('id, path')
        .eq('user_id', userId)
        .isFilter('parent_id', null)
        .single();
    return response;
  }

  /// Fetches the breadcrumb path for a given folder.
  Future<List<Map<String, dynamic>>> getFolderPath(String folderId) async {
    final result = await _supabaseClient.rpc(
      'get_folder_path',
      params: {'p_folder_id': folderId},
    );
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Uploads file bytes to a specific path in Supabase Storage.
  Future<void> uploadFile({
    required String path,
    required Uint8List fileBytes,
  }) async {
    await _supabaseClient.storage.from(supabaseBucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
  }

  /// Downloads a file from a specific path.
  Future<Uint8List> downloadFile({required String path}) async {
    return await _supabaseClient.storage.from(supabaseBucket).download(path);
  }

  /// Deletes a file from storage.
  Future<void> deleteFile({required String path}) async {
    await _supabaseClient.storage.from(supabaseBucket).remove([path]);
  }
}

final cloudFileServiceProvider = Provider<CloudFileService>((ref) {
  return CloudFileService(Supabase.instance.client);
});