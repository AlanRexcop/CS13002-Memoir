import 'package:flutter/material.dart';
import 'dart:math';

class Tag extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;


  const Tag({
    super.key,
    required this.label,
    this.onDeleted,
  });

  Color _getColorFromString(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final random = Random(hash);
    final hue = random.nextDouble() * 360;
    final saturation = 0.8 + random.nextDouble() * 0.2;
    final lightness = 0.8 + random.nextDouble() * 0.2;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDeletable = onDeleted != null;
    final tagColor = _getColorFromString(label);

    return Container(
      padding: EdgeInsets.only(
        left: 8.0,
        right: isDeletable ? 4.0 : 8.0,
      ),
      decoration: BoxDecoration(
        // color: const Color(0xFFFFD6EB),
        color: tagColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isDeletable) ...[
            const SizedBox(width: 4.0),
            InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: onDeleted,
              child: Icon(
                Icons.close,
                size: 14,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}