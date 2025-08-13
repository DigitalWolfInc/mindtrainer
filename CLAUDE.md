# Claude Operating Guide — MindTrainer (Flutter)

## How to work
- Make **small, focused patches** (1–3 files).
- **Only** touch files I name. If more are required, ask first.
- Don’t reformat whole files. Change only what’s needed to meet the goal.
- Keep public APIs as-is unless explicitly told to change them.
- Every patch must compile and keep current behavior stable.

## Project layout (initial)
- Entry: `lib/main.dart`
- App code goes under `lib/`
- If a new area is needed, create a folder under `lib/features/<name>/`
- Shared helpers go under `lib/core/` (create it if missing)

## UI rules
- Respect existing spacing/typography.
- Tap targets ≥ 44x44.
- Keep animations subtle.

## Errors & logs
- No `print` in production code.
- If logging is needed, write a tiny helper in `lib/core/logging.dart`.

## Tests
- If logic (not just UI) changes, add or update a small test.

## Git hygiene
- One topic per commit, with a clear subject (e.g., `feat: add app bar title`).

## When unsure
- Ask one clarifying question, then do the **smallest safe change**.

## Request format I will use
- **Intent**: what should change for the user.
- **Scope**: exact file(s) to touch.
- **Acceptance**: bullet list of what must be true after the change.
We’re working on MindTrainer.

Current status:
- All Flutter tests are passing, including the LanguageValidator fix.
- Project structure: lib/core, lib/features/[feature], docs/CLAUDE.md, docs/DECISIONS.md, docs/memory_core_v1.
- No BACKLOG.md file exists.

Your task:
- Implement focus session statistics tracking:
  • Track total focus time (in minutes)
  • Track average session length
  • Track number of completed sessions
- Persist data so stats remain after app restart.
- Display these stats in history_screen.dart under lib/features/f