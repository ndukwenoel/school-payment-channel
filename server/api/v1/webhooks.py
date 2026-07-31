from fastapi import APIRouter, Request, HTTPException, Header, Depends
from ...services.payment_adapters import get_payment_adapter
from ...services.reconciliation import parse_and_route_email_alert
from ...events import BaseEvent, EventDispatcher
from ...database import get_db
from sqlalchemy.orm import Session

router = APIRouter(
    prefix="/webhooks",
    tags=["Webhooks"]
)

@router.post("/{provider}")
async def receive_webhook(
    provider: str,
    request: Request,
    x_paystack_signature: str = Header(None)
):
    try:
        adapter = get_payment_adapter(provider)
    except ValueError:
        raise HTTPException(status_code=400, detail="Unsupported payment provider")

    payload_bytes = await request.body()
    payload_dict = await request.json()

    # Determine signature from headers based on provider
    signature = ""
    if provider == "paystack":
        signature = x_paystack_signature
    elif provider == "mock":
        signature = "mock_signature"

    if not adapter.verify_webhook_signature(payload_bytes, signature):
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

    parsed_event = adapter.parse_webhook_event(payload_dict)
    
    # Ideally, we look up the school_id from the transaction reference via DB, but let's publish
    # the event and let the Celery worker look it up, or do a quick lookup here.
    # For now, we publish without school_id and the Reconciliation engine finds the attempt
    
    event = BaseEvent(
        event_type="PaymentReceived",
        payload={
            "provider": parsed_event["provider"],
            "amount": parsed_event["amount"],
            "transaction_id": parsed_event["transaction_id"],
            "status": parsed_event["status"],
            "raw": parsed_event["raw_payload"]
        }
    )
    
    EventDispatcher.publish(event)
    return {"status": "success"}

@router.post("/inbound-email")
async def receive_email_webhook(
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Webhook endpoint to receive parsed emails from SendGrid Inbound Parse or Postmark.
    """
    try:
        # Most email APIs send as multipart form-data or JSON. 
        # We assume JSON for this MVP.
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    result = parse_and_route_email_alert(db, payload)
    return result
