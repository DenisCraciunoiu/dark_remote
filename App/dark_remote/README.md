# PC Remote

PC Remote is a Flutter app that turns an Android or iOS phone into a
wireless controller for a computer on the same local network.

## Features

- Use the main touch area as a trackpad.
- Tap for a left click.
- Long-press for a right click.
- Adjust pointer sensitivity from the settings drawer.
- Send text from the phone to the connected PC.
- Send backspace and common media/keyboard commands from the control bar.
- Shut down the connected PC after confirming the action.
- Discover the PC automatically on the local network.
- Connect manually by entering the PC's IP address.
- Save the last successful PC address for the next launch.
- Switch between light and dark themes.

## Requirements

### To use the app

- An Android or iOS device.
- A compatible PC companion/server running on the computer.
- The phone and PC connected to the same Wi-Fi or local network.
- The PC companion/server available on WebSocket port `8765`.
- The PC firewall configured to allow the companion/server to receive local
  network connections on that port.

The PC companion/server is not included in this Flutter project. Automatic
discovery expects the service to advertise itself through mDNS. If discovery
does not find the PC, open the settings drawer and enter the PC's local IP
address manually.

### To build the app

- Flutter SDK with Dart `3.13.5` or newer within the configured SDK range.
- Android Studio and an Android SDK for Android builds.
- Xcode and CocoaPods for iOS builds on macOS.
- A connected device or configured emulator/simulator.

Install project dependencies before building:

```bash
flutter pub get
```

## Running

Start the app on a connected device or emulator:

```bash
flutter run
```

Build a release APK for Android:

```bash
flutter build apk --release
```

The APK is generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build an iOS release on macOS:

```bash
flutter build ipa --release
```

## Connecting to a PC

1. Start the compatible PC companion/server.
2. Connect the phone and PC to the same local network.
3. Open PC Remote. The app first tries the last successful address and then
   scans for the PC.
4. If the scan is unsuccessful, open the menu, select **Enter IP manually**,
   enter the PC's local IPv4 address, and select **Connect**.
5. Use **Rescan network** from the menu if the server is started after the app.

Only use the shutdown control when the correct PC is connected. The app asks
for confirmation before sending the shutdown command.
