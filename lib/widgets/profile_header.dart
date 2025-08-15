// C:\dev\memoir\lib\widgets\profile_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/cloud_provider.dart';

class ProfileHeader extends ConsumerWidget {
  final VoidCallback? onBackButtonPressed;
  final VoidCallback? onAvatarEditPressed;
  final VoidCallback? onBackgroundEditPressed;
  final String username; // Now required
  final String email;    // Now required

  const ProfileHeader({
    super.key,
    this.onBackButtonPressed,
    this.onAvatarEditPressed,
    this.onBackgroundEditPressed,
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarAsync = ref.watch(localAvatarProvider);
    final backgroundAsync = ref.watch(localBackgroundProvider);

    final avatarImage = avatarAsync.when(
      data: (bytes) => (bytes != null)
          ? MemoryImage(bytes) as ImageProvider
          : const AssetImage('assets/avatar.png'),
      loading: () => const AssetImage('assets/avatar.png'),
      error: (_, __) => const AssetImage('assets/avatar.png'),
    );

    final backgroundImage = backgroundAsync.when(
      data: (bytes) => (bytes != null)
          ? MemoryImage(bytes) as ImageProvider
          : const AssetImage('assets/bgProfile.png'),
      loading: () => const AssetImage('assets/bgProfile.png'),
      error: (_, __) => const AssetImage('assets/bgProfile.png'),
    );

    return SizedBox(
      // We need to give the SizedBox a height that encompasses all elements,
      // including the positioned avatar and the text below it.
      height: 200 + 55 + 60, // Background Height + Avatar Overhang + Text Section
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Background Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: onBackButtonPressed,
              ),
            )
          ),
          
          // Edit Background Button
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
                onPressed: onBackgroundEditPressed,
                tooltip: 'Change background image',
              ),
            ),
          ),

          // Avatar and Edit Button
          Positioned(
            top: 200 - 60, // Position avatar so it's centered on the edge
            child: GestureDetector(
              onTap: onAvatarEditPressed,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: avatarImage,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white,
                          width: 3),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 15
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User Info Section (moved inside the stack)
          Positioned(
            top: 200 + 65, // Position below the avatar
            child: Column(
              children: [
                Text(
                  username,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.primary
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}