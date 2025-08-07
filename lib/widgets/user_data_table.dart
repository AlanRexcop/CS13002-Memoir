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

    return LayoutBuilder( // NEW: Use LayoutBuilder make the table responsive
      builder: (context, constraints) {
        // NEW: Calculate the total width and allocate space for each column
        final double totalWidth = constraints.maxWidth;
        final double checkboxColWidth = 60;
        final double remainingWidth = totalWidth - checkboxColWidth;
        
        // NEW: Allocate widths for each column based on the remaining width
        final double nameColWidth = remainingWidth * 0.30; // 30%
        final double emailColWidth = remainingWidth * 0.40; // 40%
        final double dateColWidth = remainingWidth * 0.30; // 30%

        return DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
          // NEW: set the margin outside the table
          horizontalMargin: 20,
          columnSpacing: 20,
          // NEW: Adding a hover color to indicate rows are clickable
          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return Theme.of(context).colorScheme.primary.withOpacity(0.08);
            }
            return null; // Use default
          }),
          columns: [
            // NEW: checkbox select all
            DataColumn(
              label: Checkbox(
                value: selectedIds.isNotEmpty && selectedIds.length == users.length,
                tristate: selectedIds.isNotEmpty && selectedIds.length < users.length,
                onChanged: (bool? value) {
                  userProvider.toggleSelectAll(value, users.map((u) => u.id).toList());
                },
              ),
            ),
            DataColumn(
              label: Container(
                width: nameColWidth,
                alignment: Alignment.centerLeft,
                child: const Text('Account name', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ),
            DataColumn(
              label: Container(
                width: emailColWidth,
                alignment: Alignment.centerLeft,
                child: const Text('Gmail', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ),
            DataColumn(
              label: Container(
                width: dateColWidth,
                alignment: Alignment.centerLeft,
                child: const Text('Created At', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ),
          ],
          rows: users.map((user) {
            final isSelected = selectedIds.contains(user.id);
            return DataRow(
              // NEW: change color to purple when selected
              color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.purple[100];
                }
                return null; 
              }),
              selected: isSelected,
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) => userProvider.toggleUserSelection(user.id),
                  ),
                  onTap: () => {},
                ),
                DataCell(
                  Text(user.username),
                  onTap: () => _navigateToDetails(context, user.id)
                ),
                DataCell(
                  Text(user.email),
                  onTap: () => _navigateToDetails(context, user.id),
                ),
                DataCell(
                  Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt)),
                  onTap: () => _navigateToDetails(context, user.id),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  // UPDATED: Navigation helper now uses the provider to change view state.
  void _navigateToDetails(BuildContext context, String userId) {
    context.read<UserProvider>().viewUser(userId);
  }
}