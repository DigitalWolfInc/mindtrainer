import 'package:flutter/material.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// Private journal with Pro soft-lock
class JournalPrivateScreen extends StatelessWidget {
  const JournalPrivateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Private Journal',
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
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2436),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Private Sub-Journal',
                          style: TextStyle(
                            color: const Color(0xFFF2F5F7),
                            fontSize: (24 * textScaler).toDouble(),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (12 * textScaler).toDouble(),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Extra secure space for your most private thoughts',
                          style: TextStyle(
                            color: const Color(0xFFC7D1DD),
                            fontSize: (16 * textScaler).toDouble(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2436),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Private Journal Features',
                          style: TextStyle(
                            color: const Color(0xFFF2F5F7),
                            fontSize: (18 * textScaler).toDouble(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem('🔒 Extra encryption layer'),
                        _buildFeatureItem('🔑 Biometric access only'),
                        _buildFeatureItem('👁️ Hidden from main journal'),
                        _buildFeatureItem('🗂️ Separate export file'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // Navigate to paywall or Pro features
                Navigator.pushNamed(context, '/paywall');
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontSize: (16 * textScaler).toDouble(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Show preview with limited functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preview: Private journal would appear here'),
                  ),
                );
              },
              child: Text(
                'Preview (Limited)',
                style: TextStyle(
                  color: const Color(0xFFC7D1DD),
                  fontSize: (14 * textScaler).toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFC7D1DD),
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}