import 'package:flutter/material.dart';

class UserInfoSection extends StatelessWidget {
  final String name;
  final String email;

  const UserInfoSection({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 70, left: 20, right: 20),
      child: Column(
        children: [
          Text(
            name,
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
    );
  }
}