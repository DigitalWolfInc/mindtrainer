import 'dart:convert';

class Receipt {
  final String purchaseToken;
  final String productId;
  final String purchaseState;
  final DateTime purchaseTime;
  final bool acknowledged;
  final String source;
  final Map<String, dynamic>? raw;
  final DateTime? expiryTime;
  final bool? autoRenewing;
  final String? accountState;
  final DateTime? accountStateUntil;

  const Receipt._({
    required this.purchaseToken,
    required this.productId,
    required this.purchaseState,
    required this.purchaseTime,
    required this.acknowledged,
    required this.source,
    this.raw,
    this.expiryTime,
    this.autoRenewing,
    this.accountState,
    this.accountStateUntil,
  });

  factory Receipt.fromEvent(Map<String, dynamic> event) {
    final purchaseToken = event['purchaseToken'] as String? ?? '';
    final productId = event['productId'] as String? ?? '';
    final purchaseState = _normalizePurchaseState(event['purchaseState']);
    final purchaseTimeMillis = event['purchaseTime'] as int? ?? 0;
    final purchaseTime = DateTime.fromMillisecondsSinceEpoch(purchaseTimeMillis);
    final acknowledged = event['acknowledged'] as bool? ?? false;
    final source = event['source'] as String? ?? 'unknown';

    // Parse optional time-bounded fields
    final expiryTime = _parseExpiryTime(event['expiryTimeMillis']);
    final autoRenewing = event['autoRenewing'] as bool?;
    final accountState = _parseAccountState(event);
    final accountStateUntil = _parseAccountStateUntil(event['accountStateUntilMillis']);

    return Receipt._(
      purchaseToken: purchaseToken,
      productId: productId,
      purchaseState: purchaseState,
      purchaseTime: purchaseTime,
      acknowledged: acknowledged,
      source: source,
      raw: event,
      expiryTime: expiryTime,
      autoRenewing: autoRenewing,
      accountState: accountState,
      accountStateUntil: accountStateUntil,
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt._(
      purchaseToken: json['purchaseToken'] as String,
      productId: json['productId'] as String,
      purchaseState: json['purchaseState'] as String,
      purchaseTime: DateTime.parse(json['purchaseTime'] as String),
      acknowledged: json['acknowledged'] as bool,
      source: json['source'] as String,
      raw: json['raw'] as Map<String, dynamic>?,
      expiryTime: json['expiryTime'] != null ? DateTime.parse(json['expiryTime'] as String) : null,
      autoRenewing: json['autoRenewing'] as bool?,
      accountState: json['accountState'] as String?,
      accountStateUntil: json['accountStateUntil'] != null ? DateTime.parse(json['accountStateUntil'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseToken': purchaseToken,
      'productId': productId,
      'purchaseState': purchaseState,
      'purchaseTime': purchaseTime.toIso8601String(),
      'acknowledged': acknowledged,
      'source': source,
      'raw': raw,
      'expiryTime': expiryTime?.toIso8601String(),
      'autoRenewing': autoRenewing,
      'accountState': accountState,
      'accountStateUntil': accountStateUntil?.toIso8601String(),
    };
  }

  Receipt copyWith({
    String? purchaseToken,
    String? productId,
    String? purchaseState,
    DateTime? purchaseTime,
    bool? acknowledged,
    String? source,
    Map<String, dynamic>? raw,
    DateTime? expiryTime,
    bool? autoRenewing,
    String? accountState,
    DateTime? accountStateUntil,
  }) {
    return Receipt._(
      purchaseToken: purchaseToken ?? this.purchaseToken,
      productId: productId ?? this.productId,
      purchaseState: purchaseState ?? this.purchaseState,
      purchaseTime: purchaseTime ?? this.purchaseTime,
      acknowledged: acknowledged ?? this.acknowledged,
      source: source ?? this.source,
      raw: raw ?? this.raw,
      expiryTime: expiryTime ?? this.expiryTime,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      accountState: accountState ?? this.accountState,
      accountStateUntil: accountStateUntil ?? this.accountStateUntil,
    );
  }

  bool get isPro => (productId.contains('_pro_') || productId.endsWith('_pro')) && 
                    purchaseState == 'purchased' && acknowledged;

  bool get isActive {
    return purchaseState == 'purchased' && acknowledged;
  }

  static String _normalizePurchaseState(dynamic state) {
    if (state == null) return 'unknown';
    
    final stateStr = state.toString().toLowerCase();
    switch (stateStr) {
      case 'purchased':
      case '1':
        return 'purchased';
      case 'pending':
      case '0':
        return 'pending';
      case 'cancelled':
      case 'canceled':
      case '2':
        return 'cancelled';
      default:
        return stateStr;
    }
  }

  @override
  String toString() {
    final tokenDisplay = purchaseToken.length > 8 
        ? '${purchaseToken.substring(0, 8)}...' 
        : purchaseToken;
    final expiryDisplay = expiryTime != null ? ', expiry: ${expiryTime!.toIso8601String()}' : '';
    final renewDisplay = autoRenewing != null ? ', autoRenew: $autoRenewing' : '';
    final stateDisplay = accountState != null ? ', state: $accountState' : '';
    return 'Receipt(token: $tokenDisplay, '
           'product: $productId, state: $purchaseState, '
           'time: ${purchaseTime.toIso8601String()}, '
           'acknowledged: $acknowledged, source: $source$expiryDisplay$renewDisplay$stateDisplay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Receipt &&
            runtimeType == other.runtimeType &&
            purchaseToken == other.purchaseToken &&
            productId == other.productId &&
            purchaseState == other.purchaseState &&
            purchaseTime == other.purchaseTime &&
            acknowledged == other.acknowledged &&
            source == other.source &&
            expiryTime == other.expiryTime &&
            autoRenewing == other.autoRenewing &&
            accountState == other.accountState &&
            accountStateUntil == other.accountStateUntil;
  }

  @override
  int get hashCode {
    return purchaseToken.hashCode ^
        productId.hashCode ^
        purchaseState.hashCode ^
        purchaseTime.hashCode ^
        acknowledged.hashCode ^
        source.hashCode ^
        expiryTime.hashCode ^
        autoRenewing.hashCode ^
        accountState.hashCode ^
        accountStateUntil.hashCode;
  }

  static DateTime? _parseExpiryTime(dynamic expiryTimeMillis) {
    if (expiryTimeMillis == null) return null;
    
    try {
      int? millis;
      if (expiryTimeMillis is int) {
        millis = expiryTimeMillis;
      } else if (expiryTimeMillis is String) {
        millis = int.tryParse(expiryTimeMillis);
      }
      
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (e) {
      // Ignore malformed input
    }
    
    return null;
  }

  static String? _parseAccountState(Map<String, dynamic> event) {
    try {
      // Priority: PAUSED > ON_HOLD > IN_GRACE > ACTIVE
      if (event['isPaused'] == true) {
        return 'PAUSED';
      }
      if (event['accountHold'] == true || event['isOnHold'] == true) {
        return 'ON_HOLD';
      }
      if (event['isInGracePeriod'] == true || event['inGracePeriod'] == true) {
        return 'IN_GRACE';
      }
      
      // Check for explicit state string
      final stateStr = event['accountState'] as String?;
      if (stateStr != null) {
        final normalized = stateStr.toUpperCase();
        if (['ACTIVE', 'ON_HOLD', 'IN_GRACE', 'PAUSED'].contains(normalized)) {
          return normalized;
        }
      }
      
      // Default to ACTIVE if we have purchase state but no specific account issues
      if (event['purchaseState'] != null) {
        return 'ACTIVE';
      }
    } catch (e) {
      // Ignore malformed input
    }
    
    return null;
  }

  static DateTime? _parseAccountStateUntil(dynamic accountStateUntilMillis) {
    if (accountStateUntilMillis == null) return null;
    
    try {
      int? millis;
      if (accountStateUntilMillis is int) {
        millis = accountStateUntilMillis;
      } else if (accountStateUntilMillis is String) {
        millis = int.tryParse(accountStateUntilMillis);
      }
      
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (e) {
      // Ignore malformed input
    }
    
    return null;
  }
}