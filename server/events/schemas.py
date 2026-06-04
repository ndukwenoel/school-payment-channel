from pydantic import BaseModel, Field
from typing import Any, Dict, Optional
from datetime import datetime, timezone
import uuid

class BaseEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    event_type: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    school_id: Optional[int] = None
    payload: Dict[str, Any]
    
    class Config:
        from_attributes = True
