import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(AppSettings.keyNotificationsEnabled) ?? true;
      _themeMode = prefs.getString(AppSettings.keyThemeMode) ?? 'system';
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettings.keyNotificationsEnabled, value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _saveThemeSetting(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettings.keyThemeMode, value);
    setState(() {
      _themeMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Privacy Section
            const Text(
              'Privacy & Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Your Data Stays Private',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppSettings.privacyStatement,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Works Offline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppSettings.offlineNotice,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Settings Section
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Gentle Reminders'),
              subtitle: const Text('Optional notifications for check-ins (stored locally)'),
              value: _notificationsEnabled,
              onChanged: _saveNotificationSetting,
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'App Theme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            
            RadioListTile<String>(
              title: const Text('Follow System'),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) => _saveThemeSetting(value!),
            ),
            RadioListTile<String>(
              title: const Text('Light Mode'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) => _saveThemeSetting(value!),
            ),
            RadioListTile<String>(
              title: const Text('Dark Mode'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) => _saveThemeSetting(value!),
            ),
            
            const SizedBox(height: 32),
            
            // Technical Info Section
            const Text(
              'Technical Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: Text(AppSettings.version),
            ),
            
            const ListTile(
              leading: Icon(Icons.storage),
              title: Text('Data Storage'),
              subtitle: Text('All data stored locally on your device only'),
            ),
            
            const ListTile(
              leading: Icon(Icons.wifi_off),
              title: Text('Network Access'),
              subtitle: Text('No network requests made without your permission'),
            ),
          ],
        ),
      ),
    );
  }
}