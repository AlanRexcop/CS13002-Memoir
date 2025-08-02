// lib/providers/feedback_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/services/feedback_service.dart';

enum FeedbackStatus { initial, loading, success, failure }

class FeedbackState {
  final FeedbackStatus status;
  final String? errorMessage;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.errorMessage,
  });

  FeedbackState copyWith({
    FeedbackStatus? status,
    String? errorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  final FeedbackService _feedbackService;

  FeedbackNotifier(this._feedbackService) : super(const FeedbackState());

  Future<void> submitFeedback({
    required String title,
    required String text,
    String? tag,
  }) async {
    state = state.copyWith(status: FeedbackStatus.loading);
    try {
      await _feedbackService.submitFeedback(
        title: title,
        text: text,
        tag: tag,
      );
      state = state.copyWith(status: FeedbackStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: FeedbackStatus.failure,
        errorMessage: 'Failed to submit feedback. Please try again.',
      );
    }
  }

  // Resets the state to initial, useful after a submission attempt.
  void resetState() {
    state = const FeedbackState();
  }
}

final feedbackNotifierProvider =
    StateNotifierProvider<FeedbackNotifier, FeedbackState>((ref) {
  final feedbackService = ref.watch(feedbackServiceProvider);
  return FeedbackNotifier(feedbackService);
});