import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/offline_validation/domain/connectivity_validator.dart';

void main() {
  group('ConnectivityValidator', () {
    test('should validate that core features work offline', () {
      final offlineFunctionality = ConnectivityValidator.validateOfflineFunctionality();
      
      // All core features should work offline
      expect(offlineFunctionality['focus_sessions'], isTrue);
      expect(offlineFunctionality['mood_checkins'], isTrue);
      expect(offlineFunctionality['session_history'], isTrue);
      expect(offlineFunctionality['checkin_history'], isTrue);
      expect(offlineFunctionality['settings'], isTrue);
      expect(offlineFunctionality['language_audit'], isTrue);
    });

    test('should list offline-required features', () {
      final requiredFeatures = ConnectivityValidator.offlineRequiredFeatures;
      
      expect(requiredFeatures, contains('focus_sessions'));
      expect(requiredFeatures, contains('mood_checkins'));
      expect(requiredFeatures, contains('emergency_support'));
      expect(requiredFeatures.length, greaterThanOrEqualTo(6));
    });

    test('should list optional network features', () {
      final optionalFeatures = ConnectivityValidator.optionalNetworkFeatures;
      
      expect(optionalFeatures, contains('feedback_sharing'));
      expect(optionalFeatures, contains('app_updates'));
      // These features should be limited and require explicit consent
      expect(optionalFeatures.length, lessThanOrEqualTo(3));
    });

    test('should validate no unexpected network requests', () {
      final noNetworkRequests = ConnectivityValidator.validateNoNetworkRequests();
      
      // Currently should always return true since all features are local
      expect(noNetworkRequests, isTrue);
    });
  });
}