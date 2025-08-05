import 'package:flutter/material.dart';
enum NotificationType { global, feedback, event }

class AppNotification {
  final String id; // A unique identifier for this notification
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final IconData icon;

  // Foreign key for updates, can be null for local notifications
  final String? remoteId; 

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.icon,
    this.remoteId,
  });
}