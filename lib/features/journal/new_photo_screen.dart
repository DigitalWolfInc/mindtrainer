import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// Photo note journal entry screen
class JournalNewPhotoScreen extends StatefulWidget {
  const JournalNewPhotoScreen({super.key});

  @override
  State<JournalNewPhotoScreen> createState() => _JournalNewPhotoScreenState();
}

class _JournalNewPhotoScreenState extends State<JournalNewPhotoScreen> {
  final _captionController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPhotoPath;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String source) async {
    setState(() => _isLoading = true);
    
    // Simulate photo picking
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _selectedPhotoPath = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _isLoading = false;
    });
  }

  Future<void> _savePhotoNote() async {
    if (_selectedPhotoPath == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final sp = await SharedPreferences.getInstance();
      final entries = sp.getStringList('journal_entries') ?? [];
      final timestamp = DateTime.now().toIso8601String();
      final caption = _captionController.text.trim();
      final entry = '$timestamp|photo|$_selectedPhotoPath${caption.isNotEmpty ? '|$caption' : ''}';
      entries.add(entry);
      await sp.setStringList('journal_entries', entries);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo note saved locally')),
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
          'Photo Note',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
        actions: [
          if (_selectedPhotoPath != null)
            TextButton(
              onPressed: _isLoading ? null : _savePhotoNote,
              child: Text(
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
            if (_selectedPhotoPath == null) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined,
                      size: 64,
                      color: Color(0xFFC7D1DD),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add a photo to your journal',
                      style: TextStyle(
                        color: const Color(0xFFF2F5F7),
                        fontSize: (18 * textScaler).toDouble(),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : () => _pickPhoto('camera'),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        'Take Photo',
                        style: TextStyle(fontSize: (16 * textScaler).toDouble()),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickPhoto('gallery'),
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        'Choose from Gallery',
                        style: TextStyle(fontSize: (16 * textScaler).toDouble()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF2F5F7),
                        side: const BorderSide(color: Color(0xA3274862)),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Photo preview placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2436),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Color(0xFFC7D1DD),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Photo Preview',
                        style: TextStyle(color: Color(0xFFC7D1DD)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add a caption (optional)',
                style: TextStyle(
                  color: const Color(0xFFF2F5F7),
                  fontSize: (16 * textScaler).toDouble(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2436),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                ),
                child: TextField(
                  controller: _captionController,
                  maxLines: 3,
                  style: TextStyle(
                    color: const Color(0xFFF2F5F7),
                    fontSize: (16 * textScaler).toDouble(),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'What\'s in this photo?',
                    hintStyle: TextStyle(color: Color(0xFFC7D1DD)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isLoading ? null : _savePhotoNote,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Photo Note',
                  style: TextStyle(
                    fontSize: (16 * textScaler).toDouble(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}