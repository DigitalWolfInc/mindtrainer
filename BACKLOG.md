# MindTrainer Development Backlog

## Phase 1: Must-Have Core

### 1. Animal-Based Mood Check-ins ✅ DONE
**Goal:** Implement positive, animal-themed emotional state tracking to replace clinical mood assessments.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Core_Emotional_Flows/animal_checkins_positive.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/System_Ethics_&_Safety/trauma_safe_language_guide.md`

**Acceptance Criteria:**
- ✅ User can select from 6 animal states (energetic rabbit, calm turtle, curious cat, wise owl, playful dolphin, gentle deer)
- ✅ Each selection saves timestamp and animal choice to local storage (SharedPreferences)
- ✅ UI uses only positive, non-clinical language ("How are you feeling?" vs medical terms)
- ✅ Check-in screen accessible from home screen via "Animal Check-in" button
- ✅ History view shows past week of animal selections

**Implementation:** Commit `83edf42` 
**Files:** `lib/features/mood_checkin/domain/animal_mood.dart`, `lib/features/mood_checkin/domain/checkin_entry.dart`, `lib/features/mood_checkin/data/checkin_storage.dart`, `lib/features/mood_checkin/presentation/animal_checkin_screen.dart`, `lib/features/mood_checkin/presentation/checkin_history_screen.dart`, `lib/features/focus_session/presentation/home_screen.dart`, `test/animal_mood_test.dart`

### 2. Trauma-Safe Language Audit
**Goal:** Review and update all UI text to ensure trauma-informed, supportive language throughout the app.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/System_Ethics_&_Safety/trauma_safe_language_guide.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/System_Ethics_&_Safety/user_first_design_manifesto.md`

**Acceptance Criteria:**
- All button text, labels, and messages avoid medical/clinical terms
- No language suggesting app provides medical treatment
- Error messages are supportive, not blame-focused  
- Session completion uses encouraging, not achievement-pressure language
- Emergency situations include disclaimers about professional care

### 3. Offline-First Architecture Validation
**Goal:** Ensure app functions completely without internet and data never leaves device without explicit consent.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Core_Emotional_Flows/offline_mode_always_at_your_6.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Support_Features/offline_mode_trigger_conditions.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/System_Ethics_&_Safety/privacy_guidelines_for_children.txt`

**Acceptance Criteria:**
- App starts and functions fully in airplane mode
- All session data, history, and preferences stored locally only
- No network requests made without explicit user action
- Settings screen clearly states "no data leaves your device"
- App works identically whether online or offline

### 4. Emergency Support Flow
**Goal:** Provide immediate access to crisis resources without replacing professional mental health care.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Core_Emotional_Flows/panic_detection_flow.txt`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Support_Features/emergency_voice_activation_notes.md`

**Acceptance Criteria:**
- "Get Support" button always visible on focus session screen
- Tapping opens local crisis resource list (no web links requiring internet)
- Clear disclaimer: "This app is not medical treatment"
- Option to exit session immediately and return to calm home screen
- No mood tracking or questions during crisis flow

## Phase 2: Enhancements

### 5. Deep Focus Session Levels
**Goal:** Offer progressive session depths while maintaining trauma-safe, non-medical framing.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Core_Emotional_Flows/deep_sync_mode_levels.txt`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Design_Themes_&_Visual_Notes/screen_layout_sketch_notes.txt`

**Acceptance Criteria:**
- 3 session types: "Gentle Focus" (10 min), "Steady Focus" (25 min), "Deep Focus" (45 min)
- Each level uses nature-inspired naming, no clinical terms
- Session history tracks which level was completed
- User can switch levels mid-session without penalty
- Visual design uses calming, non-medical imagery

### 6. Voice-Based Check-ins
**Goal:** Enable audio-based emotional state sharing for users who prefer speaking over tapping.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Core_Emotional_Flows/voice_based_checkin_little_watch.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/System_Ethics_&_Safety/privacy_guidelines_for_children.txt`

**Acceptance Criteria:**
- Voice recording stays on device, never transmitted
- 30-second max recording length
- User can re-record before saving
- Optional transcription using device-only speech recognition
- Clear privacy notice: "recordings never leave your device"

### 7. Sleep Support Mode
**Goal:** Adapt focus sessions for bedtime routines without making sleep-related medical claims.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Support_Features/sleep_support_logic.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Support_Features/follow_up_notification_schedule.txt`

**Acceptance Criteria:**
- "Evening Wind-Down" session type available after 7 PM
- Darker UI theme activates automatically in evening mode
- Sessions end with gentle suggestion to "rest when ready"
- No sleep tracking or medical sleep advice
- Optional gentle notification: "Evening session available" (user can disable)

### 8. Emotion Badge Collection
**Goal:** Gamify emotional awareness through collectible, animal-themed badges without medical assessment.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Design_Themes_&_Visual_Notes/emotion_badge_samples.png`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Design_Themes_&_Visual_Notes/honour_badge_templates.png`

**Acceptance Criteria:**
- Badges earned through session completion, not mood assessment
- 10+ animal-themed badges with nature-inspired names
- Badge gallery accessible from home screen
- No ranking, competition, or comparison features
- Badges celebrate participation, not emotional "improvement"

## Phase 3: Expansion

### 9. Community Testing Protocol
**Goal:** Enable safe user feedback collection while maintaining privacy-first principles.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Pricing_&_Partnerships/testgroup_chopbusters_notes.md`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Pricing_&_Partnerships/cmha_testing_protocol_draft.pdf`

**Acceptance Criteria:**
- Opt-in only feedback form, completely anonymous
- No user identification or device tracking
- Feedback stored locally until user chooses to share
- Clear notice: "sharing is optional and anonymous"
- Feedback focuses on app experience, not personal mental health

### 10. Child-Safe Version Adaptations
**Goal:** Ensure app is appropriate for younger users while maintaining core functionality.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Design_Themes_&_Visual_Notes/child_version_ui_notes.txt`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/System_Ethics_&_Safety/privacy_guidelines_for_children.txt`

**Acceptance Criteria:**
- Larger buttons and text for easier tapping
- Animal characters use playful, age-appropriate language
- Shorter session options (5, 10, 15 minutes)
- Emergency support includes "talk to a trusted adult" messaging
- No data collection beyond basic session completion tracking

### 11. Military Support Adaptation
**Goal:** Adapt interface and language for service members while avoiding medical claims.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Pricing_&_Partnerships/military_care_model.txt`
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Design_Themes_&_Visual_Notes/camo_ui_theme_al_dark.json`

**Acceptance Criteria:**
- Optional military-inspired visual theme (earth tones, tactical styling)
- Language adapted for service culture ("mission complete" vs "session finished")
- Emergency resources include military-specific support contacts
- No PTSD or trauma-specific medical content
- Theme is optional preference, not default

### 12. Premium Local Features
**Goal:** Offer enhanced local-only features through one-time purchase, no subscriptions.

**Sources:**
- `docs/memory_core_v1/mindtrainer_memory_core_v1/Pricing_&_Partnerships/tiered_pricing_structure.md`

**Acceptance Criteria:**
- One-time purchase unlocks additional session lengths and themes
- No features related to mental health assessment behind paywall
- Core emotional support features always free
- Premium features work offline, no cloud dependency
- Purchase processed through platform stores (iOS/Android), no third-party payments

---

**Constraints Honored:**
- All features maintain trauma-safe, non-clinical language
- No medical claims or diagnostic functionality
- Local-first architecture with offline capability
- User privacy and data protection prioritized
- Features sized for 1-2 day implementation cycles