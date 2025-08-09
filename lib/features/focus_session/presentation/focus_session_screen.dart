import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: restore to 25 * 60 before release
const int kDefaultSessionSeconds = 10;

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  int _remainingSeconds = kDefaultSessionSeconds;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _clearTestData(); // TEMP: remove after testing
    _loadSavedTimer();
  }

  // TEMP: remove after testing
  Future<void> _clearTestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_end_time');
    await prefs.remove('session_history');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEndTime = prefs.getString('timer_end_time');
    
    if (savedEndTime != null) {
      final endTime = DateTime.parse(savedEndTime);
      final now = DateTime.now();
      
      if (endTime.isAfter(now)) {
        final remaining = endTime.difference(now).inSeconds;
        setState(() {
          _remainingSeconds = remaining;
          _isRunning = true;
        });
        _startTimer();
      } else {
        await _clearSavedTimer();
      }
    }
  }

  Future<void> _saveEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    await prefs.setString('timer_end_time', endTime.toIso8601String());
  }

  Future<void> _clearSavedTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_end_time');
  }

  Future<void> _logCompletedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sessionRecord = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}|${(kDefaultSessionSeconds ~/ 60).toString()}';
    
    final history = prefs.getStringList('session_history') ?? [];
    history.insert(0, sessionRecord);
    await prefs.setStringList('session_history', history);
  }

  void _startTimer() {
    if (_remainingSeconds > 0) {
      if (!_isRunning) {
        setState(() {
          _isRunning = true;
        });
        _saveEndTime();
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            _clearSavedTimer();
            _logCompletedSession();
          }
        });
      });
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _resetTimer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Session'),
        content: const Text('Reset the current session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer?.cancel();
      _clearSavedTimer();
      setState(() {
        _remainingSeconds = kDefaultSessionSeconds;
        _isRunning = false;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _isRunning ? null : _startTimer,
                child: const Text('Start'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _isRunning ? _pauseTimer : null,
                child: const Text('Pause'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _resetTimer,
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}