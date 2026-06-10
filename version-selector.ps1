# version-selector.ps1 — FlowerOS Interactive Beta Version Selector
# Usage: .\version-selector.ps1
# Navigate with ↑ ↓ arrow keys, Enter to confirm, Q to quit.

$ErrorActionPreference = "SilentlyContinue"
Set-StrictMode -Off

# ── Console helpers ───────────────────────────────────────────────────────
function ok   { param($m) Write-Host " [" -NoNewline; Write-Host "✓" -ForegroundColor Green   -NoNewline; Write-Host "] $m" }
function err_ { param($m) Write-Host " [" -NoNewline; Write-Host "✗" -ForegroundColor Red     -NoNewline; Write-Host "] $m" }
function info { param($m) Write-Host " [" -NoNewline; Write-Host "✿" -ForegroundColor Cyan    -NoNewline; Write-Host "] $m" }
function warn { param($m) Write-Host " [" -NoNewline; Write-Host "⚠" -ForegroundColor Yellow  -NoNewline; Write-Host "] $m" }
function hdr  { param($m) Write-Host $m -ForegroundColor Magenta }
function dim  { param($m) Write-Host $m -ForegroundColor DarkGray }
function accent { param($m) Write-Host $m -ForegroundColor Cyan }

# ── Version registry (2.8.3 → 2.9.1 beta Dandelion series) ───────────────
$versions = @(
    [ordered]@{
        ver       = "2.8.3"
        codename  = "Dandelion RC1"
        date      = "2025-Q3"
        status    = "Release Candidate"
        statusCol = "Yellow"
        tier      = "5 (Linux/WSL active)"
        highlights= @(
            "Network routing layer stabilised (Rooter.hpp)"
            "Tier-4 Windows IPC broker compiled and tested"
            "flower-run auto-detects 16 languages"
            "Games suite: chess, colony, tower-defense finalized"
            "MOTD composable providers v2"
        )
        buildCmd  = "bash build.sh"
        buildWin  = ".\build_native.ps1"
        gcc       = $true
        notes     = "First RC — all v1.3.x experimental features promoted to RC."
    },
    [ordered]@{
        ver       = "2.8.4"
        codename  = "Dandelion RC2"
        date      = "2025-Q3"
        status    = "Release Candidate"
        statusCol = "Yellow"
        tier      = "5 + Tier-4 Windows"
        highlights= @(
            "Tier-4 state.json schema v2 (GPU flags, shell profiles)"
            "Named-pipe IPC bus hardened — multi-client support"
            "flower-kernel: parasitic attach on Debian / AlmaLinux"
            "fp (LaTeX workflow) — watch mode and deps auto-install"
            "Install engine: checksum verification for downloads"
        )
        buildCmd  = "bash build.sh"
        buildWin  = ".\build_native.ps1"
        gcc       = $true
        notes     = "Tier-4 Windows substrate promoted from scaffolded to functional."
    },
    [ordered]@{
        ver       = "2.8.5"
        codename  = "Dandelion RC3"
        date      = "2025-Q4"
        status    = "Release Candidate"
        statusCol = "Yellow"
        tier      = "2 + 4 + 5"
        highlights= @(
            "Tier-2 kernel wrapper: intercept-and-enhance on existing Linux"
            "flower-userdb: multi-user account model"
            "GPU batch dispatch (flower-run --gpu --hpc)"
            "Terminal network node discovery + relay"
            "Colortest: extended 256-color + Unicode flower diagnostics"
        )
        buildCmd  = "bash build.sh"
        buildWin  = ".\build_native.ps1"
        gcc       = $true
        notes     = "Tier-2 kernel moves from prototype to RC."
    },
    [ordered]@{
        ver       = "2.9.0"
        codename  = "Dandelion Beta 1"
        date      = "2026-Q1"
        status    = "Beta"
        statusCol = "Cyan"
        tier      = "1 → 5 full tier model"
        highlights= @(
            "Full tier model 1-5 — bare metal, parasitic, container, Windows, Linux"
            "Permanent system install hardened (immutable flags, multi-distro)"
            "flower-ai optional local inference subsystem scaffold"
            "Theming v3: palette inheritance, runtime hot-swap"
            "Unified install engine: acquire → verify → build → graft → bloom v2"
        )
        buildCmd  = "bash build.sh"
        buildWin  = ".\build_native.ps1"
        gcc       = $true
        notes     = "First integrated beta across all five tiers."
    },
    [ordered]@{
        ver       = "2.9.1"
        codename  = "Dandelion Beta 2"
        date      = "2026-Q1"
        status    = "Beta"
        statusCol = "Cyan"
        tier      = "1 → 5 full tier model"
        highlights= @(
            "Security hardening — Thorns defense subsystem active"
            "IPC bus: named-pipe + Unix socket bridge for mixed OS nodes"
            "flower-run: CUDA + OpenCL GPU dispatch fully integrated"
            "LaTeX fp: multi-file projects, bibliography, watch daemon"
            "Dandelion release tooling: version-selector + compile-check"
        )
        buildCmd  = "bash build.sh"
        buildWin  = ".\build_native.ps1"
        gcc       = $true
        notes     = "Security and integration hardening before 3.0 stable."
    }
)

# ── Compiler probe ────────────────────────────────────────────────────────
function Get-CompilerInfo {
    $info = [ordered]@{ gcc=$false; clang=$false; cl=$false; wsl=$false; label="none" }
    if (Get-Command gcc   -ErrorAction SilentlyContinue) { $info.gcc   = $true }
    if (Get-Command clang -ErrorAction SilentlyContinue) { $info.clang = $true }
    if (Get-Command cl    -ErrorAction SilentlyContinue) { $info.cl    = $true }
    try { $null = & wsl --status 2>&1; if ($LASTEXITCODE -eq 0) { $info.wsl = $true } } catch {}
    if     ($info.gcc)   { $info.label = "gcc" }
    elseif ($info.clang) { $info.label = "clang" }
    elseif ($info.wsl)   { $info.label = "WSL gcc" }
    elseif ($info.cl)    { $info.label = "MSVC (partial — POSIX unsupported)" }
    return $info
}

# ── Draw top banner ───────────────────────────────────────────────────────
function Show-Banner {
    Clear-Host
    hdr "╔══════════════════════════════════════════════════════════════════╗"
    hdr "║  ✿  FlowerOS  —  Interactive Version Selector                  ║"
    hdr "║      Beta series:  2.8.3  →  2.9.1   (Dandelion)               ║"
    hdr "╚══════════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

# ── Draw version list ─────────────────────────────────────────────────────
function Show-VersionList {
    param([int]$selected)
    Write-Host "  Use " -NoNewline
    Write-Host "↑ ↓" -ForegroundColor Yellow -NoNewline
    Write-Host " to navigate,  " -NoNewline
    Write-Host "Enter" -ForegroundColor Green -NoNewline
    Write-Host " to select,  " -NoNewline
    Write-Host "Q" -ForegroundColor Red -NoNewline
    Write-Host " to quit"
    Write-Host "  ─────────────────────────────────────────────────────────────"
    Write-Host ""

    for ($i = 0; $i -lt $versions.Count; $i++) {
        $v = $versions[$i]
        $isSelected = ($i -eq $selected)
        $prefix = if ($isSelected) { "  ►" } else { "   " }
        $vColor  = if ($isSelected) { "White" }  else { "Gray" }
        $scColor = $v.statusCol

        if ($isSelected) {
            Write-Host ("$prefix ") -NoNewline
            Write-Host ("v{0}" -f $v.ver) -ForegroundColor Cyan -NoNewline
            Write-Host ("  {0,-20}" -f $v.codename) -ForegroundColor White -NoNewline
            Write-Host ("[{0}]" -f $v.status) -ForegroundColor $scColor
        } else {
            Write-Host ("$prefix ") -NoNewline
            Write-Host ("v{0}" -f $v.ver) -ForegroundColor DarkCyan -NoNewline
            Write-Host ("  {0,-20}" -f $v.codename) -ForegroundColor Gray -NoNewline
            Write-Host ("[{0}]" -f $v.status) -ForegroundColor DarkYellow
        }
    }
    Write-Host ""
}

# ── Draw version detail panel ─────────────────────────────────────────────
function Show-Detail {
    param($v, $compiler)
    Write-Host "  ─────────────────────────────────────────────────────────────"
    Write-Host ("  Version   ") -NoNewline; accent $v.ver
    Write-Host ("  Codename  ") -NoNewline; Write-Host $v.codename -ForegroundColor Magenta
    Write-Host ("  Status    ") -NoNewline; Write-Host $v.status   -ForegroundColor $v.statusCol
    Write-Host ("  Target    ") -NoNewline; Write-Host $v.date     -ForegroundColor DarkCyan
    Write-Host ("  Tiers     ") -NoNewline; Write-Host $v.tier     -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Highlights:" -ForegroundColor Yellow
    foreach ($h in $v.highlights) {
        Write-Host "    • $h" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  Build:" -ForegroundColor Yellow
    Write-Host ("    Linux / WSL  :  {0}" -f $v.buildCmd)   -ForegroundColor DarkGreen
    Write-Host ("    Windows      :  {0}" -f $v.buildWin)   -ForegroundColor DarkCyan

    Write-Host ""
    Write-Host "  Compiler status:" -ForegroundColor Yellow
    if ($compiler.gcc -or $compiler.clang -or $compiler.wsl) {
        Write-Host ("    ✓  {0} detected — full build supported" -f $compiler.label) -ForegroundColor Green
    } elseif ($compiler.cl) {
        Write-Host "    ⚠  MSVC only — portable sources compile; POSIX sources need gcc/WSL" -ForegroundColor Yellow
    } else {
        Write-Host "    ✗  No compatible compiler found" -ForegroundColor Red
        Write-Host "       Install gcc (MSYS2: pacman -S mingw-w64-ucrt-x86_64-gcc)" -ForegroundColor DarkGray
        Write-Host "       Or enable WSL: wsl --install" -ForegroundColor DarkGray
    }

    Write-Host ""
    dim ("  Note: " + $v.notes)
    Write-Host "  ─────────────────────────────────────────────────────────────"
    Write-Host ""
}

# ── Build action ──────────────────────────────────────────────────────────
function Invoke-Build {
    param($v, $compiler)

    Show-Banner
    hdr ("  ✿  Building FlowerOS v{0}  —  {1}" -f $v.ver, $v.codename)
    Write-Host ""

    if ($compiler.gcc -or $compiler.clang) {
        ok "Compiler: $($compiler.label)"
        Write-Host ""
        info "Running compile check first..."
        Write-Host ""
        & "$PSScriptRoot\compile-check.ps1" -Version $v.ver
        Write-Host ""

        $choice = Read-Host "  Proceed with full build? [Y/n]"
        if ($choice -match '^[Nn]') {
            info "Build cancelled."
        } else {
            if (Test-Path (Join-Path $PSScriptRoot "build_native.ps1")) {
                & "$PSScriptRoot\build_native.ps1"
            } else {
                err "build_native.ps1 not found — run from the FlowerOS repo root"
            }
        }
    } elseif ($compiler.wsl) {
        ok "Compiler: WSL gcc"
        info "Launching build.sh via WSL..."
        & wsl bash (Join-Path $PSScriptRoot "build.sh").Replace("\", "/")
    } else {
        err_ "No compatible compiler available"
        warn "Cannot build v$($v.ver) without gcc, clang, or WSL"
        Write-Host ""
        Write-Host "  Install options:" -ForegroundColor Yellow
        Write-Host "    1. MSYS2  →  https://www.msys2.org/" -ForegroundColor Cyan
        Write-Host "              pacman -S mingw-w64-ucrt-x86_64-gcc" -ForegroundColor DarkCyan
        Write-Host "    2. WSL    →  wsl --install"             -ForegroundColor Cyan
        Write-Host "              sudo apt install build-essential" -ForegroundColor DarkCyan
        Write-Host "    3. MinGW  →  https://www.mingw-w64.org/" -ForegroundColor Cyan
        Write-Host ""
    }

    Write-Host ""
    Write-Host "  Press any key to return to the selector..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ═════════════════════════════════════════════════════════════════════════
#  MAIN  — interactive loop
# ═════════════════════════════════════════════════════════════════════════
$compiler = Get-CompilerInfo
$sel      = 0    # default: first version (2.8.3)

while ($true) {
    Show-Banner
    Show-VersionList -selected $sel
    Show-Detail -v $versions[$sel] -compiler $compiler

    # Status bar
    if ($compiler.gcc -or $compiler.clang -or $compiler.wsl) {
        Write-Host ("  Compiler: {0}" -f $compiler.label) -ForegroundColor Green -NoNewline
        Write-Host "  •  Press Enter to compile-check + build selected version" -ForegroundColor DarkGray
    } else {
        Write-Host "  No compiler  •  " -ForegroundColor Red -NoNewline
        Write-Host "Install gcc (MSYS2) or WSL, then re-run this selector" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Key input
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.VirtualKeyCode) {
        38 { # ↑
            if ($sel -gt 0) { $sel-- }
            else { $sel = $versions.Count - 1 }
        }
        40 { # ↓
            if ($sel -lt ($versions.Count - 1)) { $sel++ }
            else { $sel = 0 }
        }
        13 { # Enter — run compile-check + offer build
            Invoke-Build -v $versions[$sel] -compiler $compiler
        }
        81 { # Q — quit
            Clear-Host
            hdr "  ✿  FlowerOS version selector — exited"
            dim ("     Selected: v{0}  ({1})" -f $versions[$sel].ver, $versions[$sel].codename)
            Write-Host ""
            exit 0
        }
        27 { # Escape — quit
            Clear-Host
            exit 0
        }
        default {
            # numeric shortcut: 1-5
            $char = $key.Character
            if ($char -ge '1' -and $char -le '5') {
                $idx = [int]::Parse($char) - 1
                if ($idx -ge 0 -and $idx -lt $versions.Count) {
                    $sel = $idx
                }
            }
        }
    }
}
