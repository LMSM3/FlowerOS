# build_native.ps1 - Native Windows PowerShell build script
# Usage: .\build_native.ps1

$ErrorActionPreference = "Stop"

# Load shared helpers
. "$PSScriptRoot\lib\helpers.ps1"

Write-Host ""
Write-Info "FlowerOS Advanced Build System (Native Windows)"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

# Check for gcc (MSYS2, MinGW, or WSL)
$gccPath = $null
try {
    $gccPath = Get-Command gcc -ErrorAction SilentlyContinue
} catch {}

if (-not $gccPath) {
    Write-Err "gcc not found!"
    Write-Host ""
    Write-Host "Install options:" -ForegroundColor Yellow
    Write-Host "  1. MSYS2:   https://www.msys2.org/"
    Write-Host "  2. MinGW:   https://www.mingw-w64.org/"
    Write-Host "  3. WSL:     wsl --install"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

$gccVersion = & gcc --version 2>&1 | Select-Object -First 1
Write-OK "Found gcc: $gccVersion"
Write-Host ""

# Build flags
$CFLAGS = "-O2 -std=c11 -Wall -Wextra"

# Feature detection
$features = @()
if (Get-Command tput -ErrorAction SilentlyContinue) {
    $features += "-DHAS_TERMCAP"
    Write-OK "Feature: Terminal capabilities"
}
if (Test-Path "/dev/urandom" -ErrorAction SilentlyContinue) {
    $features += "-DHAS_URANDOM"
    Write-OK "Feature: /dev/urandom"
}

$featureFlags = $features -join " "
if ($features.Count -eq 0) {
    Write-Host ""
}

Write-Info "Compiling C subsystems..."
Write-Host ""

$built = 0
$failed = 0

# Build each subsystem
$subsystems = @(
    @{name="random"; desc="Core line picker"; file="random.c"},
    @{name="animate"; desc="Animation engine"; file="animate.c"},
    @{name="banner"; desc="Banner generator"; file="banner.c"},
    @{name="fortune"; desc="Wisdom database"; file="fortune.c"},
    @{name="colortest"; desc="Terminal diagnostics"; file="colortest.c"}
)

$i = 1
foreach ($sub in $subsystems) {
    Write-Info "[$i/$($subsystems.Count)] Building $($sub.name) ($($sub.desc))..."
    
    if (-not (Test-Path $sub.file)) {
        Write-Warn "$($sub.file) not found (skipping)"
        Write-Host ""
        $i++
        continue
    }
    
    try {
        $output = & gcc $CFLAGS.Split() $featureFlags.Split() -o $sub.name $sub.file 2>&1
        if ($LASTEXITCODE -eq 0) {
            $size = (Get-Item $sub.name -ErrorAction SilentlyContinue).Length
            $sizeKB = [math]::Round($size / 1KB, 1)
            Write-OK "Built: $($sub.name) ($sizeKB KB)"
            $built++
        } else {
            Write-Err "Failed to compile $($sub.file)"
            Write-Host $output -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Err "Failed to compile $($sub.file): $_"
        $failed++
    }
    
    Write-Host ""
    $i++
}

# Test binaries
if ($built -gt 0) {
    Write-Info "Testing binaries..."
    Write-Host ""
    
    if (Test-Path "random.exe") {
        try {
            $testOutput = & .\random.exe . 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -and $testOutput) {
                $preview = $testOutput.Substring(0, [Math]::Min(40, $testOutput.Length)).Trim()
                Write-OK "random: $preview..."
            } else {
                Write-Warn "random: No output (needs .ascii/.txt files)"
            }
        } catch {
            Write-Warn "random: Test failed"
        }
    }
    
    if (Test-Path "animate.exe") {
        Write-OK "animate: Ready (use: .\animate.exe file.anim)"
    }
    
    if (Test-Path "banner.exe") {
        Write-OK "banner: Ready (use: .\banner.exe 'Text')"
    }
    
    if (Test-Path "fortune.exe") {
        Write-OK "fortune: Ready (use: .\fortune.exe [category])"
    }
    
    if (Test-Path "colortest.exe") {
        Write-OK "colortest: Ready (use: .\colortest.exe)"
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ($failed -eq 0) {
    Write-OK "Build complete! $built binaries ready"
} else {
    Write-Warn "Build completed with $failed failures, $built successes"
}
Write-Host ""
