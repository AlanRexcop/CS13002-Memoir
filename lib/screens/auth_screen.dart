// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/otp_screen.dart';
import 'package:memoir/widgets/custom_float_button.dart';
import 'package:memoir/widgets/custom_pinput.dart';
import 'package:memoir/widgets/custom_text_field.dart';
import 'package:memoir/widgets/primary_button.dart';

import '../widgets/app_logo_header.dart';

enum AuthView { signIn, signUp, forgotPassword, verifyOtp }

class AuthScreen extends ConsumerStatefulWidget {
  final AuthView initialView;
  const AuthScreen({super.key, this.initialView = AuthView.signIn});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late AuthView _view;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
  }
  
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
        authNotifier.signUp(email: email, password: password, username: username);
        break;
      case AuthView.forgotPassword:
        authNotifier.requestPasswordReset(email);
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
            SnackBar(content: Text(current.errorMessage!), backgroundColor: Colors.red),
          );
        }
        notifier.resetStatus();
      } else if (current.status == AuthStatus.success) {
        if (mounted) Navigator.of(context).pop();
      } else if (current.status == AuthStatus.otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset OTP sent to your email.')),
        );
        // Navigate to the dedicated OTP screen for password recovery
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OtpScreen(email: _emailController.text.trim()),
          ));
        }
        setState(() => _view = AuthView.signIn);
        notifier.resetStatus();
      } else if (current.status == AuthStatus.awaitingVerification) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification OTP sent! Please check your email.')),
        );
        setState(() => _view = AuthView.verifyOtp);
        notifier.resetStatus();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle())),
      backgroundColor: colorScheme.secondary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ..._buildFormFields(),
              const SizedBox(height: 40),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_view) {
      case AuthView.signIn:
        return '';
      case AuthView.signUp:
        return '';
      case AuthView.forgotPassword:
        return '';
      case AuthView.verifyOtp:
        return 'Verify Your Email';
    }
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
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
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
          const SizedBox(height: 50,),

          _buildUsernameField(),
          const SizedBox(height: 20),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildPasswordField(isSignUp: true),
        ];
      case AuthView.forgotPassword:
        return [
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
          const SizedBox(height: 70,),
          _buildEmailField()
        ];
      case AuthView.verifyOtp:
        return [
          Text(
            'Enter the OTP sent to ${_emailController.text}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomPinput(controller: _otpController),
        ];
    }
  }

  Widget _buildButtons() {
    switch (_view) {
      case AuthView.signIn:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainButton('Sign In'),
            _buildTextButton('Create an account', () => setState(() => _view = AuthView.signUp)),
            _buildTextButton('Forgot Password?', () => setState(() => _view = AuthView.forgotPassword)),
          ],
        );
      case AuthView.signUp:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainButton('Sign Up'),
            _buildTextButton('Have an account? Sign In', () => setState(() => _view = AuthView.signIn)),
          ],
        );
      case AuthView.forgotPassword:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainButton('Send Reset Instructions'),
            _buildTextButton('Back to Sign In', () => setState(() => _view = AuthView.signIn)),
          ],
        );
      case AuthView.verifyOtp:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainButton('Verify and Sign In'),
            _buildTextButton('Back to Sign In', () => setState(() => _view = AuthView.signIn)),
          ],
        );
    }
  }
  
  Widget _buildMainButton(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return PrimaryButton(
        text: text,
        background: colorScheme.primary,
        onPress: _handleAuthAction,
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(onPressed: onPressed, child: Text(text));
  }

  Widget _buildEmailField() {
    return CustomTextField(
        hintText: 'Email',
        controller: _emailController,
        validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
        keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField({bool isSignUp = false}) {
    return CustomTextField(
        controller: _passwordController,
        isPassword: true,
        hintText: 'Password',
        validator: (value) {
          if (value == null || value.isEmpty) return 'Password cannot be empty';
          if (isSignUp && value.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
    );
  }

  Widget _buildUsernameField() {
    return CustomTextField(
        controller: _usernameController,
        hintText: "Username",
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter a username' : null
    );
  }

}