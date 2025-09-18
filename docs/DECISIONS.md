# MindTrainer – Decisions Log

## Vision
MindTrainer is a Flutter-based app for mental training, cognitive exercises, and mood tracking. It aims to help users strengthen focus, emotional resilience, and memory through interactive sessions, safe language, and adaptive challenges.

## Must-Haves
- Local-first design for all features; no mandatory online connection.
- Focus session timer with history tracking.
- Mood check-in system with customizable themes.
- Offline mode with full functionality.
- Ethics and trauma-safe language in all interactions.
- Intuitive navigation with child-friendly mode.
- Cross-platform support: Android, iOS, tablets, Chromebook.

## Guardrails
- Follow System_Ethics_&_Safety.md at all times.
- Avoid medical claims or diagnostics.
- Store data locally unless the user explicitly opts in for sync or backup.
- Minimize disruption during user flow.
- Prioritize privacy and dignity over engagement tricks.
- Keep pricing transparent; no dark patterns.

## Deferred Items
- Subscription tiers and payment integration.
- Cloud sync and multi-device support.
- Third-party integrations.
- Advanced analytics (only with explicit user consent).

## Mood Score Mapping
For cross-feature insights (mood ↔ focus correlation), animal moods are mapped to numeric scores on a 1-10 scale where higher scores indicate moods associated with higher energy/focus potential:

- **Energetic Rabbit** (🐰): 9.0 - High energy, ready for action
- **Curious Cat** (🐱): 8.0 - Active interest and engagement  
- **Playful Dolphin** (🐬): 7.0 - Fun-seeking, moderately active
- **Wise Owl** (🦉): 6.0 - Thoughtful, contemplative
- **Gentle Deer** (🦌): 4.0 - Quiet, gentle energy
- **Calm Turtle** (🐢): 3.0 - Low energy, peaceful pace

This mapping is used in `lib/features/insights/domain/mood_focus_insights.dart` for computing Pearson correlation between daily mood scores and focus session minutes.

Purpose: This file is a single, ongoing record of confirmed product decisions so future sessions and contributors can get up to speed instantly.