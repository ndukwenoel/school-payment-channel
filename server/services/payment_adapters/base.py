from abc import ABC, abstractmethod
from typing import Dict, Any

class PaymentAdapter(ABC):
    @abstractmethod
    def create_payment_intent(self, invoice_id: int, amount: float, customer_email: str) -> Dict[str, Any]:
        """
        Creates a payment intent or initialization URL for the provider.
        Returns a dictionary with at least 'client_secret' or 'authorization_url'.
        """
        pass

    @abstractmethod
    def create_virtual_account(self, customer_email: str, customer_name: str) -> Dict[str, Any]:
        """
        Creates a dedicated/static virtual account for a customer.
        Returns a dictionary with 'account_number', 'account_name', and 'bank_name'.
        """
        pass

    @abstractmethod
    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """
        Verifies the cryptographic signature of the webhook payload.
        """
        pass

    @abstractmethod
    def parse_webhook_event(self, payload: dict) -> Dict[str, Any]:
        """
        Parses the provider-specific webhook payload into a standardized format
        suitable for the 'payment.received' domain event.
        Must return a dict with: provider, amount, transaction_id, status.
        """
        pass

