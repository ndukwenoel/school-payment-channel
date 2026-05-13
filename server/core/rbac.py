from fastapi import HTTPException, Depends, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Role, RolePermission, Permission
from typing import Callable
import importlib

# Lazy import get_current_user to avoid circular imports during refactoring
def _get_current_user_dependency():
    from ..api.v1.auth import get_current_user
    return get_current_user

def requires_permission(permission_name: str) -> Callable:
    """
    Dependency that checks if the current user has the required permission 
    in their assigned role for their specific school.
    """
    def dependency(user: User = Depends(_get_current_user_dependency()), db: Session = Depends(get_db)):
        # Bypass for system superadmins
        if user.role == "superadmin":
            return user
            
        # Check explicit RBAC tables
        role_record = db.query(Role).filter(Role.name == user.role, Role.school_id == user.school_id).first()
        if not role_record:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Role '{user.role}' not found for this school")
            
        has_perm = db.query(RolePermission).join(Permission).filter(
            RolePermission.role_id == role_record.id,
            Permission.name == permission_name
        ).first()
        
        if not has_perm:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Action requires permission: {permission_name}")
            
        return user
    return dependency
