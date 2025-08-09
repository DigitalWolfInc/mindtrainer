import 'package:flutter/material.dart';

class FocusSessionScreen extends StatelessWidget {
  const FocusSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
      ),
      body: const Center(
        child: Text('Focus Session Screen'),
      ),
    );
  }
}