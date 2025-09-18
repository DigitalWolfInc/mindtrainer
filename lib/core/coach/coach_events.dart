/// Coach Event System for MindTrainer
/// 
/// Provides value objects and event emission for coaching sessions that integrate
/// with the existing export pipeline, insights system, and tag/filter infrastructure.
/// 
/// **UI Integration Pattern:**
/// ```dart
/// // 1. Start a coach conversation
/// final coach = ConversationalCoach(
///   profile: appProfileSource,
///   history: appHistorySource, 
///   journal: appJournalSink,
///   eventSink: (event) => coachEventRepository.save(event),
/// );
///
/// // 2. Pipe every reply into next(userReply: ...)
/// final step = coach.next(userReply: userInput);
/// // CoachEvent is automatically emitted to eventSink
///
/// // 3. Persist emitted events with the export layer
/// await exportService.exportCoachEvents('coach_data_2024.json');
///
/// // 4. Read summaries for dashboards
/// final summaries = summarizeCoachActivity(coachEvents);
/// final correlation = correlationPlansVsFocusMinutes(summaries, moodFocusData);
/// ```

/// Outcome achieved during coaching session phase transitions
enum CoachOutcome { 
  /// User reached emotional stability (stabilize phase complete)
  stabilized, 
  /// User opened up and shared meaningful content (open phase complete)
  opened, 
  /// User received and processed cognitive reframing (reframe phase complete)
  reframed, 
  /// User committed to specific action plan (plan phase complete)
  planned, 
  /// User completed full coaching session (close phase complete)
  closed 
}

/// Event emitted during coaching session interactions
/// 
/// Each user reply in a coaching conversation generates a CoachEvent that captures:
/// - The coaching phase and prompt used
/// - Any guidance provided (reframes, plans, etc.)
/// - Auto-suggested tags from reply content analysis
/// - Outcome achieved if phase completed
class CoachEvent {
  /// Timestamp when the event occurred (local device time)
  final DateTime at;
  
  /// Current coaching phase (stabilize, open, reflect, reframe, plan, close)
  final String phase;
  
  /// Stable identifier for the prompt used (for analytics, not full text)
  /// Format: "phase_index" (e.g., "stabilize_0", "open_2", "reframe_0")
  final String promptId;
  
  /// Short summary of guidance provided (reframes, plans, etc.)
  /// Automatically truncated to ≤200 characters for storage efficiency
  final String? guidance;
  
  /// Outcome achieved if this event completed a coaching phase
  final CoachOutcome? outcome;
  
  /// Auto-suggested tags based on user reply content analysis
  /// Generated from common themes using deterministic keyword matching
  /// Format: lowercase snake_case (e.g., "low_energy", "self_compassion")
  /// Limited to ≤6 tags per event
  final List<String> tags;
  
  const CoachEvent({
    required this.at,
    required this.phase,
    required this.promptId,
    this.guidance,
    this.outcome,
    this.tags = const [],
  });
  
  /// Create event with guidance truncated to safe storage length
  factory CoachEvent.create({
    required DateTime at,
    required String phase,
    required String promptId,
    String? guidance,
    CoachOutcome? outcome,
    List<String> tags = const [],
  }) {
    return CoachEvent(
      at: at,
      phase: phase,
      promptId: promptId,
      guidance: guidance != null && guidance.length > 200 
        ? '${guidance.substring(0, 197)}...'
        : guidance,
      outcome: outcome,
      tags: List.unmodifiable(tags.take(6)), // Enforce ≤6 tag limit
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachEvent &&
          runtimeType == other.runtimeType &&
          at == other.at &&
          phase == other.phase &&
          promptId == other.promptId &&
          guidance == other.guidance &&
          outcome == other.outcome &&
          _listEquals(tags, other.tags);
  
  @override
  int get hashCode =>
      at.hashCode ^
      phase.hashCode ^
      promptId.hashCode ^
      guidance.hashCode ^
      outcome.hashCode ^
      tags.hashCode;
  
  @override
  String toString() => 'CoachEvent('
      'at: $at, '
      'phase: $phase, '
      'promptId: $promptId, '
      'guidance: $guidance, '
      'outcome: $outcome, '
      'tags: $tags'
      ')';
  
  /// Convert CoachEvent to Map for JSON/storage serialization
  Map<String, dynamic> toMap() {
    return {
      'atIso': at.toIso8601String(),
      'phase': phase,
      'promptId': promptId,
      'guidance': guidance,
      'outcome': outcome?.name,
      'tags': tags.join(';'),
    };
  }

  /// Create CoachEvent from Map (JSON/storage deserialization)
  static CoachEvent fromMap(Map<String, dynamic> map) {
    return CoachEvent(
      at: DateTime.parse(map['atIso'] as String),
      phase: map['phase'] as String,
      promptId: map['promptId'] as String,
      guidance: map['guidance'] as String?,
      outcome: map['outcome'] != null 
        ? CoachOutcome.values.firstWhere((e) => e.name == map['outcome'])
        : null,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
        ? (map['tags'] as String).split(';')
        : [],
    );
  }

  /// Convert to CSV row format
  /// CSV header: atIso,phase,promptId,guidance,outcome,tags
  String toCsvRow() {
    return [
      _escapeCsvField(at.toIso8601String()),
      _escapeCsvField(phase),
      _escapeCsvField(promptId),
      _escapeCsvField(guidance ?? ''),
      _escapeCsvField(outcome?.name ?? ''),
      _escapeCsvField(tags.join(';')),
    ].join(',');
  }

  /// CSV header for CoachEvent export
  static String get csvHeader => 'atIso,phase,promptId,guidance,outcome,tags';

  /// Parse CoachEvent from CSV row
  static CoachEvent fromCsvRow(String csvRow) {
    final fields = _parseCsvRow(csvRow);
    if (fields.length != 6) {
      throw FormatException('Invalid CSV row format: expected 6 fields, got ${fields.length}');
    }

    return CoachEvent(
      at: DateTime.parse(fields[0]),
      phase: fields[1],
      promptId: fields[2],
      guidance: fields[3].isEmpty ? null : fields[3],
      outcome: fields[4].isEmpty ? null : CoachOutcome.values.firstWhere((e) => e.name == fields[4]),
      tags: fields[5].isEmpty ? [] : fields[5].split(';'),
    );
  }

  /// Escape CSV field for safe serialization
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Parse CSV row handling quoted fields
  static List<String> _parseCsvRow(String row) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < row.length; i++) {
      final char = row[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          buffer.write('"'); // Escaped quote
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    fields.add(buffer.toString()); // Add final field
    return fields;
  }
}

/// Function type for receiving coach events
/// 
/// Called by ConversationalCoach when user interactions generate events.
/// Typically connected to export pipeline for persistence.
typedef CoachEventSink = void Function(CoachEvent event);

/// Helper for list equality comparison
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}