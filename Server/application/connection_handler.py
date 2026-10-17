import json

import websockets

from application.authentication import authenticate
from infrastructure.input_controller import execute_action, is_known_action


async def handle_connection(websocket):
    """Handles an incoming connection from the mobile app."""
    client_ip = websocket.remote_address[0]
    print(f"\n[Connection] New attempt from {client_ip}")

    if not await authenticate(websocket):
        print(f"[Auth] Authentication failed for {client_ip}. Closing connection.")
        await websocket.close()
        return

    print(f"[Auth] Client {client_ip} authenticated successfully!")
    await websocket.send(json.dumps({"action": "auth_success"}))

    try:
        async for message in websocket:
            data = json.loads(message)
            execute_action(data)

            if not is_known_action(data):
                print(f"[Action] Unknown action '{data.get('action')}' from {client_ip}")

    except websockets.exceptions.ConnectionClosed:
        print(f"[Connection] Client {client_ip} disconnected.")
