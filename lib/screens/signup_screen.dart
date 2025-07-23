import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}


class _SignupScreenState extends State<SignupScreen> {

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
                // Logo and Title
                Column(
                  children: [
                    AppLogoHeader(
                      size: 30,
                      logoAsset: 'assets/Logo.png',
                      title: 'Memoir',
                      textColor: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your Memoir account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),

                // Username TextField
                const CustomTextField(
                  hintText: 'Username',
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Email TextField
                const CustomTextField(
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // Password TextField
                const CustomTextField(
                  hintText: 'Password',
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 40),

                // Sign Up Button
                PrimaryButton(
                    text: 'Sign up',
                    textSize: 18,
                    background: colorScheme.primary,
                    onPress: () => const {

                    }
                ),
                const SizedBox(height: 30),

                // Divider
                Row(
                  children: <Widget>[
                    Expanded(child: Divider(color: colorScheme.primary)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Or better yet...',
                        style: GoogleFonts.poppins(
                            color: colorScheme.primary
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 24),

                // Continue with Google Button
                PrimaryButton(
                    text: 'Continue with Google',
                    textColor: colorScheme.primary,
                    borderColor: colorScheme.primary,
                    background: colorScheme.secondary,
                    icon: Icon(FontAwesomeIcons.google, size: 16, color: colorScheme.primary),
                    onPress: () => {

                    }
                ),
                const SizedBox(height: 16),

                // Continue with Facebook Button
                PrimaryButton(
                    text: 'Continue with Facebook',
                    textColor: colorScheme.primary,
                    borderColor: colorScheme.primary,
                    background: colorScheme.secondary,
                    icon: Icon(FontAwesomeIcons.facebook, size: 16, color: colorScheme.primary),
                    onPress: () => {

                    }
                ),
                const SizedBox(height: 32),

                // Login Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.poppins(
                          color: colorScheme.primary,
                          fontSize: 14
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),

                // Terms and Conditions Text
                Text(
                  'By creating an account, you accept our\nTerms and conditions you read our Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
