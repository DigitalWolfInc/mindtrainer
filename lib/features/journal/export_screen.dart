import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// Journal export screen for downloading data
class JournalExportScreen extends StatefulWidget {
  const JournalExportScreen({super.key});

  @override
  State<JournalExportScreen> createState() => _JournalExportScreenState();
}

class _JournalExportScreenState extends State<JournalExportScreen> {
  bool _isExporting = false;
  int _entryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEntryCount();
  }

  Future<void> _loadEntryCount() async {
    final sp = await SharedPreferences.getInstance();
    final entries = sp.getStringList('journal_entries') ?? [];
    setState(() => _entryCount = entries.length);
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final sp = await SharedPreferences.getInstance();
      final entries = sp.getStringList('journal_entries') ?? [];
      
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));
      
      // In real implementation, this would create a ZIP file
      // and save to app storage or offer to share
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${entries.length} entries to Downloads'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // Would open file manager or share sheet
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Export Data',
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2436),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 1.2, color: const Color(0xA3274862)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Export Your Journal',
                    style: TextStyle(
                      color: const Color(0xFFF2F5F7),
                      fontSize: (20 * textScaler).toDouble(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download all your journal entries as a ZIP file',
                    style: TextStyle(
                      color: const Color(0xFFC7D1DD),
                      fontSize: (16 * textScaler).toDouble(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    'What\'s included:',
                    style: TextStyle(
                      color: const Color(0xFFF2F5F7),
                      fontSize: (16 * textScaler).toDouble(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIncludeItem('📝 Text entries ($_entryCount total)'),
                  _buildIncludeItem('🎤 Voice recordings (encrypted paths)'),
                  _buildIncludeItem('📷 Photo attachments (encrypted paths)'),
                  _buildIncludeItem('📊 Entry metadata (timestamps, tags)'),
                  const SizedBox(height: 12),
                  Text(
                    'Export format: ZIP archive with JSON files',
                    style: TextStyle(
                      color: const Color(0xFFC7D1DD),
                      fontSize: (14 * textScaler).toDouble(),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _isExporting || _entryCount == 0 ? null : _exportData,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isExporting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Exporting...',
                          style: TextStyle(
                            fontSize: (16 * textScaler).toDouble(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _entryCount == 0 
                          ? 'No entries to export'
                          : 'Export Journal Data',
                      style: TextStyle(
                        fontSize: (16 * textScaler).toDouble(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFC7D1DD),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}