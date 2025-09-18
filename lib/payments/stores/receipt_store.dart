import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/receipt.dart';

class ReceiptStore {
  static const String _fileName = 'receipts.json';
  static ReceiptStore? _instance;
  
  final Map<String, Receipt> _cache = {};
  bool _loaded = false;

  ReceiptStore._();

  static ReceiptStore get instance {
    _instance ??= ReceiptStore._();
    return _instance!;
  }

  Future<void> addReceipt(Receipt receipt) async {
    await _ensureLoaded();
    
    _cache[receipt.purchaseToken] = receipt;
    await _saveToFile();
  }

  Future<void> addReceipts(List<Receipt> receipts) async {
    if (receipts.isEmpty) return;
    
    await _ensureLoaded();
    
    bool hasChanges = false;
    for (final receipt in receipts) {
      final existing = _cache[receipt.purchaseToken];
      if (existing != receipt) {
        _cache[receipt.purchaseToken] = receipt;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveToFile();
    }
  }

  Future<Receipt?> getReceipt(String purchaseToken) async {
    await _ensureLoaded();
    return _cache[purchaseToken];
  }

  Future<List<Receipt>> getAllReceipts() async {
    await _ensureLoaded();
    return _cache.values.toList();
  }

  Future<List<Receipt>> getReceiptsForProduct(String productId) async {
    await _ensureLoaded();
    return _cache.values
        .where((receipt) => receipt.productId == productId)
        .toList();
  }

  Future<List<Receipt>> getActiveProReceipts() async {
    await _ensureLoaded();
    return _cache.values
        .where((receipt) => receipt.isPro && receipt.isActive)
        .toList();
  }

  Future<bool> removeReceipt(String purchaseToken) async {
    await _ensureLoaded();
    
    final removed = _cache.remove(purchaseToken);
    if (removed != null) {
      await _saveToFile();
      return true;
    }
    return false;
  }

  Future<void> clear() async {
    _cache.clear();
    await _saveToFile();
  }

  Future<int> count() async {
    await _ensureLoaded();
    return _cache.length;
  }

  Future<bool> isEmpty() async {
    await _ensureLoaded();
    return _cache.isEmpty;
  }

  Future<bool> isNotEmpty() async {
    await _ensureLoaded();
    return _cache.isNotEmpty;
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
        return;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return;
      }

      final jsonData = json.decode(content);
      if (jsonData is Map<String, dynamic>) {
        final receiptsJson = jsonData['receipts'] as List<dynamic>?;
        if (receiptsJson != null) {
          _cache.clear();
          for (final receiptJson in receiptsJson) {
            if (receiptJson is Map<String, dynamic>) {
              try {
                final receipt = Receipt.fromJson(receiptJson);
                _cache[receipt.purchaseToken] = receipt;
              } catch (e) {
                // Skip invalid receipt entries
                continue;
              }
            }
          }
        }
      }
    } catch (e) {
      // If loading fails, start with empty cache
      _cache.clear();
    }
  }

  Future<void> _saveToFile() async {
    try {
      final file = await _getFile();
      
      // Ensure parent directory exists
      await file.parent.create(recursive: true);
      
      final receiptsJson = _cache.values
          .map((receipt) => receipt.toJson())
          .toList();
      
      final data = {
        'version': 1,
        'receipts': receiptsJson,
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      final content = json.encode(data);
      
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
    return {
      'loaded': _loaded,
      'cacheSize': _cache.length,
      'receiptTokens': _cache.keys.map((token) => 
          '${token.substring(0, 8)}...').toList(),
      'activeProCount': _cache.values
          .where((r) => r.isPro && r.isActive).length,
    };
  }

  static void resetInstance() {
    _instance = null;
  }
}