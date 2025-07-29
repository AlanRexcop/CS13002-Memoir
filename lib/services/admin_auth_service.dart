// lib/services/admin_auth_service.dart
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

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
}