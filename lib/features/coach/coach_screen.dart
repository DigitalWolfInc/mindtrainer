import 'package:flutter/material.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Main coach chat screen
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi! I'm here to guide you through whatever you're facing. What's on your mind?",
      isFromCoach: true,
      timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isFromCoach: false,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate coach response
    Future.delayed(const Duration(milliseconds: 1500), () {
      final response = _generateCoachResponse(text);
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isFromCoach: true,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  String _generateCoachResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    
    if (lower.contains('stressed') || lower.contains('anxious')) {
      return "It sounds like you're feeling overwhelmed. Let's try a quick breathing exercise. Would you like me to guide you through a 1-minute calm breath technique?";
    } else if (lower.contains('sad') || lower.contains('down')) {
      return "I hear that you're going through a tough time. It's okay to feel this way. Sometimes it helps to name what you're feeling. Can you tell me more about what's bringing you down?";
    } else if (lower.contains('tired') || lower.contains('sleep')) {
      return "Fatigue can really affect how we feel. Are you having trouble sleeping, or do you feel mentally drained? I can suggest some wind-down techniques.";
    } else if (lower.contains('stuck')) {
      return "Feeling stuck is frustrating. Let's break this down into smaller pieces. What's one tiny step you could take right now, even if it's just 1% progress?";
    } else {
      return "I'm here to listen and help however I can. Can you tell me more about what you're experiencing right now?";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Coach',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
        actions: [
          IconButton(
            onPressed: () => R.go(context, '/sos'),
            icon: const Icon(Icons.sos, color: Colors.red),
            tooltip: 'SOS Help',
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], textScaler);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2436),
              border: Border(top: BorderSide(color: Color(0xA3274862), width: 1.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1826),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: const Color(0xFFF2F5F7),
                        fontSize: (16 * textScaler).toDouble(),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Color(0xFFC7D1DD)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, double textScaler) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isFromCoach) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromCoach ? const Color(0xFF0F2436) : const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(16),
                border: message.isFromCoach 
                    ? Border.all(width: 1.2, color: const Color(0xA3274862))
                    : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (15 * textScaler).toDouble(),
                ),
              ),
            ),
          ),
          if (!message.isFromCoach) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFC7D1DD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF0B1826), size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromCoach;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromCoach,
    required this.timestamp,
  });
}