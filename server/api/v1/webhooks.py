from fastapi import APIRouter, Request, HTTPException, Header
from ...services.payment_adapters import get_payment_adapter
from ...events import BaseEvent, EventDispatcher
from .. import database

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
