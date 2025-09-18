import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// New text journal entry screen
class JournalNewTextScreen extends StatefulWidget {
  const JournalNewTextScreen({super.key});

  @override
  State<JournalNewTextScreen> createState() => _JournalNewTextScreenState();
}

class _JournalNewTextScreenState extends State<JournalNewTextScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final sp = await SharedPreferences.getInstance();
      final entries = sp.getStringList('journal_entries') ?? [];
      final timestamp = DateTime.now().toIso8601String();
      final entry = '$timestamp|text|${_controller.text.trim()}';
      entries.add(entry);
      await sp.setStringList('journal_entries', entries);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'New Text Entry',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: (16 * textScaler).toDouble(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What\'s on your mind?',
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (18 * textScaler).toDouble(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2436),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    color: const Color(0xFFF2F5F7),
                    fontSize: (16 * textScaler).toDouble(),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    hintStyle: TextStyle(color: Color(0xFFC7D1DD)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _saveEntry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Entry',
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
}