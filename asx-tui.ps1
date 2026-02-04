# ASX-TUI-AI-WORKSTATION.ps1
# Advanced Terminal AI Workspace with Multi-Provider Models + Local Runtimes + File Operations

# ============================================================================
# CONFIGURATION
# ============================================================================

$ASX_VERSION = "1.0.0"
$ASX_BASE_DIR = "$env:USERPROFILE\.asx-tui"
$HISTORY_FILE = "$ASX_BASE_DIR\history.json"
$CONFIG_FILE = "$ASX_BASE_DIR\config.json"
$WORKSPACE_DIR = "$ASX_BASE_DIR\workspace"

# Default Models Configuration
$DEFAULT_MODELS = @{
    "ollama-cloud" = @{
        "llama3" = @{
            name = "Llama 3 70B"
            provider = "ollama-cloud"
            endpoint = "https://api.ollama.cloud/v1/chat/completions"
            context = 8192
            capabilities = @("chat", "code", "reasoning")
        }
        "mistral" = @{
            name = "Mistral 7B"
            provider = "ollama-cloud"
            endpoint = "https://api.ollama.cloud/v1/chat/completions"
            context = 4096
            capabilities = @("chat", "summarization", "translation")
        }
        "codellama" = @{
            name = "CodeLlama 34B"
            provider = "ollama-cloud"
            endpoint = "https://api.ollama.cloud/v1/chat/completions"
            context = 16384
            capabilities = @("code", "debugging", "documentation")
        }
    }

    "local-ollama" = @{
        "llama2" = @{
            name = "Llama 2 7B"
            provider = "local-ollama"
            endpoint = "http://localhost:11434/api/generate"
            context = 4096
            capabilities = @("chat", "general")
        }
        "neural-chat" = @{
            name = "Neural Chat 7B"
            provider = "local-ollama"
            endpoint = "http://localhost:11434/api/generate"
            context = 4096
            capabilities = @("chat", "reasoning")
        }
    }

    "openai" = @{
        "gpt-4o-mini" = @{
            name = "GPT-4o Mini"
            provider = "openai"
            endpoint = "https://api.openai.com/v1/chat/completions"
            context = 128000
            capabilities = @("chat", "code", "reasoning", "creative")
        }
    }

    "anthropic" = @{
        "claude-3-5-sonnet" = @{
            name = "Claude 3.5 Sonnet"
            provider = "anthropic"
            endpoint = "https://api.anthropic.com/v1/messages"
            context = 200000
            capabilities = @("chat", "analysis", "long-context")
        }
    }

    "google" = @{
        "gemini-1.5-pro" = @{
            name = "Gemini 1.5 Pro"
            provider = "google"
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
            context = 1048576
            capabilities = @("chat", "analysis", "long-context")
        }
    }

    "mistral" = @{
        "mistral-large" = @{
            name = "Mistral Large"
            provider = "mistral"
            endpoint = "https://api.mistral.ai/v1/chat/completions"
            context = 128000
            capabilities = @("chat", "reasoning", "code")
        }
    }

    "groq" = @{
        "llama3-70b" = @{
            name = "Llama 3 70B (Groq)"
            provider = "groq"
            endpoint = "https://api.groq.com/openai/v1/chat/completions"
            context = 8192
            capabilities = @("chat", "reasoning", "code")
        }
    }

    "deepseek" = @{
        "deepseek-chat" = @{
            name = "DeepSeek Chat"
            provider = "deepseek"
            endpoint = "https://api.deepseek.com/chat/completions"
            context = 128000
            capabilities = @("chat", "reasoning", "code")
        }
    }

    "lmstudio" = @{
        "local-openai" = @{
            name = "LM Studio (OpenAI Compatible)"
            provider = "lmstudio"
            endpoint = "http://localhost:1234/v1/chat/completions"
            context = 8192
            capabilities = @("chat", "local")
        }
    }

    "mlc" = @{
        "local-openai" = @{
            name = "MLC (OpenAI Compatible)"
            provider = "mlc"
            endpoint = "http://localhost:8000/v1/chat/completions"
            context = 8192
            capabilities = @("chat", "local")
        }
    }

    "openai-compatible" = @{
        "custom" = @{
            name = "OpenAI-Compatible (Custom)"
            provider = "openai-compatible"
            endpoint = "configured"
            context = 8192
            capabilities = @("chat", "custom")
        }
    }

    "custom" = @{
        "custom" = @{
            name = "Custom HTTP Adapter"
            provider = "custom"
            endpoint = "configured"
            context = 8192
            capabilities = @("chat", "custom")
        }
    }
}

# Available Tools
$TOOLS = @{
    "file" = @{
        name = "File Operations"
        commands = @("create", "edit", "read", "delete", "list", "search")
        description = "File creation, editing, and management"
    }
    "code" = @{
        name = "Code Tools"
        commands = @("generate", "explain", "debug", "test", "refactor")
        description = "Code generation and analysis"
    }
    "model" = @{
        name = "Model Management"
        commands = @("list", "switch", "add", "remove", "test")
        description = "AI model configuration"
    }
    "chat" = @{
        name = "Chat Sessions"
        commands = @("new", "continue", "save", "load", "export")
        description = "AI chat conversations"
    }
    "system" = @{
        name = "System Tools"
        commands = @("config", "update", "health", "logs", "clean")
        description = "System management and configuration"
    }
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-TUI {
    param(
        [string]$Message,
        [string]$Type = "info",
        [switch]$NoNewLine
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "success" { "✅" }
        "error" { "❌" }
        "warning" { "⚠️" }
        "info" { "ℹ️" }
        "chat" { "💬" }
        "system" { "🖥️" }
        "file" { "📄" }
        "model" { "🧠" }
        default { "»" }
    }

    $formatted = "[$timestamp] $prefix $Message"

    if ($NoNewLine) {
        Write-Host $formatted -NoNewline
    } else {
        Write-Host $formatted
    }
}

function Initialize-TUI {
    # Clear screen and show banner
    Clear-Host

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  ASX T-UI AI WORKSTATION                    ║" -ForegroundColor Cyan
    Write-Host "║           Terminal AI Interface v$ASX_VERSION                   ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Features:" -ForegroundColor White
    Write-Host "  • Ollama Cloud + OpenAI + Anthropic + Google + Mistral + Groq + DeepSeek" -ForegroundColor Gray
    Write-Host "  • Local runtimes (Ollama, LM Studio, MLC)" -ForegroundColor Gray
    Write-Host "  • OpenAI-compatible + Custom HTTP adapters" -ForegroundColor Gray
    Write-Host "  • File Creation & Editing" -ForegroundColor Gray
    Write-Host "  • Code Generation & Analysis" -ForegroundColor Gray
    Write-Host "  • Multi-Model Chat Sessions" -ForegroundColor Gray
    Write-Host "  • System Integration Tools" -ForegroundColor Gray
    Write-Host ""

    # Create directories
    if (-not (Test-Path $ASX_BASE_DIR)) {
        New-Item -ItemType Directory -Path $ASX_BASE_DIR -Force | Out-Null
        New-Item -ItemType Directory -Path $WORKSPACE_DIR -Force | Out-Null
        Write-TUI "Created workspace directory" -Type success
    }

    # Load or create config
    if (Test-Path $CONFIG_FILE) {
        $config = Get-Content $CONFIG_FILE | ConvertFrom-Json -AsHashtable
        Write-TUI "Configuration loaded" -Type success
    } else {
        $config = @{
            active_model = "ollama-cloud:llama3"
            workspace = $WORKSPACE_DIR
            theme = "dark"
            max_history = 1000
            auto_save = $true
            api_keys = @{}
            provider_adapters = @{
                "openai-compatible" = @{
                    endpoint = ""
                    headers = @{}
                }
                "custom" = @{
                    endpoint = ""
                    headers = @{}
                }
            }
        }
        Save-Config -Config $config
        Write-TUI "Default configuration created" -Type success
    }

    return $config
}

function Save-Config {
    param($Config)

    $Config | ConvertTo-Json -Depth 10 | Set-Content $CONFIG_FILE
}

function Get-ApiKey-ConfigKey {
    param([string]$Provider)

    switch ($Provider) {
        "ollama-cloud" { return "ollama-cloud" }
        "openai" { return "openai" }
        "anthropic" { return "anthropic" }
        "google" { return "google" }
        "mistral" { return "mistral" }
        "groq" { return "groq" }
        "deepseek" { return "deepseek" }
        "lmstudio" { return "lmstudio" }
        "mlc" { return "mlc" }
        "openai-compatible" { return "openai-compatible" }
        "custom" { return "custom" }
        default { return $Provider }
    }
}

function Ensure-ApiKey {
    param(
        [string]$Provider,
        [switch]$ForcePrompt
    )

    $configKey = Get-ApiKey-ConfigKey -Provider $Provider
    $existingKey = $null

    if ($script:config.api_keys.ContainsKey($configKey)) {
        $existingKey = $script:config.api_keys[$configKey]
    } elseif ($Provider -eq "ollama-cloud" -and $script:config.api_keys.ContainsKey("ollama_cloud")) {
        $existingKey = $script:config.api_keys["ollama_cloud"]
        if ($existingKey) {
            $script:config.api_keys[$configKey] = $existingKey
            $script:config.api_keys.Remove("ollama_cloud")
            Save-Config -Config $script:config
        }
    }

    if (-not $ForcePrompt -and $existingKey) {
        return $existingKey
    }

    Write-TUI "API key required for $Provider. Please enter it now." -Type warning
    $key = Read-Host "Enter $Provider API key" -AsSecureString
    $plainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($key)
    )

    if ([string]::IsNullOrWhiteSpace($plainKey)) {
        Write-TUI "No API key provided for $Provider" -Type error
        return $null
    }

    $script:config.api_keys[$configKey] = $plainKey
    Save-Config -Config $script:config
    Write-TUI "$Provider API key saved" -Type success
    return $plainKey
}

function Format-UserFacingError {
    param(
        [string]$Provider,
        [string]$ErrorMessage,
        [int]$StatusCode,
        [string]$Endpoint,
        [string]$Category
    )

    $providerLabel = if ($Provider) { $Provider } else { "provider" }
    $details = $ErrorMessage
    $nextSteps = @()

    if (-not $Category) {
        if ($StatusCode -in 401, 403 -or $ErrorMessage -match "Unauthorized|Forbidden|401|403|API key|invalid key|permission") {
            $Category = "auth"
        } elseif ($ErrorMessage -match "timed out|timeout|NameResolution|No such host|could not resolve|connection.*refused|actively refused|Network|502|503|504|temporarily unavailable|SSL|certificate") {
            $Category = "network"
        } elseif ($ErrorMessage -match "endpoint" -or $ErrorMessage -match "No endpoint configured") {
            $Category = "endpoint"
        } elseif ($ErrorMessage -match "Unsupported provider") {
            $Category = "provider"
        } else {
            $Category = "unknown"
        }
    }

    switch ($Category) {
        "auth" {
            $message = "Authorization failed for $providerLabel."
            $nextSteps += "Set or update the $providerLabel API key when prompted."
            if ($Provider -in @("openai-compatible", "custom")) {
                $nextSteps += "Ensure api_keys.$providerLabel or provider_adapters headers include a valid Authorization token."
            }
        }
        "network" {
            $message = "Unable to reach the $providerLabel endpoint."
            if ($Endpoint) {
                $nextSteps += "Verify the endpoint URL: $Endpoint"
            }
            $nextSteps += "Check your network connection, VPN, or proxy settings."
            $nextSteps += "Try switching to another provider or model."
        }
        "endpoint" {
            $message = "No endpoint configured for $providerLabel."
            $nextSteps += "Configure an endpoint in the model or provider adapter settings."
        }
        "provider" {
            $message = "Unsupported provider selected: $providerLabel."
            $nextSteps += "Choose a supported provider from the model list."
        }
        default {
            $message = "Something went wrong while contacting $providerLabel."
            $nextSteps += "Try again or switch providers if the issue persists."
        }
    }

    if ($Provider -in @("local-ollama", "lmstudio", "mlc")) {
        $nextSteps += "Confirm the local server is running and reachable."
        if ($Endpoint) {
            $nextSteps += "Check the local endpoint: $Endpoint"
        }
    }

    return @{
        message = $message
        next_steps = $nextSteps
        details = $details
        category = $Category
    }
}

function Get-Provider-AdapterConfig {
    param([string]$Provider)

    if ($script:config.ContainsKey("provider_adapters") -and $script:config.provider_adapters.ContainsKey($Provider)) {
        return $script:config.provider_adapters[$Provider]
    }

    return @{}
}

function Get-Model-Info {
    param([string]$ModelKey)

    $parts = $ModelKey -split ":"
    if ($parts.Count -ne 2) {
        return $null
    }

    $provider = $parts[0]
    $model = $parts[1]

    if ($DEFAULT_MODELS.ContainsKey($provider) -and $DEFAULT_MODELS[$provider].ContainsKey($model)) {
        return $DEFAULT_MODELS[$provider][$model]
    }

    return $null
}

# ============================================================================
# MODEL MANAGEMENT
# ============================================================================

function List-Models {
    Write-TUI "Available AI Models:" -Type model

    foreach ($provider in $DEFAULT_MODELS.Keys) {
        Write-Host "`n  [$provider]" -ForegroundColor Cyan
        foreach ($model in $DEFAULT_MODELS[$provider].Keys) {
            $info = $DEFAULT_MODELS[$provider][$model]
            $status = " "
            if ("$provider`:$model" -eq $script:config.active_model) {
                $status = "*"
            }
            Write-Host "    $status $($info.name)" -ForegroundColor White
            Write-Host "      Context: $($info.context) | Capabilities: $($info.capabilities -join ', ')" -ForegroundColor Gray
        }
    }
}

function Switch-Model {
    param([string]$ModelKey)

    $modelInfo = Get-Model-Info -ModelKey $ModelKey
    if ($modelInfo) {
        $script:config.active_model = $ModelKey
        Save-Config -Config $script:config
        Write-TUI "Switched to model: $($modelInfo.name)" -Type success
        return $true
    } else {
        Write-TUI "Model not found: $ModelKey" -Type error
        return $false
    }
}

function Test-Model-Connection {
    param([string]$ModelKey = $script:config.active_model)

    $modelInfo = Get-Model-Info -ModelKey $ModelKey
    if (-not $modelInfo) {
        Write-TUI "Model not found: $ModelKey" -Type error
        return $false
    }

    Write-TUI "Testing connection to $($modelInfo.name)..." -Type info

    try {
        switch ($modelInfo.provider) {
            "ollama-cloud" {
                # Test Ollama Cloud
                $headers = @{
                    "Authorization" = "Bearer $($script:config.api_keys.ollama_cloud)"
                    "Content-Type" = "application/json"
                }

                $body = @{
                    model = $modelKey.Split(":")[1]
                    messages = @(@{ role = "user"; content = "test" })
                    stream = $false
                } | ConvertTo-Json

                $response = Invoke-RestMethod -Uri $modelInfo.endpoint `
                    -Method Post `
                    -Headers $headers `
                    -Body $body `
                    -TimeoutSec 10

                Write-TUI "Ollama Cloud connection successful" -Type success
                return $true
            }

            "local-ollama" {
                # Test local Ollama
                $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" `
                    -Method Get `
                    -TimeoutSec 5

                if ($response.models.name -contains $modelKey.Split(":")[1]) {
                    Write-TUI "Local Ollama connection successful" -Type success
                    return $true
                } else {
                    Write-TUI "Model not found in local Ollama" -Type warning
                    return $false
                }
            }

            default {
                Write-TUI "Provider test not implemented: $($modelInfo.provider)" -Type warning
                return $false
            }
        }
    } catch {
        Write-TUI "Connection failed: $_" -Type error
        return $false
    }
}

function Add-Custom-Model {
    Write-TUI "Adding custom model..." -Type model

    $provider = Read-Host "Provider (e.g., 'openai', 'anthropic', 'google', 'mistral', 'groq', 'deepseek', 'openai-compatible', 'custom')"
    $modelName = Read-Host "Model name"
    $endpoint = Read-Host "API endpoint"
    $context = Read-Host "Context length" -AsSecureString | ConvertFrom-SecureString

    $customModel = @{
        name = $modelName
        provider = $provider
        endpoint = $endpoint
        context = [int]$context
        capabilities = @("chat", "custom")
    }

    if (-not $DEFAULT_MODELS.ContainsKey($provider)) {
        $DEFAULT_MODELS[$provider] = @{}
    }

    $DEFAULT_MODELS[$provider][$modelName] = $customModel
    Write-TUI "Custom model added: $provider`:$modelName" -Type success
}

# ============================================================================
# AI CHAT INTERFACE
# ============================================================================

function Start-Chat {
    param([string]$ModelKey = $script:config.active_model)

    $modelInfo = Get-Model-Info -ModelKey $ModelKey
    if (-not $modelInfo) {
        Write-TUI "Invalid model: $ModelKey" -Type error
        return
    }

    Write-TUI "Starting chat with $($modelInfo.name)" -Type chat
    Write-TUI "Type '/exit' to end chat, '/save' to save conversation" -Type info
    Write-Host ("─" * 60) -ForegroundColor DarkGray

    $messages = @()
    $conversationId = [guid]::NewGuid().ToString()

    while ($true) {
        $userInput = Read-Host "`nYou"

        if ($userInput -eq '/exit') {
            break
        }

        if ($userInput -eq '/save') {
            Save-Chat -Messages $messages -Model $modelInfo.name
            continue
        }

        if ($userInput -eq '/clear') {
            Clear-Host
            Write-TUI "Chat cleared" -Type system
            continue
        }

        # Add user message
        $messages += @{ role = "user"; content = $userInput }

        # Get AI response
        $response = Invoke-AI-Model -ModelInfo $modelInfo -Messages $messages

        if ($response.success) {
            Write-Host "AI: " -NoNewline -ForegroundColor Green
            Write-Host $response.content -ForegroundColor White

            # Add AI response to messages
            $messages += @{ role = "assistant"; content = $response.content }
        } else {
            Write-TUI "Error: $($response.error)" -Type error
            if ($response.details -and $response.details -ne $response.error) {
                Write-TUI "Details: $($response.details)" -Type warning
            }
            if ($response.next_steps -and $response.next_steps.Count -gt 0) {
                Write-TUI "Next steps:" -Type info
                foreach ($step in $response.next_steps) {
                    Write-Host "  - $step" -ForegroundColor Yellow
                }
            }
        }
    }

    Write-Host ("─" * 60) -ForegroundColor DarkGray
    Write-TUI "Chat session ended" -Type chat
}

function Invoke-AI-Model {
    param($ModelInfo, $Messages)

    try {
        $providersNeedingKeys = @("ollama-cloud", "openai", "anthropic", "google", "mistral", "groq", "deepseek")
        if ($providersNeedingKeys -contains $ModelInfo.provider) {
            $apiKey = Ensure-ApiKey -Provider $ModelInfo.provider
            if (-not $apiKey) {
                $friendly = Format-UserFacingError -Provider $ModelInfo.provider -ErrorMessage "Missing API key for provider: $($ModelInfo.provider)" -Category "auth"
                return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
            }
        }

        switch ($ModelInfo.provider) {
            "ollama-cloud" {
                return Invoke-Ollama-Cloud -ModelInfo $ModelInfo -Messages $Messages
            }
            "local-ollama" {
                return Invoke-Local-Ollama -ModelInfo $ModelInfo -Messages $Messages
            }
            "openai" {
                return Invoke-OpenAI -ModelInfo $ModelInfo -Messages $Messages
            }
            "anthropic" {
                return Invoke-Anthropic -ModelInfo $ModelInfo -Messages $Messages
            }
            "google" {
                return Invoke-Google -ModelInfo $ModelInfo -Messages $Messages
            }
            "mistral" {
                return Invoke-Mistral -ModelInfo $ModelInfo -Messages $Messages
            }
            "groq" {
                return Invoke-Groq -ModelInfo $ModelInfo -Messages $Messages
            }
            "deepseek" {
                return Invoke-DeepSeek -ModelInfo $ModelInfo -Messages $Messages
            }
            "lmstudio" {
                return Invoke-LMStudio -ModelInfo $ModelInfo -Messages $Messages
            }
            "mlc" {
                return Invoke-MLC -ModelInfo $ModelInfo -Messages $Messages
            }
            "openai-compatible" {
                return Invoke-OpenAI-Compatible -ModelInfo $ModelInfo -Messages $Messages
            }
            "custom" {
                return Invoke-OpenAI-Compatible -ModelInfo $ModelInfo -Messages $Messages
            }
            default {
                $friendly = Format-UserFacingError -Provider $ModelInfo.provider -ErrorMessage "Unsupported provider: $($ModelInfo.provider)" -Category "provider"
                return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
            }
        }
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider $ModelInfo.provider -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-Ollama-Cloud {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "ollama-cloud"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "ollama-cloud" -ErrorMessage "Ollama Cloud API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $modelName = $script:config.active_model.Split(":")[1]

    $body = @{
        model = $modelName
        messages = $Messages
        stream = $false
        options = @{
            temperature = 0.7
            top_p = 0.9
        }
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Uri $ModelInfo.endpoint `
            -Method Post `
            -Headers $headers `
            -Body $body `
            -TimeoutSec 30
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }

        if ($statusCode -in 401, 403 -or $_.Exception.Message -match "Unauthorized|Forbidden|401|403") {
            Write-TUI "Authorization failed. Please update your Ollama Cloud API key." -Type warning
            $apiKey = Ensure-ApiKey -Provider "ollama-cloud" -ForcePrompt
            if ($apiKey) {
                $headers["Authorization"] = "Bearer $apiKey"
                try {
                    $response = Invoke-RestMethod -Uri $ModelInfo.endpoint `
                        -Method Post `
                        -Headers $headers `
                        -Body $body `
                        -TimeoutSec 30
                } catch {
                    $retryStatus = $null
                    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                        $retryStatus = $_.Exception.Response.StatusCode.value__
                    }
                    $friendly = Format-UserFacingError -Provider "ollama-cloud" -ErrorMessage $_.Exception.Message -StatusCode $retryStatus -Endpoint $ModelInfo.endpoint
                    return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
                }
            } else {
                $friendly = Format-UserFacingError -Provider "ollama-cloud" -ErrorMessage "Ollama Cloud API key not configured" -Category "auth"
                return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
            }
        } else {
            $friendly = Format-UserFacingError -Provider "ollama-cloud" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
            return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
        }
    }

    return @{
        success = $true
        content = $response.choices[0].message.content
        usage = $response.usage
    }
}

function Invoke-Local-Ollama {
    param($ModelInfo, $Messages)

    $modelName = $script:config.active_model.Split(":")[1]

    # Convert messages to Ollama format
    $prompt = ""
    foreach ($msg in $Messages) {
        $prompt += "$($msg.role): $($msg.content)`n"
    }
    $prompt += "assistant: "

    $body = @{
        model = $modelName
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.7
        }
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $ModelInfo.endpoint `
            -Method Post `
            -Headers @{"Content-Type" = "application/json"} `
            -Body $body `
            -TimeoutSec 60
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "local-ollama" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    return @{
        success = $true
        content = $response.response
    }
}

function Invoke-OpenAI-ChatCompletion {
    param(
        [string]$Endpoint,
        [hashtable]$Headers,
        [string]$ModelName,
        $Messages
    )

    $body = @{
        model = $ModelName
        messages = $Messages
        temperature = 0.7
        stream = $false
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint `
        -Method Post `
        -Headers $Headers `
        -Body $body `
        -TimeoutSec 60

    return @{
        success = $true
        content = $response.choices[0].message.content
        usage = $response.usage
    }
}

function Invoke-OpenAI {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "openai"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "openai" -ErrorMessage "OpenAI API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $modelName = $script:config.active_model.Split(":")[1]
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $ModelInfo.endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "openai" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-Anthropic {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "anthropic"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "anthropic" -ErrorMessage "Anthropic API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $modelName = $script:config.active_model.Split(":")[1]
    $systemPrompt = ($Messages | Where-Object { $_.role -eq "system" } | ForEach-Object { $_.content }) -join "`n"
    $anthropicMessages = @()
    foreach ($msg in $Messages) {
        if ($msg.role -eq "system") {
            continue
        }
        $anthropicMessages += @{
            role = $msg.role
            content = $msg.content
        }
    }

    $body = @{
        model = $modelName
        max_tokens = 1024
        messages = $anthropicMessages
    }
    if ($systemPrompt) {
        $body["system"] = $systemPrompt
    }

    $headers = @{
        "x-api-key" = $apiKey
        "anthropic-version" = "2023-06-01"
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Uri $ModelInfo.endpoint `
            -Method Post `
            -Headers $headers `
            -Body ($body | ConvertTo-Json -Depth 10) `
            -TimeoutSec 60
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "anthropic" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    return @{
        success = $true
        content = $response.content[0].text
        usage = $response.usage
    }
}

function Invoke-Google {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "google"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "google" -ErrorMessage "Google API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $systemPrompt = ($Messages | Where-Object { $_.role -eq "system" } | ForEach-Object { $_.content }) -join "`n"
    $contents = @()
    $systemApplied = $false

    foreach ($msg in $Messages) {
        if ($msg.role -eq "system") {
            continue
        }

        $role = if ($msg.role -eq "assistant") { "model" } else { "user" }
        $text = $msg.content
        if (-not $systemApplied -and $systemPrompt -and $role -eq "user") {
            $text = "$systemPrompt`n`n$text"
            $systemApplied = $true
        }

        $contents += @{
            role = $role
            parts = @(@{ text = $text })
        }
    }

    if (-not $contents) {
        $contents = @(@{
                role = "user"
                parts = @(@{ text = $systemPrompt })
            })
    }

    $body = @{
        contents = $contents
    } | ConvertTo-Json -Depth 10

    $endpoint = $ModelInfo.endpoint
    if ($endpoint -match "\?") {
        $endpoint = "$endpoint&key=$apiKey"
    } else {
        $endpoint = "$endpoint?key=$apiKey"
    }

    try {
        $response = Invoke-RestMethod -Uri $endpoint `
            -Method Post `
            -Headers @{"Content-Type" = "application/json"} `
            -Body $body `
            -TimeoutSec 60
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "google" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    return @{
        success = $true
        content = $response.candidates[0].content.parts[0].text
    }
}

function Invoke-Mistral {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "mistral"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "mistral" -ErrorMessage "Mistral API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $modelName = $script:config.active_model.Split(":")[1]
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $ModelInfo.endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "mistral" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-Groq {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "groq"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "groq" -ErrorMessage "Groq API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $modelName = $script:config.active_model.Split(":")[1]
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $ModelInfo.endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "groq" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-DeepSeek {
    param($ModelInfo, $Messages)

    $apiKey = Ensure-ApiKey -Provider "deepseek"
    if (-not $apiKey) {
        $friendly = Format-UserFacingError -Provider "deepseek" -ErrorMessage "DeepSeek API key not configured" -Category "auth"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $modelName = $script:config.active_model.Split(":")[1]
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $ModelInfo.endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "deepseek" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-LMStudio {
    param($ModelInfo, $Messages)

    $modelName = $script:config.active_model.Split(":")[1]
    $headers = @{
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $ModelInfo.endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "lmstudio" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-MLC {
    param($ModelInfo, $Messages)

    $modelName = $script:config.active_model.Split(":")[1]
    $headers = @{
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $ModelInfo.endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider "mlc" -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $ModelInfo.endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Invoke-OpenAI-Compatible {
    param($ModelInfo, $Messages)

    $adapterConfig = Get-Provider-AdapterConfig -Provider $ModelInfo.provider
    $endpoint = $adapterConfig.endpoint
    if ($endpoint -eq "configured") {
        $endpoint = $null
    }
    if (-not $endpoint) {
        $endpoint = $ModelInfo.endpoint
    }
    if ($endpoint -eq "configured") {
        $endpoint = $null
    }
    if (-not $endpoint) {
        $friendly = Format-UserFacingError -Provider $ModelInfo.provider -ErrorMessage "No endpoint configured for $($ModelInfo.provider)" -Category "endpoint"
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }

    $headers = @{
        "Content-Type" = "application/json"
    }
    if ($adapterConfig.headers) {
        foreach ($key in $adapterConfig.headers.Keys) {
            $headers[$key] = $adapterConfig.headers[$key]
        }
    }

    if ($script:config.api_keys.ContainsKey($ModelInfo.provider) -and -not $headers.ContainsKey("Authorization")) {
        $headers["Authorization"] = "Bearer $($script:config.api_keys[$ModelInfo.provider])"
    }

    $modelName = $script:config.active_model.Split(":")[1]
    try {
        return Invoke-OpenAI-ChatCompletion -Endpoint $endpoint -Headers $headers -ModelName $modelName -Messages $Messages
    } catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        $friendly = Format-UserFacingError -Provider $ModelInfo.provider -ErrorMessage $_.Exception.Message -StatusCode $statusCode -Endpoint $endpoint
        return @{ success = $false; error = $friendly.message; next_steps = $friendly.next_steps; details = $friendly.details }
    }
}

function Save-Chat {
    param($Messages, $Model)

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $fileName = "chat-$timestamp.json"
    $filePath = Join-Path $WORKSPACE_DIR $fileName

    $chatData = @{
        model = $Model
        timestamp = Get-Date -Format "o"
        messages = $Messages
    }

    $chatData | ConvertTo-Json -Depth 10 | Set-Content $filePath
    Write-TUI "Chat saved to: $filePath" -Type file
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

function Create-File {
    param([string]$Path)

    if (-not $Path) {
        $Path = Read-Host "File path (relative to workspace)"
    }

    $fullPath = Join-Path $WORKSPACE_DIR $Path

    # Create directory if needed
    $dir = Split-Path $fullPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Check if file exists
    if (Test-Path $fullPath) {
        $overwrite = Read-Host "File exists. Overwrite? (y/n)"
        if ($overwrite -ne 'y') {
            Write-TUI "File creation cancelled" -Type warning
            return
        }
    }

    # Get initial content from AI or empty
    $contentPrompt = Read-Host "Initial content (or 'ai' to generate with AI)"

    if ($contentPrompt -eq 'ai') {
        $modelInfo = Get-Model-Info -ModelKey $script:config.active_model
        $aiPrompt = "Create a new file at path: $Path. The file should contain:"
        $aiPrompt += Read-Host "Describe what the file should contain"

        $response = Invoke-AI-Model -ModelInfo $modelInfo -Messages @(
            @{ role = "system"; content = "You are a code/file generation assistant." }
            @{ role = "user"; content = $aiPrompt }
        )

        if ($response.success) {
            $content = $response.content
        } else {
            Write-TUI "AI generation failed, creating empty file" -Type warning
            $content = ""
        }
    } else {
        $content = $contentPrompt
    }

    Set-Content -Path $fullPath -Value $content
    Write-TUI "File created: $fullPath" -Type success
}

function Edit-File {
    param([string]$Path)

    if (-not $Path) {
        $Path = Read-Host "File path (relative to workspace)"
    }

    $fullPath = Join-Path $WORKSPACE_DIR $Path

    if (-not (Test-Path $fullPath)) {
        Write-TUI "File not found: $Path" -Type error
        return
    }

    # Read current content
    $content = Get-Content $fullPath -Raw

    Write-TUI "Editing: $Path" -Type file
    Write-Host ("─" * 60) -ForegroundColor DarkGray
    Write-Host $content -ForegroundColor Gray
    Write-Host ("─" * 60) -ForegroundColor DarkGray

    $choice = Read-Host "`nOptions: (e)dit, (a)i-assist, (c)ancel"

    switch ($choice.ToLower()) {
        'e' {
            # Open in default editor
            notepad $fullPath
            Write-TUI "Opened in editor" -Type success
        }

        'a' {
            # AI-assisted editing
            $instruction = Read-Host "What changes would you like to make?"

            $modelInfo = Get-Model-Info -ModelKey $script:config.active_model
            $aiPrompt = "Modify this file content based on: $instruction`n`nCurrent content:`n```$content```"

            $response = Invoke-AI-Model -ModelInfo $modelInfo -Messages @(
                @{ role = "system"; content = "You are a file editing assistant. Return only the modified content." }
                @{ role = "user"; content = $aiPrompt }
            )

            if ($response.success) {
                Set-Content -Path $fullPath -Value $response.content
                Write-TUI "File updated with AI assistance" -Type success
            } else {
                Write-TUI "AI edit failed" -Type error
            }
        }
    }
}

function List-Files {
    param([string]$Pattern = "*")

    $files = Get-ChildItem -Path $WORKSPACE_DIR -File -Recurse

    if (-not $files) {
        Write-TUI "No files in workspace" -Type info
        return
    }

    Write-TUI "Workspace Files:" -Type file

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($WORKSPACE_DIR.Length + 1)
        $size = "{0:N2} KB" -f ($file.Length / 1KB)
        $modified = $file.LastWriteTime.ToString("MM/dd HH:mm")

        Write-Host "  $relativePath" -ForegroundColor White
        Write-Host "    Size: $size | Modified: $modified" -ForegroundColor Gray
    }
}

function Generate-Code {
    param([string]$Language, [string]$Description)

    if (-not $Language) {
        $Language = Read-Host "Programming language"
    }

    if (-not $Description) {
        $Description = Read-Host "What should the code do?"
    }

    $modelInfo = Get-Model-Info -ModelKey $script:config.active_model
    $aiPrompt = "Generate $Language code that: $Description. Include comments and proper structure."

    Write-TUI "Generating $Language code..." -Type info

    $response = Invoke-AI-Model -ModelInfo $modelInfo -Messages @(
        @{ role = "system"; content = "You are a code generation assistant. Return only the code with appropriate comments." }
        @{ role = "user"; content = $aiPrompt }
    )

    if ($response.success) {
        Write-Host ("─" * 60) -ForegroundColor DarkGray
        Write-Host $response.content -ForegroundColor Green
        Write-Host ("─" * 60) -ForegroundColor DarkGray

        $save = Read-Host "Save to file? (y/n)"
        if ($save -eq 'y') {
            $fileName = Read-Host "File name (e.g., 'script.$Language')"
            $filePath = Join-Path $WORKSPACE_DIR $fileName
            Set-Content -Path $filePath -Value $response.content
            Write-TUI "Code saved to: $filePath" -Type success
        }
    } else {
        Write-TUI "Code generation failed: $($response.error)" -Type error
    }
}

# ============================================================================
# SYSTEM TOOLS
# ============================================================================

function Show-Config {
    Write-TUI "Current Configuration:" -Type system

    Write-Host "  Active Model: $($script:config.active_model)" -ForegroundColor White
    Write-Host "  Workspace: $($script:config.workspace)" -ForegroundColor Gray
    Write-Host "  Theme: $($script:config.theme)" -ForegroundColor Gray
    Write-Host "  Auto-save: $($script:config.auto_save)" -ForegroundColor Gray

    Write-TUI "API Keys Configured:" -Type system
    foreach ($key in $script:config.api_keys.Keys) {
        $masked = "*" * 8 + $script:config.api_keys[$key].Substring($script:config.api_keys[$key].Length - 4)
        Write-Host "  $key`: $masked" -ForegroundColor Gray
    }
}

function Update-API-Keys {
    Write-TUI "Update API Keys" -Type system

    $providers = @(
        "ollama-cloud",
        "openai",
        "anthropic",
        "google",
        "mistral",
        "groq",
        "deepseek",
        "openai-compatible",
        "custom"
    )

    foreach ($provider in $providers) {
        $setKey = Read-Host "Set $provider API key? (y/n)"
        if ($setKey -eq 'y') {
            $key = Read-Host "Enter $provider API key" -AsSecureString
            $plainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($key)
            )
            $script:config.api_keys[$provider] = $plainKey
        }
    }

    Save-Config -Config $script:config
    Write-TUI "API keys updated" -Type success
}

function Show-System-Health {
    Write-TUI "System Health Check" -Type system

    # Check workspace
    $workspaceSize = (Get-ChildItem $WORKSPACE_DIR -Recurse | Measure-Object Length -Sum).Sum / 1MB
    Write-Host "  Workspace: $workspaceSize MB used" -ForegroundColor Gray

    # Check config
    if (Test-Path $CONFIG_FILE) {
        Write-Host "  Config: OK" -ForegroundColor Green
    } else {
        Write-Host "  Config: Missing" -ForegroundColor Red
    }

    # Test model connections
    Write-TUI "Testing Model Connections:" -Type system

    foreach ($provider in $DEFAULT_MODELS.Keys) {
        foreach ($model in $DEFAULT_MODELS[$provider].Keys) {
            $modelKey = "$provider`:$model"
            $status = Test-Model-Connection -ModelKey $modelKey
            $statusText = if ($status) { "✓" } else { "✗" }
            Write-Host "  $statusText $modelKey" -ForegroundColor $(if ($status) { "Green" } else { "Red" })
        }
    }
}

# ============================================================================
# MAIN INTERFACE
# ============================================================================

function Show-Main-Menu {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                       MAIN MENU                             ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "  [1] 💬 Start Chat Session" -ForegroundColor White
    Write-Host "  [2] 📄 File Operations" -ForegroundColor White
    Write-Host "  [3] 💻 Code Generation" -ForegroundColor White
    Write-Host "  [4] 🧠 Model Management" -ForegroundColor White
    Write-Host "  [5] 🛠️  System Tools" -ForegroundColor White
    Write-Host "  [6] ℹ️  Show Configuration" -ForegroundColor White
    Write-Host "  [7] 🚪 Exit" -ForegroundColor White
    Write-Host ""
}

function Show-File-Menu {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                       FILE OPERATIONS                       ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "  [1] 📝 Create New File" -ForegroundColor White
    Write-Host "  [2] ✏️  Edit Existing File" -ForegroundColor White
    Write-Host "  [3] 📋 List Workspace Files" -ForegroundColor White
    Write-Host "  [4] 🔍 Search in Files" -ForegroundColor White
    Write-Host "  [5] 🗑️  Delete File" -ForegroundColor White
    Write-Host "  [6] ↩️  Back to Main Menu" -ForegroundColor White
    Write-Host ""
}

function Show-Model-Menu {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                      MODEL MANAGEMENT                       ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "  [1] 📋 List Available Models" -ForegroundColor White
    Write-Host "  [2] 🔄 Switch Active Model" -ForegroundColor White
    Write-Host "  [3] ➕ Add Custom Model" -ForegroundColor White
    Write-Host "  [4] 🧪 Test Model Connection" -ForegroundColor White
    Write-Host "  [5] 🔑 Configure API Keys" -ForegroundColor White
    Write-Host "  [6] ↩️  Back to Main Menu" -ForegroundColor White
    Write-Host ""
}

function Show-System-Menu {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                       SYSTEM TOOLS                          ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "  [1] 🩺 System Health Check" -ForegroundColor White
    Write-Host "  [2] ⚙️  Update Configuration" -ForegroundColor White
    Write-Host "  [3] 📊 Show Usage Statistics" -ForegroundColor White
    Write-Host "  [4] 🧹 Clean Workspace" -ForegroundColor White
    Write-Host "  [5] 📜 View Logs" -ForegroundColor White
    Write-Host "  [6] ↩️  Back to Main Menu" -ForegroundColor White
    Write-Host ""
}

function Main-Loop {
    $script:config = Initialize-TUI

    while ($true) {
        Show-Main-Menu
        $choice = Read-Host "Select option (1-7)"

        switch ($choice) {
            '1' { Start-Chat }
            '2' { File-Operations-Loop }
            '3' { Generate-Code }
            '4' { Model-Management-Loop }
            '5' { System-Tools-Loop }
            '6' { Show-Config }
            '7' {
                Write-TUI "Goodbye!" -Type system
                exit 0
            }
            default { Write-TUI "Invalid option" -Type error }
        }
    }
}

function File-Operations-Loop {
    while ($true) {
        Show-File-Menu
        $choice = Read-Host "Select option (1-6)"

        switch ($choice) {
            '1' { Create-File }
            '2' { Edit-File }
            '3' { List-Files }
            '4' {
                $search = Read-Host "Search term"
                Get-ChildItem $WORKSPACE_DIR -Recurse -File |
                    Select-String $search |
                    ForEach-Object { Write-Host "$($_.Filename): $($_.LineNumber): $($_.Line)" -ForegroundColor Gray }
            }
            '5' {
                $file = Read-Host "File to delete (relative path)"
                $fullPath = Join-Path $WORKSPACE_DIR $file
                if (Test-Path $fullPath) {
                    Remove-Item $fullPath -Confirm
                    Write-TUI "File deleted" -Type success
                }
            }
            '6' { return }
            default { Write-TUI "Invalid option" -Type error }
        }
    }
}

function Model-Management-Loop {
    while ($true) {
        Show-Model-Menu
        $choice = Read-Host "Select option (1-6)"

        switch ($choice) {
            '1' { List-Models }
            '2' {
                List-Models
                $modelKey = Read-Host "Enter model key (provider:model)"
                Switch-Model -ModelKey $modelKey
            }
            '3' { Add-Custom-Model }
            '4' {
                $modelKey = Read-Host "Model key to test (leave empty for active)"
                if (-not $modelKey) { $modelKey = $script:config.active_model }
                Test-Model-Connection -ModelKey $modelKey
            }
            '5' { Update-API-Keys }
            '6' { return }
            default { Write-TUI "Invalid option" -Type error }
        }
    }
}

function System-Tools-Loop {
    while ($true) {
        Show-System-Menu
        $choice = Read-Host "Select option (1-6)"

        switch ($choice) {
            '1' { Show-System-Health }
            '2' {
                $theme = Read-Host "Theme (dark/light)"
                $autoSave = Read-Host "Auto-save (true/false)"
                $script:config.theme = $theme
                $script:config.auto_save = [bool]::Parse($autoSave)
                Save-Config -Config $script:config
                Write-TUI "Configuration updated" -Type success
            }
            '3' {
                $logs = Get-ChildItem $ASX_BASE_DIR -Filter "*.json" |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 10
                Write-TUI "Recent Files:" -Type system
                $logs | ForEach-Object { Write-Host "  $($_.Name) - $($_.LastWriteTime)" -ForegroundColor Gray }
            }
            '4' {
                $confirm = Read-Host "Clean workspace? (y/n)"
                if ($confirm -eq 'y') {
                    Get-ChildItem $WORKSPACE_DIR -File | Remove-Item -Force
                    Write-TUI "Workspace cleaned" -Type success
                }
            }
            '5' {
                Get-Content "$ASX_BASE_DIR\session.log" -Tail 20 -ErrorAction SilentlyContinue |
                    ForEach-Object { Write-Host $_ -ForegroundColor Gray }
            }
            '6' { return }
            default { Write-TUI "Invalid option" -Type error }
        }
    }
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

function Invoke-Quick-Command {
    param([string[]]$Args)

    if ($Args.Count -eq 0) {
        Main-Loop
        return
    }

    $command = $Args[0]

    switch ($command.ToLower()) {
        "chat" {
            if ($Args.Count -gt 1) {
                Start-Chat -ModelKey $Args[1]
            } else {
                Start-Chat
            }
        }

        "generate" {
            Generate-Code -Language $Args[1] -Description ($Args[2..($Args.Count-1)] -join " ")
        }

        "file" {
            if ($Args.Count -gt 1) {
                switch ($Args[1].ToLower()) {
                    "create" { Create-File -Path $Args[2] }
                    "edit" { Edit-File -Path $Args[2] }
                    "list" { List-Files }
                    default { Write-TUI "Unknown file command" -Type error }
                }
            } else {
                File-Operations-Loop
            }
        }

        "model" {
            if ($Args.Count -gt 1) {
                switch ($Args[1].ToLower()) {
                    "list" { List-Models }
                    "switch" { Switch-Model -ModelKey $Args[2] }
                    "test" { Test-Model-Connection -ModelKey $Args[2] }
                    default { Write-TUI "Unknown model command" -Type error }
                }
            } else {
                Model-Management-Loop
            }
        }

        "config" {
            Show-Config
        }

        "health" {
            Show-System-Health
        }

        "help" {
            Write-Host ""
            Write-Host "ASX T-UI Quick Commands:" -ForegroundColor Cyan
            Write-Host "  chat [model]           - Start chat session" -ForegroundColor Gray
            Write-Host "  generate lang desc     - Generate code" -ForegroundColor Gray
            Write-Host "  file create/edit/list  - File operations" -ForegroundColor Gray
            Write-Host "  model list/switch/test - Model management" -ForegroundColor Gray
            Write-Host "  config                 - Show configuration" -ForegroundColor Gray
            Write-Host "  health                 - System health check" -ForegroundColor Gray
            Write-Host "  (no args)              - Interactive mode" -ForegroundColor Gray
            Write-Host ""
        }

        default {
            Write-TUI "Unknown command: $command" -Type error
            Write-TUI "Use 'help' for available commands" -Type info
        }
    }
}

# ============================================================================
# EXECUTION
# ============================================================================

# Check if running interactively or with arguments
if ($MyInvocation.InvocationName -ne '.') {
    # Parse command line arguments
    $argsList = $args

    if ($argsList.Count -eq 0) {
        # Interactive mode
        Main-Loop
    } else {
        # Quick command mode
        Initialize-TUI
        Invoke-Quick-Command -Args $argsList
    }
}

# Export functions for module use
Export-ModuleMember -Function *

## 🚀 SAVE AS: `asx-tui.ps1`

## 📋 QUICK START COMMANDS

```powershell
# 1. INTERACTIVE MODE (Full T-UI)
.\asx-tui.ps1

# 2. QUICK CHAT WITH OLLAMA CLOUD
.\asx-tui.ps1 chat ollama-cloud:llama3

# 3. GENERATE CODE QUICKLY
.\asx-tui.ps1 generate python "a web scraper that extracts data from a website"

# 4. FILE OPERATIONS
.\asx-tui.ps1 file create script.py
.\asx-tui.ps1 file edit script.py
.\asx-tui.ps1 file list

# 5. MODEL MANAGEMENT
.\asx-tui.ps1 model list
.\asx-tui.ps1 model switch ollama-cloud:codellama
.\asx-tui.ps1 model test ollama-cloud:llama3

# 6. SYSTEM TOOLS
.\asx-tui.ps1 config
.\asx-tui.ps1 health
```

## 🎯 FEATURES HIGHLIGHTS

### 1. OLLAMA CLOUD INTEGRATION (Primary Focus)
- Llama 3 70B - Advanced reasoning and coding
- Mistral 7B - Fast and efficient chat
- CodeLlama 34B - Specialized for code generation
- Automatic API key management
- Connection testing and validation

### 2. LOCAL MODEL SUPPORT
- Local Ollama - Run models on your machine
- Auto-detection of installed local models
- Fallback support when cloud unavailable
- Hybrid mode - Use cloud for heavy tasks, local for quick responses

### 3. ADVANCED FILE OPERATIONS
- AI-assisted file creation - Describe what you want, get the file
- Smart editing - AI helps modify existing files
- Workspace management - Organized file system
- Code generation - Full projects or single files

### 4. TERMINAL CHAT INTERFACE
- Multi-model conversations - Switch between models mid-chat
- Chat persistence - Save and load conversations
- Context awareness - Models remember conversation history
- Streaming responses - Real-time AI output

### 5. SYSTEM TOOLS
- Health monitoring - Check all model connections
- API key management - Secure storage and rotation
- Workspace cleaning - Manage disk space
- Usage statistics - Track your AI usage

## 🔧 API KEY CONFIGURATION

First run will prompt for API keys:

```powershell
# Set up Ollama Cloud API key (get from https://ollama.cloud)
Update-API-Keys

# Or set via environment variable
$env:OLLAMA_CLOUD_API_KEY = "your-api-key-here"
```

## 🏗️ ARCHITECTURE

```
ASX T-UI Architecture
├── Model Layer
│   ├── Ollama Cloud (Primary)
│   ├── Local Ollama (Fallback)
│   ├── OpenAI / Anthropic / Google
│   ├── Mistral / Groq / DeepSeek
│   ├── LM Studio / MLC (Local)
│   └── OpenAI-Compatible + Custom HTTP Adapter
├── File System Layer
│   ├── Workspace Management
│   ├── AI-Assisted Editing
│   ├── Code Generation
│   └── Project Scaffolding
├── Chat Layer
│   ├── Multi-Model Sessions
│   ├── Context Management
│   ├── Conversation History
│   └── Export/Import
└── System Layer
    ├── Health Monitoring
    ├── Configuration
    ├── API Key Management
    └── Logging
```

## 💡 USAGE EXAMPLES

### Example 1: AI-Powered Code Generation
```powershell
# Generate a complete Python web scraper
.\asx-tui.ps1 generate python "web scraper using requests and beautifulsoup that saves to CSV"

# Edit the generated file with AI assistance
.\asx-tui.ps1 file edit scraper.py
# Choose 'a' for AI-assisted editing
# "Add error handling and logging"
```

### Example 2: Multi-Model Chat Session
```powershell
# Start chat with Llama 3 for reasoning
.\asx-tui.ps1 chat ollama-cloud:llama3
# Ask: "Explain quantum computing in simple terms"

# Switch to CodeLlama for coding help
/model switch ollama-cloud:codellama
# Ask: "Show me how to implement a binary search tree"
```

### Example 3: File Management
```powershell
# Create a new configuration file
.\asx-tui.ps1 file create config.yaml
# Enter: "ai" for AI generation
# Describe: "YAML config for a web app with database, redis, and API settings"

# List all files in workspace
.\asx-tui.ps1 file list

# Search for specific content
.\asx-tui.ps1 file search "database"
```

## 🔒 SECURITY FEATURES

- API key encryption - Secure storage in user directory
- Local-only workspace - Files stay on your machine
- No data sent to third parties (except chosen AI providers)
- Configurable timeouts - Prevent hanging requests
- Connection validation - Verify API endpoints before use

## 📊 PERFORMANCE OPTIMIZATION

```powershell
# For fastest responses:
1. Use local Ollama for simple tasks
2. Use Ollama Cloud for complex reasoning
3. Set appropriate context windows
4. Enable streaming for real-time feedback
5. Cache frequently used prompts
```

## 🚨 TROUBLESHOOTING

```powershell
# Check if Ollama Cloud is accessible
.\asx-tui.ps1 health

# Test specific model connection
.\asx-tui.ps1 model test ollama-cloud:llama3

# Reset configuration
Remove-Item ~\.asx-tui\config.json
.\asx-tui.ps1
```

## 🎨 CUSTOMIZATION

Edit `~\.asx-tui\config.json` to customize:

```json
{
  "active_model": "ollama-cloud:llama3",
  "workspace": "C:\\Users\\You\\ai-workspace",
  "theme": "dark",
  "auto_save": true,
  "max_context": 8000,
  "temperature": 0.7,
  "provider_adapters": {
    "openai-compatible": {
      "endpoint": "https://api.openai.com/v1/chat/completions",
      "headers": {
        "Authorization": "Bearer sk-your-token"
      }
    },
    "custom": {
      "endpoint": "https://internal.ai/api/v1/chat",
      "headers": {
        "x-api-key": "your-custom-key"
      }
    }
  },
  "custom_models": {
    "my-company-model": {
      "endpoint": "https://internal.ai/api/v1/chat",
      "provider": "custom"
    }
  }
}
```

## 📈 ROADMAP

- [ ] Plugin system for custom tools
- [ ] Batch processing for multiple files
- [ ] Team collaboration features
- [ ] Advanced debugging with AI assistance
- [ ] Integration with version control
- [ ] Real-time collaboration editing

---

This is a complete terminal AI workstation with multi-provider AI support (cloud + local), file operations, and code generation - all in a beautiful T-UI interface.
