# FlowerOS Professional Theme Installer (PowerShell)
# One-command installation for VS Code & PowerShell

param(
    [Parameter()]
    [ValidateSet('install', 'uninstall', 'status')]
    [string]$Action = 'install'
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🌸 FlowerOS Professional Theme Installer                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$themePath = Join-Path $PSScriptRoot "FlowerOS-PowerShell.ps1"

switch ($Action) {
    'install' {
        Write-Host "Installing FlowerOS theme...`n" -ForegroundColor Yellow
        
        if (-not (Test-Path $themePath)) {
            Write-Host "✗ Theme file not found: $themePath" -ForegroundColor Red
            exit 1
        }
        
        # Load and install
        . $themePath
        Install-FlowerOSTheme
        
        Write-Host "`n🎨 Testing theme..." -ForegroundColor Cyan
        Initialize-PSReadLine
        Initialize-VSCodeIntegration
        
        Write-Host "`n✨ Installation complete!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "  1. Restart PowerShell or run: " -NoNewline
        Write-Host ". `$PROFILE" -ForegroundColor Cyan
        Write-Host "  2. Open VS Code terminal to see the theme" -ForegroundColor Gray
        Write-Host ""
    }
    
    'uninstall' {
        Write-Host "Removing FlowerOS theme...`n" -ForegroundColor Yellow
        
        . $themePath
        Uninstall-FlowerOSTheme
        
        Write-Host "✨ Uninstallation complete!`n" -ForegroundColor Green
    }
    
    'status' {
        if (Test-Path $PROFILE) {
            $content = Get-Content $PROFILE -Raw
            if ($content -match "FlowerOS Theme") {
                Write-Host "✓ FlowerOS theme is installed" -ForegroundColor Green
                Write-Host "  Profile: $PROFILE" -ForegroundColor Gray
                
                # Check version
                if ($content -match "FlowerOS Theme v([\d\.]+)") {
                    Write-Host "  Version: $($matches[1])" -ForegroundColor Gray
                }
            } else {
                Write-Host "✗ FlowerOS theme is not installed" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ No PowerShell profile found" -ForegroundColor Red
        }
        Write-Host ""
    }
}
