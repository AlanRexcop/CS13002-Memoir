// lib/models/notification_item.dart

class GlobalNotification {
  final String id;
  final String adminId;
  final String title;
  final String body;
  final DateTime createdAt;

  GlobalNotification({
    required this.id,
    required this.adminId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory GlobalNotification.fromJson(Map<String, dynamic> json) {
    return GlobalNotification(
      id: json['id'],
      adminId: json['admin_id'],
      title: json['title'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}