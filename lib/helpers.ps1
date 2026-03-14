# lib/helpers.ps1 - Shared PowerShell helpers for FlowerOS
# Import: . "$PSScriptRoot\lib\helpers.ps1"

function Write-OK { 
    param($msg) 
    Write-Host "[" -NoNewline
    Write-Host "✓" -ForegroundColor Green -NoNewline
    Write-Host "] $msg" 
}

function Write-Err { 
    param($msg) 
    Write-Host "[" -NoNewline
    Write-Host "✗" -ForegroundColor Red -NoNewline
    Write-Host "] $msg" 
}

function Write-Info { 
    param($msg) 
    Write-Host "[" -NoNewline
    Write-Host "✿" -ForegroundColor Cyan -NoNewline
    Write-Host "] $msg" 
}

function Write-Warn { 
    param($msg) 
    Write-Host "[" -NoNewline
    Write-Host "⚠" -ForegroundColor Yellow -NoNewline
    Write-Host "] $msg" 
}

function Get-GccPath {
    try {
        return Get-Command gcc -ErrorAction SilentlyContinue
    } catch {
        return $null
    }
}

function Test-GccAvailable {
    $gccPath = Get-GccPath
    if (-not $gccPath) {
        Write-Err "gcc not found!"
        Write-Host ""
        Write-Host "Install options:" -ForegroundColor Yellow
        Write-Host "  1. MSYS2:   https://www.msys2.org/"
        Write-Host "  2. MinGW:   https://www.mingw-w64.org/"
        Write-Host "  3. WSL:     wsl --install"
        Write-Host ""
        return $false
    }
    
    $gccVersion = & gcc --version 2>&1 | Select-Object -First 1
    Write-OK "Found gcc: $gccVersion"
    return $true
}
