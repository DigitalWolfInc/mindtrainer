/// Coach Event Filtering for MindTrainer
/// 
/// Provides filtering capabilities for coaching events that integrate with
/// the existing session filtering infrastructure without modifying core filter logic.
/// 
/// **Usage:**
/// ```dart
/// // Filter coaching events similar to session filters
/// final filter = CoachFilter(
///   tagsAny: ['anxiety', 'gratitude'],
///   from: DateTime(2024, 1, 1),
///   to: DateTime(2024, 12, 31),
///   textQuery: 'reframe',
/// );
/// 
/// final filteredEvents = filterCoachEvents(allCoachEvents, filter);
/// ```

import '../coach/coach_events.dart';

/// Filter criteria for coaching events
/// 
/// Follows the same semantics as session filters:
/// - Inclusive tag matching (any of the specified tags)
/// - Inclusive date bounds (from <= event.at <= to)
/// - Case-insensitive text search in guidance and prompt IDs
class CoachFilter {
  /// Include events that have any of these tags (OR logic)
  /// Empty list means no tag filtering
  final List<String>? tagsAny;
  
  /// Include events on or after this date (inclusive)
  final DateTime? from;
  
  /// Include events on or before this date (inclusive)
  final DateTime? to;
  
  /// Include events where guidance or promptId contains this text (case-insensitive)
  /// Null means no text filtering
  final String? textQuery;
  
  const CoachFilter({
    this.tagsAny,
    this.from,
    this.to,
    this.textQuery,
  });
  
  /// Check if this filter would match any events (has at least one criterion)
  bool get isActive => 
    (tagsAny != null && tagsAny!.isNotEmpty) ||
    from != null ||
    to != null ||
    (textQuery != null && textQuery!.trim().isNotEmpty);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachFilter &&
          runtimeType == other.runtimeType &&
          _listEquals(tagsAny, other.tagsAny) &&
          from == other.from &&
          to == other.to &&
          textQuery == other.textQuery;
  
  @override
  int get hashCode =>
      (tagsAny?.hashCode ?? 0) ^
      (from?.hashCode ?? 0) ^
      (to?.hashCode ?? 0) ^
      (textQuery?.hashCode ?? 0);
  
  @override
  String toString() => 'CoachFilter('
      'tagsAny: $tagsAny, '
      'from: $from, '
      'to: $to, '
      'textQuery: $textQuery'
      ')';
}

/// Filter coaching events based on provided criteria
/// 
/// Applies filters with AND logic (all active filters must match):
/// - Tag filter: event must have at least one of the specified tags
/// - Date filter: event timestamp must be within specified range
/// - Text filter: event guidance or promptId must contain query text
/// 
/// Returns filtered list in original order.
List<CoachEvent> filterCoachEvents(
  Iterable<CoachEvent> events,
  CoachFilter filter,
) {
  if (!filter.isActive) {
    return events.toList(); // No filtering, return all events
  }
  
  return events.where((event) {
    // Tag filtering (OR logic within tags, AND with other filters)
    if (filter.tagsAny != null && filter.tagsAny!.isNotEmpty) {
      final hasMatchingTag = filter.tagsAny!.any((filterTag) =>
          event.tags.any((eventTag) => 
              eventTag.toLowerCase() == filterTag.toLowerCase()));
      if (!hasMatchingTag) return false;
    }
    
    // Date range filtering (inclusive bounds)
    if (filter.from != null) {
      if (event.at.isBefore(filter.from!)) return false;
    }
    if (filter.to != null) {
      // Make 'to' date inclusive by treating it as end of day
      final endOfToDate = DateTime(
        filter.to!.year, 
        filter.to!.month, 
        filter.to!.day, 
        23, 59, 59, 999
      );
      if (event.at.isAfter(endOfToDate)) return false;
    }
    
    // Text query filtering (case-insensitive, searches guidance and promptId)
    if (filter.textQuery != null && filter.textQuery!.trim().isNotEmpty) {
      final query = filter.textQuery!.toLowerCase();
      
      final guidanceMatches = event.guidance?.toLowerCase().contains(query) ?? false;
      final promptIdMatches = event.promptId.toLowerCase().contains(query);
      
      if (!guidanceMatches && !promptIdMatches) return false;
    }
    
    return true; // Event passed all active filters
  }).toList();
}

/// Helper for list equality comparison
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}