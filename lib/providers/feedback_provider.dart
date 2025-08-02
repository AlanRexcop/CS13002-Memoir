// lib/providers/feedback_provider.dart
import 'package:flutter/material.dart';
import '../models/feedback_item.dart';
import '../models/user_profile.dart';
import '../services/feedback_service.dart';
import '../services/user_management_service.dart'; // Import the user service

class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _feedbackService;
  final UserManagementService _userService; // Add the user service dependency
  
  // Update the constructor to accept both services
  FeedbackProvider(this._feedbackService, this._userService);

  // --- State for the list view ---
  List<FeedbackItem> _feedbackItems = [];
  List<FeedbackItem> get feedbackItems => _feedbackItems;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  String _selectedStatus = 'unresolved';
  String get selectedStatus => _selectedStatus;

  // --- State for the detail view ---
  int? _viewingFeedbackId;
  int? get viewingFeedbackId => _viewingFeedbackId;
  FeedbackItem? _selectedFeedbackDetail;
  FeedbackItem? get selectedFeedbackDetail => _selectedFeedbackDetail;
  UserProfile? _selectedFeedbackUser;
  UserProfile? get selectedFeedbackUser => _selectedFeedbackUser;
  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;
  String? _detailError;
  String? get detailError => _detailError;
  
  Future<void> fetchFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _feedbackItems = await _feedbackService.fetchFeedback();
    } catch (e) {
      _error = 'Failed to load feedback: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(int feedbackId, String newStatus) async {
    try {
      await _feedbackService.updateFeedbackStatus(feedbackId, newStatus);
      final listIndex = _feedbackItems.indexWhere((item) => item.id == feedbackId);
      if (listIndex != -1) {
        _feedbackItems[listIndex] = _feedbackItems[listIndex].copyWith(status: newStatus);
      }
      if (_selectedFeedbackDetail?.id == feedbackId) {
        _selectedFeedbackDetail = _selectedFeedbackDetail?.copyWith(status: newStatus);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update status: ${e.toString()}');
    }
  }
  
  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void viewFeedback(int feedbackId) {
    _viewingFeedbackId = feedbackId;
    notifyListeners();
  }

  void viewFeedbackList() {
    _viewingFeedbackId = null;
    _selectedFeedbackDetail = null;
    _selectedFeedbackUser = null;
    _detailError = null;
    notifyListeners();
  }
  
  Future<void> fetchFeedbackDetails(int feedbackId) async {
    _isDetailLoading = true;
    _detailError = null;
    _selectedFeedbackDetail = null;
    _selectedFeedbackUser = null;
    notifyListeners();

    try {
      _selectedFeedbackDetail = await _feedbackService.fetchFeedbackById(feedbackId);

      if (_selectedFeedbackDetail?.userId != null) {
        // REUSE the existing method from the user service!
        _selectedFeedbackUser = await _userService.fetchUserById(_selectedFeedbackDetail!.userId!);
      }
    } catch (e) {
      _detailError = e.toString();
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }
}