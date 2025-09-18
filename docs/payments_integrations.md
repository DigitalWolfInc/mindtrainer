# Payments & Charity Integration

This document describes MindTrainer's subscription model, charity messaging, and privacy-safe email opt-in system.

## Subscription Model

### Pro Subscription Tiers

- **Free**: Basic focus sessions and mood tracking
- **Pro**: All features unlocked ($10/month or $100/year)

### Pricing Structure

- Monthly Pro: $10.00/month via Google Play Billing
- Yearly Pro: $100.00/year via Google Play Billing (17% discount)
- Platform adapters to be implemented for Google Play Billing and App Store

### Pro Features

When Pro subscription is active, the following features are unlocked:

- Unlimited focus sessions (vs. limited for free users)
- Advanced insights and analytics with correlation analysis
- Data export and backup (JSON/CSV formats)
- AI coaching conversations with personalized guidance
- Premium themes and customization options
- Ad-free experience

### Technical Implementation

The subscription system uses a clean architecture with ports and adapters:

- `ProStatus` - Value object for subscription state
- `SubscriptionGateway` - Abstract interface for platform billing
- `ProManager` - Central manager for subscription logic
- `DefaultProGate` - Feature gating based on subscription status

Platform-specific implementations (Google Play Billing, App Store) will be added as separate adapter modules.

## Charity Messaging

### Policy

MindTrainer allocates **one-third (33%) of subscription revenue** to a fund supporting shelters. This is a fixed allocation, not user-configurable.

### Key Points

- **No in-app donations**: Users cannot make direct donations within the app
- **Revenue sharing only**: Charity support comes from subscription revenue allocation
- **Transparency**: Users are informed about the charity allocation
- **External donations**: Optional external link opens browser to separate donation page

### Implementation

- `CharityPolicy` - Configuration for revenue share and external donation link
- `ImpactSnapshot` - Calculated impact from subscription revenue
- `computeImpact()` - Pure function to calculate earmarked charity funds
- Messaging helpers for consistent UI copy

### Privacy & Compliance

- No donation-based feature unlocks or perks
- External donation link opens browser (no in-app payment processing)
- Transparent communication about revenue allocation
- No tracking of individual user donation amounts

## Email Opt-in System

### Privacy Design

- **Opt-in default**: Users must explicitly consent to email updates
- **Local storage**: Consent stored locally on device only
- **No network calls**: Email enrollment handled server-side later
- **Easy revocation**: Users can revoke consent at any time
- **Data minimization**: Only stores consent flag, email, and timestamp

### Implementation

- `EmailOptInManager` - Manages consent and email storage
- `KVStore` - Abstract storage interface (SharedPreferences in production)
- Consent versioning (`email_opt_in_v1`) for future policy changes
- Privacy export functionality for GDPR compliance

### Consent Management

1. **Initial state**: Opted out by default
2. **Opt-in**: User explicitly consents, timestamp recorded
3. **Email storage**: Optional email address stored with consent
4. **Opt-out**: All email data cleared immediately
5. **Revocation**: Complete consent removal with data cleanup

### Data Stored

When user opts in, the following data is stored locally:

```
email_opt_in_v1: boolean           // Consent flag
email_opt_in_address_v1: string?   // Email address (optional)
email_opt_in_timestamp_v1: string  // ISO 8601 timestamp
```

## Settings Integration

### App Settings VM

The `AppSettingsVM` provides a unified interface for:

- Pro subscription status and management
- Charity messaging and external donation link
- Email opt-in consent management
- Privacy data export

### Usage Example

```dart
// Create settings VM
final settings = AppSettingsVMFactory.create(
  email: EmailOptInManager(sharedPrefsStore),
  pro: ProManager(playBillingGateway),
  donateLink: Uri.parse('https://charity.org/donate'),
);

// Display charity message
Text(settings.charityCopy)

// Handle email opt-in
settings.setEmailOptIn(true, emailAddress: userEmail)

// Check Pro status
if (settings.proActive) {
  // Show Pro features
}
```

## Security & Compliance

### Payment Security

- No credit card data stored or processed in app
- Platform billing services handle all payment processing
- Subscription verification handled by platform stores

### Privacy Compliance

- GDPR-ready with explicit consent and easy revocation
- Privacy export functionality for data portability
- Minimal data collection (consent + email only)
- Clear opt-out mechanisms

### Charity Compliance

- No donation processing within app (external link only)
- Transparent revenue allocation messaging
- No perks or rewards tied to charity donations
- Clear separation between subscription features and charity support

## Implementation Status

### Completed
- ✅ Pro subscription domain model
- ✅ Charity messaging logic
- ✅ Email opt-in consent management  
- ✅ Settings integration layer
- ✅ Comprehensive test suite
- ✅ Fake implementations for development

### Pending
- ⏳ Google Play Billing adapter implementation
- ⏳ App Store billing adapter implementation
- ⏳ Server-side email enrollment integration
- ⏳ UI components for subscription management
- ⏳ Charity impact dashboard
- ⏳ Production SharedPreferences KVStore implementation

## Testing

The implementation includes comprehensive tests covering:

- Charity impact calculation with various revenue scenarios
- Email consent management with all edge cases
- Pro subscription status transitions and feature gating
- Settings VM integration across all components
- Safety assertions preventing donation-based unlocks
- Privacy compliance and data export functionality

Run tests with:
```bash
flutter test test/charity_optin_test.dart
```