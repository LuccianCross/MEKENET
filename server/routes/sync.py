"""
routes/sync.py
--------------
POST /sync

Accepts a transaction payload from the Flutter app and writes it into
the in-memory fake store.

Swap guide (when Postgres env arrives):
  - Remove the `fake_db` import.
  - Inject `db: Session = Depends(get_db)`.
  - Replace `fake_db.insert_transaction(tx_dict)` with:
        db.add(Transaction(**tx_dict))
        db.commit()
"""

from datetime import datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field, field_validator

import fake_db

router = APIRouter(prefix="/sync", tags=["sync"])


# ---------------------------------------------------------------------------
# Request schema
# ---------------------------------------------------------------------------

class TransactionIn(BaseModel):
    """
    The exact shape Flutter sends over the wire.

    Field notes
    -----------
    id          – client-generated UUID/string; deduplicated on the server.
    type        – "income" or "expense" only.
    amount      – must be positive; stored as float to handle cents.
    description – free text, trimmed on arrival.
    date        – ISO-8601 date string (YYYY-MM-DD); falls back to today.
    category    – optional label (e.g. "food", "transport").
    currency    – defaults to "ETB" (Ethiopian Birr) to match Mekenet scope.
    """

    id: str = Field(..., description="Client-generated transaction ID")
    type: Literal["income", "expense"]
    amount: float = Field(..., gt=0, description="Must be positive")
    description: str = Field(..., min_length=1, max_length=500)
    date: Optional[str] = Field(
        default=None,
        description="ISO-8601 date string (YYYY-MM-DD). Defaults to today.",
    )
    category: Optional[str] = Field(default="uncategorized")
    currency: str = Field(default="ETB", max_length=10)

    @field_validator("description", mode="before")
    @classmethod
    def strip_description(cls, v: str) -> str:
        return v.strip()

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


# ---------------------------------------------------------------------------
# Response schema
# ---------------------------------------------------------------------------

class SyncResponse(BaseModel):
    success: bool
    message: str
    transaction_id: str
    stored_count: int = Field(
        description="Total transactions in the fake store after this sync"
    )


# ---------------------------------------------------------------------------
# Route
# ---------------------------------------------------------------------------

@router.post(
    "/",
    response_model=SyncResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Sync a transaction from the Flutter app",
    description=(
        "Validates and stores a single transaction, deduplicating by id. "
        "Backed by an in-memory list until Postgres is wired."
    ),
)
def sync_transaction(
    payload: TransactionIn,
    x_device_id: Optional[str] = Header(default=None, alias="X-Device-ID"),
) -> SyncResponse:
    if not x_device_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-Device-ID header",
        )

    tx_dict = payload.model_dump()
    tx_dict["synced_at"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    try:
        result = fake_db.insert_transaction(tx_dict)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Storage error: {exc}",
        )

    if result == "duplicate":
        stored_count = len(fake_db.get_all_transactions())
        return SyncResponse(
            success=True,
            message="Transaction already exists (deduplicated)",
            transaction_id=payload.id,
            stored_count=stored_count,
        )

    stored_count = len(fake_db.get_all_transactions())

    return SyncResponse(
        success=True,
        message="Transaction synced successfully",
        transaction_id=payload.id,
        stored_count=stored_count,
    )
