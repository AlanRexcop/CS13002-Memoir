import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const Tag({
    super.key,
    required this.label,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDeletable = onDeleted != null;

    return Container(
      padding: EdgeInsets.only(
        left: 8.0,
        right: isDeletable ? 4.0 : 8.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD6EB),
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