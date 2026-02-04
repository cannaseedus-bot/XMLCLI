# AGL T-UI Profile
. $PSScriptRoot\AGL-TUI.ps1

# Set environment
$env:AGL_MODE = "Interactive"
$env:AGL_VERSION = "1.0.0"

# Create project directory
$projectDir = ".\AGL-Projects"
if (-not (Test-Path $projectDir)) {
    New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
}

Write-Host "`n🤖 AGL T-UI Ready" -ForegroundColor Cyan
Write-Host "Type 'Start-ChatInterface' to begin interactive AI development" -ForegroundColor Yellow
