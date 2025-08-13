import 'package:flutter/material.dart';

/// Tool definition for the favorites system
class ToolDefinition {
  final String id;
  final String title;
  final IconData icon;
  final Duration? estimated;

  const ToolDefinition({
    required this.id,
    required this.title,
    required this.icon,
    this.estimated,
  });
}

/// Registry of all available tools in the app
class ToolRegistry {
  static const String focusSession = 'focus_session';
  static const String animalCheckin = 'animal_checkin';
  static const String sessionHistory = 'session_history';
  static const String checkinHistory = 'checkin_history';
  static const String languageAudit = 'language_audit';
  static const String analytics = 'analytics';
  static const String settings = 'settings';
  
  // Time badge tools
  static const String calmBreath = 'calm_breath';
  static const String tinyNextStep = 'tiny_next_step';
  static const String brainDump = 'brain_dump';
  static const String perspectiveFlip = 'perspective_flip';
  static const String windDown = 'wind_down';

  /// Map of all tools with their definitions
  static const Map<String, ToolDefinition> tools = {
    focusSession: ToolDefinition(
      id: focusSession,
      title: 'Start Focus Session',
      icon: Icons.psychology,
      estimated: Duration(minutes: 10),
    ),
    animalCheckin: ToolDefinition(
      id: animalCheckin,
      title: 'Animal Check-in',
      icon: Icons.pets,
      estimated: Duration(minutes: 2),
    ),
    sessionHistory: ToolDefinition(
      id: sessionHistory,
      title: 'View Session History',
      icon: Icons.history,
    ),
    checkinHistory: ToolDefinition(
      id: checkinHistory,
      title: 'View Check-in History',
      icon: Icons.list,
    ),
    languageAudit: ToolDefinition(
      id: languageAudit,
      title: 'Language Safety Check',
      icon: Icons.security,
      estimated: Duration(minutes: 3),
    ),
    analytics: ToolDefinition(
      id: analytics,
      title: 'Analytics',
      icon: Icons.analytics,
    ),
    settings: ToolDefinition(
      id: settings,
      title: 'Settings',
      icon: Icons.settings,
    ),
    
    // Time badge tools
    calmBreath: ToolDefinition(
      id: calmBreath,
      title: 'Calm Breath',
      icon: Icons.air,
      estimated: Duration(minutes: 1),
    ),
    tinyNextStep: ToolDefinition(
      id: tinyNextStep,
      title: 'Tiny Next Step',
      icon: Icons.arrow_forward,
      estimated: Duration(minutes: 1),
    ),
    brainDump: ToolDefinition(
      id: brainDump,
      title: 'Brain Dump',
      icon: Icons.psychology_outlined,
      estimated: Duration(minutes: 5),
    ),
    perspectiveFlip: ToolDefinition(
      id: perspectiveFlip,
      title: 'Perspective Flip',
      icon: Icons.flip,
      estimated: Duration(minutes: 3),
    ),
    windDown: ToolDefinition(
      id: windDown,
      title: 'Wind Down',
      icon: Icons.bedtime,
      estimated: Duration(minutes: 10),
    ),
  };

  /// Get tool definition by ID
  static ToolDefinition? getTool(String id) {
    return tools[id];
  }

  /// Get all tool IDs
  static List<String> getAllToolIds() {
    return tools.keys.toList();
  }
}