// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/auth_screen.dart';
import 'package:memoir/screens/reset_password_screen.dart';
import 'package:memoir/widgets/custom_text_field.dart';
import 'package:memoir/widgets/primary_button.dart';

import '../widgets/app_logo_header.dart';

class ChangePasswordScreen extends ConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    void updatePassword() {
      if (!formKey.currentState!.validate()) {
        return;
      }
      ref.read(authNotifierProvider.notifier).changePassword(
            oldPassword: oldPasswordController.text,
            newPassword: newPasswordController.text,
          );
    }

    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      if (current.status == AuthStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(authNotifierProvider.notifier).resetStatus();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else if (current.status == AuthStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authNotifierProvider.notifier).resetStatus();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.secondary,
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLogoHeader(
                size: 30,
                logoAsset: 'assets/Logo.png',
                title: 'Memoir',
                textColor: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Change your password',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 70,),
              CustomTextField(
                  controller: oldPasswordController,
                  hintText: 'Old Password',
                  isPassword: true,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please enter your old password' : null,
              ),

              const SizedBox(height: 12),
              CustomTextField(
                controller: newPasswordController,
                hintText: 'New Password',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: confirmPasswordController,
                hintText: 'Confirm New Password',
                isPassword: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              authState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                    text: 'Update Password',
                    background: colorScheme.primary,
                    onPress: updatePassword
                  ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to the auth screen and specify the forgot password view
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen(initialView: AuthView.forgotPassword)),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}