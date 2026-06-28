from sqlalchemy.orm import Session
from .. import models


# --- OPERAÇÕES CRUD DE LOGS ---
def get_logs_auditoria(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.LogAuditoria).order_by(models.LogAuditoria.data_evento.desc()).offset(skip).limit(limit).all()
