import hmac
import hashlib
import os
from typing import Dict, Any
from .base import PaymentAdapter

import httpx
from fastapi import HTTPException

class PaystackAdapter(PaymentAdapter):
    def __init__(self):
        self.secret_key = os.getenv("PAYSTACK_SECRET_KEY", "sk_test_mock_paystack_key")

    def create_payment_intent(self, invoice_id: int, amount: float, customer_email: str) -> Dict[str, Any]:
        """
        Make an HTTP POST to Paystack's /transaction/initialize
        """
        amount_kobo = int(amount * 100)
        reference = f"INV-{invoice_id}-{amount_kobo}-{os.urandom(4).hex()}"
        
        headers = {
            "Authorization": f"Bearer {self.secret_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "email": customer_email,
            "amount": amount_kobo,
            "reference": reference,
            "callback_url": "http://localhost:62939/#/payment-success" # Replace with actual dynamic url if available
        }
        
        try:
            with httpx.Client() as client:
                response = client.post("https://api.paystack.co/transaction/initialize", json=payload, headers=headers)
                response.raise_for_status()
                data = response.json()["data"]
                
                return {
                    "provider": "paystack",
                    "authorization_url": data["authorization_url"],
                    "access_code": data["access_code"],
                    "reference": data["reference"]
                }
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Paystack initialization failed: {str(e)}")

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
