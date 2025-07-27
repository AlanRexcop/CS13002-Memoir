import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/screens/otp_verification_screen.dart';

import '../widgets/app_logo_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}


class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                // Logo and Title
                Column(
                  children: [
                    // A placeholder for the brain icon
                    AppLogoHeader(
                      size: 30,
                      logoAsset: 'assets/Logo.png',
                      title: 'Memoir',
                      textColor: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recovery your password',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Username TextField
                const CustomTextField(
                  hintText: 'Current password',
                  isPassword: true,
                ),
                const SizedBox(height: 16),

                // Email TextField
                const CustomTextField(
                  hintText: 'New password',
                  isPassword: true,
                ),
                const SizedBox(height: 16),

                // Password TextField
                const CustomTextField(
                  hintText: 'Confirm new password',
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                // Sign Up Button
                PrimaryButton(
                    text: 'Recovery my password',
                    textSize: 18,
                    background: colorScheme.primary,
                    onPress: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OtpVerificationScreen()),
                      )
                    }
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}