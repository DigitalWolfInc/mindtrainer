import 'package:flutter/material.dart';
import '../core/feature_flags.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.ff_profile_avatar) {
      return const Scaffold(body: Center(child: Text('Avatar selection not available')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose profile picture')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person_outline, size: 50),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('encrypted://avatar/default'),
              child: const Text('Use default avatar'),
            ),
          ],
        ),
      ),
    );
  }
}