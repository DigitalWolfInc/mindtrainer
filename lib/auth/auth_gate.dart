import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/feature_flags.dart';
import 'login_screen.dart';
import '../shell/tab_shell.dart';

/// Authentication gate that routes users to login or main app
/// based on their authentication state and feature flags
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _isSignedIn;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final signedIn = sp.getBool('mt_signed_in_v1') ?? false;
      
      if (mounted) {
        setState(() {
          _isSignedIn = signedIn;
        });
      }
    } catch (e) {
      // On error, default to not signed in
      if (mounted) {
        setState(() {
          _isSignedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auth state
    if (_isSignedIn == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A), // Midnight Calm top
              Color(0xFF0A1622), // Midnight Calm bottom
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7D1DD)),
          ),
        ),
      );
    }

    // Route based on auth state and feature flags
    if (!FeatureFlags.authPasskeyEnabled || _isSignedIn == false) {
      return const LoginScreen();
    }

    return const TabShell();
  }
}