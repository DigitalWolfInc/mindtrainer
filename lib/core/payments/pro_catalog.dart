/// Pro Subscription Catalog for MindTrainer
/// 
/// Manages subscription plan definitions, pricing, and display information.
/// Provides UI-ready data structures for subscription plan presentation.

import 'play_billing_adapter.dart';
import 'pro_status.dart';

/// Pro subscription plan definition
class ProPlan {
  /// Unique product ID for Play Billing
  final String productId;
  
  /// Display name for UI
  final String displayName;
  
  /// Short description of the plan
  final String description;
  
  /// Subscription duration period
  final ProPlanPeriod period;
  
  /// Base price in USD (before Play Billing formatting)
  final double basePriceUsd;
  
  /// Whether this plan offers the best value
  final bool bestValue;
  
  /// Features included in this plan
  final List<String> features;
  
  /// Play Billing product details (populated when available)
  final BillingProduct? billingProduct;
  
  const ProPlan({
    required this.productId,
    required this.displayName,
    required this.description,
    required this.period,
    required this.basePriceUsd,
    this.bestValue = false,
    this.features = const [],
    this.billingProduct,
  });
  
  /// Create a copy with updated billing product
  ProPlan withBillingProduct(BillingProduct product) {
    return ProPlan(
      productId: productId,
      displayName: displayName,
      description: description,
      period: period,
      basePriceUsd: basePriceUsd,
      bestValue: bestValue,
      features: features,
      billingProduct: product,
    );
  }
  
  /// Get formatted price from billing product or fallback to base price
  String get formattedPrice {
    if (billingProduct != null) {
      return billingProduct!.price;
    }
    return '\$${basePriceUsd.toStringAsFixed(2)}';
  }
  
  /// Get monthly equivalent price for comparison
  double get monthlyEquivalentPrice {
    switch (period) {
      case ProPlanPeriod.monthly:
        return basePriceUsd;
      case ProPlanPeriod.yearly:
        return basePriceUsd / 12;
    }
  }
  
  /// Calculate savings compared to monthly plan
  double calculateSavings(double monthlyPrice) {
    if (period == ProPlanPeriod.monthly) return 0.0;
    final yearlyAsMonthly = monthlyPrice * 12;
    return yearlyAsMonthly - basePriceUsd;
  }
  
  /// Get savings percentage compared to monthly
  int getSavingsPercentage(double monthlyPrice) {
    if (period == ProPlanPeriod.monthly) return 0;
    final yearlyAsMonthly = monthlyPrice * 12;
    return (((yearlyAsMonthly - basePriceUsd) / yearlyAsMonthly) * 100).round();
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProPlan &&
          runtimeType == other.runtimeType &&
          productId == other.productId;
  
  @override
  int get hashCode => productId.hashCode;
  
  @override
  String toString() => 'ProPlan(id: $productId, price: $formattedPrice, period: $period)';
}

/// Subscription period duration
enum ProPlanPeriod {
  /// Monthly subscription
  monthly,
  /// Yearly subscription  
  yearly,
}

extension ProPlanPeriodExtension on ProPlanPeriod {
  /// Human-readable period name
  String get displayName {
    switch (this) {
      case ProPlanPeriod.monthly:
        return 'Monthly';
      case ProPlanPeriod.yearly:
        return 'Yearly';
    }
  }
  
  /// Period suffix for display (e.g., "/month")
  String get suffix {
    switch (this) {
      case ProPlanPeriod.monthly:
        return '/month';
      case ProPlanPeriod.yearly:
        return '/year';
    }
  }
}

/// Catalog of available Pro subscription plans
class ProCatalog {
  final List<ProPlan> _plans;
  
  const ProCatalog(this._plans);
  
  /// Get all available plans
  List<ProPlan> get plans => List.unmodifiable(_plans);
  
  /// Get plans by period
  List<ProPlan> getPlansByPeriod(ProPlanPeriod period) {
    return _plans.where((plan) => plan.period == period).toList();
  }
  
  /// Find plan by product ID
  ProPlan? findPlanById(String productId) {
    try {
      return _plans.firstWhere((plan) => plan.productId == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get best value plan (marked as bestValue = true)
  ProPlan? get bestValuePlan {
    try {
      return _plans.firstWhere((plan) => plan.bestValue);
    } catch (e) {
      return null;
    }
  }
  
  /// Get monthly plan (for price comparison)
  ProPlan? get monthlyPlan {
    try {
      return _plans.firstWhere((plan) => plan.period == ProPlanPeriod.monthly);
    } catch (e) {
      return null;
    }
  }
  
  /// Get yearly plan (for price comparison)
  ProPlan? get yearlyPlan {
    try {
      return _plans.firstWhere((plan) => plan.period == ProPlanPeriod.yearly);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all product IDs for Play Billing queries
  List<String> get productIds {
    return _plans.map((plan) => plan.productId).toList();
  }
  
  /// Create catalog with updated billing products
  ProCatalog withBillingProducts(List<BillingProduct> billingProducts) {
    final Map<String, BillingProduct> productMap = {
      for (final product in billingProducts) product.productId: product
    };
    
    final updatedPlans = _plans.map((plan) {
      final billingProduct = productMap[plan.productId];
      return billingProduct != null 
          ? plan.withBillingProduct(billingProduct)
          : plan;
    }).toList();
    
    return ProCatalog(updatedPlans);
  }
  
  /// Get plans sorted by best value first, then by price
  List<ProPlan> get plansByValue {
    final sorted = List<ProPlan>.from(_plans);
    sorted.sort((a, b) {
      // Best value first
      if (a.bestValue && !b.bestValue) return -1;
      if (!a.bestValue && b.bestValue) return 1;
      
      // Then by monthly equivalent price (lower first)
      return a.monthlyEquivalentPrice.compareTo(b.monthlyEquivalentPrice);
    });
    return sorted;
  }
}

/// Factory for creating Pro catalog with default plans
class ProCatalogFactory {
  /// Create default Pro catalog with standard monthly/yearly plans
  static ProCatalog createDefault() {
    final plans = [
      const ProPlan(
        productId: 'pro_monthly',
        displayName: 'Pro Monthly',
        description: 'All Pro features with monthly billing',
        period: ProPlanPeriod.monthly,
        basePriceUsd: 9.99,
        features: [
          'Unlimited focus sessions',
          'Advanced insights and analytics',
          'Data export and backup',
          'AI coaching conversations',
          'Premium themes',
          'Ad-free experience',
        ],
      ),
      const ProPlan(
        productId: 'pro_yearly',
        displayName: 'Pro Yearly',
        description: 'All Pro features with yearly billing - best value!',
        period: ProPlanPeriod.yearly,
        basePriceUsd: 99.99,
        bestValue: true,
        features: [
          'Unlimited focus sessions',
          'Advanced insights and analytics', 
          'Data export and backup',
          'AI coaching conversations',
          'Premium themes',
          'Ad-free experience',
          '2 months free compared to monthly',
        ],
      ),
    ];
    
    return ProCatalog(plans);
  }
  
  /// Create catalog with custom plans
  static ProCatalog create(List<ProPlan> plans) {
    return ProCatalog(plans);
  }
}

/// UI helper for formatting subscription plans
class ProPlanFormatter {
  /// Format plan price with period
  static String formatPlanPrice(ProPlan plan) {
    return '${plan.formattedPrice}${plan.period.suffix}';
  }
  
  /// Format savings message for yearly plans
  static String? formatSavingsMessage(ProPlan plan, ProCatalog catalog) {
    if (plan.period != ProPlanPeriod.yearly) return null;
    
    final monthlyPlan = catalog.monthlyPlan;
    if (monthlyPlan == null) return null;
    
    final savingsPercent = plan.getSavingsPercentage(monthlyPlan.basePriceUsd);
    if (savingsPercent <= 0) return null;
    
    return 'Save $savingsPercent% vs monthly';
  }
  
  /// Format monthly equivalent for yearly plans
  static String formatMonthlyEquivalent(ProPlan plan) {
    if (plan.period == ProPlanPeriod.monthly) {
      return 'Billed monthly';
    }
    
    final monthlyPrice = plan.monthlyEquivalentPrice;
    return 'Only \$${monthlyPrice.toStringAsFixed(2)}/month';
  }
  
  /// Format plan comparison summary
  static String formatComparisonSummary(ProPlan plan, ProCatalog catalog) {
    final savings = formatSavingsMessage(plan, catalog);
    final equivalent = formatMonthlyEquivalent(plan);
    
    if (savings != null) {
      return '$equivalent • $savings';
    }
    return equivalent;
  }
}