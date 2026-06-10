# compile-check.ps1 — FlowerOS Beta 2.8.3-2.9.1 Compilation Diagnostic
# Usage: .\compile-check.ps1 [-Version <x.y.z>] [-Verbose]
# Returns exit code 0 on success, 1 on failure.

param(
    [string]$Version = "2.9.1",
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"
Set-StrictMode -Off

# ── Colour helpers ────────────────────────────────────────────────────────
function ok   { param($m) Write-Host "[" -NoNewline; Write-Host "✓" -ForegroundColor Green   -NoNewline; Write-Host "] $m" }
function err  { param($m) Write-Host "[" -NoNewline; Write-Host "✗" -ForegroundColor Red     -NoNewline; Write-Host "] $m" }
function info { param($m) Write-Host "[" -NoNewline; Write-Host "✿" -ForegroundColor Cyan    -NoNewline; Write-Host "] $m" }
function warn { param($m) Write-Host "[" -NoNewline; Write-Host "⚠" -ForegroundColor Yellow  -NoNewline; Write-Host "] $m" }
function hdr  { param($m) Write-Host $m -ForegroundColor Magenta }
function dim  { param($m) Write-Host $m -ForegroundColor DarkGray }

# ── Banner ────────────────────────────────────────────────────────────────
Write-Host ""
hdr  "╔══════════════════════════════════════════════════════════════╗"
hdr  "║  FlowerOS  •  Compile Check  •  Beta $Version                   ║"
hdr  "╚══════════════════════════════════════════════════════════════╝"
Write-Host ""

$REPO = $PSScriptRoot
$SRC  = Join-Path $REPO "src"

# ═════════════════════════════════════════════════════════════════════════
#  PHASE 1 — Compiler discovery
# ═════════════════════════════════════════════════════════════════════════
info "Phase 1 — Compiler Discovery"
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$compilers = [ordered]@{}

# 1a. gcc (MSYS2 / MinGW)
$gccCmd = Get-Command gcc -ErrorAction SilentlyContinue
if ($gccCmd) {
    $gccVer = (& gcc --version 2>&1 | Select-Object -First 1) -replace '\r|\n',''
    $compilers["gcc"] = $gccVer
    ok "gcc           $gccVer"
} else {
    err "gcc           NOT FOUND"
    dim "              Install via: MSYS2 · MinGW-w64 · WSL"
}

# 1b. clang
$clangCmd = Get-Command clang -ErrorAction SilentlyContinue
if ($clangCmd) {
    $clangVer = (& clang --version 2>&1 | Select-Object -First 1) -replace '\r|\n',''
    $compilers["clang"] = $clangVer
    ok "clang         $clangVer"
} else {
    err "clang         NOT FOUND"
}

# 1c. MSVC cl.exe
$clCmd = Get-Command cl -ErrorAction SilentlyContinue
if ($clCmd) {
    $clVer = (& cl /? 2>&1 | Select-Object -First 1) -replace '\r|\n',''
    $compilers["cl"] = $clVer
    warn "MSVC cl.exe   FOUND (POSIX sources unsupported)"
    dim "              Sources require unistd.h, dirent.h, sys/wait.h"
    dim "              → compile via gcc/clang or WSL"
} else {
    err "MSVC cl.exe   NOT FOUND"
}

# 1d. WSL
$wslAvail = $false
try {
    $wslOut = & wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) { $wslAvail = $true }
} catch {}
if ($wslAvail) {
    ok "WSL           Available"
    $compilers["wsl"] = "wsl"
} else {
    err "WSL           NOT INSTALLED  (wsl --install to enable)"
}

Write-Host ""

# ═════════════════════════════════════════════════════════════════════════
#  PHASE 2 — Source inventory
# ═════════════════════════════════════════════════════════════════════════
info "Phase 2 — Source File Inventory"
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$sources = @(
    # Path (relative to $SRC)          Display name              Requires
    [pscustomobject]@{ rel="utils\random.c";        name="random";        posix=$true;  notes="dirent.h, getline, /dev/urandom" },
    [pscustomobject]@{ rel="utils\animate.c";       name="animate";       posix=$true;  notes="unistd.h, sleep" },
    [pscustomobject]@{ rel="utils\banner.c";        name="banner";        posix=$false; notes="stdio.h only" },
    [pscustomobject]@{ rel="utils\fortune.c";       name="fortune";       posix=$false; notes="stdio.h, time.h" },
    [pscustomobject]@{ rel="utils\colortest.c";     name="colortest";     posix=$true;  notes="unistd.h (isatty)" },
    [pscustomobject]@{ rel="utils\visual.c";        name="visual";        posix=$false; notes="stdio.h only" },
    [pscustomobject]@{ rel="utils\flower_guy.c";    name="flower-guy";    posix=$false; notes="stdio.h only" },
    [pscustomobject]@{ rel="utils\flower_walk.c";   name="flower-walk";   posix=$true;  notes="unistd.h, usleep" },
    [pscustomobject]@{ rel="utils\gpu-detect.c";    name="gpu-detect";    posix=$true;  notes="sys/utsname.h" },
    [pscustomobject]@{ rel="publish\fp.c";          name="fp";            posix=$true;  notes="unistd.h, sys/wait.h" },
    [pscustomobject]@{ rel="runner\fos_runner.c";   name="flower-run";    posix=$true;  notes="libgen.h, sys/stat.h, sys/wait.h" },
    [pscustomobject]@{ rel="games\chess_engine.c";  name="flower-chess";  posix=$false; notes="stdio.h, stdlib.h" },
    [pscustomobject]@{ rel="games\colony_engine.c"; name="flower-colony"; posix=$false; notes="stdio.h, stdlib.h" },
    [pscustomobject]@{ rel="games\td_engine.c";     name="flower-td";     posix=$false; notes="stdio.h, stdlib.h" },
    [pscustomobject]@{ rel="games\play.c";          name="flower-play";   posix=$false; notes="stdio.h, stdlib.h" },
    [pscustomobject]@{ rel="tools\flower_todo.c";   name="flower-todo";   posix=$false; notes="stdio.h, stdlib.h" },
    [pscustomobject]@{ rel="motd\miniloop.c";       name="miniloop";      posix=$true;  notes="unistd.h" },
    [pscustomobject]@{ rel="motd\mini_win32.c";     name="mini_win32";    posix=$false; notes="windows.h" },
    [pscustomobject]@{ rel="motd\show_motd.c";      name="show_motd";     posix=$true;  notes="unistd.h" },
    [pscustomobject]@{ rel="tier4\broker.c";        name="broker";        posix=$false; notes="windows.h (named pipe IPC)" },
    [pscustomobject]@{ rel="install\install.c";     name="install";       posix=$true;  notes="unistd.h, dirent.h" },
    [pscustomobject]@{ rel="install\uninstall.c";   name="uninstall";     posix=$true;  notes="unistd.h, dirent.h" },
    [pscustomobject]@{ rel="kernel\flower_kernel.c";name="flower-kernel"; posix=$true;  notes="sys/stat.h, sys/wait.h" },
    [pscustomobject]@{ rel="config\flower_config.c";name="flower-config"; posix=$true;  notes="unistd.h" }
)

$found   = 0
$missing = 0
$posixCount = 0
$portableCount = 0

foreach ($s in $sources) {
    $fullPath = Join-Path $SRC $s.rel
    $exists   = Test-Path $fullPath
    if ($exists) {
        $found++
        if ($s.posix) {
            $posixCount++
            warn "  $($s.name.PadRight(16)) POSIX   ($($s.notes))"
        } else {
            $portableCount++
            ok   "  $($s.name.PadRight(16)) portable ($($s.notes))"
        }
    } else {
        $missing++
        dim  "  $($s.name.PadRight(16)) missing  $($s.rel)"
    }
}

Write-Host ""
dim "  Sources found:    $found"
dim "  Sources missing:  $missing"
dim "  POSIX-only:       $posixCount  (need gcc/clang or WSL)"
dim "  Portable/Windows: $portableCount"
Write-Host ""

# ═════════════════════════════════════════════════════════════════════════
#  PHASE 3 — Compile feasibility verdict
# ═════════════════════════════════════════════════════════════════════════
info "Phase 3 — Compile Feasibility for Beta $Version"
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$canBuildFull     = $compilers.Contains("gcc") -or $compilers.Contains("clang") -or $wslAvail
$canBuildPartial  = ($compilers.Contains("cl") -and $portableCount -gt 0)

if ($canBuildFull) {
    $compiler = if ($compilers.Contains("gcc")) { "gcc" } elseif ($compilers.Contains("clang")) { "clang" } else { "WSL gcc" }
    ok "Full build POSSIBLE via $compiler"
    info "  Run:  bash build.sh          (Linux / WSL)"
    info "  Run:  .\build_native.ps1     (Windows with MSYS2 gcc)"
} elseif ($canBuildPartial) {
    warn "Partial build possible via MSVC cl.exe"
    warn "  Only $portableCount portable source(s) can compile without POSIX headers"
    warn "  POSIX sources require gcc, clang, or WSL"
    info "  Install gcc via MSYS2: https://www.msys2.org/"
    info "  Or enable WSL:        wsl --install"
} else {
    err "Compilation is NOT currently possible on this machine"
    err "  Missing: gcc, clang, and WSL"
    Write-Host ""
    Write-Host "  To fix — choose one:" -ForegroundColor Yellow
    Write-Host "    Option A  MSYS2 (recommended for Windows natives)"     -ForegroundColor Cyan
    Write-Host "              https://www.msys2.org/"
    Write-Host "              pacman -S mingw-w64-ucrt-x86_64-gcc"
    Write-Host ""
    Write-Host "    Option B  WSL (full Linux build environment)"           -ForegroundColor Cyan
    Write-Host "              wsl --install"
    Write-Host "              sudo apt install build-essential"
    Write-Host ""
    Write-Host "    Option C  MinGW-w64 standalone"                        -ForegroundColor Cyan
    Write-Host "              https://www.mingw-w64.org/"
    Write-Host ""
}

# ═════════════════════════════════════════════════════════════════════════
#  PHASE 4 — Live compile attempt (only if gcc available)
# ═════════════════════════════════════════════════════════════════════════
if ($compilers.Contains("gcc")) {
    Write-Host ""
    info "Phase 4 — Live Compile Attempt"
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $testTargets = @(
        [pscustomobject]@{ file = "src\utils\banner.c";  out = "banner";  extra = @() },
        [pscustomobject]@{ file = "src\utils\fortune.c"; out = "fortune"; extra = @() },
        [pscustomobject]@{ file = "src\utils\visual.c";  out = "visual";  extra = @() }
    )

    $pass = 0; $fail = 0
    $buildDir = Join-Path $REPO "bin"
    if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

    foreach ($t in $testTargets) {
        $srcFile = Join-Path $REPO $t.file
        $outExe  = Join-Path $buildDir "$($t.out).exe"
        if (-not (Test-Path $srcFile)) { dim "  $($t.out.PadRight(14)) skipped (source not found)"; continue }

        $args = @("-O2", "-std=c11", "-Wall", "-o", $outExe, $srcFile) + $t.extra
        $result = & gcc @args 2>&1
        if ($LASTEXITCODE -eq 0) {
            ok "  $($t.out.PadRight(14)) compiled OK  →  bin\$($t.out).exe"
            $pass++
        } else {
            err "  $($t.out.PadRight(14)) FAILED"
            if ($Verbose) { $result | ForEach-Object { dim "    $_" } }
            $fail++
        }
    }

    Write-Host ""
    if ($fail -eq 0) {
        ok "Live compile: $pass/$($pass+$fail) targets passed"
    } else {
        warn "Live compile: $pass passed, $fail failed"
    }
}

# ═════════════════════════════════════════════════════════════════════════
#  PHASE 5 — Beta 2.8.3-2.9.1 version status summary
# ═════════════════════════════════════════════════════════════════════════
Write-Host ""
info "Phase 5 — Beta Version Status  (2.8.3 → 2.9.1 series)"
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$betas = @(
    [pscustomobject]@{ ver="2.8.3"; name="Dandelion RC1";   status="planned"; sources=$found; posix=$posixCount },
    [pscustomobject]@{ ver="2.8.4"; name="Dandelion RC2";   status="planned"; sources=$found; posix=$posixCount },
    [pscustomobject]@{ ver="2.8.5"; name="Dandelion RC3";   status="planned"; sources=$found; posix=$posixCount },
    [pscustomobject]@{ ver="2.9.0"; name="Dandelion Beta1"; status="planned"; sources=$found; posix=$posixCount },
    [pscustomobject]@{ ver="2.9.1"; name="Dandelion Beta2"; status="planned"; sources=$found; posix=$posixCount }
)

foreach ($b in $betas) {
    $marker = if ($b.ver -eq $Version) { "◄ selected" } else { "" }
    $color  = if ($b.ver -eq $Version) { "Cyan" } else { "Gray" }
    Write-Host ("  v{0}  {1,-20}  {2} sources  ({3} POSIX)  {4}" -f `
        $b.ver, $b.name, $b.sources, $b.posix, $marker) -ForegroundColor $color
}

Write-Host ""
dim "  All betas share the same source tree (Dandelion series)."
dim "  Use version-selector.ps1 to pick and configure a target version."

# ═════════════════════════════════════════════════════════════════════════
#  Summary
# ═════════════════════════════════════════════════════════════════════════
Write-Host ""
hdr "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ($canBuildFull) {
    ok "RESULT: Ready to compile beta $Version  →  run version-selector.ps1"
    Write-Host ""
    exit 0
} elseif ($canBuildPartial) {
    warn "RESULT: Partial compile only (install gcc/WSL for full build)"
    Write-Host ""
    exit 1
} else {
    err "RESULT: Cannot compile — install gcc (MSYS2) or WSL first"
    Write-Host ""
    exit 1
}
