// lib/providers/admin_auth_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _authService;
  late final StreamSubscription<AuthState> _authStateSubscription;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AdminAuthProvider(this._authService) {
    // This listener remains crucial. It updates the state when sign-in or
    // sign-out is successful.
    _authStateSubscription = _authService.authStateChanges.listen((data) {
      final session = data.session;
      _user = session?.user;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  /// Performs login and validates if the user has admin privileges.
  Future<void> signIn(String email, String password) async {
    try {
      // Step 1: Authenticate with Supabase as usual.
      // This will throw an AuthException for invalid credentials.
      await _authService.signIn(email, password);

      // Step 2: Post-login validation. Get the user object.
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        // This case is unlikely but good to handle.
        throw const AuthException('Login failed. Please try again.');
      }

      // Step 3: Check the user's metadata for the admin role.
      final userMetadata = currentUser.appMetadata;
      final isRolePresent = userMetadata.containsKey('role');
      final isAdmin = isRolePresent && userMetadata['role'] == 'admin';

      // Step 4: If the user is not an admin, deny access.
      if (!isAdmin) {
        // CRITICAL: Immediately sign the user out to invalidate their session.
        await _authService.signOut();
        // Throw a specific error to be displayed on the login screen.
        throw const AuthException('Access Denied: You do not have admin privileges.');
      }

      // If we reach here, the user is a valid admin. The onAuthStateChange
      // listener will handle setting the user and notifying widgets to rebuild.

    } on AuthException {
      // Re-throw any AuthException (e.g., "Invalid login credentials" or our custom one)
      // so the UI can catch it and display the message.
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}