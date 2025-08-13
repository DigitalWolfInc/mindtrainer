import 'package:flutter/material.dart';
import '../core/feature_flags.dart';
import '../ui/mtds/components/mtds_scaffold.dart';
import '../ui/mtds/components/mtds_header.dart';
import '../a11y/a11y.dart';
import '../profile/avatar_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import landing screens
import '../features/journal/landing_screen.dart';
import '../features/coach/landing_screen.dart';
import '../features/regulate/landing_screen.dart';
import '../features/think/landing_screen.dart';
import '../features/do/landing_screen.dart';
import '../features/rest/landing_screen.dart';

/// Main navigation shell with 6 tabs: Journal, Coach, Regulate, Think, Do, Rest
class TabShell extends StatefulWidget {
  const TabShell({super.key});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = const [
    JournalLandingScreen(),
    CoachLandingScreen(),
    RegulateLandingScreen(),
    ThinkLandingScreen(),
    DoLandingScreen(),
    RestLandingScreen(),
  ];

  final List<_TabInfo> _tabs = const [
    _TabInfo(
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      label: 'Journal',
    ),
    _TabInfo(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Coach',
    ),
    _TabInfo(
      icon: Icons.self_improvement_outlined,
      selectedIcon: Icons.self_improvement,
      label: 'Regulate',
    ),
    _TabInfo(
      icon: Icons.psychology_alt_outlined,
      selectedIcon: Icons.psychology_alt,
      label: 'Think',
    ),
    _TabInfo(
      icon: Icons.checklist_rtl_outlined,
      selectedIcon: Icons.checklist_rtl,
      label: 'Do',
    ),
    _TabInfo(
      icon: Icons.nightlight_round_outlined,
      selectedIcon: Icons.nightlight_round,
      label: 'Rest',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    final prefersReducedMotion = A11y.prefersReducedMotion(context);
    
    // Use MTDS scaffold if available, otherwise fallback to standard
    if (FeatureFlags.mtdsComponentsEnabled) {
      return MtdsScaffold(
        body: Column(
          children: [
            const MtdsHeader(
              title: 'MindTrainer',
              subtitle: 'A calm mind isn\'t out of reach.',
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: prefersReducedMotion 
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                children: _pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(context, textScaler),
      );
    }

    // Fallback to standard Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MindTrainer',
          style: TextStyle(fontSize: 20 * textScaler),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (FeatureFlags.ff_profile_avatar)
            A11y.ensureMinTouchTarget(
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/account'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.person_outline, size: 20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!FeatureFlags.mtdsComponentsEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'A calm mind isn\'t out of reach.',
                style: TextStyle(
                  fontSize: 16 * textScaler,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: prefersReducedMotion 
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context, textScaler),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, double textScaler) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      height: 72, // Ensure minimum touch target height
      destinations: _tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final isSelected = index == _selectedIndex;
        
        return NavigationDestination(
          icon: A11y.ensureMinTouchTarget(
            Semantics(
              button: true,
              selected: isSelected,
              label: '${tab.label} tab${isSelected ? ', selected' : ''}',
              child: Icon(
                isSelected ? tab.selectedIcon : tab.icon,
                size: 24,
              ),
            ),
          ),
          selectedIcon: A11y.ensureMinTouchTarget(
            Icon(tab.selectedIcon, size: 24),
          ),
          label: tab.label,
        );
      }).toList(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}

class _TabInfo {
  const _TabInfo({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}