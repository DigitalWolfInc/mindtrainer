class LanguageValidator {
  // Medical/clinical terms to avoid
  static const Set<String> _clinicalTerms = {
    'diagnosis', 'diagnose', 'diagnostic', 'disorder', 'disease', 'symptoms', 
    'treatment', 'therapy', 'medication', 'prescription', 'clinical', 'medical',
    'patient', 'condition', 'syndrome', 'pathology', 'cure', 'heal', 'fix',
    'broken', 'abnormal', 'normal', 'healthy', 'unhealthy', 'sick', 'illness'
  };

  // Blame-focused terms to avoid
  static const Set<String> _blameTerms = {
    'failed', 'failure', 'wrong', 'bad', 'mistake', 'error', 'fault', 
    'blame', 'should have', 'must', 'have to', 'need to'
  };

  // Achievement pressure terms to avoid
  static const Set<String> _pressureTerms = {
    'perfect', 'best', 'winner', 'loser', 'success', 'failure', 'achieve',
    'accomplish', 'master', 'expert', 'score', 'rating', 'grade'
  };

  /// Validates text for trauma-safe language
  /// Returns null if valid, or a suggestion if problematic
  static String? validateText(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Check for clinical terms
    for (final term in _clinicalTerms) {
      if (lowercaseText.contains(term)) {
        return 'Consider using supportive language instead of clinical terms like "$term"';
      }
    }

    // Check for blame-focused terms
    for (final term in _blameTerms) {
      if (lowercaseText.contains(term)) {
        return 'Consider using encouraging language instead of blame-focused terms like "$term"';
      }
    }

    // Check for pressure terms in completion contexts
    for (final term in _pressureTerms) {
      if (lowercaseText.contains(term)) {
        return 'Consider using gentle language instead of achievement-pressure terms like "$term"';
      }
    }

    return null; // Text is acceptable
  }

  /// Gets trauma-safe alternative suggestions
  static Map<String, String> get safePhrases => {
    // Session completion
    'Session completed successfully': 'Nice work on your session',
    'Perfect session!': 'Thanks for taking time for yourself',
    'You failed to complete': 'Ready to try again when you are',
    
    // Errors and problems
    'Error occurred': 'Something unexpected happened',
    'Failed to save': 'Let\'s try saving that again',
    'You must complete': 'When you\'re ready, you can complete',
    
    // Encouragement
    'Fix your problems': 'Support for your journey',
    'Cure your anxiety': 'Tools for feeling calmer',
    'Treat your symptoms': 'Gentle support for how you\'re feeling',
    
    // Emergency situations
    'Seek medical help': 'Talk to someone you trust or a professional',
    'This will cure you': 'This app offers gentle support alongside professional care',
    'Diagnose your condition': 'Understand how you\'re feeling right now'
  };

  /// Checks if text contains medical treatment claims
  static bool containsMedicalClaims(String text) {
    final lowercaseText = text.toLowerCase();
    final medicalClaims = [
      'treat', 'cure', 'heal', 'diagnose', 'medical', 'therapy', 'clinical'
    ];
    
    return medicalClaims.any((claim) => lowercaseText.contains(claim));
  }
}