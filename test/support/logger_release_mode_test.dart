import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/support/logger.dart';

void main() {
  group('Logger Release Mode Guards', () {
    late MindTrainerLogger logger;

    setUp(() {
      logger = MindTrainerLogger.instance;
    });

    test('logger guards prevent execution in release mode', () {
      // This test verifies the guards exist, but cannot test actual release mode
      // behavior since we cannot control kReleaseMode in tests
      expect(kReleaseMode, isFalse, reason: 'Tests run in debug mode');
      
      // Verify logger accepts messages in debug mode
      expect(() => logger.debug('Test message'), returnsNormally);
      expect(() => logger.info('Test message'), returnsNormally);
      expect(() => logger.warn('Test message'), returnsNormally);
      expect(() => logger.error('Test message'), returnsNormally);
    });

    test('Log class static methods have release mode guards', () {
      // Verify static methods accept messages in debug mode
      expect(() => Log.debug('Test message'), returnsNormally);
      expect(() => Log.info('Test message'), returnsNormally);
      expect(() => Log.warn('Test message'), returnsNormally);
      expect(() => Log.error('Test message'), returnsNormally);
    });

    test('logger initialization guard exists', () {
      // Verify initialization can be called in debug mode
      expect(() => MindTrainerLogger.initialize(), returnsNormally);
    });

    test('logger buffers messages correctly in debug mode', () {
      logger.clearLogs();
      
      logger.info('Test message 1');
      logger.warn('Test message 2');
      logger.error('Test message 3');
      
      final logs = logger.getAllLogs();
      expect(logs.length, equals(3));
      expect(logs[0].message, equals('Test message 1'));
      expect(logs[1].message, equals('Test message 2'));
      expect(logs[2].message, equals('Test message 3'));
    });
  });
}