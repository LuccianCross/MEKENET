"""
routes/sync.py
--------------
POST /sync

Accepts a transaction payload from the Flutter app and writes it into
the Postgres database. Deduplicates by transaction id.
"""

import re
from datetime import datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from db.database import get_db
from middleware.auth import require_api_key
from models.transaction import Transaction

router = APIRouter(prefix="/sync", tags=["sync"])

_XSS_STRIP = re.compile(r"[<>&\"']")


class TransactionIn(BaseModel):
    id: str = Field(..., description="Client-generated transaction ID")
    type: Literal["income", "expense"]
    amount: float = Field(..., gt=0, description="Must be positive")
    description: str = Field(..., min_length=1, max_length=500)
    date: Optional[str] = Field(default=None)
    category: Optional[str] = Field(default="uncategorized")
    currency: str = Field(default="ETB", max_length=10)

    @field_validator("description", mode="before")
    @classmethod
    def sanitize_description(cls, v: str) -> str:
        v = v.strip()
        v = _XSS_STRIP.sub("", v)
        return v

    @field_validator("category", mode="before")
    @classmethod
    def sanitize_category(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return _XSS_STRIP.sub("", v.strip())

    @field_validator("date", mode="before")
    @classmethod
    def default_date(cls, v: Optional[str]) -> str:
        if not v:
            return datetime.now(timezone.utc).date().isoformat()
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError("date must be in YYYY-MM-DD format")
        return v


class SyncResponse(BaseModel):
    success: bool
    message: str
    transaction_id: str
    stored_count: int


@router.post(
    "/",
    response_model=SyncResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Sync a transaction from the Flutter app",
)
def sync_transaction(
    payload: TransactionIn,
    x_device_id: Optional[str] = Header(default=None, alias="X-Device-ID"),
    _key: str = Depends(require_api_key),
    db: Session = Depends(get_db),
) -> SyncResponse:
    if not x_device_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-Device-ID header",
        )

    existing = db.query(Transaction).filter(Transaction.id == payload.id).first()
    if existing:
        count = db.query(Transaction).filter(
            Transaction.device_id == x_device_id
        ).count()
        return SyncResponse(
            success=True,
            message="Transaction already exists (deduplicated)",
            transaction_id=payload.id,
            stored_count=count,
        )

    tx = Transaction(
        id=payload.id,
        type=payload.type,
        amount=payload.amount,
        description=payload.description,
        date=payload.date or datetime.now(timezone.utc).date().isoformat(),
        category=payload.category or "uncategorized",
        currency=payload.currency,
        device_id=x_device_id,
    )
    db.add(tx)
    db.commit()

    count = db.query(Transaction).filter(
        Transaction.device_id == x_device_id
    ).count()

    return SyncResponse(
        success=True,
        message="Transaction synced successfully",
        transaction_id=payload.id,
        stored_count=count,
    )
