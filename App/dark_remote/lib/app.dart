import 'package:flutter/material.dart';

import 'services/settings_service.dart';
import 'screens/trackpad_screen.dart';

class MouseRemoteApp extends StatefulWidget {
  const MouseRemoteApp({super.key});

  @override
  State<MouseRemoteApp> createState() => _MouseRemoteAppState();
}

class _MouseRemoteAppState extends State<MouseRemoteApp> {
  final _settings = SettingsService();
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final isDarkMode = await _settings.loadDarkMode();
    if (!mounted) return;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: TrackpadScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }

  void _toggleTheme([bool? _]) {
    final isDarkMode = _themeMode != ThemeMode.dark;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
    _settings.saveDarkMode(isDarkMode);
  }
}
