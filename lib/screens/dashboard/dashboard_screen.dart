// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/feedback_provider.dart'; // Import feedback provider
import 'users_screen.dart';
import 'user_details_screen.dart';
import 'feedback_screen.dart'; // Import feedback screen
import 'feedback_details_screen.dart'; // Import feedback details screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1; // Default to Users

  // UPDATED: The function now takes both providers to determine the correct view
  Widget _getScreen(int index, UserProvider userProvider, FeedbackProvider feedbackProvider) {
    switch (index) {
      case 0: return const Center(child: Text("Dashboard"));
      case 1:
        // User list or detail view
        if (userProvider.viewingUserId != null) {
          return UserDetailsScreen(userId: userProvider.viewingUserId!);
        }
        return const UsersScreen();
      case 2: return const Center(child: Text("Notifications"));
      case 3: 
        // Feedback list or detail view
        if (feedbackProvider.viewingFeedbackId != null) {
          return FeedbackDetailsScreen(feedbackId: feedbackProvider.viewingFeedbackId!);
        }
        return const FeedbackScreen();
      default: return const UsersScreen();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/memoir_logo.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Memoir",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
              ],
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
              NavigationRailDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: Text('Notification')),
              // Note: The icon is bug_report but the label matches your screenshot
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Bugs ands Feedbacks')),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      context.read<AdminAuthProvider>().signOut();
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          // UPDATED: Use Consumer2 to listen to both providers
          Expanded(
            child: Consumer2<UserProvider, FeedbackProvider>(
              builder: (context, userProvider, feedbackProvider, _) => _getScreen(_selectedIndex, userProvider, feedbackProvider),
            ),
          ),
        ],
      ),
    );
  }
}