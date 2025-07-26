// lib/screens/account_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/screens/change_password_screen.dart'; // Import the new screen
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider to fetch user profile data asynchronously
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(appProvider).currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  final cloudService = ref.read(cloudFileServiceProvider);
  return cloudService.fetchUserProfile(user.id);
});

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await ref.read(appProvider.notifier).signOut();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Out Error: ${e.message}')),
        );
      }
    } catch (e, stackTrace) {
      log('An unexpected error occurred during sign out:', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    if (decimals < 0) decimals = 0;
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = 0;
    double dBytes = bytes.toDouble();

    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }

    return '${dBytes.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appProvider).currentUser;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userProfileProvider),
          )
        ],
      ),
      body: Stack(
        children: [
          if (user != null)
            profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading profile: $err')),
              data: (profileData) {
                final username = profileData['username'] as String? ?? 'N/A';
                final storageUsed = profileData['storage_used'] as int? ?? 0;
                final storageLimit = profileData['storage_limit'] as int? ?? 1; 
                final fileCount = profileData['file_count'] as int? ?? 0;
                
                final createdAtStr = profileData['created_at'] as String?;
                final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : null;
                
                final lastSignInStr = profileData['last_sign_in_at'] as String?;
                final lastSignIn = lastSignInStr != null ? DateTime.parse(lastSignInStr) : null;

                final storagePercentage = (storageUsed / storageLimit).clamp(0.0, 1.0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoTile('Username', username),
                      _buildInfoTile('Email Address', user.email ?? 'N/A'),
                      const Divider(height: 30),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ));
                        },
                      ),
                      const Divider(height: 30),

                      const Text('Cloud Storage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: storagePercentage,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatBytes(storageUsed, 2)} of ${_formatBytes(storageLimit, 0)} used',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fileCount files',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Divider(height: 30),
                      
                      _buildInfoTile('Member Since', createdAt != null ? DateFormat.yMMMd().format(createdAt) : 'N/A'),
                      _buildInfoTile('Last Sign In', lastSignIn != null ? DateFormat.yMMMd().add_jm().format(lastSignIn.toLocal()) : 'N/A'),
                      _buildInfoTile('User ID', user.id, isSelectable: true),
                      const SizedBox(height: 40),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40)
                        ),
                        onPressed: _isSigningOut ? null : _signOut,
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
            )
          else 
             const Center(child: Text('Not signed in.')),
          
          if (_isSigningOut)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          isSelectable
              ? SelectableText(value, style: const TextStyle(fontSize: 16))
              : Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}