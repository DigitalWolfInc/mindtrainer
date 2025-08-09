import 'package:flutter/material.dart';
import '../domain/animal_mood.dart';
import '../domain/checkin_entry.dart';
import '../data/checkin_storage.dart';

class AnimalCheckinScreen extends StatelessWidget {
  const AnimalCheckinScreen({super.key});

  Future<void> _saveCheckin(BuildContext context, AnimalMood mood) async {
    final entry = CheckinEntry(
      timestamp: DateTime.now(),
      animalMood: mood,
    );
    
    final storage = CheckinStorage();
    await storage.saveCheckin(entry);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thanks for sharing that you\'re feeling like a ${mood.name}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the animal that matches how you\'re feeling right now:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: AnimalMood.allMoods.length,
                itemBuilder: (context, index) {
                  final mood = AnimalMood.allMoods[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        mood.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        mood.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => _saveCheckin(context, mood),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}