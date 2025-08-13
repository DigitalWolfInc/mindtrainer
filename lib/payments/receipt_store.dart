import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'billing_constants.dart';

/// File-based storage for purchase receipts with atomic operations
/// 
/// Provides persistence for valid purchase receipts to maintain Pro state
/// across app restarts and device reboots.
class ReceiptStore {
  static const String _fileName = BillingFileConstants.receiptsFileName;
  static ReceiptStore? _instance;
  File? _file;
  Map<String, PurchaseInfo> _cache = {};

  ReceiptStore._();

  /// Singleton instance
  static ReceiptStore get instance {
    _instance ??= ReceiptStore._();
    return _instance!;
  }

  /// Initialize the store and load existing receipts
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _file = File('${directory.path}/$_fileName');
      await _loadReceipts();
    } catch (e) {
      // If initialization fails, continue with empty cache
      _cache = {};
    }
  }

  /// Save a purchase receipt with duplicate token handling
  /// 
  /// Only saves valid, purchased receipts. Uses atomic write operation
  /// (write to temp file, then rename) to prevent corruption.
  /// 
  /// If a receipt with the same purchaseToken already exists, the new
  /// receipt will replace it (new fields overwrite old ones).
  Future<void> saveReceipt(PurchaseInfo purchase) async {
    if (!purchase.isValid) {
      throw ArgumentError('Cannot save invalid purchase receipt');
    }

    if (purchase.productId == null || purchase.purchaseToken == null) {
      throw ArgumentError('Purchase must have productId and purchaseToken');
    }

    // Handle duplicate token: if same purchaseToken exists, replace entry
    final purchaseToken = purchase.purchaseToken!;
    final existingKey = _cache.keys.firstWhere(
      (key) => _cache[key]?.purchaseToken == purchaseToken,
      orElse: () => '',
    );
    
    if (existingKey.isNotEmpty) {
      // Remove old entry with same token
      _cache.remove(existingKey);
    }

    // Add new entry
    final key = _getReceiptKey(purchase.productId!, purchaseToken);
    _cache[key] = purchase;

    // Prune stale receipts for the same product
    _pruneStaleReceipts(purchase.productId!);

    // Persist to file
    await _writeReceipts();
  }
  
  /// Prune stale receipts by keeping only the latest per productId by purchaseTimeMs
  void _pruneStaleReceipts(String productId) {
    final receiptsForProduct = _cache.values
        .where((p) => p.productId == productId)
        .toList();
    
    if (receiptsForProduct.length <= 1) {
      return; // Nothing to prune
    }
    
    // Sort by purchase time (newest first)
    receiptsForProduct.sort((a, b) {
      final aTime = a.purchaseTime ?? 0;
      final bTime = b.purchaseTime ?? 0;
      return bTime.compareTo(aTime);
    });
    
    // Keep only the newest receipt for this product
    final latestReceipt = receiptsForProduct.first;
    
    // Remove older receipts for the same product
    final keysToRemove = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.productId == productId && 
          entry.value.purchaseToken != latestReceipt.purchaseToken) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Get a specific receipt by product ID and purchase token
  PurchaseInfo? getReceipt(String productId, String purchaseToken) {
    final key = _getReceiptKey(productId, purchaseToken);
    return _cache[key];
  }

  /// Get all receipts for a specific product ID
  List<PurchaseInfo> getReceiptsForProduct(String productId) {
    return _cache.values
        .where((purchase) => purchase.productId == productId)
        .toList();
  }

  /// Get all stored receipts
  List<PurchaseInfo> getAllReceipts() {
    return _cache.values.toList();
  }

  /// Check if we have a valid receipt for any Pro product
  bool hasValidProReceipt() {
    return _cache.values.any((purchase) =>
        purchase.isValid &&
        BillingProducts.isProProduct(purchase.productId));
  }

  /// Get the most recent Pro purchase (if any)
  PurchaseInfo? getMostRecentProPurchase() {
    final proPurchases = _cache.values
        .where((purchase) =>
            purchase.isValid &&
            BillingProducts.isProProduct(purchase.productId))
        .toList();

    if (proPurchases.isEmpty) return null;

    // Sort by purchase time (most recent first)
    proPurchases.sort((a, b) {
      final timeA = a.purchaseTime ?? 0;
      final timeB = b.purchaseTime ?? 0;
      return timeB.compareTo(timeA);
    });

    return proPurchases.first;
  }

  /// Remove a receipt (typically after it's been consumed or refunded)
  Future<void> removeReceipt(String productId, String purchaseToken) async {
    final key = _getReceiptKey(productId, purchaseToken);
    final removed = _cache.remove(key);
    
    if (removed != null) {
      await _writeReceipts();
    }
  }

  /// Clear all stored receipts
  Future<void> clearAll() async {
    _cache.clear();
    await _writeReceipts();
  }

  /// Get count of stored receipts
  int get receiptCount => _cache.length;

  /// Check if store has been initialized
  bool get isInitialized => _file != null;

  /// Reset instance for testing (test use only)
  static void resetInstance() {
    _instance = null;
  }

  /// Create unique key for receipt storage
  String _getReceiptKey(String productId, String purchaseToken) {
    return '${productId}_${purchaseToken}';
  }

  /// Load receipts from file
  Future<void> _loadReceipts() async {
    if (_file == null || !await _file!.exists()) {
      _cache = {};
      return;
    }

    try {
      final content = await _file!.readAsString();
      if (content.trim().isEmpty) {
        _cache = {};
        return;
      }

      final data = jsonDecode(content) as Map<String, dynamic>;
      _cache = {};
      
      for (final entry in data.entries) {
        try {
          final purchaseMap = Map<String, Object?>.from(entry.value as Map);
          final purchase = PurchaseInfo.fromMap(purchaseMap);
          
          // Only load valid purchases
          if (purchase.isValid) {
            _cache[entry.key] = purchase;
          }
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    } catch (e) {
      // If loading fails, start with empty cache
      _cache = {};
    }
  }

  /// Write receipts to file using atomic operation
  Future<void> _writeReceipts() async {
    if (_file == null) return;

    try {
      // Convert cache to JSON
      final data = <String, Map<String, Object?>>{};
      for (final entry in _cache.entries) {
        data[entry.key] = entry.value.toMap();
      }

      final jsonContent = jsonEncode(data);
      
      // Atomic write: write to temp file, then rename
      final tempFile = File('${_file!.path}.tmp');
      await tempFile.writeAsString(jsonContent);
      await tempFile.rename(_file!.path);
    } catch (e) {
      // Write failure is non-fatal - cache remains valid
      // Could log error in production
    }
  }
}

/// Statistics and metadata about stored receipts
class ReceiptStoreStats {
  final int totalReceipts;
  final int proReceipts;
  final List<String> productIds;
  final DateTime? oldestPurchase;
  final DateTime? newestPurchase;
  final bool hasValidProSubscription;

  const ReceiptStoreStats({
    required this.totalReceipts,
    required this.proReceipts,
    required this.productIds,
    this.oldestPurchase,
    this.newestPurchase,
    required this.hasValidProSubscription,
  });

  /// Generate stats from current receipt store
  static ReceiptStoreStats fromStore(ReceiptStore store) {
    final receipts = store.getAllReceipts();
    final proReceipts = receipts.where((r) => 
        BillingProducts.isProProduct(r.productId)).toList();
    
    final productIds = receipts
        .map((r) => r.productId)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    DateTime? oldest;
    DateTime? newest;

    for (final receipt in receipts) {
      final purchaseTime = receipt.purchaseDateTime;
      if (purchaseTime != null) {
        oldest = oldest == null || purchaseTime.isBefore(oldest) 
            ? purchaseTime : oldest;
        newest = newest == null || purchaseTime.isAfter(newest) 
            ? purchaseTime : newest;
      }
    }

    return ReceiptStoreStats(
      totalReceipts: receipts.length,
      proReceipts: proReceipts.length,
      productIds: productIds,
      oldestPurchase: oldest,
      newestPurchase: newest,
      hasValidProSubscription: store.hasValidProReceipt(),
    );
  }

  @override
  String toString() => 
      'ReceiptStoreStats(total: $totalReceipts, pro: $proReceipts, hasValid: $hasValidProSubscription)';
}