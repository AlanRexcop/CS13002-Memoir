import 'package:flutter/material.dart';


class SettingItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Function() onTap;
  final Color backgroundColor;

  const SettingItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.backgroundColor = const Color(0x80DFD5E7),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary,),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
            ),
            Icon(Icons.chevron_right_outlined, size: 26,)
          ],
        ),
      ),
    );
  }
}