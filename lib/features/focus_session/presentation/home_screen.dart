import 'package:flutter/material.dart';
import 'focus_session_screen.dart';
import 'history_screen.dart';
import '../../mood_checkin/presentation/animal_checkin_screen.dart';
import '../../mood_checkin/presentation/checkin_history_screen.dart';
import '../../language_audit/presentation/language_audit_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../analytics/domain/analytics_service.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/billing/billing_adapter.dart';
import '../../../core/analytics/conversion_analytics.dart';
import '../../../core/engagement/engagement_cue_service.dart';
import '../../../core/engagement/widgets/engagement_cue_card.dart';
import '../../../core/feature_flags.dart';
import '../../../payments/pro_gate.dart';
import '../../../favorites/favorite_tools_store.dart';
import '../../../favorites/tool_tile.dart';
import '../../../favorites/tool_definitions.dart';
import '../../../services/tool_usage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EngagementCueService _engagementService = EngagementCueService();
  List<EngagementCue> _activeCues = [];
  List<String> _dismissedCues = [];

  @override
  void initState() {
    super.initState();
    _loadEngagementCues();
    _initializeFavorites();
  }

  void _initializeFavorites() async {
    await FavoriteToolsStore.instance.init();
    await ToolUsageService.instance.init();
  }

  void _loadEngagementCues() {
    // Temporarily disable engagement cues during testing
    setState(() {
      _activeCues = [];
    });
    
    // Create mock user activity context for demonstration (commented out for testing)
    // final context = _createMockUserContext();
    // final allCues = _engagementService.getEngagementCues(context);
    // 
    // setState(() {
    //   _activeCues = _engagementService.getActiveCues(allCues)
    //       .where((cue) => !_dismissedCues.contains(cue.id))
    //       .take(2) // Limit to 2 cues at once
    //       .toList();
    // });
  }

  UserActivityContext _createMockUserContext() {
    // Mock data for demonstration - in real app, this would come from user data
    return UserActivityContext(
      daysSinceLastSession: 1,
      currentStreak: 5,
      sessionsThisWeek: 3,
      weeklyGoal: 5,
      hasProAccess: false, // Will be updated with real billing status
      daysSinceProFeatureUse: 10,
      unusedProFeatures: ['mood_correlations', 'tag_insights'],
      recentSessionsCount: 4,
      averageRecentFocusScore: 7.2,
      personalBest: 8.9,
    );
  }

  void _handleCueTap(EngagementCue cue) {
    _engagementService.trackCueInteraction(cue, 'tapped');
    
    switch (cue.actionTarget) {
      case EngagementTarget.focusSession:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusSessionScreen()),
        );
        break;
      case EngagementTarget.analytics:
        _navigateToAnalytics();
        break;
      case EngagementTarget.settings:
        Navigator.pushNamed(context, '/settings');
        break;
      case EngagementTarget.history:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
        break;
    }
  }

  void _handleCueDismiss(EngagementCue cue) {
    _engagementService.trackCueInteraction(cue, 'dismissed');
    _engagementService.dismissCue(cue.id);
    
    setState(() {
      _dismissedCues.add(cue.id);
      _activeCues.removeWhere((c) => c.id == cue.id);
    });
  }

  void _navigateToAnalytics() async {
    // Use ProGate soft-gating: if user isn't Pro, show paywall first
    final wasGated = await context.maybePromptPaywall();
    if (wasGated) return; // User saw paywall, don't navigate to analytics
    
    // User is Pro or dismissed paywall, proceed to analytics
    final proGates = MindTrainerProGates.fromEntitlementResolver();
    final analyticsService = AdvancedAnalyticsService(proGates);
    final billingAdapter = BillingAdapterFactory.create();
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          analyticsService: analyticsService,
          proGates: proGates,
          billingAdapter: billingAdapter,
        ),
      ),
    );
  }

  // Navigation methods for tools
  void _navigateToTool(String toolId) {
    // Record tool usage
    ToolUsageService.instance.recordUsage(toolId);
    
    switch (toolId) {
      case ToolRegistry.focusSession:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusSessionScreen()),
        );
        break;
      case ToolRegistry.animalCheckin:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalCheckinScreen()),
        );
        break;
      case ToolRegistry.sessionHistory:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
        break;
      case ToolRegistry.checkinHistory:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckinHistoryScreen()),
        );
        break;
      case ToolRegistry.languageAudit:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LanguageAuditScreen()),
        );
        break;
      case ToolRegistry.analytics:
        _navigateToAnalytics();
        break;
      case ToolRegistry.settings:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  Widget _buildRecentToolsSection() {
    final recentUsage = ToolUsageService.instance.getRecent(5);
    
    // Get unique tools (most recent first)
    final seen = <String>{};
    final uniqueRecentTools = <String>[];
    
    for (final usage in recentUsage) {
      if (!seen.contains(usage.toolId)) {
        seen.add(usage.toolId);
        uniqueRecentTools.add(usage.toolId);
      }
    }
    
    if (uniqueRecentTools.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: uniqueRecentTools.length,
              itemBuilder: (context, index) {
                final toolId = uniqueRecentTools[index];
                return _buildRecentToolTile(toolId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentToolTile(String toolId) {
    final tool = ToolRegistry.getTool(toolId);
    if (tool == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToTool(toolId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tool.icon,
                size: 22,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 6),
              Text(
                tool.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (tool.estimated != null) ...[
                const SizedBox(height: 2),
                Text(
                  '• ${tool.estimated!.inMinutes}m',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If home cards feature is enabled, redirect to Today screen
    if (FeatureFlags.ff_home_cards_journal_coach) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/today');
      });
      return const SizedBox.shrink();
    }
    
    // Legacy home screen implementation
    return _buildLegacyHomeScreen(context);
  }
  
  Widget _buildLegacyHomeScreen(BuildContext context) {
    // Use new EntitlementResolver-based Pro gates
    final proGates = MindTrainerProGates.fromEntitlementResolver();
    final analyticsService = AdvancedAnalyticsService(proGates);
    final billingAdapter = BillingAdapterFactory.create();
    final conversionAnalytics = ConversionAnalytics();
    
    // Track home screen view
    conversionAnalytics.trackScreenNavigation('start_screen', 'home_screen', {
      'has_pro': proGates.isProActive,
      'billing_mode': BillingAdapterFactory.getConfigInfo(),
    });
    
    if (!proGates.isProActive) {
      // Track funnel entry for free users seeing Pro features
      conversionAnalytics.trackFunnelEntry(ConversionEntryPoints.homeScreenProBadge, {
        'screen': 'home',
        'user_type': 'free',
        'pro_features_visible': 1, // Analytics button with Pro badge
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('MindTrainer')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Engagement Cues Section
            if (_activeCues.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._activeCues.map((cue) => EngagementCueCard(
                cue: cue,
                onTap: () => _handleCueTap(cue),
                onDismiss: () => _handleCueDismiss(cue),
              )),
            ],
            
            // Favorites Section
            ListenableBuilder(
              listenable: FavoriteToolsStore.instance,
              builder: (context, _) {
                final store = FavoriteToolsStore.instance;
                final topFavorites = store.getTopFavorites(3);
                
                if (topFavorites.isEmpty) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Favorites',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: topFavorites.length,
                          itemBuilder: (context, index) {
                            final toolId = topFavorites[index];
                            return FavoriteToolTile(
                              toolId: toolId,
                              onTap: () => _navigateToTool(toolId),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Recent Tools Section
            _buildRecentToolsSection(),
            
            // Main Navigation Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
              ToolTile(
                toolId: ToolRegistry.focusSession,
                onTap: () => _navigateToTool(ToolRegistry.focusSession),
              ),
              const SizedBox(height: 16),
              ToolTile(
                toolId: ToolRegistry.animalCheckin,
                onTap: () => _navigateToTool(ToolRegistry.animalCheckin),
              ),
              const SizedBox(height: 16),
              ToolTile(
                toolId: ToolRegistry.sessionHistory,
                onTap: () => _navigateToTool(ToolRegistry.sessionHistory),
              ),
              const SizedBox(height: 16),
              ToolTile(
                toolId: ToolRegistry.checkinHistory,
                onTap: () => _navigateToTool(ToolRegistry.checkinHistory),
              ),
              const SizedBox(height: 16),
              ToolTile(
                toolId: ToolRegistry.languageAudit,
                onTap: () => _navigateToTool(ToolRegistry.languageAudit),
              ),
              const SizedBox(height: 16),
              ToolTile(
                toolId: ToolRegistry.analytics,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: proGates.isProActive ? Colors.amber[100] : null,
                  foregroundColor: proGates.isProActive ? Colors.black : null,
                ),
                onTap: () {
                  // Track analytics navigation
                  conversionAnalytics.trackUpgradePromptInteraction('home_screen', 'analytics_tapped', {
                    'has_pro_badge': !proGates.isProActive,
                    'button_style': proGates.isProActive ? 'pro_active' : 'pro_badge',
                  });
                  
                  if (!proGates.isProActive) {
                    // Track funnel progression for free users
                    conversionAnalytics.trackFunnelStep(ConversionFunnelSteps.proFeatureView, 
                        ConversionFunnelSteps.homeScreenView, {
                      'feature': 'analytics',
                      'entry_point': 'home_screen_button',
                    });
                  }
                  
                  // Use soft-gating via ProGate helper
                  _navigateToAnalytics();
                },
                trailing: !proGates.isProActive ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ) : null,
              ),
              const SizedBox(height: 16),
              ToolTile(
                toolId: ToolRegistry.settings,
                onTap: () => _navigateToTool(ToolRegistry.settings),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
