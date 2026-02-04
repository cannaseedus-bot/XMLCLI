[CmdletBinding()]
param()

$scriptPath = Join-Path $PSScriptRoot "asx-tui.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Error "ASX T-UI script not found at $scriptPath"
    exit 1
}

& $scriptPath
