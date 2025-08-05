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
  
  /// --- NEW: Downloads the admin's avatar from the private bucket. ---
  Future<Uint8List> downloadAdminAvatar(String userId) async {
    final path = '$userId/profile/avatar.png';
    // Downloads file data from the 'user-files' bucket. [4]
    return await _supabase.storage.from('user-files').download(path);
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
}