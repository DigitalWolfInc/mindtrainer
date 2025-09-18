import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'payments/paywall_view.dart';
import 'settings/settings_view.dart';
import 'achievements/achievements_view.dart';
import 'features/home/today_screen.dart';
import 'shell/tab_shell.dart';
import 'core/feature_flags.dart';
import 'ui/mtds/mtds.dart';
import 'ui/mtds/showcase/showcase.dart';
import 'auth/auth_gate.dart';
import 'account/account_screen.dart';
import 'auth/register_screen.dart';
import 'auth/forgot_password_screen.dart';
import 'features/journal/new_text_screen.dart';
import 'features/journal/new_voice_screen.dart';
import 'features/journal/new_photo_screen.dart';
import 'features/journal/search_screen.dart';
import 'features/journal/export_screen.dart';
import 'features/journal/private_screen.dart';
import 'features/coach/coach_screen.dart';
import 'features/coach/triage_screen.dart';
import 'features/coach/sos_screen.dart';
import 'features/coach/pro_screen.dart';
import 'features/tools/calm_breath_screen.dart';
import 'features/animals/animal_badges_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindTrainer',
      theme: FeatureFlags.mtdsThemeEnabled 
          ? MtdsTheme.midnightCalm()
          : ThemeData(
              primarySwatch: Colors.indigo,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
      home: FeatureFlags.authPasskeyEnabled 
          ? const AuthGate()
          : const SplashScreen(),
      routes: {
        '/today': (context) => const TodayScreen(),
        '/journal': (context) => const _JournalStub(),
        '/focus': (context) => const _FocusStub(),
        '/tools': (context) => const _ToolsStub(),
        '/me': (context) => const SettingsView(appVersion: '1.0.0'),
        '/paywall': (context) => const PaywallView(),
        '/settings': (context) => const SettingsView(appVersion: '1.0.0'),
        '/achievements': (context) => const AchievementsView(),
        '/account': (context) => const AccountScreen(),
        
        // Journal routes
        '/journal/newText': (context) => const JournalNewTextScreen(),
        '/journal/newVoice': (context) => const JournalNewVoiceScreen(),
        '/journal/newPhoto': (context) => const JournalNewPhotoScreen(),
        '/journal/search': (context) => const JournalSearchScreen(),
        '/journal/exports': (context) => const JournalExportScreen(),
        '/journal/private': (context) => const JournalPrivateScreen(),
        
        // Coach routes
        '/coach': (context) => const CoachScreen(),
        '/coach/triage': (context) => const CoachTriageScreen(),
        '/sos': (context) => const SosScreen(),
        '/coach/pro': (context) => const CoachProScreen(),
        
        // Auth routes
        '/auth/register': (context) => const RegisterScreen(),
        '/auth/forgot': (context) => const ForgotPasswordScreen(),
        
        // Regulate tools routes
        '/tools/calm-breath': (context) => const CalmBreathScreen(),
        '/tools/phys-sigh': (context) => const _PhysSighStub(),
        '/tools/grounding-54321': (context) => const _Grounding54321Stub(),
        '/tools/body-unclench': (context) => const _BodyUnclenchStub(),
        
        // Think tools routes  
        '/tools/name-thought': (context) => const _NameThoughtStub(),
        '/tools/evidence-check': (context) => const _EvidenceCheckStub(),
        '/tools/perspective-flip': (context) => const _PerspectiveFlipStub(),
        
        // Do tools routes
        '/tools/tiny-next-step': (context) => const _TinyNextStepStub(),
        '/tools/energy-map': (context) => const _EnergyMapStub(),
        
        // Rest tools routes
        '/tools/wind-down': (context) => const _WindDownStub(),
        '/tools/brain-dump': (context) => const _BrainDumpStub(),
        '/sleep/body-scan': (context) => const _BodyScanStub(),
        '/sleep/sounds': (context) => const _SleepSoundsStub(),
        
        // Overflow routes
        '/history': (context) => const _HistoryStub(),
        '/analytics': (context) => const _AnalyticsStub(),
        '/achievements/animals': (context) => const AnimalBadgesScreen(),
        '/checkin/animal': (context) => const _AnimalCheckinStub(),
        
        // Debug-only routes
        if (kDebugMode && FeatureFlags.mtdsShowcaseEnabled)
          '/mtds-showcase': (context) => const MtdsShowcase(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Stub screens for new routes
class _JournalStub extends StatelessWidget {
  const _JournalStub();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Journal feature coming soon', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _CoachStub extends StatelessWidget {
  const _CoachStub();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talk to Coach')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Coach feature coming soon', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _FocusStub extends StatelessWidget {
  const _FocusStub();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Session')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timelapse_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Focus session feature coming soon', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _ToolsStub extends StatelessWidget {
  const _ToolsStub();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tools feature coming soon', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// Journal route stubs
class _JournalNewTextStub extends StatelessWidget {
  const _JournalNewTextStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Text Entry')),
      body: const Center(child: Text('Text journal coming soon')),
    );
  }
}

class _JournalNewVoiceStub extends StatelessWidget {
  const _JournalNewVoiceStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Voice Entry')),
      body: const Center(child: Text('Voice journal coming soon')),
    );
  }
}

class _JournalNewPhotoStub extends StatelessWidget {
  const _JournalNewPhotoStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Photo Entry')),
      body: const Center(child: Text('Photo journal coming soon')),
    );
  }
}

class _JournalHistoryStub extends StatelessWidget {
  const _JournalHistoryStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal History')),
      body: const Center(child: Text('Journal history coming soon')),
    );
  }
}

// Coach route stubs
class _SosStub extends StatelessWidget {
  const _SosStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Help')),
      body: const Center(child: Text('SOS feature coming soon')),
    );
  }
}

class _CoachProStub extends StatelessWidget {
  const _CoachProStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Pro')),
      body: const Center(child: Text('Coach Pro coming soon')),
    );
  }
}

class _CoachTriageStub extends StatelessWidget {
  const _CoachTriageStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Triage')),
      body: const Center(child: Text('Coach triage coming soon')),
    );
  }
}

// Regulate tool stubs
class _CalmBreathStub extends StatelessWidget {
  const _CalmBreathStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calm Breath')),
      body: const Center(child: Text('Calm breath tool coming soon')),
    );
  }
}

class _QuickCoherenceStub extends StatelessWidget {
  const _QuickCoherenceStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Coherence')),
      body: const Center(child: Text('Quick coherence coming soon')),
    );
  }
}

class _ExtendedExhaleStub extends StatelessWidget {
  const _ExtendedExhaleStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extended Exhale')),
      body: const Center(child: Text('Extended exhale coming soon')),
    );
  }
}

// Think tool stubs
class _NameThoughtStub extends StatelessWidget {
  const _NameThoughtStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Name the Thought')),
      body: const Center(child: Text('Name thought tool coming soon')),
    );
  }
}

class _EvidenceCheckStub extends StatelessWidget {
  const _EvidenceCheckStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Check')),
      body: const Center(child: Text('Evidence check coming soon')),
    );
  }
}

class _PerspectiveFlipStub extends StatelessWidget {
  const _PerspectiveFlipStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perspective Flip')),
      body: const Center(child: Text('Perspective flip coming soon')),
    );
  }
}

class _FactFeelingStub extends StatelessWidget {
  const _FactFeelingStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fact vs Feeling')),
      body: const Center(child: Text('Fact vs feeling coming soon')),
    );
  }
}

// Do tool stubs
class _TinyNextStepStub extends StatelessWidget {
  const _TinyNextStepStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiny Next Step')),
      body: const Center(child: Text('Tiny next step coming soon')),
    );
  }
}

class _EnergyMapStub extends StatelessWidget {
  const _EnergyMapStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Energy Map')),
      body: const Center(child: Text('Energy map coming soon')),
    );
  }
}

class _PomodoroTimerStub extends StatelessWidget {
  const _PomodoroTimerStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer')),
      body: const Center(child: Text('Pomodoro timer coming soon')),
    );
  }
}

// Rest tool stubs
class _WindDownStub extends StatelessWidget {
  const _WindDownStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wind-Down')),
      body: const Center(child: Text('Wind-down coming soon')),
    );
  }
}

class _BrainDumpStub extends StatelessWidget {
  const _BrainDumpStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brain Dump')),
      body: const Center(child: Text('Brain dump coming soon')),
    );
  }
}

class _BodyScanStub extends StatelessWidget {
  const _BodyScanStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Scan')),
      body: const Center(child: Text('Body scan coming soon')),
    );
  }
}

class _SleepSoundsStub extends StatelessWidget {
  const _SleepSoundsStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Sounds')),
      body: const Center(child: Text('Sleep sounds coming soon')),
    );
  }
}

// Missing stub implementations
class _PhysSighStub extends StatelessWidget {
  const _PhysSighStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physiological Sigh')),
      body: const Center(child: Text('Physiological sigh tool - breathe deeply')),
    );
  }
}

class _Grounding54321Stub extends StatelessWidget {
  const _Grounding54321Stub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('5-4-3-2-1 Grounding')),
      body: const Center(child: Text('5-4-3-2-1 grounding technique')),
    );
  }
}

class _BodyUnclenchStub extends StatelessWidget {
  const _BodyUnclenchStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Unclench')),
      body: const Center(child: Text('Progressive muscle relaxation')),
    );
  }
}

class _HistoryStub extends StatelessWidget {
  const _HistoryStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('Session history')),
    );
  }
}

class _AnalyticsStub extends StatelessWidget {
  const _AnalyticsStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const Center(child: Text('Analytics (Pro feature)')),
    );
  }
}

class _AnimalCheckinStub extends StatelessWidget {
  const _AnimalCheckinStub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animal Check-in')),
      body: const Center(child: Text('How are you feeling today?')),
    );
  }
}
