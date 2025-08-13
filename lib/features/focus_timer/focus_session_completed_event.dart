/// Domain event fired when a focus session completes successfully
class FocusSessionCompleted {
  /// Duration of the completed session
  final Duration duration;
  
  const FocusSessionCompleted(this.duration);
  
  @override
  String toString() => 'FocusSessionCompleted(duration: $duration)';
}