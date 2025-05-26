import uuid
from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import cast, Date
from models.n_back_result import NBackResult
from models.user import User
from pydantic_schemas.n_back_result import NBackResultCreate, NBackResultOut
from database import get_db
from middleware.auth_middleware import auth_middleware

router = APIRouter()

@router.post("/", response_model=NBackResultOut, status_code=201)
def create_n_back_result(
    result: NBackResultCreate,
    db: Session = Depends(get_db),
    user_dict=Depends(auth_middleware)
):
    submitted_date = result.submitted_at.date()
    start = datetime.combine(submitted_date, datetime.min.time())
    end = datetime.combine(submitted_date, datetime.max.time())

    existing_result = (
        db.query(NBackResult)
        .filter(
            NBackResult.user_id == user_dict["uid"],
            NBackResult.submitted_at >= start,
            NBackResult.submitted_at <= end
        )
        .first()
    )

    if existing_result:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Result for this day already exists.")
    n_back_result = NBackResult(
        id=str(uuid.uuid4()),
        user_id=user_dict["uid"],
        score=result.score,
        level=result.level,
        submitted_at=result.submitted_at
    )
    db.add(n_back_result)
    db.commit()
    db.refresh(n_back_result)
    return n_back_result

@router.get("/", response_model=list[NBackResultOut])
def get_user_n_back_results(
    db: Session = Depends(get_db),
    user_dict=Depends(auth_middleware)
):
    results = db.query(NBackResult).filter(NBackResult.user_id == user_dict["uid"]).all()
    return results

@router.get("/all", response_model=list[NBackResultOut])
def get_all_n_back_results(db: Session = Depends(get_db)):
    return db.query(NBackResult).all()

@router.put("/", response_model=NBackResultOut)
def update_n_back_result(
    result: NBackResultCreate,
    db: Session = Depends(get_db),
    user_dict=Depends(auth_middleware)
):
    submitted_date = result.submitted_at.date()
    start = datetime.combine(submitted_date, datetime.min.time())
    end = datetime.combine(submitted_date, datetime.max.time())

    existing_result = (
        db.query(NBackResult)
        .filter(
            NBackResult.user_id == user_dict["uid"],
            NBackResult.submitted_at >= start,
            NBackResult.submitted_at <= end
        )
        .first()
    )

    if not existing_result:
        raise HTTPException(status_code=404, detail="No result for this day to update.")

    if result.level > existing_result.level:
        existing_result.level = result.level
        existing_result.score = result.score
    elif result.level == existing_result.level and result.score > existing_result.score:
        existing_result.score = result.score
    else:
        return existing_result

    existing_result.submitted_at = result.submitted_at  # Aktualizuj datę, jeśli potrzeba
    db.commit()
    db.refresh(existing_result)
    return existing_result

@router.get("/recent", response_model=list[NBackResultOut])
def get_recent_n_back_results(
    db: Session = Depends(get_db),
    user_dict=Depends(auth_middleware)
):
    """
    Zwraca 5 ostatnich wyników danego użytkownika (posortowane od najnowszego).
    """
    results = (
        db.query(NBackResult)
        .filter(NBackResult.user_id == user_dict["uid"])
        .order_by(NBackResult.submitted_at.desc())
        .limit(5)
        .all()
    )
    return results