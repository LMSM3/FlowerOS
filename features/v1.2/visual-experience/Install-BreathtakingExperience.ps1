#!/usr/bin/env pwsh
# FlowerOS Breathtaking Experience Installer
# One-command transformation from boring to beautiful

param(
    [switch]$SkipFonts,
    [switch]$SkipTerminalConfig,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ═══════════════════════════════════════════════════════════════════════════
#  Configuration
# ═══════════════════════════════════════════════════════════════════════════

$Script:Config = @{
    Version = "1.2.0"
    BaseDir = $PSScriptRoot
    NerdFontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
    FontName = "CaskaydiaCove Nerd Font"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Beautiful Header
# ═══════════════════════════════════════════════════════════════════════════

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                                                      ║" -ForegroundColor Magenta
    Write-Host "║     🌸 FlowerOS v1.2.0 - Breathtaking Experience Installer 🌸       ║" -ForegroundColor Magenta
    Write-Host "║                                                                      ║" -ForegroundColor Magenta
    Write-Host "║         Transform your terminal from boring to BEAUTIFUL!            ║" -ForegroundColor Magenta
    Write-Host "║                                                                      ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Progress Display
# ═══════════════════════════════════════════════════════════════════════════

function Show-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [string]$Icon = "  "
    )
    
    Write-Host "`n$Icon " -NoNewline -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor White
    Write-Host ("─" * 70) -ForegroundColor DarkGray
}

function Show-Success {
    param([string]$Message)
    Write-Host "  ✓ " -NoNewline -ForegroundColor Green
    Write-Host $Message -ForegroundColor Gray
}

function Show-Warning {
    param([string]$Message)
    Write-Host "  ⚠ " -NoNewline -ForegroundColor Yellow
    Write-Host $Message -ForegroundColor Gray
}

function Show-Error {
    param([string]$Message)
    Write-Host "  ✗ " -NoNewline -ForegroundColor Red
    Write-Host $Message -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════════════════
#  Nerd Font Installation
# ═══════════════════════════════════════════════════════════════════════════

function Install-NerdFont {
    if ($SkipFonts) {
        Show-Warning "Skipping font installation (--SkipFonts specified)"
        return
    }
    
    Show-Step "Installing Nerd Fonts" "📦"
    
    # Check if already installed
    $fonts = [System.Drawing.Text.InstalledFontCollection]::new()
    if ($fonts.Families.Name -contains $Script:Config.FontName) {
        Show-Success "$($Script:Config.FontName) already installed"
        return
    }
    
    try {
        $tempDir = Join-Path $env:TEMP "floweros-fonts"
        $zipPath = Join-Path $tempDir "CascadiaCode.zip"
        
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        Write-Host "  → Downloading Cascadia Code Nerd Font..." -ForegroundColor Gray
        
        # Download font
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Script:Config.NerdFontUrl -OutFile $zipPath -UseBasicParsing
        
        Write-Host "  → Extracting..." -ForegroundColor Gray
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        
        Write-Host "  → Installing fonts..." -ForegroundColor Gray
        
        # Install fonts
        $fontsFolder = [Environment]::GetFolderPath("Fonts")
        $shell = New-Object -ComObject Shell.Application
        $fontsDir = $shell.Namespace($fontsFolder)
        
        $installed = 0
        Get-ChildItem $tempDir -Filter "*.ttf" | ForEach-Object {
            try {
                $fontsDir.CopyHere($_.FullName, 0x10)
                $installed++
            } catch {
                # Font might already exist
            }
        }
        
        # Cleanup
        Remove-Item -Path $tempDir -Recurse -Force
        
        Show-Success "Installed $installed Nerd Font files"
        Show-Warning "You may need to restart applications to see new fonts"
        
    } catch {
        Show-Error "Failed to install fonts: $_"
        Show-Warning "You can install manually from: https://www.nerdfonts.com/font-downloads"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
#  Windows Terminal Configuration
# ═══════════════════════════════════════════════════════════════════════════

function Install-WindowsTerminalConfig {
    if ($SkipTerminalConfig) {
        Show-Warning "Skipping Windows Terminal configuration (--SkipTerminalConfig specified)"
        return
    }
    
    Show-Step "Configuring Windows Terminal" "🎨"
    
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    if (-not (Test-Path $wtSettingsPath)) {
        Show-Warning "Windows Terminal settings not found - install Windows Terminal first"
        return
    }
    
    try {
        # Backup existing settings
        $backupPath = "$wtSettingsPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $wtSettingsPath $backupPath
        Show-Success "Backed up settings to: $(Split-Path $backupPath -Leaf)"
        
        # Read our configuration
        $ourConfig = Get-Content "$Script:Config.BaseDir\windows-terminal-settings.json" -Raw | ConvertFrom-Json
        
        # Read existing settings
        $existingSettings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
        
        # Merge configurations
        # Add our themes
        if (-not $existingSettings.themes) {
            $existingSettings | Add-Member -MemberType NoteProperty -Name "themes" -Value @()
        }
        foreach ($theme in $ourConfig.themes) {
            $existingSettings.themes += $theme
        }
        
        # Add our color schemes
        if (-not $existingSettings.schemes) {
            $existingSettings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @()
        }
        foreach ($scheme in $ourConfig.schemes) {
            $existingSettings.schemes += $scheme
        }
        
        # Update profile defaults
        if ($existingSettings.profiles -and $existingSettings.profiles.defaults) {
            $ourConfig.profiles.defaults.PSObject.Properties | ForEach-Object {
                $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
            }
        }
        
        # Save merged settings
        $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $wtSettingsPath
        
        Show-Success "Windows Terminal configured with FlowerOS themes"
        Show-Success "Applied: Transparency, Acrylic effects, Beautiful colors"
        
    } catch {
        Show-Error "Failed to configure Windows Terminal: $_"
        Show-Warning "You can manually copy settings from: windows-terminal-settings.json"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
#  Welcome System Installation
# ═══════════════════════════════════════════════════════════════════════════

function Install-WelcomeSystem {
    Show-Step "Installing Welcome System" "🌸"
    
    $welcomeScript = Join-Path $Script:Config.BaseDir "FlowerOS-Welcome.ps1"
    
    if (-not (Test-Path $welcomeScript)) {
        Show-Error "Welcome script not found"
        return
    }
    
    # Load and install
    . $welcomeScript
    Install-FlowerOSWelcome
    
    Show-Success "Welcome system installed to PowerShell profile"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Preview
# ═══════════════════════════════════════════════════════════════════════════

function Show-Preview {
    Show-Step "🎉 Installation Complete!" "✨"
    
    Write-Host ""
    Write-Host "  Your terminal transformation includes:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    🌸  Beautiful ASCII art welcome screen" -ForegroundColor Magenta
    Write-Host "    🎨  Semi-transparent terminal with acrylic effects" -ForegroundColor Magenta
    Write-Host "    📊  System info display with icons" -ForegroundColor Magenta
    Write-Host "    🔠  Nerd Font icons for professional look" -ForegroundColor Magenta
    Write-Host "    🌈  3 gorgeous color schemes (Dracula, Tokyo Night, Nord)" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "  Next Steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    1. " -NoNewline -ForegroundColor Gray
    Write-Host "Restart Windows Terminal" -ForegroundColor White
    Write-Host "    2. " -NoNewline -ForegroundColor Gray
    Write-Host "Open a new PowerShell tab" -ForegroundColor White
    Write-Host "    3. " -NoNewline -ForegroundColor Gray
    Write-Host "See the magic! 🎭" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  To change themes:" -ForegroundColor Yellow
    Write-Host "    • Open Windows Terminal settings (Ctrl+,)" -ForegroundColor Gray
    Write-Host "    • Select a profile" -ForegroundColor Gray
    Write-Host "    • Change 'Color scheme' to FlowerOS Dracula/Tokyo Night/Nord" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  🌺 Every terminal session is now a garden! 🌺" -ForegroundColor Magenta
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main Installation
# ═══════════════════════════════════════════════════════════════════════════

Show-Header

Write-Host "This installer will:" -ForegroundColor Cyan
Write-Host "  • Install Nerd Fonts (for beautiful icons)" -ForegroundColor Gray
Write-Host "  • Configure Windows Terminal (transparency, themes)" -ForegroundColor Gray
Write-Host "  • Set up welcome screen (ASCII art, system info)" -ForegroundColor Gray
Write-Host ""

if (-not $Force) {
    $response = Read-Host "Continue? (Y/n)"
    if ($response -match '^[Nn]') {
        Write-Host "`nInstallation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""

# Run installations
Install-NerdFont
Install-WindowsTerminalConfig
Install-WelcomeSystem

# Show preview
Show-Preview

# Test welcome
Write-Host "  Preview of welcome screen:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

. "$Script:Config.BaseDir\FlowerOS-Welcome.ps1"
Show-Welcome -Style small

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
