// lib/services/notification_service.dart
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
      // After sending, refresh the list to show the new notification
      await fetchNotifications();
    } catch (e) {
      // In a real app, you might want to expose this error to the UI
      print('Failed to send notification: $e');
      throw Exception('Failed to send notification.');
    }
  }
}