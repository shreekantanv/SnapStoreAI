// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // If signed in (anon or Google), leave this screen.
    if (auth.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          HomeScreen.routeName,
              (_) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (auth.error != null && auth.user == null) ...[
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                icon: Image.asset('assets/images/google_logo.png', height: 24),
                label: const Text('Sign in with Google'),
                onPressed: auth.isLoading ? null : () => auth.signInWithGoogle(),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: auth.isLoading ? null : () => auth.signInAnonymously(),
                child: const Text('Continue as Guest'),
              ),
              if (auth.isLoading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
