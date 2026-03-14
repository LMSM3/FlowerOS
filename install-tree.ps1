#!/usr/bin/env pwsh
# FlowerOS System Installer (PowerShell)
# Installs tree.sh as system-wide command

$BinDir = "$env:USERPROFILE\.local\bin"
$ScriptName = "floweros-tree"
$ScriptPath = "$BinDir\$ScriptName.sh"

# Create bin directory
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

# Copy script
Copy-Item tree.sh $ScriptPath -Force

# Create wrapper batch file
$WrapperPath = "$BinDir\$ScriptName.bat"
@"
@echo off
wsl bash "$ScriptPath"
"@ | Set-Content $WrapperPath -Encoding ASCII

# Add to PATH if not already there
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
    $env:PATH += ";$BinDir"
}

Write-Host "✓ Installed to $BinDir" -ForegroundColor Green
Write-Host "  Run: $ScriptName" -ForegroundColor Cyan
Write-Host "  (Restart terminal to use)" -ForegroundColor Yellow
