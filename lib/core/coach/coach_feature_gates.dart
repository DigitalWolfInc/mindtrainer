/// Coaching Feature Gates for MindTrainer Pro
/// 
/// Controls access to ConversationalCoach phases based on subscription status.
/// Free users get basic emotional check-in; Pro users get full therapeutic flow.

import '../payments/pro_feature_gates.dart';
import 'conversational_coach.dart' as coach;

/// Result of checking coaching phase access
class CoachPhaseAccessResult {
  final bool allowed;
  final String? upgradeMessage;
  final coach.CoachPhase phase;
  
  const CoachPhaseAccessResult({
    required this.allowed,
    required this.phase,
    this.upgradeMessage,
  });
  
  /// Phase is accessible
  const CoachPhaseAccessResult.allowed(coach.CoachPhase phase)
    : this(allowed: true, phase: phase);
  
  /// Phase requires Pro upgrade
  const CoachPhaseAccessResult.requiresPro(coach.CoachPhase phase, String message)
    : this(allowed: false, phase: phase, upgradeMessage: message);
}

/// Coaching feature access controller
class CoachingFeatureGates {
  final MindTrainerProGates _gates;
  
  const CoachingFeatureGates(this._gates);
  
  /// Check if user can access a specific coaching phase
  CoachPhaseAccessResult checkPhaseAccess(coach.CoachPhase phase) {
    if (_isCoachPhaseAvailable(phase)) {
      return CoachPhaseAccessResult.allowed(phase);
    }
    
    return CoachPhaseAccessResult.requiresPro(
      phase,
      _getUpgradeMessageForPhase(phase),
    );
  }
  
  /// Get list of available coaching phases for current user
  List<coach.CoachPhase> getAvailablePhases() {
    if (_gates.extendedCoachingPhases) {
      // Pro users get all phases
      return coach.CoachPhase.values;
    } else {
      // Free users get basic phases only
      return [coach.CoachPhase.stabilize, coach.CoachPhase.open];
    }
  }
  
  /// Get list of locked coaching phases for current user  
  List<coach.CoachPhase> getLockedPhases() {
    if (_gates.extendedCoachingPhases) {
      return []; // Pro users have no locked phases
    } else {
      return [coach.CoachPhase.reflect, coach.CoachPhase.reframe, coach.CoachPhase.plan, coach.CoachPhase.close];
    }
  }
  
  /// Check if coaching session can continue to next phase
  bool canProgressToPhase(coach.CoachPhase nextPhase) {
    return checkPhaseAccess(nextPhase).allowed;
  }
  
  /// Get the maximum coaching phase available to current user
  coach.CoachPhase getMaxAvailablePhase() {
    if (_gates.extendedCoachingPhases) {
      return coach.CoachPhase.close; // Pro users can go to final phase
    } else {
      return coach.CoachPhase.open; // Free users stop after opening
    }
  }
  
  /// Get upgrade prompt when user hits coaching limits
  String getCoachingUpgradePrompt() {
    return 'Unlock the full coaching experience with Pro! '
           'Get personalized reflection, cognitive reframing, '
           'and action planning tailored to your focus journey.';
  }
  
  /// Get feature summary for coaching Pro benefits
  Map<String, String> getCoachingProFeatures() {
    return {
      'Deep Reflection': 'Mirror back insights about your emotional state and patterns',
      'Cognitive Reframing': 'Identify and reframe unhelpful thinking patterns', 
      'Personalized Planning': 'Action steps based on your focus session history',
      'Achievement Reinforcement': 'Celebrate progress using your streaks and goals',
    };
  }
  
  /// Check if user has reached free coaching limits in this session
  bool hasReachedFreeLimit(List<coach.CoachPhase> completedPhases) {
    if (_gates.extendedCoachingPhases) {
      return false; // Pro users never hit limits
    }
    
    // Free users can complete stabilize and open phases
    return completedPhases.contains(coach.CoachPhase.open);
  }
  
  /// Internal helper to check if phase is available
  bool _isCoachPhaseAvailable(coach.CoachPhase phase) {
    // Free users get basic phases
    if (phase == coach.CoachPhase.stabilize || phase == coach.CoachPhase.open) {
      return true;
    }
    // Pro users get advanced phases
    return _gates.extendedCoachingPhases;
  }
  
  /// Get phase-specific upgrade messages
  String _getUpgradeMessageForPhase(coach.CoachPhase phase) {
    switch (phase) {
      case coach.CoachPhase.stabilize:
      case coach.CoachPhase.open:
        return ''; // These are always free
        
      case coach.CoachPhase.reflect:
        return 'Upgrade to Pro to unlock deeper reflection and insight guidance.';
        
      case coach.CoachPhase.reframe:
        return 'Pro users get cognitive reframing to transform negative thought patterns.';
        
      case coach.CoachPhase.plan:
        return 'Get personalized action plans based on your focus history with Pro.';
        
      case coach.CoachPhase.close:
        return 'Pro coaching includes reinforcement using your personal achievements.';
    }
  }
}