"""
tests/test_sync_export.py
--------------------------
End-to-end tests for the sync → store → export pipeline.

Run with:
    cd server
    pip install pytest httpx
    pytest tests/test_sync_export.py -v

These tests prove the acceptance criterion:
    "a fake transaction goes in through /sync
     and a real report comes out through /export"
"""

import sys
import os

# Make sure `server/` is on the path when running from the repo root
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient

import fake_db
from main import app

client = TestClient(app)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def reset_fake_db():
    """Wipe the in-memory store before every test so tests are isolated."""
    fake_db.clear_all()
    yield
    fake_db.clear_all()


# ---------------------------------------------------------------------------
# Sample payloads
# ---------------------------------------------------------------------------

INCOME_TX = {
    "id": "tx001",
    "type": "income",
    "amount": 500.0,
    "description": "Sold shoes",
    "date": "2026-08-17",
    "category": "sales",
    "currency": "ETB",
}

EXPENSE_TX = {
    "id": "tx002",
    "type": "expense",
    "amount": 200.0,
    "description": "Office supplies",
    "date": "2026-08-17",
    "category": "office",
    "currency": "ETB",
}

SECOND_INCOME_TX = {
    "id": "tx003",
    "type": "income",
    "amount": 1000.0,
    "description": "Freelance payment",
    "date": "2026-08-10",
    "category": "freelance",
    "currency": "ETB",
}


# ===========================================================================
# /sync tests
# ===========================================================================

class TestSync:

    def test_sync_single_income(self):
        """A valid income transaction returns 201 and success."""
        response = client.post("/sync/", json=INCOME_TX)
        assert response.status_code == 201
        body = response.json()
        assert body["success"] is True
        assert body["transaction_id"] == "tx001"
        assert body["stored_count"] == 1

    def test_sync_single_expense(self):
        """A valid expense transaction is stored."""
        response = client.post("/sync/", json=EXPENSE_TX)
        assert response.status_code == 201
        assert response.json()["stored_count"] == 1

    def test_sync_multiple_builds_count(self):
        """Syncing two transactions increments stored_count correctly."""
        client.post("/sync/", json=INCOME_TX)
        response = client.post("/sync/", json=EXPENSE_TX)
        assert response.json()["stored_count"] == 2

    def test_sync_defaults_date_to_today(self):
        """Omitting date should not crash — server fills in today."""
        payload = {**INCOME_TX, "date": None}
        response = client.post("/sync/", json=payload)
        assert response.status_code == 201

    def test_sync_rejects_zero_amount(self):
        """Amount of 0 is invalid — must be > 0."""
        payload = {**INCOME_TX, "amount": 0}
        response = client.post("/sync/", json=payload)
        assert response.status_code == 422

    def test_sync_rejects_negative_amount(self):
        """Negative amounts are invalid."""
        payload = {**INCOME_TX, "amount": -50}
        response = client.post("/sync/", json=payload)
        assert response.status_code == 422

    def test_sync_rejects_invalid_type(self):
        """Type must be 'income' or 'expense', nothing else."""
        payload = {**INCOME_TX, "type": "transfer"}
        response = client.post("/sync/", json=payload)
        assert response.status_code == 422

    def test_sync_rejects_bad_date_format(self):
        """Date string must be YYYY-MM-DD."""
        payload = {**INCOME_TX, "date": "17-08-2026"}
        response = client.post("/sync/", json=payload)
        assert response.status_code == 422

    def test_sync_strips_description_whitespace(self):
        """Description should be stripped of leading/trailing spaces."""
        payload = {**INCOME_TX, "description": "  Sold shoes  "}
        response = client.post("/sync/", json=payload)
        assert response.status_code == 201
        # Verify it was actually stored stripped
        stored = fake_db.get_all_transactions()
        assert stored[0]["description"] == "Sold shoes"


# ===========================================================================
# /export tests
# ===========================================================================

class TestExport:

    def test_export_with_no_data_returns_404(self):
        """Calling /export on an empty store should return 404."""
        response = client.post("/export/")
        assert response.status_code == 404

    def test_export_single_income_transaction(self):
        """
        Core acceptance test:
        sync a fake transaction → export should reflect it.
        """
        client.post("/sync/", json=INCOME_TX)
        response = client.post("/export/")
        assert response.status_code == 200

        report = response.json()
        assert report["summary"]["total_income"] == 500.0
        assert report["summary"]["total_expense"] == 0.0
        assert report["summary"]["net_balance"] == 500.0
        assert report["summary"]["transaction_count"] == 1

    def test_export_income_and_expense(self):
        """Report should compute income, expense, and net balance correctly."""
        client.post("/sync/", json=INCOME_TX)    # +500
        client.post("/sync/", json=EXPENSE_TX)  # -200

        report = client.post("/export/").json()

        assert report["summary"]["total_income"] == 500.0
        assert report["summary"]["total_expense"] == 200.0
        assert report["summary"]["net_balance"] == 300.0
        assert report["summary"]["transaction_count"] == 2

    def test_export_multiple_transactions(self):
        """Net balance should accumulate across all synced transactions."""
        client.post("/sync/", json=INCOME_TX)          # +500
        client.post("/sync/", json=EXPENSE_TX)         # -200
        client.post("/sync/", json=SECOND_INCOME_TX)   # +1000

        report = client.post("/export/").json()

        assert report["summary"]["total_income"] == 1500.0
        assert report["summary"]["total_expense"] == 200.0
        assert report["summary"]["net_balance"] == 1300.0
        assert report["summary"]["transaction_count"] == 3

    def test_export_category_breakdown_income(self):
        """Income category breakdown should group by category."""
        client.post("/sync/", json=INCOME_TX)          # sales: 500
        client.post("/sync/", json=SECOND_INCOME_TX)   # freelance: 1000

        report = client.post("/export/").json()
        income_cats = {c["category"]: c for c in report["income_by_category"]}

        assert "sales" in income_cats
        assert income_cats["sales"]["total"] == 500.0
        assert income_cats["sales"]["count"] == 1

        assert "freelance" in income_cats
        assert income_cats["freelance"]["total"] == 1000.0

    def test_export_category_breakdown_expense(self):
        """Expense category breakdown should group correctly."""
        client.post("/sync/", json=EXPENSE_TX)  # office: 200

        report = client.post("/export/").json()
        expense_cats = {c["category"]: c for c in report["expense_by_category"]}

        assert "office" in expense_cats
        assert expense_cats["office"]["total"] == 200.0

    def test_export_contains_full_transaction_list(self):
        """The transactions list in the report should contain all synced items."""
        client.post("/sync/", json=INCOME_TX)
        client.post("/sync/", json=EXPENSE_TX)

        report = client.post("/export/").json()

        ids = [t["id"] for t in report["transactions"]]
        assert "tx001" in ids
        assert "tx002" in ids

    def test_export_transactions_sorted_newest_first(self):
        """Transactions should appear newest date first."""
        client.post("/sync/", json=SECOND_INCOME_TX)   # 2026-08-10
        client.post("/sync/", json=INCOME_TX)           # 2026-08-17

        report = client.post("/export/").json()
        dates = [t["date"] for t in report["transactions"]]
        assert dates == sorted(dates, reverse=True)

    def test_export_filter_by_type_income(self):
        """?type=income filter should return only income transactions."""
        client.post("/sync/", json=INCOME_TX)
        client.post("/sync/", json=EXPENSE_TX)

        report = client.post("/export/?type=income").json()

        assert report["summary"]["transaction_count"] == 1
        assert report["summary"]["total_income"] == 500.0
        assert report["summary"]["total_expense"] == 0.0
        assert report["filters_applied"]["type"] == "income"

    def test_export_filter_by_type_expense(self):
        """?type=expense filter should return only expense transactions."""
        client.post("/sync/", json=INCOME_TX)
        client.post("/sync/", json=EXPENSE_TX)

        report = client.post("/export/?type=expense").json()

        assert report["summary"]["transaction_count"] == 1
        assert report["summary"]["total_expense"] == 200.0

    def test_export_filter_by_date_range(self):
        """Date range filter should exclude transactions outside the window."""
        client.post("/sync/", json=INCOME_TX)          # 2026-08-17
        client.post("/sync/", json=SECOND_INCOME_TX)   # 2026-08-10

        # Only ask for transactions from 2026-08-15 onwards
        report = client.post(
            "/export/?from_date=2026-08-15&to_date=2026-08-17"
        ).json()

        assert report["summary"]["transaction_count"] == 1
        assert report["summary"]["total_income"] == 500.0  # only tx001

    def test_export_report_is_not_hardcoded(self):
        """
        Prove the report changes based on what was synced.
        If the report were hardcoded, both rounds would return the same total.
        """
        # Round 1: one income of 500
        client.post("/sync/", json=INCOME_TX)
        report1 = client.post("/export/").json()

        fake_db.clear_all()

        # Round 2: one income of 1000
        client.post("/sync/", json=SECOND_INCOME_TX)
        report2 = client.post("/export/").json()

        # Totals must differ — proving the report is computed, not hardcoded
        assert report1["summary"]["total_income"] != report2["summary"]["total_income"]
        assert report1["summary"]["total_income"] == 500.0
        assert report2["summary"]["total_income"] == 1000.0

    def test_export_has_generated_at_timestamp(self):
        """Report should include a UTC timestamp."""
        client.post("/sync/", json=INCOME_TX)
        report = client.post("/export/").json()
        assert "generated_at" in report
        assert report["generated_at"].endswith("Z")

    def test_export_invalid_type_filter_returns_400(self):
        """Unknown type filter value should return 400."""
        client.post("/sync/", json=INCOME_TX)
        response = client.post("/export/?type=transfer")
        assert response.status_code == 400

    def test_export_invalid_date_format_returns_400(self):
        """Malformed date filter should return 400."""
        client.post("/sync/", json=INCOME_TX)
        response = client.post("/export/?from_date=17-08-2026")
        assert response.status_code == 400
