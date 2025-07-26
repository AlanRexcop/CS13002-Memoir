// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, success, failure, otpSent, awaitingVerification, otpVerified }

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AuthStatus status;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.status = AuthStatus.initial,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthStatus? status,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      await _authRepository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        username: username,
      );
      state = state.copyWith(isLoading: false, status: AuthStatus.awaitingVerification);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> verifySignUp({required String email, required String token}) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.awaitingVerification);
    try {
      await _authRepository.verifySignUpOtp(email: email, token: token);
      state = state.copyWith(isLoading: false, status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false, status: AuthStatus.otpSent);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> verifyPasswordResetOtp({required String email, required String token}) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      await _authRepository.verifyRecoveryOtp(email: email, token: token);
      state = state.copyWith(isLoading: false, status: AuthStatus.otpVerified);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }
  
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      //Verify the old password by trying to sign in with it again.
      final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
      if (currentUserEmail == null) {
        throw const AuthException('Not authenticated. Please sign in again.');
      }
      
      await _authRepository.signInWithEmailPassword(
        email: currentUserEmail, 
        password: oldPassword
      );

      //If the sign-in was successful, update the user's password to the new one.
      await _authRepository.updateUserPassword(newPassword);

      state = state.copyWith(isLoading: false, status: AuthStatus.success);
    } on AuthException catch (e) {
      final errorMessage = e.message.contains('Invalid login credentials') 
        ? 'The old password you entered is incorrect.' 
        : e.message;
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> setNewPassword(String newPassword) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      await _authRepository.updateUserPassword(newPassword);
      state = state.copyWith(isLoading: false, status: AuthStatus.success);
    } on AuthException catch (e) {
       state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  void resetStatus() {
    state = state.copyWith(status: AuthStatus.initial, errorMessage: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});