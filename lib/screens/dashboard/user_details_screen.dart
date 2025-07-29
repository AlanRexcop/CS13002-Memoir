// lib/screens/dashboard/user_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the user data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserById(widget.userId);
    });
  }

  // Helper to format bytes into a readable string (KB, MB, GB)
  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and Title
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 20),
                  SizedBox(width: 8),
                  Text('Users Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Main content area
            Consumer<UserProvider>(
              builder: (context, provider, child) {
                // --- State Handling ---
                if (provider.isDetailLoading) {
                  return const Expanded(child: Center(child: CircularProgressIndicator()));
                }
                if (provider.detailError != null) {
                  return Expanded(child: Center(child: Text('Error: ${provider.detailError}')));
                }
                if (provider.selectedUserDetail == null) {
                  return const Expanded(child: Center(child: Text('No user data found.')));
                }
                // --- End State Handling ---

                final user = provider.selectedUserDetail!;
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.person, size: 80, color: Colors.white70),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('User ID:', _InfoPill(text: user.id.substring(0, 8), color: Colors.blue)),
                              _buildInfoRow('Account name:', _InfoPill(text: user.username, color: Colors.blue)),
                              _buildInfoRow('Email:', _InfoPill(text: user.email, color: Colors.blue)),
                              _buildInfoRow('Created At:', _InfoPill(text: DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt))),
                              _buildInfoRow('Last login:', user.lastSignInAt != null ? _InfoPill(text: DateFormat('yyyy-MM-dd HH:mm:ss').format(user.lastSignInAt!)) : const Text("Never")),
                              _buildInfoRow('Number of notes:', _InfoPill(text: user.fileCount.toString(), color: Colors.indigo[300])),
                              _buildInfoRow('Number of published notes:', _InfoPill(text: user.publicFileCount.toString(), color: Colors.green)),
                              // This is the row that was causing the error
                              _buildInfoRow(
                                'Storage used:',
                                _buildStorageIndicator(user.storageUsed, user.storageLimit),
                                expandValue: true, // THE FIX: This flag will wrap the pill in an Expanded widget
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // THE FIX IS HERE: Added an optional `expandValue` parameter.
  Widget _buildInfoRow(String label, Widget valueWidget, {bool expandValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 200, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          // If expandValue is true, wrap the widget in Expanded to give it a bounded width.
          if (expandValue)
            Expanded(child: valueWidget)
          else
            valueWidget,
        ],
      ),
    );
  }

  Widget _buildStorageIndicator(int used, int limit) {
    final double ratio = limit > 0 ? used / limit : 0.0;
    final String usedText = formatBytes(used, 2);
    final String limitText = formatBytes(limit, 2);

    return _InfoPill(
      text: '$usedText / $limitText',
      color: Colors.orange,
      progressBarValue: ratio,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final Color? color;
  final double? progressBarValue;

  const _InfoPill({required this.text, this.color, this.progressBarValue});

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? Colors.grey[300]!;
    final textColor = (progressBarValue == null && color != null) ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pillColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      // The Stack is what allows the text to be drawn on top of the progress bar
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Progress Bar
          if (progressBarValue != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progressBarValue!,
                minHeight: 25, // Set a height for the progress bar
                backgroundColor: Colors.transparent, // The container provides the transparent background
                valueColor: AlwaysStoppedAnimation<Color>(pillColor),
              ),
            ),
          // Foreground Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}