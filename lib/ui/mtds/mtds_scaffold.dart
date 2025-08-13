import 'package:flutter/material.dart';

/// MTDS Scaffold with Midnight Calm background
class MtdsScaffold extends StatelessWidget {
  const MtdsScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.bottomNav,
    this.floatingActionButton,
    this.useGradient = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? bottomNav;
  final Widget? floatingActionButton;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1826), // Slightly darker than blocks
          gradient: useGradient
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D1B2A), // Midnight Calm top
                    Color(0xFF0A1622), // Midnight Calm bottom
                  ],
                )
              : null,
        ),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar: bottomNav,
      floatingActionButton: floatingActionButton,
      backgroundColor: Colors.transparent,
    );
  }
}