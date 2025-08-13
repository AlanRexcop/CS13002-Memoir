// lib/widgets/user_data_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    return Column(
      children: [
        // Header
        _buildHeader(context, userProvider),
        const Divider(height: 1, thickness: 1),

        // Data rows
        if (users.isEmpty) 
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No users found.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelected = selectedIds.contains(user.id);
              return _UserDataRow(
                user: user,
                isSelected: isSelected,
                onSelect: () => userProvider.toggleUserSelection(user.id),
                onNavigate: () => _navigateToDetails(context, user.id),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UserProvider userProvider) {
    final selectedIds = userProvider.selectedUserIds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: selectedIds.isNotEmpty && selectedIds.length == users.length,
              tristate: selectedIds.isNotEmpty && selectedIds.length < users.length,
              onChanged: (bool? value) {
                userProvider.toggleSelectAll(value, users.map((u) => u.id).toList());
              },
            ),
          ),
          // Auto scale width
          const Expanded(
            flex: 3, // 30%
            child: Text('Account name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 4, // 40%
            child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 3, // 30%
            child: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // UPDATED: Navigation helper now uses the provider to change view state.
  void _navigateToDetails(BuildContext context, String userId) {
    context.read<UserProvider>().viewUser(userId);
  }
}

class _UserDataRow extends StatefulWidget {
  final UserProfile user;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onNavigate;

  const _UserDataRow({
    required this.user,
    required this.isSelected,
    required this.onSelect,
    required this.onNavigate,
  });

  @override
  State<_UserDataRow> createState() => _UserDataRowState();
}

class _UserDataRowState extends State<_UserDataRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // InkWell cover entire row
    return InkWell(
      onTap: widget.onNavigate,
      onHover: (hovering) => setState(() => _isHovering = hovering),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        // Thay đổi màu nền dựa trên trạng thái selected hoặc hovering
        color: widget.isSelected
            ? Colors.purple.shade100
            : _isHovering
                ? Colors.grey[100]
                : Colors.transparent,
        child: Row(
          children: [
            // Cột Checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onSelect(),
              ),
            ),
            // data column
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(widget.user.username, overflow: TextOverflow.ellipsis),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(widget.user.email, overflow: TextOverflow.ellipsis),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.user.createdAt)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}