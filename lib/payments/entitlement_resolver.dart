import 'dart:async';
import 'package:flutter/foundation.dart';

import 'models/receipt.dart';
import 'models/entitlement.dart';
import 'stores/receipt_store.dart';
import '../settings/diagnostics.dart';

class EntitlementResolver extends ChangeNotifier {
  static const bool _diagEnabled = true;
  static EntitlementResolver? _instance;
  
  final ReceiptStore _receiptStore;
  Entitlement _currentEntitlement = Entitlement.none();
  bool _initialized = false;

  EntitlementResolver._(this._receiptStore);

  static EntitlementResolver get instance {
    _instance ??= EntitlementResolver._(ReceiptStore.instance);
    return _instance!;
  }

  Entitlement get currentEntitlement => _currentEntitlement;
  bool get isPro => _currentEntitlement.isPro;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    
    await _refreshEntitlementFromStore();
    _initialized = true;
  }

  Future<void> handleBillingEvent(Map<String, dynamic> event) async {
    final eventType = event['type'] as String?;
    
    switch (eventType) {
      case 'purchase_completed':
      case 'purchase_restored':
        await _handlePurchaseEvent(event);
        break;
      case 'purchase_cancelled':
        await _handleCancellationEvent(event);
        break;
      case 'subscription_expired':
        await _handleExpirationEvent(event);
        break;
      default:
        // Unknown event type, ignore
        break;
    }
  }

  Future<void> _handlePurchaseEvent(Map<String, dynamic> event) async {
    final purchaseData = event['purchase'] as Map<String, dynamic>?;
    if (purchaseData == null) return;

    final receipt = Receipt.fromEvent(purchaseData);
    
    // Log receipt parsing with time-bounded fields
    if (_diagEnabled) {
      final details = <String>[];
      if (receipt.expiryTime != null) {
        details.add('expiryTime=${receipt.expiryTime!.toIso8601String()}');
      }
      if (receipt.autoRenewing != null) {
        details.add('autoRenewing=${receipt.autoRenewing}');
      }
      if (receipt.accountState != null) {
        details.add('accountState=${receipt.accountState}');
      }
      
      if (details.isNotEmpty) {
        Diag.d('Receipt', 'Parsed with ${details.join(', ')} for ${receipt.productId}');
      }
    }
    
    await _receiptStore.addReceipt(receipt);
    await _refreshEntitlement();
  }

  Future<void> _handleCancellationEvent(Map<String, dynamic> event) async {
    final purchaseToken = event['purchaseToken'] as String?;
    if (purchaseToken == null) return;

    final existingReceipt = await _receiptStore.getReceipt(purchaseToken);
    if (existingReceipt != null) {
      final cancelledReceipt = existingReceipt.copyWith(
        purchaseState: 'cancelled',
      );
      await _receiptStore.addReceipt(cancelledReceipt);
      await _refreshEntitlement();
    }
  }

  Future<void> _handleExpirationEvent(Map<String, dynamic> event) async {
    await _refreshEntitlement();
  }

  Future<void> processReceiptsFromBilling(List<Map<String, dynamic>> purchaseInfos) async {
    if (purchaseInfos.isEmpty) return;

    final receipts = purchaseInfos
        .map((info) => Receipt.fromEvent(info))
        .toList();

    // Log receipt parsing with time-bounded fields
    if (_diagEnabled) {
      for (final receipt in receipts) {
        final details = <String>[];
        if (receipt.expiryTime != null) {
          details.add('expiryTime=${receipt.expiryTime!.toIso8601String()}');
        }
        if (receipt.autoRenewing != null) {
          details.add('autoRenewing=${receipt.autoRenewing}');
        }
        if (receipt.accountState != null) {
          details.add('accountState=${receipt.accountState}');
        }
        
        if (details.isNotEmpty) {
          Diag.d('Receipt', 'Parsed with ${details.join(', ')} for ${receipt.productId}');
        }
      }
    }

    await _receiptStore.addReceipts(receipts);
    await _refreshEntitlement();
  }

  Future<void> _refreshEntitlement() async {
    await _refreshEntitlementFromStore();
  }

  Future<void> _refreshEntitlementFromStore() async {
    final now = DateTime.now();
    final receipts = await _receiptStore.getAllReceipts();
    final newEntitlement = Entitlement.fromReceipts(receipts, now);
    
    if (newEntitlement != _currentEntitlement) {
      final wasProBefore = _currentEntitlement.isPro;
      final isProNow = newEntitlement.isPro;
      final oldReason = _currentEntitlement.reason;
      final newReason = newEntitlement.reason;
      
      if (_diagEnabled) {
        if (wasProBefore != isProNow) {
          String reasonDetails = '';
          if (newReason == 'grace') {
            reasonDetails = ' (in grace period until ${newEntitlement.until?.toIso8601String()})';
          } else if (newReason == 'expired' && oldReason != 'expired') {
            reasonDetails = ' (expired)';
          } else if (newReason == 'awaiting_renewal') {
            reasonDetails = ' (awaiting renewal)';
          }
          
          Diag.d('Billing', 'Entitlement recompute: ${wasProBefore ? 'Pro → Free' : 'Free → Pro'}$reasonDetails');
        } else if (oldReason != newReason) {
          Diag.d('Billing', 'Entitlement reason changed: $oldReason → $newReason');
        }
        
        // Log time-based transitions
        if (newReason == 'expired' && receipts.any((r) => r.expiryTime != null)) {
          final expiredReceipts = receipts.where((r) => r.expiryTime != null && now.isAfter(r.expiryTime!));
          for (final receipt in expiredReceipts) {
            if (receipt.autoRenewing == false) {
              Diag.d('Entitlement', 'expired at ${receipt.expiryTime!.toIso8601String()}; autoRenewing=false → revoke');
            } else if (receipt.autoRenewing == true) {
              Diag.d('Entitlement', 'expired at ${receipt.expiryTime!.toIso8601String()}; autoRenewing=true → await renewal');
            }
          }
        }
      }
      
      _currentEntitlement = newEntitlement;
      notifyListeners();
    }
  }

  Future<void> forceRefresh() async {
    await _refreshEntitlement();
  }

  Future<List<Receipt>> getAllReceipts() async {
    return await _receiptStore.getAllReceipts();
  }

  Future<List<Receipt>> getActiveProReceipts() async {
    return await _receiptStore.getActiveProReceipts();
  }

  Future<void> clearAllData() async {
    await _receiptStore.clear();
    _currentEntitlement = Entitlement.none();
    notifyListeners();
  }

  Stream<Entitlement> get entitlementStream {
    late StreamController<Entitlement> controller;
    
    controller = StreamController<Entitlement>(
      onListen: () {
        controller.add(_currentEntitlement);
        addListener(() {
          if (!controller.isClosed) {
            controller.add(_currentEntitlement);
          }
        });
      },
      onCancel: () {
        removeListener(() {});
      },
    );
    
    return controller.stream;
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'currentEntitlement': _currentEntitlement.toJson(),
      'isPro': isPro,
      'receiptStore': _receiptStore.getDebugInfo(),
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  static void setTestInstance(EntitlementResolver resolver) {
    _instance = resolver;
  }
}