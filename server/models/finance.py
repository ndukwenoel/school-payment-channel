from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


class VirtualAccount(Base):
    __tablename__ = "virtual_accounts"
    id = Column(Integer, primary_key=True, index=True)
    account_number = Column(String, unique=True, index=True)
    account_name = Column(String)
    bank_name = Column(String)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=True)
    classroom_id = Column(Integer, ForeignKey("classrooms.id"), nullable=True)
    school_id = Column(Integer, ForeignKey("schools.id"))
    status = Column(String, default="active") # active, inactive
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    student = relationship("Student", back_populates="virtual_accounts")
    classroom = relationship("ClassRoom", back_populates="virtual_accounts")
    school = relationship("School")

class Invoice(Base):
    __tablename__ = "invoices"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String) # e.g. "Term 1 Invoice"
    due_date = Column(DateTime)
    status = Column(String, default="pending") # pending, paid, partial, overdue
    late_fee_applied = Column(Boolean, default=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    student_id = Column(Integer, ForeignKey("students.id"))
    discount_id = Column(Integer, ForeignKey("discounts.id"), nullable=True)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    student = relationship("Student", back_populates="invoices")
    discount = relationship("Discount", back_populates="invoices")
    line_items = relationship("InvoiceLineItem", back_populates="invoice")
    payment_attempts = relationship("PaymentAttempt", back_populates="invoice")
    installment_plan = relationship("InstallmentPlan", back_populates="invoice", uselist=False)

class InvoiceLineItem(Base):
    __tablename__ = "invoice_line_items"
    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    title = Column(String)
    amount = Column(Float)
    invoice = relationship("Invoice", back_populates="line_items")

class PaymentAttempt(Base):
    __tablename__ = "payment_attempts"
    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    amount = Column(Float)
    provider = Column(String) # paystack, flutterwave, mock, manual_transfer
    status = Column(String, default="pending") # pending, success, failed, pending_verification
    transaction_id = Column(String, nullable=True) # Used for Opay/Bank reference number
    receipt_url = Column(String, nullable=True) # Optional uploaded receipt image
    payment_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    invoice = relationship("Invoice", back_populates="payment_attempts")

class PaymentBundle(Base):
    __tablename__ = "payment_bundles"
    id = Column(Integer, primary_key=True, index=True)
    reference = Column(String, unique=True, index=True) # e.g. BNDL-1234
    total_amount = Column(Float)
    status = Column(String, default="pending") # pending, paid
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"))
    items = relationship("PaymentBundleItem", back_populates="bundle")

class PaymentBundleItem(Base):
    __tablename__ = "payment_bundle_items"
    id = Column(Integer, primary_key=True, index=True)
    bundle_id = Column(Integer, ForeignKey("payment_bundles.id"))
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    amount_allocated = Column(Float)
    bundle = relationship("PaymentBundle", back_populates="items")
    invoice = relationship("Invoice")

class PaymentPlanRequest(Base):
    __tablename__ = "payment_plan_requests"
    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    parent_id = Column(Integer, ForeignKey("users.id"))
    proposed_plan = Column(String) # JSON string of proposed installments
    reason = Column(String)
    status = Column(String, default="pending") # pending, approved, rejected
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"))
    invoice = relationship("Invoice")
    parent = relationship("User")

class FeeTemplate(Base):
    __tablename__ = "fee_templates"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Standard Grade 10 Tuition"
    description = Column(String, nullable=True)
    school_id = Column(Integer, ForeignKey("schools.id"))
    line_items = relationship("FeeTemplateLineItem", back_populates="template")
    school = relationship("School")

class FeeTemplateLineItem(Base):
    __tablename__ = "fee_template_line_items"
    id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("fee_templates.id"))
    title = Column(String)
    amount = Column(Float)
    template = relationship("FeeTemplate", back_populates="line_items")

class InstallmentPlan(Base):
    __tablename__ = "installment_plans"
    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))
    invoice = relationship("Invoice", back_populates="installment_plan")
    installments = relationship("Installment", back_populates="plan")

class Installment(Base):
    __tablename__ = "installments"
    id = Column(Integer, primary_key=True, index=True)
    plan_id = Column(Integer, ForeignKey("installment_plans.id"))
    amount_due = Column(Float)
    due_date = Column(DateTime)
    status = Column(String, default="pending") # pending, paid, overdue
    plan = relationship("InstallmentPlan", back_populates="installments")

class Discount(Base):
    __tablename__ = "discounts"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Sibling Discount", "Staff Child"
    percentage = Column(Float, default=0.0)
    flat_amount = Column(Float, default=0.0)
    description = Column(String)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    invoices = relationship("Invoice", back_populates="discount")

class LedgerAccount(Base):
    __tablename__ = "ledger_accounts"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g., "Parent Wallet", "School Revenue"
    type = Column(String) # asset, liability, equity, revenue, expense
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

class LedgerTransaction(Base):
    __tablename__ = "ledger_transactions"
    id = Column(Integer, primary_key=True, index=True)
    description = Column(String)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    entries = relationship("LedgerEntry", back_populates="transaction")

class LedgerEntry(Base):
    __tablename__ = "ledger_entries"
    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(Integer, ForeignKey("ledger_transactions.id"))
    account_id = Column(Integer, ForeignKey("ledger_accounts.id"))
    amount = Column(Float)
    type = Column(String) # "debit" or "credit"
    transaction = relationship("LedgerTransaction", back_populates="entries")
    account = relationship("LedgerAccount")

class PostingRule(Base):
    __tablename__ = "posting_rules"
    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String) # e.g. "payment.received", "payment.exception"
    provider = Column(String, nullable=True) # e.g. "paystack", "mock", "virtual_account"
    debit_account_name = Column(String)
    credit_account_name = Column(String)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

class Expense(Base):
    __tablename__ = "expenses"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    amount = Column(Float)
    category = Column(String) # e.g. "Utilities", "Vendor", "Payroll"
    payment_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"))
    recorded_by_id = Column(Integer, ForeignKey("users.id"))
    school = relationship("School")
    recorded_by = relationship("User")

class UnmatchedPayment(Base):
    __tablename__ = "unmatched_payments"
    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float)
    bank_name = Column(String)
    account_number = Column(String)
    transaction_ref = Column(String)
    narration = Column(String)
    status = Column(String, default="pending") # pending, resolved
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"))
    classroom_id = Column(Integer, ForeignKey("classrooms.id"), nullable=True)
    resolved_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    school = relationship("School")
    classroom = relationship("ClassRoom")
    resolved_by = relationship("User")
