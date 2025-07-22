import 'package:flutter/material.dart';



class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle),
            child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24
            ),
          ),
          const SizedBox(width: 20),
          Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
              )
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.primary
            ),
          ),
        ],
      ),
    );
  }
}