import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationContent {
  final String text;
  final bool isBold;
  NotificationContent(this.text, {this.isBold = false});
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.chevron_left_outlined, size: 30,),
        ),
        title: Text(
          'Notification',
        ),
        centerTitle: true,
      ),

      body: OrientationBuilder(
        builder: (context, orientation) {
          final screenSize = MediaQuery.of(context).size;
          return Stack(
            children: [
              if (orientation == Orientation.portrait)
                _buildPortraitBackground(screenSize)
              else
                _buildLandscapeBackground(screenSize),

              ListView(
                // Padding để đẩy nội dung xuống dưới AppBar và thanh status
                padding: EdgeInsets.only(
                  top: appBarHeight + statusBarHeight + 16,
                  bottom: 16,
                ),
                children: const [
                  NotificationItem(
                    avatarIcon: Icons.person,
                    title: 'Software Update Available:  Version 1.2.4 of Memoir is available for download',
                    timeAgo: '1h ago',
                    trailingIcon: Icons.alarm,
                  ),
                  NotificationItem(
                    avatarIcon: Icons.admin_panel_settings,
                    title: 'Meeting Reminder: You have a meeting scheduled with SE team tomorrow at 2:30 PM',
                    timeAgo: '15 minute ago',
                  ),
                  NotificationItem(
                    avatarIcon: Icons.person,
                    title: 'Meeting Reminder: You have a meeting scheduled with SE team tomorrow at 2:30 PM',
                    timeAgo: '15 minute ago',
                  ),
                  NotificationItem(
                    avatarIcon: Icons.person,
                    title: 'Monthly Engagement Statistics: you have met a total of 100 new friends through our platform!',
                    timeAgo: '15 minute ago',
                    trailingIcon: Icons.alarm,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPortraitBackground(Size screenSize) {
    final screenWidth = screenSize.width;
    final circleOneSize = screenWidth * 1.15;
    final circleTwoSize = screenWidth * 0.95;
    final circleThreeSize = screenWidth * 0.9;

    return Stack(
      children: [
        Positioned(
          top: -circleOneSize * 0.45,
          left: -circleOneSize * 0.12,
          child: _buildCircle(circleOneSize),
        ),
        Positioned(
          top: -circleTwoSize * 0.1,
          right: -circleTwoSize * 0.4,
          child: _buildCircle(circleTwoSize),
        ),
        Positioned(
          bottom: -circleThreeSize * 0.3,
          left: -circleThreeSize * 0.4,
          child: _buildCircle(circleThreeSize),
        ),
      ],
    );
  }

  Widget _buildLandscapeBackground(Size screenSize) {
    final screenHeight = screenSize.height;
    final circleOneSize = screenHeight * 1.3;
    final circleTwoSize = screenHeight * 1.5;

    return Stack(
      children: [
        Positioned(
          top: -circleOneSize * 0.5,
          left: -circleOneSize * 0.2,
          child: _buildCircle(circleOneSize),
        ),
        Positioned(
          bottom: -circleTwoSize * 0.6,
          right: -circleTwoSize * 0.25,
          child: _buildCircle(circleTwoSize),
        ),
      ],
    );
  }

  Widget _buildCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF9F1FC),
        backgroundBlendMode: BlendMode.multiply,
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final IconData? avatarIcon;
  final String title;
  final String timeAgo;
  final IconData? trailingIcon;

  const NotificationItem({
    super.key,
    this.avatarIcon,
    required this.title,
    required this.timeAgo,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE2D1F9),
                width: 2.0,
              ),
            ),
            child: Icon(avatarIcon, size: 30, color: colorScheme.primary),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: trailingIcon != null
                ? Icon(trailingIcon, color: const Color(0xFF8E44AD), size: 30)
                : null,
          ),
        ],
      ),
    );
  }
}