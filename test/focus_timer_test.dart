import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/time_format.dart';

void main() {
  group('formatDuration', () {
    test('formats 25 minutes as 25:00', () {
      expect(formatDuration(const Duration(minutes: 25)), '25:00');
    });

    test('formats 0 seconds as 00:00', () {
      expect(formatDuration(const Duration(seconds: 0)), '00:00');
    });

    test('formats 65 seconds as 01:05', () {
      expect(formatDuration(const Duration(seconds: 65)), '01:05');
    });
  });
}