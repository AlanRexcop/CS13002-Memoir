// lib/providers/admin_auth_provider.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _authService;
  late final StreamSubscription<AuthState> _authStateSubscription;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  // --- NEW: State for downloaded admin avatar ---
  Uint8List? _avatarData;
  Uint8List? get avatarData => _avatarData;

  AdminAuthProvider(this._authService) {
    // This listener remains crucial. It updates the state when sign-in or
    // sign-out is successful.
    _authStateSubscription = _authService.authStateChanges.listen((data) {
      final session = data.session;
      _user = session?.user;
      // Clear avatar data on logout
      if (_user == null) {
        _avatarData = null;
      }
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
      await _authService.signIn(email, password);

      // Step 2: Post-login validation. Get the user object.
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      // Step 3: Check the user's metadata for the admin role.
      final userMetadata = currentUser.appMetadata;
      final isAdmin = userMetadata['role'] == 'admin';

      // Step 4: If the user is not an admin, deny access.
      if (!isAdmin) {
        await _authService.signOut();
        throw const AuthException('Access Denied: You do not have admin privileges.');
      }

      // --- NEW: Fetch and set admin avatar data ---
      try {
        _avatarData = await _authService.downloadAdminAvatar(currentUser.id);
      } on StorageException {
        // Ignore if avatar is not found.
        _avatarData = null;
      }
      notifyListeners();

    } on AuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}