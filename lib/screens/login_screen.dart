import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/screens/home_wrapper.dart';
import 'package:memoir/screens/recovery_password_screen.dart';
import 'package:memoir/screens/signup_screen.dart';
import 'package:memoir/widgets/custom_text_field.dart';
import 'package:memoir/widgets/primary_button.dart';
import '../widgets/app_logo_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 80,),
                  Column(
                    children: [
                      AppLogoHeader(
                        size: 30,
                        logoAsset: 'assets/Logo.png',
                        title: 'Memoir',
                        textColor: colorScheme.primary,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Welcome Back',
                        style: GoogleFonts.nunito(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to your Memoir account',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      CustomTextField(
                        hintText: 'Email',
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        hintText: 'Password',
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      PrimaryButton(
                          text: 'Login',
                          textSize: 18,
                          background: colorScheme.primary,
                          onPress: () => {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeWrapper()),
                            )
                          }
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecoveryPasswordScreen()),
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 200,),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, top: 20),
                    child: Text.rich(
                      TextSpan(
                        text: 'Don\'t have an account? ',
                        style: GoogleFonts.poppins(
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.poppins(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary,
                              fontSize: 14,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
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
