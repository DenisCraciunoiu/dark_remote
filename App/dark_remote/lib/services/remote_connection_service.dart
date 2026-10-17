import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemoteConnectionService {
  RemoteConnectionService({
    required this.onStatusChanged,
    required this.onConnectionChanged,
    required this.onConnected,
  });

  static const _platform = MethodChannel('com.example.dark_remote/multicast');
  static const _sharedSecret = 'Secret_password';

  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onConnectionChanged;
  final ValueChanged<String> onConnected;
  WebSocketChannel? _channel;

  bool get isConnected => _isConnected;
  bool _isConnected = false;

  Future<void> discoverAndConnect() async {
    disconnect();
    _reportStatus('Acquiring network lock...');
    await _acquireMulticastLock();

    final nativeService = await _discoverWithAndroidNsd();
    if (nativeService != null) {
      final address = nativeService['address'] as String?;
      final port = nativeService['port'] as int?;
      if (address != null && port != null) {
        _reportStatus('Found PC at $address:$port. Connecting...');
        if (await connect(address, port: port)) return;
      }
    }

    final client = MDnsClient(
      rawDatagramSocketFactory:
          (
            dynamic host,
            int port, {
            bool reuseAddress = true,
            bool reusePort = false,
            int ttl = 255,
          }) async {
            return RawDatagramSocket.bind(
              host,
              port,
              reuseAddress: reuseAddress,
              reusePort: false,
              ttl: ttl,
            );
          },
    );

    _reportStatus('Scanning local network...');
    try {
      final availableInterfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      final wifiInterfaces = availableInterfaces
          .where((interface) => interface.name.toLowerCase().contains('wlan'))
          .toList();
      final interfaces = wifiInterfaces.isNotEmpty
          ? wifiInterfaces
          : availableInterfaces;
      _log(
        'Using mDNS interfaces: ${interfaces.map((interface) => '${interface.name} (${interface.addresses.map((address) => address.address).join(', ')})').join(', ')}',
      );
      await client.start(
        listenAddress: InternetAddress.anyIPv4,
        interfacesFactory: (type) async => interfaces,
      );
      _log('mDNS client started; querying _darkremote._tcp.local.');
      await for (final PtrResourceRecord ptr in client.lookup(
        ResourceRecordQuery.serverPointer('_darkremote._tcp.local.'),
      )) {
        _log('PTR record: ${ptr.domainName}');
        _reportStatus('Found service: ${ptr.domainName}');
        await for (final SrvResourceRecord srv in client.lookup(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          _log('SRV record: target=${srv.target}, port=${srv.port}');
          _reportStatus(
            'Found server ${srv.target}:${srv.port}. Resolving address...',
          );
          final pcIp = await _resolveServiceAddress(client, srv.target);
          if (pcIp == null) {
            _log('No IPv4 address found for ${srv.target}');
            _reportStatus('Could not resolve ${srv.target}.');
            continue;
          }

          _log('Resolved ${srv.target} to $pcIp');
          final connected = await connect(pcIp, port: srv.port);
          if (connected) return;
        }
      }
    } catch (error) {
      _log('mDNS discovery error: $error');
      _reportStatus('Scan error: $error');
    } finally {
      client.stop();
      await _releaseMulticastLock();
    }

    if (!_isConnected) {
      _log('mDNS discovery completed without an authenticated connection');
      _reportStatus('PC not found. Tap edit icon to enter IP.');
    }
  }

  Future<Map<String, Object?>?> _discoverWithAndroidNsd() async {
    try {
      final result = await _platform
          .invokeMethod<Map<Object?, Object?>>('discoverService')
          .timeout(const Duration(seconds: 5));
      if (result == null) return null;
      return result.map((key, value) => MapEntry(key.toString(), value));
    } on PlatformException catch (error) {
      _log('Native Android NSD discovery failed: $error');
    } on MissingPluginException {
      _log('Native Android NSD is unavailable in this build; using Dart mDNS.');
    } on TimeoutException {
      _log('Native Android NSD discovery timed out');
    }
    return null;
  }

  Future<String?> _resolveServiceAddress(
    MDnsClient client,
    String target,
  ) async {
    await for (final IPAddressResourceRecord record in client.lookup(
      ResourceRecordQuery.addressIPv4(target),
    )) {
      _log('mDNS A record: ${record.address.address}');
      return record.address.address;
    }

    final hostname = target.endsWith('.')
        ? target.substring(0, target.length - 1)
        : target;
    try {
      final addresses = await InternetAddress.lookup(
        hostname,
        type: InternetAddressType.IPv4,
      );
      if (addresses.isNotEmpty) {
        _log('System DNS resolved $hostname to ${addresses.first.address}');
        return addresses.first.address;
      }
    } on SocketException catch (error) {
      debugPrint('Fallback mDNS address lookup failed for $hostname: $error');
    }
    return null;
  }

  Future<bool> connect(String ip, {int port = 8765}) async {
    _log('Opening WebSocket ws://$ip:$port');
    _closeChannel();
    late final WebSocketChannel channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://$ip:$port'));
    } catch (error) {
      _log('WebSocket creation failed: $error');
      _reportStatus('Connection failed: $error');
      return false;
    }
    _channel = channel;

    try {
      await channel.ready.timeout(const Duration(seconds: 5));
    } catch (_) {
      if (_channel != channel) return false;
      channel.sink.close();
      _setConnectionState(false);
      _reportStatus("Can't reach $ip:$port (firewall / server not started?)");
      return false;
    }

    final authentication = Completer<bool>();
    channel.stream.listen(
      (message) => _handleMessage(channel, ip, message, authentication),
      onDone: () {
        if (_channel != channel) return;
        _setConnectionState(false);
        _log('WebSocket closed by server');
        _reportStatus('Disconnected. Tap refresh to retry.');
        if (!authentication.isCompleted) authentication.complete(false);
      },
      onError: (error) {
        if (_channel != channel) return;
        _setConnectionState(false);
        _log('WebSocket stream error: $error');
        _reportStatus('Connection failed: $error');
        if (!authentication.isCompleted) authentication.complete(false);
      },
    );

    try {
      return await authentication.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      if (_channel == channel) {
        channel.sink.close();
        _setConnectionState(false);
        _reportStatus('Authentication timed out for $ip:$port.');
      }
      return false;
    }
  }

  void sendMovement(double dx, double dy) {
    _send({'action': 'move', 'dx': dx * 2, 'dy': dy * 2});
  }

  void sendCommand(String command) {
    _send({'action': command});
  }

  void sendClick() {
    _send({'action': 'click'});
  }

  void sendRightClick() {
    _send({'action': 'right_click'});
  }

  void sendText(String text) {
    _send({'action': 'text', 'text': text});
  }

  void disconnect() {
    _closeChannel();
  }

  void dispose() {
    disconnect();
  }

  void _handleMessage(
    WebSocketChannel channel,
    String ip,
    dynamic message,
    Completer<bool> authentication,
  ) {
    if (_channel != channel) return;
    final data = jsonDecode(message);
    if (data['action'] == 'auth_challenge') {
      _log('Received authentication challenge');
      final digest = Hmac(
        sha256,
        utf8.encode(_sharedSecret),
      ).convert(utf8.encode(data['challenge']));
      channel.sink.add(
        jsonEncode({'action': 'auth_response', 'hash': digest.toString()}),
      );
    } else if (data['action'] == 'auth_success') {
      _log('Authentication succeeded');
      _setConnectionState(true);
      onConnected(ip);
      _reportStatus('Connected & Secured ($ip)');
      if (!authentication.isCompleted) authentication.complete(true);
    }
  }

  void _send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _setConnectionState(bool value) {
    _isConnected = value;
    onConnectionChanged(value);
  }

  void _reportStatus(String status) {
    _log('Status: $status');
    onStatusChanged(status);
  }

  void _log(String message) {
    debugPrint('[RemoteConnection] $message');
  }

  void _closeChannel() {
    _channel?.sink.close();
    _channel = null;
    _setConnectionState(false);
  }

  Future<void> _acquireMulticastLock() async {
    try {
      await _platform.invokeMethod('acquire'); // Use _platform here
      debugPrint('Multicast lock acquired');
    } catch (error) {
      debugPrint('MulticastLock acquire note: $error');
    }
  }

  Future<void> _releaseMulticastLock() async {
    try {
      await _platform.invokeMethod('release'); // Use _platform here
    } catch (error) {
      debugPrint('MulticastLock release note: $error');
    }
  }
}
