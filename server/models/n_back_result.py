from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from models.base import Base
from sqlalchemy.sql import func

class NBackResult(Base):
    __tablename__ = "n_back_results"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    score = Column(Integer, nullable=False)
    level = Column(Integer, nullable=False)
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")