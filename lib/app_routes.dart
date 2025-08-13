import 'package:flutter/widgets.dart';

/// Simple route helper to avoid boilerplate navigation calls
class R {
  static void go(BuildContext c, String p) => Navigator.of(c).pushNamed(p);
  static void repl(BuildContext c, String p) => Navigator.of(c).pushReplacementNamed(p);
}