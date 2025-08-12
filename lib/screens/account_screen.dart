// C:\dev\memoir\lib\screens\account_screen.dart
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/image_gallery_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/screens/change_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../widgets/info_item.dart';
import '../widgets/profile_header.dart';
import '../widgets/storage_info.dart';
// import '../widgets/user_info_section.dart'; // No longer needed

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
  bool _isUploadingBackground = false;

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
      // Navigate to the image gallery to select an image
      final relativePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const ImageGalleryScreen(purpose: ScreenPurpose.select),
        ),
      );

      if (relativePath != null && mounted) {
        // Get the absolute path of the selected image file
        final vaultRoot = ref.read(appProvider).storagePath;
        if (vaultRoot == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage path not set. Cannot upload avatar.')),
          );
          return;
        }
        final imageFile = File(p.join(vaultRoot, relativePath));
        
        if (!await imageFile.exists() && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image file not found.')),
          );
          return;
        }

        // Upload the avatar
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
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploadingAvatar = false; });
      }
    }
  }

  Future<void> _pickAndUploadBackground() async {
    if (_isUploadingBackground) return;

    setState(() { _isUploadingBackground = true; });

    try {
      // Navigate to the image gallery to select an image
      final relativePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const ImageGalleryScreen(purpose: ScreenPurpose.select),
        ),
      );

      if (relativePath != null && mounted) {
        // Get the absolute path of the selected image file
        final vaultRoot = ref.read(appProvider).storagePath;
        if (vaultRoot == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage path not set. Cannot upload background.')),
          );
          return;
        }
        final imageFile = File(p.join(vaultRoot, relativePath));
        
        if (!await imageFile.exists() && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image file not found.')),
          );
          return;
        }

        // Upload the background
        final success = await ref.read(cloudNotifierProvider.notifier).uploadBackground(imageFile);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Background updated successfully!')),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ref.read(cloudNotifierProvider).errorMessage ?? 'Background upload failed.')),
            );
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploadingBackground = false; });
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
                        username: username,
                        email: user.email ?? 'N/A',
                        onAvatarEditPressed: _pickAndUploadAvatar,
                        onBackgroundEditPressed: _pickAndUploadBackground,
                        onBackButtonPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      // UserInfoSection has been moved into ProfileHeader
                      // const SizedBox(height: 20), // This spacing is now controlled by ProfileHeader

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

          if (_isSigningOut || _isUploadingAvatar || _isUploadingBackground)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}