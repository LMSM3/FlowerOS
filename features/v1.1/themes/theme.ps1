# FlowerOS Professional Theme System
# Simple, elegant light/grey themes only

$ErrorActionPreference = "Stop"

function Set-FlowerOSTheme {
    <#
    .SYNOPSIS
    Apply professional theme (light or grey)
    
    .PARAMETER Theme
    Theme name: "light" or "grey"
    
    .EXAMPLE
    Set-FlowerOSTheme -Theme light
    #>
    
    param(
        [Parameter(Mandatory)]
        [ValidateSet("light", "grey")]
        [string]$Theme
    )
    
    Write-Host "`n🎨 FlowerOS Professional Theme" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
    
    switch ($Theme) {
        "light" {
            # Clean, minimal light theme
            if (Get-Module -ListAvailable PSReadLine) {
                Set-PSReadLineOption -Colors @{
                    Command   = 'Blue'
                    Parameter = 'DarkGray'
                    String    = 'DarkGreen'
                    Comment   = 'Gray'
                }
            }
            
            $host.UI.RawUI.BackgroundColor = "White"
            $host.UI.RawUI.ForegroundColor = "Black"
            Clear-Host
            
            Write-Host "✓ Light theme applied" -ForegroundColor Green
        }
        
        "grey" {
            # Professional grey theme
            if (Get-Module -ListAvailable PSReadLine) {
                Set-PSReadLineOption -Colors @{
                    Command   = 'Cyan'
                    Parameter = 'Gray'
                    String    = 'Yellow'
                    Comment   = 'DarkGray'
                }
            }
            
            $host.UI.RawUI.BackgroundColor = "Black"
            $host.UI.RawUI.ForegroundColor = "Gray"
            Clear-Host
            
            Write-Host "✓ Grey theme applied" -ForegroundColor Green
        }
    }
    
    # Save preference
    $configDir = "$env:USERPROFILE\.floweros"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    @{ theme = $Theme; version = "1.1.0" } | ConvertTo-Json | 
        Set-Content "$configDir\theme.json"
    
    Write-Host "`n✨ Professional and clean!`n" -ForegroundColor Magenta
}

function Get-FlowerOSTheme {
    <#
    .SYNOPSIS
    Get current theme
    #>
    
    $configFile = "$env:USERPROFILE\.floweros\theme.json"
    
    if (Test-Path $configFile) {
        $config = Get-Content $configFile | ConvertFrom-Json
        return $config.theme
    }
    
    return "none"
}

Export-ModuleMember -Function @('Set-FlowerOSTheme', 'Get-FlowerOSTheme')
