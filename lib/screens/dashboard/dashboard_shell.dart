// lib/screens/dashboard/dashboard_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../providers/notification_provider.dart';

import '../feedback/feedback_details_screen.dart';
import 'dashboard_screen.dart';
import '../notification/Notification_screen.dart';
import '../notification/Notification_details_screen.dart';
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
    NotificationProvider notificationProvider, // Added provider
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
        // Added logic to switch between list and detail view
        if (notificationProvider.selectedNotificationId != null) {
          return NotificationDetailsScreen(
            notificationId: notificationProvider.selectedNotificationId!,
          );
        }
        return const NotificationScreen();
      case 3:
        if (feedbackProvider.viewingFeedbackId != null) {
          return FeedbackDetailsScreen(
            feedbackId: feedbackProvider.viewingFeedbackId!,
          );
        }
        return const FeedbackScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Row(
        children: [
          // === Sidebar ===
          SizedBox(
            width: 288,
            height: 1024,
            child: Container(
              color: Colors.white,
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
                    icon: Icons.bug_report_outlined,
                    selectedIcon: Icons.bug_report,
                    label: 'Bugs and\nFeedbacks',
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  const Spacer(),
                ],
              ),
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

                      Row(
                        children: [
                          // Avatar + Admin text (KHÔNG trigger popup)
                          Consumer<AdminAuthProvider>(
                            builder: (context, authProvider, _) {
                              final avatarData = authProvider.avatarData;
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: avatarData != null
                                        ? MemoryImage(avatarData)
                                        : null,
                                    child: avatarData == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 25,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              );
                            },
                          ),

                          // Popup chỉ hiện khi click vào tam giác ↓
                          PopupMenuButton<String>(
                            elevation: 0,
                            color: Colors.transparent,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (value) {
                              if (value == 'logout') {
                                context.read<AdminAuthProvider>().signOut();
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login');
                              }
                            },
                            offset: const Offset(30, 30),
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'logout',
                                padding: EdgeInsets.zero,
                                child: Container(
                                  width: 131,
                                  height: 41,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ==== CONTENT ====
                Expanded(
                  child: Consumer3<UserProvider, FeedbackProvider,
                      NotificationProvider>(
                    builder: (
                      context,
                      userProvider,
                      feedbackProvider,
                      notificationProvider,
                      _,
                    ) =>
                        _getScreen(
                      _selectedIndex,
                      userProvider,
                      feedbackProvider,
                      notificationProvider,
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
                  size: isSelected ? 36 : 33, // to hơn khi selected
                  color: isSelected
                      ? Colors.white
                      : Colors.black, // <- đổi màu icon
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'Inter',
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500, // bold khi selected
                  color: isSelected
                      ? Colors.white
                      : Colors.black, // <- đổi màu chữ
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}