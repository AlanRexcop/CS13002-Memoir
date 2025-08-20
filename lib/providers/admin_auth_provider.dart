// lib/providers/admin_auth_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  // ... (properties are unchanged) ...
  final AdminAuthService _authService;
  late final StreamSubscription<AuthState> _authStateSubscription;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  // --- NEW: State for downloaded admin avatar ---
  Uint8List? _avatarData;
  Uint8List? get avatarData => _avatarData;

  // ... (constructor and dispose are unchanged) ...
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


  /// --- MODIFIED: Performs login and fetches avatar by searching. ---
  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      final userMetadata = currentUser.appMetadata;
      final isAdmin = userMetadata['role'] == 'admin';

      if (!isAdmin) {
        await _authService.signOut();
        throw const AuthException('Access Denied: You do not have admin privileges.');
      }

      // Fetch and set admin avatar data using the search method.
      try {
        _avatarData = await _authService.findAndDownloadAdminAvatar(currentUser.id);
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