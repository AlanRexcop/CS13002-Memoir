// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/auth_provider.dart';
import 'package:memoir/screens/otp_screen.dart';

enum AuthView { signIn, signUp, forgotPassword, verifyOtp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

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

    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ..._buildFormFields(),
                const SizedBox(height: 20),
                if (authState.isLoading)
                  const CircularProgressIndicator()
                else
                  _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_view) {
      case AuthView.signIn:
        return 'Sign In to Memoir Cloud';
      case AuthView.signUp:
        return 'Create Account';
      case AuthView.forgotPassword:
        return 'Reset Password';
      case AuthView.verifyOtp:
        return 'Verify Your Email';
    }
  }

  List<Widget> _buildFormFields() {
    switch (_view) {
      case AuthView.signIn:
        return [
          _buildEmailField(),
          const SizedBox(height: 8),
          _buildPasswordField(),
        ];
      case AuthView.signUp:
        return [
          _buildUsernameField(),
          const SizedBox(height: 8),
          _buildEmailField(),
          const SizedBox(height: 8),
          _buildPasswordField(isSignUp: true),
        ];
      case AuthView.forgotPassword:
        return [_buildEmailField()];
      case AuthView.verifyOtp:
        return [
          Text(
            'Enter the OTP sent to ${_emailController.text}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildOtpField(),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
      onPressed: _handleAuthAction,
      child: Text(text),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(onPressed: onPressed, child: Text(text));
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
    );
  }

  Widget _buildPasswordField({bool isSignUp = false}) {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password cannot be empty';
        if (isSignUp && value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(labelText: 'Username'),
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a username' : null,
    );
  }

  Widget _buildOtpField() {
    return TextFormField(
      controller: _otpController,
      decoration: const InputDecoration(labelText: 'OTP Code'),
      keyboardType: TextInputType.number,
      validator: (value) => (value == null || value.length < 6) ? 'Enter a valid 6-digit OTP' : null,
    );
  }
}