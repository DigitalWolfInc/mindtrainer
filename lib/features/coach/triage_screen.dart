import 'package:flutter/material.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Coach triage screen for state-based suggestions
class CoachTriageScreen extends StatelessWidget {
  const CoachTriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Pick Your State',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling right now?',
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (18 * textScaler).toDouble(),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what feels closest to help me guide you',
              style: TextStyle(
                color: const Color(0xFFC7D1DD),
                fontSize: (16 * textScaler).toDouble(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildStateCard(
                    context,
                    title: 'Wired',
                    subtitle: 'Anxious, restless, can\'t sit still',
                    icon: Icons.electric_bolt,
                    color: Colors.orange,
                    onTap: () => _handleStateSelection(context, 'wired'),
                    textScaler: textScaler,
                  ),
                  _buildStateCard(
                    context,
                    title: 'Stuck',
                    subtitle: 'Overwhelmed, don\'t know what to do',
                    icon: Icons.help_outline,
                    color: Colors.blue,
                    onTap: () => _handleStateSelection(context, 'stuck'),
                    textScaler: textScaler,
                  ),
                  _buildStateCard(
                    context,
                    title: 'Low',
                    subtitle: 'Sad, tired, unmotivated',
                    icon: Icons.trending_down,
                    color: Colors.indigo,
                    onTap: () => _handleStateSelection(context, 'low'),
                    textScaler: textScaler,
                  ),
                  _buildStateCard(
                    context,
                    title: 'Can\'t Sleep',
                    subtitle: 'Mind racing, can\'t wind down',
                    icon: Icons.bedtime_off,
                    color: Colors.purple,
                    onTap: () => _handleStateSelection(context, 'sleep'),
                    textScaler: textScaler,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => R.go(context, '/coach'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF2F5F7),
                side: const BorderSide(color: Color(0xA3274862)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Just Talk to Coach Instead',
                style: TextStyle(
                  fontSize: (16 * textScaler).toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double textScaler,
  }) {
    return A11y.ensureMinTouchTarget(
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2436),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(width: 1.2, color: const Color(0xA3274862)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFFF2F5F7),
                  fontSize: (16 * textScaler).toDouble(),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFFC7D1DD),
                  fontSize: (12 * textScaler).toDouble(),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStateSelection(BuildContext context, String state) {
    // Navigate to coach with pre-filled message or suggested tools
    final suggestions = {
      'wired': {
        'message': 'I\'m feeling wired and anxious right now.',
        'tools': ['/tools/calm-breath', '/tools/phys-sigh'],
      },
      'stuck': {
        'message': 'I feel stuck and overwhelmed.',
        'tools': ['/tools/tiny-next-step', '/tools/energy-map'],
      },
      'low': {
        'message': 'I\'m feeling low and unmotivated.',
        'tools': ['/tools/name-thought', '/tools/perspective-flip'],
      },
      'sleep': {
        'message': 'I can\'t sleep, my mind is racing.',
        'tools': ['/tools/wind-down', '/tools/brain-dump'],
      },
    };

    final suggestion = suggestions[state];
    if (suggestion != null) {
      // Show suggestion dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F2436),
          title: const Text(
            'Suggested Actions',
            style: TextStyle(color: Color(0xFFF2F5F7)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on how you\'re feeling, here are some options:',
                style: TextStyle(color: const Color(0xFFC7D1DD)),
              ),
              const SizedBox(height: 12),
              ...(suggestion['tools'] as List<String>).map((tool) => ListTile(
                dense: true,
                leading: const Icon(Icons.arrow_forward, color: Color(0xFF6366F1), size: 16),
                title: Text(
                  _getToolName(tool),
                  style: const TextStyle(color: Color(0xFFF2F5F7), fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(context);
                  R.go(context, tool);
                },
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                R.go(context, '/coach');
              },
              child: const Text('Talk to Coach'),
            ),
          ],
        ),
      );
    }
  }

  String _getToolName(String route) {
    return switch (route) {
      '/tools/calm-breath' => 'Calm Breath (1m)',
      '/tools/phys-sigh' => 'Physiological Sigh',
      '/tools/tiny-next-step' => 'Tiny Next Step',
      '/tools/energy-map' => 'Energy Map',
      '/tools/name-thought' => 'Name the Thought',
      '/tools/perspective-flip' => 'Perspective Flip',
      '/tools/wind-down' => 'Wind-Down',
      '/tools/brain-dump' => 'Brain Dump',
      _ => route,
    };
  }
}