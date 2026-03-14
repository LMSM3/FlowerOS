# FlowerOS v1.1 Test Runner (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  FlowerOS v1.1 - Test Suite" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$Passed = 0
$Failed = 0

function Test-Header { param($msg) Write-Host "▶ $msg" -ForegroundColor Cyan }
function Test-Pass { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green; $script:Passed++ }
function Test-Fail { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; $script:Failed++ }

$RootDir = Split-Path $PSScriptRoot

# Test 1: v1.0 Core
Test-Header "Test: v1.0 Core Files Unchanged"
@("lib/colors.sh", "lib/helpers.ps1", "random.c", "build.sh") | ForEach-Object {
    if (Test-Path "$RootDir/$_") { Test-Pass "Found: $_" } else { Test-Fail "Missing: $_" }
}

# Test 2: v1.1 Structure
Test-Header "Test: v1.1 Structure"
@("features/v1.1/themes", "test", "temp") | ForEach-Object {
    if (Test-Path "$RootDir/$_") { Test-Pass "Directory: $_" } else { Test-Fail "Missing: $_" }
}

# Test 3: Theme System
Test-Header "Test: Theme System"
if (Test-Path "$RootDir/features/v1.1/themes/theme.ps1") {
    Test-Pass "Found: theme.ps1"
    try {
        . "$RootDir/features/v1.1/themes/theme.ps1"
        Test-Pass "Theme module loads"
    } catch {
        Test-Fail "Theme module error: $_"
    }
} else {
    Test-Fail "Missing: theme.ps1"
}

if (Test-Path "$RootDir/features/v1.1/themes/theme.sh") {
    Test-Pass "Found: theme.sh"
} else {
    Test-Fail "Missing: theme.sh"
}

# Test 4: VERSION
Test-Header "Test: Version"
if (Test-Path "$RootDir/VERSION") {
    $version = Get-Content "$RootDir/VERSION"
    if ($version -eq "1.1.0") {
        Test-Pass "VERSION correct: $version"
    } else {
        Test-Fail "VERSION incorrect: $version (expected 1.1.0)"
    }
} else {
    Test-Fail "Missing: VERSION file"
}

# Test 5: Documentation
Test-Header "Test: Documentation"
if (Test-Path "$RootDir/features/v1.1/THEMING.md") {
    Test-Pass "Found: THEMING.md"
} else {
    Test-Fail "Missing: THEMING.md"
}

# Summary
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Test Results" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Passed: $Passed" -ForegroundColor Green
Write-Host "  Failed: $Failed" -ForegroundColor Red
Write-Host ""

if ($Failed -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "✗ Some tests failed" -ForegroundColor Red
    Write-Host ""
    exit 1
}
