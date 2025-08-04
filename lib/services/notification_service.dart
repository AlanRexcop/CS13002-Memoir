// lib/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  /// Fetches all global notifications from the database.
  Future<List<Map<String, dynamic>>> fetchGlobalNotifications() async {
    try {
      final response = await _supabase
          .from('global_notifications')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // It's good practice to handle potential errors
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Sends a new global notification.
  Future<void> sendGlobalNotification({
    required String title,
    required String body,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to send notifications.');
    }

    try {
      await _supabase.from('global_notifications').insert({
        'admin_id': currentUser.id,
        'title': title,
        'body': body,
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }
}