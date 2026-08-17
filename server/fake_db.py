"""
fake_db.py
----------
Temporary in-memory store that mimics what Postgres will do later.

When the real DATABASE_URL env var arrives, every line here gets
replaced with  `await pool.execute(...)` / `await pool.fetch(...)`.

Nothing else in the codebase needs to change except these two files:
    - server/routes/sync.py   →  replaces list appends with INSERT
    - server/routes/export.py →  replaces list reads   with SELECT
"""

from typing import List, Dict, Any, Optional

# ---------------------------------------------------------------------------
# The single source-of-truth while Postgres is not wired up.
# It survives the lifetime of one server process, which is exactly
# what we need to test the sync → export pipeline end-to-end.
# ---------------------------------------------------------------------------
_transactions: List[Dict[str, Any]] = []
_seen_ids: set = set()


def insert_transaction(tx: Dict[str, Any]) -> Optional[str]:
    """
    Insert a transaction. Returns None on success.
    Returns "duplicate" if a transaction with the same id already exists.
    """
    tx_id = tx.get("id")
    if tx_id and tx_id in _seen_ids:
        return "duplicate"
    _transactions.append(tx)
    if tx_id:
        _seen_ids.add(tx_id)
    return None


def get_all_transactions() -> List[Dict[str, Any]]:
    """Return a shallow copy so callers cannot mutate the store."""
    return list(_transactions)


def clear_all() -> None:
    """Wipe the store — used by tests only, never call from a route."""
    _transactions.clear()
    _seen_ids.clear()
