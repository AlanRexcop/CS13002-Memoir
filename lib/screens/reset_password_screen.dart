// lib/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/widgets/custom_text_field.dart';
import 'package:memoir/widgets/primary_button.dart';

class ResetPasswordScreen extends ConsumerWidget {
  ResetPasswordScreen({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _updatePassword(WidgetRef ref) {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).setNewPassword(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      final notifier = ref.read(authNotifierProvider.notifier);
      if (current.status == AuthStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your password has been updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        notifier.resetStatus();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (current.status == AuthStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage ?? 'Failed to update password.'),
            backgroundColor: Colors.red,
          ),
        );
        notifier.resetStatus();
      }
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set New Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                    controller: _passwordController,
                    hintText: 'New Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm New Password',
                    isPassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 20),
                if (authState.isLoading)
                  const CircularProgressIndicator()
                else
                  PrimaryButton(
                      text: 'Reset Password',
                      background: Theme.of(context).colorScheme.primary,
                      onPress: () => _updatePassword(ref)
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}