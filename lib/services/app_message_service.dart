import 'package:memoir/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; 

/// A service dedicated to fetching and managing notifications from the backend (Supabase).
class AppMessageService {
  final _supabase = Supabase.instance.client;

  /// Fetches all notifications (global and specific) from Supabase for the current user.
  Future<List<AppNotification>> fetchAllNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final List<AppNotification> notifications = [];

    try {
      final globalRes = await _supabase
          .from('global_notifications')
          .select('*, user_read_notifications!inner(read_at)')
          .eq('user_read_notifications.user_id', userId);

      for (var n in globalRes) {
        try {
          final readStatusList = n['user_read_notifications'] as List<dynamic>? ?? [];
          bool isRead = false;
          if (readStatusList.isNotEmpty) {
            final readStatusData = readStatusList.first as Map<String, dynamic>?;
            if (readStatusData != null && readStatusData['read_at'] != null) {
              isRead = true;
            }
          }
          notifications.add(AppNotification(
            id: 'global_${n['id']}', remoteId: n['id'], type: NotificationType.global,
            title: n['title'], body: n['body'], timestamp: DateTime.parse(n['created_at']),
            isRead: isRead, icon: Icons.campaign,
          ));
        } catch (e) {
          print('Error parsing a single global notification: $e. Data: $n');
        }
      }

      final specificRes = await _supabase
          .from('user_specific_notifications')
          .select()
          .eq('user_id', userId);

      for (var n in specificRes) {
        notifications.add(AppNotification(
          id: 'specific_${n['id']}', remoteId: n['id'], type: NotificationType.feedback,
          title: n['title'], body: n['body'], timestamp: DateTime.parse(n['created_at']),
          isRead: n['read_at'] != null, icon: Icons.admin_panel_settings,
        ));
      }

      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    } catch (e) {
      print('Error fetching app messages: $e');
      rethrow;
    }
  }

  /// Marks a backend notification as read in the database.
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead || notification.remoteId == null) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      if (notification.type == NotificationType.global) {
        await _supabase.from('user_read_notifications').update({'read_at': now})
            .match({'user_id': userId, 'notification_id': ?notification.remoteId});
      } else if (notification.type == NotificationType.feedback) {
        await _supabase.from('user_specific_notifications').update({'read_at': now})
            .eq('id', notification.remoteId!);
      }
    } catch (e) {
      print("Error marking app message as read: $e");
    }
  }

  /// Fetches the latest public global notifications for unauthenticated users.
  Future<List<AppNotification>> fetchPublicNotifications() async {
    try {
      final response = await _supabase
          .from('global_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      
      return response.map<AppNotification>((n) => AppNotification(
        id: 'public_${n['id']}', remoteId: n['id'], type: NotificationType.global,
        title: n['title'], body: n['body'], timestamp: DateTime.parse(n['created_at']),
        isRead: true, // Guests can't have "unread" status
        icon: Icons.campaign,
      )).toList();
    } catch (e) {
      print('Error fetching public notifications: $e');
      return [];
    }
  }
}