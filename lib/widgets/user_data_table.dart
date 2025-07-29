// lib/widgets/user_data_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../screens/dashboard/user_details_screen.dart'; // IMPORTANT: Import the detail screen

class UserDataTable extends StatelessWidget {
  final List<UserProfile> users;
  const UserDataTable({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final selectedIds = userProvider.selectedUserIds;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
      // NEW: Adding a hover color to indicate rows are clickable
      dataRowColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.hovered)) {
          return Theme.of(context).colorScheme.primary.withOpacity(0.08);
        }
        return null; // Use default
      }),
      columns: [
        DataColumn(
          label: Checkbox(
            value: selectedIds.isNotEmpty && selectedIds.length == users.length,
            tristate: selectedIds.isNotEmpty && selectedIds.length < users.length,
            onChanged: (bool? value) {
              userProvider.toggleSelectAll(value, users.map((u) => u.id).toList());
            },
          ),
        ),
        const DataColumn(label: Text('Account name', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Gmail', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: users.map((user) {
        final isSelected = selectedIds.contains(user.id);
        return DataRow(
          // Note: The onSelectChanged here is for the checkbox behavior.
          // We add onTap to the cells for navigation.
          selected: isSelected,
          onSelectChanged: (bool? selected) {
            if (selected != null) {
              userProvider.toggleUserSelection(user.id);
            }
          },
          cells: [
            DataCell(Checkbox(value: isSelected, onChanged: (v) => userProvider.toggleUserSelection(user.id))),
            // NEW: Added onTap to the cells for navigation
            DataCell(Text(user.username), onTap: () => _navigateToDetails(context, user.id)),
            DataCell(Text(user.email), onTap: () => _navigateToDetails(context, user.id)),
            DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt)), onTap: () => _navigateToDetails(context, user.id)),
          ],
        );
      }).toList(),
    );
  }

  // NEW: Navigation helper method
  void _navigateToDetails(BuildContext context, String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => UserDetailsScreen(userId: userId),
    ));
  }
}