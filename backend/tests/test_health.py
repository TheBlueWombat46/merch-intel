from sqlalchemy import create_engine

from tests.conftest import client_for


def test_health_ok_reports_database_and_schema_version(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok", "database": "ok", "schema_version": "0001"}


def test_health_returns_503_when_database_unreachable():
    # Port 1 is never a Postgres server; connect fails fast.
    dead = create_engine(
        "postgresql+psycopg://nobody:nothing@127.0.0.1:1/none",
        connect_args={"connect_timeout": 2},
    )
    resp = client_for(dead).get("/api/health")
    assert resp.status_code == 503
    assert resp.json() == {"status": "degraded", "database": "unavailable", "schema_version": None}


def test_openapi_lists_health_route(client):
    paths = client.get("/openapi.json").json()["paths"]
    assert "/api/health" in paths
