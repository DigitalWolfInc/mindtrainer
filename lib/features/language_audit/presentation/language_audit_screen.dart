import 'package:flutter/material.dart';
import '../domain/language_validator.dart';

class LanguageAuditScreen extends StatefulWidget {
  const LanguageAuditScreen({super.key});

  @override
  State<LanguageAuditScreen> createState() => _LanguageAuditScreenState();
}

class _LanguageAuditScreenState extends State<LanguageAuditScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _validationResult;
  bool _containsMedicalClaims = false;

  void _validateText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _validationResult = null;
        _containsMedicalClaims = false;
      });
      return;
    }

    setState(() {
      _validationResult = LanguageValidator.validateText(text);
      _containsMedicalClaims = LanguageValidator.containsMedicalClaims(text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Safety Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check if text uses trauma-safe, supportive language:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter text to check for trauma-safe language...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _validateText(),
            ),
            const SizedBox(height: 16),
            if (_validationResult != null)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationResult!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_containsMedicalClaims)
              Card(
                color: Colors.red[50],
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: Text contains medical claims. Apps should not provide medical treatment.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_validationResult == null && !_containsMedicalClaims && _textController.text.isNotEmpty)
              Card(
                color: Colors.green[50],
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Text looks good! Uses supportive, trauma-safe language.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Safe Phrase Examples:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: LanguageValidator.safePhrases.entries
                    .map((entry) => Card(
                          child: ListTile(
                            title: Text(
                              'Instead of: "${entry.key}"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text(
                              'Try: "${entry.value}"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}