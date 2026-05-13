from sqlalchemy import event
from sqlalchemy.orm import Session
import json
from ..models import AuditLog, Fee, Payment, User, Payroll

def setup_audit_logging():
    """
    Hooks into SQLAlchemy ORM events to automatically capture changes to 
    sensitive tables and store them in the audit_logs table.
    """
    def make_log(mapper, connection, target, action):
        session = Session(bind=connection)
        
        table_name = target.__tablename__
        
        if table_name not in ["fees", "payments", "users", "payrolls"]:
            return
            
        record_id = str(target.id) if hasattr(target, "id") else "unknown"
        school_id = getattr(target, "school_id", None)
        
        # Note: Extracting the actual acting user ID would require a context variable 
        # set by the FastAPI middleware. For now, it's None.
        user_id = None 
        ip_address = None
        
        new_values = {}
        old_values = {}
        
        try:
            if action == "INSERT":
                new_values = {c.name: str(getattr(target, c.name)) for c in target.__table__.columns}
            elif action == "UPDATE":
                for attr in getattr(target.__class__, "__mapper__").attrs:
                    if hasattr(attr, "history"):
                        hist = getattr(target.__class__, attr.key).impl.get_history(target, None)
                        if hist.has_changes():
                            old_values[attr.key] = str(hist.deleted[0]) if hist.deleted else None
                            new_values[attr.key] = str(hist.added[0]) if hist.added else None
            elif action == "DELETE":
                old_values = {c.name: str(getattr(target, c.name)) for c in target.__table__.columns}
                
            log = AuditLog(
                school_id=school_id,
                user_id=user_id,
                action=action,
                table_name=table_name,
                record_id=record_id,
                old_values=json.dumps(old_values),
                new_values=json.dumps(new_values),
                ip_address=ip_address
            )
            session.add(log)
            session.commit()
        except Exception as e:
            session.rollback()
            print(f"Failed to write audit log: {e}")
        finally:
            session.close()

    @event.listens_for(Fee, 'after_insert')
    @event.listens_for(Payment, 'after_insert')
    @event.listens_for(User, 'after_insert')
    @event.listens_for(Payroll, 'after_insert')
    def after_insert(mapper, connection, target):
        make_log(mapper, connection, target, "INSERT")

    @event.listens_for(Fee, 'after_update')
    @event.listens_for(Payment, 'after_update')
    @event.listens_for(User, 'after_update')
    @event.listens_for(Payroll, 'after_update')
    def after_update(mapper, connection, target):
        make_log(mapper, connection, target, "UPDATE")

    @event.listens_for(Fee, 'after_delete')
    @event.listens_for(Payment, 'after_delete')
    @event.listens_for(User, 'after_delete')
    @event.listens_for(Payroll, 'after_delete')
    def after_delete(mapper, connection, target):
        make_log(mapper, connection, target, "DELETE")
