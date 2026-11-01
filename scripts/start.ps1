# Start everything for local development. Run from the repo root:
#   .\scripts\start.ps1
# Starts Postgres (Docker), applies migrations, then opens two windows:
# the API on http://localhost:8000 and the web app on http://localhost:5173.
# Close those windows (or press Ctrl+C in them) to stop. Database: docker compose down
# Using a native PostgreSQL install instead of Docker?  .\scripts\start.ps1 -NoDocker

param([switch]$NoDocker)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not $NoDocker) {
    Write-Host '== Starting PostgreSQL ==' -ForegroundColor Cyan
    docker compose up -d --wait
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Docker failed. Is Docker Desktop running?' -ForegroundColor Red
        exit 1
    }
}

Write-Host '== Applying database migrations ==' -ForegroundColor Cyan
Push-Location backend
& .\.venv\Scripts\python.exe -m alembic upgrade head
if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
Pop-Location

Write-Host '== Starting API and web app in new windows ==' -ForegroundColor Cyan
Start-Process powershell -WorkingDirectory "$root\backend" -ArgumentList '-NoExit', '-Command',
    '.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000'
Start-Process powershell -WorkingDirectory "$root\frontend" -ArgumentList '-NoExit', '-Command',
    'npm run dev'

Write-Host "`nWeb app:  http://localhost:5173" -ForegroundColor Green
Write-Host 'API docs: http://localhost:8000/docs' -ForegroundColor Green
