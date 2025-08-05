import 'package:flutter/material.dart';
// Import the markdown_widget package
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/notification_model.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_outlined, size: 30, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, topPadding + 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/Logo.png',
                    height: 60,
                    width: 60,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  notification.title,
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),

                // --- WIDGET REPLACEMENT START (CORRECTED) ---
                MarkdownWidget(
                  data: notification.body,
                  // --- FIX FOR THE LAYOUT ERROR ---
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // --- END OF FIX ---
                  config: MarkdownConfig(
                    configs: [
                      PConfig(
                        textStyle: GoogleFonts.roboto(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                      H1Config(
                        style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      H2Config(
                        style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      H3Config(
                        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
                // --- WIDGET REPLACEMENT END ---
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BACKGROUND WIDGETS (Unchanged) ---
  Widget _buildBackground(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      return _buildPortraitBackground(screenSize);
    } else {
      return _buildLandscapeBackground(screenSize);
    }
  }

  Widget _buildPortraitBackground(Size screenSize) {
    final screenWidth = screenSize.width;
    final circleOneSize = screenWidth * 1.15;
    final circleTwoSize = screenWidth * 0.95;
    final circleThreeSize = screenWidth * 0.9;

    return Stack(children: [
      Positioned(top: -circleOneSize * 0.45, left: -circleOneSize * 0.12, child: _buildCircle(circleOneSize)),
      Positioned(top: -circleTwoSize * 0.1, right: -circleTwoSize * 0.4, child: _buildCircle(circleTwoSize)),
      Positioned(bottom: -circleThreeSize * 0.3, left: -circleThreeSize * 0.4, child: _buildCircle(circleThreeSize)),
    ]);
  }

  Widget _buildLandscapeBackground(Size screenSize) {
    final screenHeight = screenSize.height;
    final circleOneSize = screenHeight * 1.3;
    final circleTwoSize = screenHeight * 1.5;

    return Stack(children: [
      Positioned(top: -circleOneSize * 0.5, left: -circleOneSize * 0.2, child: _buildCircle(circleOneSize)),
      Positioned(bottom: -circleTwoSize * 0.6, right: -circleTwoSize * 0.25, child: _buildCircle(circleTwoSize)),
    ]);
  }

  Widget _buildCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF9F1FC),
        backgroundBlendMode: BlendMode.multiply,
      ),
    );
  }
}