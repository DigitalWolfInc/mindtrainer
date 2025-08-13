/// Integration Examples for MindTrainer Optimization System
/// 
/// Shows how to integrate optimization features into existing screens
/// and workflows with minimal code changes.

import 'package:flutter/material.dart';
import '../payments/pro_feature_gates.dart';
import 'optimization_manager.dart';
import 'optimization_widgets.dart';
import 'engagement_system.dart';
import 'upsell_strategy.dart';
import 'analytics_expansion.dart';

/// Example: Enhanced Home Screen with Optimization
class OptimizedHomeScreen extends StatefulWidget {
  final OptimizationManager optimizationManager;
  
  const OptimizedHomeScreen({
    super.key,
    required this.optimizationManager,
  });
  
  @override
  State<OptimizedHomeScreen> createState() => _OptimizedHomeScreenState();
}

class _OptimizedHomeScreenState extends State<OptimizedHomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.optimizationManager.analytics.trackEvent(
        GrowthEvent.onboardingStepCompleted,
        metadata: {'screen': 'home'},
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return OptimizedScreen(
      screenName: 'home',
      optimizationManager: widget.optimizationManager,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MindTrainer'),
        ),
        body: Column(
          children: [
            // Engagement cues at top
            EngagementCuesWidget(
              optimizationManager: widget.optimizationManager,
              maxCues: 1,
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildWelcomeSection(),
                    _buildQuickActions(),
                    _buildRecentActivity(),
                    _buildProFeatureTeaser(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: widget.optimizationManager.engagement.getEngagementPattern(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                final pattern = snapshot.data!;
                return Text(
                  'You\'re on a ${pattern.consecutiveDays}-day streak! 🔥',
                  style: Theme.of(context).textTheme.bodyLarge,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Focus Session',
              Icons.self_improvement,
              () => _startFocusSession(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Mood Check',
              Icons.sentiment_satisfied,
              () => _startMoodCheck(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: () async {
          // Measure button interaction
          await widget.optimizationManager.measure(
            'button_tap_$label',
            () async {
              onTap();
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Recent activity items would go here
            const Text('3 focus sessions this week'),
            const Text('2 mood check-ins completed'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProFeatureTeaser() {
    // Only show if user is in pro preview experiment
    if (!widget.optimizationManager.isFeatureEnabled('pro_feature_previews')) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showProFeaturePreview(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Pro Features',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text('Unlock advanced insights and unlimited sessions'),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _startFocusSession() async {
    // Check session limits with upsell opportunity
    final sessionCount = 3; // Get from actual session service
    
    if (sessionCount >= 5) { // Free tier limit
      final upsellMessage = await widget.optimizationManager.evaluateUpsellTrigger(
        UpsellTrigger.sessionLimitReached,
        {'session_count': sessionCount},
      );
      
      if (upsellMessage != null && mounted) {
        _showUpsellDialog(upsellMessage);
        return;
      }
    }
    
    // Track session start
    await widget.optimizationManager.onSessionStart();
    
    // Navigate to session
    // Navigator.push(context, MaterialRoute(builder: (_) => FocusSessionScreen()));
  }
  
  Future<void> _startMoodCheck() async {
    await widget.optimizationManager.analytics.trackEvent(
      GrowthEvent.proFeatureViewed,
      metadata: {'feature': 'mood_check'},
    );
    
    // Navigate to mood check
  }
  
  Future<void> _showProFeaturePreview() async {
    await widget.optimizationManager.onProFeatureInteraction(
      'pro_features_overview',
      'viewed',
    );
    
    // Show Pro features screen
  }
  
  void _showUpsellDialog(UpsellMessage message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: UpsellMessageWidget(
          message: message,
          opportunity: UpsellOpportunity(
            trigger: UpsellTrigger.sessionLimitReached,
            score: 0.8,
            context: {'session_count': 5},
            timestamp: DateTime.now(),
          ),
          optimizationManager: widget.optimizationManager,
          onUpgrade: () {
            Navigator.of(context).pop();
            // Navigate to Pro purchase
          },
          onDismiss: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

/// Example: Pro Feature with Optimization Integration
class OptimizedProFeatureScreen extends StatefulWidget {
  final String featureName;
  final OptimizationManager optimizationManager;
  final ProFeatureGates proGates;
  
  const OptimizedProFeatureScreen({
    super.key,
    required this.featureName,
    required this.optimizationManager,
    required this.proGates,
  });
  
  @override
  State<OptimizedProFeatureScreen> createState() => _OptimizedProFeatureScreenState();
}

class _OptimizedProFeatureScreenState extends State<OptimizedProFeatureScreen> {
  @override
  void initState() {
    super.initState();
    
    // Track Pro feature view
    widget.optimizationManager.onProFeatureInteraction(
      widget.featureName,
      'viewed',
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return OptimizedScreen(
      screenName: 'pro_feature_${widget.featureName}',
      optimizationManager: widget.optimizationManager,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.featureName),
        ),
        body: widget.proGates.isProActive
            ? _buildProContent()
            : _buildBlockedContent(),
      ),
    );
  }
  
  Widget _buildProContent() {
    return const Center(
      child: Text('Pro feature content goes here'),
    );
  }
  
  Widget _buildBlockedContent() {
    return FutureBuilder<UpsellMessage?>(
      future: widget.optimizationManager.evaluateUpsellTrigger(
        UpsellTrigger.proFeatureBlocked,
        {'blocked_feature': widget.featureName},
      ),
      builder: (context, snapshot) {
        final upsellMessage = snapshot.data;
        
        return Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('This feature requires Pro'),
                  ],
                ),
              ),
            ),
            
            if (upsellMessage != null)
              UpsellMessageWidget(
                message: upsellMessage,
                opportunity: UpsellOpportunity(
                  trigger: UpsellTrigger.proFeatureBlocked,
                  score: 0.75,
                  context: {'blocked_feature': widget.featureName},
                  timestamp: DateTime.now(),
                ),
                optimizationManager: widget.optimizationManager,
                onUpgrade: () {
                  // Navigate to Pro purchase
                },
                onDismiss: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }
}

/// Example: App Initialization with Optimization
class OptimizedApp extends StatefulWidget {
  const OptimizedApp({super.key});
  
  @override
  State<OptimizedApp> createState() => _OptimizedAppState();
}

class _OptimizedAppState extends State<OptimizedApp> {
  late final OptimizationManager _optimizationManager;
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize optimization system
    _optimizationManager = OptimizationManager(
      LocalStorage(), // Your local storage instance
    );
    
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Measure app startup
    _optimizationManager.measureAppStartup();
    
    try {
      // Initialize optimization systems
      await _optimizationManager.initialize();
      
      // Complete startup measurement
      await _optimizationManager.completeAppStartup();
      
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'MindTrainer',
      home: PerformanceDebugOverlay(
        optimizationManager: _optimizationManager,
        child: OptimizedHomeScreen(
          optimizationManager: _optimizationManager,
        ),
      ),
    );
  }
}

/// Utility class for easy integration
class OptimizationIntegration {
  static OptimizationManager? _instance;
  
  /// Get singleton instance
  static OptimizationManager get instance {
    if (_instance == null) {
      throw StateError('OptimizationManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize optimization system
  static Future<void> initialize(LocalStorage storage) async {
    _instance = OptimizationManager(storage);
    await _instance!.initialize();
  }
  
  /// Track screen navigation
  static Future<void> trackScreenNavigation(String screenName) async {
    await instance.analytics.trackEvent(
      GrowthEvent.onboardingStepCompleted,
      metadata: {'screen': screenName},
    );
  }
  
  /// Check feature flag
  static bool isFeatureEnabled(String featureId) {
    return instance.isFeatureEnabled(featureId);
  }
  
  /// Evaluate upsell opportunity
  static Future<UpsellMessage?> evaluateUpsell(
    UpsellTrigger trigger,
    Map<String, dynamic> context,
  ) async {
    return await instance.evaluateUpsellTrigger(trigger, context);
  }
}

// Import in local_storage.dart for the example to work
class LocalStorage {
  Future<String?> getString(String key) async {
    // Implementation
    return null;
  }
  
  Future<void> setString(String key, String value) async {
    // Implementation
  }
  
  static Map<String, dynamic>? parseJson(String json) {
    // Implementation
    return {};
  }
  
  static String encodeJson(Object obj) {
    // Implementation
    return '{}';
  }
}