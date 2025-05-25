from pydantic import BaseModel
from datetime import datetime

class NBackResultCreate(BaseModel):
    score: int
    level: int
    submitted_at: datetime
class NBackResultOut(BaseModel):
    id: str
    user_id: str
    score: int
    level: int
    submitted_at: datetime

    class Config:
        orm_mode = True