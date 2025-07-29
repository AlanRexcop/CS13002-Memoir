// lib/models/user_profile.dart
import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String username;
  final String email;
  final int storageUsed;
  final int storageLimit;
  final int fileCount;
  final int publicFileCount; // NEW: Added to match schema
  final DateTime createdAt;
  final DateTime? updatedAt;   // NEW: Added to match schema
  final DateTime? lastSignInAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.storageUsed,
    required this.storageLimit,
    required this.fileCount,
    required this.publicFileCount, // NEW
    required this.createdAt,
    this.updatedAt,             // NEW
    this.lastSignInAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['mail'], // Column name in 'profiles' table is 'mail'
      storageUsed: json['storage_used'] ?? 0,
      storageLimit: json['storage_limit'] ?? 0,
      fileCount: json['file_count'] ?? 0,
      publicFileCount: json['public_file_count'] ?? 0, // NEW
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['update_at'] != null ? DateTime.parse(json['update_at']) : null, // NEW
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'])
          : null,
    );
  }
}