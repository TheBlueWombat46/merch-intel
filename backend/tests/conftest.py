"""Shared test fixtures.

Tests run against a separate database (merch_test) so they never touch
your development data. Override with TEST_DATABASE_URL if needed.
"""

from collections.abc import Iterator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.config import get_settings
from app.db import get_session
from app.main import create_app

BACKEND_DIR = Path(__file__).resolve().parent.parent
# Reads TEST_DATABASE_URL from the environment or the repo-root .env file.
TEST_DATABASE_URL = get_settings().test_database_url
if TEST_DATABASE_URL == get_settings().database_url:
    raise RuntimeError("TEST_DATABASE_URL must differ from DATABASE_URL; tests wipe it.")


def alembic_config(url: str) -> Config:
    cfg = Config(str(BACKEND_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
    cfg.set_main_option("sqlalchemy.url", url)
    return cfg


@pytest.fixture(scope="session")
def engine() -> Iterator[Engine]:
    eng = create_engine(TEST_DATABASE_URL, pool_pre_ping=True)
    yield eng
    eng.dispose()


@pytest.fixture(scope="session")
def migrated(engine: Engine) -> Engine:
    """Reset the test database to a freshly migrated schema once per run."""
    cfg = alembic_config(TEST_DATABASE_URL)
    command.downgrade(cfg, "base")
    command.upgrade(cfg, "head")
    return engine


def client_for(engine: Engine) -> TestClient:
    app = create_app()
    factory = sessionmaker(bind=engine, expire_on_commit=False)

    def override() -> Iterator[Session]:
        with factory() as session:
            yield session

    app.dependency_overrides[get_session] = override
    return TestClient(app)


@pytest.fixture
def client(migrated: Engine) -> TestClient:
    return client_for(migrated)
