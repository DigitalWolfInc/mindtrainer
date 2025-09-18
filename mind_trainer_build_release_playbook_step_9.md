# Step 1 — Lock the Toolchain and Project Skeleton (Known‑Good Build Baseline)

**Objective:** eliminate Gradle/AGP/JDK mismatch as a source of failures before we touch app code, animations, or audio. This baseline is compatible with Play’s 2025 targeting rules and supports your feature set (Training, Mindfulness with audio/animation, Progress, Profile).

---

## 1. Pin the environment

1. **Flutter channel**: Use *stable*. Verify with `flutter doctor -v` and `flutter --version`.
2. **Android Studio & SDK**: Update to the latest stable Android Studio. In SDK Manager, install:

   * **Android 15 (API 35) Platform** and **Build Tools 35.x**
   * **Android 14 (API 34)** (for backward compile checks)
   * **Platform‑Tools**
3. **JDK**: Use **JDK 17 (LTS)**. Set `JAVA_HOME` to this JDK. Avoid mixing system JDKs.

> Sanity check: run `./gradlew -v` inside `android/` and confirm it shows JDK 17.

---

## 2. Pin AGP ↔ Gradle (single known‑good pair)

Use this pair across all Flutter Android modules:

* **Android Gradle Plugin (AGP): 8.12.x**
* **Gradle Wrapper: 8.13**
* **Build Tools: 35.x**
* **Min JDK: 17**

**Actions**

* Update `android/gradle/wrapper/gradle-wrapper.properties` to the 8.13 distribution.
* In the top‑level Gradle settings (plugins block), set AGP to 8.12.x and Kotlin plugin to the matching stable series.
* If Android Studio flags incompatibility, run **Tools → AGP Upgrade Assistant** and let it apply required changes.

**Why this pair?** It aligns with current Studio builds, supports API 35 targeting, and avoids experimental Gradle/AGP edges that trigger packaging or R8/D8 surprises.

---

## 3. Set Android SDK levels (Play‑compliant defaults)

* **minSdk**: 24 (Android 7.0) unless you have a hard requirement for lower.
* **compileSdk / targetSdk**: **35**.
* Do not over‑advance `compileSdk` beyond what your AGP pair officially supports.

> We will bump these later only if Play or library requirements force it.

---

## 4. Create a clean asset strategy (animations + audio)

**Folders (at project root):**

```
assets/
  animations/          # Lottie JSON or sprite sheets
  images/              # PNG/WebP vectors/rasters for UI
  audio/
    ambient/           # long‑form loops (OGG/Opus/MP3)
    sfx/               # short UI cues (OGG/WAV)
```

**Rules**

* Filenames: lowercase, hyphen‑separated, no spaces.
* Prefer **WebP** for rasters; keep originals elsewhere.
* Lottie preferred for UI breathing/visual guides; sprite sheets for gamified badges and grids.
* Audio:

  * **SFX** (taps, ticks): OGG (Vorbis) at 44.1 kHz, short duration; or small WAV if latency‑critical.
  * **Ambience/music**: OGG/Opus (preferred) or MP3 CBR 128–192 kbps.
* Keep any clip >10s as a streamed asset (not preloaded into memory). We’ll wire this in Step 3.

---

## 5. Publish assets in `pubspec.yaml` safely

* Use globbing per folder rather than hundreds of lines.
* Ensure indentation is two spaces; no tabs.
* Keep the list minimal now; expand only when a folder is stable.

Example shape (do **not** paste yet; we’ll generate the exact block once your first asset batch is in place):

```
flutter:
  assets:
    - assets/images/
    - assets/animations/
    - assets/audio/ambient/
    - assets/audio/sfx/
```

---

## 6. Baseline Gradle properties (stability‑first)

In `android/gradle.properties`:

```
org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
android.useAndroidX=true
# Keep Jetifier off unless you add a very old library that requires it
android.enableJetifier=false
```

If you hit out‑of‑memory on CI, raise `-Xmx` gradually; don’t exceed your machine limits.

---

## 7. Sanity project build (proves the toolchain)

1. From repo root: `flutter clean && flutter pub get`
2. Kill any daemon: `./android/gradlew --stop`
3. First build: `flutter build apk -v`
4. If this fails, capture the **first** error cause above the stacktrace. We only proceed once this passes.

---

## 8. Sign‑off checklist for Step 1

* [ ] Flutter on stable; `doctor` clean (or only benign warnings)
* [ ] Android Studio + SDKs installed (API 35 + Build Tools 35.x)
* [ ] JDK 17 active for Gradle
* [ ] Gradle wrapper 8.13; AGP 8.12.x set
* [ ] `compileSdk/targetSdk` at 35; `minSdk` 24 (unless you need lower)
* [ ] Asset folders created; naming rules applied
* [ ] `gradle.properties` tuned
* [ ] `flutter build apk -v` succeeds on a clean tree

— End of Step 1 —

# Step 2 — Project Hygiene & Gradle Settings (Assets, Pubspec, Shrinker)

**Objective:** lock in a clean structure and Gradle config so animations/audio won’t trip packaging, AAPT, or R8/D8.

---

## 2.1 Directory & naming discipline (prevents AAPT errors)

**Folders**

```
lib/
  src/
    core/            # theme, routing, constants, utilities
    features/
      training/
      mindfulness/
      progress/
      profile/
    services/        # audio, notifications, analytics
    data/            # repositories, DAOs, models
    widgets/         # shared UI components
assets/
  animations/        # lottie/JSON or sprite sheets
  images/            # PNG/WebP (no spaces; lowercase)
  audio/
    ambient/
    sfx/
```

**Rules**

* **Filenames:** lowercase, hyphen-separated, ASCII only (e.g., `calm-breath-10m.json`, `wind-loop.ogg`).
* **No spaces** or `@#%&()` in names.
* Keep long audio in `assets/audio/ambient/`; short cues in `assets/audio/sfx/`.

---

## 2.2 Register assets in `pubspec.yaml` (safe pattern)

1. Add only the folders you actually created:

```
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/
    - assets/audio/ambient/
    - assets/audio/sfx/
```

2. Indentation is **2 spaces**. Tabs or mis‑indent = silent asset failures.
3. After editing: `flutter pub get` → `flutter clean` → quick run to verify no missing-asset exceptions.

---

## 2.2.1 Working with temporarily missing media (safe-by-default)

You can ship and build **before** animations/audio are downloaded.

**Do this now**

* Ensure the folders exist: `assets/animations/`, `assets/audio/ambient/`, `assets/audio/sfx/` (add a `.gitkeep` in each).
* Keep the `pubspec.yaml` folder entries exactly as in §2.2. Empty folders are fine.
* Do **not** list individual files until they actually exist.

**Guarded asset access (no exceptions if files aren’t there)**

```dart
import 'package:flutter/services.dart' show rootBundle;

Future<bool> assetExists(String path) async {
  try { await rootBundle.load(path); return true; } catch (_) { return false; }
}
```

**Animations**

* Before loading Lottie/spritesheet, check `assetExists()`. If false, render a simple fallback (e.g., `AnimatedOpacity`/`ScaleTransition`).
* Log once per session so you can verify which assets are missing.

**Audio** (service stub behavior)

* In `AudioService.play(String assetPath, {bool loop = false})`:

  * If `!await assetExists(assetPath)`, return immediately (no-op) and log a single warning.
  * When files are added later, no code changes—just rebuild and the service will start playing.

**Result**

* Debug and release builds work with empty media folders.
* Users see graceful fallbacks instead of crashes.

---

## 2.3 Android module defaults (`android/app/build.gradle[.kts]`)

Ensure these are set inside the `android { }` block:

* **namespace** = your package id
* **compileSdk = 35**
* **defaultConfig** → `minSdk = 24`, `targetSdk = 35`.
* **multiDex**: leave **off** unless you exceed 64K methods after adding many plugins. If needed:

  * `multiDexEnabled true` in `defaultConfig`
  * Add `implementation("androidx.multidex:multidex:2.0.1")`

**Packaging options** (preempt duplicate META‑INF collisions):

```
android {
  packagingOptions {
    resources {
      excludes += [
        "META-INF/{AL2.0,LGPL2.1}",
        "META-INF/*.kotlin_module",
        "META-INF/LICENSE*",
        "META-INF/NOTICE*"
      ]
    }
  }
}
```

---

## 2.4 Shrinker & resource shrink (release only)

In the `buildTypes { release { ... } }` block:

```
minifyEnabled true
shrinkResources true
proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
```

Create an **empty** `android/app/proguard-rules.pro` to start. Only add rules when the shrinker complains. (We’ll collect rules as you integrate Lottie/ExoPlayer/etc.)

---

## 2.5 Common Gradle pitfalls and the one‑line fixes

* **Duplicate META‑INF files** during `:merge…Resources` → use the **packagingOptions** above.
* **`AAPT: error: failed to compile`** → asset path invalid (spaces/uppercase) or corrupt file; rename/replace.
* **`Dexing/Transform` failures** → wrong JDK or AGP; confirm JDK 17 and AGP/Gradle versions from Step 1; run `./android/gradlew --stop && rm -rf ~/.gradle/caches`.
* **`minSdk` mismatch** from a plugin → raise `minSdk` to 24 or higher (don’t fight old libs).
* **`.so` collision (mergeNativeLibs)`** → two plugins ship the same native lib; remove the redundant plugin or exclude the lib via `packagingOptions { jniLibs { excludes += \["**/libfoo.so"] } }\`.
* **R8 removes reflection‑used classes** → add specific `-keep class ... { *; }` rules *only* when you see ClassNotFound at runtime.

---

## 2.6 Build flow to prove hygiene

1. `flutter clean && flutter pub get`
2. Kill daemons: `./android/gradlew --stop`
3. Debug build: `flutter run -d emulator` (verifies AAPT/assets quickly)
4. Release test (no signing): `flutter build apk --release -v`
5. If step 4 fails, fix the **first** red error above any long stacktrace; rebuild. Do not shotgun-edit multiple files at once.

---

## 2.7 Go/No‑Go checklist for Step 2

* [ ] Assets registered with correct indentation
* [ ] File names clean (lowercase, ASCII, no spaces)
* [ ] `compileSdk/targetSdk=35`, `minSdk=24`
* [ ] `packagingOptions` added
* [ ] Release build with shrinker **succeeds** (`flutter build apk --release`)

— End of Step 2 —

# Step 3 — Animations & Audio Pipeline (no‑drama wiring)

**Objective:** implement animations and audio with graceful fallbacks, low latency, and predictable behavior on Android. Keep it modular so Claude can plug media in later without touching Gradle.

---

## 3.1 Animation strategy (Lottie + sprite sheets)

**Use cases**

* **Mindfulness visuals** (breathing, body scan, calm pulses): **Lottie** JSON.
* **Badges/tiles/grids**: **sprite sheets** (static or short loops), or simple Flutter tweens if effects are minimal.

**Packages**

* `lottie` for JSON animations.
* **Avoid heavy engines** unless needed; start with Flutter’s built‑in animation widgets for pulses/fades/moves.

**Folder & naming**
`assets/animations/` → `breath-4-7-8.json`, `calm-pulse.json`, `sleep-waves.json`, etc.

**Widget contract (Claude to implement)**

* `BreathLottie({required String assetPath, Duration? duration, double? speed})`

  * Checks `assetExists(assetPath)` (§2.2.1). If false → fallback: `AnimatedScale/Opacity` slow pulse.
  * Exposes `play()`, `pause()`, `setSpeed()`, and disposes its controller.
* `SpriteSequence({required String sheetPath, required Size frameSize, required int frameCount, Duration frameDuration, bool loop = true})`

  * Decodes once, uses `Image` cache; guard with `assetExists()`; fallback renders the first frame or a static icon.

**Performance rules**

* Limit simultaneous Lottie instances to **≤2** per screen.
* Precache next‑screen animations in `didChangeDependencies()` with `precacheImage` when navigating.
* Target stable frame times: keep Lottie complexity moderate; avoid 4K raster layers.

---

## 3.2 Audio strategy (simple SFX + looped ambience)

**Use cases**

* **SFX/UI**: taps, ticks, completion sounds → short, low‑latency.
* **Ambience/Guides**: wind, waves, soft music, spoken guidance → long loops, smooth fades.

**Packages**

* `just_audio` for robust playback (ExoPlayer under the hood on Android).
* `audio_session` to request audio focus / ducking correctly.

> If you only need very simple one‑shot sounds and no background behavior, `audioplayers` is acceptable. This plan assumes `just_audio` + `audio_session` for stability.

**Folder & naming**
`assets/audio/ambient/` → `ocean-loop.ogg`, `rain-soft.ogg`, `night-wind.opus`
`assets/audio/sfx/` → `tap.ogg`, `success.ogg`, `fail.ogg`

---

## 3.3 AudioService (Claude to implement)

**Class:** `AudioService` (singleton) in `lib/src/services/audio_service.dart`

**Dependencies:** `just_audio`, `audio_session`

**Responsibilities**

* Manage one **ambience** player (loopable) and one **sfx** player (short, fire‑and‑forget).
* Request/release audio focus via `audio_session`.
* Respect system interruptions (calls/alarms), obey ringer/Do Not Disturb where possible.
* Provide soft fail when assets missing (§2.2.1).

**Public API**

```dart
class AudioService {
  static final AudioService I = AudioService._();
  AudioService._();

  Future<void> init();
  Future<void> playAmbience(String assetPath, {double volume = 0.6, bool loop = true, Duration fadeIn = const Duration(milliseconds: 600)});
  Future<void> stopAmbience({Duration fadeOut = const Duration(milliseconds: 600)});
  Future<void> setAmbienceVolume(double volume, {Duration? ramp});

  Future<void> playSfx(String assetPath, {double volume = 1.0});
  Future<void> dispose();
}
```

**Behavior notes**

* `init()` sets up `AudioSession`, config = `speech/music` depending on context, enables ducking.
* `playAmbience()`

  * If `!assetExists(assetPath)` → **no‑op** + log once.
  * Use `setAsset()`; if `loop`, set `LoopMode.one`.
  * Apply fade‑in by ramping `setVolume()` from 0 → desired volume.
* `stopAmbience()` fades out then stops.
* `playSfx()` checks asset; if exists, uses a short‑lived separate player or a shared pool; no fade required.
* Ensure `dispose()` is called on app shutdown.

**Edge cases handled**

* **Focus loss transient** (notifications): auto‑duck ambience to \~0.2, restore after.
* **Focus loss permanent** (another app starts media): stop ambience.
* **Headphone unplug**: pause ambience.

---

## 3.4 MindfulnessSession engine hooks

**Session controller** `MindfulnessController` in `lib/src/features/mindfulness/`:

* Holds selected technique, duration, chosen ambience and/or guidance track.
* On `start()`:

  1. Start timer (5/10/15/30).
  2. `AudioService.I.playAmbience(selectedTrack, loop: true, fadeIn: 800ms)`.
  3. Kick the primary animation widget (Lottie or pulse).
* On `pause()`:

  * Pause animation timeline; reduce ambience volume with ramp to \~0.2
* On `resume()`:

  * Restore volume to prior level over 400ms; resume animation
* On `complete()` or `cancel()`:

  * `AudioService.I.stopAmbience(fadeOut: 800ms)`; persist session record.

**Low‑latency SFX**

* Optional taps/breath ticks: call `AudioService.I.playSfx()` on beat markers; guard behind a user setting.

---

## 3.5 Background playback (optional, phase‑later)

If you need **screen‑off** guidance with notifications/lock screen controls:

* Add `audio_service` and promote ambience/guidance to a foreground task.
* Define a minimal media notification (title, stop/pause).
* This adds manifest/service code; postpone until core features are stable.

---

## 3.6 ProGuard/R8 starter rules (only if needed)

Create `android/app/proguard-rules.pro` (already referenced in Step 2). Add rules **only** when shrinker removes reflectively used classes. Example placeholders (do not add blindly):

```
# just_audio / ExoPlayer types are usually kept via consumer rules; add only on error.
#-keep class com.google.android.exoplayer2.** { *; }
#-dontwarn com.google.android.exoplayer2.**

# Lottie is typically safe; add rules only if you see ClassNotFound in release.
#-keep class com.airbnb.lottie.** { *; }
```

---

## 3.7 Testing & QA checklist (animations/audio)

* [ ] Animations render with media present; fallback pulse shows when file missing.
* [ ] Only one ambience track plays at a time; starting a new one fades the previous out.
* [ ] Volume ramps are smooth (no clicks/pops).
* [ ] SFX trigger latency < 50ms on mid‑tier device.
* [ ] Phone call/notification ducking works; ambience resumes afterward.
* [ ] App background/foreground life cycle doesn’t leak players (no extra audio after exit).
* [ ] Release build with shrinker still plays audio & animations.

— End of Step 3 —

# Step 4 — Data & Analytics Backbone (models → storage → charts)

**Objective:** persist everything locally first (privacy‑first), keep write paths bulletproof, and expose read models optimized for charts and streaks. Cloud sync can be layered later without changing call sites.

---

## 4.1 Storage choices (pick one; both are stable)

* **SQLite via `sqflite`**: lightweight, manual SQL/DAOs. Easiest to reason about.
* **SQLite via `drift`**: typed schema, migrations, query helpers. Slightly heavier; safer migrations.

> Default to **`sqflite`** unless you want typed queries. Either way, keep a repository layer so you can swap later.

**Additional stores**

* **SharedPreferences**: UI prefs (theme, haptics, audio on/off, last tab).
* **SecureStorage**: sensitive tokens or encrypted export keys.
* **File storage**: JSON exports of sessions for backup/import.

---

## 4.2 Schema (minimum viable tables)

### users

* `id TEXT PRIMARY KEY`
* `name TEXT`
* `date_joined INTEGER` (epoch ms)

### achievements

* `id TEXT PRIMARY KEY`
* `name TEXT`
* `description TEXT`
* `type TEXT`
* `progress INTEGER`
* `target INTEGER`
* `date_earned INTEGER NULL`
* `icon_path TEXT`

### training\_sessions

* `id TEXT PRIMARY KEY`
* `timestamp INTEGER`
* `exercise_id TEXT`
* `level TEXT`
* `duration_ms INTEGER`
* `score INTEGER`
* `performance_json TEXT`  // blob of metrics

### mindfulness\_sessions

* `id TEXT PRIMARY KEY`
* `timestamp INTEGER`
* `session_type TEXT`      // breathing/body-scan/etc
* `duration_ms INTEGER`
* `guidance_audio TEXT NULL`
* `ambient_audio TEXT NULL`
* `config_json TEXT`       // breath ratios, etc.

### analytics\_daily

* `day TEXT PRIMARY KEY`   // YYYY-MM-DD
* `training_minutes INTEGER DEFAULT 0`
* `mindfulness_minutes INTEGER DEFAULT 0`
* `sessions_count INTEGER DEFAULT 0`
* `streak INTEGER DEFAULT 0`

**Indexes**

* `training_sessions(timestamp)`
* `mindfulness_sessions(timestamp)`
* `analytics_daily(day)`

---

## 4.3 Repositories (Claude to implement)

Create `lib/src/data/` repos with interfaces:

```dart
abstract class TrainingRepo {
  Future<void> saveSession(TrainingSession s);
  Future<List<TrainingSession>> list({DateTime? from, DateTime? to});
  Future<int> bestScore(String exerciseId);
}

abstract class MindfulnessRepo {
  Future<void> saveSession(MindfulnessSession s);
  Future<List<MindfulnessSession>> list({DateTime? from, DateTime? to});
}

abstract class AnalyticsRepo {
  Future<void> bumpDaily({required DateTime when, int trainingMin = 0, int mindfulnessMin = 0});
  Future<AnalyticsDaily?> getDay(String ymd);
  Future<List<AnalyticsDaily>> lastNDays(int n);
}
```

**Notes**

* Enforce all writes through repos (no direct DB writes from UI).
* Add simple retry/transaction wrappers; never partially write a session.

---

## 4.4 Session logging flow (single source of truth)

When a **Training** or **Mindfulness** session completes:

1. Construct the domain object with exact timestamps.
2. Repo `.saveSession(...)` (single transaction):

   * Insert into `*_sessions`.
   * Upsert `analytics_daily` row for `YYYY-MM-DD`.
   * Recompute `streak` (see §4.5) and store it in `analytics_daily`.
3. Post an in‑app event (e.g., `Bus.emit(SessionSaved)`) so dashboards can refresh.

If the app crashes mid‑session, on next launch check an in‑progress flag and either discard or finalize with partial credit.

---

## 4.5 Streak logic (deterministic & testable)

* Streak = count of **consecutive days** with `sessions_count > 0` ending **today**.
* On write, compute:

  * If `today has activity` and `yesterday had activity` → `streak = yesterday.streak + 1`.
  * If `today has activity` and `yesterday had none` → `streak = 1`.
  * If `today has none` → streak remains what yesterday had (for read models, compute on demand).
* Unit tests cover month/year boundaries and DST.

---

## 4.6 Progress & charts adapter (UI‑friendly queries)

Expose pre‑digested series for the dashboard so charts don’t know SQL:

```dart
class ProgressSeries {
  final List<Point<DateTime,int>> trainingMinutes;
  final List<Point<DateTime,int>> mindfulnessMinutes;
  final List<Point<DateTime,int>> sessionsCount;
  final int currentStreak;
}
```

* `AnalyticsRepo.lastNDays(30)` → convert to `ProgressSeries`.
* Provide an additional `CategoryBreakdown` for training by `exercise_id`.

---

## 4.7 Preferences & privacy controls

* `SharedPreferences` keys: `themeMode`, `haptics`, `audioEnabled`, `notificationsEnabled`, `mindfulnessTicksEnabled`.
* Privacy toggle: **Analytics on device only** (default). Add an opt‑in for cloud sync later.
* Export/Import:

  * **Export** creates a ZIP with JSON dumps of each table + a manifest; store in app documents.
  * **Import** validates manifest version and does an all‑or‑nothing restore in a transaction.

---

## 4.8 Migrations (future‑proof)

* Keep a `db_version` in `PRAGMA user_version`.
* Maintain a `migrations/` folder with numbered scripts or Dart functions (`from=1→2`, `2→3`, ...).
* On startup, run migrations sequentially inside a single transaction; if any step fails, rollback and show a user‑friendly error.

---

## 4.9 Testing checklist (data layer)

* [ ] Create DB fresh → write 1 training + 1 mindfulness → daily row upserts correctly.
* [ ] Streak increments across multiple days; breaks correctly after a gap.
* [ ] Export/Import roundtrip reproduces identical row counts and checksums.
* [ ] Repos never throw on null/empty optional fields.
* [ ] Release build passes with shrinker on (no reflection issues).

— End of Step 4 —

# Step 5 — Training Module (framework, timers, difficulty, scoring)

**Objective:** a modular exercise framework with consistent lifecycle, timers, difficulty scaling, scoring, and analytics hooks. Each game implements a small interface; the shell handles UI and persistence.

---

## 5.1 Exercise abstraction

**Interface** `ExerciseEngine` (in `lib/src/features/training/core/`):

```dart
abstract class ExerciseEngine {
  String get id;              // e.g., "mem_pattern_01"
  String get name;            // UI display name
  ExerciseCategory get category; // memory/focus/problem/speed

  Future<void> prepare(DifficultyLevel level); // preload assets/state
  void start();               // begin round
  void pause();               // optional
  void resume();              // optional
  void submit(dynamic input); // user answer/interaction
  bool get isComplete;        // round over?
  ExerciseResult buildResult(); // score, duration, metadata
  void dispose();
}
```

**Data types** (shared): `ExerciseCategory`, `DifficultyLevel { easy, medium, hard, expert }`, `ExerciseResult { score:int, duration:Duration, details:Map }`.

---

## 5.2 Shell widget & lifecycle

**Widget** `ExerciseRunner(engine: ExerciseEngine, level: DifficultyLevel)`

* Orchestrates: `prepare → start → collect input → complete → buildResult → persist → next`.
* Displays: header, timer, score-on-the-fly (if applicable), pause/quit.
* Emits `TrainingSession` to repo on completion (§4.4).

**Contract**

* Engines are **pure Dart**; no platform channels.
* UI components read engine state via `ValueNotifier/ChangeNotifier` or streams.

---

## 5.3 Timers & pacing

**TimerService** (reusable):

* Start/stop/reset; exposes `remaining`, `elapsed` as `ValueNotifier`.
* Supports **countdown** (e.g., 60s) and **per‑question** time caps.
* Low‑jitter implementation using `Ticker`/`TickerProvider` rather than `Timer.periodic`.

**UX rules**

* Always show a visible countdown for time‑boxed tasks.
* Provide a 3‑2‑1 pre‑roll for speed tests.

---

## 5.4 Difficulty scaling (deterministic)

* **easy**: small grids / fewer items / longer time / simpler distractors.
* **medium**: moderate size / mixed distractors.
* **hard**: larger sets / tighter time / similar‑looking distractors.
* **expert**: maximal set size / shortest time / near‑duplicate distractors.

Implement via a **`DifficultyProfile`** struct per exercise:

```dart
class DifficultyProfile {
  final int setSize;        // items or grid
  final Duration timeLimit; // total or per question
  final double noise;       // distractor intensity 0..1
}
```

Provide `profileFor(level)` in each engine.

---

## 5.5 Scoring model (consistent across games)

`score = base + speedBonus + streakBonus - penalty`

* **base**: points per correct action (exercise‑specific).
* **speedBonus**: linear or piecewise based on remaining time.
* **streakBonus**: within‑session consecutive correct answers.
* **penalty**: wrong attempts / hints used.

**Constraints**

* Clamp to ≥0.
* Serialize `details` explaining how the score was formed (transparent analytics).

---

## 5.6 Built‑ins to implement first (thin engines)

1. **Pattern recognition (Memory)**

   * Show N symbols briefly → hide → user reconstructs order.
2. **Sequence memorization (Memory)**

   * Simon‑style repeats; grows by 1 each turn until mistake.
3. **Attention filter (Focus)**

   * Stream of symbols; tap only targets, ignore distractors.
4. **Reaction time (Speed)**

   * Random delay → GO signal; record ms reaction; repeat K trials.
5. **Logic mini (Problem)**

   * 1‑step pattern completion from a small bank.

Each must expose a `prepare(level)` that builds the round deterministically from a seeded RNG (`seed = now.millisecondsSinceEpoch` or provided seed for tests).

---

## 5.7 Persistence & analytics hooks

On completion (`isComplete → true`):

1. Construct `TrainingSession` with `exerciseId`, `level`, `duration`, `score`, `performance` (JSON metrics: accuracy, reaction\_mean, false\_positives, etc.).
2. `TrainingRepo.saveSession(session)` → updates daily analytics (§4.4).
3. Emit `SessionSaved` event for dashboards.

---

## 5.8 UI skeleton (Claude to implement)

**Screens**

* `TrainingHome` (tabs by category, daily challenge entry)
* `ExerciseCatalog` (grid of exercises with lock states)
* `ExerciseRunner` (header, timer, engine viewport, footer controls)
* `ResultsSheet` (score, breakdown, personal best compare, retry/next)

**Daily challenge**

* Picks 3 exercises (rotating categories), fixed seeds; posts a combined score and bonus badge on completion.

---

## 5.9 Tests (unit + widget)

* **Engine unit tests**: deterministic with fixed seed; verify scoring math and completion conditions.
* **TimerService**: simulated tick progression; ensures no drift > 1 tick per minute.
* **Runner widget**: golden tests for header/timer layout; ensures pause/resume keeps state.

---

## 5.10 Performance rules

* Avoid setState storms: engines push updates via notifiers.
* Reuse painters and text layouts where possible.
* Keep per‑frame allocations near zero (profile with `flutter devtools`).

— End of Step 5 —

# Step 6 — Mindfulness Module (session engine, breathing, visuals + audio)

**Objective:** deliver guided sessions (breathing/body scan/focused attention/sleep/stress/anxiety/emergency) with precise timers, optional guidance audio + ambience, and resilient fallbacks if media is missing. All sessions share one controller pattern.

---

## 6.1 Session types & taxonomy

Define enum `SessionType { breathing, bodyScan, focusedAttention, lovingKindness, sleepPrep, stressRelief, anxietyEase, emergencyCalm }`

Each `SessionType` maps to a **protocol** describing visuals, audio, and timing knobs. Keep protocols in JSON for easy tweaks.

---

## 6.2 Session protocol (config JSON)

Store per‑session configs under `assets/animations/` or `assets/config/` (your choice). Example shape (not code, just schema):

```
{
  "type": "breathing",
  "displayName": "4‑7‑8 Breath",
  "durations": [300, 600, 900, 1800],   // seconds: 5/10/15/30m
  "breath": { "inhale": 4, "hold": 7, "exhale": 8, "cycles": null },
  "visual": { "lottie": "breath-4-7-8.json", "fallback": "pulse" },
  "audio": { "ambience": "night-wind.opus", "guidance": "478-voice.mp3" },
  "ticks": { "enabled": false }
}
```

**Rules**

* Any media path may be absent at runtime (§2.2.1) → fallbacks apply.
* Durations picklist must include 5/10/15/30 minutes for parity with spec.

---

## 6.3 Controller contract (Claude to implement)

**Class** `MindfulnessController` (per active session):

* `MindfulnessController(this.protocol, {required Duration total});`
* `start()`, `pause()`, `resume()`, `cancel()`, `complete()`
* Exposes `elapsed`, `remaining`, `phase` (e.g., inhale/hold/exhale), and `progress 0..1`.
* Emits lifecycle events for analytics (§4.4) and UI.

**Breathing phases**

* For `breathing` type, controller cycles `inhale → hold → exhale`, respecting exact seconds (use `Ticker`‑based clock, not `Timer.periodic`).
* Optional “tick” SFX per phase boundary via `AudioService.playSfx()`; behind a user pref.

---

## 6.4 Visuals glue

**Primary widget** `MindfulnessView(controller)`

* If protocol visual has a Lottie asset and `assetExists()` → render Lottie bound to phase/speed.
* Else → render fallback pulse/scale that matches breath cadence (inhale = scale up; exhale = scale down; hold = steady).
* Keep Lottie instances ≤2 per screen; pre‑cache next if navigating.

---

## 6.5 Audio glue

On `start()`

1. If protocol has `guidance` and user enabled guidance → play it once (non‑loop), volume 0.9.
2. If protocol has `ambience` → start loop with fade‑in (0.6 volume).
3. If both, duck ambience by −6 dB during voice guidance.

On `pause()` → ramp ambience to 0.2.
On `resume()` → ramp back to previous.
On `complete()/cancel()` → fade‑out and stop.

Handle interruptions (calls/alarms) via `audio_session` focus events (§3.3).

---

## 6.6 Emergency calm (fast path)

**Scenario:** user taps “I’m spiraling” → 60–180s protocol with immediate effect.

* Visual: fast‑to‑slow breathing (e.g., 3‑3‑4 → 4‑4‑6 over first minute) or box‑breathing 4‑4‑4‑4.
* Audio: soft “grounding” ambience; optional voice snippet (“You’re safe. Breathe with me.”) if enabled.
* UI reduces chrome; large centered rhythm, single stop button.

---

## 6.7 Offline media packs (optional, phase‑later)

* Keep a manifest listing available files and SHA‑256 checksums.
* Download packs to app documents dir; update a local index.
* `AudioService` and animation loaders first check documents dir, then bundled assets.

---

## 6.8 Notifications & reminders

* Daily/weekly reminder schedule managed by a `ReminderService` (wrapping `flutter_local_notifications`).
* Tapping a reminder deep‑links into a preselected protocol (e.g., “10‑minute 4‑7‑8”).
* Respect DND hours; user can snooze for 24h.

---

## 6.9 Accessibility & inclusivity

* Voice guidance transcripts available; large text option.
* Haptic cues (short pulses) can mirror breath phases when audio is off.
* Color‑blind‑friendly visuals; avoid meaning conveyed purely by color.

---

## 6.10 Persistence & analytics

On `complete()`

* Save `MindfulnessSession` (type, duration, chosen ambience/guidance, config JSON snapshot).
* Bump daily analytics minutes/streak (§4.4/§4.5).

---

## 6.11 Tests (mindfulness)

* Controller phase timing within ±1 tick over long runs.
* Pause/resume preserves phase and remaining time.
* Fallback visuals render when assets are missing.
* Audio ducking/restore verified via mocked `AudioService` calls.

— End of Step 6 —

# Step 7 — Progress Dashboard (series → charts, badges, records, streaks)

**Objective:** turn stored analytics into clear visuals and summaries. Keep adapters thin so chart widgets never touch SQL. Everything must render even with sparse data (day 1 users).

---

## 7.1 Data adapters (UI‑friendly)

Use §4.6 `ProgressSeries` as the single input for charts. Add convenience mappers:

```dart
class ProgressAdapters {
  static LineChartModel minutesSeries(ProgressSeries s);     // training + mindfulness
  static BarChartModel sessionsPerDay(ProgressSeries s);     // last 7/30 days
  static RadarChartModel skillRadar(Map<String,int> skillLv); // from UserProfile
  static PieModel timeDistribution(ProgressSeries s);        // training vs mindfulness share
}
```

These models are plain Dart structs consumed by chart widgets.

---

## 7.2 Screens & cards (Claude to implement)

**ProgressHome** (scrollable):

* **Summary strip**: today’s minutes, current streak, personal record badges.
* **Line chart**: minutes over time (toggle 7/30/90 days).
* **Bar chart**: sessions/day (last 14 or 30 days).
* **Radar**: skill levels (from `UserProfile.skillLevels`).
* **Achievements carousel**: earned badges with dates.
* **Time distribution**: pie or donut (training vs mindfulness minutes).

Each card is a reusable widget with `isEmpty` state to render placeholders when data is missing.

---

## 7.3 Streak & records display

* **Streak pill**: big number, tooltip explains rules (§4.5). If zero, show “Start today” CTA.
* **Personal bests**: per exercise `bestScore(exerciseId)` (§4.3). Show delta vs last session (+/−).
* **Daily goal** (optional): 10/20/30 minutes target; ring fills as minutes accrue.

---

## 7.4 Achievements system (minimal viable)

* Triggered by repository writes (no polling).
* Examples:

  * **First Steps**: first completed session.
  * **Focused Ten**: 10 minutes mindfulness in a day.
  * **Consistency 7**: 7‑day active streak.
  * **Sharpshooter**: 90% accuracy in an attention task.
* When unlocked: persist `Achievement` (§Data Models) and show a non‑blocking toast/sheet.

---

## 7.5 Charts implementation notes

* Use a lightweight chart package or custom painters to avoid bloat.
* Always clamp/clean series: fill missing days with zeros so axes don’t jump.
* Prefer integer ticks for days; format dates as locale short (Mon, Tue…).
* Dark/light aware; ensure colors meet contrast.

**Empty states**

* Line/Bar: show dotted baseline + hint text (e.g., “No data yet — time to train”).
* Radar: gray outline with “Set your first goals”.

---

## 7.6 Navigation glue

* Cards link to detail screens: tapping minutes → calendar view; tapping sessions/day → list filtered by date; tapping radar → skill explanation.
* Deep links from notifications or post‑session sheets should land on ProgressHome with a highlight.

---

## 7.7 Export / Import hooks (from §4.7)

* Add “Export Data” and “Import Data” buttons in a settings sub‑page.
* After import success, navigate to ProgressHome and show a brief “Data restored” banner.

---

## 7.8 Testing checklist (dashboard)

* [ ] Adapters generate monotonic day labels; missing days zero‑filled.
* [ ] Charts render with 0, 1, and many points without exceptions.
* [ ] Streak pill logic matches §4.5 across month/year borders.
* [ ] Achievement fires exactly once per condition (idempotent).
* [ ] Dark mode colors legible; contrast ≥ WCAG AA.

— End of Step 7 —

# Step 8 — Profile & Settings (goals, schedule, prefs, backups, privacy)

**Objective:** capture user identity, targets, schedules, and preferences; wire notifications, backups, and privacy toggles — all without blocking core usage.

---

## 8.1 Profile model & screen

**Model** `UserProfile` (§Data Models) with:

* `name`, `dateJoined`
* `skillLevels` (Map category→int)
* `preferences` (struct below)
* `statistics` (denormalized quick reads like total minutes)

**Screen** `ProfileHome`

* Header card with name and join date
* Achievements showcase (carousel)
* Goals & schedule quick‑edit
* Data summary (total minutes, sessions, best streak)

---

## 8.2 Preferences (SharedPreferences)

Keys and defaults:

* `themeMode` = system
* `haptics` = true
* `audioEnabled` = true
* `notificationsEnabled` = true
* `mindfulnessTicksEnabled` = false
* `dailyGoalMinutes` = 20

Expose a `PreferencesService` with getters/setters and `ValueNotifier` for live updates.

---

## 8.3 Goals & schedule

* **Daily goal minutes** (10/20/30 custom)
* **Training schedule** days (checkboxes Mon–Sun)
* **Mindfulness reminder** times (one or more)
* Use `flutter_local_notifications` for local reminders; store times in prefs.

---

## 8.4 Backups (export/import) (§4.7)

* Export: one‑tap ZIP to app documents; share sheet option.
* Import: file picker → validate → transaction restore.
* Post‑import banner and dashboard refresh.

---

## 8.5 Privacy controls

* **Analytics on device only** (default). Toggle: “Allow anonymous improvement data” (off by default; future cloud).
* **Clear data**: button to wipe tables after confirmation sheet.
* **Lock screen** (optional): simple app PIN before opening (store hashed in SecureStorage).

---

## 8.6 Settings screen structure (Claude to implement)

Sections:

* **Appearance**: theme, haptics
* **Audio**: enable/disable, ticks, volumes
* **Notifications**: training schedule, mindfulness times, DND window
* **Data**: export, import, clear data
* **Privacy & Security**: analytics toggle, optional PIN
* **About**: version, licenses, credits

---

## 8.7 Tests (profile & settings)

* [ ] Preferences persist across restarts; notifiers update bound widgets.
* [ ] Reminders schedule/cancel correctly when toggled.
* [ ] Export/import roundtrip restores profile and analytics.
* [ ] PIN lock (if enabled) blocks entry until correct.

— End of Step 8 —

# Step 9 — Build, Signing & Play Delivery (keystore, flavors, CI)

**Objective:** reproducible release builds with proper signing, size controls, and a dead‑simple CI path to AAB upload. Includes a fallback path if Gradle complains.

---

## 9.1 Versioning rules

* Keep **`pubspec.yaml`** as the single source of truth:

  * `version: 1.0.0+1`  → `versionName = 1.0.0`, `versionCode = 1`
* Increment **build number** (`+N`) every Play upload.
* Add a `scripts/bump_version.dart` later for automation.

---

## 9.2 Keystore (upload key)

**Create once** (outside repo, then copy the `.jks` into `android/app/` or a secure path):

```
keytool -genkeypair -v \
 -keystore mindtrainer-upload.jks \
 -keyalg RSA -keysize 2048 -validity 10000 \
 -alias upload
```

**`android/key.properties`** (do not commit real secrets):

```
storePassword=******
keyPassword=******
keyAlias=upload
storeFile=../app/mindtrainer-upload.jks
```

**`android/app/build.gradle[.kts]` signingConfigs**

```
signingConfigs {
  release {
    storeFile file(properties['storeFile'])
    storePassword properties['storePassword']
    keyAlias properties['keyAlias']
    keyPassword properties['keyPassword']
  }
}
buildTypes {
  release {
    signingConfig signingConfigs.release
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
  }
}
```

If alias already exists error: your keystore already has `upload`; skip `-genkeypair` and reuse the file.

---

## 9.3 Product flavors (optional)

Set up `dev` and `prod` to separate package IDs and icons:

```
flavorDimensions 'env'
productFlavors {
  dev  { dimension 'env'; applicationIdSuffix '.dev'; versionNameSuffix '-dev' }
  prod { dimension 'env' }
}
```

Build commands: `flutter build appbundle --flavor prod -t lib/main_prod.dart`

---

## 9.4 Release build commands (local)

1. Clean & get deps

```
flutter clean && flutter pub get
./android/gradlew --stop
```

2. Build **AAB** (preferred for Play):

```
flutter build appbundle --release \
  --split-debug-info=build/symbols \
  --obfuscate
```

3. Optional signed **APK** for testers:

```
flutter build apk --release
```

Artifacts end up in `build/app/outputs/bundle/release/` and `…/apk/release/`.

---

## 9.5 Size, symbols & mapping files

* `--split-debug-info` writes symbol maps to `build/symbols/` (keep for crash decoding).
* R8 mapping: `android/app/build/outputs/mapping/release/mapping.txt` (archive with each release).
* Remove unused locales/resources via shrinker (Step 2). Avoid shipping raw PSDs/PNGs—use WebP.

---

## 9.6 Play Console setup (first time)

* Create app → package name matches `applicationId`.
* Upload **AAB** from Step 9.4.
* Set target API (compile/target 35 from Step 1/2).
* Complete content rating, privacy policy URL, ads declaration, and data safety form.

---

## 9.7 CI (GitHub Actions minimal)

`.github/workflows/android-release.yml` (skeleton):

```
name: android-release
on:
  workflow_dispatch:
  push:
    tags: ['v*.*.*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: 'stable' }
      - name: Android SDK setup
        uses: android-actions/setup-android@v3
      - name: Decrypt keystore
        run: |
          mkdir -p android/app
          echo "$KEYSTORE_BASE64" | base64 -d > android/app/mindtrainer-upload.jks
      - name: Build AAB
        run: |
          flutter pub get
          flutter build appbundle --release \
            --split-debug-info=build/symbols --obfuscate
        env:
          JAVA_TOOL_OPTIONS: -Xmx3g
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with: { name: app-release.aab, path: build/app/outputs/bundle/release/*.aab }
```

Secrets to add: `KEYSTORE_BASE64`, and optionally `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` via `key.properties` injection.

---

## 9.8 Play upload automation (optional)

* Use Fastlane Supply or the Play Developer API to push the built AAB, changelog, and track (internal, alpha, prod). Wire later to avoid scope creep.

---

## 9.9 Troubleshooting matrix (build/signing)

* **`Build failed to produce an .apk/.aab`**

  * Re‑run with `-v` to capture the **first** failing task.
  * Confirm Step 1 versions (AGP/Gradle/JDK). Clear caches: `rm -rf ~/.gradle/caches && ./android/gradlew --stop`.
  * Check assets naming/paths (§2.1/§2.2). A single bad filename can break AAPT.
* **`Execution failed for task :app:minifyReleaseWithR8`**

  * Temporarily set `minifyEnabled false` to confirm it’s the shrinker. If fixed, add minimal keep rules for the class reported.
* **`Duplicate class` / dependency hell**

  * You pulled in overlapping plugins. Remove the newer/older one, or exclude transitive deps in Gradle `dependencies { implementation(project(':x')) { exclude group: 'com.y', module: 'z' } }`.
* **`Keystore/alias incorrect`**

  * `keytool -list -v -keystore mindtrainer-upload.jks` to inspect; update `key.properties` paths/passwords.
* **`minSdk` errors from plugins**

  * Raise to `minSdk 24` (or plugin’s stated min). Don’t fight it.
* **`uses-sdk:minSdkVersion` manifest merge conflicts\`**

  * Ensure your `defaultConfig.minSdk` ≥ every transitive AAR’s min; add `tools:overrideLibrary` only as last resort.

---

## 9.10 Release checklist

* [ ] `flutter test` and key widget tests pass
* [ ] Bump `version` in `pubspec.yaml`
* [ ] Clean build succeeds locally (AAB + mapping saved)
* [ ] Smoke test on 1–2 real devices (audio, animations, sessions)
* [ ] Upload to **Internal Testing** track first; invite testers
* [ ] Promote to **Closed**/**Open**/**Production** once checks pass

— End of Step 9 —

# Step 10 — Final QA & Troubleshooting Flow (pre‑launch)

**Objective:** the exact order to debug Gradle/APK/AAB issues, verify performance, and confirm user‑visible flows before Play submission.

---

## 10.1 Gradle/APK/AAB debugging order

1. **Clean env**: `flutter clean` → `./android/gradlew --stop` → delete `~/.gradle/caches` if needed.
2. **Doctor**: `flutter doctor -v` (fix JDK/SDK/AGP mismatches first).
3. **Debug run**: `flutter run` on device/emulator (AAPT/asset issues show faster here).
4. **Release w/o shrinker**: `minifyEnabled false` → `flutter build apk --release`.
5. **Enable shrinker**: turn `minifyEnabled true`; add only the keep rules from the last error.
6. **AAB build**: `flutter build appbundle --release --split-debug-info=build/symbols --obfuscate`.

---

## 10.2 Performance checks (mid‑tier Android)

* **Startup** < 2.5s cold; < 1.2s warm.
* **Frame times** steady at 60fps on animation screens.
* **Jank**: profile with `flutter devtools`; fix largest offenders first (layout thrash, image decode on main thread, too many Lottie layers).
* **Audio**: no clicks/pops on start/stop; ducking works.

---

## 10.3 User flows to smoke test

* Onboarding → set goal → run a training session → save → check Progress.
* Mindfulness 10m with ambience + guidance → pause/resume → complete.
* Export data → uninstall → reinstall → import data → confirm charts.
* Toggle dark/light → notifications schedule + deep link.

---

## 10.4 Pre‑launch pack

* Changelog text for the store.
* 6–8 screenshots (dark & light), 1 short promo video if available.
* Privacy policy URL and Data Safety form answers.
* Contact email and support link.

— End of Step 10 —
