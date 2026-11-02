# One-time setup on Windows. Run from the repo root:
#   .\scripts\setup.ps1
# Safe to re-run; it only installs what is missing or updates dependencies.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Check($what) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nFAILED: $what (exit code $LASTEXITCODE). Fix the error above and re-run." -ForegroundColor Red
        exit 1
    }
}

function Require($cmd, $hint) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "Missing: $cmd. $hint" -ForegroundColor Red
        exit 1
    }
}

Require 'py'     'Install Python 3.13 from python.org (check "Add to PATH" and the py launcher).'
Require 'npm'    'Install Node.js 26 LTS from nodejs.org.'
if (-not (Get-Command 'docker' -ErrorAction SilentlyContinue)) {
    Write-Host 'Note: Docker not found. Install Docker Desktop, or use native PostgreSQL (see README).' -ForegroundColor Yellow
}

if (-not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    Write-Host 'Created .env from .env.example'
}

Write-Host "`n== Backend: Python virtual environment and packages ==" -ForegroundColor Cyan
# Python 3.12 or 3.13 required: some packages don't publish Windows builds for newer versions yet.
$pyver = $null
foreach ($v in '3.13', '3.12') {
    py -$v -c "import sys" 2>$null
    if ($LASTEXITCODE -eq 0) { $pyver = $v; break }
}
if (-not $pyver) {
    Write-Host 'Python 3.12 or 3.13 not found (see installed versions with: py -0).' -ForegroundColor Red
    Write-Host 'Install Python 3.13 from python.org; it can sit alongside newer versions.' -ForegroundColor Red
    exit 1
}
Write-Host "Using Python $pyver"
Push-Location backend
if (Test-Path '.venv') {
    $venvver = & .\.venv\Scripts\python.exe -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')" 2>$null
    if ($venvver -ne $pyver) {
        Write-Host "Recreating .venv (was Python $venvver)"
        Remove-Item -Recurse -Force .venv
    }
}
if (-not (Test-Path '.venv')) { py -$pyver -m venv .venv; Check 'creating virtual environment' }
& .\.venv\Scripts\python.exe -m pip install --upgrade pip --quiet
Check 'upgrading pip'
& .\.venv\Scripts\python.exe -m pip install -e ".[dev]" --quiet
Check 'installing backend packages'
Pop-Location

Write-Host "`n== Frontend: npm packages ==" -ForegroundColor Cyan
Push-Location frontend
npm install
Check 'installing frontend packages'
Pop-Location

Write-Host "`nSetup complete. Next: .\scripts\start.ps1" -ForegroundColor Green
