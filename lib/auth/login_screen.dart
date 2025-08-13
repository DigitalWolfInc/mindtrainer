import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'passkey_adapter.dart';
import '../shell/tab_shell.dart';
import '../a11y/a11y.dart';

/// Login screen with passkey-first authentication and email fallback
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithPasskey() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await PasskeyAdapter.instance.signIn();
      if (success) {
        await _markSignedIn();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    // Email fallback stub - just mark as signed in
    await _markSignedIn();
  }

  Future<void> _markSignedIn() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('mt_signed_in_v1', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TabShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App branding
                  Semantics(
                    header: true,
                    child: Text(
                      'MindTrainer',
                      style: TextStyle(
                        color: const Color(0xFFF2F5F7),
                        fontSize: 28 * textScaler,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A calm mind isn\'t out of reach.',
                    style: TextStyle(
                      color: const Color(0xFFC7D1DD),
                      fontSize: 16 * textScaler,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Primary passkey button
                  A11y.ensureMinTouchTarget(
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _signInWithPasskey,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Continue with Passkey',
                                style: TextStyle(
                                  fontSize: 16 * textScaler,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email fallback button
                  A11y.ensureMinTouchTarget(
                    TextButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      child: Text(
                        'Use email instead',
                        style: TextStyle(
                          color: const Color(0xFFC7D1DD),
                          fontSize: 14 * textScaler,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}