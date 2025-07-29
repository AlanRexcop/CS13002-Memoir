// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/user_provider.dart';
import 'users_screen.dart';
import 'user_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1; // Default to Users

  // The UserProvider now determines if we show the list or details.
  Widget _getScreen(int index, UserProvider userProvider) {
    switch (index) {
      case 0: return const Center(child: Text("Dashboard"));
      case 1:
        // If a user ID is being viewed, show the details screen.
        if (userProvider.viewingUserId != null) {
          return UserDetailsScreen(userId: userProvider.viewingUserId!);
        }
        // Otherwise, show the list of users.
        return const UsersScreen();
      case 2: return const Center(child: Text("Notifications"));
      case 3: return const Center(child: Text("Bugs and Feedbacks"));
      // Default to the users list view.
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
            // --- LOGO IS ADDED HERE ---
            leading: Column(
              children: [
                const SizedBox(height: 20),
                // Use the Image.asset widget
                Image.asset(
                  'assets/images/memoir_logo.png', // Logo path
                  width: 100,  // Increased size for better visibility
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
            // --- END OF LOGO SECTION ---
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
              NavigationRailDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: Text('Notification')),
              NavigationRailDestination(icon: Icon(Icons.bug_report_outlined), selectedIcon: Icon(Icons.bug_report), label: Text('Bugs')),
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
          // Use a Consumer to rebuild this part when the view state changes
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) => _getScreen(_selectedIndex, userProvider),
            ),
          ),
        ],
      ),
    );
  }
}