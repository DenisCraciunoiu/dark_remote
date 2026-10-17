import asyncio

import websockets

from application.connection_handler import handle_connection
from domain.config import PORT
from infrastructure.discovery import setup_zeroconf


async def run_server(ip, port=PORT):
    loop = asyncio.get_running_loop()
    zc = info = None

    async with websockets.serve(handle_connection, "0.0.0.0", port):
        print(f"[Server] Listening on 0.0.0.0:{port}")
        try:
            zc, info = await loop.run_in_executor(None, setup_zeroconf, ip)
        except Exception as e:
            print(f"[mDNS] Failed, continuing without discovery: {e!r}")

        try:
            await asyncio.Future()
        finally:
            if zc:
                await loop.run_in_executor(None, zc.unregister_service, info)
                await loop.run_in_executor(None, zc.close)
