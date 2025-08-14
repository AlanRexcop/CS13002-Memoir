// lib/screens/dashboard/users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../providers/user_provider.dart';
import '../../widgets/user_data_table.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserProvider>();
      // remove old search and filter when rebuild
      provider.searchUsers('');
      provider.setDateFilter(start: null, end: null);
      provider.fetchUsers();
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
    Future<void> _showFilterDialog(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    DateTime? tempStartDate = userProvider.filterStartDate;
    DateTime? tempEndDate = userProvider.filterEndDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate(bool isStartDate) async {
              final initialDate = (isStartDate ? tempStartDate : tempEndDate) ?? DateTime.now();
              final firstDate = DateTime(2020);
              final lastDate = DateTime.now();

              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
              );

              if (pickedDate != null) {
                setDialogState(() {
                  if (isStartDate) {
                    tempStartDate = pickedDate;
                  } else {
                    tempEndDate = pickedDate;
                  }
                });
              }
            }

            return AlertDialog(
              title: const Text('Filter by Creation Date'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(tempStartDate == null
                        ? 'Not set'
                        : DateFormat('yyyy-MM-dd').format(tempStartDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(true),
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(tempEndDate == null
                        ? 'Not set'
                        : DateFormat('yyyy-MM-dd').format(tempEndDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempStartDate = null;
                      tempEndDate = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    userProvider.setDateFilter(start: tempStartDate, end: tempEndDate);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
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
                ? Center(child: Text('Error: ${userProvider.error}')) // the table is centered
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: UserDataTable(users: users),
                        ),
                      ),
                    ),
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
    final userProvider = context.watch<UserProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search something',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              userProvider.searchUsers(value);
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            _showFilterDialog(context);
          },
          icon: const Icon(Icons.filter_list),
          label: const Text('Filter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: userProvider.isFilterActive ? Theme.of(context).primaryColorDark : Colors.green,
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
