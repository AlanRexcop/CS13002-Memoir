// lib/providers/user_provider.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/user_management_service.dart';

class UserProvider extends ChangeNotifier {
  final UserManagementService _userService;

  UserProvider(this._userService);

  // State for the main users list
  List<UserProfile> _users = [];
  // List<UserProfile> get users => _users;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  final Set<String> _selectedUserIds = {};
  Set<String> get selectedUserIds => _selectedUserIds;

  // --- State to manage which view is active (list vs detail) ---
  String? _viewingUserId;
  String? get viewingUserId => _viewingUserId;

  // --- State for the user detail screen ---
  UserProfile? _selectedUserDetail;
  UserProfile? get selectedUserDetail => _selectedUserDetail;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailError;
  String? get detailError => _detailError;
  
  // --- NEW: State for downloaded user avatar ---
  Uint8List? _userDetailAvatar;
  Uint8List? get userDetailAvatar => _userDetailAvatar;

  bool _isAvatarLoading = false;
  bool get isAvatarLoading => _isAvatarLoading;

  // --- NEW: Search n filter ----
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool get isFilterActive => _filterStartDate != null || _filterEndDate != null;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  // getter for filtered users đc chuyển xuống đây 
  List<UserProfile> get users {
    List<UserProfile> filteredUsers = List.from(_users);

    // search by name or email
    if (_searchQuery.isNotEmpty) {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      filteredUsers = filteredUsers.where((user) {
        return user.username.toLowerCase().contains(lowerCaseQuery) ||
               user.email.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    // filter by start date
    if (_filterStartDate != null) {
      filteredUsers = filteredUsers.where((user) =>
        user.createdAt.isAtSameMomentAs(_filterStartDate!) || user.createdAt.isAfter(_filterStartDate!)
      ).toList();
    }
    // filter by end date
    if (_filterEndDate != null) {
      // Add 1 day to include the selected date
      final inclusiveEndDate = _filterEndDate!.add(const Duration(days: 1));
      filteredUsers = filteredUsers.where((user) =>
        user.createdAt.isBefore(inclusiveEndDate)
      ).toList();
    }

    return filteredUsers;
  }

  void searchUsers(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter({DateTime? start, DateTime? end}) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }
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

  // --- Methods to control the view state ---
  void viewUser(String userId) {
    _viewingUserId = userId;
    notifyListeners();
  }

  void viewUserList() {
    _viewingUserId = null;
    _selectedUserDetail = null; // Clear previously viewed user data
    _detailError = null;
    _userDetailAvatar = null; // Clear avatar data
    notifyListeners();
  }
  // --- End of new methods ---

  // --- Method to fetch a single user for the detail screen ---
  Future<void> fetchUserById(String userId) async {
    // Set the detail screen state to loading
    _isDetailLoading = true;
    _detailError = null;
    _selectedUserDetail = null; // Clear any previously viewed user
    _userDetailAvatar = null;   // Clear previous avatar
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
  
  // --- NEW: Method to download avatar for the detail screen ---
  Future<void> fetchUserAvatar(String userId) async {
    _isAvatarLoading = true;
    notifyListeners();
    try {
      _userDetailAvatar = await _userService.downloadAvatar(userId);
    } on StorageException {
      // It's okay if the user has no avatar, just ignore the error.
      _userDetailAvatar = null;
    } catch (e) {
      // Handle other potential errors if necessary
      _userDetailAvatar = null;
    } finally {
      _isAvatarLoading = false;
      notifyListeners();
    }
  }

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