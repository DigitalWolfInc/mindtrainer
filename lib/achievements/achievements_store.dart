import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'badge.dart';
import 'snapshot.dart';

class AchievementsStore {
  static AchievementsStore? _instance;
  
  AchievementsSnapshot _snapshot = AchievementsSnapshot.empty();
  bool _initialized = false;

  AchievementsStore._();

  static AchievementsStore get instance {
    _instance ??= AchievementsStore._();
    return _instance!;
  }

  AchievementsSnapshot get snapshot => _snapshot;

  Future<void> init() async {
    if (_initialized) return;
    
    final data = await _readJsonSafe();
    if (data != null) {
      try {
        _snapshot = AchievementsSnapshot.fromJson(data);
      } catch (e) {
        // Malformed data, start with empty snapshot
        _snapshot = AchievementsSnapshot.empty();
      }
    } else {
      _snapshot = AchievementsSnapshot.empty();
    }
    
    _initialized = true;
  }

  Future<void> upsert(Badge badge) async {
    await upsertMany([badge]);
  }

  Future<void> upsertMany(Iterable<Badge> badges) async {
    if (badges.isEmpty) return;
    
    _snapshot = _snapshot.withBadges(badges);
    await _writeJsonAtomic(_snapshot.toJson());
  }

  Future<void> replaceAll(AchievementsSnapshot snapshot) async {
    _snapshot = snapshot;
    await _writeJsonAtomic(_snapshot.toJson());
  }

  // Animal counter methods (additive storage)
  static const String _kAnimalCountsV1 = 'mt_ach_animal_counts_v1';

  Future<Map<String, int>> _readAnimalCounts() async {
    try {
      final file = File(await _getAnimalCountsPath());
      if (!await file.exists()) return {};
      
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v as int));
    } catch (e) {
      return {};
    }
  }

  Future<void> _writeAnimalCounts(Map<String, int> counts) async {
    final path = await _getAnimalCountsPath();
    final file = File(path);
    
    try {
      await file.parent.create(recursive: true);
      final content = jsonEncode(counts);
      await file.writeAsString(content);
    } catch (e) {
      // Ignore write errors for now
    }
  }

  Future<String> _getAnimalCountsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/animal_counts.json';
  }

  Future<int> incrementAnimal(String species) async {
    final counts = Map<String, int>.from(await _readAnimalCounts());
    final newCount = (counts[species] ?? 0) + 1;
    counts[species] = newCount;
    await _writeAnimalCounts(counts);
    return newCount;
  }

  Future<Map<String, int>> getAnimalCounts() async {
    return await _readAnimalCounts();
  }

  Future<List<Badge>> fetchByCategory(String category) async {
    await init();
    return _snapshot.badges.where((badge) => badge.category == category).toList();
  }

  Future<void> unlock(Badge badge) async {
    await upsert(badge);
  }

  // Private methods

  Future<String> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/achievements.json';
  }

  Future<Map<String, dynamic>?> _readJsonSafe() async {
    try {
      final file = File(await _path());
      if (!await file.exists()) return null;
      
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      // Ignore any read errors - start fresh
      return null;
    }
  }

  Future<void> _writeJsonAtomic(Map<String, dynamic> data) async {
    final path = await _path();
    final file = File(path);
    final tempFile = File('$path.tmp');

    try {
      // Ensure parent directory exists
      await file.parent.create(recursive: true);
      
      // Write to temp file
      final content = jsonEncode(data);
      await tempFile.writeAsString(content);
      
      // Atomic rename
      await tempFile.rename(path);
    } catch (e) {
      // Clean up temp file if it exists
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      rethrow;
    }
  }

  // Testing helpers
  static void resetInstance() {
    _instance = null;
  }

  static void setTestInstance(AchievementsStore store) {
    _instance = store;
  }
}