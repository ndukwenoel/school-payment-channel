from typing import Dict, Any
import uuid
from .base import PaymentAdapter

class MockAdapter(PaymentAdapter):
    def create_payment_intent(self, invoice_id: int, amount: float, customer_email: str) -> Dict[str, Any]:
        return {
            "provider": "mock",
            "authorization_url": f"http://localhost:8000/mock-checkout/{invoice_id}",
            "reference": f"MOCK-{invoice_id}-{int(amount)}"
        }

    def create_virtual_account(self, customer_email: str, customer_name: str) -> Dict[str, Any]:
        account_number = str(uuid.uuid4().int)[:10]
        return {
            "account_number": account_number,
            "account_name": customer_name,
            "bank_name": "Mock Bank Plc"
        }

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """
        Always returns True for local testing.
        """
        return True

    def parse_webhook_event(self, payload: dict) -> Dict[str, Any]:
        """
        Expects a simple JSON payload like {"status": "success", "amount": 500, "reference": "MOCK-123"}
        """
        return {
            "provider": "mock",
            "amount": payload.get("amount", 0),
            "transaction_id": payload.get("reference", ""),
            "status": payload.get("status", "success"),
            "raw_payload": payload
        }
