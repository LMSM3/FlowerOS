#!/usr/bin/env pwsh
# FlowerOS Image-to-Terminal Wrapper (PowerShell)
# Easy image conversion for Windows users

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ImagePath,
    
    [Parameter(Position=1)]
    [int]$Columns = 120,
    
    [Parameter()]
    [ValidateSet('pastel', 'hash')]
    [string]$Mode = 'pastel',
    
    [Parameter()]
    [ValidateRange(0, 1)]
    [double]$PastelStrength = 0.55,
    
    [Parameter()]
    [ValidateSet('half', 'full')]
    [string]$BlockMode = 'half',
    
    [Parameter()]
    [switch]$Save
)

$ErrorActionPreference = "Stop"

# Check if file exists
if (-not (Test-Path $ImagePath)) {
    Write-Host "Error: File not found: $ImagePath" -ForegroundColor Red
    exit 1
}

$ImagePath = Resolve-Path $ImagePath

# Check for Python
if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "Error: Python not found" -ForegroundColor Red
        Write-Host "Install from: https://www.python.org/downloads/" -ForegroundColor Yellow
        exit 1
    }
    $pythonCmd = "python"
} else {
    $pythonCmd = "python3"
}

# Check for Pillow
$pillowCheck = & $pythonCmd -c "import PIL" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing Pillow..." -ForegroundColor Yellow
    & $pythonCmd -m pip install --user pillow
}

$toolsDir = $PSScriptRoot

if ($Mode -eq 'hash') {
    # Hash-based pastel mode
    $script = Join-Path $toolsDir "img2term-hash.py"
    
    if ($Save) {
        $output = & $pythonCmd $script $ImagePath $Columns
        $outputFile = [System.IO.Path]::ChangeExtension($ImagePath, ".ascii")
        $output | Set-Content $outputFile -Encoding UTF8
        Write-Host "`nSaved to: $outputFile" -ForegroundColor Green
    } else {
        & $pythonCmd $script $ImagePath $Columns
    }
} else {
    # Standard pastel mode
    $script = Join-Path $toolsDir "img2term.sh"
    
    if ($Save) {
        $output = bash $script $ImagePath $Columns $PastelStrength $BlockMode
        $outputFile = [System.IO.Path]::ChangeExtension($ImagePath, ".ascii")
        $output | Set-Content $outputFile -Encoding UTF8
        Write-Host "`nSaved to: $outputFile" -ForegroundColor Green
    } else {
        bash $script $ImagePath $Columns $PastelStrength $BlockMode
    }
}
