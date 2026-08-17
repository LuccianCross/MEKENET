from fastapi import FastAPI
from routes import hello
from routes import sync
from routes import export
from db.database import engine, SessionLocal

app = FastAPI(
    title="Mekenet API",
    description="Backend for the Mekenet financial tracker.",
    version="0.1.0",
)

# Existing routes
app.include_router(hello.router)

# New routes (feature/backend-sync-export)
app.include_router(sync.router)
app.include_router(export.router)


@app.get("/health")
def health_check():
    return {"status": "ok", "db_connection": "initialized"}