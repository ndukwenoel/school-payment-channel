from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class DiscountBase(BaseModel):
    name: str
    percentage: float = 0.0
    flat_amount: float = 0.0
    description: Optional[str] = None

class DiscountCreate(DiscountBase):
    pass

class Discount(DiscountBase):
    id: int

    class Config:
        from_attributes = True


class InvoiceLineItemBase(BaseModel):
    title: str
    amount: float

class InvoiceLineItemCreate(InvoiceLineItemBase):
    pass

class InvoiceLineItem(InvoiceLineItemBase):
    id: int
    invoice_id: int

    class Config:
        from_attributes = True


class InvoiceBase(BaseModel):
    title: str
    due_date: datetime
    student_id: int
    discount_id: Optional[int] = None

class InvoiceCreate(InvoiceBase):
    line_items: List[InvoiceLineItemCreate]

class InvoiceBulkCreate(BaseModel):
    title: str
    due_date: datetime
    grade: str
    discount_id: Optional[int] = None
    line_items: List[InvoiceLineItemCreate]

class Invoice(InvoiceBase):
    id: int
    status: str
    late_fee_applied: bool = False
    line_items: List[InvoiceLineItem] = []

    class Config:
        from_attributes = True


class FeeTemplateLineItemBase(BaseModel):
    title: str
    amount: float

class FeeTemplateLineItemCreate(FeeTemplateLineItemBase):
    pass

class FeeTemplateLineItem(FeeTemplateLineItemBase):
    id: int
    template_id: int

    class Config:
        from_attributes = True

class FeeTemplateBase(BaseModel):
    name: str
    description: Optional[str] = None

class FeeTemplateCreate(FeeTemplateBase):
    line_items: List[FeeTemplateLineItemCreate]

class FeeTemplate(FeeTemplateBase):
    id: int
    school_id: int
    line_items: List[FeeTemplateLineItem] = []

    class Config:
        from_attributes = True


class InstallmentBase(BaseModel):
    amount_due: float
    due_date: datetime

class InstallmentCreate(InstallmentBase):
    pass

class Installment(InstallmentBase):
    id: int
    plan_id: int
    status: str

    class Config:
        from_attributes = True

class InstallmentPlanBase(BaseModel):
    invoice_id: int

class InstallmentPlanCreate(BaseModel):
    installments: List[InstallmentCreate]

class InstallmentPlan(InstallmentPlanBase):
    id: int
    school_id: int
    installments: List[Installment] = []

    class Config:
        from_attributes = True


class PaymentAttemptBase(BaseModel):
    invoice_id: int
    amount: float
    provider: str = "paystack"

class PaymentAttemptCreate(PaymentAttemptBase):
    pass

class ManualPaymentCreate(BaseModel):
    invoice_id: int
    amount: float
    reference_number: str
    receipt_url: Optional[str] = None

class PaymentAttempt(PaymentAttemptBase):
    id: int
    status: str
    transaction_id: Optional[str] = None
    receipt_url: Optional[str] = None
    payment_date: datetime

    class Config:
        from_attributes = True


class PaymentBundleCreate(BaseModel):
    invoice_ids: List[int]

class PaymentBundleItemSchema(BaseModel):
    invoice_id: int
    amount_allocated: float

class PaymentBundleResponse(BaseModel):
    id: int
    reference: str
    total_amount: float
    status: str
    created_at: datetime
    items: List[PaymentBundleItemSchema] = []

    class Config:
        from_attributes = True


class WebhookPayload(BaseModel):
    reference: str # Can be a BNDL- ref, an Invoice ref, or a Virtual Account number
    amount: float
    provider: str
    status: str # e.g. "success"
    customer_email: Optional[str] = None
    paid_at: Optional[datetime] = None


class PaymentPlanRequestCreate(BaseModel):
    proposed_plan: str
    reason: str

class PaymentPlanRequestResponse(BaseModel):
    id: int
    invoice_id: int
    parent_id: int
    proposed_plan: str
    reason: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class VirtualAccountBase(BaseModel):
    account_number: str
    account_name: str
    bank_name: str
    student_id: int
    school_id: int

class VirtualAccountCreate(VirtualAccountBase):
    pass

class VirtualAccount(VirtualAccountBase):
    id: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True



class PostingRuleBase(BaseModel):
    event_type: str
    provider: Optional[str] = None
    debit_account_name: str
    credit_account_name: str
    school_id: Optional[int] = None

class PostingRuleCreate(PostingRuleBase):
    pass

class PostingRule(PostingRuleBase):
    id: int
    class Config:
        from_attributes = True

class LedgerAccountBase(BaseModel):
    name: str
    type: str # asset, liability, equity, revenue, expense
    school_id: Optional[int] = None

class LedgerAccountCreate(LedgerAccountBase):
    pass

class LedgerAccount(LedgerAccountBase):
    id: int
    balance: float = 0.0 # Computed field
    class Config:
        from_attributes = True

class LedgerEntryBase(BaseModel):
    account_id: int
    amount: float
    type: str # debit, credit

class LedgerEntryCreate(LedgerEntryBase):
    pass

class LedgerEntry(LedgerEntryBase):
    id: int
    transaction_id: int
    account: Optional[LedgerAccount] = None
    class Config:
        from_attributes = True

class LedgerTransactionBase(BaseModel):
    description: str
    school_id: Optional[int] = None

class LedgerTransactionCreate(LedgerTransactionBase):
    entries: List[LedgerEntryCreate]

class LedgerTransaction(LedgerTransactionBase):
    id: int
    created_at: datetime
    entries: List[LedgerEntry] = []
    class Config:
        from_attributes = True



class AgingBucket(BaseModel):
    bucket: str # "0-30 days", "31-60 days", "61-90 days", "90+ days"
    total_amount: float
    invoice_ids: List[int]

class AgingReportResponse(BaseModel):
    total_overdue: float
    buckets: List[AgingBucket]

class ReminderRequest(BaseModel):
    type: str = "all" # email, sms, whatsapp, all
    target: str = "overdue_only" # overdue_only, all_parents
    custom_message: Optional[str] = None

class RevenueBreakdown(BaseModel):
    category: str
    amount: float

class RevenueReportResponse(BaseModel):
    total_revenue: float
    breakdowns: List[RevenueBreakdown] = []
    
class ExpectedSettlementResponse(BaseModel):
    total_expected: float
    total_settled: float = 0.0
    providers: dict # e.g. {"paystack": 5000, "flutterwave": 1000}


class ExpenseBase(BaseModel):
    title: str
    amount: float
    category: str
    payment_date: datetime

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    id: int
    school_id: int
    recorded_by_id: int

    class Config:
        from_attributes = True

class PlatformInvoiceBase(BaseModel):
    school_id: int
    amount_due: float
    status: str = "unpaid"
    billing_period: Optional[str] = None
    due_date: Optional[datetime] = None

class PlatformInvoiceCreate(PlatformInvoiceBase):
    pass

class PlatformInvoice(PlatformInvoiceBase):
    id: int
    created_at: datetime
    school: Optional[School] = None

    class Config:
        from_attributes = True

class SystemSettingsBase(BaseModel):
    paystack_public_key: Optional[str] = None
    paystack_secret_key: Optional[str] = None
    platform_fee_percentage: float = 1.5

class SystemSettingsUpdate(SystemSettingsBase):
    pass

class SystemSettings(SystemSettingsBase):
    id: int
    updated_at: datetime

    class Config:
        from_attributes = True

class AuditLogBase(BaseModel):
    school_id: Optional[int] = None
    user_id: Optional[int] = None
    action: str
    table_name: str
    record_id: str
    old_values: Optional[str] = None
    new_values: Optional[str] = None
    ip_address: Optional[str] = None

class AuditLog(AuditLogBase):
    id: int
    timestamp: datetime
    
    class Config:
        from_attributes = True

