import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  Future<List<Map<String, dynamic>>> _loadSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('session_history') ?? [];
    
    return historyJson.map((jsonString) {
      final parts = jsonString.split('|');
      return {
        'dateTime': DateTime.parse(parts[0]),
        'durationMinutes': int.parse(parts[1]),
      };
    }).toList();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Clear all session history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_history');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          TextButton(
            onPressed: _clearHistory,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadSessionHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data ?? [];
            
            if (sessions.isEmpty) {
              return const Center(
                child: Text('No sessions yet'),
              );
            }

            return ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  title: Text(_formatDateTime(session['dateTime'])),
                  subtitle: Text('${session['durationMinutes']} minutes'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}