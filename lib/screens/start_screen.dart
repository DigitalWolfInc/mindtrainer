import 'package:flutter/material.dart';
import '../a11y/a11y.dart';
import '../i18n/i18n.dart';
import '../core/feature_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MindTrainer start screen - first interactive screen after splash
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FocusTraversalGroup(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo with semantic info
                A11y.focusTraversalOrder(
                  order: 1.0,
                  child: Semantics(
                    label: strings.appName,
                    image: true,
                    child: Image.asset(
                      'assets/images/mindtrainer2_icon_512.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // App title as header
                A11y.focusTraversalOrder(
                  order: 2.0,
                  child: Semantics(
                    label: strings.appName,
                    header: true,
                    child: Text(
                      strings.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32 * textScaler,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                A11y.focusTraversalOrder(
                  order: 3.0,
                  child: Text(
                    strings.appSubtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16 * textScaler,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Passkey button
                if (FeatureFlags.ff_auth_guest_pass)
                  A11y.focusTraversalOrder(
                    order: 4.0,
                    child: A11y.ensureMinTouchTarget(
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: 'Use Passkey',
                          hint: 'Continue as guest with Passkey',
                          button: true,
                          child: FilledButton(
                            onPressed: () async {
                              final sp = await SharedPreferences.getInstance();
                              await sp.setBool('mt_guest_active_v1', true);
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('/');
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Use Passkey',
                              style: TextStyle(
                                fontSize: 18 * textScaler,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Email registration button
                if (FeatureFlags.ff_auth_email_register)
                  A11y.focusTraversalOrder(
                    order: 5.0,
                    child: A11y.ensureMinTouchTarget(
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: 'Create account',
                          hint: 'Create a new account with email',
                          button: true,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/auth/register');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 18 * textScaler,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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