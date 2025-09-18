import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/price_cache.dart';

class PriceCacheStore {
  static const String _fileName = 'price_cache.json';
  static PriceCacheStore? _instance;
  
  PriceCache? _cache;
  bool _loaded = false;

  PriceCacheStore._();

  static PriceCacheStore get instance {
    _instance ??= PriceCacheStore._();
    return _instance!;
  }

  Future<void> saveCache(PriceCache cache) async {
    _cache = cache;
    await _saveToFile();
  }

  Future<PriceCache> getCache() async {
    await _ensureLoaded();
    return _cache ?? PriceCache.empty();
  }

  Future<PriceCache> updatePrices(Map<String, String> newPrices) async {
    final current = await getCache();
    final updated = current.updatePrices(newPrices);
    await saveCache(updated);
    return updated;
  }

  Future<String?> getPriceForProduct(String productId) async {
    final cache = await getCache();
    return cache.getPriceForProduct(productId);
  }

  Future<bool> hasPriceForProduct(String productId) async {
    final cache = await getCache();
    return cache.hasPriceForProduct(productId);
  }

  Future<bool> isCacheStale() async {
    final cache = await getCache();
    return cache.isStale;
  }

  Future<bool> isCacheEmpty() async {
    final cache = await getCache();
    return cache.isEmpty;
  }

  Future<Duration> getCacheAge() async {
    final cache = await getCache();
    return cache.age;
  }

  Future<void> clear() async {
    _cache = PriceCache.empty();
    await _saveToFile();
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) {
      await _loadFromFile();
      _loaded = true;
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = await _getFile();
      
      if (!await file.exists()) {
        _cache = PriceCache.empty();
        return;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _cache = PriceCache.empty();
        return;
      }

      final jsonData = json.decode(content);
      if (jsonData is Map<String, dynamic>) {
        _cache = PriceCache.fromJson(jsonData);
      } else {
        _cache = PriceCache.empty();
      }
    } catch (e) {
      // If loading fails, start with empty cache
      _cache = PriceCache.empty();
    }
  }

  Future<void> _saveToFile() async {
    if (_cache == null) return;
    
    try {
      final file = await _getFile();
      
      // Ensure parent directory exists
      await file.parent.create(recursive: true);
      
      final content = json.encode(_cache!.toJson());
      
      // Atomic write: write to temp file, then rename
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(content);
      await tempFile.rename(file.path);
      
    } catch (e) {
      // Log error but don't throw - we want the app to continue working
      // even if persistence fails
      rethrow;
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Map<String, dynamic> getDebugInfo() {
    final cache = _cache;
    return {
      'loaded': _loaded,
      'hasCache': cache != null,
      'isEmpty': cache?.isEmpty ?? true,
      'isStale': cache?.isStale ?? false,
      'age': cache?.age.toString(),
      'productCount': cache?.cachedProductIds.length ?? 0,
      'products': cache?.cachedProductIds ?? [],
    };
  }

  static void resetInstance() {
    _instance = null;
  }
}