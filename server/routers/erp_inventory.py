from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/erp/inventory",
    tags=["ERP Inventory"]
)

@router.post("/items", response_model=schemas.InventoryItem)
def create_inventory_item(
    item: schemas.InventoryItemCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if item.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_item = models.InventoryItem(**item.model_dump())
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

@router.get("/items", response_model=List[schemas.InventoryItem])
def get_inventory_items(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    return db.query(models.InventoryItem).filter(models.InventoryItem.school_id == current_user.school_id).all()

@router.patch("/items/{item_id}/stock", response_model=schemas.InventoryItem)
def update_stock(
    item_id: int,
    quantity_change: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    item = db.query(models.InventoryItem).filter(
        models.InventoryItem.id == item_id,
        models.InventoryItem.school_id == current_user.school_id
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    item.quantity += quantity_change
    if item.quantity < 0:
        item.quantity = 0

    db.commit()
    db.refresh(item)
    return item
