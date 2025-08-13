import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/feature_flags.dart';
import '../profile/avatar_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _displayName = TextEditingController();
  bool _busy = false;
  bool _terms = false;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.ff_auth_email_register) {
      return const Scaffold(body: Center(child: Text('Email registration is not available')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _displayName,
            decoration: const InputDecoration(labelText: 'Display name (optional)'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPassword,
            decoration: const InputDecoration(labelText: 'Confirm password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _terms,
            onChanged: (value) => setState(() => _terms = value ?? false),
            title: const Text('I agree to the Terms'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy || !_terms ? null : _register,
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_password.text.isEmpty || _password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords must match')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('mt_user_id_v1', _email.text.trim());
      if (_displayName.text.isNotEmpty) {
        await sp.setString('mt_profile_name_v1', _displayName.text.trim());
      }
      await sp.setBool('mt_signed_in_v1', true);
      await sp.setBool('mt_guest_active_v1', false);

      if (!mounted) return;

      if (FeatureFlags.ff_profile_avatar) {
        final avatar = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const AvatarPicker()),
        );
        if (avatar != null && mounted) {
          final sp = await SharedPreferences.getInstance();
          await sp.setString('mt_profile_avatar_ref_v1', avatar);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _displayName.dispose();
    super.dispose();
  }
}