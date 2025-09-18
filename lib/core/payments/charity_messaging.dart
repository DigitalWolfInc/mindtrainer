/// Charity Messaging for MindTrainer
/// 
/// Provides charity policy information and impact calculation logic.
/// No in-app donations - only messaging about subscription revenue allocation
/// and external donation link support.

/// Policy defining charity revenue sharing
class CharityPolicy {
  /// Fraction of subscription revenue allocated to charity (0.3333 for 1/3)
  final double share;
  
  /// Optional external donation webpage URL (opened in browser)
  final Uri? externalDonate;
  
  const CharityPolicy({
    required this.share,
    this.externalDonate,
  });
  
  /// Default policy: 1/3 of subscription revenue to shelters
  const CharityPolicy.defaultPolicy({Uri? externalDonate})
      : this(share: 1/3, externalDonate: externalDonate);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharityPolicy &&
          runtimeType == other.runtimeType &&
          share == other.share &&
          externalDonate == other.externalDonate;
  
  @override
  int get hashCode => share.hashCode ^ externalDonate.hashCode;
  
  @override
  String toString() => 'CharityPolicy(share: $share, externalDonate: $externalDonate)';
}

/// Snapshot of charity impact from subscription revenue
class ImpactSnapshot {
  /// Number of active Pro subscribers
  final int activeSubscribers;
  
  /// Total gross subscription revenue this month in cents
  final int monthlyCents;
  
  /// Amount earmarked for charity in cents (floor of share * monthlyCents)
  final int earmarkedCents;
  
  const ImpactSnapshot({
    required this.activeSubscribers,
    required this.monthlyCents,
    required this.earmarkedCents,
  });
  
  /// Earmarked amount in dollars (for display)
  double get earmarkedDollars => earmarkedCents / 100.0;
  
  /// Monthly revenue in dollars (for display)
  double get monthlyDollars => monthlyCents / 100.0;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImpactSnapshot &&
          runtimeType == other.runtimeType &&
          activeSubscribers == other.activeSubscribers &&
          monthlyCents == other.monthlyCents &&
          earmarkedCents == other.earmarkedCents;
  
  @override
  int get hashCode =>
      activeSubscribers.hashCode ^
      monthlyCents.hashCode ^
      earmarkedCents.hashCode;
  
  @override
  String toString() => 'ImpactSnapshot('
      'activeSubscribers: $activeSubscribers, '
      'monthlyCents: $monthlyCents, '
      'earmarkedCents: $earmarkedCents'
      ')';
}

/// Pure helper function to compute charity impact
/// 
/// UI supplies subscriber counts and revenue data (from backend when available).
/// Returns calculated impact snapshot for display.
ImpactSnapshot computeImpact({
  required CharityPolicy policy,
  required int activeSubscribers,
  required int monthlyCents, // Can be 0 if unknown
}) {
  final earmarked = (monthlyCents * policy.share).floor();
  
  return ImpactSnapshot(
    activeSubscribers: activeSubscribers,
    monthlyCents: monthlyCents,
    earmarkedCents: earmarked,
  );
}

/// Copy helper for UI charity messaging
/// 
/// Returns centralized charity blurb text (no i18n yet).
String charityBlurb(CharityPolicy policy) {
  return "MindTrainer allocates one-third of subscription revenue to a fund supporting shelters.";
}

/// Format earmarked amount for display
String formatEarmarked(ImpactSnapshot snapshot) {
  if (snapshot.earmarkedCents == 0) {
    return "Revenue data not available";
  }
  
  return "\$${snapshot.earmarkedDollars.toStringAsFixed(2)} earmarked this month";
}

/// Format subscriber count for display
String formatSubscriberImpact(ImpactSnapshot snapshot) {
  if (snapshot.activeSubscribers == 0) {
    return "Join our community to make an impact";
  } else if (snapshot.activeSubscribers == 1) {
    return "1 subscriber supporting shelters";
  } else {
    return "${snapshot.activeSubscribers} subscribers supporting shelters";
  }
}