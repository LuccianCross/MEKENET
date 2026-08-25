import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from routes import hello, sync, export
from db.database import create_tables
from middleware.rate_limiter import RateLimiter

_allowed = os.getenv("CORS_ORIGINS", "").split(",")
_allowed = [o.strip() for o in _allowed if o.strip()]
if not _allowed:
    _allowed = ["http://localhost"]


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_tables()
    yield


app = FastAPI(
    title="Mekenet API",
    description="Backend for the Mekenet financial tracker.",
    version="0.2.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "X-Device-ID", "X-API-Key"],
)

_limiter = RateLimiter(max_requests=60, window_seconds=60)


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    if request.url.path in ("/health", "/docs", "/openapi.json"):
        return await call_next(request)
    try:
        _limiter.check(request)
    except Exception as exc:
        if hasattr(exc, "status_code"):
            return JSONResponse(
                status_code=exc.status_code,
                content={"detail": exc.detail},
                headers=getattr(exc, "headers", None),
            )
        raise
    return await call_next(request)


app.include_router(hello.router)
app.include_router(sync.router)
app.include_router(export.router)


@app.get("/health")
def health_check():
    from db.database import SessionLocal
    from sqlalchemy import text

    db = None
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        return {"status": "ok", "db_connection": "healthy"}
    except Exception:
        return JSONResponse(
            status_code=503,
            content={"status": "degraded", "db_connection": "unavailable"},
        )
    finally:
        if db:
            db.close()
