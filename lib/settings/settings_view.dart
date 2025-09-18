/// Settings & About view for MindTrainer
/// 
/// Compact, scrollable screen with grouped sections:
/// Account & Pro, Data, Privacy, Charity & About, Diagnostics

import 'package:flutter/material.dart';
import 'settings_vm.dart';

class SettingsView extends StatefulWidget {
  final String? appVersion;
  
  const SettingsView({
    super.key,
    this.appVersion,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late SettingsVM vm;
  
  @override
  void initState() {
    super.initState();
    vm = SettingsVM.instance;
    vm.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountSection(),
              const SizedBox(height: 24),
              _buildDataSection(),
              const SizedBox(height: 24),
              _buildPrivacySection(),
              const SizedBox(height: 24),
              _buildCharitySection(),
              const SizedBox(height: 24),
              _buildDiagnosticsSection(),
              const SizedBox(height: 24),
              if (vm.status != null) _buildStatusStrip(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Account & Pro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pro status
            Row(
              children: [
                Text(
                  vm.proLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (vm.isPro && vm.productId != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      vm.productId!.contains('monthly') ? 'Monthly' : 'Yearly',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green[100],
                  ),
                ],
              ],
            ),
            
            if (vm.isPro) ...[
              const SizedBox(height: 8),
              const Text('Active', style: TextStyle(color: Colors.green)),
            ] else ...[
              const SizedBox(height: 16),
              
              // Purchase buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: vm.busy ? null : vm.buyMonthly,
                      child: vm.busy 
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Buy Monthly'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: vm.busy ? null : vm.buyYearly,
                      child: vm.busy 
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Buy Yearly'),
                    ),
                  ),
                ],
              ),
              
              // Price hints
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vm.monthlyPrice ?? '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vm.yearlyPrice ?? '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              
              if (vm.pricesStale) ...[
                const SizedBox(height: 8),
                Text(
                  '(pending…)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: vm.busy ? null : vm.restore,
                    child: const Text('Restore purchases'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: vm.busy ? null : vm.manage,
                    child: const Text('Manage subscription'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: vm.busy ? null : vm.exportSessions,
                    icon: vm.busy 
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                    label: const Text('Export sessions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: vm.busy ? null : vm.importSessions,
                    icon: vm.busy 
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                    label: const Text('Import sessions'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Text(
              'Exports are saved to Documents folder as CSV and JSON files.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.privacy_tip, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Privacy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Email updates & tips'),
              subtitle: const Text('Receive helpful meditation tips and app updates'),
              value: vm.emailOptIn,
              onChanged: vm.busy ? null : vm.toggleEmailOptIn,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCharitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Charity & About',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            const Text('MindTrainer is independent software.'),
            const SizedBox(height: 8),
            const Text('1/3 of proceeds support shelters.'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Text('Version: '),
                Text(
                  widget.appVersion ?? '1.0.0',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/achievements'),
                icon: const Icon(Icons.emoji_events, size: 18),
                label: const Text('View Achievements'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiagnosticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              title: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Diagnostics (Developer)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: vm.refreshDiagnostics,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (vm.diagLines.isNotEmpty) ...[
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: vm.diagLines.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          vm.diagLines[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'No diagnostic entries',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                Text(
                  'Diagnostics are local and cleared on app restart.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.status!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: vm.clearStatus,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}