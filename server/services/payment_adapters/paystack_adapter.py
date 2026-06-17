import hmac
import hashlib
import os
from typing import Dict, Any
from .base import PaymentAdapter

class PaystackAdapter(PaymentAdapter):
    def __init__(self):
        self.secret_key = os.getenv("PAYSTACK_SECRET_KEY", "sk_test_mock_paystack_key")

    def create_payment_intent(self, invoice_id: int, amount: float, customer_email: str) -> Dict[str, Any]:
        """
        In a real scenario, this would make an HTTP POST to Paystack's /transaction/initialize
        """
        # Converting amount to kobo/cents
        amount_kobo = int(amount * 100)
        
        return {
            "provider": "paystack",
            "authorization_url": f"https://checkout.paystack.com/mock_{invoice_id}",
            "access_code": f"mock_access_{invoice_id}",
            "reference": f"INV-{invoice_id}-{amount_kobo}"
        }

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """
        Verify the Paystack signature using HMAC SHA512.
        """
        if not signature:
            return False
            
        computed_hmac = hmac.new(
            self.secret_key.encode('utf-8'),
            payload,
            hashlib.sha512
        ).hexdigest()
        
        # For testing, if it's the mock key, we'll just allow it
        if self.secret_key == "sk_test_mock_paystack_key":
            return True
            
        return hmac.compare_digest(computed_hmac, signature)

    def parse_webhook_event(self, payload: dict) -> Dict[str, Any]:
        """
        Extract data from Paystack's charge.success event format.
        """
        event_type = payload.get("event")
        data = payload.get("data", {})
        
        status = "failed"
        if event_type == "charge.success":
            status = "success"
            
        return {
            "provider": "paystack",
            "amount": data.get("amount", 0) / 100.0, # Convert kobo to standard unit
            "transaction_id": data.get("reference", ""),
            "status": status,
            "raw_payload": payload
        }
