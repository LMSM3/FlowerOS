#!/usr/bin/env pwsh
# FlowerOS Breathtaking Welcome System
# Creates a stunning visual experience on terminal launch

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ═══════════════════════════════════════════════════════════════════════════
#  Configuration
# ═══════════════════════════════════════════════════════════════════════════

$Script:Config = @{
    Version = "1.2.0"
    AsciiDir = "$PSScriptRoot/ascii"
    UseNerdFonts = $true
    ShowSystemInfo = $true
    AnimateWelcome = $false  # Set to $true for animation
}

# Nerd Font Icons (requires Nerd Font installed)
$Icons = @{
    OS = ""           # 
    Kernel = ""       # 
    CPU = ""          # 
    GPU = "󰢮"          # 󰢮
    Memory = ""       # 
    Disk = "󰋊"          # 󰋊
    Shell = ""        # 
    Terminal = ""     # 
    Git = ""          # 
    Package = "󰏖"       # 󰏖
    Time = ""         # 
    User = ""         # 
    Host = "󰒋"          # 󰒋
    Folder = ""       # 
    Flower = "🌸"
    Success = "✓"
    Arrow = ""        # 
    Branch = ""       # 
}

# Colors
$Colors = @{
    Primary = "Magenta"
    Secondary = "Cyan"
    Accent = "Yellow"
    Info = "Blue"
    Success = "Green"
    Muted = "Gray"
}

# ═══════════════════════════════════════════════════════════════════════════
#  ASCII Art Display
# ═══════════════════════════════════════════════════════════════════════════

function Show-FlowerOSArt {
    param(
        [Parameter()]
        [ValidateSet('small', 'medium', 'large')]
        [string]$Size = 'medium'
    )
    
    $artFile = Join-Path $Script:Config.AsciiDir "floweros-$Size.txt"
    
    if (Test-Path $artFile) {
        $art = Get-Content $artFile -Raw
        
        if ($Script:Config.AnimateWelcome) {
            # Animated reveal
            $lines = $art -split "`n"
            foreach ($line in $lines) {
                Write-Host $line -ForegroundColor $Colors.Primary
                Start-Sleep -Milliseconds 30
            }
        } else {
            Write-Host $art -ForegroundColor $Colors.Primary
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
#  System Information
# ═══════════════════════════════════════════════════════════════════════════

function Get-SystemInfo {
    $os = [System.Environment]::OSVersion
    $computerInfo = Get-ComputerInfo 2>$null
    
    $info = @{
        OS = if ($computerInfo) { 
            "$($computerInfo.WindowsProductName) $($computerInfo.WindowsVersion)"
        } else {
            "$($os.Platform) $($os.Version)"
        }
        User = $env:USERNAME
        Host = $env:COMPUTERNAME
        Kernel = $os.Version
        Shell = "PowerShell $($PSVersionTable.PSVersion)"
        Terminal = if ($env:TERM_PROGRAM) { $env:TERM_PROGRAM } else { "Windows Terminal" }
        CPU = (Get-WmiObject Win32_Processor).Name
        GPU = (Get-WmiObject Win32_VideoController).Name
        Memory = "{0:N2} GB" -f ((Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize / 1MB)
        Disk = "{0:N2} GB free" -f ((Get-PSDrive C).Free / 1GB)
        Uptime = (Get-Uptime -Since).ToString("d'd 'h'h 'm'm'")
    }
    
    return $info
}

function Show-SystemInfo {
    param($Info)
    
    Write-Host "`n" -NoNewline
    
    # Left column
    $leftWidth = 20
    
    # OS
    Write-Host " $($Icons.OS) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "OS".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.OS -ForegroundColor $Colors.Info
    
    # User@Host
    Write-Host " $($Icons.User) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "User".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host "$($Info.User)@$($Info.Host)" -ForegroundColor $Colors.Info
    
    # Kernel
    Write-Host " $($Icons.Kernel) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "Kernel".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.Kernel -ForegroundColor $Colors.Info
    
    # Shell
    Write-Host " $($Icons.Shell) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "Shell".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.Shell -ForegroundColor $Colors.Info
    
    # Terminal
    Write-Host " $($Icons.Terminal) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "Terminal".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.Terminal -ForegroundColor $Colors.Info
    
    # CPU
    Write-Host " $($Icons.CPU) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "CPU".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.CPU -ForegroundColor $Colors.Info
    
    # GPU
    if ($Info.GPU) {
        Write-Host " $($Icons.GPU) " -NoNewline -ForegroundColor $Colors.Secondary
        Write-Host "GPU".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
        Write-Host $Info.GPU -ForegroundColor $Colors.Info
    }
    
    # Memory
    Write-Host " $($Icons.Memory) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "Memory".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.Memory -ForegroundColor $Colors.Info
    
    # Disk
    Write-Host " $($Icons.Disk) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "Disk".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.Disk -ForegroundColor $Colors.Info
    
    # Uptime
    Write-Host " $($Icons.Time) " -NoNewline -ForegroundColor $Colors.Secondary
    Write-Host "Uptime".PadRight($leftWidth) -NoNewline -ForegroundColor $Colors.Muted
    Write-Host $Info.Uptime -ForegroundColor $Colors.Info
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Color Palette Display
# ═══════════════════════════════════════════════════════════════════════════

function Show-ColorPalette {
    Write-Host " Color Palette  " -NoNewline -ForegroundColor $Colors.Muted
    
    $palette = @(
        @{ Color = "Black"; Char = "█" },
        @{ Color = "DarkRed"; Char = "█" },
        @{ Color = "DarkGreen"; Char = "█" },
        @{ Color = "DarkYellow"; Char = "█" },
        @{ Color = "DarkBlue"; Char = "█" },
        @{ Color = "DarkMagenta"; Char = "█" },
        @{ Color = "DarkCyan"; Char = "█" },
        @{ Color = "Gray"; Char = "█" }
    )
    
    foreach ($color in $palette) {
        Write-Host $color.Char -NoNewline -ForegroundColor $color.Color
    }
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Random Wisdom/Quote
# ═══════════════════════════════════════════════════════════════════════════

function Show-Wisdom {
    $quotes = @(
        "Every terminal session is a garden 🌸",
        "Code with beauty, debug with grace 🌺",
        "Professional tools deserve professional themes 💎",
        "Simplicity is the ultimate sophistication ✨",
        "Make your terminal a place you love to be 🎨",
        "Beautiful code starts with a beautiful environment 🌟"
    )
    
    $quote = $quotes | Get-Random
    
    Write-Host "`n  $($Icons.Flower) " -NoNewline -ForegroundColor $Colors.Accent
    Write-Host $quote -ForegroundColor $Colors.Muted
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main Welcome Display
# ═══════════════════════════════════════════════════════════════════════════

function Show-Welcome {
    param(
        [Parameter()]
        [ValidateSet('small', 'medium', 'large', 'full')]
        [string]$Style = 'medium'
    )
    
    Clear-Host
    
    # ASCII Art
    if ($Style -eq 'full') {
        Show-FlowerOSArt -Size 'large'
    } elseif ($Style -ne 'small') {
        Show-FlowerOSArt -Size $Style
    }
    
    # System Info
    if ($Script:Config.ShowSystemInfo) {
        $sysInfo = Get-SystemInfo
        Show-SystemInfo -Info $sysInfo
    }
    
    # Color Palette
    Show-ColorPalette
    
    # Wisdom
    Show-Wisdom
}

# ═══════════════════════════════════════════════════════════════════════════
#  Installation Functions
# ═══════════════════════════════════════════════════════════════════════════

function Install-FlowerOSWelcome {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor $Colors.Primary
    Write-Host "║  🌸 FlowerOS Welcome System Installer                    ║" -ForegroundColor $Colors.Primary
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor $Colors.Primary
    
    $profilePath = $PROFILE
    $profileDir = Split-Path $profilePath
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Check if already installed
    if ((Test-Path $profilePath) -and (Get-Content $profilePath -Raw) -match "FlowerOS Welcome") {
        Write-Host "⚠ FlowerOS Welcome already installed" -ForegroundColor Yellow
        return
    }
    
    # Add to profile
    $welcomePath = $PSCommandPath
    $profileContent = @"

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Welcome v$($Script:Config.Version)
# ═══════════════════════════════════════════════════════════════════════════

. "$welcomePath"
Show-Welcome -Style medium

"@
    
    Add-Content -Path $profilePath -Value $profileContent
    
    Write-Host "✓ Installed to PowerShell profile" -ForegroundColor $Colors.Success
    Write-Host "  Profile: $profilePath" -ForegroundColor $Colors.Muted
    Write-Host "`n✨ Restart PowerShell to see the magic!`n" -ForegroundColor $Colors.Accent
}

# ═══════════════════════════════════════════════════════════════════════════
#  Module Exports
# ═══════════════════════════════════════════════════════════════════════════

Export-ModuleMember -Function @(
    'Show-Welcome',
    'Show-FlowerOSArt',
    'Show-SystemInfo',
    'Install-FlowerOSWelcome'
)

# Auto-show if not already in profile
if ($MyInvocation.InvocationName -eq '.' -or $Force) {
    Show-Welcome -Style medium
}
