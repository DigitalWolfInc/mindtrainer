import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/time_format.dart';
import '../domain/focus_session_state.dart';
import '../domain/focus_session_repository.dart';
import '../data/focus_session_repository_impl.dart';
import 'session_completion_dialog.dart';

// TODO: restore to 25 * 60 before release
const int kDefaultSessionSeconds = 10;

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  FocusSessionState _sessionState = FocusSessionState.idle(kDefaultSessionSeconds * 1000);
  late final FocusSessionRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = FocusSessionRepositoryImpl();
    _loadActiveSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveSession() async {
    final activeSession = await _repository.loadActiveSession();
    if (activeSession != null) {
      setState(() {
        _sessionState = activeSession;
      });
      
      if (_sessionState.status == FocusSessionStatus.running) {
        _startTimer();
      }
    }
  }

  Future<void> _saveActiveSession() async {
    if (_sessionState.status == FocusSessionStatus.idle || 
        _sessionState.status == FocusSessionStatus.completed) {
      await _repository.clearActiveSession();
    } else {
      await _repository.saveActiveSession(_sessionState);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      setState(() {
        _sessionState = _sessionState.tick();
      });
      
      if (_sessionState.status == FocusSessionStatus.completed) {
        await _onSessionCompleted();
      }
    });
  }

  Future<void> _onStart() async {
    setState(() {
      _sessionState = _sessionState.start();
    });
    await _saveActiveSession();
    _startTimer();
  }

  Future<void> _onPause() async {
    _timer?.cancel();
    setState(() {
      _sessionState = _sessionState.pause();
    });
    await _saveActiveSession();
  }

  Future<void> _onResume() async {
    setState(() {
      _sessionState = _sessionState.start();
    });
    await _saveActiveSession();
    _startTimer();
  }

  Future<void> _onComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session'),
        content: const Text('Mark this session as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer?.cancel();
      setState(() {
        _sessionState = _sessionState.complete();
      });
      await _onSessionCompleted();
    }
  }

  Future<void> _onCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: const Text('Cancel this session and start fresh?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer?.cancel();
      setState(() {
        _sessionState = _sessionState.cancel();
      });
      await _saveActiveSession();
    }
  }

  Future<void> _onSessionCompleted() async {
    _timer?.cancel();
    
    final durationMinutes = (_sessionState.elapsedMs / 60000).round();
    
    final metadata = await showDialog<SessionMetadata>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SessionCompletionDialog(),
    );
    
    await _repository.saveCompletedSession(
      completedAt: DateTime.now(),
      durationMinutes: durationMinutes,
      tags: metadata?.tags,
      note: metadata?.note,
    );
    await _repository.clearActiveSession();
  }

  String _getDisplayTime() {
    final remainingMs = _sessionState.currentRemainingMs;
    final duration = Duration(milliseconds: remainingMs);
    return formatDuration(duration);
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: _sessionState.status == FocusSessionStatus.idle ? _onStart : null,
      child: const Text('Start'),
    );
  }

  Widget _buildPauseResumeButton() {
    final isRunning = _sessionState.status == FocusSessionStatus.running;
    final isPaused = _sessionState.status == FocusSessionStatus.paused;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: isRunning ? _onPause : (isPaused ? _onResume : null),
      child: Text(isRunning ? 'Pause' : 'Resume'),
    );
  }

  Widget _buildCompleteButton() {
    final canComplete = _sessionState.status == FocusSessionStatus.running ||
                       _sessionState.status == FocusSessionStatus.paused;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: canComplete ? _onComplete : null,
      child: const Text('Complete'),
    );
  }

  Widget _buildCancelButton() {
    final canCancel = _sessionState.status != FocusSessionStatus.idle &&
                     _sessionState.status != FocusSessionStatus.completed;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: canCancel ? _onCancel : null,
      child: const Text('Cancel'),
    );
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
                _getDisplayTime(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStartButton(),
              const SizedBox(height: 16),
              _buildPauseResumeButton(),
              const SizedBox(height: 16),
              _buildCompleteButton(),
              const SizedBox(height: 16),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }
}