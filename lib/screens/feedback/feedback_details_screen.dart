// lib/screens/dashboard/feedback_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';

class FeedbackDetailsScreen extends StatefulWidget {
  final int feedbackId;
  const FeedbackDetailsScreen({super.key, required this.feedbackId});

  @override
  State<FeedbackDetailsScreen> createState() => _FeedbackDetailsScreenState();
}

class _FeedbackDetailsScreenState extends State<FeedbackDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the details for this specific feedback item when the screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackProvider>().fetchFeedbackDetails(widget.feedbackId);
    });
  }

  // Helper to get a relative time string like "5 days ago"
  String _getRelativeTime(DateTime dt) {
    final difference = DateTime.now().difference(dt);
    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours == 1) {
      return '1 hour ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<FeedbackProvider>(
        builder: (context, provider, child) {
          if (provider.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.detailError != null) {
            return Center(child: Text('Error: ${provider.detailError}'));
          }
          if (provider.selectedFeedbackDetail == null) {
            return const Center(child: Text('Feedback item not found.'));
          }

          final feedback = provider.selectedFeedbackDetail!;
          final user =
              provider.selectedFeedbackUser; // Can be null if user was deleted
          final formattedDate = DateFormat(
            'MMM dd, yyyy, HH:mm',
          ).format(feedback.sendDate);
          final relativeTime = _getRelativeTime(feedback.sendDate);

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
                  onTap: () => provider.viewFeedbackList(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      // This title could be dynamic, but for now it's static
                      Text(
                        'System Notification',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Title and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feedback.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Chip(
                      label: Text(
                        feedback.status,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User Info and Date
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: user != null
                          ? const Icon(Icons.person, color: Colors.grey)
                          // Show a different icon if the user is deleted
                          : const Icon(Icons.person_off, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Deleted User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          feedback.userEmail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '$formattedDate ($relativeTime)',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Full text content
                SelectableText(
                  feedback.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // OutlinedButton.icon(
                    //   onPressed: () {
                    //     /* TODO: Implement Reply Logic */
                    //   },
                    //   icon: const Icon(Icons.reply),
                    //   label: const Text('Reply'),
                    //   style: OutlinedButton.styleFrom(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 24,
                    //       vertical: 16,
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(width: 16),
                    const Text(
                      'Change Status:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      initialValue: feedback.status,
                      onSelected: (String newValue) {
                        if (newValue != feedback.status) {
                          context.read<FeedbackProvider>().updateStatus(
                                feedback.id,
                                newValue,
                              );
                        }
                      },
                      position: PopupMenuPosition.under,
                      offset: const Offset(0, 4),
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxHeight: 200,
                      ),
                      itemBuilder: (context) => [
                        'pending',
                        'in_progress', 
                        'resolved',
                        'closed'
                      ].map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              color: status == feedback.status
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                              fontWeight: status == feedback.status
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ).toList(),
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              feedback.status,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}