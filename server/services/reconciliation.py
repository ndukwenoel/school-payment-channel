import re
from sqlalchemy.orm import Session
from .. import models
from ..events import BaseEvent, EventDispatcher
import logging

logger = logging.getLogger(__name__)

def parse_and_route_email_alert(db: Session, email_payload: dict):
    """
    Parses an inbound email alert, matches the account and student,
    and fires the VirtualAccountFunded event or creates an UnmatchedPayment.
    """
    # Assuming email_payload contains standard fields from an email API like SendGrid
    # For this implementation we expect standard JSON structure for demo purposes
    body = email_payload.get("text", "") or email_payload.get("html", "")
    subject = email_payload.get("subject", "")
    
    # 1. Extract Bank Account Number (mock logic: assuming it's in the email text)
    # A robust implementation would use a regex depending on the bank's email format.
    # We look for a generic "Account: 0123456789" format for this MVP.
    account_match = re.search(r'Account:\s*(\d{10})', body, re.IGNORECASE)
    
    if not account_match:
        # Check payload directly if sent parsed by a smart webhook
        account_number = email_payload.get("account_number")
        if not account_number:
            logger.error("Could not extract account number from email alert")
            return {"status": "error", "message": "No account number found"}
    else:
        account_number = account_match.group(1)

    # 2. Extract Amount
    amount_match = re.search(r'Amount:\s*(?:NGN)?\s*([\d,]+\.?\d*)', body, re.IGNORECASE)
    amount = float(amount_match.group(1).replace(',', '')) if amount_match else email_payload.get("amount", 0.0)

    # 3. Extract Narration/Transaction Reference
    # 3. Extract Narration/Transaction Reference/Desc
    narration_match = re.search(r'(?:Narration|Desc):\s*(.*)', body, re.IGNORECASE)
    narration = narration_match.group(1).strip() if narration_match else email_payload.get("narration", "")

    transaction_ref_match = re.search(r'Ref:\s*([A-Z0-9]+)', body, re.IGNORECASE)
    transaction_ref = transaction_ref_match.group(1).strip() if transaction_ref_match else email_payload.get("transaction_ref", f"TRX-{int(amount)}")

    # 4. Lookup Virtual Account
    virtual_account = db.query(models.VirtualAccount).filter(
        models.VirtualAccount.account_number == account_number
    ).first()

    if not virtual_account:
        logger.warning(f"Virtual account not found for number: {account_number}")
        # Log as UnmatchedPayment without classroom
        unmatched = models.UnmatchedPayment(
            amount=amount,
            bank_name="Unknown",
            account_number=account_number,
            transaction_ref=transaction_ref,
            narration=narration,
            status="pending"
        )
        db.add(unmatched)
        db.commit()
        return {"status": "unmatched_account", "message": "Virtual account not found"}

    # 5. Extract Enrollment Number / Student ID from narration (e.g. STU-001 or STU001)
    # Assuming enrollment_number format is 'STU-[ID]'
    stu_match = re.search(r'STU-?(\d+)', narration, re.IGNORECASE)
    matched_student = None

    if stu_match:
        enrollment_id = int(stu_match.group(1))
        # Find student by ID (assuming ID maps to enrollment number for MVP, or we would have an enrollment_number field)
        # We will use the student.id since we haven't added an explicit enrollment_number column yet,
        # but the prompt mentioned `enrollment_number`. Since `models.py` Student doesn't have it, we use `id`.
        if virtual_account.classroom_id:
            matched_student = db.query(models.Student).filter(
                models.Student.id == enrollment_id,
                models.Student.classroom_id == virtual_account.classroom_id
            ).first()
        else:
            matched_student = db.query(models.Student).filter(
                models.Student.id == enrollment_id
            ).first()
    
    # 6. Fuzzy Match Fallback
    if not matched_student and virtual_account.classroom_id:
        # Search by name in the classroom
        # Basic implementation: Check if any student's full name is in the narration
        students_in_class = db.query(models.Student).filter(
            models.Student.classroom_id == virtual_account.classroom_id
        ).all()
        
        possible_matches = []
        narration_lower = narration.lower()
        for student in students_in_class:
            full_name = student.full_name.lower() if student.full_name else ""
            
            # Simple check if name is present
            if full_name and full_name in narration_lower:
                possible_matches.append(student)
        
        # If EXACTLY one match is found, we might accept it, but as per plan:
        # "I strongly recommend flagging it for manual review to avoid misallocating funds."
        # We will NOT auto-match on fuzzy logic to be safe. We just leave matched_student as None.
        pass

    if matched_student:
        # Exact match found, fire the event
        event = BaseEvent(
            event_type="VirtualAccountFunded",
            payload={
                "student_id": matched_student.id,
                "school_id": virtual_account.school_id,
                "amount": amount,
                "reference": transaction_ref,
                "channel": "bank_transfer"
            }
        )
        EventDispatcher.publish(event)
        return {"status": "success", "message": "Matched and routed"}
    else:
        # Create Unmatched Payment for manual review
        unmatched = models.UnmatchedPayment(
            amount=amount,
            bank_name=virtual_account.bank_name,
            account_number=account_number,
            transaction_ref=transaction_ref,
            narration=narration,
            status="pending",
            school_id=virtual_account.school_id,
            classroom_id=virtual_account.classroom_id
        )
        db.add(unmatched)
        db.commit()
        return {"status": "unmatched_student", "message": "Pending manual review"}
