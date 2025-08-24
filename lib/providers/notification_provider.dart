// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider(this._notificationService) {
    // Load notifications when the provider is initialized
    fetchNotifications();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  // --- ADDED PROPERTIES FOR DETAIL VIEW ---

  // Holds the ID of the selected notification to show the detail screen
  dynamic _selectedNotificationId; // Use `dynamic` to support int or String IDs
  dynamic get selectedNotificationId => _selectedNotificationId;

  // Holds the data for the detailed view
  Map<String, dynamic>? _selectedNotificationDetail;
  Map<String, dynamic>? get selectedNotificationDetail => _selectedNotificationDetail;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailError;
  String? get detailError => _detailError;

  // --- END OF ADDED PROPERTIES ---

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.fetchGlobalNotifications();
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _notificationService.sendGlobalNotification(
        title: title,
        body: body,
      );
      // Refresh the list after sending a new notification
      await fetchNotifications();
    } catch (e) {
      // In a real app, you might want to expose this error to the UI
      print('Failed to send notification: $e');
      throw Exception('Failed to send notification.');
    }
  }

  /// Sets the selected notification ID to trigger the navigation to the detail view.
  void selectNotification(dynamic id) {
    _selectedNotificationId = id;
    // Clear previous details and errors to avoid showing stale data
    _selectedNotificationDetail = null;
    _detailError = null;
    notifyListeners();
  }

  /// Clears the selected notification ID to navigate back to the list view.
  void viewNotificationList() {
    _selectedNotificationId = null;
    _selectedNotificationDetail = null;
    notifyListeners();
  }

  /// Fetches the data for a single notification by its ID.
  Future<void> fetchNotificationDetails(dynamic id) async {
    _isDetailLoading = true;
    _detailError = null;
    notifyListeners();

    try {
      // In a real app, you would make a specific API call here:
      // _selectedNotificationDetail = await _notificationService.fetchNotificationById(id);

      // For now, we'll find the notification in the existing list.
      // This is efficient if the list is already loaded and complete.
      _selectedNotificationDetail = _notifications.firstWhere(
        (notification) => notification['id'] == id,
        orElse: () => throw Exception('Notification not found in the list.'),
      );
    } catch (e) {
      _detailError = "Failed to load notification details: ${e.toString()}";
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }
}