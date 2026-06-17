from .base import PaymentAdapter
from .paystack_adapter import PaystackAdapter
from .mock_adapter import MockAdapter

def get_payment_adapter(provider: str = "paystack") -> PaymentAdapter:
    if provider == "paystack":
        return PaystackAdapter()
    elif provider == "mock":
        return MockAdapter()
    else:
        raise ValueError(f"Unknown payment provider: {provider}")
