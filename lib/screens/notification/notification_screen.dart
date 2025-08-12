// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/models/notification_model.dart';
// Import both providers and the new detail screen
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/notification_provider.dart';
import 'package:memoir/screens/notification/notification_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart'; // Import for User type

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication status to decide which UI to build
    final User? currentUser = ref.watch(appProvider.select((s) => s.currentUser));

    // Based on auth status, build the appropriate body
    // Pass the currentUser variable down to the builder methods
    final Widget body = currentUser != null
        ? _buildAuthenticatedBody(context, ref, currentUser)
        : _buildUnauthenticatedBody(context, ref);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_outlined, size: 30),
        ),
        title: Text(
          currentUser != null ? 'Your Notifications' : 'Recent Announcements',
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }

  // --- WIDGET BUILDER FOR LOGGED-IN USERS ---
  // The method now accepts the currentUser
  Widget _buildAuthenticatedBody(BuildContext context, WidgetRef ref, User currentUser) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    if (notificationState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _buildBackground(context),
        if (notifications.isEmpty)
          const Center(child: Text("You have no notifications.", style: TextStyle(color: Colors.grey)))
        else
          ListView.builder(
            padding: EdgeInsets.only(top: topPadding, bottom: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () {
                  // Mark as read first
                  ref.read(notificationProvider.notifier).markNotificationAsRead(notification);

                  // Navigate to the detail screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailScreen(
                        notification: notification,
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // --- WIDGET BUILDER FOR GUEST/UNAUTHENTICATED USERS ---
  Widget _buildUnauthenticatedBody(BuildContext context, WidgetRef ref) {
    // Watch our new FutureProvider
    final publicNotificationsAsync = ref.watch(publicNotificationProvider);
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    return Stack(
      children: [
        _buildBackground(context),
        // Use .when() to handle the states of the FutureProvider
        publicNotificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(child: Text("No recent announcements.", style: TextStyle(color: Colors.grey)));
            }
            return ListView.builder(
              padding: EdgeInsets.only(top: topPadding, bottom: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () {
                    // For a guest, just navigate without trying to mark as read
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailScreen(
                          notification: notification,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- SHARED UI WIDGETS ---
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

// --- NOTIFICATION ITEM SUB-WIDGET (No changes needed) ---
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2D1F9), width: 2.0),
                  ),
                  child: Icon(notification.icon, size: 30, color: colorScheme.primary),
                ),
                if (!notification.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: !notification.isRead ? FontWeight.bold : FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    timeago.format(notification.timestamp),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}