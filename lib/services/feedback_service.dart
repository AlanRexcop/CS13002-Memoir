// lib/services/feedback_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  final SupabaseClient _supabaseClient;

  FeedbackService(this._supabaseClient);

  /// Submits user feedback by calling the 'submit_user_feedback' RPC function.
  ///
  /// This is the preferred method as it's more secure. The database function
  /// handles setting the user_id and user_email on the server-side.
  Future<void> submitFeedback({
    required String title,
    required String text,
    String? tag,
  }) async {
    try {
      await _supabaseClient.rpc('submit_user_feedback', params: {
        'p_title': title,
        'p_text': text,
        'p_tag': tag,
      });
    } catch (e) {
      // Re-throw the exception to be caught by the notifier
      rethrow;
    }
  }
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(Supabase.instance.client);
});