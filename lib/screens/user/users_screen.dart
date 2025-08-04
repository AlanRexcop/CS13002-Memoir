// lib/screens/dashboard/users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_data_table.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch users when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final users = userProvider.users;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'User Accounts (${users.length})',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          // --- RESPONSIVE ACTION BAR ---
          // Uses a LayoutBuilder to switch between Row and Column.
          LayoutBuilder(
            builder: (context, constraints) {
              // On narrow screens, use a Column
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchAndFilter(),
                    const SizedBox(height: 16),
                    _buildDeleteButton(userProvider),
                  ],
                );
              }
              // On wider screens, use a Row
              return Row(
                children: [
                  _buildDeleteButton(userProvider),
                  const Spacer(),
                  _buildSearchAndFilter(),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // --- SCROLLABLE DATA TABLE ---
          // The Expanded ensures the table takes up the remaining vertical space.
          // The SingleChildScrollView allows the table to be scrolled horizontally.
          Expanded(
            child: userProvider.isLoading && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : userProvider.error != null
                ? Center(child: Text('Error: ${userProvider.error}'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: UserDataTable(users: users),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the delete button
  Widget _buildDeleteButton(UserProvider userProvider) {
    return ElevatedButton.icon(
      onPressed: userProvider.selectedUserIds.isEmpty
          ? null
          : () {
              // Add a confirmation dialog before deleting
              context.read<UserProvider>().deleteSelectedUsers();
            },
      icon: const Icon(Icons.delete),
      label: const Text('Delete'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Helper widget for the search and filter elements
  Widget _buildSearchAndFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search something',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            /* TODO: Implement Filter Dialog */
          },
          icon: const Icon(Icons.filter_list),
          label: const Text('Filter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
