// lib/models/feedback_item.dart
import 'package:flutter/foundation.dart';

@immutable
class FeedbackItem {
  final int id;
  final String title;
  final String text;
  final String? tag;
  final String status;
  final DateTime sendDate;
  final String? userId;
  final String userEmail;
  final bool isUserDeleted;

  const FeedbackItem({
    required this.id,
    required this.title,
    required this.text,
    this.tag,
    required this.status,
    required this.sendDate,
    this.userId,
    required this.userEmail,
    required this.isUserDeleted,
  });

  // Factory constructor to create a FeedbackItem from a JSON object (from Supabase)
  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      tag: json['tag'],
      status: json['status'],
      sendDate: DateTime.parse(json['send_date']),
      userId: json['user_id'],
      userEmail: json['user_email'],
      isUserDeleted: json['is_user_deleted'] ?? false,
    );
  }

  // A helper method to create a copy of this instance with some new values.
  // This is useful for updating the state in the provider immutably.
  FeedbackItem copyWith({
    String? status,
  }) {
    return FeedbackItem(
      id: id,
      title: title,
      text: text,
      tag: tag,
      status: status ?? this.status,
      sendDate: sendDate,
      userId: userId,
      userEmail: userEmail,
      isUserDeleted: isUserDeleted,
    );
  }
}