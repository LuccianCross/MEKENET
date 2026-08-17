"""
routes/export.py
----------------
POST /export

Reads everything from the fake store and computes a human-readable
financial report.

Swap guide (when Postgres env arrives):
  - Remove the `fake_db` import.
  - Inject `db: Session = Depends(get_db)`.
  - Replace the list comprehension with:
        rows = db.query(Transaction).all()
        txs = [r.__dict__ for r in rows]
"""

from collections import defaultdict
from datetime import datetime, timezone
from typing import Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel

import fake_db

router = APIRouter(prefix="/export", tags=["export"])


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class CategoryBreakdown(BaseModel):
    category: str
    total: float
    count: int


class TransactionSummary(BaseModel):
    id: str
    type: str
    amount: float
    description: str
    date: str
    category: str
    currency: str
    synced_at: str


class ExportReport(BaseModel):
    """
    The "readable report" referenced in the task spec.

    Sections
    --------
    summary        – top-level numbers (income, expense, balance, count).
    income_by_category  – income broken down by category label.
    expense_by_category – expense broken down by category label.
    transactions   – full list (newest first) so the report is self-contained.
    generated_at   – UTC timestamp so the consumer knows freshness.
    filters_applied – echoes back any query-string filters used.
    """

    summary: Dict
    income_by_category: List[CategoryBreakdown]
    expense_by_category: List[CategoryBreakdown]
    transactions: List[TransactionSummary]
    generated_at: str
    filters_applied: Dict


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def _build_category_breakdown(
    txs: List[Dict], tx_type: str
) -> List[CategoryBreakdown]:
    """Aggregate amount and count per category for a given transaction type."""
    buckets: Dict[str, Dict] = defaultdict(lambda: {"total": 0.0, "count": 0})
    for tx in txs:
        if tx["type"] == tx_type:
            cat = tx.get("category") or "uncategorized"
            buckets[cat]["total"] += tx["amount"]
            buckets[cat]["count"] += 1

    return [
        CategoryBreakdown(category=cat, total=round(data["total"], 2), count=data["count"])
        for cat, data in sorted(buckets.items())
    ]


# ---------------------------------------------------------------------------
# Route
# ---------------------------------------------------------------------------

@router.post(
    "/",
    response_model=ExportReport,
    status_code=status.HTTP_200_OK,
    summary="Export a financial report from synced transactions",
    description=(
        "Reads all stored transactions and returns a structured financial "
        "summary. Optionally filter by date range or transaction type."
    ),
)
def export_report(
    from_date: Optional[str] = Query(
        default=None,
        description="Filter: include transactions on or after YYYY-MM-DD",
    ),
    to_date: Optional[str] = Query(
        default=None,
        description="Filter: include transactions on or before YYYY-MM-DD",
    ),
    type_filter: Optional[str] = Query(
        default=None,
        alias="type",
        description="Filter: 'income' or 'expense'",
    ),
) -> ExportReport:
    """
    Build a complete financial report from the fake (or real) store.

    1. Load all transactions.
    2. Apply optional date-range / type filters.
    3. Compute totals.
    4. Build per-category breakdowns.
    5. Return the structured report.
    """

    all_txs = fake_db.get_all_transactions()

    if not all_txs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "No transactions found. "
                "Call POST /sync first to load some data."
            ),
        )

    # ------------------------------------------------------------------
    # Apply filters
    # ------------------------------------------------------------------
    filters_applied: Dict = {}
    filtered = all_txs

    if from_date:
        try:
            datetime.strptime(from_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(400, "from_date must be YYYY-MM-DD")
        filtered = [t for t in filtered if t["date"] >= from_date]
        filters_applied["from_date"] = from_date

    if to_date:
        try:
            datetime.strptime(to_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(400, "to_date must be YYYY-MM-DD")
        filtered = [t for t in filtered if t["date"] <= to_date]
        filters_applied["to_date"] = to_date

    if type_filter:
        if type_filter not in ("income", "expense"):
            raise HTTPException(400, "type must be 'income' or 'expense'")
        filtered = [t for t in filtered if t["type"] == type_filter]
        filters_applied["type"] = type_filter

    # ------------------------------------------------------------------
    # Compute summary numbers
    # ------------------------------------------------------------------
    total_income = round(
        sum(t["amount"] for t in filtered if t["type"] == "income"), 2
    )
    total_expense = round(
        sum(t["amount"] for t in filtered if t["type"] == "expense"), 2
    )
    net_balance = round(total_income - total_expense, 2)
    transaction_count = len(filtered)

    summary = {
        "total_income": total_income,
        "total_expense": total_expense,
        "net_balance": net_balance,
        "transaction_count": transaction_count,
        "currency": filtered[0]["currency"] if filtered else "ETB",
    }

    # ------------------------------------------------------------------
    # Build category breakdowns
    # ------------------------------------------------------------------
    income_by_cat = _build_category_breakdown(filtered, "income")
    expense_by_cat = _build_category_breakdown(filtered, "expense")

    # ------------------------------------------------------------------
    # Serialize transactions (newest date first)
    # ------------------------------------------------------------------
    sorted_txs = sorted(filtered, key=lambda t: t["date"], reverse=True)
    tx_summaries = [
        TransactionSummary(
            id=t["id"],
            type=t["type"],
            amount=t["amount"],
            description=t["description"],
            date=t["date"],
            category=t.get("category", "uncategorized"),
            currency=t.get("currency", "ETB"),
            synced_at=t.get("synced_at", ""),
        )
        for t in sorted_txs
    ]

    return ExportReport(
        summary=summary,
        income_by_category=income_by_cat,
        expense_by_category=expense_by_cat,
        transactions=tx_summaries,
        generated_at=datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        filters_applied=filters_applied,
    )
