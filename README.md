# Merchandising Intelligence POC

A local-first proof of concept for retail merchandising intelligence: map SKUs to
multiple physical homes, record dated showcases, and view honest before/after sales
trends. **Synthetic data only.** No employer data, logos, floor plans or system access.

Current state: **Milestone 0**. Repository scaffold, database connection, empty
baseline migration, health endpoint, tests and CI. No business features yet.

## Stack
React + TypeScript + Vite · FastAPI + Pydantic · PostgreSQL 16 · SQLAlchemy 2 + Alembic ·
pytest + Vitest · Docker Compose (database only)

The API and web app run directly on your machine. Docker runs just the database,
so you don't need to know Docker beyond the two commands below.

## Windows setup (one time)

1. **Install the tools** (accept defaults unless noted):
   - [Git for Windows](https://git-scm.com/download/win)
   - [Python 3.13](https://www.python.org/downloads/): tick **"Add python.exe to PATH"**. Must be
     3.12 or 3.13 (newer versions lack prebuilt packages); it can be installed alongside others.
   - [Node.js 26 LTS](https://nodejs.org/)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/): it may ask to install
     or update **WSL 2** and restart Windows; say yes. Open Docker Desktop once and wait for
     "Engine running".
2. **Allow local scripts** (PowerShell, once per user):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
3. **Clone and set up:**
   ```powershell
   git clone https://github.com/TheBlueWombat46/merch-intel.git
   cd merch-intel
   .\scripts\setup.ps1
   ```

## Daily use

```powershell
.\scripts\start.ps1     # start database, migrate, open API + web app windows
.\scripts\check.ps1     # run all linters and tests
docker compose down     # stop the database when you're done (data is kept)
```

Then open:
- Web app: <http://localhost:5173>. Shows API, database and schema status.
- API docs: <http://localhost:8000/docs>. Interactive; try `GET /api/health`.

**Verify Milestone 0:** the web app shows API **ok**, Database **ok**, Schema version
**0001**, and `check.ps1` ends with "All checks passed".

## Common commands

| Task | Command (from repo root) |
|---|---|
| Backend tests only | `cd backend; .\.venv\Scripts\python -m pytest` |
| Frontend tests only | `cd frontend; npm test` |
| Apply migrations | `cd backend; .\.venv\Scripts\python -m alembic upgrade head` |
| New migration | `cd backend; .\.venv\Scripts\python -m alembic revision -m "describe change"` |
| Wipe local database | `docker compose down -v` (then `start.ps1` recreates it) |

## Without Docker (fallback)
Install [PostgreSQL 16 for Windows](https://www.postgresql.org/download/windows/), then in
`psql` as the `postgres` user:
```sql
CREATE ROLE merch LOGIN PASSWORD 'merch';
CREATE DATABASE merch OWNER merch;
CREATE DATABASE merch_test OWNER merch;
```
Then start with `.\scripts\start.ps1 -NoDocker`.

## Troubleshooting
- **`docker` not found / engine not running:** open Docker Desktop and wait for "Engine running".
- **Port 5432 already in use:** another PostgreSQL is installed. Stop it in Windows Services,
  or change the left port in `docker-compose.yml` (e.g. `"5433:5432"`) and in `.env`.
- **"running scripts is disabled":** run step 2 of setup.
- **Web app says "Cannot reach the API":** the API window closed or errored; re-run `start.ps1`.

## Repository layout
```
backend/            FastAPI app, Alembic migrations, pytest suite
  app/              main.py, config.py, db.py, api/
  alembic/versions/ one file per schema change
  tests/
frontend/           Vite + React + TypeScript, Vitest
docs/
  adr/              architecture decision records (dates, attribution, identifiers)
  schema-draft.md   planned tables for migration 0002
docker/             database init script (creates merch_test)
scripts/            setup.ps1, start.ps1, check.ps1 (Windows)
.github/workflows/  CI: lint + tests on every push
```

## Ground rules
- Synthetic data only; fixtures live in `data/fixtures/`.
- Every schema change is an Alembic migration; no manual database edits.
- Showcase results describe observed association, never causal impact (see ADR 0002).
