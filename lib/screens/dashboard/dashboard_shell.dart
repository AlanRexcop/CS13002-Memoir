import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/feedback_provider.dart';

import 'dashboard_screen.dart';
import '../Notification_screen.dart';
import '../user/users_screen.dart';
import '../user/user_details_screen.dart';
import '../feedback/feedback_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Users',
    'Notification',
    'Bugs and Feedbacks',
  ];

  Widget _getScreen(
    int index,
    UserProvider userProvider,
    FeedbackProvider feedbackProvider,
  ) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        if (userProvider.viewingUserId != null) {
          return UserDetailsScreen(userId: userProvider.viewingUserId!);
        }
        return const UsersScreen();
      case 2:
        return const NotificationScreen();
      case 3:
        return const FeedbackScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // === Sidebar ===
          SizedBox(
            width: 288,
            height: 1024,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/dashboard_logo.png',
                  width: 229,
                  height: 75,
                ),
                const SizedBox(height: 50),
                navItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                navItem(
                  index: 1,
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Users',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                navItem(
                  index: 2,
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  label: 'Notification',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                navItem(
                  index: 3,
                  label: 'Bugs and\nFeedbacks',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                  customIcon: Image.asset(
                    'assets/images/bficon.png',
                    width: 36,
                    height: 36,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // === Main Area ===
          Expanded(
            child: Column(
              children: [
                // ==== HEADER BAR ====
                Container(
                  height: 72,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: title
                      Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      // Right: avatar + name + popup
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            context.read<AdminAuthProvider>().signOut();
                            Navigator.of(
                              context,
                            ).pushReplacementNamed('/login');
                          }
                        },
                        offset: const Offset(0, 50),
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                        ],
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                'assets/images/avatar.png',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Ethan Blake',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ==== CONTENT ====
                Expanded(
                  child: Consumer2<UserProvider, FeedbackProvider>(
                    builder: (context, userProvider, feedbackProvider, _) =>
                        _getScreen(
                          _selectedIndex,
                          userProvider,
                          feedbackProvider,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget navItem({
    required int index,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    IconData? selectedIcon,
    Widget? customIcon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? const Color(0xFF9DB2FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        width: double.infinity,
        child: Row(
          children: [
            customIcon ??
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 36,
                  color: Colors.black,
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 25,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
