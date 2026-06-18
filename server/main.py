from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from . import models, database

from .api.v1 import auth, invoices, schools, students, parents, payments, notifications, reports, webhooks
from .api.v1 import erp_academic, erp_hr, erp_inventory, erp_collaboration
from .api.v1 import virtual_accounts, finance, settlements

# Create tables
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Channel")

# API V1 Router setup
from fastapi import APIRouter
v1_router = APIRouter(prefix="/api/v1")

v1_router.include_router(auth.router)
v1_router.include_router(schools.router)
v1_router.include_router(students.router)
v1_router.include_router(invoices.router)
v1_router.include_router(parents.router)
v1_router.include_router(payments.router)
v1_router.include_router(webhooks.router)
v1_router.include_router(virtual_accounts.router)
v1_router.include_router(notifications.router)
v1_router.include_router(reports.router)
v1_router.include_router(erp_academic.router)
v1_router.include_router(erp_hr.router)
v1_router.include_router(erp_inventory.router)
v1_router.include_router(erp_collaboration.router)
v1_router.include_router(finance.router)
v1_router.include_router(settlements.router)

app.include_router(v1_router)

from fastapi.responses import RedirectResponse

@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Routes Placeholder
@app.get("/api/health")
def read_root():
    return {"status": "ok", "message": "Channel API is running"}

from .events import BaseEvent, EventDispatcher

@app.post("/api/test-event")
def test_dispatch_event(event_type: str = "StudentEnrolled"):
    """
    Test endpoint to verify the event infrastructure.
    """
    payload = {}
    if event_type == "StudentEnrolled":
        payload = {"student_id": 123}
    elif event_type == "PaymentReceived":
        payload = {"payment_id": 456, "amount": 1500.0}
        
    event = BaseEvent(
        event_type=event_type,
        payload=payload,
        school_id=1
    )
    
    EventDispatcher.publish(event)
    return {"status": "published", "event_id": event.event_id, "event_type": event.event_type}

# Serve Frontend (Client)
# Ensure the client directory exists one level up or adjust path
import os
CLIENT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "client")

if os.path.exists(CLIENT_DIR):
    app.mount("/", StaticFiles(directory=CLIENT_DIR, html=True), name="client")
else:
    print(f"Warning: Client directory not found at {CLIENT_DIR}")

# Fallback for SPA routing if we were using React, but for static files this is fine.
