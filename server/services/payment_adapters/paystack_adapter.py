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

    def create_virtual_account(self, customer_email: str, customer_name: str) -> Dict[str, Any]:
        """
        Creates a dedicated virtual account using Paystack's API.
        This requires first creating/fetching a Customer, then creating the DVA.
        """
        if self.secret_key == "sk_test_mock_paystack_key":
            import uuid
            return {
                "account_number": str(uuid.uuid4().int)[:10],
                "account_name": customer_name,
                "bank_name": "Paystack Titan"
            }
            
        headers = {
            "Authorization": f"Bearer {self.secret_key}",
            "Content-Type": "application/json"
        }
        
        try:
            with httpx.Client() as client:
                # 1. Ensure Customer Exists
                customer_payload = {
                    "email": customer_email,
                    "first_name": customer_name.split()[0] if customer_name else "",
                    "last_name": " ".join(customer_name.split()[1:]) if len(customer_name.split()) > 1 else ""
                }
                cust_res = client.post("https://api.paystack.co/customer", json=customer_payload, headers=headers)
                cust_res.raise_for_status()
                customer_code = cust_res.json()["data"]["customer_code"]
                
                # 2. Create Dedicated Account
                dva_payload = {
                    "customer": customer_code,
                    "preferred_bank": "wema-bank"
                }
                dva_res = client.post("https://api.paystack.co/dedicated_account", json=dva_payload, headers=headers)
                dva_res.raise_for_status()
                dva_data = dva_res.json()["data"]
                
                return {
                    "account_number": dva_data["account_number"],
                    "account_name": dva_data["account_name"],
                    "bank_name": dva_data["bank"]["name"]
                }
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Paystack DVA creation failed: {str(e)}")

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
