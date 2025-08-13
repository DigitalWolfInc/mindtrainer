/// Advanced Focus Modes Pro Feature Screen
/// 
/// First Pro feature implementation demonstrating proper gating, preview/teaser in free mode,
/// and full functionality for Pro users. Serves as template for other Pro features.

import 'package:flutter/material.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/payments/pro_status.dart';
import '../application/focus_mode_service.dart';
import '../domain/focus_environment.dart';
import 'focus_environment_selector.dart';
import 'breathing_pattern_selector.dart';

class AdvancedFocusModesScreen extends StatefulWidget {
  final MindTrainerProGates proGates;
  final FocusModeService focusService;
  final VoidCallback? onProUpgradeRequested;

  const AdvancedFocusModesScreen({
    super.key,
    required this.proGates,
    required this.focusService,
    this.onProUpgradeRequested,
  });

  @override
  State<AdvancedFocusModesScreen> createState() => _AdvancedFocusModesScreenState();
}

class _AdvancedFocusModesScreenState extends State<AdvancedFocusModesScreen> {
  FocusEnvironment _selectedEnvironment = FocusEnvironment.silence;
  BreathingPattern? _selectedBreathingPattern;
  double _soundVolume = 0.6;
  bool _enableBinauralBeats = false;
  bool _enableBreathingCues = false;
  int _sessionDuration = 10;
  
  FocusSessionState _sessionState = FocusSessionState.preparing;
  double _sessionProgress = 0.0;
  String _breathingInstruction = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _setupListeners();
  }

  @override
  void dispose() {
    widget.focusService.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final preferred = await widget.focusService.getPreferredEnvironment();
    if (mounted) {
      setState(() {
        _selectedEnvironment = preferred;
      });
    }
  }

  void _setupListeners() {
    widget.focusService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _sessionState = state;
        });
      }
    });

    widget.focusService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _sessionProgress = progress;
        });
      }
    });

    widget.focusService.breathingInstructionStream.listen((instruction) {
      if (mounted) {
        setState(() {
          _breathingInstruction = instruction;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Advanced Focus Modes'),
            const SizedBox(width: 8),
            if (!widget.proGates.isProActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: _getThemeColor(),
        foregroundColor: Colors.white,
        actions: [
          if (!widget.proGates.isProActive)
            TextButton(
              onPressed: widget.onProUpgradeRequested,
              child: const Text(
                'Upgrade',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _sessionState == FocusSessionState.preparing
          ? _buildSetupView()
          : _buildSessionView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pro Status Banner
          if (!widget.proGates.isProActive) _buildProBanner(),
          
          // Environment Selection
          FocusEnvironmentSelector(
            selectedEnvironment: _selectedEnvironment,
            proGates: widget.proGates,
            onEnvironmentSelected: (environment) {
              setState(() {
                _selectedEnvironment = environment;
              });
              widget.focusService.setPreferredEnvironment(environment);
            },
            onProUpgradeRequested: widget.onProUpgradeRequested,
          ),
          
          const SizedBox(height: 24),
          
          // Advanced Settings (Pro Only)
          _buildAdvancedSettings(),
          
          const SizedBox(height: 24),
          
          // Session Duration
          _buildSessionDurationSelector(),
          
          const SizedBox(height: 32),
          
          // Start Button
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildProBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Premium Focus Environments',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '9 immersive soundscapes, breathing cues, and binaural beats',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onProUpgradeRequested,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
            ),
            child: const Text('Try Pro'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    final envConfig = FocusEnvironmentConfig.getConfig(_selectedEnvironment);
    final isProEnvironment = envConfig?.isProOnly ?? false;
    final hasProAccess = widget.proGates.isProActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (!hasProAccess)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Breathing Pattern Selection
        if (hasProAccess || !isProEnvironment) ...[
          BreathingPatternSelector(
            selectedPattern: _selectedBreathingPattern,
            onPatternSelected: hasProAccess ? (pattern) {
              setState(() {
                _selectedBreathingPattern = pattern;
                if (pattern != null) {
                  _enableBreathingCues = true;
                }
              });
            } : null,
            enabled: hasProAccess,
          ),
          
          const SizedBox(height: 16),
        ],
        
        // Sound Volume
        if (envConfig?.soundFiles.isNotEmpty ?? false) ...[
          _buildVolumeSlider(hasProAccess),
          const SizedBox(height: 16),
        ],
        
        // Advanced Options
        if (hasProAccess) ...[
          _buildAdvancedOptions(envConfig),
        ] else ...[
          _buildLockedAdvancedOptions(),
        ],
      ],
    );
  }

  Widget _buildVolumeSlider(bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sound Volume'),
        const SizedBox(height: 4),
        Slider(
          value: _soundVolume,
          onChanged: enabled ? (value) {
            setState(() {
              _soundVolume = value;
            });
          } : null,
          divisions: 10,
          label: '${(_soundVolume * 100).round()}%',
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions(FocusEnvironmentConfig? config) {
    return Column(
      children: [
        if (config?.supportsBinauralBeats == true)
          SwitchListTile(
            title: const Text('Binaural Beats'),
            subtitle: const Text('Enhanced focus frequencies'),
            value: _enableBinauralBeats,
            onChanged: (value) {
              setState(() {
                _enableBinauralBeats = value;
              });
            },
          ),
        
        if (_selectedBreathingPattern != null)
          SwitchListTile(
            title: const Text('Breathing Cues'),
            subtitle: const Text('Guided breathing prompts'),
            value: _enableBreathingCues,
            onChanged: (value) {
              setState(() {
                _enableBreathingCues = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildLockedAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Pro Features',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.headphones, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Text('Binaural Beats', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.air, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Text('Breathing Cues', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.tune, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Text('Custom Patterns', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Duration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          children: [5, 10, 15, 20, 30].map((minutes) {
            final isSelected = _sessionDuration == minutes;
            return ChoiceChip(
              label: Text('${minutes}m'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _sessionDuration = minutes;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final envConfig = FocusEnvironmentConfig.getConfig(_selectedEnvironment);
    final canStart = envConfig != null && (!envConfig.isProOnly || widget.proGates.isProActive);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canStart ? _startSession : widget.onProUpgradeRequested,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart ? _getThemeColor() : Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          canStart ? 'Start Focus Session' : 'Upgrade to Pro',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getThemeColor(),
            _getThemeColor().withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Session Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    FocusEnvironmentConfig.getConfig(_selectedEnvironment)?.name ?? 'Focus Session',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSessionStateText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress Ring
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _sessionProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Breathing Instructions
                    if (_sessionState == FocusSessionState.breathing)
                      Text(
                        _breathingInstruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    
                    // Session Progress
                    Text(
                      _getProgressText(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Session Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_sessionState == FocusSessionState.paused)
                    ElevatedButton(
                      onPressed: () => widget.focusService.resumeSession(),
                      child: const Text('Resume'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => widget.focusService.pauseSession(),
                      child: const Text('Pause'),
                    ),
                  
                  ElevatedButton(
                    onPressed: _stopSession,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor() {
    final envConfig = FocusEnvironmentConfig.getConfig(_selectedEnvironment);
    if (envConfig != null) {
      return Color(int.parse(envConfig.colorTheme.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.blue;
  }

  String _getSessionStateText() {
    switch (_sessionState) {
      case FocusSessionState.preparing:
        return 'Preparing...';
      case FocusSessionState.breathing:
        return 'Breathing Phase';
      case FocusSessionState.focusing:
        return 'Focus Session';
      case FocusSessionState.transitioning:
        return 'Transitioning...';
      case FocusSessionState.paused:
        return 'Paused';
      case FocusSessionState.completed:
        return 'Completed!';
    }
  }

  String _getProgressText() {
    final totalSeconds = _sessionDuration * 60;
    final elapsedSeconds = (totalSeconds * _sessionProgress).round();
    final remainingSeconds = totalSeconds - elapsedSeconds;
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} remaining';
  }

  void _startSession() async {
    final config = widget.proGates.isProActive
        ? FocusSessionConfig.pro(
            environment: _selectedEnvironment,
            sessionDurationMinutes: _sessionDuration,
            breathingPattern: _selectedBreathingPattern,
            soundVolume: _soundVolume,
            enableBinauralBeats: _enableBinauralBeats,
            enableBreathingCues: _enableBreathingCues,
          )
        : FocusSessionConfig.basic(
            environment: _selectedEnvironment,
            sessionDurationMinutes: _sessionDuration,
          );

    final started = await widget.focusService.startSession(config);
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start session. Please try again.'),
        ),
      );
    }
  }

  void _stopSession() async {
    final outcome = await widget.focusService.stopSession(
      focusRating: 4, // Could show rating dialog
    );
    
    if (outcome != null && mounted) {
      // Show completion dialog or navigate to results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Session Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration: ${outcome.actualDuration.inMinutes} minutes'),
              Text('Completion: ${outcome.completionPercentage}%'),
              if (outcome.completedWithBreathing)
                Text('Breathing cycles: ${outcome.breathingCyclesCompleted}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}