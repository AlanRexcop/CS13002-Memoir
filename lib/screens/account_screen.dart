// C:\dev\memoir\lib\screens\account_screen.dart
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/screens/change_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/info_item.dart';
import '../widgets/profile_header.dart';
import '../widgets/storage_info.dart';
import '../widgets/user_info_section.dart';

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
  bool _isUploadingAvatar = false;

  // Sign out logic from Alan's branch
  Future<void> _signOut() async {
    setState(() { _isSigningOut = true; });
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
        setState(() { _isSigningOut = false; });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    setState(() { _isUploadingAvatar = true; });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        // The notifier now handles invalidation via the version provider
        final success = await ref.read(cloudNotifierProvider.notifier).uploadAvatar(imageFile);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avatar updated successfully!')),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ref.read(cloudNotifierProvider).errorMessage ?? 'Avatar upload failed.')),
            );
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while picking image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploadingAvatar = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appProvider).currentUser;
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (user == null)
            const Center(child: Text('Not signed in.'))
          else
            profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading profile: $err')),
              data: (profileData) {
                // Extract real data from the provider
                final username = profileData['username'] as String? ?? 'N/A';
                final storageUsed = profileData['storage_used'] as int? ?? 0;
                final storageLimit = profileData['storage_limit'] as int? ?? 1;
                final createdAtStr = profileData['created_at'] as String?;
                final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : null;
                final lastSignInStr = profileData['last_sign_in_at'] as String?;
                final lastSignIn = lastSignInStr != null ? DateTime.parse(lastSignInStr) : null;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ProfileHeader(
                        onAvatarEditPressed: _pickAndUploadAvatar,
                        onBackButtonPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      UserInfoSection(
                        name: username, // Use real data
                        email: user.email ?? 'N/A', // Use real data
                      ),
                      const SizedBox(height: 20),

                      InfoItem(
                        icon: Icons.key_sharp,
                        label: 'Account type',
                        value: 'Authenticated'
                      ),
                      InfoItem(
                        icon: Icons.calendar_month,
                        label: 'Joined on',
                        value: createdAt != null ? DateFormat.yMMMd().format(createdAt) : 'N/A'
                      ),
                      InfoItem(
                        icon: Icons.access_time,
                        label: 'Last active',
                        value: lastSignIn != null ? DateFormat.yMMMd().add_jm().format(lastSignIn.toLocal()) : 'N/A'
                      ),
                      // Use the new data-driven StorageInfo widget
                      StorageInfo(
                        usedStorage: storageUsed,
                        storageLimit: storageLimit,
                      ),

                      // Functional buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch,
                           children: [
                              OutlinedButton.icon(
                                icon: Icon(Icons.lock_outline, color: colorScheme.primary),
                                label: Text('Change Password', style: TextStyle(color: colorScheme.primary)),
                                style: OutlinedButton.styleFrom(side: BorderSide(color: colorScheme.primary)),
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const ChangePasswordScreen(),
                                  ));
                                },
                              ),
                             const SizedBox(height: 16),
                             ElevatedButton.icon(
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign Out'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isSigningOut ? null : _signOut,
                              ),
                           ],
                        ),
                      ),
                       const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),

          if (_isSigningOut || _isUploadingAvatar)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}