// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool signUpSuccess;
  final bool signInSuccess;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.signUpSuccess = false,
    this.signInSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? signUpSuccess,
    bool? signInSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Explicitly set to null if not provided
      signUpSuccess: signUpSuccess ?? this.signUpSuccess,
      signInSuccess: signInSuccess ?? this.signInSuccess,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(AuthState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, signInSuccess: false);
    try {
      await _authRepository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, signInSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, signUpSuccess: false);
    try {
      await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, signUpSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
    }
  }

  void clearMessageFlags() {
    state = state.copyWith(errorMessage: null, signUpSuccess: false, signInSuccess: false);
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepository);
});