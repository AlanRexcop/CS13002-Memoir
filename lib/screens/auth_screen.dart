// C:\dev\memoir\lib\screens\auth_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/forgot_password_screen.dart';
import 'package:memoir/widgets/custom_text_field.dart';
import 'package:memoir/widgets/primary_button.dart';
import '../widgets/app_logo_header.dart';
import 'otp_screen.dart'; // Keep for signup verification

enum AuthView { signIn, signUp, verifyOtp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthView _view = AuthView.signIn;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleAuthAction() {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final otp = _otpController.text.trim();

    switch (_view) {
      case AuthView.signIn:
        authNotifier.signIn(email: email, password: password);
        break;
      case AuthView.signUp:
        authNotifier.signUp(
            email: email, password: password, username: username);
        break;
      case AuthView.verifyOtp:
        authNotifier.verifySignUp(email: email, token: otp);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      final notifier = ref.read(authNotifierProvider.notifier);
      if (current.status == AuthStatus.failure) {
        if (current.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(current.errorMessage!),
                backgroundColor: Colors.red),
          );
        }
        notifier.resetStatus();
      } else if (current.status == AuthStatus.success) {
        // This will pop the AuthScreen and return to the previous screen (e.g., Settings)
        if (mounted) Navigator.of(context).pop();
      } else if (current.status == AuthStatus.awaitingVerification) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Verification OTP sent! Please check your email.')),
        );
        setState(() => _view = AuthView.verifyOtp);
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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._buildFormFields(),
                const SizedBox(height: 40),
                if (authState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildButtons(),
                
                if (_view == AuthView.signIn)
                  const SizedBox(height: 150),
                
                if (_view == AuthView.signIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, top: 20),
                    child: _buildFooterText(),
                  ),

                if (_view == AuthView.signUp)
                  const SizedBox(height: 150),

                if (_view == AuthView.signUp)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, top: 20),
                    child: _buildFooterText(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_view) {
      case AuthView.signIn:
        return [
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
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            isPassword: true,
            prefixIcon: Icons.lock_outline,
          ),
        ];
      case AuthView.signUp:
        return [
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
          const SizedBox(
            height: 50,
          ),
          CustomTextField(
            controller: _usernameController,
            hintText: 'Username',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            isPassword: true,
            prefixIcon: Icons.lock_outline,
          ),
        ];
      case AuthView.verifyOtp:
        return [
          const SizedBox(height: 20),
          AppLogoHeader(
            size: 30,
            logoAsset: 'assets/Logo.png',
            title: 'Memoir',
            textColor: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your Email',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Enter the 6-digit verification code sent to ${_emailController.text}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Using a standard text field for OTP for now
          CustomTextField(
            controller: _otpController,
            hintText: 'OTP Code',
            keyboardType: TextInputType.number,
          ),
        ];
    }
  }

  Widget _buildButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_view) {
      case AuthView.signIn:
        return Column(
          children: [
            PrimaryButton(
              text: 'Login',
              background: colorScheme.primary,
              onPress: _handleAuthAction,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen()));
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
        );
      case AuthView.signUp:
        return PrimaryButton(
          text: 'Sign Up',
          background: colorScheme.primary,
          onPress: _handleAuthAction,
        );
      case AuthView.verifyOtp:
        return PrimaryButton(
          text: 'Verify',
          background: colorScheme.primary,
          onPress: _handleAuthAction,
        );
    }
  }

  Widget _buildFooterText() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_view == AuthView.signIn) {
      return Text.rich(
        TextSpan(
          text: 'Don\'t have an account? ',
          style: GoogleFonts.poppins(color: colorScheme.primary, fontSize: 14),
          children: [
            TextSpan(
              text: 'Sign Up',
              style: GoogleFonts.poppins(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _view = AuthView.signUp),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    if (_view == AuthView.signUp) {
      return Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: GoogleFonts.poppins(color: colorScheme.primary, fontSize: 14),
          children: [
            TextSpan(
              text: 'Sign In',
              style: GoogleFonts.poppins(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _view = AuthView.signIn),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    return const SizedBox.shrink(); // No footer for verify OTP
  }
}