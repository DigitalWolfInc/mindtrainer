/// Pro Subscription Status for MindTrainer
/// 
/// Provides subscription tiers, status tracking, and feature gates for Pro functionality.
/// No payment SDK integration yet - just ports and logic for later platform adapters.

/// Available Pro subscription tiers
enum ProTier {
  /// Free tier with basic features
  free,
  /// Premium subscription with full features
  pro,
}

/// Current Pro subscription status
class ProStatus {
  /// The active subscription tier
  final ProTier tier;
  
  /// Whether the subscription is currently active
  final bool active;
  
  /// Optional expiration date for active subscriptions
  final DateTime? expiresAt;
  
  /// Optional renewal information
  final bool autoRenewing;
  
  const ProStatus({
    required this.tier,
    required this.active,
    this.expiresAt,
    this.autoRenewing = false,
  });
  
  /// Create free tier status
  const ProStatus.free() : this(
    tier: ProTier.free,
    active: false,
    autoRenewing: false,
  );
  
  /// Create active Pro status
  ProStatus.activePro({
    DateTime? expiresAt,
    bool autoRenewing = true,
  }) : this(
    tier: ProTier.pro,
    active: true,
    expiresAt: expiresAt,
    autoRenewing: autoRenewing,
  );
  
  /// Whether this is an active Pro subscription
  bool get isPro => tier == ProTier.pro && active;
  
  /// Whether subscription has expired (if expiration date is set)
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProStatus &&
          runtimeType == other.runtimeType &&
          tier == other.tier &&
          active == other.active &&
          expiresAt == other.expiresAt &&
          autoRenewing == other.autoRenewing;
  
  @override
  int get hashCode =>
      tier.hashCode ^
      active.hashCode ^
      expiresAt.hashCode ^
      autoRenewing.hashCode;
      
  @override
  String toString() => 'ProStatus('
      'tier: $tier, '
      'active: $active, '
      'expiresAt: $expiresAt, '
      'autoRenewing: $autoRenewing'
      ')';
}