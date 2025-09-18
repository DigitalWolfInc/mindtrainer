# Performance Testing Guide

## Performance Targets

### Startup Time
- Cold start: < 2.5s
- Warm start: < 1.2s
- Hot restart: < 0.5s

### Frame Times
- Target: 16.67ms (60fps)
- Max jank: < 0.5% of frames
- No frozen frames > 700ms

### Memory Usage
- Base footprint: < 100MB
- Peak during exercises: < 200MB
- No leaks after session

### Storage
- Install size: < 50MB
- Maximum cache: 100MB
- Clean uninstall

## Testing Tools

### Flutter DevTools
```bash
flutter run --profile
dart devtools
```

Key metrics to monitor:
- Frame timeline
- Memory timeline
- CPU usage
- Widget rebuilds

### Android Studio Profilers
- CPU Profiler
- Memory Profiler
- Network Profiler
- Energy Profiler

### Performance Overlay
```dart
MaterialApp(
  showPerformanceOverlay: true,
  // ...
)
```

## Test Scenarios

### Animation Performance
1. **Lottie Animations**
   - Monitor during breath animations
   - Check CPU usage
   - Verify frame drops
   - Test concurrent animations

2. **Training Exercises**
   - Pattern recognition rendering
   - Sprite sheet performance
   - Transition animations
   - Score animations

3. **UI Responsiveness**
   - List scrolling
   - Tab switching
   - Modal transitions
   - Keyboard interactions

### Audio Performance
1. **Sound Effects**
   - Latency < 50ms
   - No audio glitches
   - Memory usage stable
   - Background handling

2. **Ambient Audio**
   - Smooth transitions
   - No gaps in loops
   - Focus changes
   - Memory stable

### Memory Management
1. **Session Lifecycle**
   - Start → Complete flow
   - Check for leaks
   - Verify cleanup
   - Background/foreground

2. **Asset Loading**
   - Load time monitoring
   - Cache effectiveness
   - Memory pressure
   - Cleanup verification

### Background Behavior
1. **State Preservation**
   - App suspend/resume
   - Process kill recovery
   - State restoration
   - Data persistence

2. **Audio Continuity**
   - Screen off playback
   - Interruption handling
   - Focus recovery
   - Battery impact

## Performance Logging

### Frame Timing
```dart
import 'package:flutter/scheduler.dart';

void logFrameTiming(Duration duration) {
  if (duration.inMilliseconds > 16) {
    // Log slow frame
  }
}
```

### Memory Snapshots
```dart
import 'package:flutter/services.dart';

Future<void> logMemoryUsage() async {
  final info = await SystemChannels.platform.invokeMethod('getMemoryInfo');
  // Log memory stats
}
```

### Performance Events
```dart
class PerformanceEvent {
  final String name;
  final Duration duration;
  final Map<String, dynamic> metrics;
  
  // Log performance event
}
```

## Testing Environment

### Device Matrix
- Low-end Android (2GB RAM)
- Mid-range Android (4GB RAM)
- High-end Android (8GB+ RAM)
- Various screen sizes
- Different Android versions

### Test Conditions
- Clean install
- After extended use
- Low battery
- Low storage
- Background apps
- Network variations

### Performance Test Data
- Large session history
- Many achievements
- Full analytics data
- Maximum audio cache
- Maximum image cache

## Performance Optimization

### Widget Optimization
- Use const constructors
- Implement shouldRebuild
- Cache expensive widgets
- Lazy load when possible

### Animation Optimization
- Use RepaintBoundary
- Hardware acceleration
- Reduce layer count
- Optimize Lottie files

### Memory Optimization
- Image caching strategy
- Audio buffer sizes
- Dispose resources
- Clear unused caches

### Build Optimization
- R8 optimization
- Asset compression
- Native library stripping
- Code splitting