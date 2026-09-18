from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str
    full_name: str
    role: str = "parent"

class UserLogin(UserBase):
    password: str

class User(UserBase):
    id: int
    full_name: str
    role: str
    is_active: bool
    credit_balance: float = 0.0
    auto_pay_enabled: bool = False

    class Config:
        from_attributes = True

