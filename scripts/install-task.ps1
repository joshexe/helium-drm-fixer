# Registers a per-user scheduled task that runs auto-fix.ps1 at logon and hourly.
# Remove it with: Unregister-ScheduledTask -TaskName HeliumDrmAutoFix

$script = Join-Path $PSScriptRoot "auto-fix.ps1"

# conhost --headless keeps a console window from flashing on every run.
$action = New-ScheduledTaskAction -Execute "conhost.exe" `
  -Argument "--headless powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`""

$logon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$hourly = New-ScheduledTaskTrigger -Once -At (Get-Date) `
  -RepetitionInterval (New-TimeSpan -Hours 1)

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask -TaskName "HeliumDrmAutoFix" -Force `
  -Description "Copies WidevineCdm into new Helium version folders (helium-drm-fixer)" `
  -Action $action -Trigger $logon, $hourly -Settings $settings | Out-Null

Write-Host "Registered HeliumDrmAutoFix (runs at logon and hourly)."
