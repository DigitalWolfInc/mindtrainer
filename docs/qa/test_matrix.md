# MindTrainer QA Test Matrix

This document defines comprehensive test scenarios for MindTrainer across all user journeys, edge cases, and device configurations.

## Core User Journeys

### 1. Free User Onboarding Flow

#### Happy Path
- [ ] **First Launch**: Splash screen shows DigitalWolf for exactly 5 seconds
- [ ] **Start Screen**: MindTrainer2 icon displays correctly, navigation works
- [ ] **First Session**: User can complete full focus session without issues
- [ ] **Mood Check-in**: Animal selection works, data persists
- [ ] **Session History**: Completed session appears in history
- [ ] **Basic Analytics**: Free analytics show session data correctly
- [ ] **Goal Setting**: User can set and track weekly goals

#### Edge Cases
- [ ] **App Kill During Onboarding**: Resume from correct state after force-close
- [ ] **Network Loss**: All features work offline, no crashes
- [ ] **Storage Low**: Graceful handling when device storage is nearly full
- [ ] **Orientation Changes**: UI adapts correctly during onboarding

### 2. Pro Purchase Flow

#### Happy Path - Monthly
- [ ] **Pro Discovery**: User sees Pro badges on analytics screen
- [ ] **Billing Trigger**: Tapping Pro badge opens subscription screen
- [ ] **Plan Selection**: Monthly plan ($9.99) selectable and highlighted
- [ ] **Purchase Flow**: Google Play billing completes successfully
- [ ] **Receipt Verification**: Purchase confirmed and receipt generated
- [ ] **Feature Unlock**: Pro analytics immediately available
- [ ] **Subscription Status**: Pro status persists across app restarts

#### Happy Path - Yearly  
- [ ] **Plan Selection**: Yearly plan ($95.99) shows "Save 20%" badge
- [ ] **Price Confirmation**: User sees correct annual pricing
- [ ] **Purchase Flow**: Yearly subscription completes successfully
- [ ] **Savings Display**: UI correctly shows yearly savings vs monthly

#### Edge Cases
- [ ] **Purchase Interrupted**: Network loss during billing flow
- [ ] **Duplicate Purchase**: Attempting to buy same subscription twice
- [ ] **Payment Failure**: Credit card declined or insufficient funds
- [ ] **Google Play Error**: Billing service temporarily unavailable
- [ ] **Multiple Accounts**: Switching Google accounts during purchase

### 3. Subscription Management

#### Restore Purchases
- [ ] **New Device**: Installing app on new device restores Pro status
- [ ] **Account Switch**: Switching Google accounts updates Pro status correctly
- [ ] **Manual Restore**: "Restore Purchases" button works when needed
- [ ] **Failed Restore**: Graceful error handling when restore fails

#### Subscription Changes
- [ ] **Monthly to Yearly**: Upgrade flow works with proper proration
- [ ] **Yearly to Monthly**: Downgrade scheduled for next billing cycle  
- [ ] **Cancellation**: Cancel subscription through Google Play
- [ ] **Reactivation**: Resubscribe after cancellation

#### Expiration Scenarios
- [ ] **Natural Expiry**: Subscription expires, features lock gracefully
- [ ] **Grace Period**: 3-day grace period functions correctly
- [ ] **Failed Payment**: Account downgrade after payment failure
- [ ] **Refund Processing**: App handles Google Play refunds appropriately

## Feature-Specific Testing

### 4. Focus Sessions

#### Core Functionality
- [ ] **Session Timer**: Accurate timing, pause/resume works
- [ ] **Quality Rating**: 1-10 scale saves correctly
- [ ] **Session Notes**: Text input, save, and retrieval
- [ ] **Tag System**: Add, edit, delete custom tags
- [ ] **Progress Tracking**: Session counts and streaks calculate correctly

#### Edge Cases
- [ ] **App Backgrounding**: Session continues when app backgrounded
- [ ] **Phone Call Interruption**: Session pauses appropriately during calls
- [ ] **Battery Low**: Session saves data before app killed by system
- [ ] **Clock Changes**: Time zone or manual clock changes handled correctly
- [ ] **Extremely Long Sessions**: 2+ hour sessions don't cause memory issues

### 5. Analytics System

#### Free Analytics
- [ ] **Basic Stats**: Total sessions, average score, time display correctly
- [ ] **Recent History**: Last 30 days of sessions shown
- [ ] **Top Tags**: Most used tags appear in summary
- [ ] **Goal Progress**: Weekly goal tracking functions

#### Pro Analytics
- [ ] **Mood Correlations**: Mood-focus patterns calculate and display
- [ ] **Tag Performance**: Uplift metrics for tags shown correctly
- [ ] **Keyword Analysis**: Session note keywords extracted and analyzed
- [ ] **Unlimited History**: All historical data accessible
- [ ] **Data Export**: CSV export includes all user data correctly

### 6. Mood Check-in System

#### Animal Companions
- [ ] **Selection UI**: All animal options display and select correctly
- [ ] **State Persistence**: Selected mood saves and appears in history
- [ ] **Correlation Tracking**: Mood selections factor into Pro analytics
- [ ] **History View**: Check-in history displays chronologically

### 7. Goal and Streak System

#### Goal Setting
- [ ] **Weekly Goals**: Set sessions per week target (1-21 range)
- [ ] **Progress Display**: Current week progress shows correctly
- [ ] **Achievement Notifications**: Completion celebrations appear
- [ ] **Streak Calculation**: Consecutive weeks with goal achievement

#### Milestone Tracking
- [ ] **Daily Streaks**: Consecutive session days tracked
- [ ] **Weekly Streaks**: Consecutive weeks meeting goals
- [ ] **Personal Bests**: Highest scores and longest sessions recorded

## Device and Platform Testing

### 8. Android Device Classes

#### Minimum Specification (API 24, 2GB RAM)
- [ ] **App Launch**: < 5 seconds cold start time
- [ ] **Memory Usage**: < 150MB during normal operation
- [ ] **Session Recording**: No lag in timer or note-taking
- [ ] **Analytics Loading**: < 3 seconds for Pro analytics

#### Mid-Range Devices (API 28, 4GB RAM) 
- [ ] **Smooth Performance**: All animations fluid at 60fps
- [ ] **Background Handling**: App survives 1+ hours in background
- [ ] **Storage Efficiency**: App size stays under 100MB after use

#### High-End Devices (API 33, 8GB+ RAM)
- [ ] **Premium Experience**: Instant loading, no performance issues
- [ ] **Advanced Features**: All Pro analytics load under 1 second
- [ ] **Multitasking**: App handles split-screen and picture-in-picture

### 9. Screen Sizes and Orientations

#### Phone Screens
- [ ] **Small (5")**: All UI elements accessible, no text cutoff
- [ ] **Medium (6")**: Optimal layout and spacing
- [ ] **Large (6.5"+)**: Content scales appropriately, not sparse

#### Tablet Screens  
- [ ] **7" Tablets**: UI adapts to wider layout
- [ ] **10"+ Tablets**: Multi-column layouts where appropriate

#### Orientation Changes
- [ ] **Portrait to Landscape**: Smooth transition, state preserved
- [ ] **During Sessions**: Timer continues, UI adapts correctly
- [ ] **During Billing**: Purchase flow handles orientation changes

## Edge Case Scenarios

### 10. System Integration

#### Device State Changes
- [ ] **Airplane Mode**: App functions offline, graceful online transition
- [ ] **Do Not Disturb**: Respects system notification settings
- [ ] **Battery Saver**: Reduced background activity, core features work
- [ ] **Storage Full**: Graceful degradation, critical data still saves

#### Time and Clock Scenarios
- [ ] **Time Zone Change**: Sessions timestamp correctly in new zone
- [ ] **Daylight Saving**: Time changes don't break streaks or analytics
- [ ] **Manual Clock Change**: App detects and handles time discrepancies
- [ ] **NTP Sync**: Network time sync doesn't disrupt ongoing sessions

### 11. Stress Testing

#### Memory and Performance
- [ ] **1000+ Sessions**: Large data sets don't slow app performance
- [ ] **Rapid Navigation**: Fast tapping between screens doesn't crash app
- [ ] **Background Survival**: App survives 24+ hours in background
- [ ] **Memory Pressure**: Graceful handling when system memory is low

#### Data Integrity
- [ ] **Corrupted Data**: Recovery from corrupted local storage
- [ ] **Database Migrations**: Existing data preserved during app updates
- [ ] **Export Large Data**: CSV export works with months of session data
- [ ] **Concurrent Access**: Multiple app instances (if possible) handle data correctly

## Billing and Subscription Edge Cases

### 12. Payment Scenarios

#### Google Play Billing Edge Cases
- [ ] **Billing Service Down**: Graceful error messages when billing unavailable
- [ ] **Account Without Payment**: Clear messaging for accounts without payment methods
- [ ] **Regional Pricing**: Correct pricing shown for different countries
- [ ] **Family Sharing**: Proper handling of Google Play family subscriptions

#### Subscription Lifecycle
- [ ] **Billing Date Changes**: Monthly billing on different dates works correctly
- [ ] **Proration Calculations**: Upgrade/downgrade prorations calculate correctly
- [ ] **Refund Window**: App behavior during Google Play refund processing
- [ ] **Chargeback Handling**: Account status updates after payment disputes

### 13. Security and Privacy

#### Data Protection
- [ ] **Local Data Encryption**: Sensitive data encrypted on device
- [ ] **Session Isolation**: App data not accessible to other apps
- [ ] **Secure Deletion**: Deleted data is actually removed from storage
- [ ] **Privacy Policy Compliance**: Data handling matches privacy policy

#### App Security
- [ ] **Debug Builds**: No debug info or logs in production builds
- [ ] **API Key Security**: No hardcoded keys or sensitive data in APK
- [ ] **Certificate Pinning**: Secure connections for any network calls
- [ ] **Root/Jailbreak Detection**: App functions safely on modified devices

## Platform-Specific Testing

### 14. Android Versions

#### Android 7.0 (API 24) - Minimum Support
- [ ] **Core Features**: All basic functionality works
- [ ] **Billing Integration**: Google Play Billing v6 compatibility
- [ ] **Notification Handling**: Proper notification channel usage
- [ ] **File System**: Scoped storage compatibility

#### Android 10+ (API 29+) 
- [ ] **Scoped Storage**: File operations work with storage restrictions
- [ ] **Background Limits**: App adapts to background execution limits
- [ ] **Dark Mode**: UI adapts to system dark mode preference
- [ ] **Gesture Navigation**: Works with gesture-based navigation

### 15. Cross-Platform Considerations

#### Windows Desktop (if applicable)
- [ ] **Window Resizing**: UI scales appropriately with window size changes
- [ ] **Keyboard Navigation**: Tab navigation works for accessibility
- [ ] **File System Integration**: Export features work with Windows file system

#### Web Platform (if applicable)
- [ ] **Browser Compatibility**: Works in Chrome, Firefox, Safari
- [ ] **Responsive Design**: Adapts to different browser window sizes
- [ ] **Local Storage**: Browser storage used appropriately for data persistence

## Test Execution Strategy

### 16. Testing Phases

#### Pre-Release Testing Schedule
1. **Week 1**: Core functionality and happy path scenarios
2. **Week 2**: Edge cases and device compatibility  
3. **Week 3**: Billing integration and subscription management
4. **Week 4**: Performance testing and final validation

#### Testing Environments
- **Internal Testing**: Development team, comprehensive test matrix
- **Closed Testing**: 20 trusted users, focus on real-world usage
- **Open Testing**: 100+ users, stress testing and edge case discovery

### 17. Success Criteria

#### Performance Metrics
- **Crash Rate**: < 0.1% across all test scenarios
- **ANR Rate**: < 0.05% (no app-not-responding incidents)  
- **Cold Start Time**: < 3 seconds on minimum spec devices
- **Memory Usage**: < 150MB peak usage during normal operation

#### User Experience Metrics
- **Onboarding Completion**: > 90% of users complete first session
- **Feature Discovery**: > 75% of users try Pro analytics preview
- **Billing Success**: > 95% success rate for subscription purchases
- **Data Integrity**: 100% data preservation across all test scenarios

#### Compatibility Requirements  
- **Device Coverage**: Support 95% of Android devices in Play Console data
- **OS Version Coverage**: Android 7.0+ (API 24+)
- **Screen Size Coverage**: 4.5" to 12" screen sizes
- **Network Conditions**: Full offline functionality, graceful online sync

## Test Case Tracking

### 18. Issue Classification

#### Priority Levels
- **P0 - Blocker**: App crash, billing failure, data loss
- **P1 - Critical**: Core feature broken, poor performance
- **P2 - Major**: UI/UX issue, edge case problem  
- **P3 - Minor**: Cosmetic issue, enhancement opportunity

#### Resolution Requirements
- **P0 Issues**: Must fix before any release
- **P1 Issues**: Must fix before public release, may release to internal testing
- **P2 Issues**: Should fix but may ship with workaround
- **P3 Issues**: Nice to fix, can defer to next release

---

**Testing Philosophy**: Every scenario in this matrix should pass before public release. When in doubt, test the edge case - it's better to discover issues in QA than in user reviews.