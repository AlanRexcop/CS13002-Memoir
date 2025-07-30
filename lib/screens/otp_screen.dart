// lib/screens/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/reset_password_screen.dart';

class OtpScreen extends ConsumerWidget {
  final String email;
  OtpScreen({super.key, required this.email});

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  void _verifyOtp(WidgetRef ref) {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).verifyPasswordResetOtp(
            email: email,
            token: _otpController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      final notifier = ref.read(authNotifierProvider.notifier);
      if (current.status == AuthStatus.otpVerified) {
        notifier.resetStatus();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen()),
        );
      } else if (current.status == AuthStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage ?? 'OTP verification failed.'),
            backgroundColor: Colors.red,
          ),
        );
        notifier.resetStatus();
      }
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Verification Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'A 6-digit verification code has been sent to $email. Please enter it below.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: 'OTP Code'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return 'Please enter a valid 6-digit OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (authState.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                    onPressed: () => _verifyOtp(ref),
                    child: const Text('Verify'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}