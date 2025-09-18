# MindTrainer Release Checklist

## Version Strategy
- **SemVer Format**: MAJOR.MINOR.PATCH
- **Android versionCode**: MAJOR*10000 + MINOR*100 + PATCH
- **Example**: v1.2.3 = versionCode 10203

## Pre-Release Preparation

### 1. Code & Build
- [ ] Update version in `pubspec.yaml` and `android/app/build.gradle`
- [ ] Run `flutter clean && flutter pub get`
- [ ] Verify no debug prints or test code in production
- [ ] Confirm `FAKE_BILLING=false` for production build
- [ ] Generate signed release APK/AAB
- [ ] Test release build on physical device

### 2. Billing & Subscriptions
- [ ] Verify SKUs match Play Console exactly:
  - `pro_monthly` → `base_monthly_v1`
  - `pro_yearly` → `base_yearly_v1`
- [ ] Test purchase flow in internal testing track
- [ ] Test restore purchases functionality
- [ ] Verify subscription status persistence across app restarts
- [ ] Test billing with real Google account (not test account)

### 3. Content & Compliance
- [ ] Review all user-facing text for typos and tone
- [ ] Confirm charity messaging is clearly non-transactional
- [ ] Verify no medical claims or therapeutic language
- [ ] Check Pro feature descriptions match actual functionality
- [ ] Validate privacy policy covers all data collection

## Track Progression Strategy

### Internal Testing (Team Only)
**Duration**: 2-3 days  
**Goal**: Catch obvious bugs and billing issues

- [ ] Upload to Internal Testing track
- [ ] Test core functionality: sessions, journaling, analytics
- [ ] Test billing: purchase, cancel, restore
- [ ] Test edge cases: network loss, app backgrounding
- [ ] Verify splash screen timing and transitions
- [ ] Check memory usage and performance

### Closed Testing (Trusted Users)
**Duration**: 1 week  
**Goal**: Real-world usage patterns and feedback

- [ ] Upload to Closed Testing track  
- [ ] Recruit 10-20 trusted users
- [ ] Provide testing guidelines focusing on:
  - Free user experience completeness
  - Pro upgrade flow clarity
  - Billing confirmation and receipt
  - Session data persistence
- [ ] Monitor crash reports and user feedback
- [ ] Fix any P0/P1 issues found

### Open Testing (Public Beta)
**Duration**: 1-2 weeks  
**Goal**: Scale testing and Play Store approval

- [ ] Upload to Open Testing track
- [ ] Monitor Play Console for policy violations
- [ ] Watch for:
  - Subscription cancellation patterns
  - Support requests about billing
  - Feature confusion or UX friction
- [ ] Collect analytics on conversion funnel
- [ ] Prepare production rollout plan

### Production Release
**Goal**: Gradual rollout with monitoring

- [ ] Upload to Production track
- [ ] Start with 5% rollout
- [ ] Monitor for 24-48 hours:
  - Crash-free rate > 99.5%
  - ANR rate < 0.1%
  - User ratings >= 4.0
  - No billing support tickets
- [ ] Increase to 25% if metrics are good
- [ ] Full 100% rollout after another 24-48 hours

## Quality Gates

### Must-Pass Tests
- [ ] App launches without crash on Android 7.0+ (API 24+)
- [ ] Splash screen shows DigitalWolf for exactly 5 seconds
- [ ] Free users can complete full onboarding and sessions
- [ ] Pro users see all premium features unlocked
- [ ] Billing receipts are generated correctly
- [ ] Subscription status persists across app kills
- [ ] Airplane mode doesn't crash the app
- [ ] Device orientation changes handled gracefully

### Performance Requirements  
- [ ] App startup time < 3 seconds on mid-range devices
- [ ] Session recording has < 100ms latency
- [ ] Analytics screen loads in < 2 seconds
- [ ] Memory usage stays under 150MB during normal use
- [ ] No memory leaks during 30-minute test session

### Edge Case Scenarios
- [ ] **Clock Skew**: Change device time during active session
- [ ] **Network Loss**: Go offline during billing flow
- [ ] **App Kill**: Force-kill app during session recording
- [ ] **Storage Full**: Test behavior when device storage is low  
- [ ] **Subscription Expired**: Verify graceful degradation to free features
- [ ] **Multiple Purchases**: Attempt to buy same subscription twice
- [ ] **Refund Processing**: Test app behavior after Google Play refund

## Rollback Plan

### Immediate Halt Triggers
Stop rollout immediately if any of these occur:
- Crash rate > 0.5% in first 24 hours
- Billing complaints > 5 in first day
- Play Store policy violation notice
- Major feature completely broken
- User ratings drop below 3.5

### Rollback Actions
1. **Halt Rollout**: Pause release in Play Console
2. **Assess Impact**: Check affected user count and issue severity  
3. **Quick Fix**: If fixable in < 4 hours, prepare hotfix
4. **Full Rollback**: If not quickly fixable, rollback to previous version
5. **Communication**: Update Play Console "What's New" with issue acknowledgment
6. **Post-Mortem**: Document what went wrong and prevention steps

### Hotfix Process
For critical issues requiring immediate fix:
- Increment PATCH version (e.g., 1.2.3 → 1.2.4)
- Make minimal, targeted changes only
- Skip Closed Testing, go directly to Internal → Open → Production
- Monitor rollout at 10% → 50% → 100% in 6-hour intervals

## Play Console Configuration

### Required Manual Actions
- [ ] Create subscription products in Play Console:
  - Product ID: `pro_monthly`, Base Plan: `base_monthly_v1`
  - Product ID: `pro_yearly`, Base Plan: `base_yearly_v1`
- [ ] Set up upgrade/downgrade rules per `billing_catalog.json`
- [ ] Configure license testing accounts
- [ ] Upload app screenshots (8 total: 4 phone, 4 tablet)
- [ ] Set age rating and content guidelines
- [ ] Configure Data Safety form per `data_safety_map.md`

### Store Listing Updates
- [ ] Upload feature graphic (1024×500px)
- [ ] Add short description (80 chars max)
- [ ] Add full description with Pro feature bullets
- [ ] Set app category: Health & Fitness
- [ ] Add privacy policy URL
- [ ] Configure in-app product pricing for all supported countries

## Post-Release Monitoring

### First 24 Hours
- [ ] Monitor Play Console vitals hourly
- [ ] Check billing revenue and subscription metrics  
- [ ] Review user ratings and feedback
- [ ] Monitor support email for billing issues
- [ ] Track key metrics: DAU, retention, conversion rate

### First Week
- [ ] Daily vitals review
- [ ] Weekly cohort analysis
- [ ] Billing refund/chargeback monitoring  
- [ ] Feature usage analytics review
- [ ] Plan next release based on user feedback

### Success Metrics
- Crash-free rate: > 99.5%
- ANR rate: < 0.1%
- Average rating: > 4.0
- Pro conversion rate: > 2%
- Day 7 retention: > 25%

## Emergency Contacts
- **Play Console Admin**: [Team Lead]
- **Billing Support**: [Finance Lead]  
- **Technical Lead**: [Engineering Lead]
- **Customer Support**: [Support Lead]

---

**⚠️ Never release on Friday or before holidays**  
**✅ Always have at least 2 team members available for first 24 hours**