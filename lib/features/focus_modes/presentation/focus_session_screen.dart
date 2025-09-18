/// Focus Session Screen with Advanced Environment Support
/// 
/// Enhanced focus session experience with Pro environmental features.

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/payments/pro_feature_gates.dart';
import '../domain/focus_environment.dart';
import '../application/focus_mode_service.dart';

class FocusSessionScreen extends StatefulWidget {
  final FocusSessionConfig sessionConfig;
  final MindTrainerProGates proGates;
  final FocusModeService focusModeService;
  final Function(FocusSessionOutcome)? onSessionComplete;
  
  const FocusSessionScreen({
    super.key,
    required this.sessionConfig,
    required this.proGates,
    required this.focusModeService,
    this.onSessionComplete,
  });
  
  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _progressController;
  
  StreamSubscription<FocusSessionState>? _stateSubscription;
  StreamSubscription<double>? _progressSubscription;
  StreamSubscription<String>? _breathingSubscription;
  
  FocusSessionState _sessionState = FocusSessionState.preparing;
  double _progress = 0.0;
  String _breathingInstruction = '';
  bool _isPaused = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4), // Default, will be updated
      vsync: this,
    );
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _progressController = AnimationController(
      duration: Duration(minutes: widget.sessionConfig.sessionDurationMinutes),
      vsync: this,
    );
    
    // Listen to service streams
    _setupServiceListeners();
    
    // Start session
    _startSession();
  }
  
  @override
  void dispose() {
    _breathingController.dispose();
    _progressController.dispose();
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();
    _breathingSubscription?.cancel();
    super.dispose();
  }
  
  void _setupServiceListeners() {
    _stateSubscription = widget.focusModeService.stateStream.listen((state) {
      setState(() {
        _sessionState = state;
        _isPaused = state == FocusSessionState.paused;
      });
      
      if (state == FocusSessionState.completed) {
        _onSessionComplete();
      }
    });
    
    _progressSubscription = widget.focusModeService.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });
      _progressController.animateTo(progress);
    });
    
    _breathingSubscription = widget.focusModeService.breathingInstructionStream.listen((instruction) {
      setState(() {
        _breathingInstruction = instruction;
      });
      _updateBreathingAnimation(instruction);
    });
  }
  
  Future<void> _startSession() async {
    final success = await widget.focusModeService.startSession(widget.sessionConfig);
    if (!success && mounted) {
      Navigator.of(context).pop();
    }
  }
  
  void _updateBreathingAnimation(String instruction) {
    if (instruction.contains('in')) {
      _breathingController.forward();
    } else if (instruction.contains('out')) {
      _breathingController.reverse();
    } else if (instruction.contains('hold') || instruction.contains('pause')) {
      // Keep current position
    }
  }
  
  Future<void> _onSessionComplete() async {
    final rating = await _showCompletionDialog();
    final outcome = await widget.focusModeService.stopSession(focusRating: rating);
    
    if (outcome != null && mounted) {
      widget.onSessionComplete?.call(outcome);
      Navigator.of(context).pop();
    }
  }
  
  Future<int> _showCompletionDialog() async {
    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How focused did you feel during this session?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(rating),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Center(
                      child: Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ) ?? 3; // Default rating
  }
  
  @override
  Widget build(BuildContext context) {
    final envConfig = FocusEnvironmentConfig.getConfig(widget.sessionConfig.environment)!;
    final colorTheme = Color(int.parse(envConfig.colorTheme.substring(1), radix: 16) + 0xFF000000);
    
    return Scaffold(
      backgroundColor: colorTheme.withOpacity(0.1),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorTheme.withOpacity(0.3),
              colorTheme.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with environment info and controls
              _buildHeader(context, envConfig),
              
              // Main session area
              Expanded(
                child: _buildSessionContent(context, colorTheme),
              ),
              
              // Controls
              _buildControls(context),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, FocusEnvironmentConfig envConfig) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envConfig.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.sessionConfig.sessionDurationMinutes} min session',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Volume control for Pro users
          if (widget.proGates.isProActive && envConfig.soundFiles.isNotEmpty)
            IconButton(
              onPressed: () {
                // Show volume control
              },
              icon: const Icon(Icons.volume_up),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSessionContent(BuildContext context, Color colorTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          _buildProgressIndicator(colorTheme),
          
          const SizedBox(height: 48),
          
          // Breathing visualization or focus indicator
          if (_sessionState == FocusSessionState.breathing)
            _buildBreathingVisualization(colorTheme)
          else
            _buildFocusVisualization(colorTheme),
          
          const SizedBox(height: 48),
          
          // Session state text
          _buildStateText(context),
          
          // Time remaining
          _buildTimeDisplay(context),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator(Color colorTheme) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          
          // Progress arc
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(colorTheme),
            ),
          ),
          
          // Center content
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBreathingVisualization(Color colorTheme) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Container(
          width: 120 * _breathingAnimation.value,
          height: 120 * _breathingAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorTheme.withOpacity(0.3),
            border: Border.all(
              color: colorTheme,
              width: 2,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFocusVisualization(Color colorTheme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorTheme.withOpacity(0.2),
        border: Border.all(
          color: colorTheme,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.self_improvement,
        size: 48,
        color: colorTheme,
      ),
    );
  }
  
  Widget _buildStateText(BuildContext context) {
    String stateText;
    switch (_sessionState) {
      case FocusSessionState.preparing:
        stateText = 'Preparing...';
        break;
      case FocusSessionState.breathing:
        stateText = _breathingInstruction.isNotEmpty 
            ? _breathingInstruction 
            : 'Follow your breath';
        break;
      case FocusSessionState.focusing:
        stateText = 'Focus on your breath';
        break;
      case FocusSessionState.transitioning:
        stateText = 'Settling into focus...';
        break;
      case FocusSessionState.paused:
        stateText = 'Session paused';
        break;
      case FocusSessionState.completed:
        stateText = 'Session complete';
        break;
    }
    
    return Text(
      stateText,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w300,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildTimeDisplay(BuildContext context) {
    final remainingMinutes = max(0, widget.sessionConfig.sessionDurationMinutes - (_progress * widget.sessionConfig.sessionDurationMinutes).round());
    
    return Text(
      '$remainingMinutes min remaining',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.white70,
      ),
    );
  }
  
  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pause/Resume button
        FloatingActionButton(
          onPressed: () {
            if (_isPaused) {
              widget.focusModeService.resumeSession();
            } else {
              widget.focusModeService.pauseSession();
            }
          },
          backgroundColor: Colors.white,
          child: Icon(
            _isPaused ? Icons.play_arrow : Icons.pause,
            color: Colors.grey[800],
          ),
        ),
        
        // Stop button
        FloatingActionButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('End Session'),
                content: const Text('Are you sure you want to end this session early?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Continue'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('End Session'),
                  ),
                ],
              ),
            );
            
            if (confirm == true) {
              _onSessionComplete();
            }
          },
          backgroundColor: Colors.red[400],
          child: const Icon(
            Icons.stop,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}