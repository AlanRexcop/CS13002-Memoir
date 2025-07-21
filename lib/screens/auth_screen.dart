// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
    if (current.status == AuthStatus.initial) return;

    if (current.status == AuthStatus.success) {
        if (current.isSignUp) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign up successful! Please check your email for confirmation.')),
            );
        }
        Navigator.of(context).pop();
    }
    else if (current.status == AuthStatus.failure) {
        if (current.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(current.errorMessage!)),
            );
        }
    }

    Future(() {
        ref.read(authNotifierProvider.notifier).resetStatus();
    });
});

    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Memoir Cloud')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                      onPressed: () {
                        authNotifier.signIn(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        authNotifier.signUp(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}