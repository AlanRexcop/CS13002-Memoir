// lib/services/admin_auth_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthService {
  final SupabaseClient _supabase;

  AdminAuthService(this._supabase);

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Finds and downloads the admin's avatar. ---
  Future<Uint8List> findAndDownloadAdminAvatar(String userId) async {
    final String folderPath = '$userId/profile';

    // Search for any file starting with 'avatar'. [6, 7]
    final List<FileObject> files = await _supabase.storage
        .from('user-files')
        .list(path: folderPath, searchOptions: SearchOptions(search: 'avatar'));

    if (files.isEmpty) {
      throw const StorageException('Admin avatar not found.');
    }

    // Download the first file found.
    final String avatarFilename = files.first.name;
    final String fullPath = '$folderPath/$avatarFilename';

    return await _supabase.storage.from('user-files').download(fullPath);
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
}