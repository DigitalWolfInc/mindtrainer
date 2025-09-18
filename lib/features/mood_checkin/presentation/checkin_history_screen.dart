import 'package:flutter/material.dart';
import '../domain/checkin_entry.dart';
import '../data/checkin_storage.dart';

class CheckinHistoryScreen extends StatelessWidget {
  const CheckinHistoryScreen({super.key});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Animal Check-ins'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<CheckinEntry>>(
          future: CheckinStorage().getCheckinsForWeek(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final checkins = snapshot.data ?? [];
            
            if (checkins.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🐾',
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No check-ins yet this week',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to share how you\'re feeling!',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: checkins.length,
              itemBuilder: (context, index) {
                final checkin = checkins[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      checkin.animalMood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(checkin.animalMood.name),
                    subtitle: Text(_formatDateTime(checkin.timestamp)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}