# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Complete Build Script
#  Compiles ALL components: Tier 4, Network, GPU Detection, Core Utils
# ═══════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                                                                           ║" -ForegroundColor Magenta
Write-Host "║                  FlowerOS Complete Build System                           ║" -ForegroundColor Magenta
Write-Host "║                  Building ALL Components                                  ║" -ForegroundColor Magenta
Write-Host "║                                                                           ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$ROOT = $PSScriptRoot
$BuildSuccess = 0
$BuildFailed = 0

# ═══════════════════════════════════════════════════════════════════════════
#  Check Prerequisites
# ═══════════════════════════════════════════════════════════════════════════

Write-Host "🔍 Checking build prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check for gcc
$gccFound = $null -ne (Get-Command gcc -ErrorAction SilentlyContinue)
if ($gccFound) {
    $gccVersion = gcc --version | Select-Object -First 1
    Write-Host "  ✓ GCC found: $gccVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ GCC not found" -ForegroundColor Red
    Write-Host "    Install MinGW-w64 or MSYS2 for Windows builds" -ForegroundColor Yellow
}

# Check for g++
$gppFound = $null -ne (Get-Command g++ -ErrorAction SilentlyContinue)
if ($gppFound) {
    Write-Host "  ✓ G++ found" -ForegroundColor Green
} else {
    Write-Host "  ✗ G++ not found (needed for network)" -ForegroundColor Yellow
}

# Check for make
$makeFound = $null -ne (Get-Command make -ErrorAction SilentlyContinue)
if ($makeFound) {
    Write-Host "  ✓ Make found" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Make not found (will use direct gcc calls)" -ForegroundColor Yellow
}

Write-Host ""

if (-not $gccFound) {
    Write-Host "Cannot proceed without GCC. Install build tools first." -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  Build Tier 4: Windows Broker
# ═══════════════════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Building Tier 4: Windows Broker" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

Push-Location "$ROOT\tier4"

if (Test-Path "broker.exe") {
    Remove-Item "broker.exe" -Force
}

Write-Host "Compiling broker.c..." -ForegroundColor Cyan

& gcc -O2 -Wall -Wextra -std=c11 -DBROKER_STANDALONE `
    -o broker.exe `
    ..\src\tier4\broker.c `
    -ladvapi32 -lcrypt32

if ($LASTEXITCODE -eq 0 -and (Test-Path "broker.exe")) {
    Write-Host "✓ Tier 4 broker built successfully" -ForegroundColor Green
    Write-Host "  Binary: tier4\broker.exe" -ForegroundColor Gray
    $BuildSuccess++
} else {
    Write-Host "✗ Tier 4 broker build failed" -ForegroundColor Red
    $BuildFailed++
}

Pop-Location
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
#  Build Core Utilities (if not already built)
# ═══════════════════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Building Core Utilities" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

$UtilSources = @(
    "random.c",
    "animate.c",
    "banner.c",
    "fortune.c",
    "colortest.c"
)

foreach ($util in $UtilSources) {
    $binary = [System.IO.Path]::GetFileNameWithoutExtension($util)
    $binaryExe = "$binary.exe"
    
    if (Test-Path "$ROOT\src\utils\$util") {
        Write-Host "Compiling $util..." -ForegroundColor Cyan
        
        & gcc -O2 -std=c11 -Wall -Wextra `
            -o "$ROOT\$binaryExe" `
            "$ROOT\src\utils\$util"
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path "$ROOT\$binaryExe")) {
            Write-Host "  ✓ $binary built" -ForegroundColor Green
            $BuildSuccess++
        } else {
            Write-Host "  ✗ $binary failed" -ForegroundColor Red
            $BuildFailed++
        }
    }
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
#  Build GPU Detection Utility
# ═══════════════════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Building GPU Detection Utility" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

Write-Host "Compiling gpu-detect.c..." -ForegroundColor Cyan

& gcc -O2 -std=c11 -Wall -Wextra `
    -o "$ROOT\gpu-detect.exe" `
    "$ROOT\src\utils\gpu-detect.c" `
    -lsetupapi

if ($LASTEXITCODE -eq 0 -and (Test-Path "$ROOT\gpu-detect.exe")) {
    Write-Host "✓ GPU detection utility built" -ForegroundColor Green
    Write-Host "  Binary: gpu-detect.exe" -ForegroundColor Gray
    Write-Host "  WARNING: This is a STUB - detects hardware but doesn't accelerate" -ForegroundColor Yellow
    $BuildSuccess++
} else {
    Write-Host "✗ GPU detection build failed" -ForegroundColor Red
    $BuildFailed++
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
#  Build Network Components (if G++ available)
# ═══════════════════════════════════════════════════════════════════════════

if ($gppFound) {
    Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  Building Network Components (EXPERIMENTAL)" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "WARNING: Network routing is EXPERIMENTAL!" -ForegroundColor Red
    Write-Host ""
    
    Push-Location "$ROOT\src\network"
    
    # Create build directory
    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }
    
    # Compile Rooting.cpp
    Write-Host "Compiling Rooting.cpp..." -ForegroundColor Cyan
    
    & g++ -std=c++17 -Wall -Wextra -O2 -c Rooting.cpp -o build\Rooting.o
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Network routing compiled" -ForegroundColor Green
        
        # Try to build executables
        Write-Host "Building network binaries..." -ForegroundColor Cyan
        
        # Note: The .cpp files for executables may not have main functions
        # This is expected - they're referenced but not fully implemented
        Write-Host "  WARNING: Network executables need main function implementations" -ForegroundColor Yellow
        Write-Host "  Library object built: build\Rooting.o" -ForegroundColor Gray
        
        $BuildSuccess++
    } else {
        Write-Host "  ✗ Network build failed" -ForegroundColor Red
        $BuildFailed++
    }
    
    Pop-Location
    Write-Host ""
} else {
    Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  Skipping Network Components (G++ not found)" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Build Summary
# ═══════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "║                          Build Summary                                    ║" -ForegroundColor Cyan
Write-Host "║                                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Successful: $BuildSuccess" -ForegroundColor Green
Write-Host "  Failed:     $BuildFailed" -ForegroundColor $(if ($BuildFailed -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($BuildSuccess -gt 0) {
    Write-Host "Built Components:" -ForegroundColor Cyan
    
    if (Test-Path "$ROOT\tier4\broker.exe") {
        Write-Host "  ✓ Tier 4 Broker:     tier4\broker.exe" -ForegroundColor Green
    }
    
    if (Test-Path "$ROOT\gpu-detect.exe") {
        Write-Host "  ✓ GPU Detection:     gpu-detect.exe" -ForegroundColor Green
    }
    
    foreach ($util in @("random", "animate", "banner", "fortune", "colortest")) {
        if (Test-Path "$ROOT\$util.exe") {
            Write-Host "  ✓ $($util.PadRight(16)): $util.exe" -ForegroundColor Green
        }
    }
    
    if (Test-Path "$ROOT\src\network\build\Rooting.o") {
        Write-Host "  ✓ Network (partial): src\network\build\Rooting.o" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($BuildFailed -eq 0) {
    Write-Host "🌸 Build completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test Tier 4 broker: cd tier4 && .\broker.exe" -ForegroundColor White
    Write-Host "  2. Test GPU detection: .\gpu-detect.exe status" -ForegroundColor White
    Write-Host "  3. Install FlowerOS: bash install.sh" -ForegroundColor White
} else {
    Write-Host "WARNING: Build completed with errors" -ForegroundColor Yellow
    Write-Host "Check error messages above" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Every task executed beautifully... on CPU! 🌸" -ForegroundColor Magenta
Write-Host "  (GPU acceleration coming soon)" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
