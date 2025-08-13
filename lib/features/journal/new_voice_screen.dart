import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// Voice note journal entry screen  
class JournalNewVoiceScreen extends StatefulWidget {
  const JournalNewVoiceScreen({super.key});

  @override
  State<JournalNewVoiceScreen> createState() => _JournalNewVoiceScreenState();
}

class _JournalNewVoiceScreenState extends State<JournalNewVoiceScreen> {
  bool _isRecording = false;
  bool _isLoading = false;
  int _recordingSeconds = 0;

  Future<void> _toggleRecording() async {
    setState(() => _isRecording = !_isRecording);
    
    if (_isRecording) {
      // Start recording simulation
      _startRecordingTimer();
    } else {
      // Stop recording and save
      await _saveVoiceNote();
    }
  }

  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() => _recordingSeconds++);
        return true;
      }
      return false;
    });
  }

  Future<void> _saveVoiceNote() async {
    setState(() => _isLoading = true);
    
    try {
      final sp = await SharedPreferences.getInstance();
      final entries = sp.getStringList('journal_entries') ?? [];
      final timestamp = DateTime.now().toIso8601String();
      final entry = '$timestamp|voice|Voice note (${_recordingSeconds}s)';
      entries.add(entry);
      await sp.setStringList('journal_entries', entries);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note saved locally')),
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

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Voice Note',
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Voice Note',
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (24 * textScaler).toDouble(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : const Color(0xFF6366F1),
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(60),
                  onTap: _isLoading ? null : _toggleRecording,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isRecording ? _formatTime(_recordingSeconds) : '00:00',
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (32 * textScaler).toDouble(),
                fontWeight: FontWeight.w300,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording 
                  ? 'Tap to stop recording'
                  : 'Tap to start recording',
              style: TextStyle(
                color: const Color(0xFFC7D1DD),
                fontSize: (16 * textScaler).toDouble(),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}