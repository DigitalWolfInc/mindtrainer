import 'package:flutter/material.dart';
import 'focus_session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MindTrainer')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FocusSessionScreen(),
              ),
            );
          },
          child: const Text('Start Focus Session'),
        ),
      ),
    );
  }
}
