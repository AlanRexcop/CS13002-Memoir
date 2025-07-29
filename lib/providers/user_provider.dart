// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_management_service.dart';

class UserProvider extends ChangeNotifier {
  final UserManagementService _userService;

  UserProvider(this._userService);

  // State for the main users list
  List<UserProfile> _users = [];
  List<UserProfile> get users => _users;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  final Set<String> _selectedUserIds = {};
  Set<String> get selectedUserIds => _selectedUserIds;

  // --- NEW: State to manage which view is active (list vs detail) ---
  String? _viewingUserId;
  String? get viewingUserId => _viewingUserId;

  // --- NEW: State for the user detail screen ---
  UserProfile? _selectedUserDetail;
  UserProfile? get selectedUserDetail => _selectedUserDetail;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailError;
  String? get detailError => _detailError;
  // --- End of new state ---

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _userService.fetchUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NEW: Methods to control the view state ---
  void viewUser(String userId) {
    _viewingUserId = userId;
    notifyListeners();
  }

  void viewUserList() {
    _viewingUserId = null;
    _selectedUserDetail = null; // Clear previously viewed user data
    _detailError = null;
    notifyListeners();
  }
  // --- End of new methods ---

  // --- NEW: Method to fetch a single user for the detail screen ---
  Future<void> fetchUserById(String userId) async {
    // Set the detail screen state to loading
    _isDetailLoading = true;
    _detailError = null;
    _selectedUserDetail = null; // Clear any previously viewed user
    notifyListeners();

    try {
      _selectedUserDetail = await _userService.fetchUserById(userId);
    } catch (e) {
      _detailError = e.toString();
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }
  // --- End of new method ---

  Future<void> deleteSelectedUsers() async {
     if (_selectedUserIds.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _userService.deleteUsers(_selectedUserIds.toList());
      // Refresh the list after deletion
      await fetchUsers();
      _selectedUserIds.clear();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleUserSelection(String userId) {
    if (_selectedUserIds.contains(userId)) {
      _selectedUserIds.remove(userId);
    } else {
      _selectedUserIds.add(userId);
    }
    notifyListeners();
  }

  void toggleSelectAll(bool? select, List<String> allVisibleUserIds) {
    if (select == true) {
      _selectedUserIds.addAll(allVisibleUserIds);
    } else {
      _selectedUserIds.clear();
    }
    notifyListeners();
  }
}