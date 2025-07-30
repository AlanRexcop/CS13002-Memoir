// lib/screens/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/reset_password_screen.dart';
import 'package:memoir/widgets/custom_pinput.dart';
import 'package:memoir/widgets/primary_button.dart';
import 'package:pinput/pinput.dart';

import '../widgets/app_logo_header.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.secondary,
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AppLogoHeader(
                size: 30,
                logoAsset: 'assets/Logo.png',
                title: 'OTP verification',
                textColor: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the OTP sent to $email. \nPlease enter it below.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Pinput(
              //   controller: _otpController,
              //   length: 6,
              //   separatorBuilder: (index) => const SizedBox(width: 10),
              //   defaultPinTheme: defaultPinTheme,
              //   focusedPinTheme: defaultPinTheme.copyWith(
              //     decoration: defaultPinTheme.decoration!.copyWith(
              //       border: Border.all(color: Color(0xFFE2D1F9), width: 2),
              //       boxShadow: [
              //         BoxShadow(
              //           color: const Color(0x4D999999),
              //           spreadRadius: 5,
              //           blurRadius: 7,
              //           offset: const Offset(0, 3),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              CustomPinput(controller: _otpController),

              const SizedBox(height: 32),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                PrimaryButton(
                    text: 'Verify',
                    background: colorScheme.primary,
                    onPress: () => _verifyOtp(ref)
                )
            ],
          ),
        ),
      ),
    );
  }
}