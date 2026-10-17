# DarkRemote Server

DarkRemote Server is the Windows desktop server for the DarkRemote mobile remote-control app. It listens for the mobile app on the local network and translates received commands into mouse and keyboard actions on the computer.

## Features

- Shows the computer's local IP address and server port.
- Starts and stops the WebSocket server with the buttons in the desktop window.
- Publishes the server through mDNS so compatible clients can discover it automatically.
- Runs in the Windows system tray when the window is closed.
- Uses `icon_on.png` in the tray while the server is running and `icon_off.png` when it is stopped.
- Uses `Desktop_icon.ico` for the desktop window and taskbar icon.

## Running the executable

Run `dist\DarkRemoteServer.exe` on the Windows computer that should receive remote-control commands. Keep the computer and mobile device on the same local network, then start the server and connect from the DarkRemote mobile app.

Closing the window hides the server in the system tray. Use the tray menu to reopen the window or quit the application.

## Running from source

Create and activate a virtual environment, install the dependencies, and run:

```powershell
python -m pip install -r requirements.txt
python main.py
```

The default server port is `8765`. Application settings, including the port and shared authentication secret, are defined in `domain\config.py`.

## Building the executable

PyInstaller is needed only to build the executable:

```powershell
python -m pip install pyinstaller
pyinstaller --noconfirm --clean --onefile --windowed --name DarkRemoteServer --icon .\Desktop_icon.ico --add-data ".\Desktop_icon.ico;." --add-data ".\Desktop_icon.png;." --add-data ".\icon_on.png;." --add-data ".\icon_off.png;." .\main.py
```

The executable is created at `dist\DarkRemoteServer.exe`.
