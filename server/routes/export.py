"""
routes/export.py
----------------
GET /export

Reads everything from the Postgres database and computes a human-readable
financial report.
"""

from collections import defaultdict
from datetime import datetime, timezone
from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from db.database import get_db
from models.transaction import Transaction

router = APIRouter(prefix="/export", tags=["export"])


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
    summary: Dict
    income_by_category: List[CategoryBreakdown]
    expense_by_category: List[CategoryBreakdown]
    transactions: List[TransactionSummary]
    generated_at: str
    filters_applied: Dict


def _build_category_breakdown(txs: List[Dict], tx_type: str) -> List[CategoryBreakdown]:
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


@router.get(
    "/",
    response_model=ExportReport,
    status_code=status.HTTP_200_OK,
    summary="Export a financial report from synced transactions",
)
def export_report(
    from_date: Optional[str] = Query(default=None),
    to_date: Optional[str] = Query(default=None),
    type_filter: Optional[str] = Query(default=None, alias="type"),
    x_device_id: Optional[str] = Header(default=None, alias="X-Device-ID"),
    db: Session = Depends(get_db),
) -> ExportReport:
    if not x_device_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-Device-ID header",
        )

    query = db.query(Transaction)

    if from_date:
        try:
            datetime.strptime(from_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(400, "from_date must be YYYY-MM-DD")
        query = query.filter(Transaction.date >= from_date)

    if to_date:
        try:
            datetime.strptime(to_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(400, "to_date must be YYYY-MM-DD")
        query = query.filter(Transaction.date <= to_date)

    if type_filter:
        if type_filter not in ("income", "expense"):
            raise HTTPException(400, "type must be 'income' or 'expense'")
        query = query.filter(Transaction.type == type_filter)

    rows = query.order_by(Transaction.date.desc()).all()

    if not rows:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No transactions found. Call POST /sync first to load some data.",
        )

    txs = [
        {
            "id": r.id,
            "type": r.type,
            "amount": r.amount,
            "description": r.description,
            "date": r.date,
            "category": r.category or "uncategorized",
            "currency": r.currency or "ETB",
            "synced_at": r.synced_at.isoformat().replace("+00:00", "Z") if r.synced_at else "",
        }
        for r in rows
    ]

    total_income = round(sum(t["amount"] for t in txs if t["type"] == "income"), 2)
    total_expense = round(sum(t["amount"] for t in txs if t["type"] == "expense"), 2)

    filters_applied: Dict = {}
    if from_date:
        filters_applied["from_date"] = from_date
    if to_date:
        filters_applied["to_date"] = to_date
    if type_filter:
        filters_applied["type"] = type_filter

    return ExportReport(
        summary={
            "total_income": total_income,
            "total_expense": total_expense,
            "net_balance": round(total_income - total_expense, 2),
            "transaction_count": len(txs),
            "currency": txs[0]["currency"] if txs else "ETB",
        },
        income_by_category=_build_category_breakdown(txs, "income"),
        expense_by_category=_build_category_breakdown(txs, "expense"),
        transactions=[
            TransactionSummary(
                id=t["id"],
                type=t["type"],
                amount=t["amount"],
                description=t["description"],
                date=t["date"],
                category=t["category"],
                currency=t["currency"],
                synced_at=t["synced_at"],
            )
            for t in txs
        ],
        generated_at=datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        filters_applied=filters_applied,
    )
