/// Billing catalog - source of truth for MindTrainer Pro subscriptions
/// Mirrors Play Console configuration, consumed by ProCatalog and billing adapters

/// Subscription product definition
class SubscriptionProduct {
  final String productId;
  final String basePlanId;
  final String title;
  final String description;
  final String currency;
  final int priceMicros;
  final String billingPeriod;
  final bool freeTrialEnabled;
  final String? freeTrialPeriod;
  final String gracePeriod;

  const SubscriptionProduct({
    required this.productId,
    required this.basePlanId,
    required this.title,
    required this.description,
    required this.currency,
    required this.priceMicros,
    required this.billingPeriod,
    required this.freeTrialEnabled,
    this.freeTrialPeriod,
    required this.gracePeriod,
  });

  /// Get formatted price string (e.g., "$9.99")
  String get formattedPrice {
    final dollars = priceMicros / 1000000;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Get price in dollars as double
  double get priceInDollars => priceMicros / 1000000;

  /// Get billing cycle description
  String get billingCycleDescription {
    switch (billingPeriod) {
      case 'P1M':
        return 'per month';
      case 'P1Y':
        return 'per year';
      default:
        return 'per billing cycle';
    }
  }

  /// Get savings percentage compared to monthly (for yearly plan)
  int? getSavingsPercent(SubscriptionProduct monthlyPlan) {
    if (billingPeriod != 'P1Y' || monthlyPlan.billingPeriod != 'P1M') {
      return null;
    }
    
    final yearlyEquivalent = monthlyPlan.priceMicros * 12;
    final savings = ((yearlyEquivalent - priceMicros) / yearlyEquivalent * 100).round();
    return savings > 0 ? savings : null;
  }

  /// Check if product has free trial
  bool get hasFreeTrial => freeTrialEnabled && freeTrialPeriod != null;

  /// Get free trial description
  String? get freeTrialDescription {
    if (!hasFreeTrial) return null;
    
    switch (freeTrialPeriod) {
      case 'P7D':
        return '7-day free trial';
      case 'P14D':
        return '14-day free trial';
      case 'P30D':
        return '30-day free trial';
      default:
        return 'Free trial available';
    }
  }
}

/// Upgrade/downgrade rule configuration
class UpgradeDowngradeRule {
  final String fromProductId;
  final String toProductId;
  final String type; // 'upgrade' or 'downgrade'
  final String prorationMode;
  final String replacementMode;

  const UpgradeDowngradeRule({
    required this.fromProductId,
    required this.toProductId,
    required this.type,
    required this.prorationMode,
    required this.replacementMode,
  });

  bool get isUpgrade => type == 'upgrade';
  bool get isImmediate => prorationMode.contains('immediate');
}

/// Complete billing catalog for MindTrainer
class BillingCatalog {
  static const SubscriptionProduct monthlyPro = SubscriptionProduct(
    productId: 'pro_monthly',
    basePlanId: 'base_monthly_v1',
    title: 'MindTrainer Pro Monthly',
    description: 'Unlock advanced focus analytics and unlimited sessions with monthly billing',
    currency: 'USD',
    priceMicros: 9990000, // $9.99
    billingPeriod: 'P1M',
    freeTrialEnabled: false,
    freeTrialPeriod: null,
    gracePeriod: 'P3D',
  );

  static const SubscriptionProduct yearlyPro = SubscriptionProduct(
    productId: 'pro_yearly',
    basePlanId: 'base_yearly_v1',
    title: 'MindTrainer Pro Yearly',
    description: 'Unlock advanced focus analytics and unlimited sessions with yearly billing - Save 20%!',
    currency: 'USD',
    priceMicros: 95990000, // $95.99
    billingPeriod: 'P1Y',
    freeTrialEnabled: false,
    freeTrialPeriod: null,
    gracePeriod: 'P3D',
  );

  /// All available subscription products
  static const List<SubscriptionProduct> catalog = [
    monthlyPro,
    yearlyPro,
  ];

  /// Upgrade/downgrade rules
  static const List<UpgradeDowngradeRule> upgradeRules = [
    UpgradeDowngradeRule(
      fromProductId: 'pro_monthly',
      toProductId: 'pro_yearly',
      type: 'upgrade',
      prorationMode: 'immediate_with_time_proration',
      replacementMode: 'with_time_proration',
    ),
    UpgradeDowngradeRule(
      fromProductId: 'pro_yearly',
      toProductId: 'pro_monthly',
      type: 'downgrade',
      prorationMode: 'deferred',
      replacementMode: 'deferred',
    ),
  ];

  /// Get product by ID
  static SubscriptionProduct? getProduct(String productId) {
    for (final product in catalog) {
      if (product.productId == productId) {
        return product;
      }
    }
    return null;
  }

  /// Get all product IDs
  static List<String> get allProductIds => catalog.map((p) => p.productId).toList();

  /// Get monthly product
  static SubscriptionProduct get monthly => monthlyPro;

  /// Get yearly product  
  static SubscriptionProduct get yearly => yearlyPro;

  /// Get yearly savings compared to monthly
  static int get yearlySavingsPercent => yearlyPro.getSavingsPercent(monthlyPro) ?? 20;

  /// Get upgrade rule for product change
  static UpgradeDowngradeRule? getUpgradeRule(String fromProductId, String toProductId) {
    for (final rule in upgradeRules) {
      if (rule.fromProductId == fromProductId && rule.toProductId == toProductId) {
        return rule;
      }
    }
    return null;
  }

  /// Check if change from one product to another is an upgrade
  static bool isUpgrade(String fromProductId, String toProductId) {
    final rule = getUpgradeRule(fromProductId, toProductId);
    return rule?.isUpgrade ?? false;
  }

  /// Get formatted pricing comparison
  static String getPricingComparison() {
    final monthlyPrice = monthlyPro.formattedPrice;
    final yearlyPrice = yearlyPro.formattedPrice;
    final savings = yearlySavingsPercent;
    
    return 'Monthly: $monthlyPrice/month • Yearly: $yearlyPrice/year (save $savings%)';
  }

  /// Get product features description
  static List<String> getProFeatures() {
    return [
      'Advanced mood-focus correlation analysis',
      'Detailed tag performance insights',
      'Unlimited session history access', 
      'Export your focus data',
      'Premium meditation environments',
      'Priority customer support',
    ];
  }

  /// Get upgrade CTA text based on context
  static String getUpgradeCTA(String context) {
    switch (context) {
      case 'analytics_locked':
        return 'Unlock Pro Analytics';
      case 'export_limit':
        return 'Export All Data';
      case 'history_limit':
        return 'Access Full History';
      case 'premium_content':
        return 'Get Premium Access';
      default:
        return 'Upgrade to Pro';
    }
  }

  /// Validate catalog integrity
  static bool validateCatalog() {
    // Check product IDs are unique
    final productIds = catalog.map((p) => p.productId).toList();
    if (productIds.length != productIds.toSet().length) {
      return false;
    }

    // Check base plan IDs are unique
    final basePlanIds = catalog.map((p) => p.basePlanId).toList();
    if (basePlanIds.length != basePlanIds.toSet().length) {
      return false;
    }

    // Check prices are reasonable (between $1 and $1000)
    for (final product in catalog) {
      if (product.priceMicros < 1000000 || product.priceMicros > 1000000000) {
        return false;
      }
    }

    // Check upgrade rules reference valid products
    for (final rule in upgradeRules) {
      if (getProduct(rule.fromProductId) == null || getProduct(rule.toProductId) == null) {
        return false;
      }
    }

    return true;
  }
}

/// Helper extensions for billing integration
extension SubscriptionProductExtensions on SubscriptionProduct {
  /// Convert to Play Billing ProductDetails format (for interface compatibility)
  Map<String, dynamic> toPlayBillingFormat() {
    return {
      'productId': productId,
      'productType': 'subs',
      'title': title,
      'description': description,
      'subscriptionOfferDetails': [
        {
          'basePlanId': basePlanId,
          'pricingPhases': [
            {
              'priceAmountMicros': priceMicros,
              'priceCurrencyCode': currency,
              'billingPeriod': billingPeriod,
              'recurrenceMode': 1, // RECURRING
            }
          ],
        }
      ],
    };
  }

  /// Check if this is the recommended plan
  bool get isRecommended => productId == 'pro_yearly';

  /// Get display priority (lower = higher priority)
  int get displayPriority {
    switch (productId) {
      case 'pro_yearly':
        return 1; // Show first
      case 'pro_monthly':
        return 2;
      default:
        return 999;
    }
  }
}