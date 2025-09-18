import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// SOS crisis support screen
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'SOS Crisis Support',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If you\'re in immediate danger, please call emergency services (911) right away.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: (16 * textScaler).toDouble(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Crisis Support Resources',
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (20 * textScaler).toDouble(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildContactCard(
                    context,
                    title: '988 Suicide & Crisis Lifeline',
                    subtitle: '24/7 free and confidential support',
                    phone: '988',
                    description: 'Talk to someone now if you\'re having thoughts of suicide or in emotional distress.',
                    textScaler: textScaler,
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    title: 'Crisis Text Line',
                    subtitle: 'Text HOME to 741741',
                    phone: '741741',
                    description: 'Free 24/7 crisis support via text message.',
                    textScaler: textScaler,
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    title: 'SAMHSA National Helpline',
                    subtitle: '1-800-662-4357 (HELP)',
                    phone: '18006624357',
                    description: 'Treatment referral and information service for mental health and substance abuse.',
                    textScaler: textScaler,
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    title: 'Emergency Services',
                    subtitle: '911',
                    phone: '911',
                    description: 'Call immediately if you or someone else is in immediate danger.',
                    textScaler: textScaler,
                    isEmergency: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2436),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 1.2, color: const Color(0xA3274862)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are not alone',
                    style: TextStyle(
                      color: const Color(0xFFF2F5F7),
                      fontSize: (16 * textScaler).toDouble(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These feelings are temporary. Help is available, and you deserve support.',
                    style: TextStyle(
                      color: const Color(0xFFC7D1DD),
                      fontSize: (14 * textScaler).toDouble(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String phone,
    required String description,
    required double textScaler,
    bool isEmergency = false,
  }) {
    return A11y.ensureMinTouchTarget(
      Container(
        decoration: BoxDecoration(
          color: isEmergency ? Colors.red.withOpacity(0.1) : const Color(0xFF0F2436),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1.2, 
            color: isEmergency ? Colors.red.withOpacity(0.3) : const Color(0xA3274862),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _makeCall(context, phone),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isEmergency 
                          ? Colors.red.withOpacity(0.2)
                          : const Color(0xFF6366F1).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone,
                      color: isEmergency ? Colors.red : const Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: const Color(0xFFF2F5F7),
                            fontSize: (16 * textScaler).toDouble(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isEmergency ? Colors.red : const Color(0xFF6366F1),
                            fontSize: (14 * textScaler).toDouble(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: const Color(0xFFC7D1DD),
                            fontSize: (13 * textScaler).toDouble(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isEmergency ? Colors.red : const Color(0xFFC7D1DD),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _makeCall(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2436),
        title: const Text(
          'Call for Help',
          style: TextStyle(color: Color(0xFFF2F5F7)),
        ),
        content: Text(
          'This will open your phone app to call $phoneNumber. Continue?',
          style: const TextStyle(color: Color(0xFFC7D1DD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // In real implementation, would use url_launcher to make the call
              // For now, just show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Would call $phoneNumber')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }
}