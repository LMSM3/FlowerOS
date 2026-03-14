#!/usr/bin/env pwsh
# FlowerOS Banner Library - Bulk Migration Script
# Converts top priority files to use lib/banners.sh

$filesToConvert = @(
    "demo-bare-metal-hpc.sh",
    "demo-network-routing.sh",
    "demo-node-monitor.sh",
    "demo-terminal-network.sh",
    "buddy-windows.sh",
    "relay-auto-test.sh",
    "test-linux-network.sh",
    "test-internet-relay.sh",
    "test-network-deployment.sh"
)

Write-Host "`n🔧 FlowerOS Banner Library - Bulk Migration`n" -ForegroundColor Cyan

foreach ($file in $filesToConvert) {
    if (-not (Test-Path $file)) {
        Write-Host "  ⚠ Skipping $file (not found)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  📝 Processing: $file" -ForegroundColor White
    
    $content = Get-Content $file -Raw
    $originalBoxCount = ([regex]::Matches($content, '[╔╗╚╝]')).Count
    
    # Check if already converted
    if ($content -match 'source.*lib/banners\.sh') {
        Write-Host "    ✓ Already uses banner library" -ForegroundColor Green
        continue
    }
    
    # Step 1: Add banner library source after shebang/header comments
    if ($content -notmatch 'source.*lib/banners\.sh') {
        $lines = $content -split "`n"
        $insertIndex = 0
        
        # Find first non-comment/non-empty line after header
        for ($i = 0; $i < $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -and $line -notmatch '^#' -and $line -ne '') {
                $insertIndex = $i
                break
            }
        }
        
        $sourceBlock = @"

SCRIPT_DIR="`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)"
source "`${SCRIPT_DIR}/lib/banners.sh"
"@
        
        $lines = @($lines[0..($insertIndex-1)]) + $sourceBlock + @($lines[$insertIndex..($lines.Count-1)])
        $content = $lines -join "`n"
    }
    
    # Step 2: Remove manual color definitions
    $content = $content -replace "RED=.*\\033\[31m.*`n", ""
    $content = $content -replace "GREEN=.*\\033\[32m.*`n", ""
    $content = $content -replace "YELLOW=.*\\033\[33m.*`n", ""
    $content = $content -replace "BLUE=.*\\033\[34m.*`n", ""
    $content = $content -replace "MAGENTA=.*\\033\[35m.*`n", ""
    $content = $content -replace "CYAN=.*\\033\[36m.*`n", ""
    $content = $content -replace "WHITE=.*\\033\[37m.*`n", ""
    $content = $content -replace "RESET=.*\\033\[0m.*`n", ""
    
    # Step 3: Replace color variable references
    $content = $content -replace '\$\{RED\}', '${_FOS_RED}'
    $content = $content -replace '\$\{GREEN\}', '${_FOS_GREEN}'
    $content = $content -replace '\$\{YELLOW\}', '${_FOS_YELLOW}'
    $content = $content -replace '\$\{BLUE\}', '${_FOS_BLUE}'
    $content = $content -replace '\$\{MAGENTA\}', '${_FOS_MAGENTA}'
    $content = $content -replace '\$\{CYAN\}', '${_FOS_CYAN}'
    $content = $content -replace '\$\{WHITE\}', '${_FOS_WHITE}'
    $content = $content -replace '\$\{RESET\}', '${_FOS_RESET}'
    
    # Step 4: Replace common status messages
    $content = $content -replace 'echo -e "\$\{(_FOS_)?GREEN\}✓([^$"]+)\$\{(_FOS_)?RESET\}"', 'fos_status_ok "$2"'
    $content = $content -replace 'echo -e "\$\{(_FOS_)?RED\}✗([^$"]+)\$\{(_FOS_)?RESET\}"', 'fos_status_fail "$2"'
    $content = $content -replace 'echo -e "\$\{(_FOS_)?YELLOW\}⚠([^$"]+)\$\{(_FOS_)?RESET\}"', 'fos_status_warn "$2"'
    
    # Save with Unix line endings
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($false))
    
    $newBoxCount = ([regex]::Matches($content, '[╔╗╚╝]')).Count
    Write-Host "    ✓ Modified (boxes: $originalBoxCount → $newBoxCount)" -ForegroundColor Green
    
    if ($newBoxCount -gt 0) {
        Write-Host "    ⚠ $newBoxCount boxes remain (manual conversion needed)" -ForegroundColor Yellow
    }
}

Write-Host "`n✓ Bulk migration complete!`n" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review modified files" -ForegroundColor White
Write-Host "  2. Manually convert remaining box banners to fos_banner_* calls" -ForegroundColor White
Write-Host "  3. Test each script" -ForegroundColor White
Write-Host ""
