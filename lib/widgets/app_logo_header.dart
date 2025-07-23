import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogoHeader extends StatelessWidget {
  final String logoAsset;
  final String title;
  final double size;
  final Color textColor;
  final double spacing;

  const AppLogoHeader({
    super.key,
    required this.logoAsset,
    required this.title,
    required this.textColor,
    this.size = 30.0,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = size * 0.83;
    final double spacing = size * 0.27;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        SizedBox(
          height: size,
          width: size,
          child: Image.asset(logoAsset),
        ),
        SizedBox(width: spacing),

        // Title
        Text(
          title,
          style: GoogleFonts.baloo2(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}