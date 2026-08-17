from fastapi import FastAPI
from routes import hello
from db.database import engine, SessionLocal

app = FastAPI()

app.include_router(hello.router)

@app.get("/health")
def health_check():
    return {"status": "ok", "db_connection": "initialized"}