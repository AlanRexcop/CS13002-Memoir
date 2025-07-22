import 'package:flutter/material.dart';

class SettingGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingGroup({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 0.0),
      padding: const EdgeInsets.only(top: 5, bottom: 5) ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 35,
            color: colorScheme.secondary,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}