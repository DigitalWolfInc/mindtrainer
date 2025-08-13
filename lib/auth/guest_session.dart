import 'package:flutter/widgets.dart';

/// Gate that enables guest session mode, which uses in-memory storage only.
/// When active, repositories should use ephemeral implementations.
class GuestSessionGate extends InheritedWidget {
  const GuestSessionGate({super.key, required super.child});

  /// Returns true if guest session is active in this context
  static bool of(BuildContext context) => 
    context.dependOnInheritedWidgetOfExactType<GuestSessionGate>() != null;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}