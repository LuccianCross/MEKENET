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

from fastapi import APIRouter, HTTPException, status
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
    id          – client-generated UUID/string; uniqueness check is the DB's
                  job (skipped for now — fake store accepts duplicates).
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
        today = datetime.now(timezone.utc).date().isoformat()

        # No value provided — default to today
        if not v:
            return today

        # Flutter sometimes sends the Swagger placeholder "string" — treat as missing
        if v.lower() == "string":
            return today

        # Validate proper ISO-8601 date format (YYYY-MM-DD)
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            # Invalid format — fall back to today's date gracefully
            return today

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
        "Validates and stores a single transaction. "
        "Backed by an in-memory list until Postgres is wired."
    ),
)
def sync_transaction(payload: TransactionIn) -> SyncResponse:
    """
    Validate the incoming transaction, persist it to the fake store,
    and return confirmation.

    Future:  replace fake_db.insert_transaction() with a real DB write.
    """
    tx_dict = payload.model_dump()

    # Add a server-side timestamp for audit purposes
    tx_dict["synced_at"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    try:
        fake_db.insert_transaction(tx_dict)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Storage error: {exc}",
        )

    stored_count = len(fake_db.get_all_transactions())

    return SyncResponse(
        success=True,
        message="Transaction synced successfully",
        transaction_id=payload.id,
        stored_count=stored_count,
    )
