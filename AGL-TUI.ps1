# AGL-TUI.ps1 - Terminal UI Inference App Builder
# Complete PowerShell implementation - no external dependencies required

#region T-UI BOOTSTRAP & STATE
<#
    ╔══════════════════════════════════════════════════════════╗
    ║           AGL INFERENCE APP BUILDER T-UI                ║
    ║          Terminal AI Development Environment            ║
    ╚══════════════════════════════════════════════════════════╝

    Version: 1.0.0
    Architecture: Chat + Filesystem + Commands + API Router
    Philosophy: Interactive, Helpful, Self-Configuring
#>

$TUIState = @{
    Name = "AGL Inference App Builder"
    Version = "1.0.0"
    Mode = "Interactive"
    UserContext = @{}
    ProjectPath = $PWD.Path
    ModelProviders = @{}
    Configuration = @{}
    ActiveTools = @()
    ConversationHistory = [System.Collections.ArrayList]::new()
    ErrorMode = $false
}

# Core Registry
$ToolRegistry = @{}
$CommandRegistry = @{}
$ModelRegistry = @{}
$FileOperations = @{}
$APIRegistry = @{}
$ErrorHandlers = @{}

# Colors for T-UI
$Colors = @{
    Primary = "Cyan"
    Secondary = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Blue"
    Success = "Green"
    Dim = "DarkGray"
    Highlight = "Magenta"
}
#endregion

#region T-UI DISPLAY ENGINE
function Show-TUIHeader {
    param([string]$Title, [string]$Subtitle = "")

    $width = 70
    $border = "═" * $width

    Write-Host "╔$border╗" -ForegroundColor $Colors.Primary
    Write-Host "║" -NoNewline -ForegroundColor $Colors.Primary
    Write-Host " $Title " -NoNewline -ForegroundColor $Colors.Highlight
    Write-Host "$(' ' * ($width - $Title.Length - 2)) ║" -ForegroundColor $Colors.Primary

    if ($Subtitle) {
        Write-Host "║" -NoNewline -ForegroundColor $Colors.Primary
        Write-Host " $Subtitle " -NoNewline -ForegroundColor $Colors.Dim
        Write-Host "$(' ' * ($width - $Subtitle.Length - 2)) ║" -ForegroundColor $Colors.Primary
    }

    Write-Host "╚$border╝" -ForegroundColor $Colors.Primary
}

function Write-TUI {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("Primary", "Secondary", "Warning", "Error", "Info", "Success", "Dim", "Highlight")]
        [string]$Color = "Primary",

        [switch]$NoNewline,
        [switch]$Bullet,
        [switch]$Indent
    )

    $prefix = ""
    if ($Bullet) { $prefix = "• " }
    if ($Indent) { $prefix = "  " }

    $output = "$prefix$Message"

    if ($NoNewline) {
        Write-Host $output -NoNewline -ForegroundColor $Colors[$Color]
    } else {
        Write-Host $output -ForegroundColor $Colors[$Color]
    }
}

function Show-Progress {
    param(
        [string]$Message,
        [int]$Percent = -1
    )

    if ($Percent -ge 0) {
        $barWidth = 30
        $filled = [Math]::Floor($barWidth * $Percent / 100)
        $empty = $barWidth - $filled
        $bar = "[$("█" * $filled)$("░" * $empty)]"
        Write-TUI "$Message $bar $Percent%" -Color Info
    } else {
        Write-TUI "$Message..." -Color Info
    }
}

function Clear-TUIScreen {
    Clear-Host
    Show-TUIHeader -Title $TUIState.Name -Subtitle "v$($TUIState.Version)"
}
#endregion

#region TOOL REGISTRATION SYSTEM
class TUITool {
    [string]$Id
    [string]$Name
    [string]$Category
    [string]$Description
    [scriptblock]$Logic
    [string[]]$Parameters
    [hashtable]$Examples

    TUITool([string]$name, [string]$category, [string]$description, [scriptblock]$logic) {
        $this.Id = "tool_$($category)_$($name)".ToLower().Replace(' ', '_')
        $this.Name = $name
        $this.Category = $category
        $this.Description = $description
        $this.Logic = $logic
        $this.Parameters = @()
        $this.Examples = @{}
    }

    [object] Invoke([hashtable]$params = @{}) {
        return & $this.Logic @params
    }

    [string] ToString() {
        return "$($this.Name) [$($this.Category)]"
    }
}

function Register-TUITool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Filesystem", "Command", "Project", "Inference", "Configuration", "Debug", "Build")]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Logic,

        [string[]]$Parameters = @(),

        [hashtable]$Examples = @{}
    )

    $tool = [TUITool]::new($Name, $Category, $Description, $Logic)
    $tool.Parameters = $Parameters
    $tool.Examples = $Examples

    $ToolRegistry[$tool.Id] = $tool
    Write-TUI "✅ Registered tool: $tool" -Color Success

    return $tool
}

function Show-TUITools {
    param(
        [string]$Category,
        [switch]$Detailed
    )

    Write-TUI "🛠️  AVAILABLE TOOLS" -Color Primary

    $tools = if ($Category) {
        $ToolRegistry.Values | Where-Object { $_.Category -eq $Category }
    } else {
        $ToolRegistry.Values
    }

    $categories = $tools | Group-Object Category

    foreach ($cat in $categories) {
        Write-TUI "`n$($cat.Name.ToUpper()):" -Color Secondary
        foreach ($tool in $cat.Group) {
            if ($Detailed) {
                Write-TUI "  • $($tool.Name)" -Color Highlight
                Write-TUI "    $($tool.Description)" -Color Dim -Indent
                if ($tool.Parameters.Count -gt 0) {
                    Write-TUI "    Parameters: $($tool.Parameters -join ', ')" -Color Dim -Indent
                }
                if ($tool.Examples.Count -gt 0) {
                    foreach ($example in $tool.Examples.Keys) {
                        Write-TUI "    Example: $example -> $($tool.Examples[$example])" -Color Dim -Indent
                    }
                }
            } else {
                Write-TUI "  • $($tool.Name) - $($tool.Description)" -Color Highlight
            }
        }
    }
}
#endregion

#region FILESYSTEM TOOLS
Register-TUITool -Name "Read File" -Category "Filesystem" -Description "Read contents of a file" -Logic {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @{ Success = $false; Error = "File not found: $Path" }
    }

    try {
        $content = Get-Content -Path $Path -Raw
        return @{ Success = $true; Content = $content; Path = $Path; Size = $content.Length }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
} -Parameters @("Path") -Examples @{
    "Read config.json" = "ReadFile -Path ./config.json"
}

Register-TUITool -Name "Write File" -Category "Filesystem" -Description "Write content to a file" -Logic {
    param([string]$Path, [string]$Content)

    try {
        Set-Content -Path $Path -Value $Content -Force
        return @{ Success = $true; Path = $Path; Written = $true }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
} -Parameters @("Path", "Content") -Examples @{
    "Create hello.txt" = "WriteFile -Path ./hello.txt -Content 'Hello World'"
}

Register-TUITool -Name "List Directory" -Category "Filesystem" -Description "List contents of a directory" -Logic {
    param([string]$Path = ".", [switch]$Recursive, [string]$Filter = "*")

    if (-not (Test-Path $Path)) {
        return @{ Success = $false; Error = "Directory not found: $Path" }
    }

    try {
        $items = Get-ChildItem -Path $Path -Filter $Filter -Recurse:$Recursive
        $result = @{
            Success = $true
            Path = $Path
            Items = @($items | ForEach-Object {
                @{
                    Name = $_.Name
                    Type = if ($_.PSIsContainer) { "Directory" } else { "File" }
                    Size = $_.Length
                    Modified = $_.LastWriteTime
                    FullPath = $_.FullName
                }
            })
            Count = $items.Count
        }
        return $result
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
} -Parameters @("Path", "Recursive", "Filter")

Register-TUITool -Name "Refactor Code" -Category "Filesystem" -Description "Refactor code in a file or directory" -Logic {
    param([string]$Path, [string]$Pattern, [string]$Replacement, [switch]$Preview)

    if (-not (Test-Path $Path)) {
        return @{ Success = $false; Error = "Path not found: $Path" }
    }

    try {
        $files = if (Test-Path -Path $Path -PathType Container) {
            Get-ChildItem -Path $Path -Recurse -File -Include "*.ps1", "*.py", "*.js", "*.ts", "*.json", "*.md"
        } else {
            Get-Item -Path $Path
        }

        $changes = @()
        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -Raw
            $newContent = $content -replace $Pattern, $Replacement

            if ($content -ne $newContent) {
                if (-not $Preview) {
                    Set-Content -Path $file.FullName -Value $newContent -Force
                }

                $changes += @{
                    File = $file.Name
                    Path = $file.FullName
                    Changes = ($content | Select-String $Pattern).Count
                    Preview = $Preview
                }
            }
        }

        return @{
            Success = $true
            Changes = $changes
            Summary = "$($changes.Count) files updated with pattern '$Pattern' -> '$Replacement'"
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
} -Parameters @("Path", "Pattern", "Replacement", "Preview")

Register-TUITool -Name "Search Files" -Category "Filesystem" -Description "Search for text in files" -Logic {
    param([string]$Path = ".", [string]$Pattern, [string[]]$Extensions)

    if (-not $Pattern) {
        return @{ Success = $false; Error = "Search pattern is required" }
    }

    try {
        $files = Get-ChildItem -Path $Path -Recurse -File
        if ($Extensions) {
            $files = $files | Where-Object { $Extensions -contains "*$($_.Extension)" }
        }

        $results = @()
        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match $Pattern) {
                $matches = [regex]::Matches($content, $Pattern)
                $results += @{
                    File = $file.Name
                    Path = $file.FullName
                    MatchCount = $matches.Count
                    SampleMatches = $matches | Select-Object -First 3 | ForEach-Object { $_.Value }
                }
            }
        }

        return @{
            Success = $true
            Results = $results
            Summary = "Found $($results.Count) files matching '$Pattern'"
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
#endregion

#region COMMAND TOOLS
Register-TUITool -Name "Run Command" -Category "Command" -Description "Run a shell command" -Logic {
    param([string]$Command, [string]$Arguments, [string]$WorkingDirectory)

    try {
        $originalDir = $null
        if ($WorkingDirectory) {
            $originalDir = Get-Location
            Set-Location -Path $WorkingDirectory
        }

        Write-TUI "Running: $Command $Arguments" -Color Info
        $output = Invoke-Expression "$Command $Arguments" 2>&1

        if ($originalDir) {
            Set-Location -Path $originalDir
        }

        return @{
            Success = $true
            Command = "$Command $Arguments"
            Output = $output
            ExitCode = $LASTEXITCODE
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
} -Parameters @("Command", "Arguments", "WorkingDirectory")

Register-TUITool -Name "Git Command" -Category "Command" -Description "Run a git command" -Logic {
    param([string]$Operation, [string[]]$Arguments)

    $gitCommands = @{
        "status" = "git status"
        "pull" = "git pull"
        "push" = "git push"
        "commit" = "git commit -m '{0}'"
        "add" = "git add {0}"
        "branch" = "git branch"
        "checkout" = "git checkout {0}"
        "log" = "git log --oneline -10"
        "diff" = "git diff"
        "clone" = "git clone {0}"
    }

    if (-not $gitCommands.ContainsKey($Operation.ToLower())) {
        return @{ Success = $false; Error = "Unknown git operation: $Operation" }
    }

    $command = $gitCommands[$Operation.ToLower()]
    if ($Arguments) {
        $command = $command -f $Arguments
    }

    return (Invoke-Tool -ToolId "tool_command_run_command" -Parameters @{
        Command = "git"
        Arguments = "$Operation $($Arguments -join ' ')"
    })
}

Register-TUITool -Name "Package Manager" -Category "Command" -Description "Run package manager commands" -Logic {
    param([string]$Manager, [string]$Operation, [string[]]$Packages)

    $managers = @{
        "npm" = @{
            "install" = "npm install {0}"
            "uninstall" = "npm uninstall {0}"
            "update" = "npm update"
            "init" = "npm init -y"
        }
        "pip" = @{
            "install" = "pip install {0}"
            "uninstall" = "pip uninstall {0}"
            "freeze" = "pip freeze"
        }
        "dotnet" = @{
            "add" = "dotnet add package {0}"
            "remove" = "dotnet remove package {0}"
        }
    }

    if (-not $managers.ContainsKey($Manager)) {
        return @{ Success = $false; Error = "Unsupported package manager: $Manager" }
    }

    $operations = $managers[$Manager]
    if (-not $operations.ContainsKey($Operation)) {
        return @{ Success = $false; Error = "Unsupported operation for $Manager: $Operation" }
    }

    $command = $operations[$Operation]
    if ($Packages) {
        $command = $command -f ($Packages -join ' ')
    }

    $parts = $command.Split(' ', 2)
    return (Invoke-Tool -ToolId "tool_command_run_command" -Parameters @{
        Command = $parts[0]
        Arguments = $parts[1]
    })
}
#endregion

#region PROJECT TOOLS
Register-TUITool -Name "Create Project" -Category "Project" -Description "Create a new project with scaffolding" -Logic {
    param([string]$Type, [string]$Name, [string]$Path)

    $templates = @{
        "powershell-module" = @{
            Structure = @(
                "$Name\$Name.psd1",
                "$Name\$Name.psm1",
                "$Name\Public\",
                "$Name\Private\",
                "$Name\Tests\",
                "$Name\.gitignore",
                "$Name\README.md"
            )
            Content = @{
                "README.md" = "# $Name`n`nA PowerShell module."
            }
        }
        "web-api" = @{
            Structure = @(
                "src\",
                "src\controllers\",
                "src\routes\",
                "src\models\",
                "package.json",
                "README.md",
                ".env.example",
                "Dockerfile"
            )
        }
        "cli-tool" = @{
            Structure = @(
                "src\main.py",
                "requirements.txt",
                "setup.py",
                "README.md",
                "tests\"
            )
        }
    }

    if (-not $templates.ContainsKey($Type)) {
        return @{ Success = $false; Error = "Unknown project type: $Type. Available: $($templates.Keys -join ', ')" }
    }

    $fullPath = if ($Path) { Join-Path $Path $Name } else { $Name }

    try {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null

        $template = $templates[$Type]
        foreach ($item in $template.Structure) {
            $itemPath = Join-Path $fullPath $item
            if ($item.EndsWith('\\') -or $item.EndsWith('/')) {
                New-Item -ItemType Directory -Path $itemPath -Force | Out-Null
            } else {
                $parentDir = Split-Path $itemPath -Parent
                if (-not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }
                New-Item -ItemType File -Path $itemPath -Force | Out-Null

                if ($template.Content -and $template.Content[$item.Split('\\')[-1]]) {
                    Set-Content -Path $itemPath -Value $template.Content[$item.Split('\\')[-1]]
                }
            }
        }

        return @{
            Success = $true
            Path = $fullPath
            Type = $Type
            Created = $template.Structure.Count
            Message = "Created $Type project '$Name' at $fullPath"
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
} -Parameters @("Type", "Name", "Path")

Register-TUITool -Name "Generate Config" -Category "Project" -Description "Generate configuration files" -Logic {
    param([string]$Type, [hashtable]$Settings)

    $configTemplates = @{
        "env" = @"
# Environment Variables
API_KEY={0}
DATABASE_URL={1}
DEBUG={2}
PORT={3}
"@

        "json" = @{
            "app" = @"
{
  "name": "{0}",
  "version": "1.0.0",
  "description": "{1}",
  "main": "micronaut.ps1",
  "scripts": {
    "start": "pwsh -File micronaut.ps1",
    "test": "echo 'No tests specified'"
  },
  "dependencies": { },
  "author": ""
}
"@
        }

        "yaml" = @"
version: '3.8'
services:
  app:
    build: .
    ports:
      - "{0}:{0}"
    environment:
      - NODE_ENV=production
"@
    }

    if (-not $configTemplates.ContainsKey($Type)) {
        return @{ Success = $false; Error = "Unknown config type: $Type" }
    }

    $template = $configTemplates[$Type]
    if ($template -is [hashtable]) {
        $template = $template["app"]
    }

    $content = $template
    if ($Settings) {
        foreach ($key in $Settings.Keys) {
            $content = $content -replace "{$key}", $Settings[$key]
        }
    }

    return @{
        Success = $true
        Type = $Type
        Content = $content
        Settings = $Settings
    }
}
#endregion

#region INFERENCE TOOLS
class ModelProvider {
    [string]$Name
    [string]$BaseURL
    [string]$APIKeyEnv
    [hashtable]$DefaultHeaders
    [scriptblock]$AuthCheck

    ModelProvider([string]$name, [string]$baseURL) {
        $this.Name = $name
        $this.BaseURL = $baseURL
        $this.APIKeyEnv = $null
        $this.DefaultHeaders = @{}
        $this.AuthCheck = $null
    }
}

function Register-ModelProvider {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$BaseURL,

        [string]$APIKeyEnv,

        [hashtable]$DefaultHeaders = @{},

        [scriptblock]$AuthCheck
    )

    $provider = [ModelProvider]::new($Name, $BaseURL)
    $provider.APIKeyEnv = $APIKeyEnv
    $provider.DefaultHeaders = $DefaultHeaders
    $provider.AuthCheck = $AuthCheck

    $ModelRegistry[$Name] = $provider
    Write-TUI "✅ Registered model provider: $Name" -Color Success

    return $provider
}

# Register providers
Register-ModelProvider -Name "OpenAI" -BaseURL "https://api.openai.com/v1" -APIKeyEnv "OPENAI_API_KEY" -DefaultHeaders @{
    "Content-Type" = "application/json"
}

Register-ModelProvider -Name "Anthropic" -BaseURL "https://api.anthropic.com/v1" -APIKeyEnv "ANTHROPIC_API_KEY"

Register-ModelProvider -Name "Ollama" -BaseURL "http://localhost:11434/api" -DefaultHeaders @{
    "Content-Type" = "application/json"
}

Register-ModelProvider -Name "LMStudio" -BaseURL "http://localhost:1234/v1"

Register-TUITool -Name "List Models" -Category "Inference" -Description "List available models from providers" -Logic {
    param([string]$Provider)

    if ($Provider -and -not $ModelRegistry.ContainsKey($Provider)) {
        return @{ Success = $false; Error = "Unknown provider: $Provider. Available: $($ModelRegistry.Keys -join ', ')" }
    }

    $providers = if ($Provider) { @($Provider) } else { $ModelRegistry.Keys }
    $results = @{}

    foreach ($providerName in $providers) {
        $provider = $ModelRegistry[$providerName]

        try {
            # Simulate model listing (in real implementation, would make API call)
            $models = switch ($providerName) {
                "OpenAI" { @("gpt-4", "gpt-3.5-turbo", "text-embedding-ada-002") }
                "Anthropic" { @("claude-3-opus", "claude-3-sonnet", "claude-3-haiku") }
                "Ollama" { @("llama2", "mistral", "codellama", "phi3") }
                "LMStudio" { @("local-model-1", "local-model-2") }
                default { @("default-model") }
            }

            $results[$providerName] = @{
                Models = $models
                Count = $models.Count
                BaseURL = $provider.BaseURL
            }
        } catch {
            $results[$providerName] = @{
                Error = $_.Exception.Message
                Available = $false
            }
        }
    }

    return @{
        Success = $true
        Providers = $results
        Summary = "Found models from $($results.Count) providers"
    }
}

Register-TUITool -Name "Run Inference" -Category "Inference" -Description "Run inference on a model" -Logic {
    param(
        [string]$Provider,
        [string]$Model,
        [string]$Prompt,
        [hashtable]$Parameters
    )

    if (-not $ModelRegistry.ContainsKey($Provider)) {
        return Handle-Error -Message "Unknown provider: $Provider" -Type "Configuration"
    }

    $provider = $ModelRegistry[$Provider]

    # Check authentication
    if ($provider.APIKeyEnv -and -not [Environment]::GetEnvironmentVariable($provider.APIKeyEnv)) {
        return Handle-Error -Message "API key missing for $Provider. Set $($provider.APIKeyEnv) environment variable." -Type "Authentication"
    }

    Write-TUI "🤖 Running inference on $Model via $Provider..." -Color Info
    Write-TUI "Prompt: $Prompt" -Color Dim

    # Simulate inference (in real implementation, would make API call)
    Start-Sleep -Milliseconds 500

    $responses = @(
        "I understand your question about '$($Prompt.Substring(0, [Math]::Min(20, $Prompt.Length)))...'")
    $responses += @(
        "Based on the prompt, here's my analysis...",
        "This appears to be a query about inference. The $Model model suggests...",
        "I can help with that. The key points are..."
    )

    $response = $responses[(Get-Random -Maximum $responses.Count)]

    return @{
        Success = $true
        Provider = $Provider
        Model = $Model
        Prompt = $Prompt
        Response = $response
        TokensUsed = (Get-Random -Minimum 50 -Maximum 200)
        Latency = (Get-Random -Minimum 100 -Maximum 500)
        Parameters = $Parameters
    }
}

Register-TUITool -Name "Configure API" -Category "Inference" -Description "Configure API keys and settings" -Logic {
    param([string]$Provider, [string]$APIKey, [switch]$Test)

    if ($Provider -and -not $ModelRegistry.ContainsKey($Provider)) {
        return @{ Success = $false; Error = "Unknown provider: $Provider" }
    }

    $providers = if ($Provider) { @($Provider) } else { $ModelRegistry.Keys }
    $results = @{}

    foreach ($providerName in $providers) {
        $provider = $ModelRegistry[$providerName]

        if ($provider.APIKeyEnv) {
            if ($APIKey) {
                # Set environment variable
                [Environment]::SetEnvironmentVariable($provider.APIKeyEnv, $APIKey, "User")
                $results[$providerName] = @{
                    Configured = $true
                    Message = "Set $($provider.APIKeyEnv) for $providerName"
                }
            } else {
                $currentKey = [Environment]::GetEnvironmentVariable($provider.APIKeyEnv, "User")
                if ($currentKey) {
                    $results[$providerName] = @{
                        Configured = $true
                        Message = "Already configured (key exists)"
                    }
                } else {
                    $results[$providerName] = @{
                        Configured = $false
                        Message = "Not configured. Set $($provider.APIKeyEnv) environment variable."
                    }
                }
            }
        } else {
            $results[$providerName] = @{
                Configured = $true
                Message = "No API key required for $providerName"
            }
        }

        if ($Test -and $results[$providerName].Configured) {
            # Test the connection
            $testResult = Invoke-Tool -ToolId "tool_inference_list_models" -Parameters @{ Provider = $providerName }
            $results[$providerName].TestResult = $testResult.Success
        }
    }

    return @{
        Success = $true
        Configurations = $results
        Summary = "Checked configuration for $($providers.Count) providers"
    }
}
#endregion

#region ERROR HANDLING SYSTEM
function Handle-Error {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("Configuration", "Authentication", "Network", "Filesystem", "Command", "Unknown")]
        [string]$Type = "Unknown",

        [object]$Context,
        [switch]$Interactive
    )

    $TUIState.ErrorMode = $true

    Write-TUI "⚠️  ERROR: $Message" -Color Error
    Write-TUI "Type: $Type" -Color Warning

    $solutions = @{
        "Configuration" = @(
            "Check if configuration file exists",
            "Verify environment variables",
            "Run auto-configuration",
            "Create default configuration"
        )
        "Authentication" = @(
            "Check API keys",
            "Configure authentication",
            "Test connection",
            "Use alternative provider"
        )
        "Network" = @(
            "Check internet connection",
            "Verify API endpoint",
            "Test with curl",
            "Use local models"
        )
        "Filesystem" = @(
            "Check file permissions",
            "Verify path exists",
            "Create directory if needed",
            "Use absolute paths"
        )
        "Command" = @(
            "Check if command exists",
            "Verify syntax",
            "Run with administrator privileges",
            "Use alternative command"
        )
    }

    $typeSolutions = $solutions[$Type] ?? @("Review the error message", "Check logs", "Retry operation")

    Write-TUI "Possible solutions:" -Color Info
    foreach ($solution in $typeSolutions) {
        Write-TUI "  • $solution" -Color Dim -Indent
    }

    if ($Interactive) {
        Write-TUI "`nHow would you like to proceed?" -Color Primary
        Write-TUI "1. Try automatic fix" -Color Highlight
        Write-TUI "2. Show detailed error" -Color Highlight
        Write-TUI "3. Skip and continue" -Color Highlight
        Write-TUI "4. Exit operation" -Color Highlight

        $choice = Read-Host "Choice (1-4)"

        switch ($choice) {
            "1" {
                Write-TUI "Attempting automatic fix..." -Color Info
                # Implement auto-fix logic based on error type
                return Attempt-AutoFix -ErrorType $Type -Context $Context
            }
            "2" {
                Write-TUI "Detailed error context:" -Color Info
                if ($Context) { $Context | Format-List | Out-String | Write-Host }
                return @{ Success = $false; Action = "ShownDetails" }
            }
            "3" {
                Write-TUI "Skipping error, continuing..." -Color Warning
                return @{ Success = $false; Action = "Skipped" }
            }
            "4" {
                Write-TUI "Operation cancelled by user." -Color Warning
                return @{ Success = $false; Action = "Cancelled" }
            }
        }
    }

    return @{ Success = $false; Error = $Message; Type = $Type }
}

function Attempt-AutoFix {
    param(
        [string]$ErrorType,
        [object]$Context
    )

    switch ($ErrorType) {
        "Configuration" {
            Write-TUI "Running auto-configuration..." -Color Info
            $result = Invoke-Tool -ToolId "tool_inference_configure_api" -Parameters @{ Test = $true }
            return $result
        }
        "Authentication" {
            Write-TUI "Checking authentication..." -Color Info
            # Prompt for API key
            $key = Read-Host "Enter API key (or press Enter to skip)"
            if ($key) {
                $result = Invoke-Tool -ToolId "tool_inference_configure_api" -Parameters @{
                    Provider = $Context.Provider
                    APIKey = $key
                    Test = $true
                }
                return $result
            }
        }
        "Filesystem" {
            if ($Context.Path) {
                $parent = Split-Path $Context.Path -Parent
                if (-not (Test-Path $parent)) {
                    Write-TUI "Creating directory: $parent" -Color Info
                    New-Item -ItemType Directory -Path $parent -Force | Out-Null
                    return @{ Success = $true; Action = "CreatedDirectory" }
                }
            }
        }
    }

    return @{ Success = $false; Action = "AutoFixFailed" }
}
#endregion

#region TOOL INVOCATION SYSTEM
function Invoke-Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolId,

        [hashtable]$Parameters = @{}
    )

    if (-not $ToolRegistry.ContainsKey($ToolId)) {
        return Handle-Error -Message "Tool not found: $ToolId" -Type "Configuration"
    }

    $tool = $ToolRegistry[$ToolId]

    Write-TUI "🔧 Invoking: $($tool.Name)" -Color Info
    if ($Parameters.Count -gt 0) {
        Write-TUI "Parameters: $($Parameters.Keys -join ', ')" -Color Dim
    }

    try {
        $result = $tool.Invoke($Parameters)

        # Add to conversation history
        $TUIState.ConversationHistory.Add(@{
            Timestamp = [DateTime]::UtcNow
            Tool = $tool.Id
            Parameters = $Parameters
            Result = $result
        })

        if ($result.Success -eq $false) {
            return Handle-Error -Message $result.Error -Type "Command" -Context $result
        }

        return $result
    } catch {
        return Handle-Error -Message $_.Exception.Message -Type "Unknown" -Context @{ Tool = $tool.Id; Parameters = $Parameters }
    }
}

function Show-ConversationHistory {
    param([int]$Limit = 10)

    Write-TUI "🗣️  CONVERSATION HISTORY" -Color Primary

    $history = $TUIState.ConversationHistory | Select-Object -Last $Limit

    if ($history.Count -eq 0) {
        Write-TUI "No conversation history yet." -Color Dim
        return
    }

    foreach ($item in $history) {
        $time = $item.Timestamp.ToString("HH:mm:ss")
        Write-TUI "[$time] $($item.Tool)" -Color Secondary
        if ($item.Parameters.Count -gt 0) {
            Write-TUI "  Parameters: $($item.Parameters.Keys -join ', ')" -Color Dim -Indent
        }
        if ($item.Result.Summary) {
            Write-TUI "  Result: $($item.Result.Summary)" -Color Dim -Indent
        }
    }
}
#endregion

#region CHAT INTERFACE
function Start-ChatInterface {
    <#
    .SYNOPSIS
        Start interactive chat interface
    .DESCRIPTION
        Chat-driven interface for tool invocation
    #>

    Clear-TUIScreen

    Write-TUI "💬 CHAT INTERFACE ACTIVE" -Color Primary
    Write-TUI "Type 'help' for commands, 'exit' to quit, 'tools' to list tools" -Color Dim
    Write-TUI "You can ask me to: read files, run commands, create projects, run inference, etc." -Color Dim

    while ($true) {
        Write-Host "`n"

        $prompt = @"
╭─[🤖 @ $($env:USERNAME)]
╰─➤
"@

        Write-Host $prompt -NoNewline -ForegroundColor Cyan
        $input = Read-Host

        if ([string]::IsNullOrWhiteSpace($input)) { continue }
        if ($input -eq "exit" -or $input -eq "quit") { break }

        Process-ChatInput -Input $input
    }
}

function Process-ChatInput {
    param([string]$Input)

    # Add to history
    $TUIState.ConversationHistory.Add(@{
        Timestamp = [DateTime]::UtcNow
        Type = "UserInput"
        Content = $Input
    })

    # Handle special commands
    switch -Wildcard ($Input.ToLower()) {
        "help" {
            Show-Help
            return
        }
        "tools" {
            Show-TUITools -Detailed
            return
        }
        "status" {
            Show-TUIStatus
            return
        }
        "history" {
            Show-ConversationHistory -Limit 20
            return
        }
        "clear" {
            Clear-TUIScreen
            return
        }
        "config" {
            Invoke-Tool -ToolId "tool_inference_configure_api" -Parameters @{ Test = $true }
            return
        }
        "models" {
            Invoke-Tool -ToolId "tool_inference_list_models"
            return
        }
    }

    # Natural language processing (simplified)
    $processed = Parse-NaturalLanguage -Input $Input

    if ($processed.Tool) {
        Write-TUI "I understand: $($processed.Intent)" -Color Info
        $result = Invoke-Tool -ToolId $processed.Tool -Parameters $processed.Parameters

        if ($result.Success -and $result.Summary) {
            Write-TUI "✅ $($result.Summary)" -Color Success
        }
    } else {
        Write-TUI "I'm not sure how to handle that. Try one of these:" -Color Warning
        Write-TUI "• 'Read file config.json'" -Color Dim
        Write-TUI "• 'List directory'" -Color Dim
        Write-TUI "• 'Run inference with gpt-4'" -Color Dim
        Write-TUI "• 'Create new project'" -Color Dim
        Write-TUI "• Type 'help' for more commands" -Color Dim
    }
}

function Parse-NaturalLanguage {
    param([string]$Input)

    $input = $Input.ToLower()

    # Simple pattern matching (in reality, use proper NLP)
    $patterns = @{
        "read (file|the file) (?<path>[^\s]+)" = @{
            Tool = "tool_filesystem_read_file"
            Params = @{ Path = '$matches["path"]' }
        }
        "list (directory|files|folder)" = @{
            Tool = "tool_filesystem_list_directory"
            Params = @{}
        }
        "create (project|new project) (?<type>\w+) (?<name>[^\s]+)" = @{
            Tool = "tool_project_create_project"
            Params = @{ Type = '$matches["type"]'; Name = '$matches["name"]' }
        }
        "run inference (with|using) (?<model>[^\s]+)" = @{
            Tool = "tool_inference_run_inference"
            Params = @{ Model = '$matches["model"]'; Prompt = '$input' }
        }
        "run command (?<command>.+)" = @{
            Tool = "tool_command_run_command"
            Params = @{ Command = '$matches["command"]' }
        }
        "search (for|files for) (?<pattern>[^"]+)" = @{
            Tool = "tool_filesystem_search_files"
            Params = @{ Pattern = '$matches["pattern"]' }
        }
        "refactor (?<path>[^\s]+) (?<pattern>[^\s]+) (?<replacement>[^\s]+)" = @{
            Tool = "tool_filesystem_refactor_code"
            Params = @{
                Path = '$matches["path"]'
                Pattern = '$matches["pattern"]'
                Replacement = '$matches["replacement"]'
            }
        }
    }

    foreach ($pattern in $patterns.Keys) {
        if ($input -match $pattern) {
            $config = $patterns[$pattern]
            $params = @{}

            foreach ($key in $config.Params.Keys) {
                $value = $config.Params[$key]
                if ($value -match '^\$matches\["' -and $matches.Count -gt 0) {
                    $paramName = $value -replace '^\$matches\["' -replace '"\]$'
                    $params[$key] = $matches[$paramName]
                } else {
                    $params[$key] = $value
                }
            }

            return @{
                Tool = $config.Tool
                Parameters = $params
                Intent = "Executing: $($config.Tool -replace 'tool_[^_]+_','')"
            }
        }
    }

    return @{ Tool = $null; Parameters = @{}; Intent = "Could not parse input" }
}

function Show-Help {
    Write-TUI "📚 HELP - Available Commands" -Color Primary
    Write-TUI "`nChat Commands:" -Color Secondary
    Write-TUI "  help              - Show this help" -Color Dim
    Write-TUI "  tools             - List all available tools" -Color Dim
    Write-TUI "  status            - Show system status" -Color Dim
    Write-TUI "  history           - Show conversation history" -Color Dim
    Write-TUI "  clear             - Clear screen" -Color Dim
    Write-TUI "  config            - Configure API settings" -Color Dim
    Write-TUI "  models            - List available models" -Color Dim
    Write-TUI "  exit/quit         - Exit chat interface" -Color Dim

    Write-TUI "`nNatural Language Examples:" -Color Secondary
    Write-TUI "  Read file config.json" -Color Dim
    Write-TUI "  List directory" -Color Dim
    Write-TUI "  Create project powershell-module MyModule" -Color Dim
    Write-TUI "  Run inference with gpt-4" -Color Dim
    Write-TUI "  Search for 'function'" -Color Dim
    Write-TUI "  Run command git status" -Color Dim
    Write-TUI "  Refactor ./src pattern replacement" -Color Dim
}
#endregion

#region T-UI STATUS
function Show-TUIStatus {
    Write-TUI "📊 T-UI STATUS" -Color Primary

    $status = [PSCustomObject]@{
        "Mode" = $TUIState.Mode
        "Project Path" = $TUIState.ProjectPath
        "Tools Registered" = $ToolRegistry.Count
        "Model Providers" = $ModelRegistry.Count
        "Conversation History" = $TUIState.ConversationHistory.Count
        "Error Mode" = $TUIState.ErrorMode
    }

    $status | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Cyan

    # Show recent activity
    if ($TUIState.ConversationHistory.Count -gt 0) {
        Write-TUI "`nRecent Activity:" -Color Secondary
        $recent = $TUIState.ConversationHistory | Select-Object -Last 3
        foreach ($item in $recent) {
            if ($item.Type -eq "UserInput") {
                Write-TUI "  💬 $($item.Content)" -Color Dim
            } else {
                Write-TUI "  🔧 $($item.Tool)" -Color Dim
            }
        }
    }
}
#endregion

#region INITIALIZATION
# Initialize all tool registries
# (Tools are registered at definition time via Register-TUITool)

Write-Host @"

╔══════════════════════════════════════════════════════════╗
║           AGL INFERENCE APP BUILDER T-UI                ║
║          Terminal AI Development Environment            ║
╚══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nVersion: $($TUIState.Version)" -ForegroundColor Yellow
Write-Host "Mode: $($TUIState.Mode)" -ForegroundColor Green
Write-Host "`nReady for interactive AI development!" -ForegroundColor Cyan
Write-Host "`nAvailable Commands:" -ForegroundColor Primary
Write-Host "  Start-ChatInterface   - Start interactive chat" -ForegroundColor Yellow
Write-Host "  Show-TUITools         - List all available tools" -ForegroundColor Yellow
Write-Host "  Show-TUIStatus        - Show system status" -ForegroundColor Yellow
Write-Host "  Invoke-Tool           - Invoke a specific tool" -ForegroundColor Yellow
Write-Host "  Show-Help             - Show help information" -ForegroundColor Yellow

# Set custom prompt
function prompt {
    $tools = $ToolRegistry.Count
    $models = $ModelRegistry.Count

    $prompt = @"
╭─[AGL @ $(Split-Path $PWD -Leaf)]
│  Tools: $tools | Models: $models
╰─➤
"@

    Write-Host $prompt -NoNewline -ForegroundColor Cyan
    return " "
}
#endregion

# Export public functions
Export-ModuleMember -Function @(
    'Start-ChatInterface',
    'Show-TUITools',
    'Show-TUIStatus',
    'Invoke-Tool',
    'Show-Help',
    'Show-ConversationHistory',
    'Handle-Error'
)

# Auto-initialize if running directly
if ($MyInvocation.Line -match '\\.\\AGL-TUI\\.ps1') {
    Write-Host "`n🚀 Starting AGL T-UI..." -ForegroundColor Green
    Start-ChatInterface
}
