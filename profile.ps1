# Load K'UHUL Core
. C:\kuhul\Kμhμl.ps1

# Set environment
$env:KUHUL_MODE = "QUANTUM"
$env:KUHUL_COMPRESSION = "SCX-94.7%"

# Customize prompt
function Global:prompt {
    $time = Get-Date -Format "HH:mm:ss"
    $path = (Get-Location).Path.Replace($HOME, "~")

    # Quantum state indicator
    $quantumChar = if ($QuantumState.Superposition) { "🌀" } else { "⚛" }

    # Build prompt
    $prompt = @"
╭─[$quantumChar kuhul @ $time]
│  $path
╰─➤
"@

    Write-Host $prompt -NoNewline -ForegroundColor Cyan
    return " "
}

# Auto-completion for K'UHUL commands
Register-ArgumentCompleter -CommandName Invoke-SVGCommand -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    @('chat', 'generate', 'analyze', 'render', 'transform', 'compress', 'entangle') |
        Where-Object { $_ -like "$wordToComplete*" }
}
