// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, success, failure }

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AuthStatus status;
  final bool isSignUp;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.status = AuthStatus.initial,
    this.isSignUp = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthStatus? status,
    bool? isSignUp,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      isSignUp: isSignUp ?? this.isSignUp,
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
      state = state.copyWith(isLoading: false, status: AuthStatus.success, isSignUp: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.initial);
    try {
      await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, status: AuthStatus.success, isSignUp: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  void resetStatus() {
    state = state.copyWith(status: AuthStatus.initial, errorMessage: null, isSignUp: false);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});