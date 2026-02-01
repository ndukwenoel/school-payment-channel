from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from . import models, database

from .routers import auth, fees, schools, students, parents, payments, notifications, reports
from .routers import erp_academic, erp_hr, erp_inventory, erp_collaboration

# Create tables
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Channel")

app.include_router(auth.router)
app.include_router(schools.router)
app.include_router(students.router)
app.include_router(fees.router)
app.include_router(parents.router)
app.include_router(payments.router)
app.include_router(notifications.router)
app.include_router(reports.router)
app.include_router(erp_academic.router)
app.include_router(erp_hr.router)
app.include_router(erp_inventory.router)
app.include_router(erp_collaboration.router)

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

# Serve Frontend (Client)
# Ensure the client directory exists one level up or adjust path
import os
CLIENT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "client")

if os.path.exists(CLIENT_DIR):
    app.mount("/", StaticFiles(directory=CLIENT_DIR, html=True), name="client")
else:
    print(f"Warning: Client directory not found at {CLIENT_DIR}")

# Fallback for SPA routing if we were using React, but for static files this is fine.
