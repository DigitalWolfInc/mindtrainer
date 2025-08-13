import 'package:flutter/material.dart';
import 'dart:async';
import 'start_screen.dart';
import '../shell/tab_shell.dart';
import '../core/feature_flags.dart';
import '../a11y/a11y.dart';
import '../i18n/i18n.dart';
import '../payments/billing_service.dart';

/// DigitalWolf splash screen shown for 5 seconds on every app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  void _navigateToStartScreen() {
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FeatureFlags.navTabs6Enabled 
                ? const TabShell() 
                : const StartScreen(),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Precache the start screen icon for performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage('assets/images/mindtrainer2_icon_512.png'), context);
      }
    });
    
    // Initialize billing service in the background
    _initializeServices();
    
    _navigateToStartScreen();
  }

  /// Initialize app services during splash screen
  Future<void> _initializeServices() async {
    try {
      // Initialize billing service
      final billingService = BillingService.instance;
      await billingService.initialize();
      
      // Try to connect (non-blocking)
      billingService.connect().catchError((error) {
        // Connection errors are handled by the billing service
        // and don't block app startup
      });
      
    } catch (e) {
      // Billing initialization errors don't block app startup
      // Users can still use the free features
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.safeStrings;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with accessibility label
            Semantics(
              label: strings.appName,
              image: true,
              child: Image.asset(
                'assets/images/digitalwolf.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Loading indicator with live region for screen readers
            Semantics(
              label: strings.splashLoading,
              liveRegion: true,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}