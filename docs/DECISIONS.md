# MindTrainer – Decisions Log

## Vision
MindTrainer is a local-first mental wellness app that provides gentle, trauma-safe emotional support through animal-themed check-ins and focus sessions. The app prioritizes user safety and privacy by keeping all data on-device and avoiding medical claims or clinical language.

## Must-Haves
- **Animal-based emotional check-ins** - Positive, non-clinical way for users to track how they're feeling
- **Focus timer sessions** - Core mindfulness/concentration feature with persistence across app restarts
- **Trauma-safe language throughout** - All UI text must avoid clinical terms, blame language, and achievement pressure
- **Offline-first functionality** - App must work completely without internet connection
- **Local data storage only** - No user data leaves the device without explicit consent
- **Emergency support resources** - Crisis support information with clear disclaimers about professional care
- **Child-safe design** - Interface and language appropriate for younger users

## Guardrails

### Ethics and Safety Constraints
- **No medical claims** - App cannot suggest it provides medical treatment, diagnosis, or therapy
- **Trauma-informed language** - Avoid clinical, blame-focused, or achievement-pressure terms
- **Professional care disclaimers** - Emergency features must direct users to qualified professionals
- **Crisis support** - Always include pathways to real human support, never replace it
- **Age-appropriate content** - Design must be safe for children while serving adults

### Privacy and Security Constraints
- **Device-only storage** - All user data stays on SharedPreferences/local storage
- **No analytics or tracking** - No user behavior monitoring or data collection
- **No account system** - No user identification, emails, or personal information collected
- **Minimal permissions** - Only request essential device permissions
- **Transparent data handling** - Clear privacy notices about local-only data

### Local-First Preferences
- **Offline functionality** - Core features work without internet
- **No cloud dependencies** - Avoid services requiring network connectivity
- **Local-only premium features** - Any paid features must work offline
- **Platform-native payments only** - Use iOS/Android stores, no third-party payment processing

## Deferred Items
- **Voice recording features** - Planned for Phase 2 with device-only processing
- **Advanced session customization** - Custom timer lengths, background sounds (Phase 2)
- **Badge/achievement system** - Participation-based recognition without competition (Phase 2)
- **Sleep support mode** - Evening-specific features and themes (Phase 2)
- **Military/veteran theming** - Tactical visual themes and service-appropriate language (Phase 3)
- **Community feedback system** - Anonymous, opt-in user feedback collection (Phase 3)
- **Partnership integrations** - CMHA testing protocols, professional organization validation (Phase 3)
- **Multiple languages** - Internationalization with trauma-safe translation validation (Future)
- **Accessibility enhancements** - Screen reader optimization, motor accessibility (Future)

---

**Purpose:** This file is a single, ongoing record of confirmed product decisions so future sessions and contributors can get up to speed instantly.