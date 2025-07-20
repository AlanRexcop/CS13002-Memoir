import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback? onBackButtonPressed;

  const ProfileHeader({super.key, this.onBackButtonPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bgProfile.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

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

        Positioned(
          bottom: -55,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: AssetImage('assets/avatar.png')
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
      ],
    );
  }
}