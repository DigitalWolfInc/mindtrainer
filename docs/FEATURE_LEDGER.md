# MindTrainer Feature Ledger — Baseline (2025-08-12)

## Analytics → Usage Telemetry & Tool History

**Owner:** `lib/features/analytics/domain/analytics_service.dart`
**Purpose:** Central analytics pipeline for all user events and tool usage tracking

**Responsibilities:**
- Route all tool usage events through `AnalyticsService.trackEvent(...)`
- Maintain user interaction history with batching and conversion analysis
- Support A/B experiment hooks for feature testing
- Provide unified event interface for cross-feature analytics

**Integration Points:**
- Tool usage service routes to `analytics_service.dart` via `trackEvent('tool_usage', ...)`
- Engagement analytics extends owner class for pro feature tracking
- No parallel tracking systems - single source of truth

## Achievements → Time Badges

**Owner:** `lib/achievements/achievements_resolver.dart`, `lib/achievements/badge_ids.dart`
**Purpose:** Time-based achievement computation using foundation/clock.dart

**Responsibilities:**
- Compute early riser badges (sessions before 8 AM)
- Compute night owl badges (sessions after 10 PM) 
- Compute consistent week badges (5+ sessions/week)
- Compute monthly milestone badges (30+ sessions/month)
- Use `foundation/clock.dart` for testable time calculations

**Integration Points:**
- Badge IDs defined in `badge_ids.dart` for type safety
- Computation follows existing resolver patterns (streaks, totals, tags)
- Achievement logic centralized, testable, and consistent
- No UI computation - domain-only time-based calculations

## Dev Tooling / Diagnostics → Claude Logger

**Owner:** `lib/support/logger.dart`
**Purpose:** Development logging utilities with production safety

**Responsibilities:**
- Provide ring buffer logging for development diagnostics
- Guard all operations with `kReleaseMode` checks
- Support optional file persistence with user consent
- Zero runtime impact in production builds

**Integration Points:**
- Fully guarded behind `kReleaseMode` checks
- No coupling to production code paths
- Part of dev diagnostics toolkit only
- Available for testing and debug sessions