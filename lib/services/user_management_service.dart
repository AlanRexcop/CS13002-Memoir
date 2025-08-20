// lib/services/user_management_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserManagementService {
  final SupabaseClient _supabase;

  UserManagementService(this._supabase);

  // ... (fetchUsers and fetchUserById methods are unchanged) ...
  Future<List<UserProfile>> fetchUsers() async {
    final List<dynamic> data = await _supabase.rpc('admin_get_all_users');
    return data.map((item) => UserProfile.fromJson(item)).toList();
  }

  Future<UserProfile> fetchUserById(String userId) async {
    final List<dynamic> data = await _supabase.rpc(
      'admin_get_user_by_id',
      params: {'p_user_id': userId},
    );

    if (data.isEmpty) {
      throw Exception('User not found');
    }
    return UserProfile.fromJson(data.first);
  }


  /// --- MODIFIED: Finds and downloads a user's avatar. ---
  ///
  /// Searches for any file starting with 'avatar' in the user's profile folder.
  Future<Uint8List> findAndDownloadAvatar(String userId) async {
    final String folderPath = '$userId/profile';

    // Step 1: List files in the directory with a search pattern. [6, 7]
    final List<FileObject> files = await _supabase.storage
        .from('user-files')
        .list(path: folderPath, searchOptions: SearchOptions(search: 'avatar'));

    // Step 2: If no matching file is found, throw an exception.
    if (files.isEmpty) {
      throw const StorageException('Avatar not found.');
    }

    // Step 3: Get the name of the first matching file and download it.
    final String avatarFilename = files.first.name;
    final String fullPath = '$folderPath/$avatarFilename';
    
    final Uint8List file = await _supabase.storage.from('user-files').download(fullPath);
    return file;
  }

  /// Deletes a list of users by their IDs.
  Future<void> deleteUsers(List<String> userIds) async {
    await _supabase.rpc('admin_delete_users', params: {'user_ids': userIds});
  }
}