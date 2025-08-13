/// Pro Catalog Screen with Accessibility Support
/// 
/// Displays available Pro subscription plans with full accessibility features.

import 'package:flutter/material.dart';
import '../../../a11y/a11y.dart';
import '../../../i18n/i18n.dart';
import '../../../core/payments/pro_catalog.dart';
import '../../../payments/billing_service.dart';
import '../../../payments/models.dart';

class ProCatalogScreen extends StatefulWidget {
  const ProCatalogScreen({super.key});
  
  @override
  State<ProCatalogScreen> createState() => _ProCatalogScreenState();
}

class _ProCatalogScreenState extends State<ProCatalogScreen> with A11ySemantics {
  late final ProCatalog _catalog;
  late final BillingService _billingService;
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _catalog = ProCatalogFactory.createDefault();
    _billingService = BillingService.instance;
    
    // Listen for billing service changes
    _billingService.addListener(_onBillingStateChanged);
    
    // Ensure connection is established
    _ensureBillingConnected();
  }

  @override
  void dispose() {
    _billingService.removeListener(_onBillingStateChanged);
    super.dispose();
  }

  void _onBillingStateChanged() {
    if (mounted) {
      setState(() {
        _isLoading = _billingService.isLoading;
        _error = _billingService.lastError;
      });
    }
  }

  Future<void> _ensureBillingConnected() async {
    if (!_billingService.isConnected) {
      setState(() => _isLoading = true);
      await _billingService.connect();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: header(strings.proTitle, Text(strings.proTitle)),
        leading: A11y.accessibleIconButton(
          icon: Icons.arrow_back,
          label: strings.a11yBackButton,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Restore purchases button
          A11y.accessibleIconButton(
            icon: Icons.restore,
            label: 'Restore purchases',
            onPressed: _isLoading ? null : _restorePurchases,
          ),
        ],
      ),
      body: Stack(
        children: [
          FocusTraversalGroup(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_error != null) ...[
                    _buildErrorCard(context),
                    const SizedBox(height: 16),
                  ],
                  
                  // Current Pro status
                  if (_billingService.isProActive) ...[
                    _buildCurrentSubscriptionCard(context),
                    const SizedBox(height: 24),
                  ],
                  
                  // Header section
                  A11y.focusTraversalOrder(
                    order: 1.0,
                    child: header(
                      strings.proSubtitle,
                      Text(
                        strings.proSubtitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 24) * textScaler,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pro plans list
                  ...._buildPlanCards(context),
                  
                  const SizedBox(height: 32),
                  
                  // Features section
                  A11y.focusTraversalOrder(
                    order: 10.0,
                    child: _buildFeaturesSection(context),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Support info
                  A11y.focusTraversalOrder(
                    order: 11.0,
                    child: _buildSupportInfo(context),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildPlanCards(BuildContext context) {
    final strings = context.safeStrings;
    final plans = _catalog.plansByValue;
    final cards = <Widget>[];
    
    for (int i = 0; i < plans.length; i++) {
      final plan = plans[i];
      final order = 2.0 + i;
      
      cards.add(
        A11y.focusTraversalOrder(
          order: order,
          child: _buildPlanCard(context, plan),
        ),
      );
      
      if (i < plans.length - 1) {
        cards.add(const SizedBox(height: 16));
      }
    }
    
    return cards;
  }
  
  Widget _buildPlanCard(BuildContext context, ProPlan plan) {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    final theme = Theme.of(context);
    
    final isPrimaryPlan = plan.bestValue;
    final cardColor = isPrimaryPlan ? theme.primaryColor.withOpacity(0.1) : null;
    final borderColor = isPrimaryPlan ? theme.primaryColor : theme.dividerColor;
    
    final priceText = ProPlanFormatter.formatPlanPrice(plan);
    final comparisonText = ProPlanFormatter.formatComparisonSummary(plan, _catalog);
    
    return A11y.ensureMinTouchTarget(
      Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: isPrimaryPlan ? 2 : 1),
        ),
        child: Semantics(
          label: '${plan.displayName} - $priceText',
          hint: 'Subscription plan with ${plan.features.length} features. $comparisonText',
          button: true,
          child: InkWell(
            onTap: () => _selectPlan(plan),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name and badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 20) * textScaler,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      if (plan.bestValue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Semantics(
                            label: strings.proBestValue,
                            child: Text(
                              strings.proBestValue,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12 * textScaler,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    priceText,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: (theme.textTheme.headlineLarge?.fontSize ?? 32) * textScaler,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Comparison text
                  Text(
                    comparisonText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaler,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    plan.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaler,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Features list
                  ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                          semanticLabel: 'Included',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaler,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeaturesSection(BuildContext context) {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(
              'Why Choose Pro?',
              Text(
                'Why Choose Pro?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 20) * textScaler,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureHighlight(
              context,
              Icons.timeline,
              'Unlimited Sessions',
              'No daily limits on focus sessions',
            ),
            
            _buildFeatureHighlight(
              context,
              Icons.analytics,
              'Advanced Analytics',
              'Deep insights into your focus patterns',
            ),
            
            _buildFeatureHighlight(
              context,
              Icons.backup,
              'Data Export',
              'Export your progress and insights',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureHighlight(BuildContext context, IconData icon, String title, String description) {
    final textScaler = A11y.getClampedTextScale(context);
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.primaryColor,
            size: 24,
            semanticLabel: title,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * textScaler,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaler,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportInfo(BuildContext context) {
    final strings = context.safeStrings;
    final textScaler = A11y.getClampedTextScale(context);
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.support_agent,
              color: theme.primaryColor,
              size: 32,
              semanticLabel: 'Support',
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Questions? We\'re here to help!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * textScaler,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Cancel anytime. All purchases are secure and encrypted.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaler,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _selectPlan(ProPlan plan) async {
    // Skip if already Pro for the same plan
    if (_billingService.isProActive) {
      final currentProductId = _billingService.proState.activeProductId;
      final legacyCurrentId = BillingCatalogIntegration.mapFromLegacyProductId(plan.productId);
      if (currentProductId == legacyCurrentId) {
        A11y.announce(context, 'You already have ${plan.displayName}');
        return;
      }
    }
    
    // Announce selection to screen readers
    A11y.announce(context, 'Selected ${plan.displayName} plan');
    
    // Convert legacy product ID to new format
    final actualProductId = BillingCatalogIntegration.mapFromLegacyProductId(plan.productId);
    
    // Attempt purchase
    final success = await _billingService.purchaseProduct(actualProductId);
    
    if (success) {
      A11y.announce(context, 'Purchase initiated for ${plan.displayName}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase initiated for ${plan.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_billingService.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${_billingService.lastError}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // If success is false but no error, user likely canceled
  }

  Future<void> _restorePurchases() async {
    A11y.announce(context, 'Restoring purchases...');
    await _billingService.restorePurchases();
    
    if (_billingService.isProActive) {
      A11y.announce(context, 'Purchases restored successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_billingService.lastError == null) {
      A11y.announce(context, 'No purchases found to restore');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No purchases found to restore'),
        ),
      );
    }
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _error = null);
                _billingService.connect();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionInfo = _billingService.getSubscriptionInfo();
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  if (subscriptionInfo.displayName != null)
                    Text(
                      subscriptionInfo.displayName!,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}