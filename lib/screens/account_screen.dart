import 'package:flutter/material.dart';

import '../widgets/info_item.dart';
import '../widgets/profile_header.dart';
import '../widgets/storage_info.dart';
import '../widgets/user_info_section.dart';



class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              onBackButtonPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            const UserInfoSection(
              name: 'Nguyen Gia Huy',
              email: 'giahuyhcmus@gmail.com',
            ),
            
            InfoItem(
                icon: Icons.key,
                label: 'Account type',
                value: 'Authenticated'
            ),
            InfoItem(
                icon: Icons.calendar_month,
                label: 'Joined on',
                value: 'Jan 12, 2005'
            ),
            InfoItem(
                icon: Icons.access_time,
                label: 'Last active',
                value: '30 Jun, 2007 - 22:00'
            ),
            StorageInfo(

            )
          ],
        ),
      ),
    );
  }
}
