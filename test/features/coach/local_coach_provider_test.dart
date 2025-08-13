import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/coach/providers/local_coach_provider.dart';
import '../../../lib/features/coach/models/coach_models.dart';

void main() {
  group('LocalCoachProvider AOY6 Rules', () {
    late LocalCoachProvider provider;
    
    setUp(() {
      provider = LocalCoachProvider();
    });
    
    test('should suggest calm breath for anxious patterns', () async {
      final replies = await Future.wait([
        provider.reply('I feel so anxious right now'),
        provider.reply('My mind is racing and I feel panicky'),
        provider.reply('I\'m feeling really wired and overwhelmed'),
      ]);
      
      for (final reply in replies) {
        expect(reply.suggestedToolId, equals('calm-breath'));
        expect(reply.text, isNotEmpty);
      }
    });
    
    test('should suggest perspective flip for stuck patterns', () async {
      final replies = await Future.wait([
        provider.reply('I feel really stuck on this problem'),
        provider.reply('My thoughts are just spinning in circles'),
        provider.reply('I keep ruminating about the same thing'),
      ]);
      
      for (final reply in replies) {
        expect(reply.suggestedToolId, equals('perspective-flip'));
        expect(reply.text, isNotEmpty);
      }
    });
    
    test('should suggest tiny next step for low energy', () async {
      final replies = await Future.wait([
        provider.reply('I feel so low and drained today'),
        provider.reply('I\'m exhausted and don\'t know where to start'),
        provider.reply('Feeling really empty right now'),
      ]);
      
      for (final reply in replies) {
        expect(reply.suggestedToolId, equals('tiny-next-step'));
        expect(reply.text, isNotEmpty);
      }
    });
    
    test('should handle triage tags directly', () async {
      final replies = await Future.wait([
        provider.reply('', triageTag: 'wired'),
        provider.reply('', triageTag: 'stuck'),
        provider.reply('', triageTag: 'low'),
        provider.reply('', triageTag: 'cant_sleep'),
      ]);
      
      expect(replies[0].suggestedToolId, equals('calm-breath'));
      expect(replies[1].suggestedToolId, equals('perspective-flip'));
      expect(replies[2].suggestedToolId, equals('tiny-next-step'));
      expect(replies[3].suggestedToolId, equals('wind-down-timer'));
      
      for (final reply in replies) {
        expect(reply.text, isNotEmpty);
      }
    });
    
    test('should provide fallback response for unknown patterns', () async {
      final reply = await provider.reply('This is some random text with no keywords');
      
      expect(reply.suggestedToolId, isNotNull);
      expect(reply.text, isNotEmpty);
      expect(reply.text, contains('breathe')); // Fallback mentions breathing
    });
    
    test('should suggest brain dump for overwhelm patterns', () async {
      final reply = await provider.reply('Everything feels so chaotic and overwhelming');
      
      expect(reply.suggestedToolId, equals('brain-dump-park'));
      expect(reply.text, isNotEmpty);
    });
    
    test('should suggest grounding for disconnected patterns', () async {
      final reply = await provider.reply('I feel so disconnected and spacey');
      
      expect(reply.suggestedToolId, equals('ground-orient-5-4-3-2-1'));
      expect(reply.text, isNotEmpty);
    });
    
    test('should handle case insensitive matching', () async {
      final replies = await Future.wait([
        provider.reply('I feel ANXIOUS'),
        provider.reply('So STUCK right now'),
        provider.reply('Really LOW energy'),
      ]);
      
      expect(replies[0].suggestedToolId, equals('calm-breath'));
      expect(replies[1].suggestedToolId, equals('perspective-flip'));
      expect(replies[2].suggestedToolId, equals('tiny-next-step'));
    });
  });
}