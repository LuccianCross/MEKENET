"""
tests/test_sync_export.py
--------------------------
End-to-end tests for the sync → store → export pipeline.

Uses an in-memory SQLite database for isolation — no real Postgres needed.
Run with:
    cd server
    pip install pytest httpx
    pytest tests/test_sync_export.py -v
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from db.database import Base, get_db
from models.transaction import Transaction  # noqa: F401 — ensures model is registered
from routes import sync, export

TEST_DATABASE_URL = "sqlite:///:memory:"
test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app = FastAPI()
app.include_router(sync.router)
app.include_router(export.router)
app.dependency_overrides[get_db] = override_get_db

# Disable startup events (Neon connection) during tests
app.router.on_startup.clear()

client = TestClient(app)
HEADERS = {"X-Device-ID": "test-device-001"}


@pytest.fixture(autouse=True)
def setup_and_teardown():
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


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


class TestSync:

    def test_sync_single_income(self):
        response = client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        assert response.status_code == 201
        body = response.json()
        assert body["success"] is True
        assert body["transaction_id"] == "tx001"
        assert body["stored_count"] == 1

    def test_sync_single_expense(self):
        response = client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)
        assert response.status_code == 201
        assert response.json()["stored_count"] == 1

    def test_sync_multiple_builds_count(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)
        assert response.json()["stored_count"] == 2

    def test_sync_defaults_date_to_today(self):
        payload = {**INCOME_TX, "date": None}
        response = client.post("/sync/", json=payload, headers=HEADERS)
        assert response.status_code == 201

    def test_sync_rejects_zero_amount(self):
        payload = {**INCOME_TX, "amount": 0}
        response = client.post("/sync/", json=payload, headers=HEADERS)
        assert response.status_code == 422

    def test_sync_rejects_negative_amount(self):
        payload = {**INCOME_TX, "amount": -50}
        response = client.post("/sync/", json=payload, headers=HEADERS)
        assert response.status_code == 422

    def test_sync_rejects_invalid_type(self):
        payload = {**INCOME_TX, "type": "transfer"}
        response = client.post("/sync/", json=payload, headers=HEADERS)
        assert response.status_code == 422

    def test_sync_rejects_bad_date_format(self):
        payload = {**INCOME_TX, "date": "17-08-2026"}
        response = client.post("/sync/", json=payload, headers=HEADERS)
        assert response.status_code == 422

    def test_sync_strips_description_whitespace(self):
        payload = {**INCOME_TX, "description": "  Sold shoes  "}
        response = client.post("/sync/", json=payload, headers=HEADERS)
        assert response.status_code == 201
        with test_engine.connect() as conn:
            result = conn.execute(text("SELECT description FROM transactions LIMIT 1"))
            row = result.fetchone()
            assert row[0] == "Sold shoes"

    def test_sync_rejects_missing_device_id(self):
        response = client.post("/sync/", json=INCOME_TX)
        assert response.status_code == 401
        assert "X-Device-ID" in response.json()["detail"]

    def test_sync_deduplicates_same_id(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        assert response.status_code == 201
        body = response.json()
        assert body["success"] is True
        assert "deduplicated" in body["message"]
        assert body["stored_count"] == 1

    def test_sync_allows_different_ids(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)
        assert response.status_code == 201
        assert response.json()["stored_count"] == 2


class TestExport:

    def test_export_with_no_data_returns_404(self):
        response = client.get("/export/", headers=HEADERS)
        assert response.status_code == 404

    def test_export_rejects_missing_device_id(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.get("/export/")
        assert response.status_code == 401

    def test_export_single_income_transaction(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.get("/export/", headers=HEADERS)
        assert response.status_code == 200

        report = response.json()
        assert report["summary"]["total_income"] == 500.0
        assert report["summary"]["total_expense"] == 0.0
        assert report["summary"]["net_balance"] == 500.0
        assert report["summary"]["transaction_count"] == 1

    def test_export_income_and_expense(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)

        report = client.get("/export/", headers=HEADERS).json()

        assert report["summary"]["total_income"] == 500.0
        assert report["summary"]["total_expense"] == 200.0
        assert report["summary"]["net_balance"] == 300.0
        assert report["summary"]["transaction_count"] == 2

    def test_export_multiple_transactions(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)
        client.post("/sync/", json=SECOND_INCOME_TX, headers=HEADERS)

        report = client.get("/export/", headers=HEADERS).json()

        assert report["summary"]["total_income"] == 1500.0
        assert report["summary"]["total_expense"] == 200.0
        assert report["summary"]["net_balance"] == 1300.0
        assert report["summary"]["transaction_count"] == 3

    def test_export_category_breakdown_income(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=SECOND_INCOME_TX, headers=HEADERS)

        report = client.get("/export/", headers=HEADERS).json()
        income_cats = {c["category"]: c for c in report["income_by_category"]}

        assert "sales" in income_cats
        assert income_cats["sales"]["total"] == 500.0
        assert income_cats["sales"]["count"] == 1

        assert "freelance" in income_cats
        assert income_cats["freelance"]["total"] == 1000.0

    def test_export_category_breakdown_expense(self):
        client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)

        report = client.get("/export/", headers=HEADERS).json()
        expense_cats = {c["category"]: c for c in report["expense_by_category"]}

        assert "office" in expense_cats
        assert expense_cats["office"]["total"] == 200.0

    def test_export_contains_full_transaction_list(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)

        report = client.get("/export/", headers=HEADERS).json()

        ids = [t["id"] for t in report["transactions"]]
        assert "tx001" in ids
        assert "tx002" in ids

    def test_export_transactions_sorted_newest_first(self):
        client.post("/sync/", json=SECOND_INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)

        report = client.get("/export/", headers=HEADERS).json()
        dates = [t["date"] for t in report["transactions"]]
        assert dates == sorted(dates, reverse=True)

    def test_export_filter_by_type_income(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)

        report = client.get("/export/?type=income", headers=HEADERS).json()

        assert report["summary"]["transaction_count"] == 1
        assert report["summary"]["total_income"] == 500.0
        assert report["summary"]["total_expense"] == 0.0
        assert report["filters_applied"]["type"] == "income"

    def test_export_filter_by_type_expense(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=EXPENSE_TX, headers=HEADERS)

        report = client.get("/export/?type=expense", headers=HEADERS).json()

        assert report["summary"]["transaction_count"] == 1
        assert report["summary"]["total_expense"] == 200.0

    def test_export_filter_by_date_range(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        client.post("/sync/", json=SECOND_INCOME_TX, headers=HEADERS)

        report = client.get(
            "/export/?from_date=2026-08-15&to_date=2026-08-17",
            headers=HEADERS,
        ).json()

        assert report["summary"]["transaction_count"] == 1
        assert report["summary"]["total_income"] == 500.0

    def test_export_report_is_not_hardcoded(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        report1 = client.get("/export/", headers=HEADERS).json()

        Base.metadata.drop_all(bind=test_engine)
        Base.metadata.create_all(bind=test_engine)

        client.post("/sync/", json=SECOND_INCOME_TX, headers=HEADERS)
        report2 = client.get("/export/", headers=HEADERS).json()

        assert report1["summary"]["total_income"] != report2["summary"]["total_income"]
        assert report1["summary"]["total_income"] == 500.0
        assert report2["summary"]["total_income"] == 1000.0

    def test_export_has_generated_at_timestamp(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        report = client.get("/export/", headers=HEADERS).json()
        assert "generated_at" in report
        assert report["generated_at"].endswith("Z")

    def test_export_invalid_type_filter_returns_400(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.get("/export/?type=transfer", headers=HEADERS)
        assert response.status_code == 400

    def test_export_invalid_date_format_returns_400(self):
        client.post("/sync/", json=INCOME_TX, headers=HEADERS)
        response = client.get("/export/?from_date=17-08-2026", headers=HEADERS)
        assert response.status_code == 400
