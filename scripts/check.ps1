# Run all linters and tests. Run from the repo root:
#   .\scripts\check.ps1
# Requires the database to be running (docker compose up -d --wait).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failed = @()

function Step($name, $dir, [scriptblock]$cmd) {
    Write-Host "`n== $name ==" -ForegroundColor Cyan
    Push-Location (Join-Path $root $dir)
    & $cmd
    if ($LASTEXITCODE -ne 0) { $script:failed += $name }
    Pop-Location
}

Step 'Backend lint'   'backend'  { .\.venv\Scripts\python.exe -m ruff check . }
Step 'Backend format' 'backend'  { .\.venv\Scripts\python.exe -m ruff format --check . }
Step 'Backend tests'  'backend'  { .\.venv\Scripts\python.exe -m pytest }
Step 'Frontend lint'  'frontend' { npm run lint }
Step 'Frontend tests' 'frontend' { npm test }
Step 'Frontend build' 'frontend' { npm run build }

if ($failed.Count -gt 0) {
    Write-Host "`nFAILED: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "`nAll checks passed." -ForegroundColor Green
