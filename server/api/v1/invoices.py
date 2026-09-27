from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ... import database, models, schemas
from datetime import datetime, timezone
from .auth import get_db, get_current_user, CheckRole
from ...core.rbac import requires_permission
from ...services.collection import CollectionService

router = APIRouter(
    prefix="/invoices",
    tags=["Invoices"]
)

@router.get("/", response_model=List[schemas.Invoice])
def list_invoices(
    status: str = None,
    grade: str = None,
    classroom_id: int = None,
    search: str = None,
    skip: int = 0,
    limit: int = 500,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "super_admin"]))
):
    query = db.query(models.Invoice)
    
    if current_user.role != "super_admin":
        if not current_user.school_id:
            raise HTTPException(status_code=400, detail="User not assigned to a school")
        query = query.filter(models.Invoice.school_id == current_user.school_id)
        
    if status and status.lower() != "all":
        query = query.filter(models.Invoice.status == status.lower())
        
    has_grade = grade and grade.lower() not in ["all", "all classes"]
    needs_student_join = bool(search or has_grade or classroom_id)
    if needs_student_join:
        query = query.join(models.Student)
        if has_grade:
            query = query.outerjoin(models.ClassRoom).filter(
                (models.Student.grade == grade) |
                (models.ClassRoom.name == grade)
            )
        if classroom_id:
            query = query.filter(models.Student.classroom_id == classroom_id)
        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                (models.Invoice.title.ilike(search_filter)) |
                (models.Student.full_name.ilike(search_filter)) |
                (models.Student.enrollment_number.ilike(search_filter))
            )
        
    invoices = query.order_by(models.Invoice.due_date.desc()).offset(skip).limit(limit).all()
    
    now = datetime.now(timezone.utc)
    for inv in invoices:
        due_date = inv.due_date.replace(tzinfo=timezone.utc) if inv.due_date.tzinfo is None else inv.due_date
        if inv.status in ["pending", "partial"] and now > due_date:
            inv.status = "overdue"
            
        inv.total_amount = sum(item.amount for item in inv.line_items)
        if inv.student:
            inv.student_name = inv.student.full_name
            inv.enrollment_number = inv.student.enrollment_number
            inv.student_grade = inv.student.grade
            if inv.student.classroom:
                inv.classroom_name = inv.student.classroom.name
            
    return invoices

@router.post("/", response_model=schemas.Invoice)
def create_invoice(
    invoice_data: schemas.InvoiceCreate, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(requires_permission("can_create_fee")) # Re-using permission name for now
):
    if not invoice_data.line_items:
        raise HTTPException(status_code=400, detail="Invoice must have at least one line item")
        
    # Verify student exists and belongs to the same school as the admin
    student = db.query(models.Student).filter(
        models.Student.id == invoice_data.student_id,
        models.Student.school_id == current_user.school_id
    ).first()
    
    if not student:
         raise HTTPException(status_code=404, detail="Student not found in your school")

    # Create Invoice
    new_invoice = models.Invoice(
        title=invoice_data.title,
        due_date=invoice_data.due_date,
        student_id=invoice_data.student_id,
        discount_id=invoice_data.discount_id,
        school_id=current_user.school_id,
        status="pending"
    )
    db.add(new_invoice)
    db.flush() # Flush to get new_invoice.id

    # Create Line Items
    for item in invoice_data.line_items:
        if item.amount <= 0:
            raise HTTPException(status_code=400, detail="Line item amount must be positive")
        line_item = models.InvoiceLineItem(
            invoice_id=new_invoice.id,
            title=item.title,
            amount=item.amount
        )
        db.add(line_item)

    db.commit()
    db.refresh(new_invoice)
    return new_invoice

@router.post("/bulk", response_model=dict)
def create_bulk_invoices(
    invoice_data: schemas.InvoiceBulkCreate, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(requires_permission("can_create_fee"))
):
    if not invoice_data.line_items:
        raise HTTPException(status_code=400, detail="Invoice must have at least one line item")
        
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User not assigned to a school")

    from fastapi.encoders import jsonable_encoder
    from ...worker.tasks import bulk_generate_invoices
    
    payload = jsonable_encoder(invoice_data)
    bulk_generate_invoices.delay(payload, current_user.school_id)

    return {"message": "Bulk invoice generation started in the background."}

@router.get("/student/{student_id}", response_model=List[schemas.Invoice])
def get_student_invoices(
    student_id: int, 
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    # Parent can only see their own students
    if current_user.role == "parent" and student.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied to this student's records")
        
    # Admins can only see students in their school
    if current_user.role in ["admin", "school_admin"] and student.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Access denied to students in other schools")

    invoices = db.query(models.Invoice).filter(models.Invoice.student_id == student_id).offset(skip).limit(limit).all()
    
    now = datetime.now(timezone.utc)
    updated = False
    for invoice in invoices:
        due_date = invoice.due_date.replace(tzinfo=timezone.utc) if invoice.due_date.tzinfo is None else invoice.due_date
        if invoice.status in ["pending", "partial"] and now > due_date:
            invoice.status = "overdue"
            updated = True
            
        # Dynamically calculate total_amount for the response
        invoice.total_amount = sum(item.amount for item in invoice.line_items)
    
    if updated:
        db.commit()
        
    return invoices

@router.get("/templates", response_model=List[schemas.FeeTemplate])
def get_fee_templates(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(requires_permission("can_create_fee"))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
    return db.query(models.FeeTemplate).filter(models.FeeTemplate.school_id == current_user.school_id).all()

@router.post("/templates", response_model=schemas.FeeTemplate)
def create_fee_template(
    template_data: schemas.FeeTemplateCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(requires_permission("can_create_fee"))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    new_template = models.FeeTemplate(
        name=template_data.name,
        description=template_data.description,
        school_id=current_user.school_id
    )
    db.add(new_template)
    db.flush()
    
    for item in template_data.line_items:
        db.add(models.FeeTemplateLineItem(
            template_id=new_template.id,
            title=item.title,
            amount=item.amount
        ))
        
    db.commit()
    db.refresh(new_template)
    return new_template

@router.post("/{invoice_id}/installments", response_model=schemas.InstallmentPlan)
def create_installment_plan(
    invoice_id: int,
    plan_data: schemas.InstallmentPlanCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(requires_permission("can_create_fee"))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    invoice = db.query(models.Invoice).filter(
        models.Invoice.id == invoice_id,
        models.Invoice.school_id == current_user.school_id
    ).first()
    
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
        
    if invoice.installment_plan:
        raise HTTPException(status_code=400, detail="Invoice already has an installment plan")
        
    total_invoice = sum(item.amount for item in invoice.line_items)
    total_installments = sum(inst.amount_due for inst in plan_data.installments)
    if abs(total_installments - total_invoice) > 0.01:
        raise HTTPException(status_code=400, detail="Installment total must equal invoice total")
        
    plan = models.InstallmentPlan(
        invoice_id=invoice.id,
        school_id=current_user.school_id
    )
    db.add(plan)
    db.flush()
    
    for inst in plan_data.installments:
        db.add(models.Installment(
            plan_id=plan.id,
            amount_due=inst.amount_due,
            due_date=inst.due_date,
            status="pending"
        ))
        
    db.commit()
    db.refresh(plan)
    return plan

@router.post("/{invoice_id}/plan-requests", response_model=schemas.PaymentPlanRequestResponse)
def request_payment_plan(
    invoice_id: int,
    request_data: schemas.PaymentPlanRequestCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
        
    if invoice.student.parent_id != current_user.id and current_user.role not in ["admin", "school_admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    if invoice.status == "paid":
        raise HTTPException(status_code=400, detail="Invoice already paid")

    plan_request = models.PaymentPlanRequest(
        invoice_id=invoice.id,
        proposed_installments=request_data.proposed_installments,
        reason=request_data.reason,
        status="pending",
        school_id=invoice.school_id
    )
    db.add(plan_request)
    db.commit()
    db.refresh(plan_request)
    return plan_request

@router.get("/plan-requests/all", response_model=List[schemas.PaymentPlanRequestResponse])
def list_plan_requests(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    requests = db.query(models.PaymentPlanRequest).filter(
        models.PaymentPlanRequest.school_id == current_user.school_id,
        models.PaymentPlanRequest.status == "pending"
    ).all()
    return requests

@router.post("/plan-requests/{request_id}/approve")
def approve_plan_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    plan_req = db.query(models.PaymentPlanRequest).filter(models.PaymentPlanRequest.id == request_id).first()
    if not plan_req or plan_req.school_id != current_user.school_id:
        raise HTTPException(status_code=404, detail="Request not found")
        
    if plan_req.status != "pending":
        raise HTTPException(status_code=400, detail="Request is not pending")
        
    invoice = plan_req.invoice
    
    # Check if installment plan already exists
    if invoice.installment_plan:
        raise HTTPException(status_code=400, detail="Invoice already has an installment plan")

    plan_req.status = "approved"
    
    # Create the installment plan
    plan = models.InstallmentPlan(
        invoice_id=invoice.id,
        school_id=current_user.school_id
    )
    db.add(plan)
    db.flush()
    
    for inst in plan_req.proposed_installments:
        from datetime import datetime
        db.add(models.Installment(
            plan_id=plan.id,
            amount_due=inst["amount"],
            due_date=datetime.fromisoformat(inst["due_date"].replace("Z", "+00:00")),
            status="pending"
        ))
        
    db.commit()
    return {"status": "success", "message": "Payment plan request approved and plan created"}

@router.post("/plan-requests/{request_id}/reject")
def reject_plan_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    plan_req = db.query(models.PaymentPlanRequest).filter(models.PaymentPlanRequest.id == request_id).first()
    if not plan_req or plan_req.school_id != current_user.school_id:
        raise HTTPException(status_code=404, detail="Request not found")
        
    if plan_req.status != "pending":
        raise HTTPException(status_code=400, detail="Request is not pending")
        
    plan_req.status = "rejected"
    db.commit()
    return {"status": "success", "message": "Payment plan request rejected"}

@router.post("/{invoice_id}/pay-with-balance")
def pay_invoice_with_balance(
    invoice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can pay with balance")
        
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
        
    if invoice.student.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    if invoice.status == "paid":
        raise HTTPException(status_code=400, detail="Invoice already paid")
        
    # Calculate amount due
    total_amount = sum(item.amount for item in invoice.line_items)
    
    if current_user.credit_balance < total_amount:
        raise HTTPException(
            status_code=400, 
            detail=f"Insufficient balance. Need {total_amount}, have {current_user.credit_balance}"
        )
        
    # Deduct from balance
    current_user.credit_balance -= total_amount
    invoice.status = "paid"
    
    # Record payment attempt
    attempt = models.PaymentAttempt(
        invoice_id=invoice.id,
        amount=total_amount,
        provider="credit_balance",
        status="success",
        school_id=invoice.school_id
    )
    db.add(attempt)
    
    # Record Ledger Transaction (Debit Parent Wallet, Credit School Revenue)
    from ...core.ledger import record_event_transaction
    if invoice.school_id:
        record_event_transaction(
            db=db,
            school_id=invoice.school_id,
            description=f"Invoice {invoice.id} paid via Credit Balance",
            event_type="payment.balance_used",
            provider="credit_balance",
            amount=total_amount,
            fallback_debit="Parent Wallet",
            fallback_credit="School Revenue"
        )
        
    db.commit()
    return {"status": "success", "message": "Invoice paid successfully", "new_balance": current_user.credit_balance}

@router.get("/{invoice_id}", response_model=schemas.InvoiceDetail)
def get_invoice_detail(
    invoice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    if current_user.role == "parent":
        if not invoice.student or invoice.student.parent_id != current_user.id:
            raise HTTPException(status_code=403, detail="Access denied")
    elif current_user.role != "super_admin":
        if not current_user.school_id or invoice.school_id != current_user.school_id:
            raise HTTPException(status_code=403, detail="Access denied")

    total_amount = sum(item.amount for item in invoice.line_items)
    successful_payments = [p for p in invoice.payment_attempts if p.status == "success"]
    amount_paid = sum(p.amount for p in successful_payments)

    now = datetime.now(timezone.utc)
    due_date = invoice.due_date.replace(tzinfo=timezone.utc) if invoice.due_date.tzinfo is None else invoice.due_date

    if invoice.status != "voided":
        if amount_paid >= total_amount and total_amount > 0:
            invoice.status = "paid"
        elif amount_paid > 0:
            invoice.status = "partial"
        elif now > due_date:
            invoice.status = "overdue"

    invoice.total_amount = total_amount
    invoice.amount_paid = amount_paid
    invoice.amount_outstanding = max(0.0, total_amount - amount_paid)

    if invoice.student:
        invoice.student_name = invoice.student.full_name
        invoice.enrollment_number = invoice.student.enrollment_number
        invoice.student_grade = invoice.student.grade
        if invoice.student.parent:
            invoice.parent_name = invoice.student.parent.full_name
            invoice.parent_email = invoice.student.parent.email
        invoice.parent_phone = invoice.student.emergency_contact_phone

    return invoice

@router.post("/{invoice_id}/record-offline-payment", response_model=schemas.InvoiceDetail)
def record_offline_payment(
    invoice_id: int,
    payment_data: schemas.OfflinePaymentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "super_admin"]))
):
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    if current_user.role != "super_admin" and invoice.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Access denied")

    if invoice.status == "paid":
        raise HTTPException(status_code=400, detail="Invoice is already fully paid")

    if invoice.status == "voided":
        raise HTTPException(status_code=400, detail="Cannot record payment against a voided invoice")

    if payment_data.amount <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be greater than zero")

    total_amount = sum(item.amount for item in invoice.line_items)
    current_paid = sum(p.amount for p in invoice.payment_attempts if p.status == "success")
    outstanding = max(0.0, total_amount - current_paid)

    if payment_data.amount > outstanding + 0.01:
        raise HTTPException(status_code=400, detail=f"Amount exceeds outstanding balance of ₦{outstanding:.2f}")

    ref = payment_data.reference or f"BURSAR-{payment_data.payment_method.upper()}-{int(datetime.now().timestamp())}"

    attempt = models.PaymentAttempt(
        invoice_id=invoice.id,
        amount=payment_data.amount,
        provider=payment_data.payment_method,
        status="success",
        transaction_id=ref,
        school_id=invoice.school_id
    )
    db.add(attempt)

    new_paid = current_paid + payment_data.amount
    if new_paid >= total_amount - 0.01:
        invoice.status = "paid"
    else:
        invoice.status = "partial"

    from ...core.ledger import record_event_transaction
    if invoice.school_id:
        record_event_transaction(
            db=db,
            school_id=invoice.school_id,
            description=f"Bursar {payment_data.payment_method.upper()} payment for Invoice #{invoice.id} ({ref})",
            event_type="payment.offline_recorded",
            provider=payment_data.payment_method,
            amount=payment_data.amount,
            fallback_debit="School Cash / Bank",
            fallback_credit="School Revenue"
        )

    db.commit()
    db.refresh(invoice)

    invoice.total_amount = total_amount
    invoice.amount_paid = new_paid
    invoice.amount_outstanding = max(0.0, total_amount - new_paid)

    if invoice.student:
        invoice.student_name = invoice.student.full_name
        invoice.enrollment_number = invoice.student.enrollment_number
        invoice.student_grade = invoice.student.grade
        if invoice.student.parent:
            invoice.parent_name = invoice.student.parent.full_name
            invoice.parent_email = invoice.student.parent.email
        invoice.parent_phone = invoice.student.emergency_contact_phone

    return invoice

@router.post("/{invoice_id}/send-reminder")
def send_invoice_reminder(
    invoice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "super_admin"]))
):
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    if current_user.role != "super_admin" and invoice.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Access denied")

    recipient_email = None
    if invoice.student and invoice.student.parent:
        recipient_email = invoice.student.parent.email

    if not recipient_email:
        raise HTTPException(status_code=400, detail="Parent email not found for this student")

    total_amount = sum(item.amount for item in invoice.line_items)
    paid = sum(p.amount for p in invoice.payment_attempts if p.status == "success")
    outstanding = max(0.0, total_amount - paid)

    new_log = models.NotificationLog(
        recipient_email=recipient_email,
        subject=f"Fee Reminder: {invoice.title} (INV-{invoice.id})",
        message=f"Dear Parent, this is an automated reminder regarding the outstanding balance of ₦{outstanding:,.2f} for {invoice.student.full_name}. Due Date: {invoice.due_date.strftime('%Y-%m-%d')}.",
        status="sent",
        school_id=invoice.school_id
    )
    db.add(new_log)
    db.commit()

    return {"status": "success", "message": f"Payment reminder logged and dispatched to {recipient_email}"}

@router.post("/{invoice_id}/void")
def void_invoice(
    invoice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "super_admin"]))
):
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    if current_user.role != "super_admin" and invoice.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Access denied")

    if invoice.status == "paid":
        raise HTTPException(status_code=400, detail="Cannot void a fully paid invoice")

    invoice.status = "voided"
    db.commit()

    return {"status": "success", "message": f"Invoice INV-{invoice.id} marked as voided"}
