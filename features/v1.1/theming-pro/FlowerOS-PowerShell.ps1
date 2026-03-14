# FlowerOS Professional PowerShell Theme
# Optimized for Visual Studio Code & PowerShell 7+
# Features: Git integration, smart prompt, custom colors

#Requires -Version 5.1

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS PowerShell Theme Engine
# ═══════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$Script:FlowerOSConfig = @{
    Version = "1.1.1"
    ThemeDir = "$PSScriptRoot"
    ConfigDir = "$env:USERPROFILE\.floweros"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Color Definitions
# ─────────────────────────────────────────────────────────────────────────────

$Script:FlowerOSColors = @{
    # Prompt elements
    PromptUser      = 'Cyan'
    PromptPath      = 'Blue'
    PromptGit       = 'Magenta'
    PromptArrow     = 'Green'
    PromptError     = 'Red'
    
    # Syntax highlighting (PSReadLine)
    Command         = 'Yellow'
    Parameter       = 'DarkGray'
    String          = 'DarkGreen'
    Comment         = 'DarkGray'
    Keyword         = 'Green'
    Variable        = 'Blue'
    Operator        = 'DarkGray'
    Number          = 'Cyan'
    Type            = 'Cyan'
    Member          = 'White'
    
    # Special
    Success         = 'Green'
    Warning         = 'Yellow'
    Error           = 'Red'
    Info            = 'Cyan'
}

# ─────────────────────────────────────────────────────────────────────────────
#  Git Integration
# ─────────────────────────────────────────────────────────────────────────────

function Get-GitStatus {
    <#
    .SYNOPSIS
    Get current git branch and status
    #>
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return $null
    }
    
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) { return $null }
        
        $status = git status --porcelain 2>$null
        $hasChanges = $status -ne $null -and $status.Length -gt 0
        
        return @{
            Branch = $branch
            HasChanges = $hasChanges
            Symbol = if ($hasChanges) { "±" } else { "✓" }
        }
    } catch {
        return $null
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  Custom Prompt
# ─────────────────────────────────────────────────────────────────────────────

function prompt {
    $lastSuccess = $?
    $lastExitCode = $LASTEXITCODE
    
    # Save cursor position
    $Host.UI.RawUI.CursorPosition | Out-Null
    
    # User & Computer
    $user = $env:USERNAME
    $computer = $env:COMPUTERNAME
    
    Write-Host "[$user@$computer]" -NoNewline -ForegroundColor $Script:FlowerOSColors.PromptUser
    Write-Host " " -NoNewline
    
    # Current Path (shortened if too long)
    $path = Get-Location
    $pathStr = $path.Path
    
    # Shorten home directory
    if ($pathStr.StartsWith($HOME)) {
        $pathStr = "~" + $pathStr.Substring($HOME.Length)
    }
    
    # Shorten long paths
    if ($pathStr.Length -gt 50) {
        $parts = $pathStr -split '\\'
        if ($parts.Count -gt 3) {
            $pathStr = "$($parts[0])\...\$($parts[-2])\$($parts[-1])"
        }
    }
    
    Write-Host $pathStr -NoNewline -ForegroundColor $Script:FlowerOSColors.PromptPath
    
    # Git status
    $git = Get-GitStatus
    if ($git) {
        Write-Host " [" -NoNewline -ForegroundColor DarkGray
        Write-Host "git:" -NoNewline -ForegroundColor $Script:FlowerOSColors.PromptGit
        Write-Host $git.Branch -NoNewline -ForegroundColor $Script:FlowerOSColors.PromptGit
        Write-Host " $($git.Symbol)" -NoNewline -ForegroundColor $(
            if ($git.HasChanges) { 'Yellow' } else { 'Green' }
        )
        Write-Host "]" -NoNewline -ForegroundColor DarkGray
    }
    
    # Newline before prompt character
    Write-Host ""
    
    # Prompt character (changes color based on last command success)
    $promptChar = if ($lastSuccess) {
        Write-Host "❯" -NoNewline -ForegroundColor $Script:FlowerOSColors.PromptArrow
    } else {
        Write-Host "❯" -NoNewline -ForegroundColor $Script:FlowerOSColors.PromptError
    }
    
    # Restore exit code
    $global:LASTEXITCODE = $lastExitCode
    
    return " "
}

# ─────────────────────────────────────────────────────────────────────────────
#  PSReadLine Configuration
# ─────────────────────────────────────────────────────────────────────────────

function Initialize-PSReadLine {
    if (Get-Module -ListAvailable PSReadLine) {
        Import-Module PSReadLine
        
        # Key bindings
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
        
        # Syntax colors
        Set-PSReadLineOption -Colors @{
            Command   = $Script:FlowerOSColors.Command
            Parameter = $Script:FlowerOSColors.Parameter
            String    = $Script:FlowerOSColors.String
            Comment   = $Script:FlowerOSColors.Comment
            Keyword   = $Script:FlowerOSColors.Keyword
            Variable  = $Script:FlowerOSColors.Variable
            Operator  = $Script:FlowerOSColors.Operator
            Number    = $Script:FlowerOSColors.Number
            Type      = $Script:FlowerOSColors.Type
            Member    = $Script:FlowerOSColors.Member
        }
        
        # Prediction
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineOption -BellStyle None
        
        Write-Host "✓ PSReadLine configured" -ForegroundColor $Script:FlowerOSColors.Success
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  VS Code Integration
# ─────────────────────────────────────────────────────────────────────────────

function Test-VSCode {
    return $env:TERM_PROGRAM -eq 'vscode' -or $env:VSCODE_PID
}

function Initialize-VSCodeIntegration {
    if (Test-VSCode) {
        Write-Host "✓ VS Code detected" -ForegroundColor $Script:FlowerOSColors.Info
        
        # VS Code specific settings
        $host.UI.RawUI.BackgroundColor = 'Black'
        
        # Import VS Code shell integration if available
        if (Test-Path "$env:APPDATA\Code\User\shellIntegration.ps1") {
            . "$env:APPDATA\Code\User\shellIntegration.ps1"
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  Useful Aliases & Functions
# ─────────────────────────────────────────────────────────────────────────────

# Git shortcuts
function gs { git status $args }
function ga { git add $args }
function gc { git commit -m $args }
function gp { git push $args }
function gl { git log --oneline --graph --decorate --all }

# Directory navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Enhanced ls
function ll { Get-ChildItem -Force $args | Format-Table -AutoSize }
function la { Get-ChildItem -Force $args }

# Quick edit
function e { 
    param($file)
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $file
    } else {
        notepad $file
    }
}

# Clear screen
function c { Clear-Host }

# Touch (create file)
function touch {
    param($file)
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "✓ Created: $file" -ForegroundColor $Script:FlowerOSColors.Success
    } else {
        (Get-Item $file).LastWriteTime = Get-Date
        Write-Host "✓ Updated: $file" -ForegroundColor $Script:FlowerOSColors.Success
    }
}

# Which command
function which {
    param($command)
    Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

# ─────────────────────────────────────────────────────────────────────────────
#  Theme Installation
# ─────────────────────────────────────────────────────────────────────────────

function Install-FlowerOSTheme {
    <#
    .SYNOPSIS
    Install FlowerOS theme to PowerShell profile
    #>
    
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  FlowerOS Professional PowerShell Theme Installer" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Ensure config directory
    if (-not (Test-Path $Script:FlowerOSConfig.ConfigDir)) {
        New-Item -ItemType Directory -Path $Script:FlowerOSConfig.ConfigDir -Force | Out-Null
    }
    
    # Get profile path
    $profilePath = $PROFILE
    $profileDir = Split-Path $profilePath
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "✓ Created profile directory" -ForegroundColor $Script:FlowerOSColors.Success
    }
    
    # Check if already installed
    if (Test-Path $profilePath) {
        $content = Get-Content $profilePath -Raw
        if ($content -match "FlowerOS Theme") {
            Write-Host "⚠ FlowerOS theme already installed in profile" -ForegroundColor $Script:FlowerOSColors.Warning
            Write-Host "  Profile: $profilePath`n" -ForegroundColor Gray
            return
        }
    }
    
    # Add to profile
    $themePath = $PSCommandPath
    $profileContent = @"

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Theme v$($Script:FlowerOSConfig.Version)
#  Loaded: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ═══════════════════════════════════════════════════════════════════════════

. "$themePath"
Initialize-PSReadLine
Initialize-VSCodeIntegration

Write-Host "🌸 FlowerOS v$($Script:FlowerOSConfig.Version) loaded" -ForegroundColor Magenta

"@
    
    Add-Content -Path $profilePath -Value $profileContent
    
    Write-Host "✓ Installed to PowerShell profile" -ForegroundColor $Script:FlowerOSColors.Success
    Write-Host "  Profile: $profilePath" -ForegroundColor Gray
    Write-Host "`n✨ Restart PowerShell or run: . `$PROFILE`n" -ForegroundColor $Script:FlowerOSColors.Info
}

function Uninstall-FlowerOSTheme {
    <#
    .SYNOPSIS
    Remove FlowerOS theme from PowerShell profile
    #>
    
    if (-not (Test-Path $PROFILE)) {
        Write-Host "No profile found" -ForegroundColor $Script:FlowerOSColors.Warning
        return
    }
    
    $content = Get-Content $PROFILE -Raw
    
    # Remove FlowerOS section
    $pattern = '(?s)# ═+\s*#\s*FlowerOS Theme.*?# ═+\s*'
    $newContent = $content -replace $pattern, ''
    
    # Also remove any standalone FlowerOS lines
    $newContent = $newContent -replace '(?m)^.*FlowerOS.*$\r?\n?', ''
    
    Set-Content -Path $PROFILE -Value $newContent.Trim()
    
    Write-Host "✓ FlowerOS theme removed from profile" -ForegroundColor $Script:FlowerOSColors.Success
    Write-Host "  Restart PowerShell to complete removal`n" -ForegroundColor Gray
}

# ─────────────────────────────────────────────────────────────────────────────
#  Welcome Message
# ─────────────────────────────────────────────────────────────────────────────

function Show-FlowerOSWelcome {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  🌸 FlowerOS PowerShell Theme v$($Script:FlowerOSConfig.Version)" -ForegroundColor Cyan -NoNewline
    Write-Host (" " * (46 - $Script:FlowerOSConfig.Version.Length)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  Professional theming for PowerShell & VS Code" -ForegroundColor Gray
    Write-Host "  Type " -NoNewline -ForegroundColor Gray
    Write-Host "Install-FlowerOSTheme" -NoNewline -ForegroundColor Yellow
    Write-Host " to install`n" -ForegroundColor Gray
}

# ─────────────────────────────────────────────────────────────────────────────
#  Module Exports
# ─────────────────────────────────────────────────────────────────────────────

Export-ModuleMember -Function @(
    'Install-FlowerOSTheme',
    'Uninstall-FlowerOSTheme',
    'Show-FlowerOSWelcome',
    'Initialize-PSReadLine',
    'Initialize-VSCodeIntegration',
    'Get-GitStatus'
)

Export-ModuleMember -Alias @(
    'gs', 'ga', 'gc', 'gp', 'gl',
    'll', 'la', 'e', 'c',
    '..', '...', '....'
)

# Auto-show welcome if not sourced from profile
if ($MyInvocation.InvocationName -ne '.') {
    Show-FlowerOSWelcome
}
