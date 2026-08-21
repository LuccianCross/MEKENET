from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import hello
from routes import sync
from routes import export
from db.database import create_tables

app = FastAPI(
    title="Mekenet API",
    description="Backend for the Mekenet financial tracker.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(hello.router)
app.include_router(sync.router)
app.include_router(export.router)


@app.on_event("startup")
def on_startup():
    create_tables()


@app.get("/health")
def health_check():
    from db.database import SessionLocal
    from sqlalchemy import text
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return {"status": "ok", "db_connection": "healthy"}
    except Exception as e:
        return {"status": "degraded", "db_connection": str(e)}