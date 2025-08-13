import 'package:flutter/material.dart';
import '../../../core/feature_flags.dart';
import '../../../i18n/strings.g.dart';
import '../../focus_timer/services/focus_timer_prefs.dart';

/// Top cards for Journal, Coach, and Focus Session
class HomeCards extends StatelessWidget {
  final VoidCallback? onJournalTap;
  final VoidCallback? onCoachTap;
  final VoidCallback? onFocusTap;
  
  const HomeCards({
    super.key,
    this.onJournalTap,
    this.onCoachTap,
    this.onFocusTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.homeCardsEnabled) {
      return const SizedBox.shrink();
    }
    
    final strings = context.strings;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary cards row
          Row(
            children: [
              Expanded(
                child: _HomeCard(
                  title: strings.homeJournalTitle,
                  subtitle: strings.homeJournalSub,
                  icon: Icons.edit_outlined,
                  onTap: onJournalTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeCard(
                  title: strings.homeCoachTitle,
                  subtitle: strings.homeCoachSub,
                  icon: Icons.psychology_outlined,
                  onTap: onCoachTap,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Focus session chip row
          if (FeatureFlags.focusTimerChipsEnabled)
            _FocusChips(onFocusTap: onFocusTap),
        ],
      ),
    );
  }
}

/// Individual home card
class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  
  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus session duration chips
class _FocusChips extends StatefulWidget {
  final VoidCallback? onFocusTap;
  
  const _FocusChips({this.onFocusTap});
  
  @override
  State<_FocusChips> createState() => _FocusChipsState();
}

class _FocusChipsState extends State<_FocusChips> {
  Duration? _lastUsedDuration;
  
  @override
  void initState() {
    super.initState();
    _loadLastDuration();
  }
  
  Future<void> _loadLastDuration() async {
    final duration = await FocusTimerPrefs.instance.getLastDuration();
    if (mounted) {
      setState(() {
        _lastUsedDuration = duration;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final standardDurations = FocusTimerPrefs.standardDurations;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.homeFocusTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.homeFocusSub,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Standard duration chips
            ...standardDurations.map((duration) => _DurationChip(
              duration: duration,
              onTap: () => _startFocusSession(duration),
            )),
            
            // Last used chip (if different from standard)
            if (_lastUsedDuration != null && 
                !standardDurations.contains(_lastUsedDuration))
              _DurationChip(
                duration: _lastUsedDuration!,
                label: strings.focusChipLastUsed,
                onTap: () => _startFocusSession(_lastUsedDuration!),
                isLastUsed: true,
              ),
          ],
        ),
      ],
    );
  }
  
  void _startFocusSession(Duration duration) async {
    // Save as last used
    await FocusTimerPrefs.instance.setLastDuration(duration);
    
    // Update local state
    setState(() {
      _lastUsedDuration = duration;
    });
    
    // Navigate to focus session
    widget.onFocusTap?.call();
  }
}

/// Individual duration chip
class _DurationChip extends StatelessWidget {
  final Duration duration;
  final String? label;
  final VoidCallback onTap;
  final bool isLastUsed;
  
  const _DurationChip({
    required this.duration,
    required this.onTap,
    this.label,
    this.isLastUsed = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? '${duration.inMinutes}m';
    
    return ActionChip(
      label: Text(displayLabel),
      onPressed: onTap,
      backgroundColor: isLastUsed 
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      side: isLastUsed 
          ? BorderSide(color: Theme.of(context).primaryColor)
          : null,
    );
  }
}