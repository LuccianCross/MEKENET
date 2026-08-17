from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# We expect a Postgres URL like postgresql://user:password@host:port/dbname
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    print("Warning: DATABASE_URL not set in .env. Falling back to in-memory SQLite for testing.")
    DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
