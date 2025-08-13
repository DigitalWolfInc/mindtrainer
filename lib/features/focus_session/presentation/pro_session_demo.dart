/// Demo/Example of Pro Session Limits Integration
/// 
/// This file demonstrates how to integrate the first Pro feature (unlimited sessions)
/// into the MindTrainer app. It serves as a reference for implementing other Pro features.

import 'package:flutter/material.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/session_tags.dart';
import '../domain/session_limit_service.dart';
import 'pro_status_widgets.dart';

/// Simple demo screen showing Pro session limits in action
class ProSessionDemo extends StatefulWidget {
  const ProSessionDemo({super.key});

  @override
  State<ProSessionDemo> createState() => _ProSessionDemoState();
}

class _ProSessionDemoState extends State<ProSessionDemo> {
  late SessionLimitService _limitService;
  late MindTrainerProGates _proGates;
  bool _isProActive = false;
  List<Session> _todaySessions = [];
  
  @override
  void initState() {
    super.initState();
    _initializeProGates();
    _createMockSessions();
  }
  
  void _initializeProGates() {
    _proGates = MindTrainerProGates.fromStatusCheck(() => _isProActive);
    _limitService = SessionLimitService(_proGates);
  }
  
  void _createMockSessions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Create 4 sessions today to demonstrate approaching limit
    _todaySessions = List.generate(4, (i) => Session(
      id: 'demo_session_$i',
      dateTime: today.add(Duration(hours: 8 + i * 2)),
      durationMinutes: 25,
      tags: ['demo', 'focus'],
    ));
  }
  
  void _toggleProStatus() {
    setState(() {
      _isProActive = !_isProActive;
      _initializeProGates(); // Recreate gates with new status
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isProActive ? 'Upgraded to Pro! 🎉' : 'Switched to Free tier'),
        backgroundColor: _isProActive ? Colors.green : Colors.orange,
      ),
    );
  }
  
  void _simulateSessionStart() {
    final limitResult = _limitService.checkCanStartSession(_todaySessions);
    
    if (limitResult.canStart) {
      // Simulate adding a new session
      setState(() {
        _todaySessions.add(Session(
          id: 'session_${_todaySessions.length + 1}',
          dateTime: DateTime.now(),
          durationMinutes: 25,
          tags: ['demo'],
        ));
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session started! 🧠'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      // Show upgrade dialog
      _showUpgradeDialog(limitResult);
    }
  }
  
  void _showUpgradeDialog(SessionStartResult result) {
    showDialog(
      context: context,
      builder: (context) => SessionLimitUpgradeDialog(
        result: result,
        onUpgrade: () {
          Navigator.pop(context);
          _toggleProStatus();
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final limitResult = _limitService.checkCanStartSession(_todaySessions);
    final usageSummary = _limitService.getUsageSummary(_todaySessions);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Session Limits Demo'),
        actions: [
          IconButton(
            onPressed: _toggleProStatus,
            icon: Icon(
              _isProActive ? Icons.star : Icons.star_outline,
              color: _isProActive ? Colors.amber : null,
            ),
            tooltip: _isProActive ? 'Switch to Free' : 'Upgrade to Pro',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Pro Status Display
            SessionLimitStatusCard(
              usage: usageSummary,
              onUpgradeTap: _isProActive ? null : _toggleProStatus,
            ),
            
            // Limit Banner (shows when approaching/at limit)
            if (!limitResult.canStart || limitResult.requiresUpgrade)
              SessionLimitBanner(
                result: limitResult,
                onUpgradeTap: _toggleProStatus,
              ),
            
            // Pro Features Preview (for free users)
            if (!_isProActive && _limitService.shouldShowUpgradeHint(_todaySessions))
              UnlimitedSessionsPreview(onLearnMore: _toggleProStatus),
            
            // Demo Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Demo Controls',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: limitResult.canStart ? _simulateSessionStart : null,
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('Start Focus Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: limitResult.canStart ? Colors.blue : Colors.grey,
                    ),
                  ),
                  
                  if (!limitResult.canStart) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showUpgradeDialog(limitResult),
                      icon: const Icon(Icons.star, color: Colors.amber),
                      label: const Text(
                        'Upgrade to Continue',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _createMockSessions(); // Reset to 4 sessions
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Demo'),
                  ),
                ],
              ),
            ),
            
            // Feature Information
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Pro Session Limits Work',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildFeaturePoint(
                      icon: Icons.lock_outline,
                      title: 'Free Tier',
                      description: '5 sessions per day maximum',
                    ),
                    
                    _buildFeaturePoint(
                      icon: Icons.all_inclusive,
                      title: 'Pro Unlimited',
                      description: 'No daily session limits',
                    ),
                    
                    _buildFeaturePoint(
                      icon: Icons.warning_amber,
                      title: 'Smart Warnings',
                      description: 'Gentle reminders before hitting limits',
                    ),
                    
                    _buildFeaturePoint(
                      icon: Icons.star_outline,
                      title: 'Seamless Upgrade',
                      description: 'Instant unlock after Pro purchase',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Current Status: ${limitResult.statusMessage}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _isProActive ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeaturePoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}