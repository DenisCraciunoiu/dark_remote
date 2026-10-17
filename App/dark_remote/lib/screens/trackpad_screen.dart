import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/remote_connection_service.dart';
import '../services/settings_service.dart';
import '../widgets/dot_ripple_background.dart';
import '../widgets/trackpad_controls.dart';
import '../widgets/text_input_bar.dart';
import 'settings_screen.dart';

class TrackpadScreen extends StatefulWidget {
  const TrackpadScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<TrackpadScreen> createState() => _TrackpadScreenState();
}

class _TrackpadScreenState extends State<TrackpadScreen> {
  final _textController = TextEditingController();
  final _settings = SettingsService();
  late final RemoteConnectionService _connection;
  String _status = 'Scanning for PC...';
  bool _isConnected = false;
  double _sensitivity = SettingsService.defaultSensitivity;
  double _lastX = 0;
  double _lastY = 0;

  @override
  void initState() {
    super.initState();
    _connection = RemoteConnectionService(
      onStatusChanged: _updateStatus,
      onConnectionChanged: _updateConnection,
      onConnected: _saveLastIp,
    );
    _connectUsingLastIp();
    _loadSensitivity();
  }

  Future<void> _connectUsingLastIp() async {
    final lastIp = await _settings.loadLastIp();
    if (!mounted) return;

    if (lastIp != null && lastIp.trim().isNotEmpty) {
      _updateStatus('Connecting to saved PC...');
      final connected = await _connection.connect(lastIp);
      if (connected) return;
    }

    await _connection.discoverAndConnect();
  }

  Future<void> _saveLastIp(String ip) => _settings.saveLastIp(ip);

  Future<void> _loadSensitivity() async {
    final sensitivity = await _settings.loadSensitivity();
    if (!mounted) return;
    setState(() => _sensitivity = sensitivity);
  }

  void _updateStatus(String status) {
    if (mounted) setState(() => _status = status);
  }

  void _updateConnection(bool connected) {
    if (mounted) setState(() => _isConnected = connected);
  }

  void _sendText() {
    final text = _textController.text;
    if (text.isEmpty) return;
    _connection.sendText(text);
    _textController.clear();
  }

  void _showManualIpDialog() {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Connection'),
        content: TextField(
          controller: ipController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'e.g. 192.168.1.50',
            labelText: 'PC IP Address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                _connectManually(ip);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectManually(String ip) async {
    _updateStatus('Connecting to $ip...');
    final connected = await _connection.connect(ip);
    if (connected) {
      await _settings.saveLastIp(ip);
    }
  }

  void _showShutdownConfirmation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shut down PC?'),
        content: const Text(
          'Are you sure you want to shut down the connected computer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connection.sendCommand('shut_down');
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            child: const Text('Shut down'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SettingsDrawer(
        status: _status,
        sensitivity: _sensitivity,
        onManualConnection: _showManualIpDialog,
        onRescan: _connection.discoverAndConnect,
        onSensitivityChanged: (value) {
          setState(() => _sensitivity = value);
        },
        onSensitivityChangeEnd: _settings.saveSensitivity,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _lastX = details.globalPosition.dx;
                    _lastY = details.globalPosition.dy;
                  },
                  onPanUpdate: (details) {
                    final currentX = details.globalPosition.dx;
                    final currentY = details.globalPosition.dy;
                    _connection.sendMovement(
                      (currentX - _lastX) * _sensitivity,
                      (currentY - _lastY) * _sensitivity,
                    );
                    _lastX = currentX;
                    _lastY = currentY;
                  },
                  onTap: _connection.sendClick,
                  onLongPress: _connection.sendRightClick,
                  child: DotRippleBackground(connected: _isConnected),
                ),
                Positioned(
                  top: 50,
                  left: 17,
                  child: Material(
                    color: surfaceColor(context).withValues(alpha: 0),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: IconButton(
                        icon: const Icon(Icons.power_settings_new),
                        color: redColor(context),
                        tooltip: 'Shut down PC',
                        onPressed: _showShutdownConfirmation,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) => TrackpadControls(
              onCommand: _connection.sendCommand,
              onOpenMenu: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          TextInputBar(
            controller: _textController,
            onSubmit: _sendText,
            onBackspace: () => _connection.sendCommand('backspace'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _connection.dispose();
    super.dispose();
  }
}