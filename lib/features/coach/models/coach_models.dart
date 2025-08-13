/// Coach provider interface for pluggable implementations
abstract class CoachProvider {
  /// Get reply to user message with optional triage context
  Future<CoachReply> reply(String userText, {String? triageTag});
}

/// Response from coach with optional tool suggestion
class CoachReply {
  final String text;
  final String? suggestedToolId;
  
  const CoachReply({
    required this.text,
    this.suggestedToolId,
  });
  
  /// Reply with tool suggestion
  factory CoachReply.withTool({
    required String text,
    required String toolId,
  }) {
    return CoachReply(
      text: text,
      suggestedToolId: toolId,
    );
  }
  
  /// Reply without tool suggestion
  factory CoachReply.textOnly(String text) {
    return CoachReply(text: text);
  }
  
  @override
  String toString() => 'CoachReply(text: "$text", toolId: $suggestedToolId)';
}

/// Triage tags for quick coach access
enum TriageTag {
  wired('wired'),
  stuck('stuck'), 
  low('low'),
  cantSleep('cant_sleep');
  
  const TriageTag(this.id);
  final String id;
}

/// Coach conversation state
class CoachConversation {
  final List<CoachMessage> messages;
  final String? suggestedToolId;
  
  const CoachConversation({
    required this.messages,
    this.suggestedToolId,
  });
  
  /// Add message to conversation
  CoachConversation addMessage(CoachMessage message) {
    return CoachConversation(
      messages: [...messages, message],
      suggestedToolId: suggestedToolId,
    );
  }
  
  /// Update with tool suggestion
  CoachConversation withToolSuggestion(String toolId) {
    return CoachConversation(
      messages: messages,
      suggestedToolId: toolId,
    );
  }
}

/// Individual message in coach conversation
class CoachMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  CoachMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// User message
  factory CoachMessage.user(String text) {
    return CoachMessage(text: text, isUser: true);
  }
  
  /// Coach message
  factory CoachMessage.coach(String text) {
    return CoachMessage(text: text, isUser: false);
  }
}