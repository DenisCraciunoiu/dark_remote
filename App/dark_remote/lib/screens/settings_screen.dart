import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({
    super.key,
    required this.status,
    required this.sensitivity,
    required this.onManualConnection,
    required this.onRescan,
    required this.onSensitivityChanged,
    required this.onSensitivityChangeEnd,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final String status;
  final double sensitivity;
  final VoidCallback onManualConnection;
  final VoidCallback onRescan;
  final ValueChanged<double> onSensitivityChanged;
  final ValueChanged<double> onSensitivityChangeEnd;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: surfaceColor(context),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PC Remote',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_location_alt),
              title: const Text('Enter IP manually'),
              onTap: () {
                Navigator.of(context).pop();
                onManualConnection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Rescan network'),
              onTap: () {
                Navigator.of(context).pop();
                onRescan();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sensitivity: ${sensitivity.round()}'),
                  Slider(
                    value: sensitivity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: sensitivity.round().toString(),
                    onChanged: onSensitivityChanged,
                    onChangeEnd: onSensitivityChangeEnd,
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode,
              ),
              title: Text(isDarkMode ? 'Night mode' : 'Day mode'),
              onTap: (){
                onThemeChanged(!isDarkMode);
              },
            ),
          ],
        ),
      ),
    );
  }
}
