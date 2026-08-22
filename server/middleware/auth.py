"""
Shared API key authentication dependency.

The client must send  X-API-Key: <key>  on protected endpoints.
The key is read from the MEKENET_API_KEY environment variable.
"""

import hmac
import os

from fastapi import Header, HTTPException, status


async def require_api_key(
    x_api_key: str | None = Header(default=None, alias="X-API-Key"),
) -> str:
    """FastAPI dependency - inject into any route that needs auth."""
    expected = os.getenv("MEKENET_API_KEY")
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Server misconfiguration: MEKENET_API_KEY not set",
        )
    if not x_api_key or not hmac.compare_digest(x_api_key, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key",
        )
    return x_api_key
