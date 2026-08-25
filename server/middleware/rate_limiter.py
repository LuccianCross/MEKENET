"""
In-memory sliding-window rate limiter with stale IP eviction.

Tracks request counts per IP using a deque of timestamps.
Evicts IPs with no recent requests to prevent unbounded memory growth.
"""

import time
from collections import defaultdict, deque
from fastapi import Request, HTTPException, status


class RateLimiter:
    """Per-IP sliding-window rate limiter."""

    def __init__(self, max_requests: int = 60, window_seconds: int = 60):
        self._max = max_requests
        self._window = window_seconds
        self._hits: dict[str, deque] = defaultdict(deque)
        self._last_cleanup = time.time()
        self._cleanup_interval = 300  # evict stale IPs every 5 minutes

    def _client_ip(self, request: Request) -> str:
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return request.client.host if request.client else "unknown"

    def _evict_stale(self) -> None:
        now = time.time()
        if now - self._last_cleanup < self._cleanup_interval:
            return
        self._last_cleanup = now

        cutoff = now - self._window
        stale = [
            ip for ip, dq in self._hits.items()
            if not dq or dq[-1] < cutoff
        ]
        for ip in stale:
            del self._hits[ip]

    def check(self, request: Request) -> None:
        self._evict_stale()

        ip = self._client_ip(request)
        now = time.time()
        cutoff = now - self._window

        dq = self._hits[ip]
        while dq and dq[0] < cutoff:
            dq.popleft()

        if len(dq) >= self._max:
            retry_after = int(dq[0] + self._window - now) + 1
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Try again in {retry_after}s.",
                headers={"Retry-After": str(retry_after)},
            )

        dq.append(now)
