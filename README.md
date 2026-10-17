# DarkRemote

DarkRemote lets an Android or iOS phone control a Windows PC over the local
network.

## Components

- **App** - Flutter mobile app in [`App/dark_remote`](./App/dark_remote).
- **Server** - Windows desktop server in [`Server`](./Server). It receives
  commands from the app and controls the PC.

Start the server on the PC, connect the phone and PC to the same network, then
open the app. The app will discover the server automatically, or you can enter
the PC's IP address manually.

See the component documentation for setup and build instructions:

- [`App/dark_remote/README.md`](./App/dark_remote/README.md)
- [`Server/README.md`](./Server/README.md)
