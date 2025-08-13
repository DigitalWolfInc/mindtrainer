# Google Play Data Safety Form Mapping

This document maps MindTrainer's data practices to Google Play's Data Safety form requirements.

## Data Collection Overview

### Does your app collect or share any of the required user data types?
**Answer: YES** (we collect some data types)

## Data Types Collected

### 1. Personal Info
- **Name**: NO - not collected
- **Email address**: NO - not collected  
- **User IDs**: NO - not collected
- **Address**: NO - not collected
- **Phone number**: NO - not collected
- **Race and ethnicity**: NO - not collected
- **Political or religious beliefs**: NO - not collected
- **Sexual orientation**: NO - not collected
- **Other personal info**: NO - not collected

### 2. Financial Info  
- **User payment info**: NO - handled by Google Play Billing, we never see payment details
- **Purchase history**: NO - not collected
- **Credit score**: NO - not collected
- **Other financial info**: NO - not collected

### 3. Health and Fitness
- **Health info**: NO - we collect wellness data but not medical information
- **Fitness info**: NO - not collected

### 4. Messages
- **Emails**: NO - not collected
- **SMS or MMS**: NO - not collected  
- **Other in-app messages**: NO - not collected

### 5. Photos and Videos
- **Photos**: NO - not collected
- **Videos**: NO - not collected

### 6. Audio Files
- **Voice or sound recordings**: NO - not collected
- **Music files**: NO - not collected
- **Other audio files**: NO - not collected

### 7. Files and Docs
- **Files and docs**: NO - not collected

### 8. Calendar
- **Calendar events**: NO - not collected

### 9. Contacts
- **Contacts**: NO - not collected

### 10. App Activity
- **App interactions**: YES - we collect this data
  - **Data collected**: Session duration, frequency, quality ratings, mood check-ins, custom tags, journal entries
  - **Purpose**: App functionality, Analytics, Personalization
  - **Sharing**: Not shared with third parties
  - **Optional**: NO - required for core app functionality
  - **User control**: Users can delete individual sessions or all data

- **In-app search history**: NO - not collected
- **Installed apps**: NO - not collected  
- **Other user-generated content**: YES - we collect this data
  - **Data collected**: Journal entries, session notes, custom tags
  - **Purpose**: App functionality, Personalization
  - **Sharing**: Not shared with third parties
  - **Optional**: YES - journaling is optional
  - **User control**: Users can delete notes or disable journaling

- **Other actions**: NO - not collected

### 11. Web Browsing
- **Web browsing history**: NO - not collected

### 12. App Info and Performance
- **Crash logs**: YES - we collect this data
  - **Data collected**: App crash reports and performance metrics
  - **Purpose**: Analytics, App functionality
  - **Sharing**: Not shared with third parties  
  - **Optional**: NO - required for app stability
  - **User control**: Cannot be disabled (essential for app function)

- **Diagnostics**: YES - we collect this data
  - **Data collected**: Performance metrics, error logs
  - **Purpose**: Analytics, App functionality
  - **Sharing**: Not shared with third parties
  - **Optional**: NO - required for app performance
  - **User control**: Cannot be disabled (essential for app function)

- **Other app performance data**: NO - not collected

### 13. Device or Other IDs
- **Device or other IDs**: NO - not collected

## Data Sharing

### Is any of the required user data shared with third parties?
**Answer: NO** - We do not share any user data with third parties

## Data Security

### Is all of the user data collected by your app encrypted in transit?
**Answer: YES** - All data transmission uses TLS encryption

### Do you provide a way for users to request that their data is deleted?  
**Answer: YES** - Users can delete individual sessions or completely reset the app

## Target Audience

### Is your app designed for families (designed for children under 13)?
**Answer: NO** - App is designed for users 13 and older

## Detailed Explanations for Complex Responses

### App Activity - App Interactions
**What we collect:**
- Focus session duration and timestamps
- Session quality ratings (1-10 scale)
- Mood check-in selections (animal-based emotional states)
- Custom session tags and categories
- Weekly goals and progress tracking
- Achievement milestones and streaks

**Why we collect it:**
- **App functionality**: Core features require session tracking for basic progress display
- **Analytics**: Generate insights about focus patterns and mood correlations (Pro feature)
- **Personalization**: Customize app experience based on user preferences and history

**Data retention:**
- Users can choose retention period (30 days to unlimited)
- Data is stored locally on device by default
- Optional cloud sync available for cross-device access

### App Activity - Other User-Generated Content
**What we collect:**
- Session notes and reflections (if user chooses to journal)
- Custom tags and labels created by users
- Personal goal descriptions and targets

**Why we collect it:**
- **App functionality**: Display user's own notes and tags for reference
- **Personalization**: Organize sessions based on user-created categories

**User control:**
- Journaling is completely optional
- Users can delete individual notes or disable journaling entirely
- Tags can be edited or removed at any time

### App Performance Data
**What we collect:**
- App crash reports and stack traces (no personal data included)
- Performance metrics (startup time, memory usage, screen load times)
- Error logs for debugging (sanitized of personal information)

**Why we collect it:**
- **App functionality**: Identify and fix bugs that affect user experience  
- **Analytics**: Monitor app stability and performance across different devices

**Limitations:**
- No personal information included in crash reports
- Performance data is aggregated and anonymized
- Used solely for app improvement, not marketing

## Data Safety Form Quick Reference

| Question | Answer | Details |
|----------|--------|---------|
| Collect data? | YES | App interactions, user content, performance data |
| Share data? | NO | No third-party sharing |
| Encrypt data? | YES | TLS encryption for any data transmission |
| User deletion? | YES | Full data deletion available |
| Target kids? | NO | 13+ age requirement |

## Compliance Notes

### GDPR Compliance
- Users can access all their data through app export
- Data deletion is available (right to erasure)
- Data portability through CSV export
- Legal basis: User consent and contractual necessity

### CCPA Compliance  
- No sale of personal information
- User data deletion available
- Transparent data collection practices
- Non-discrimination policy in place

### Google Play Policy Alignment
- Essential app functionality clearly separated from optional data collection
- No sensitive data categories (health info treated as wellness, not medical)
- Clear user controls and opt-out mechanisms
- Privacy-first design with local data storage