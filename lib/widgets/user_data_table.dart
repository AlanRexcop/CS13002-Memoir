// lib/widgets/user_data_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
// No longer need to import UserDetailsScreen here, navigation is handled by the provider.

class UserDataTable extends StatelessWidget {
  final List<UserProfile> users;
  const UserDataTable({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final selectedIds = userProvider.selectedUserIds;

    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
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
          selected: isSelected,
          // This callback is triggered when the row is tapped. We use it for navigation.
          // Tapping the checkbox itself will not trigger this.
          onSelectChanged: (_) {
            _navigateToDetails(context, user.id);
          },
          cells: [
            // The checkbox's onChanged callback handles selection logic independently.
            DataCell(Checkbox(value: isSelected, onChanged: (v) => userProvider.toggleUserSelection(user.id))),
            // The cells themselves no longer need an onTap handler.
            DataCell(Text(user.username)),
            DataCell(Text(user.email)),
            DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt))),
          ],
        );
      }).toList(),
    );
  }

  // UPDATED: Navigation helper now uses the provider to change view state.
  void _navigateToDetails(BuildContext context, String userId) {
    context.read<UserProvider>().viewUser(userId);
  }
}