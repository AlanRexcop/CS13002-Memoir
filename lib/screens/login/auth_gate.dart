// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import 'login_screen.dart';
import '../dashboard/dashboard_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AdminAuthProvider>();

    return authProvider.isLoggedIn
        ? const DashboardShell()
        : const LoginScreen();
  }
}
