import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/mtds/mtds_scaffold.dart';
import '../a11y/a11y.dart';

/// Account management screen with security and data options
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _appLockEnabled = true;
  bool _cloudBackupEnabled = false;

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Account',
          style: TextStyle(
            fontSize: 20 * textScaler,
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Authentication section
          _buildSectionHeader(context, 'Authentication', textScaler),
          const SizedBox(height: 8),
          _buildListTile(
            context,
            title: 'Passkey',
            subtitle: 'Enabled',
            icon: Icons.fingerprint,
            textScaler: textScaler,
          ),
          const SizedBox(height: 16),
          
          // Security section
          _buildSectionHeader(context, 'Security', textScaler),
          const SizedBox(height: 8),
          _buildSwitchTile(
            context,
            title: 'App-lock (biometric/PIN)',
            subtitle: 'Require authentication to open app',
            value: _appLockEnabled,
            onChanged: (value) {
              setState(() {
                _appLockEnabled = value;
              });
            },
            textScaler: textScaler,
          ),
          const SizedBox(height: 16),
          
          // Data section
          _buildSectionHeader(context, 'Data', textScaler),
          const SizedBox(height: 8),
          _buildSwitchTile(
            context,
            title: 'Cloud backup',
            subtitle: 'Sync data across devices (encrypted)',
            value: _cloudBackupEnabled,
            onChanged: (value) {
              setState(() {
                _cloudBackupEnabled = value;
              });
            },
            textScaler: textScaler,
          ),
          const SizedBox(height: 8),
          _buildListTile(
            context,
            title: 'Export data (ZIP)',
            subtitle: 'Download all your data',
            icon: Icons.download_outlined,
            onTap: _exportData,
            textScaler: textScaler,
          ),
          const SizedBox(height: 32),
          
          // Danger zone
          _buildSectionHeader(context, 'Danger Zone', textScaler),
          const SizedBox(height: 8),
          _buildListTile(
            context,
            title: 'Delete account',
            subtitle: 'Permanently delete account and all data',
            icon: Icons.delete_outline,
            onTap: _showDeleteConfirmation,
            textScaler: textScaler,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, double textScaler) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18 * textScaler,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF2F5F7),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required double textScaler,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final surface = const Color(0xFF0F2436);
    final textPrimary = isDestructive ? Colors.red : const Color(0xFFF2F5F7);
    final textSecondary = isDestructive ? Colors.red.withOpacity(0.7) : const Color(0xFFC7D1DD);
    
    return A11y.ensureMinTouchTarget(
      Card(
        color: surface,
        child: ListTile(
          leading: Icon(icon, color: textPrimary),
          title: Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16 * textScaler,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14 * textScaler,
            ),
          ),
          onTap: onTap,
          trailing: onTap != null 
              ? Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary)
              : null,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double textScaler,
  }) {
    const surface = Color(0xFF0F2436);
    const textPrimary = Color(0xFFF2F5F7);
    const textSecondary = Color(0xFFC7D1DD);
    
    return A11y.ensureMinTouchTarget(
      Card(
        color: surface,
        child: SwitchListTile(
          secondary: Icon(Icons.security, color: textPrimary),
          title: Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16 * textScaler,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14 * textScaler,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('mt_signed_in_v1', false);
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }
}