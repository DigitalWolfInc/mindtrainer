/// Seasonal Content Update System for MindTrainer
/// 
/// Manages quarterly UI/feature refreshes, seasonal themes, and content updates
/// to maintain user engagement and provide fresh experiences.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';
import '../analytics/engagement_analytics.dart';
import '../experiments/ab_testing_framework.dart';

/// Seasons for content theming
enum Season {
  spring, // March-May
  summer, // June-August
  autumn, // September-November
  winter, // December-February
}

/// Types of seasonal content
enum SeasonalContentType {
  theme,
  journalingPrompt,
  streakBadge,
  moodInsight,
  backgroundArt,
  audioEnvironment,
  achievement,
}

/// Seasonal content item
class SeasonalContent {
  final String id;
  final SeasonalContentType type;
  final Season season;
  final String title;
  final String description;
  final Map<String, dynamic> content;
  final DateTime validFrom;
  final DateTime validTo;
  final bool isActive;
  final int priority; // 1-100, higher = more important
  
  SeasonalContent({
    required this.id,
    required this.type,
    required this.season,
    required this.title,
    required this.description,
    required this.content,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
    this.priority = 50,
  });
  
  /// Whether this content is currently valid
  bool get isCurrentlyValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validTo);
  }
  
  /// Days remaining for this content
  int get daysRemaining {
    final now = DateTime.now();
    if (!isCurrentlyValid) return 0;
    return validTo.difference(now).inDays;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'season': season.name,
    'title': title,
    'description': description,
    'content': content,
    'validFrom': validFrom.toIso8601String(),
    'validTo': validTo.toIso8601String(),
    'isActive': isActive,
    'priority': priority,
  };
  
  factory SeasonalContent.fromJson(Map<String, dynamic> json) {
    return SeasonalContent(
      id: json['id'],
      type: SeasonalContentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SeasonalContentType.theme,
      ),
      season: Season.values.firstWhere(
        (s) => s.name == json['season'],
        orElse: () => Season.spring,
      ),
      title: json['title'],
      description: json['description'],
      content: Map<String, dynamic>.from(json['content'] ?? {}),
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 50,
    );
  }
}

/// Seasonal theme configuration
class SeasonalTheme {
  final String id;
  final Season season;
  final String name;
  final Map<String, String> colors; // color_name -> hex_value
  final Map<String, String> assets;  // asset_name -> asset_path
  final Map<String, dynamic> styles; // style configurations
  
  SeasonalTheme({
    required this.id,
    required this.season,
    required this.name,
    required this.colors,
    required this.assets,
    required this.styles,
  });
  
  /// Primary color for the theme
  String get primaryColor => colors['primary'] ?? '#6366F1';
  
  /// Secondary color for the theme
  String get secondaryColor => colors['secondary'] ?? '#8B5CF6';
  
  /// Background color for the theme
  String get backgroundColor => colors['background'] ?? '#FFFFFF';
}

/// Seasonal content update system
class SeasonalContentSystem {
  final LocalStorage _storage;
  final EngagementAnalytics _analytics;
  final ABTestingFramework _abTesting;
  
  static const String _contentKey = 'seasonal_content';
  static const String _activeThemeKey = 'active_seasonal_theme';
  static const String _contentHistoryKey = 'seasonal_content_history';
  static const String _userPreferencesKey = 'seasonal_preferences';
  
  final StreamController<List<SeasonalContent>> _contentUpdateController =
      StreamController<List<SeasonalContent>>.broadcast();
  
  List<SeasonalContent> _activeContent = [];
  SeasonalTheme? _activeTheme;
  
  SeasonalContentSystem(this._storage, this._analytics, this._abTesting);
  
  /// Stream of content updates
  Stream<List<SeasonalContent>> get contentUpdateStream => _contentUpdateController.stream;
  
  /// Currently active seasonal theme
  SeasonalTheme? get activeTheme => _activeTheme;
  
  /// Initialize the system
  Future<void> initialize() async {
    await _loadSeasonalContent();
    await _updateActiveContent();
    await _scheduleContentUpdates();
    
    if (kDebugMode) {
      print('Seasonal content system initialized');
      print('Active content items: ${_activeContent.length}');
      print('Current season: ${getCurrentSeason().name}');
    }
  }
  
  /// Get current season based on date
  Season getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;
    
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }
  
  /// Get all active seasonal content
  List<SeasonalContent> getActiveContent({SeasonalContentType? filterType}) {
    if (filterType == null) {
      return List.from(_activeContent);
    }
    
    return _activeContent.where((content) => content.type == filterType).toList();
  }
  
  /// Get seasonal content by type
  List<SeasonalContent> getContentByType(SeasonalContentType type) {
    return getActiveContent(filterType: type);
  }
  
  /// Get seasonal journaling prompts
  List<String> getSeasonalJournalingPrompts({int limit = 10}) {
    final prompts = getContentByType(SeasonalContentType.journalingPrompt);
    
    return prompts
        .map((content) => content.content['prompt'] as String? ?? content.title)
        .take(limit)
        .toList();
  }
  
  /// Get seasonal streak badges
  List<Map<String, dynamic>> getSeasonalStreakBadges() {
    final badges = getContentByType(SeasonalContentType.streakBadge);
    
    return badges.map((content) => {
      'id': content.id,
      'title': content.title,
      'description': content.description,
      'icon': content.content['icon'],
      'requirement': content.content['requirement'],
      'season': content.season.name,
    }).toList();
  }
  
  /// Get seasonal mood insights
  List<String> getSeasonalMoodInsights() {
    final insights = getContentByType(SeasonalContentType.moodInsight);
    
    return insights
        .map((content) => content.content['insight'] as String? ?? content.description)
        .toList();
  }
  
  /// Update seasonal content (called quarterly)
  Future<void> performQuarterlyUpdate() async {
    final currentSeason = getCurrentSeason();
    
    await _generateSeasonalContent(currentSeason);
    await _updateSeasonalTheme(currentSeason);
    await _runSeasonalABTests();
    
    await _updateActiveContent();
    await _trackSeasonalUpdate(currentSeason);
    
    if (kDebugMode) {
      print('Quarterly seasonal update completed for ${currentSeason.name}');
    }
  }
  
  /// Generate seasonal A/B test for engagement
  Future<void> createSeasonalABTest({
    required String testName,
    required Map<String, dynamic> variants,
    int durationDays = 30,
  }) async {
    final currentSeason = getCurrentSeason();
    
    final experiment = Experiment(
      id: 'seasonal_${currentSeason.name}_${testName.toLowerCase()}',
      name: 'Seasonal $testName - ${currentSeason.name.toUpperCase()}',
      description: 'Testing seasonal variations of $testName for ${currentSeason.name} season',
      status: ExperimentStatus.running,
      variants: variants.entries.map((entry) => ExperimentVariant(
        name: entry.key,
        trafficAllocation: 1.0 / variants.length,
        parameters: entry.value as Map<String, dynamic>,
      )).toList(),
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: durationDays)),
      targetingCriteria: ['seasonal_update_eligible'],
    );
    
    await _abTesting.addExperiment(experiment);
    
    // Track experiment creation
    await _analytics.trackEvent('seasonal_ab_test_created', {
      'season': currentSeason.name,
      'test_name': testName,
      'variants': variants.keys.toList(),
      'duration_days': durationDays,
    });
  }
  
  /// Track seasonal content engagement
  Future<void> trackSeasonalEngagement({
    required String contentId,
    required String action, // viewed, interacted, completed
    Map<String, dynamic>? additionalData,
  }) async {
    final content = _activeContent.firstWhere(
      (c) => c.id == contentId,
      orElse: () => SeasonalContent(
        id: contentId,
        type: SeasonalContentType.theme,
        season: getCurrentSeason(),
        title: 'Unknown',
        description: '',
        content: {},
        validFrom: DateTime.now(),
        validTo: DateTime.now().add(const Duration(days: 90)),
        isActive: false,
      ),
    );
    
    await _analytics.trackEvent('seasonal_content_engagement', {
      'content_id': contentId,
      'content_type': content.type.name,
      'season': content.season.name,
      'action': action,
      'days_remaining': content.daysRemaining,
      ...additionalData ?? {},
    });
  }
  
  /// Get seasonal engagement analytics
  Future<Map<String, dynamic>> getSeasonalAnalytics({
    Season? filterSeason,
    int days = 90,
  }) async {
    final season = filterSeason ?? getCurrentSeason();
    final since = DateTime.now().subtract(Duration(days: days));
    
    // This would integrate with the analytics system
    // For now, return mock data structure
    
    return {
      'season': season.name,
      'period_days': days,
      'total_interactions': 0,
      'content_performance': <String, dynamic>{},
      'user_engagement': {
        'daily_active_users': 0,
        'content_completion_rate': 0.0,
        'seasonal_retention_lift': 0.0,
      },
      'theme_adoption': {
        'users_with_seasonal_theme': 0,
        'theme_engagement_rate': 0.0,
      },
      'top_performing_content': <Map<String, dynamic>>[],
    };
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _contentUpdateController.close();
  }
  
  // Private helper methods
  
  Future<void> _loadSeasonalContent() async {
    final contentJson = await _storage.getString(_contentKey);
    if (contentJson != null) {
      try {
        final List<dynamic> contentList = jsonDecode(contentJson);
        _activeContent = contentList
            .map((json) => SeasonalContent.fromJson(json))
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading seasonal content: $e');
        }
        _activeContent = [];
      }
    }
  }
  
  Future<void> _updateActiveContent() async {
    final now = DateTime.now();
    
    // Filter to only currently valid content
    _activeContent = _activeContent
        .where((content) => content.isCurrentlyValid)
        .toList();
    
    // Sort by priority (highest first)
    _activeContent.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Notify listeners
    if (!_contentUpdateController.isClosed) {
      _contentUpdateController.add(_activeContent);
    }
  }
  
  Future<void> _generateSeasonalContent(Season season) async {
    final now = DateTime.now();
    final endOfSeason = _getSeasonEnd(season);
    
    // Generate journaling prompts
    final journalingPrompts = _generateJournalingPrompts(season);
    
    // Generate streak badges
    final streakBadges = _generateStreakBadges(season);
    
    // Generate mood insights
    final moodInsights = _generateMoodInsights(season);
    
    // Combine all content
    final newContent = [
      ...journalingPrompts,
      ...streakBadges,
      ...moodInsights,
    ];
    
    // Add to active content
    _activeContent.addAll(newContent);
    
    // Save to storage
    await _saveSeasonalContent();
  }
  
  List<SeasonalContent> _generateJournalingPrompts(Season season) {
    final Map<Season, List<String>> seasonalPrompts = {
      Season.spring: [
        'What new growth are you experiencing in your mindfulness journey?',
        'How does the renewal of spring inspire your personal development?',
        'What habits are you ready to plant and nurture this season?',
        'Reflect on a moment of fresh perspective you\'ve gained recently.',
      ],
      Season.summer: [
        'How do you stay mindful during busy, active summer days?',
        'What brings you the most joy and energy right now?',
        'Describe a perfect moment of summer relaxation.',
        'How has your practice evolved during these longer days?',
      ],
      Season.autumn: [
        'What are you ready to release as the season changes?',
        'How do you find gratitude in times of transition?',
        'What wisdom have you gathered from this year\'s experiences?',
        'Reflect on the balance between holding on and letting go.',
      ],
      Season.winter: [
        'How do you cultivate inner warmth during quieter times?',
        'What insights emerge when you slow down and turn inward?',
        'How does stillness serve your mindfulness practice?',
        'What intentions are you setting for the year ahead?',
      ],
    };
    
    final prompts = seasonalPrompts[season] ?? [];
    final now = DateTime.now();
    final endOfSeason = _getSeasonEnd(season);
    
    return prompts.asMap().entries.map((entry) {
      final index = entry.key;
      final prompt = entry.value;
      
      return SeasonalContent(
        id: 'prompt_${season.name}_${index + 1}',
        type: SeasonalContentType.journalingPrompt,
        season: season,
        title: 'Seasonal Reflection',
        description: 'A mindful journaling prompt for ${season.name}',
        content: {'prompt': prompt},
        validFrom: now,
        validTo: endOfSeason,
        isActive: true,
        priority: 70,
      );
    }).toList();
  }
  
  List<SeasonalContent> _generateStreakBadges(Season season) {
    final Map<Season, Map<String, dynamic>> seasonalBadges = {
      Season.spring: {
        'title': 'Spring Growth',
        'icon': '🌱',
        'requirement': 14, // 14-day streak
        'description': 'Maintained mindfulness through spring\'s renewal',
      },
      Season.summer: {
        'title': 'Summer Sun',
        'icon': '☀️',
        'requirement': 21, // 21-day streak
        'description': 'Stayed consistent during summer\'s energy',
      },
      Season.autumn: {
        'title': 'Autumn Wisdom',
        'icon': '🍂',
        'requirement': 30, // 30-day streak
        'description': 'Found balance through autumn\'s changes',
      },
      Season.winter: {
        'title': 'Winter Stillness',
        'icon': '❄️',
        'requirement': 45, // 45-day streak
        'description': 'Cultivated inner peace through winter\'s quiet',
      },
    };
    
    final badgeData = seasonalBadges[season] ?? seasonalBadges[Season.spring]!;
    final now = DateTime.now();
    final endOfSeason = _getSeasonEnd(season);
    
    return [
      SeasonalContent(
        id: 'badge_${season.name}_streak',
        type: SeasonalContentType.streakBadge,
        season: season,
        title: badgeData['title'],
        description: badgeData['description'],
        content: {
          'icon': badgeData['icon'],
          'requirement': badgeData['requirement'],
          'type': 'streak',
        },
        validFrom: now,
        validTo: endOfSeason,
        isActive: true,
        priority: 60,
      ),
    ];
  }
  
  List<SeasonalContent> _generateMoodInsights(Season season) {
    final Map<Season, List<String>> seasonalInsights = {
      Season.spring: [
        'Spring energy can sometimes feel overwhelming. Remember to pace yourself.',
        'New beginnings often bring excitement and anxiety. Both feelings are natural.',
        'Growth requires patience. Trust your process.',
      ],
      Season.summer: [
        'High energy seasons can mask the need for rest. Listen to your body.',
        'Social activities increase in summer. Balance connection with solitude.',
        'Longer days offer more opportunities for mindful moments.',
      ],
      Season.autumn: [
        'Change is natural and necessary for growth.',
        'Letting go doesn\'t mean losing - it means making space.',
        'Gratitude transforms ordinary moments into blessings.',
      ],
      Season.winter: [
        'Quiet times offer deep opportunities for self-reflection.',
        'Inner warmth comes from self-compassion and acceptance.',
        'Stillness is not emptiness - it\'s fullness waiting to be discovered.',
      ],
    };
    
    final insights = seasonalInsights[season] ?? [];
    final now = DateTime.now();
    final endOfSeason = _getSeasonEnd(season);
    
    return insights.asMap().entries.map((entry) {
      final index = entry.key;
      final insight = entry.value;
      
      return SeasonalContent(
        id: 'insight_${season.name}_${index + 1}',
        type: SeasonalContentType.moodInsight,
        season: season,
        title: '${season.name.toUpperCase()} Insight',
        description: 'Seasonal wisdom for mindful living',
        content: {'insight': insight},
        validFrom: now,
        validTo: endOfSeason,
        isActive: true,
        priority: 50,
      );
    }).toList();
  }
  
  Future<void> _updateSeasonalTheme(Season season) async {
    final themes = _getSeasonalThemes();
    _activeTheme = themes[season];
    
    if (_activeTheme != null) {
      await _storage.setString(_activeThemeKey, jsonEncode({
        'id': _activeTheme!.id,
        'season': _activeTheme!.season.name,
        'name': _activeTheme!.name,
        'colors': _activeTheme!.colors,
        'assets': _activeTheme!.assets,
        'styles': _activeTheme!.styles,
      }));
    }
  }
  
  Future<void> _runSeasonalABTests() async {
    final season = getCurrentSeason();
    
    // Create seasonal theme variation test
    await createSeasonalABTest(
      testName: 'theme_intensity',
      variants: {
        'subtle': {'theme_intensity': 'subtle'},
        'vibrant': {'theme_intensity': 'vibrant'},
      },
    );
    
    // Create seasonal content frequency test
    await createSeasonalABTest(
      testName: 'content_frequency',
      variants: {
        'daily': {'prompt_frequency': 'daily'},
        'weekly': {'prompt_frequency': 'weekly'},
      },
    );
  }
  
  Map<Season, SeasonalTheme> _getSeasonalThemes() {
    return {
      Season.spring: SeasonalTheme(
        id: 'spring_2024',
        season: Season.spring,
        name: 'Fresh Growth',
        colors: {
          'primary': '#22C55E',     // Green
          'secondary': '#84CC16',   // Lime
          'background': '#F0FDF4',  // Light green
          'accent': '#059669',      // Emerald
        },
        assets: {
          'background': 'assets/themes/spring_bg.png',
          'pattern': 'assets/themes/spring_pattern.png',
        },
        styles: {
          'borderRadius': 12.0,
          'shadowIntensity': 0.1,
        },
      ),
      Season.summer: SeasonalTheme(
        id: 'summer_2024',
        season: Season.summer,
        name: 'Bright Energy',
        colors: {
          'primary': '#F59E0B',     // Amber
          'secondary': '#EF4444',   // Red
          'background': '#FFFBEB',  // Light amber
          'accent': '#DC2626',      // Red
        },
        assets: {
          'background': 'assets/themes/summer_bg.png',
          'pattern': 'assets/themes/summer_pattern.png',
        },
        styles: {
          'borderRadius': 16.0,
          'shadowIntensity': 0.2,
        },
      ),
      Season.autumn: SeasonalTheme(
        id: 'autumn_2024',
        season: Season.autumn,
        name: 'Warm Transition',
        colors: {
          'primary': '#EA580C',     // Orange
          'secondary': '#DC2626',   // Red
          'background': '#FFF7ED',  // Light orange
          'accent': '#B91C1C',      // Dark red
        },
        assets: {
          'background': 'assets/themes/autumn_bg.png',
          'pattern': 'assets/themes/autumn_pattern.png',
        },
        styles: {
          'borderRadius': 10.0,
          'shadowIntensity': 0.15,
        },
      ),
      Season.winter: SeasonalTheme(
        id: 'winter_2024',
        season: Season.winter,
        name: 'Calm Stillness',
        colors: {
          'primary': '#3B82F6',     // Blue
          'secondary': '#6366F1',   // Indigo
          'background': '#F8FAFC',  // Light blue
          'accent': '#1E40AF',      // Dark blue
        },
        assets: {
          'background': 'assets/themes/winter_bg.png',
          'pattern': 'assets/themes/winter_pattern.png',
        },
        styles: {
          'borderRadius': 8.0,
          'shadowIntensity': 0.05,
        },
      ),
    };
  }
  
  DateTime _getSeasonEnd(Season season) {
    final now = DateTime.now();
    final year = now.year;
    
    switch (season) {
      case Season.spring:
        return DateTime(year, 5, 31, 23, 59, 59); // End of May
      case Season.summer:
        return DateTime(year, 8, 31, 23, 59, 59); // End of August
      case Season.autumn:
        return DateTime(year, 11, 30, 23, 59, 59); // End of November
      case Season.winter:
        // Winter spans year boundary
        if (now.month <= 2) {
          return DateTime(year, 2, 28, 23, 59, 59); // End of February
        } else {
          return DateTime(year + 1, 2, 28, 23, 59, 59); // Next February
        }
    }
  }
  
  Future<void> _scheduleContentUpdates() async {
    // Schedule periodic content updates
    Timer.periodic(const Duration(hours: 24), (timer) async {
      await _updateActiveContent();
      
      // Check if it's time for quarterly update
      if (_isTimeForQuarterlyUpdate()) {
        await performQuarterlyUpdate();
      }
    });
  }
  
  bool _isTimeForQuarterlyUpdate() {
    // Check if we're at the start of a new season
    // This is a simplified check - in production, you'd want more sophisticated logic
    final now = DateTime.now();
    return now.day == 1 && [3, 6, 9, 12].contains(now.month);
  }
  
  Future<void> _trackSeasonalUpdate(Season season) async {
    await _analytics.trackEvent('seasonal_update_completed', {
      'season': season.name,
      'content_items_activated': _activeContent.length,
      'theme_updated': _activeTheme != null,
      'update_timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> _saveSeasonalContent() async {
    final contentJson = jsonEncode(
      _activeContent.map((content) => content.toJson()).toList()
    );
    await _storage.setString(_contentKey, contentJson);
  }
}