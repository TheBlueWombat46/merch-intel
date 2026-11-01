"""Health check: is the API up, and can it reach the database?"""

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.db import get_session

router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"]
    database: Literal["ok", "unavailable"]
    schema_version: str | None


@router.get("/health", response_model=HealthResponse)
def health(response: Response, session: Annotated[Session, Depends(get_session)]) -> HealthResponse:
    try:
        session.execute(text("SELECT 1"))
    except SQLAlchemyError:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return HealthResponse(status="degraded", database="unavailable", schema_version=None)

    try:
        version = session.execute(text("SELECT version_num FROM alembic_version")).scalar()
    except SQLAlchemyError:
        # Database reachable but migrations not applied yet.
        session.rollback()
        version = None
    return HealthResponse(status="ok", database="ok", schema_version=version)
