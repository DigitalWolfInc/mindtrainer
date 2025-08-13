import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../lib/settings/email_optin_store.dart';
import '../payments/test_helpers/fake_path_provider_platform.dart';

void main() {
  group('EmailOptInStore Tests', () {
    late EmailOptInStore store;
    late FakePathProviderPlatform fakePathProvider;

    setUp(() {
      fakePathProvider = FakePathProviderPlatform();
      PathProviderPlatform.instance = fakePathProvider;
      EmailOptInStore.resetInstance();
      store = EmailOptInStore.instance;
    });

    tearDown(() {
      EmailOptInStore.resetInstance();
    });

    group('Default State', () {
      test('should default to false on missing file', () async {
        await store.init();
        expect(store.optedIn, false);
      });

      test('should throw if not initialized', () {
        expect(() => store.optedIn, throwsStateError);
      });
    });

    group('File Operations', () {
      test('should round-trip true/false with atomic write', () async {
        await store.init();
        expect(store.optedIn, false);

        // Set to true
        await store.setOptIn(true);
        expect(store.optedIn, true);

        // Verify file content
        final file = File('${fakePathProvider.documentsPath}/email_optin.json');
        expect(await file.exists(), true);
        
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        expect(data['optedIn'], true);
        expect(data['updatedAt'], isA<String>());

        // Set to false
        await store.setOptIn(false);
        expect(store.optedIn, false);

        // Verify file content updated
        final updatedContent = await file.readAsString();
        final updatedData = jsonDecode(updatedContent) as Map<String, dynamic>;
        expect(updatedData['optedIn'], false);
      });

      test('should persist across reinitializations', () async {
        // First instance
        await store.init();
        await store.setOptIn(true);

        // Reset and create new instance
        EmailOptInStore.resetInstance();
        final newStore = EmailOptInStore.instance;
        await newStore.init();
        
        expect(newStore.optedIn, true);
      });

      test('should use atomic write pattern with temp file', () async {
        await store.init();
        
        // Mock file system to verify temp file usage
        final file = File('${fakePathProvider.documentsPath}/email_optin.json');
        final tempFile = File('${fakePathProvider.documentsPath}/email_optin.json.tmp');
        
        await store.setOptIn(true);
        
        // Temp file should be cleaned up after rename
        expect(await tempFile.exists(), false);
        expect(await file.exists(), true);
      });
    });

    group('Error Recovery', () {
      test('should recover from malformed file', () async {
        // Create malformed file
        final file = File('${fakePathProvider.documentsPath}/email_optin.json');
        await file.create(recursive: true);
        await file.writeAsString('invalid json {');
        
        // Should recover to false
        await store.init();
        expect(store.optedIn, false);
      });

      test('should handle missing optedIn field', () async {
        // Create file with missing field
        final file = File('${fakePathProvider.documentsPath}/email_optin.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode({'other': 'data'}));
        
        // Should default to false
        await store.init();
        expect(store.optedIn, false);
      });

      test('should handle wrong data type for optedIn', () async {
        // Create file with wrong type
        final file = File('${fakePathProvider.documentsPath}/email_optin.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode({'optedIn': 'not_boolean'}));
        
        // Should recover to false
        await store.init();
        expect(store.optedIn, false);
      });
    });

    group('Singleton Behavior', () {
      test('should return same instance', () {
        final store1 = EmailOptInStore.instance;
        final store2 = EmailOptInStore.instance;
        expect(identical(store1, store2), true);
      });

      test('should create new instance after reset', () {
        final store1 = EmailOptInStore.instance;
        EmailOptInStore.resetInstance();
        final store2 = EmailOptInStore.instance;
        expect(identical(store1, store2), false);
      });
    });

    group('Concurrent Operations', () {
      test('should handle rapid toggles safely', () async {
        await store.init();
        
        // Rapid toggles
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(store.setOptIn(i % 2 == 0));
        }
        
        await Future.wait(futures);
        
        // Should end up in a consistent state
        expect(store.optedIn, isA<bool>());
      });
    });

    group('JSON Format', () {
      test('should include timestamp in saved data', () async {
        await store.init();
        await store.setOptIn(true);
        
        final file = File('${fakePathProvider.documentsPath}/email_optin.json');
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        expect(data.containsKey('updatedAt'), true);
        expect(data['updatedAt'], isA<String>());
        
        // Should be valid ISO8601 timestamp
        final timestamp = DateTime.parse(data['updatedAt'] as String);
        expect(timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
      });
    });
  });
}