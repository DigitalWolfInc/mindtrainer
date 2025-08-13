import 'receipt.dart';

class _AccessEvaluation {
  final bool hasAccess;
  final String reason;
  final DateTime? until;

  _AccessEvaluation({required this.hasAccess, required this.reason, this.until});
}

class Entitlement {
  final bool isPro;
  final String source;
  final DateTime? since;
  final DateTime? until;
  final String reason;

  const Entitlement._({
    required this.isPro,
    required this.source,
    required this.reason,
    this.since,
    this.until,
  });

  factory Entitlement.none([DateTime? now]) {
    return const Entitlement._(
      isPro: false,
      source: 'none',
      reason: 'no_receipts',
    );
  }

  factory Entitlement.fromReceipts(List<Receipt> receipts, [DateTime? now]) {
    now ??= DateTime.now();
    
    if (receipts.isEmpty) {
      return Entitlement.none(now);
    }

    // Ownership candidate set: purchased and not refunded/canceled
    final candidateReceipts = receipts
        .where((r) => r.purchaseState == 'purchased' && 
                      r.purchaseState != 'refunded' && 
                      r.purchaseState != 'cancelled')
        .toList();

    if (candidateReceipts.isEmpty) {
      final latestReceipt = _getLatestReceipt(receipts);
      return Entitlement._(
        isPro: false,
        source: latestReceipt?.source ?? 'none',
        reason: 'no_valid_receipts',
        since: latestReceipt?.purchaseTime,
      );
    }

    // Find the receipt that provides the furthest effective access
    Receipt? bestReceipt;
    DateTime? furthestAccess;
    String? accessReason;
    DateTime? accessUntil;

    for (final receipt in candidateReceipts) {
      if (!receipt.isPro) continue;

      final evaluation = _evaluateReceiptAccess(receipt, now);
      if (evaluation.hasAccess) {
        final effectiveUntil = evaluation.until ?? DateTime.fromMillisecondsSinceEpoch(2147483647000); // Far future if perpetual
        
        if (furthestAccess == null || effectiveUntil.isAfter(furthestAccess)) {
          bestReceipt = receipt;
          furthestAccess = effectiveUntil;
          accessReason = evaluation.reason;
          accessUntil = evaluation.until;
        }
      }
    }

    if (bestReceipt == null) {
      // No receipt provides access
      final latestReceipt = _getLatestReceipt(candidateReceipts);
      return Entitlement._(
        isPro: false,
        source: latestReceipt?.source ?? 'receipts-cache',
        reason: 'expired',
        since: latestReceipt?.purchaseTime,
      );
    }

    return Entitlement._(
      isPro: true,
      source: 'receipts-cache',
      reason: accessReason ?? 'owned',
      since: bestReceipt.purchaseTime,
      until: accessUntil,
    );
  }

  static Receipt? _getLatestReceipt(List<Receipt> receipts) {
    if (receipts.isEmpty) return null;
    
    return receipts.reduce((a, b) => 
        a.purchaseTime.isAfter(b.purchaseTime) ? a : b);
  }

  static _AccessEvaluation _evaluateReceiptAccess(Receipt receipt, DateTime now) {
    // If PAUSED, no access regardless of expiry
    if (receipt.accountState == 'PAUSED') {
      return _AccessEvaluation(hasAccess: false, reason: 'paused');
    }

    final expiryTime = receipt.expiryTime;
    
    // No expiry time means perpetual until contrary evidence
    if (expiryTime == null) {
      return _AccessEvaluation(hasAccess: true, reason: 'owned', until: null);
    }

    // Before expiry = owned
    if (now.isBefore(expiryTime)) {
      return _AccessEvaluation(hasAccess: true, reason: 'owned', until: expiryTime);
    }

    // At/after expiry
    if (now.isAtSameMomentAs(expiryTime) || now.isAfter(expiryTime)) {
      // Check for grace/hold states
      if (receipt.accountState == 'IN_GRACE' || receipt.accountState == 'ON_HOLD') {
        final graceBoundary = receipt.accountStateUntil ?? expiryTime.add(const Duration(days: 3));
        if (now.isBefore(graceBoundary)) {
          return _AccessEvaluation(hasAccess: true, reason: 'grace', until: graceBoundary);
        }
      }

      // Check auto-renewing logic
      if (receipt.autoRenewing == true) {
        // Temporarily not owned, await renewal
        return _AccessEvaluation(hasAccess: false, reason: 'awaiting_renewal');
      } else {
        // Non-renewing or unknown, definitely expired
        return _AccessEvaluation(hasAccess: false, reason: 'expired');
      }
    }

    return _AccessEvaluation(hasAccess: false, reason: 'expired');
  }

  static DateTime? _calculateExpirationDate(Receipt receipt) {
    // Legacy method - now we prefer receipt.expiryTime if available
    if (receipt.expiryTime != null) {
      return receipt.expiryTime;
    }

    final productId = receipt.productId;
    
    if (productId.contains('monthly')) {
      return receipt.purchaseTime.add(const Duration(days: 30));
    } else if (productId.contains('yearly')) {
      return receipt.purchaseTime.add(const Duration(days: 365));
    }
    
    return null;
  }

  bool get isExpired {
    if (until == null) return false;
    return DateTime.now().isAfter(until!);
  }

  bool get isValid => isPro && !isExpired;

  Duration? get timeRemaining {
    if (until == null) return null;
    final now = DateTime.now();
    if (now.isAfter(until!)) return null;
    return until!.difference(now);
  }

  Entitlement copyWith({
    bool? isPro,
    String? source,
    String? reason,
    DateTime? since,
    DateTime? until,
  }) {
    return Entitlement._(
      isPro: isPro ?? this.isPro,
      source: source ?? this.source,
      reason: reason ?? this.reason,
      since: since ?? this.since,
      until: until ?? this.until,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPro': isPro,
      'source': source,
      'reason': reason,
      'since': since?.toIso8601String(),
      'until': until?.toIso8601String(),
    };
  }

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement._(
      isPro: json['isPro'] as bool,
      source: json['source'] as String,
      reason: json['reason'] as String? ?? 'unknown',
      since: json['since'] != null 
          ? DateTime.parse(json['since'] as String) 
          : null,
      until: json['until'] != null 
          ? DateTime.parse(json['until'] as String) 
          : null,
    );
  }

  @override
  String toString() {
    final parts = ['Entitlement(isPro: $isPro, source: $source, reason: $reason'];
    if (since != null) parts.add('since: ${since!.toIso8601String()}');
    if (until != null) parts.add('until: ${until!.toIso8601String()}');
    return '${parts.join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Entitlement &&
            runtimeType == other.runtimeType &&
            isPro == other.isPro &&
            source == other.source &&
            reason == other.reason &&
            since == other.since &&
            until == other.until;
  }

  @override
  int get hashCode {
    return isPro.hashCode ^
        source.hashCode ^
        reason.hashCode ^
        since.hashCode ^
        until.hashCode;
  }
}