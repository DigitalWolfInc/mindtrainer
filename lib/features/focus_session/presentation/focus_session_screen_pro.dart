/// Pro-Integrated Focus Session Screen
/// 
/// Enhanced version of the focus session screen with Pro feature integration.
/// Handles session limits, upgrade prompts, and Pro status display.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/time_format.dart';
import '../domain/session_limit_service.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/payments/play_billing_pro_manager.dart';
import '../../../payments/pro_gate.dart';
import '../../../core/session_tags.dart';
import '../domain/focus_session_state.dart';
import '../../../a11y/a11y.dart';
import '../../../i18n/i18n.dart';
import '../domain/focus_session_repository.dart';
import '../domain/session_limit_service.dart';
import '../data/focus_session_repository_impl.dart';
import 'session_completion_dialog.dart';
import 'pro_status_widgets.dart';

// TODO: restore to 25 * 60 before release
const int kDefaultSessionSeconds = 10;

class FocusSessionScreenPro extends StatefulWidget {
  final MindTrainerProGates? proGates; // For testing - will use DI in production
  
  const FocusSessionScreenPro({
    super.key,
    this.proGates,
  });

  @override
  State<FocusSessionScreenPro> createState() => _FocusSessionScreenProState();
}

class _FocusSessionScreenProState extends State<FocusSessionScreenPro> {
  Timer? _timer;
  FocusSessionState _sessionState = FocusSessionState.idle(kDefaultSessionSeconds * 1000);
  late final FocusSessionRepository _repository;
  late final SessionLimitService _limitService;
  late final MindTrainerProGates _proGates;
  
  List<Session> _completedSessions = [];
  SessionStartResult? _currentLimitResult;
  bool _showUpgradeBanner = true;

  @override
  void initState() {
    super.initState();
    _repository = FocusSessionRepositoryImpl();
    
    // Use EntitlementResolver-based Pro gates (or test override)
    _proGates = widget.proGates ?? MindTrainerProGates.fromEntitlementResolver();
    _limitService = SessionLimitService(_proGates);
    
    _loadActiveSession();
    _loadCompletedSessions();
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
  
  Future<void> _loadCompletedSessions() async {
    // TODO: Implement actual session loading from repository
    // For now, create fake sessions for demo
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      _completedSessions = [
        Session(
          id: '1',
          dateTime: today.add(const Duration(hours: 9)),
          durationMinutes: 25,
          tags: ['morning', 'focused'],
        ),
        Session(
          id: '2', 
          dateTime: today.add(const Duration(hours: 11)),
          durationMinutes: 30,
          tags: ['deep-work'],
        ),
        Session(
          id: '3',
          dateTime: today.add(const Duration(hours: 14)),
          durationMinutes: 20,
          tags: ['afternoon'],
        ),
        Session(
          id: '4',
          dateTime: today.add(const Duration(hours: 16)),
          durationMinutes: 25,
          tags: ['focused'],
        ),
      ];
    });
    
    _updateLimitStatus();
  }

  void _updateLimitStatus() {
    setState(() {
      _currentLimitResult = _limitService.checkCanStartSession(_completedSessions);
    });
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
    // Check session limits before starting
    final limitResult = _limitService.checkCanStartSession(_completedSessions);
    
    if (!limitResult.canStart) {
      // Show upgrade dialog instead of starting session
      await _showSessionLimitDialog(limitResult);
      return;
    }
    
    setState(() {
      _sessionState = _sessionState.start();
    });
    await _saveActiveSession();
    _startTimer();
    
    // Update status after starting
    _updateLimitStatus();
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
    await _saveActiveSession();
    
    if (!mounted) return;

    // Show completion dialog
    final metadata = await showDialog<SessionMetadata?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SessionCompletionDialog(),
    );

    if (metadata != null) {
      // Save completed session
      final now = DateTime.now();
      final durationMinutes = (_sessionState.currentElapsedMs / 60000).round();
      final completedSession = Session(
        id: 'session_${now.millisecondsSinceEpoch}',
        dateTime: now.subtract(Duration(minutes: durationMinutes)),
        durationMinutes: durationMinutes,
        tags: metadata.tags,
        note: metadata.note.isNotEmpty ? metadata.note : null,
      );
      
      setState(() {
        _completedSessions.add(completedSession);
        _sessionState = FocusSessionState.idle(kDefaultSessionSeconds * 1000);
      });
      
      _updateLimitStatus();
      
      // TODO: Save to repository
      await _repository.clearActiveSession();
    }
  }

  Future<void> _showSessionLimitDialog(SessionStartResult result) async {
    await showDialog(
      context: context,
      builder: (context) => SessionLimitUpgradeDialog(
        result: result,
        onUpgrade: _handleUpgrade,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
  
  void _handleUpgrade() async {
    Navigator.pop(context); // Close dialog
    
    // Use soft-gating via ProGate helper
    await context.maybePromptPaywall();
  }
  
  void _dismissUpgradeBanner() {
    setState(() {
      _showUpgradeBanner = false;
    });
  }
  
  /// Demo function to toggle Pro status for testing
  void _toggleProStatus() {
    // This would not exist in production - for demo only
    final currentStatus = _proGates.isProActive;
    final newGates = MindTrainerProGates.fromStatusCheck(() => !currentStatus);
    setState(() {
      // Would normally be handled by dependency injection
    });
    _updateLimitStatus();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentStatus ? 'Switched to Free tier' : 'Switched to Pro tier'),
        backgroundColor: currentStatus ? Colors.orange : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
        actions: [
          // Demo Pro toggle button - remove in production
          A11y.accessibleIconButton(
            icon: _proGates.isProActive ? Icons.star : Icons.star_outline,
            onPressed: _toggleProStatus,
            label: 'Toggle Pro Status (Demo)',
            hint: _proGates.isProActive ? 'Switch to free tier' : 'Switch to Pro tier',
            tooltip: 'Toggle Pro Status (Demo)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pro status and session limits
          if (_currentLimitResult != null)
            SessionLimitBanner(
              result: _currentLimitResult!,
              onUpgradeTap: _showUpgradeBanner ? _handleUpgrade : null,
              onDismiss: _showUpgradeBanner ? _dismissUpgradeBanner : null,
            ),
          
          // Session usage summary
          SessionLimitStatusCard(
            usage: _limitService.getUsageSummary(_completedSessions),
            onUpgradeTap: _proGates.isProActive ? null : _handleUpgrade,
          ),
          
          // Main session UI
          Expanded(
            child: _buildSessionUI(),
          ),
          
          // Pro features preview (shown occasionally to free users)
          if (!_proGates.isProActive && _limitService.shouldShowUpgradeHint(_completedSessions))
            UnlimitedSessionsPreview(onLearnMore: _handleUpgrade),
        ],
      ),
    );
  }

  Widget _buildSessionUI() {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    final timeText = formatDuration(Duration(milliseconds: _sessionState.currentRemainingMs));
    
    return FocusTraversalGroup(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer display with accessibility
            A11y.focusTraversalOrder(
              order: 1.0,
              child: A11y.accessibleTimer(
                timeText: timeText,
                context: context,
                style: TextStyle(
                  fontSize: 48 * textScaler,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Session status with live region
            if (_currentLimitResult != null)
              A11y.focusTraversalOrder(
                order: 2.0,
                child: Semantics(
                  liveRegion: true,
                  child: SessionStatusText(result: _currentLimitResult!),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Control buttons with proper order
            A11y.focusTraversalOrder(
              order: 3.0,
              child: _buildControlButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    
    switch (_sessionState.status) {
      case FocusSessionStatus.idle:
        final canStart = _currentLimitResult?.canStart ?? true;
        return Column(
          children: [
            A11y.accessibleButton(
              onPressed: canStart ? _onStart : null,
              label: canStart ? strings.actionStart : 'Daily limit reached',
              hint: canStart ? 'Start a new focus session' : 'Upgrade to Pro for unlimited sessions',
              child: SizedBox(
                width: 200,
                height: 56,
                child: Text(
                  canStart ? strings.actionStart : 'Daily Limit Reached',
                  style: TextStyle(fontSize: 18 * textScaler),
                ),
              ),
            ),
            if (!canStart) ...[
              const SizedBox(height: 12),
              A11y.accessibleButton(
                onPressed: () => context.maybePromptPaywall(),
                label: strings.proUpgradeForUnlimited,
                hint: strings.proUnlockHint,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      strings.proUpgradeForUnlimited,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16 * textScaler,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
        
      case FocusSessionStatus.running:
        return Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            A11y.accessibleButton(
              onPressed: _onPause,
              label: strings.actionPause,
              hint: strings.a11yPauseButton,
              child: Text(
                strings.actionPause,
                style: TextStyle(fontSize: 16 * textScaler),
              ),
            ),
            A11y.accessibleButton(
              onPressed: _onComplete,
              label: strings.focusSessionComplete,
              hint: strings.a11yCompleteButton,
              child: Text(
                strings.focusSessionComplete,
                style: TextStyle(fontSize: 16 * textScaler),
              ),
            ),
            A11y.ensureMinTouchTarget(
              OutlinedButton(
                onPressed: _onCancel,
                child: Semantics(
                  label: strings.focusSessionCancel,
                  hint: strings.a11yCancelButton,
                  button: true,
                  child: Text(
                    strings.focusSessionCancel,
                    style: TextStyle(fontSize: 16 * textScaler),
                  ),
                ),
              ),
            ),
          ],
        );
        
      case FocusSessionStatus.paused:
        return Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            A11y.accessibleButton(
              onPressed: _onResume,
              label: strings.actionResume,
              hint: strings.a11yResumeButton,
              child: Text(
                strings.actionResume,
                style: TextStyle(fontSize: 16 * textScaler),
              ),
            ),
            A11y.accessibleButton(
              onPressed: _onComplete,
              label: strings.focusSessionComplete,
              hint: strings.a11yCompleteButton,
              child: Text(
                strings.focusSessionComplete,
                style: TextStyle(fontSize: 16 * textScaler),
              ),
            ),
            A11y.ensureMinTouchTarget(
              OutlinedButton(
                onPressed: _onCancel,
                child: Semantics(
                  label: strings.focusSessionCancel,
                  hint: strings.a11yCancelButton,
                  button: true,
                  child: Text(
                    strings.focusSessionCancel,
                    style: TextStyle(fontSize: 16 * textScaler),
                  ),
                ),
              ),
            ),
          ],
        );
        
      case FocusSessionStatus.completed:
        return Semantics(
          label: 'Processing session completion',
          liveRegion: true,
          child: const CircularProgressIndicator(),
        );
    }
  }
}