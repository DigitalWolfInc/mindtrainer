/// Pro Status UI Components for Focus Sessions
/// 
/// Provides reusable widgets for displaying Pro status, session limits,
/// and upgrade prompts throughout the focus session experience.

import 'package:flutter/material.dart';
import '../domain/session_limit_service.dart';

/// Widget displaying current session usage and Pro status
class SessionLimitStatusCard extends StatelessWidget {
  final SessionUsageSummary usage;
  final VoidCallback? onUpgradeTap;
  
  const SessionLimitStatusCard({
    super.key,
    required this.usage,
    this.onUpgradeTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  usage.isUnlimited ? Icons.all_inclusive : Icons.today,
                  color: usage.isUnlimited ? Colors.amber : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  usage.tier,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: usage.isUnlimited ? Colors.amber[700] : Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!usage.isUnlimited) ...[
                  const Spacer(),
                  _buildLimitProgress(context),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              usage.dailyUsageText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              usage.weeklyAverageText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (usage.upgradeAvailable && onUpgradeTap != null) ...[
              const SizedBox(height: 12),
              _buildUpgradeButton(context),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLimitProgress(BuildContext context) {
    final progress = usage.dailyProgress ?? 0.0;
    final color = progress >= 0.8 ? Colors.orange : Colors.blue;
    
    return SizedBox(
      width: 60,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: color.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
  
  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onUpgradeTap,
        icon: const Icon(Icons.star, size: 18),
        label: const Text('Upgrade to Pro'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }
}

/// Banner shown when user approaches or hits session limits
class SessionLimitBanner extends StatelessWidget {
  final SessionStartResult result;
  final VoidCallback? onUpgradeTap;
  final VoidCallback? onDismiss;
  
  const SessionLimitBanner({
    super.key,
    required this.result,
    this.onUpgradeTap,
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    if (result.canStart && !result.requiresUpgrade) {
      return const SizedBox.shrink(); // No banner needed
    }
    
    final isBlocked = !result.canStart;
    final color = isBlocked ? Colors.orange : Colors.blue;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isBlocked ? Icons.block : Icons.warning_amber,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          if (result.requiresUpgrade && onUpgradeTap != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUpgradeTap,
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Upgrade to Pro'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[700],
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Preview/teaser widget showing Pro unlimited sessions feature
class UnlimitedSessionsPreview extends StatelessWidget {
  final VoidCallback? onLearnMore;
  
  const UnlimitedSessionsPreview({
    super.key,
    this.onLearnMore,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.orange.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.all_inclusive,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Unlimited Sessions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Never hit daily limits again. Focus as much as you need with Pro unlimited sessions.',
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text('No daily session limits', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.check, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text('Perfect for intensive focus days', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.check, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text('No interruption warnings', style: TextStyle(fontSize: 13)),
                ],
              ),
              if (onLearnMore != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onLearnMore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[700],
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                    child: const Text('Learn More About Pro'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple status text widget for displaying session count/limit
class SessionStatusText extends StatelessWidget {
  final SessionStartResult result;
  
  const SessionStatusText({
    super.key,
    required this.result,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = result.canStart ? Colors.grey[600] : Colors.orange[700];
    
    return Text(
      result.statusMessage,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: result.canStart ? FontWeight.normal : FontWeight.w500,
      ),
    );
  }
}

/// Pro upgrade dialog with session-specific benefits
class SessionLimitUpgradeDialog extends StatelessWidget {
  final SessionStartResult result;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;
  
  const SessionLimitUpgradeDialog({
    super.key,
    required this.result,
    this.onUpgrade,
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          SizedBox(width: 8),
          Text('Upgrade to Pro'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'ve completed ${result.currentDailyCount} sessions today. '
            'Unlock unlimited focus sessions with Pro:',
          ),
          const SizedBox(height: 16),
          ..._buildBenefitsList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Maybe Later'),
        ),
        ElevatedButton.icon(
          onPressed: onUpgrade,
          icon: const Icon(Icons.star, size: 16),
          label: const Text('Upgrade to Pro'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildBenefitsList() {
    final benefits = [
      'Unlimited daily focus sessions',
      'Extended AI coaching flows',
      'Advanced insights and analytics',
      'Data export and backup',
      'Ad-free experience',
    ];
    
    return benefits.map((benefit) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 13))),
        ],
      ),
    )).toList();
  }
}