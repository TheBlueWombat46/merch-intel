# One-time setup on Windows. Run from the repo root:
#   .\scripts\setup.ps1
# Safe to re-run; it only installs what is missing or updates dependencies.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Require($cmd, $hint) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "Missing: $cmd. $hint" -ForegroundColor Red
        exit 1
    }
}

Require 'py'     'Install Python 3.12+ from python.org (check "Add to PATH" and the py launcher).'
Require 'npm'    'Install Node.js 22 LTS from nodejs.org.'
if (-not (Get-Command 'docker' -ErrorAction SilentlyContinue)) {
    Write-Host 'Note: Docker not found. Install Docker Desktop, or use native PostgreSQL (see README).' -ForegroundColor Yellow
}

if (-not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    Write-Host 'Created .env from .env.example'
}

Write-Host "`n== Backend: Python virtual environment and packages ==" -ForegroundColor Cyan
Push-Location backend
if (-not (Test-Path '.venv')) { py -3 -m venv .venv }
& .\.venv\Scripts\python.exe -m pip install --upgrade pip --quiet
& .\.venv\Scripts\python.exe -m pip install -e ".[dev]" --quiet
Pop-Location

Write-Host "`n== Frontend: npm packages ==" -ForegroundColor Cyan
Push-Location frontend
npm install
Pop-Location

Write-Host "`nSetup complete. Next: .\scripts\start.ps1" -ForegroundColor Green
