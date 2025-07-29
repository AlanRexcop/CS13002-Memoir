// lib/services/user_management_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserManagementService {
  final SupabaseClient _supabase;

  UserManagementService(this._supabase);

  /// Fetches a list of all users for the main user table display.
  Future<List<UserProfile>> fetchUsers() async {
    final List<dynamic> data = await _supabase.rpc('admin_get_all_users');
    return data.map((item) => UserProfile.fromJson(item)).toList();
  }

  /// NEW: Fetches the detailed profile for a single user by their ID.
  ///
  /// This ensures the data is always fresh when viewing user details.
  Future<UserProfile> fetchUserById(String userId) async {
    final List<dynamic> data = await _supabase.rpc(
      'admin_get_user_by_id',
      params: {'p_user_id': userId},
    );

    if (data.isEmpty) {
      throw Exception('User not found');
    }
    // RPCs that return a SETOF table always return a list.
    // We expect only one item, so we take the first.
    return UserProfile.fromJson(data.first);
  }


  /// Deletes a list of users by their IDs.
  Future<void> deleteUsers(List<String> userIds) async {
    await _supabase.rpc('admin_delete_users', params: {'user_ids': userIds});
  }
}