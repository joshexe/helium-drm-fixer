# Re-runs the fixer when the newest Helium version folder is missing WidevineCdm.
# Meant to be run by Task Scheduler; see scripts/install-task.ps1.

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$heliumApp = Join-Path $env:LOCALAPPDATA "imput\Helium\Application"
$logDir = Join-Path $env:LOCALAPPDATA "helium-drm-fixer"
$log = Join-Path $logDir "auto-fix.log"
New-Item -ItemType Directory -Force $logDir | Out-Null

function Write-Log($msg) {
  "$(Get-Date -Format s) $msg" | Add-Content $log
}

if (-not (Test-Path $heliumApp)) {
  exit 0
}

# Helium installs each update into a new <a.b.c.d> folder; check every one so a
# staged update is fixed before the browser restarts into it.
$versions = Get-ChildItem $heliumApp -Directory |
  Where-Object Name -match '^\d+(\.\d+){3}$'
$missing = $versions | Where-Object {
  -not (Test-Path (Join-Path $_.FullName "WidevineCdm\manifest.json"))
}

if (-not $missing) {
  exit 0
}

$bun = Join-Path $env:USERPROFILE ".bun\bin\bun.exe"
# The spinner writes to stderr, which Windows PowerShell turns into a
# terminating error under "Stop".
$ErrorActionPreference = "Continue"
foreach ($v in $missing) {
  Write-Log "WidevineCdm missing in $($v.Name); running fixer"
  $out = & $bun run (Join-Path $repo "cli.ts") --helium-path $v.FullName 2>&1
  $code = $LASTEXITCODE
  $out | ForEach-Object { Write-Log "  $_" }
  Write-Log "fixer exited with $code"
}
