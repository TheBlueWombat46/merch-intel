from alembic import command
from sqlalchemy import inspect, text

from tests.conftest import TEST_DATABASE_URL, alembic_config


def test_baseline_migration_creates_empty_schema(migrated):
    tables = set(inspect(migrated).get_table_names())
    # Only Alembic's bookkeeping table exists after the baseline.
    assert tables == {"alembic_version"}
    with migrated.connect() as conn:
        assert conn.execute(text("SELECT version_num FROM alembic_version")).scalar() == "0001"


def test_migrations_round_trip(migrated):
    """Every migration must downgrade cleanly and re-apply (no hidden manual edits)."""
    cfg = alembic_config(TEST_DATABASE_URL)
    command.downgrade(cfg, "base")
    command.upgrade(cfg, "head")
    with migrated.connect() as conn:
        assert conn.execute(text("SELECT version_num FROM alembic_version")).scalar() == "0001"
