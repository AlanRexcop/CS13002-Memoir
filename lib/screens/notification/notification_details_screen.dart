// lib/screens/dashboard/notification_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final String notificationId;
  const NotificationDetailsScreen({super.key, required this.notificationId});

  @override
  State<NotificationDetailsScreen> createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch details for this specific notification when the screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<NotificationProvider>()
          .fetchNotificationDetails(widget.notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.detailError != null) {
            return Center(child: Text('Error: ${provider.detailError}'));
          }
          if (provider.selectedNotificationDetail == null) {
            return const Center(child: Text('Notification not found.'));
          }

          final notification = provider.selectedNotificationDetail!;
          final createdAt = DateTime.parse(notification['created_at']);
          final formattedDate =
              DateFormat('MMM dd, yyyy, HH:mm').format(createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                InkWell(
                  onTap: () => provider.viewNotificationList(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Global Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Title and Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Full notification body rendered from Markdown
                MarkdownBody(
                  data: notification['body'],
                  selectable: true, // This makes the rendered text selectable
                  styleSheet: MarkdownStyleSheet(
                    // You can optionally style the markdown elements
                    p: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    h3: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}