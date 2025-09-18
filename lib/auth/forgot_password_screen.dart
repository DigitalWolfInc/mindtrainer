import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/feature_flags.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.ff_auth_forgot_pw) {
      return const Scaffold(body: Center(child: Text('Password reset not available')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _resetPassword(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _resetPassword,
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) return;
    
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('mt_forgot_pw_last_email_v1', _email.text.trim());
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text('If this email exists, a reset link was sent.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }
}