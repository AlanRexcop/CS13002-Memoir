import 'package:flutter/material.dart';

// tags colors
const List<({Color background, Color foreground})> tagColorSchemes = [
    (background: Color(0xFFE0F2F1), foreground: Color(0xFF004D40)), // Teal
    (background: Color(0xFFFCE4EC), foreground: Color(0xFF880E4F)), // Pink
    (background: Color(0xFFE3F2FD), foreground: Color(0xFF0D47A1)), // Blue
    (background: Color(0xFFFFFDE7), foreground: Color(0xFFF57F17)), // Yellow
    (background: Color(0xFFF3E5F5), foreground: Color(0xFF4A148C)), // Purple
    (background: Color(0xFFE8F5E9), foreground: Color(0xFF1B5E20)), // Green
    (background: Color(0xFFFFF3E0), foreground: Color(0xFFE65100)), // Orange
    (background: Color(0xFFF1F8E9), foreground: Color(0xFF33691E)), // Light Green
  ];

/// Lấy một cặp màu nhất quán cho một tag dựa trên mã hash của nó
/// Điều này đảm bảo cùng một tag sẽ luôn có cùng một màu
({Color background, Color foreground}) getTagColors(String tag) {
  final hashCode = tag.hashCode;
  final index = hashCode.abs() % tagColorSchemes.length;
  return tagColorSchemes[index];
}

class Tag extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const Tag({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = backgroundColor ?? colorScheme.secondary;
    final fgColor = textColor ?? colorScheme.onSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: fgColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}