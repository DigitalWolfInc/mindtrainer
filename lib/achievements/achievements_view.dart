import 'package:flutter/material.dart' hide Badge;

import 'achievements_resolver.dart';
import 'badge.dart';
import 'badge_ids.dart';
import 'snapshot.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({super.key});

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView> {
  late AchievementsResolver _resolver;

  @override
  void initState() {
    super.initState();
    _resolver = AchievementsResolver.instance;
    _resolver.addListener(_onAchievementsChanged);
    _initializeResolver();
  }

  @override
  void dispose() {
    _resolver.removeListener(_onAchievementsChanged);
    super.dispose();
  }

  void _onAchievementsChanged() {
    setState(() {});
  }

  Future<void> _initializeResolver() async {
    await _resolver.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _resolver.snapshot;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(snapshot),
            const SizedBox(height: 24),
            _buildBadgeGrid(snapshot),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AchievementsSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Badges',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${snapshot.count} of ${BadgeIds.all.length} badges earned',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid(AchievementsSnapshot snapshot) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: BadgeIds.all.length,
      itemBuilder: (context, index) {
        final badgeId = BadgeIds.all[index];
        final isUnlocked = snapshot.has(badgeId);
        final badge = isUnlocked ? snapshot.unlocked[badgeId] : null;
        
        return _buildBadgeCard(badgeId, badge, isUnlocked);
      },
    );
  }

  Widget _buildBadgeCard(String badgeId, Badge? badge, bool isUnlocked) {
    final info = _getBadgeInfo(badgeId);
    
    return Card(
      elevation: isUnlocked ? 3 : 1,
      child: InkWell(
        onTap: isUnlocked ? () => _showBadgeDetails(badge!) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadgeIcon(badgeId, isUnlocked),
              const SizedBox(height: 12),
              Text(
                info.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black87 : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                info.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked && badge != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Earned ${_formatDate(badge.unlockedAt)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(String badgeId, bool isUnlocked) {
    IconData iconData;
    Color iconColor;

    // Map badge IDs to appropriate icons
    switch (badgeId) {
      case BadgeIds.firstSession:
      case BadgeIds.fiveSessions:
      case BadgeIds.twentySessions:
      case BadgeIds.hundredSessions:
        iconData = Icons.play_circle_filled;
        break;
      case BadgeIds.firstHourTotal:
      case BadgeIds.tenHoursTotal:
      case BadgeIds.hundredHoursTotal:
        iconData = Icons.access_time;
        break;
      case BadgeIds.firstStreak3:
      case BadgeIds.streak7:
      case BadgeIds.streak30:
        iconData = Icons.local_fire_department;
        break;
      case BadgeIds.longSession25m:
      case BadgeIds.longSession60m:
      case BadgeIds.longSession120m:
        iconData = Icons.timer;
        break;
      case BadgeIds.tagMastery10:
        iconData = Icons.tag;
        break;
      case BadgeIds.reflection10:
        iconData = Icons.psychology;
        break;
      case BadgeIds.weekGoal3:
        iconData = Icons.flag;
        break;
      default:
        iconData = Icons.emoji_events;
    }

    if (isUnlocked) {
      // Use different colors for different badge types
      if (badgeId.contains('streak')) {
        iconColor = Colors.orange[700]!;
      } else if (badgeId.contains('long_session')) {
        iconColor = Colors.blue[700]!;
      } else if (badgeId.contains('total')) {
        iconColor = Colors.purple[700]!;
      } else {
        iconColor = Colors.green[700]!;
      }
    } else {
      iconColor = Colors.grey[400]!;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isUnlocked ? iconColor.withOpacity(0.1) : Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 32,
        color: iconColor,
      ),
    );
  }

  void _showBadgeDetails(Badge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 16),
            Text(
              'Earned on ${_formatFullDate(badge.unlockedAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (badge.meta != null && badge.meta!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._buildMetaDetails(badge.meta!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetaDetails(Map<String, dynamic> meta) {
    final details = <Widget>[];
    
    for (final entry in meta.entries) {
      String displayValue;
      if (entry.value is double) {
        displayValue = (entry.value as double).toStringAsFixed(1);
      } else {
        displayValue = entry.value.toString();
      }
      
      details.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '${_formatMetaKey(entry.key)}: $displayValue',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    
    return details;
  }

  String _formatMetaKey(String key) {
    switch (key) {
      case 'sessionCount':
        return 'Sessions completed';
      case 'totalHours':
        return 'Total hours';
      case 'maxStreak':
        return 'Max streak';
      case 'longestSession':
        return 'Longest session (minutes)';
      case 'maxTagUsage':
        return 'Times tag used';
      case 'reflectionCount':
        return 'Reflections completed';
      case 'weeklyGoalCount':
        return 'Weekly goals met';
      default:
        return key;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  ({String title, String description}) _getBadgeInfo(String id) {
    switch (id) {
      case BadgeIds.firstSession:
        return (title: "First Step", description: "Completed your first focus session.");
      case BadgeIds.fiveSessions:
        return (title: "Getting Started", description: "Completed 5 focus sessions.");
      case BadgeIds.twentySessions:
        return (title: "Building Momentum", description: "Completed 20 focus sessions.");
      case BadgeIds.hundredSessions:
        return (title: "Centenarian", description: "Completed 100 focus sessions.");
      case BadgeIds.firstHourTotal:
        return (title: "First Hour", description: "Accumulated 1 hour of total focus time.");
      case BadgeIds.tenHoursTotal:
        return (title: "Deep Practitioner", description: "Accumulated 10 hours of total focus time.");
      case BadgeIds.hundredHoursTotal:
        return (title: "Master Focuser", description: "Accumulated 100 hours of total focus time.");
      case BadgeIds.firstStreak3:
        return (title: "Three in a Row", description: "Maintained a 3-day focus streak.");
      case BadgeIds.streak7:
        return (title: "Week Warrior", description: "Maintained a 7-day focus streak.");
      case BadgeIds.streak30:
        return (title: "Monthly Master", description: "Maintained a 30-day focus streak.");
      case BadgeIds.longSession25m:
        return (title: "Extended Focus", description: "Completed a 25-minute focus session.");
      case BadgeIds.longSession60m:
        return (title: "Deep Dive", description: "Completed a 60-minute focus session.");
      case BadgeIds.longSession120m:
        return (title: "Ultra Focus", description: "Completed a 2-hour focus session.");
      case BadgeIds.tagMastery10:
        return (title: "Tag Master", description: "Used the same tag on 10 different sessions.");
      case BadgeIds.reflection10:
        return (title: "Reflective Mind", description: "Completed 10 coach reflection sessions.");
      case BadgeIds.weekGoal3:
        return (title: "Goal Achiever", description: "Met your weekly goal 3 separate weeks.");
      default:
        return (title: "Unknown Badge", description: "Description not available.");
    }
  }
}