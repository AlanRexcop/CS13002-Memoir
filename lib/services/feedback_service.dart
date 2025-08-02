// lib/services/feedback_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback_item.dart';
// No longer need to import UserProfile here

class FeedbackService {
  final SupabaseClient _supabase;

  FeedbackService(this._supabase);

  /// Fetches all feedback items from the database.
  Future<List<FeedbackItem>> fetchFeedback() async {
    final List<dynamic> data = await _supabase
        .from('user_feedback')
        .select()
        .order('send_date', ascending: false);
    
    return data.map((item) => FeedbackItem.fromJson(item)).toList();
  }

  /// Updates the status of a specific feedback item.
  Future<void> updateFeedbackStatus(int id, String newStatus) async {
    await _supabase
        .from('user_feedback')
        .update({'status': newStatus})
        .eq('id', id);
  }

  /// Fetches the details for a single feedback item by its ID.
  Future<FeedbackItem> fetchFeedbackById(int feedbackId) async {
    final data = await _supabase
        .from('user_feedback')
        .select()
        .eq('id', feedbackId)
        .single();

    return FeedbackItem.fromJson(data);
  }
  
}