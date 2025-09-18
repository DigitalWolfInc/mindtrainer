import 'package:flutter/material.dart';

class SessionMetadata {
  final List<String> tags;
  final String note;

  const SessionMetadata({
    required this.tags,
    required this.note,
  });
}

class SessionCompletionDialog extends StatefulWidget {
  const SessionCompletionDialog({super.key});

  @override
  State<SessionCompletionDialog> createState() => _SessionCompletionDialogState();
}

class _SessionCompletionDialogState extends State<SessionCompletionDialog> {
  final _tagsController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _tagsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String tagsText) {
    if (tagsText.trim().isEmpty) return [];
    
    return tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Completed!'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add optional tags and notes to your session:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'focus, deep-work, study...',
                helperText: 'Comma-separated tags',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'What did you work on?',
                helperText: 'Optional session notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              const SessionMetadata(tags: [], note: ''),
            );
          },
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: () {
            final tags = _parseTags(_tagsController.text);
            final note = _noteController.text.trim();
            
            Navigator.of(context).pop(
              SessionMetadata(tags: tags, note: note),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}