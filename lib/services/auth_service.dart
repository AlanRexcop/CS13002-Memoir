// lib/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    String? username,
  }) async {
    return await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }
  
  Future<AuthResponse> verifySignUpOtp({
    required String email, 
    required String token
  }) async {
    return await _supabaseClient.auth.verifyOTP(
      type: OtpType.signup,
      token: token,
      email: email,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    return await _supabaseClient.auth.verifyOTP(
      type: OtpType.recovery,
      token: token,
      email: email,
    );
  }

  Future<UserResponse> updateUserPassword(String newPassword) async {
    return await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});