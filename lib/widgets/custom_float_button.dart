import 'package:flutter/material.dart';

class CustomFloatButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Function() onTap;
  const CustomFloatButton({
    super.key,
    this.tooltip = '',
    required this.icon,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: onTap,
      tooltip: tooltip,
      backgroundColor: colorScheme.secondary,
      // shape: CircleBorder(
      //   side: BorderSide(
      //     color: colorScheme.primary,
      //     width: 4.0,
      //   ),
      // ),
      shape: CircleBorder(),
      child: Icon(
        icon,
        color: colorScheme.primary,
        size: 36,
      ),
    );
  }
}
