import 'package:flutter/material.dart';
import 'paywall_vm.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  late PaywallVM _vm;

  @override
  void initState() {
    super.initState();
    _vm = PaywallVM.instance;
    _vm.initialize();
    _vm.addListener(_onVMChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVMChanged);
    super.dispose();
  }

  void _onVMChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindTrainer Pro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: 16),
            const Text(
              'MindTrainer Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Benefits list
            const _BenefitsList(),
            
            const SizedBox(height: 32),
            
            // Pricing row
            _PricingRow(vm: _vm),
            
            const SizedBox(height: 16),
            
            // Status strip
            _StatusStrip(vm: _vm),
            
            const Spacer(),
            
            // Footer actions
            _FooterActions(vm: _vm),
            
            const SizedBox(height: 8),
            
            // Tiny caption
            const Text(
              'Subscriptions handled by Google Play.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      'Unlimited insights & history',
      'Advanced Coach',
      'Priority features',
      'Support development — 1/3 supports shelters',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: benefits.map((benefit) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                benefit,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final PaywallVM vm;

  const _PricingRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PricingButton(
            label: 'Monthly',
            price: vm.monthlyPrice ?? '—',
            isStale: vm.pricesStale,
            isEnabled: !vm.isBusy,
            onPressed: vm.buyMonthly,
            semanticsLabel: 'Buy monthly',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PricingButton(
            label: 'Yearly',
            price: vm.yearlyPrice ?? '—',
            isStale: vm.pricesStale,
            isEnabled: !vm.isBusy,
            onPressed: vm.buyYearly,
            semanticsLabel: 'Buy yearly',
            badge: 'Save 20%',
          ),
        ),
      ],
    );
  }
}

class _PricingButton extends StatelessWidget {
  final String label;
  final String price;
  final bool isStale;
  final bool isEnabled;
  final VoidCallback onPressed;
  final String semanticsLabel;
  final String? badge;

  const _PricingButton({
    required this.label,
    required this.price,
    required this.isStale,
    required this.isEnabled,
    required this.onPressed,
    required this.semanticsLabel,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 80,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Semantics(
              label: semanticsLabel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (isStale && price != '—') ...[
                    const SizedBox(height: 2),
                    const Text(
                      '(price pending…)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final PaywallVM vm;

  const _StatusStrip({required this.vm});

  @override
  Widget build(BuildContext context) {
    Widget content;
    Color? backgroundColor;
    Color? textColor;

    if (vm.isPro) {
      content = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('You\'re Pro. Thank you!'),
        ],
      );
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
    } else if (vm.offline) {
      content = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — you can still use MindTrainer. Try purchases when back online.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
    } else if (vm.error != null) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.error!,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: vm.clearError,
            child: const Text('Dismiss'),
          ),
        ],
      );
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
    } else if (vm.isBusy) {
      content = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Processing...'),
        ],
      );
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
    } else {
      content = const SizedBox.shrink();
    }

    if (content is SizedBox) {
      return const SizedBox(height: 48); // Maintain consistent spacing
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor?.withOpacity(0.3) ?? Colors.transparent),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: textColor, fontSize: 14),
        child: content,
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final PaywallVM vm;

  const _FooterActions({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Semantics(
          label: 'Restore',
          child: TextButton(
            onPressed: vm.isBusy ? null : vm.restore,
            child: const Text('Restore purchases'),
          ),
        ),
        Semantics(
          label: 'Manage',
          child: TextButton(
            onPressed: vm.isBusy ? null : vm.manage,
            child: const Text('Manage subscription'),
          ),
        ),
      ],
    );
  }
}