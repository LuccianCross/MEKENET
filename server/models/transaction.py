from sqlalchemy import Column, String, Float, DateTime, Boolean, Index
from sqlalchemy.sql import func
from db.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True)
    type = Column(String, nullable=False)  # "income" or "expense"
    amount = Column(Float, nullable=False)
    description = Column(String, nullable=False)
    date = Column(String, nullable=False)  # YYYY-MM-DD
    category = Column(String, default="uncategorized")
    currency = Column(String(10), default="ETB")
    source = Column(String, nullable=True)  # "telebirr", "cbe", "awash"
    raw_sms_hash = Column(String, nullable=True, index=True)  # SHA256 hash for deduplication
    device_id = Column(String, nullable=True)
    synced_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    __table_args__ = (
        Index('ix_transaction_sms_hash', 'raw_sms_hash'),
    )
