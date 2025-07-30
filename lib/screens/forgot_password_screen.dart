// C:\dev\memoir\lib\screens\forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/otp_screen.dart';
import 'package:memoir/widgets/app_logo_header.dart';
import 'package:memoir/widgets/custom_text_field.dart';
import 'package:memoir/widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    void requestReset() {
      if (formKey.currentState!.validate()) {
        ref
            .read(authNotifierProvider.notifier)
            .requestPasswordReset(emailController.text.trim());
      }
    }

    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      final notifier = ref.read(authNotifierProvider.notifier);
      if (current.status == AuthStatus.otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset instructions sent to your email.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: emailController.text.trim()),
          ),
        );
        notifier.resetStatus();
      } else if (current.status == AuthStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage ?? 'An error occurred.'),
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
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                AppLogoHeader(
                  size: 30,
                  logoAsset: 'assets/Logo.png',
                  title: 'Memoir',
                  textColor: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Recover your password',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Enter the email address associated with your account and we\'ll send you instructions to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.primary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: emailController,
                  hintText: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Please enter a valid email'
                      : null,
                ),
                const SizedBox(height: 40),
                authState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Send Instructions',
                        background: colorScheme.primary,
                        onPress: requestReset,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}