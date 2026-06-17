# Educational Financial Operating System: Product Reorganization & Backlog

> [!NOTE]
> This document serves as the master blueprint for transitioning the platform from a standard School ERP with payment collection into an **Educational Financial Operating System**. It preserves all valid existing architectural assets and reframes the roadmap into actionable engineering and product deliverables.

## 1. Executive Summary

Our platform is evolving into the definitive **Educational Financial Operating System**. While the existing School ERP functionality provides critical contextual data (academics, attendance, HR), our core competitive advantage lies in financial intelligence. 

The system centers on five pillars: **Identity Engine, Collection Engine, Reconciliation Engine, Institutional Ledger,** and **Student Lifecycle Context**. We act as the intelligence layer—we do not hold funds or run internal wallets. Payments settle directly via licensed providers through a modular Payment Adapter Layer, and our system tracks, reconciles, and reports on these lifecycles seamlessly.

## 2. Strategic Alignment Notes

*   **Existing Assets Preserved:** We are retaining the FastAPI backend, multi-tenant architecture, RBAC permissions, immutable double-entry ledger, Celery/Redis async processing, and all existing ERP domains (Student, HR, Academics, Inventory).
*   **No Internal Wallets:** We do not hold customer funds; we track obligations and settlements.
*   **Adapter Pattern:** Payment providers are interchangeable infrastructure accessed through a Payment Adapter Layer.
*   **Focus on Context:** All new features must strengthen Collection, Reconciliation, Ledger accuracy, Reporting, or Student Lifecycle intelligence.

---

## 3. Updated Roadmap

The roadmap is structured into three subsequent phases to ensure continuous delivery while laying foundational infrastructure.

### Phase 2: Collection Infrastructure
*Focus: Robust billing, multi-channel payment requests, and provider abstraction.*
*   Payment Adapter Layer implementation
*   Advanced Invoice Engine
*   Webhook Management & Event Routing

### Phase 3: Reconciliation Infrastructure
*Focus: Automated tracking, matching, and posting to the ledger.*
*   Automated Transaction Matching (Provider webhooks vs. Internal invoices)
*   Exception Handling Queues
*   Ledger Posting Rules Engine

### Phase 4: Financial Intelligence Platform
*Focus: Analytics, contextual automation, and institutional reporting.*
*   Settlement Verification (Provider payouts vs. Bank statements)
*   Revenue tracking & forecasting
*   Automated financial workflows driven by Student Lifecycle events

---

## 4. Engineering Epics

### Phase 2: Collection Infrastructure
**Epic: Payment Adapter Layer**
*   Create `PaymentProvider` interface.
*   Implement Stripe/Paystack/Flutterwave adapters.
*   Build webhook ingestion endpoints for each adapter.

**Epic: Invoice & Billing Engine**
*   Fee template creation and management.
*   Bulk invoice generation based on `Student.enrollment` or `ClassRoom`.
*   Invoice reminders via asynchronous Celery tasks.
*   Installment plans and partial payment tracking.

### Phase 3: Reconciliation Infrastructure
**Epic: Reconciliation Engine**
*   Matching algorithm (Webhook payload `transaction_id` -> `Invoice`).
*   Exception Handling UI for Finance Teams (Unmatched transactions).
*   Handling overpayments and underpayments.

**Epic: Ledger Automation**
*   Automated double-entry posting rules (e.g., Credit Accounts Receivable, Debit Cash).
*   Audit trail linking `LedgerEntry` to `WebhookEvent`.

### Phase 4: Financial Intelligence Platform
**Epic: Settlement Tracking**
*   Upload/Ingest bank settlement reports.
*   Match aggregated provider payouts against bank deposits.
*   Identify fee deductions by payment providers.

**Epic: Advanced Reporting**
*   Aging reports for overdue invoices.
*   Revenue by `ClassRoom`, `Subject`, or `FeeType`.

---

## 5. Sprint Backlogs (Prioritized by Business Impact)

### Next 30 Days (Sprint 1-2)
**Goal:** Abstract payments and launch the Invoice Engine MVP.
*   Design and implement the `PaymentAdapter` interface.
*   Migrate existing `Fee` generation to the new `Invoice` model logic.
*   Implement webhook receivers and initial payload validation.
*   Establish the Event Bus structure (`events` pub/sub mechanism).

### Next 90 Days (Sprint 3-6)
**Goal:** Automate matching and stabilize the Ledger.
*   Build the `transaction matching worker` (Celery).
*   Implement automated double-entry posting upon successful match.
*   Create the Exception Queue dashboard in Flutter for unmatched payments.
*   Implement bulk invoice generation for the upcoming term/semester.

### Next 180 Days (Sprint 7-12)
**Goal:** Deepen financial intelligence and settlement tracking.
*   Build settlement verification (ingesting provider payout reports).
*   Develop revenue forecasting and aging reports.
*   Wire `Student.enrolled` and `Student.promoted` lifecycle events to automatically trigger invoice generation.

---

## 6. Architecture Backlog

### New Services Required
*   **Payment Adapter Service:** An isolated module responsible for formatting outbound requests to providers and normalizing inbound webhooks.
*   **Reconciliation Worker:** A background Celery process that attempts to match orphaned payments with open invoices continuously.

### Existing Services Requiring Enhancement
*   **Fee/Payment Models:** Must be enhanced into `Invoice`, `InvoiceLineItem`, and `PaymentAttempt` models.
*   **Ledger Engine:** Add automated posting rule definitions so developers don't hardcode debits/credits in the business logic.

### Event-Driven Architecture Requirements
*   Standardize event schemas (e.g., using Pydantic models for payload validation before publishing to Redis).
*   Ensure idempotency on all webhook consumers to prevent double-crediting the ledger.

---

## 7. Event Map

| Event Name | Publisher | Consumer(s) |
| :--- | :--- | :--- |
| `student.enrolled` | Lifecycle (ERP) | Billing (Generates Invoice) |
| `invoice.generated` | Billing | Communication (Sends Email/SMS) |
| `invoice.sent` | Communication | Audit (Logs action) |
| `payment.received` | Payment Adapter (Webhook) | Reconciliation Engine (Attempts match) |
| `payment.verified` | Reconciliation Engine | Ledger (Posts double-entry), Billing (Updates Invoice status) |
| `payment.reconciled` | Ledger | Lifecycle (Unlocks student access if blocked) |
| `receipt.generated` | Billing | Communication (Sends Receipt) |
| `invoice.overdue` | Billing (Celery Cron) | Communication (Sends Reminder), Lifecycle (Flag student) |

---

## 8. Team Allocation

*   **Backend Team:** Focus entirely on the Payment Adapter Layer, webhook idempotency, Reconciliation Celery workers, and Event Bus routing.
*   **Frontend Team (Flutter/Web):** Build the Finance Exception Dashboard, Invoice Template Builders, and Financial Reporting charts.
*   **DevOps Team:** Ensure Redis stability for Celery, configure dead-letter queues for failed events, and set up webhook monitoring/alerting.
*   **Product Team:** Negotiate with payment providers, map out localized settlement rules, and define accounting posting rules.
*   **QA Team:** Focus heavily on edge cases: webhook duplication, partial payments, failed network requests during ledger posting, and timezone issues in reporting.

---

## 9. No-Change Areas

To maintain velocity, the following areas **MUST NOT** be rewritten or significantly altered:
1.  **FastAPI Core Infrastructure:** Routing, Dependency Injection (DI), and database connection pooling.
2.  **Auth & RBAC:** The `User`, `Role`, `Permission`, and multi-tenant `School` logic works and scales; leave it alone.
3.  **Core Context Models:** `Student`, `StaffProfile`, `ClassRoom`, and `Attendance` schemas remain the source of truth.
4.  **Alembic & Migrations:** Continue using the existing pattern for all new schema changes.
5.  **Audit Logs:** Continue using the current logging mechanism for tracking user actions.
