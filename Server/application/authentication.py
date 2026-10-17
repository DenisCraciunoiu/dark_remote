import asyncio
import hashlib
import hmac
import json
import secrets

from domain.config import SHARED_SECRET


async def authenticate(websocket):
    """
    Performs HMAC Challenge-Response authentication.
    Prevents unauthorized devices from controlling the mouse.
    """
    challenge = secrets.token_hex(32)

    await websocket.send(json.dumps({
        "action": "auth_challenge",
        "challenge": challenge
    }))

    try:
        response_msg = await asyncio.wait_for(websocket.recv(), timeout=5.0)
        response_data = json.loads(response_msg)

        if response_data.get("action") != "auth_response":
            return False

        client_hash = response_data.get("hash")
        expected_hash = hmac.new(
            SHARED_SECRET.encode("utf-8"),
            challenge.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(expected_hash, client_hash)

    except (asyncio.TimeoutError, json.JSONDecodeError):
        return False
