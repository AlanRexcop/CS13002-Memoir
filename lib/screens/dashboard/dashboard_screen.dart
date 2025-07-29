import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import 'users_screen.dart';
import 'user_details_screen.dart'; // Make sure this is imported if you've created it

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1; // Default to Users

  Widget _getScreen(int index) {
    switch (index) {
      case 0: return const Center(child: Text("Dashboard"));
      case 1: return const UsersScreen();
      case 2: return const Center(child: Text("Notifications"));
      case 3: return const Center(child: Text("Bugs and Feedbacks"));
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
                  'assets/images/memoir_logo.png',
                  width: 48, // Control the size
                  height: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Memoir",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          Expanded(
            child: _getScreen(_selectedIndex),
          ),
        ],
      ),
    );
  }
}