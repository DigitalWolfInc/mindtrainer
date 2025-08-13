import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/time_format.dart';
import '../../../core/feature_flags.dart';
import '../domain/focus_session_state.dart';
import '../domain/focus_session_repository.dart';
import '../data/focus_session_repository_impl.dart';
import '../services/focus_timer_prefs.dart';
import 'session_completion_dialog.dart';

// Debug short durations (ignored in release builds)
const int _debugShortDurationSeconds = 10;
const int _defaultSessionSeconds = 25 * 60; // 25 minutes

class FocusSessionScreen extends StatefulWidget {
  final Duration? initialDuration;
  
  const FocusSessionScreen({super.key, this.initialDuration});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  FocusSessionState? _sessionState;
  late final FocusSessionRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = FocusSessionRepositoryImpl();
    _initializeSession();
  }
  
  Future<void> _initializeSession() async {
    await _loadActiveSession();
    
    // If no active session and we have an initial duration, create new session
    if (_sessionState == null && widget.initialDuration != null) {
      final durationMs = widget.initialDuration!.inMilliseconds;
      setState(() {
        _sessionState = FocusSessionState.idle(durationMs);
      });
      _startSessionImmediately();
    } else if (_sessionState == null) {
      // Create default session
      final defaultDuration = await _getDefaultDuration();
      setState(() {
        _sessionState = FocusSessionState.idle(defaultDuration.inMilliseconds);
      });
    }
  }
  
  Future<Duration> _getDefaultDuration() async {
    // Use debug duration in debug mode only
    if (kDebugMode && FeatureFlags.focusTimerChipsEnabled) {
      return Duration(seconds: _debugShortDurationSeconds);
    }
    
    // Otherwise use saved preference or standard default
    try {
      return await FocusTimerPrefs.instance.getLastDuration();
    } catch (e) {
      return Duration(seconds: _defaultSessionSeconds);
    }
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
      
      if (_sessionState!.status == FocusSessionStatus.running) {
        _startTimer();
      }
    }
  }
  
  void _startSessionImmediately() {
    if (_sessionState != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _sessionState = _sessionState!.start();
      });
      _saveActiveSession();
      _startTimer();
    }
  }

  Future<void> _saveActiveSession() async {
    if (_sessionState == null) return;
    
    if (_sessionState!.status == FocusSessionStatus.idle || 
        _sessionState!.status == FocusSessionStatus.completed) {
      await _repository.clearActiveSession();
    } else {
      await _repository.saveActiveSession(_sessionState!);
    }
  }

  void _startTimer() {
    if (_sessionState == null) return;
    
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_sessionState == null) return;
      
      setState(() {
        _sessionState = _sessionState!.tick();
      });
      
      if (_sessionState!.status == FocusSessionStatus.completed) {
        await _onSessionCompleted();
      }
    });
  }

  Future<void> _onStart() async {
    if (_sessionState == null) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionState = _sessionState!.start();
    });
    await _saveActiveSession();
    _startTimer();
  }

  Future<void> _onPause() async {
    if (_sessionState == null) return;
    
    _timer?.cancel();
    setState(() {
      _sessionState = _sessionState!.pause();
    });
    await _saveActiveSession();
  }

  Future<void> _onResume() async {
    if (_sessionState == null) return;
    
    setState(() {
      _sessionState = _sessionState!.start();
    });
    await _saveActiveSession();
    _startTimer();
  }

  Future<void> _onComplete() async {
    if (_sessionState == null) return;
    
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
        _sessionState = _sessionState!.complete();
      });
      await _onSessionCompleted();
    }
  }

  Future<void> _onCancel() async {
    if (_sessionState == null) return;
    
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
        _sessionState = _sessionState!.cancel();
      });
      await _saveActiveSession();
    }
  }

  Future<void> _onSessionCompleted() async {
    if (_sessionState == null) return;
    
    _timer?.cancel();
    
    final durationMinutes = (_sessionState!.elapsedMs / 60000).round();
    
    // Save duration as last used (only if session was meaningful)
    if (durationMinutes >= 1) {
      await FocusTimerPrefs.instance.setLastDuration(Duration(minutes: durationMinutes));
    }
    
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
    if (_sessionState == null) return '00:00';
    
    final remainingMs = _sessionState!.currentRemainingMs;
    final duration = Duration(milliseconds: remainingMs);
    return formatDuration(duration);
  }

  Widget _buildStartButton() {
    if (_sessionState == null) return const SizedBox.shrink();
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: _sessionState!.status == FocusSessionStatus.idle ? _onStart : null,
      child: const Text('Start'),
    );
  }

  Widget _buildPauseResumeButton() {
    if (_sessionState == null) return const SizedBox.shrink();
    
    final isRunning = _sessionState!.status == FocusSessionStatus.running;
    final isPaused = _sessionState!.status == FocusSessionStatus.paused;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: isRunning ? _onPause : (isPaused ? _onResume : null),
      child: Text(isRunning ? 'Pause' : 'Resume'),
    );
  }

  Widget _buildCompleteButton() {
    if (_sessionState == null) return const SizedBox.shrink();
    
    final canComplete = _sessionState!.status == FocusSessionStatus.running ||
                       _sessionState!.status == FocusSessionStatus.paused;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: canComplete ? _onComplete : null,
      child: const Text('Complete'),
    );
  }

  Widget _buildCancelButton() {
    if (_sessionState == null) return const SizedBox.shrink();
    
    final canCancel = _sessionState!.status != FocusSessionStatus.idle &&
                     _sessionState!.status != FocusSessionStatus.completed;
    
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
      body: _sessionState == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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