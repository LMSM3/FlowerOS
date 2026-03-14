# FlowerOS Theme Engine (PowerShell)
# Universal theming system for PowerShell terminals

$ErrorActionPreference = "Stop"

# Theme engine configuration
$script:ThemeConfig = @{
    ThemeDir = "$PSScriptRoot\themes"
    ConfigFile = "$env:USERPROFILE\.floweros\theme.json"
    BackupFile = "$env:USERPROFILE\.floweros\theme.backup.json"
}

# Color conversion utilities
function Convert-HexToAnsi {
    param([string]$Hex)
    
    $Hex = $Hex.TrimStart('#')
    $r = [convert]::ToInt32($Hex.Substring(0,2), 16)
    $g = [convert]::ToInt32($Hex.Substring(2,2), 16)
    $b = [convert]::ToInt32($Hex.Substring(4,2), 16)
    
    return "`e[38;2;${r};${g};${b}m"
}

function Get-ThemeList {
    <#
    .SYNOPSIS
    List all available themes
    #>
    
    if (-not (Test-Path $script:ThemeConfig.ThemeDir)) {
        Write-Warning "Theme directory not found"
        return @()
    }
    
    Get-ChildItem -Path $script:ThemeConfig.ThemeDir -Filter "*.json" | ForEach-Object {
        $theme = Get-Content $_.FullName | ConvertFrom-Json
        [PSCustomObject]@{
            Name = $_.BaseName
            DisplayName = $theme.name
            Description = $theme.description
            Author = $theme.author
            File = $_.FullName
        }
    }
}

function Get-Theme {
    <#
    .SYNOPSIS
    Load a theme by name
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $themeFile = Join-Path $script:ThemeConfig.ThemeDir "$Name.json"
    
    if (-not (Test-Path $themeFile)) {
        throw "Theme '$Name' not found"
    }
    
    Get-Content $themeFile | ConvertFrom-Json
}

function Test-Theme {
    <#
    .SYNOPSIS
    Validate theme structure
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Theme
    )
    
    $required = @('name', 'version', 'colors', 'terminal')
    $missing = $required | Where-Object { -not ($Theme.PSObject.Properties.Name -contains $_) }
    
    if ($missing) {
        throw "Theme missing required fields: $($missing -join ', ')"
    }
    
    # Validate color format
    $colorProps = $Theme.colors.PSObject.Properties
    foreach ($prop in $colorProps) {
        if ($prop.Value -notmatch '^#[0-9A-Fa-f]{6}$') {
            throw "Invalid color format for '$($prop.Name)': $($prop.Value)"
        }
    }
    
    return $true
}

function Apply-ThemeToPowerShell {
    <#
    .SYNOPSIS
    Apply theme to current PowerShell session
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Theme
    )
    
    Write-Host "`n🎨 Applying theme: " -NoNewline
    Write-Host $Theme.name -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
    
    # Apply PSReadLine colors (if available)
    if (Get-Module -ListAvailable PSReadLine) {
        try {
            $readlineColors = @{
                Command = $Theme.colors.command
                Parameter = $Theme.colors.parameter
                String = $Theme.colors.string
                Comment = $Theme.colors.comment
                Keyword = $Theme.colors.keyword
                Variable = $Theme.colors.variable
                Operator = $Theme.colors.operator
                Number = $Theme.colors.number
            }
            
            Set-PSReadLineOption -Colors $readlineColors
            Write-Host "✓ PSReadLine colors applied" -ForegroundColor Green
        } catch {
            Write-Warning "Could not apply PSReadLine colors: $_"
        }
    }
    
    # Apply console colors
    if ($Theme.terminal.PSObject.Properties.Name -contains 'background') {
        try {
            $host.UI.RawUI.BackgroundColor = $Theme.terminal.background
            Write-Host "✓ Background color applied" -ForegroundColor Green
        } catch {
            Write-Warning "Could not set background color"
        }
    }
    
    if ($Theme.terminal.PSObject.Properties.Name -contains 'foreground') {
        try {
            $host.UI.RawUI.ForegroundColor = $Theme.terminal.foreground
            Write-Host "✓ Foreground color applied" -ForegroundColor Green
        } catch {
            Write-Warning "Could not set foreground color"
        }
    }
    
    # Apply prompt customization
    if ($Theme.PSObject.Properties.Name -contains 'prompt' -and $Theme.prompt) {
        try {
            $promptColor = Convert-HexToAnsi $Theme.colors.prompt
            $pathColor = Convert-HexToAnsi $Theme.colors.path
            $reset = "`e[0m"
            
            $global:FlowerOSPrompt = $Theme.prompt.template
            Write-Host "✓ Custom prompt configured" -ForegroundColor Green
        } catch {
            Write-Warning "Could not apply custom prompt"
        }
    }
    
    Write-Host "`n✨ Theme applied successfully!`n" -ForegroundColor Magenta
}

function Save-ThemeConfig {
    <#
    .SYNOPSIS
    Persist theme configuration
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ThemeName
    )
    
    $configDir = Split-Path $script:ThemeConfig.ConfigFile
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    # Backup existing config
    if (Test-Path $script:ThemeConfig.ConfigFile) {
        Copy-Item $script:ThemeConfig.ConfigFile $script:ThemeConfig.BackupFile -Force
    }
    
    $config = @{
        theme = $ThemeName
        applied = (Get-Date).ToString('o')
        version = "1.1.0"
    }
    
    $config | ConvertTo-Json | Set-Content $script:ThemeConfig.ConfigFile
    Write-Host "✓ Theme configuration saved to: $($script:ThemeConfig.ConfigFile)" -ForegroundColor Green
}

function Get-CurrentTheme {
    <#
    .SYNOPSIS
    Get currently active theme
    #>
    
    if (-not (Test-Path $script:ThemeConfig.ConfigFile)) {
        return $null
    }
    
    try {
        $config = Get-Content $script:ThemeConfig.ConfigFile | ConvertFrom-Json
        return $config.theme
    } catch {
        Write-Warning "Could not read theme config"
        return $null
    }
}

function Show-ThemePreview {
    <#
    .SYNOPSIS
    Display theme preview
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Theme
    )
    
    Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  " -NoNewline -ForegroundColor Cyan
    Write-Host "Theme Preview: $($Theme.name)" -NoNewline
    Write-Host (" " * (40 - $Theme.name.Length)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Show colors
    Write-Host "Colors:" -ForegroundColor Yellow
    $Theme.colors.PSObject.Properties | ForEach-Object {
        $colorName = $_.Name.PadRight(15)
        $hex = $_.Value
        $ansi = Convert-HexToAnsi $hex
        Write-Host "  $colorName : " -NoNewline
        Write-Host "$ansi█████████`e[0m $hex"
    }
    
    Write-Host "`nTerminal:" -ForegroundColor Yellow
    Write-Host "  Background  : $($Theme.terminal.background)"
    Write-Host "  Foreground  : $($Theme.terminal.foreground)"
    
    if ($Theme.PSObject.Properties.Name -contains 'prompt') {
        Write-Host "`nPrompt:" -ForegroundColor Yellow
        Write-Host "  Template    : $($Theme.prompt.template)"
    }
    
    Write-Host ""
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ThemeList',
    'Get-Theme',
    'Test-Theme',
    'Apply-ThemeToPowerShell',
    'Save-ThemeConfig',
    'Get-CurrentTheme',
    'Show-ThemePreview'
)
