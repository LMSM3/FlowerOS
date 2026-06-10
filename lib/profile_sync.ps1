# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Profile Sync — PowerShell Side        (lib/profile_sync.ps1)
#
#  Reads the active FlowerOS theme (via WSLENV vars, the sync manifest
#  written by the bash side, or local ~/.floweros/ config) and applies
#  matching colors to the current PowerShell session + Oh My Posh.
#
#  Add to your $PROFILE:
#
#    $env:FLOWEROS_ROOT = "C:\R\FlowerOS"          # adjust path
#    . "$env:FLOWEROS_ROOT\lib\profile_sync.ps1"
#
#  Part of FlowerOS v1.3.0 — Core Architecture.
# ═══════════════════════════════════════════════════════════════════════════

#region Guard
if ($env:_FLOWEROS_PS_SYNCED -eq "1") { return }
$env:_FLOWEROS_PS_SYNCED = "1"
#endregion

# ═══════════════════════════════════════════════════════════════════════════
#  0. Resolve FlowerOS root
# ═══════════════════════════════════════════════════════════════════════════

if (-not $env:FLOWEROS_ROOT) {
    # Derive from this script's own location
    $env:FLOWEROS_ROOT = (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
}
$_fosRoot   = $env:FLOWEROS_ROOT
$_fosLib    = Join-Path $_fosRoot "lib"
$_fosConfig = Join-Path $env:USERPROFILE ".floweros"

# ═══════════════════════════════════════════════════════════════════════════
#  1. Theme palette defaults (garden)
# ═══════════════════════════════════════════════════════════════════════════

$_defaultPalette = @{
    Primary   = "#5faf5f"
    Secondary = "#af5faf"
    Accent    = "#5fafaf"
    Warning   = "#afaf00"
    Error     = "#cc4444"
    Success   = "#5fdf5f"
    Info      = "#5f87df"
    Muted     = "#808080"
    Bg        = "#1e1e2e"
    Fg        = "#cdd6f4"
}

# Hard-coded theme palettes (mirror the bash .theme files)
$_themePalettes = @{
    garden = @{
        Primary="#5faf5f"; Secondary="#af5faf"; Accent="#5fafaf"
        Warning="#afaf00"; Error="#cc4444"; Success="#5fdf5f"
        Info="#5f87df"; Muted="#808080"; Bg="#1e1e2e"; Fg="#cdd6f4"
    }
    spring = @{
        Primary="#5fdf5f"; Secondary="#ff7fff"; Accent="#5fdfdf"
        Warning="#ffff55"; Error="#ff5555"; Success="#5faf5f"
        Info="#7fafff"; Muted="#c0c0c0"; Bg="#1e1e2e"; Fg="#cdd6f4"
    }
    autumn = @{
        Primary="#afaf00"; Secondary="#cc4444"; Accent="#af5faf"
        Warning="#ffff55"; Error="#ff5555"; Success="#5faf5f"
        Info="#5f87df"; Muted="#808080"; Bg="#1e1e2e"; Fg="#cdd6f4"
    }
    night = @{
        Primary="#5f87df"; Secondary="#af5faf"; Accent="#5fafaf"
        Warning="#afaf00"; Error="#cc4444"; Success="#5faf5f"
        Info="#7fafff"; Muted="#808080"; Bg="#0d0d1a"; Fg="#b0b8d0"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
#  2. Read theme state (multiple sources, priority order)
# ═══════════════════════════════════════════════════════════════════════════

function _FOS_ReadSyncManifest {
    <#
    .SYNOPSIS
        Read the key=value manifest written by the bash side.
        Returns a hashtable or $null.
    #>
    # Try WSL default user home via \\wsl.localhost
    $wslDistros = @("Ubuntu", "Ubuntu-24.04", "Ubuntu-22.04", "Ubuntu-20.04", "Debian")
    foreach ($distro in $wslDistros) {
        $wslHome = "\\wsl.localhost\$distro\home"
        if (Test-Path $wslHome -ErrorAction SilentlyContinue) {
            # Find the first user directory
            $userDirs = Get-ChildItem $wslHome -Directory -ErrorAction SilentlyContinue | Select-Object -First 3
            foreach ($ud in $userDirs) {
                $manifest = Join-Path $ud.FullName ".floweros\theme_sync.env"
                if (Test-Path $manifest -ErrorAction SilentlyContinue) {
                    return _FOS_ParseEnvFile $manifest
                }
            }
        }
    }

    # Fallback: Windows-local config (Pollen ~/.config/flower/ then legacy ~/.floweros/)
    $pollenManifest = Join-Path $env:USERPROFILE ".config\flower\theme.env"
    if (Test-Path $pollenManifest -ErrorAction SilentlyContinue) {
        return _FOS_ParseEnvFile $pollenManifest
    }

    $localManifest = Join-Path $_fosConfig "theme_sync.env"
    if (Test-Path $localManifest -ErrorAction SilentlyContinue) {
        return _FOS_ParseEnvFile $localManifest
    }

    return $null
}

function _FOS_ParseEnvFile([string]$path) {
    $result = @{}
    foreach ($line in (Get-Content $path -ErrorAction SilentlyContinue)) {
        $line = $line.Trim()
        if ($line -match '^#' -or $line -eq '') { continue }
        if ($line -match '^([A-Z_]+)="?([^"]*)"?$') {
            $result[$Matches[1]] = $Matches[2]
        }
    }
    return $result
}

function _FOS_ResolveTheme {
    <#
    .SYNOPSIS
        Determine the active FlowerOS theme and its hex palette.
        Priority:
          1. WSLENV env vars (set when launched from WSL)
          2. Sync manifest on WSL filesystem
          3. Windows-local theme.conf
          4. Defaults (garden)
    #>

    # ── Source 1: WSLENV variables already in env ────────────────────
    if ($env:FLOWEROS_OMP_PRIMARY) {
        $themeName = if ($env:FLOWEROS_THEME_LOADED) { $env:FLOWEROS_THEME_LOADED } else { "garden" }
        return @{
            Name      = $themeName
            Variant   = if ($env:FLOWEROS_THEME_VARIANT) { $env:FLOWEROS_THEME_VARIANT } else { "dark" }
            Primary   = $env:FLOWEROS_OMP_PRIMARY
            Secondary = $env:FLOWEROS_OMP_SECONDARY
            Accent    = $env:FLOWEROS_OMP_ACCENT
            Warning   = $env:FLOWEROS_OMP_WARNING
            Error     = $env:FLOWEROS_OMP_ERROR
            Success   = $env:FLOWEROS_OMP_SUCCESS
            Info      = $env:FLOWEROS_OMP_INFO
            Muted     = $env:FLOWEROS_OMP_MUTED
            Bg        = $env:FLOWEROS_OMP_BG
            Fg        = $env:FLOWEROS_OMP_FG
            Source    = "WSLENV"
        }
    }

    # ── Source 2: Sync manifest from WSL ─────────────────────────────
    $manifest = _FOS_ReadSyncManifest
    if ($manifest -and $manifest["FLOWEROS_OMP_PRIMARY"]) {
        return @{
            Name      = $manifest["FLOWEROS_THEME_LOADED"]
            Variant   = $manifest["FLOWEROS_THEME_VARIANT"]
            Primary   = $manifest["FLOWEROS_OMP_PRIMARY"]
            Secondary = $manifest["FLOWEROS_OMP_SECONDARY"]
            Accent    = $manifest["FLOWEROS_OMP_ACCENT"]
            Warning   = $manifest["FLOWEROS_OMP_WARNING"]
            Error     = $manifest["FLOWEROS_OMP_ERROR"]
            Success   = $manifest["FLOWEROS_OMP_SUCCESS"]
            Info      = $manifest["FLOWEROS_OMP_INFO"]
            Muted     = $manifest["FLOWEROS_OMP_MUTED"]
            Bg        = $manifest["FLOWEROS_OMP_BG"]
            Fg        = $manifest["FLOWEROS_OMP_FG"]
            Source    = "manifest"
        }
    }

    # ── Source 3: Windows-local theme.conf ───────────────────────────
    $confFile = Join-Path $_fosConfig "theme.conf"
    if (Test-Path $confFile -ErrorAction SilentlyContinue) {
        $conf = _FOS_ParseEnvFile $confFile
        $themeName = if ($conf["FLOWEROS_THEME_ACTIVE"]) { $conf["FLOWEROS_THEME_ACTIVE"] } else { "garden" }
        if ($_themePalettes.ContainsKey($themeName)) {
            $p = $_themePalettes[$themeName]
            return @{
                Name    = $themeName
                Variant = "dark"
                Source  = "local-conf"
            } + $p
        }
    }

    # ── Source 4: defaults ───────────────────────────────────────────
    return @{ Name = "garden"; Variant = "dark"; Source = "default" } + $_defaultPalette
}

# ═══════════════════════════════════════════════════════════════════════════
#  3. Apply theme to current PowerShell session
# ═══════════════════════════════════════════════════════════════════════════

function _FOS_ApplyTheme([hashtable]$theme) {
    # Export every colour as an env var (so OMP picks them up)
    $env:FLOWEROS_OMP_PRIMARY   = $theme.Primary
    $env:FLOWEROS_OMP_SECONDARY = $theme.Secondary
    $env:FLOWEROS_OMP_ACCENT    = $theme.Accent
    $env:FLOWEROS_OMP_WARNING   = $theme.Warning
    $env:FLOWEROS_OMP_ERROR     = $theme.Error
    $env:FLOWEROS_OMP_SUCCESS   = $theme.Success
    $env:FLOWEROS_OMP_INFO      = $theme.Info
    $env:FLOWEROS_OMP_MUTED     = $theme.Muted
    $env:FLOWEROS_OMP_BG        = $theme.Bg
    $env:FLOWEROS_OMP_FG        = $theme.Fg
    $env:FLOWEROS_THEME_LOADED  = $theme.Name
    $env:FLOWEROS_THEME_VARIANT = $theme.Variant

    # PSStyle colours (PS 7.2+)
    if ($PSVersionTable.PSVersion.Major -ge 7 -and $null -ne (Get-Variable PSStyle -ErrorAction SilentlyContinue)) {
        try {
            $PSStyle.Formatting.FormatAccent   = "`e[36m"
            $PSStyle.Formatting.ErrorAccent     = "`e[31m"
            $PSStyle.Formatting.Warning         = "`e[33m"
            $PSStyle.Formatting.Verbose         = "`e[90m"
            $PSStyle.Formatting.Debug           = "`e[90m"
            $PSStyle.Progress.View              = 'Classic'
        } catch { }
    }

    # Map theme colours to PS console foreground/background
    # (works in Windows PowerShell 5.1 and PS 7+)
    try {
        $Host.UI.RawUI.ForegroundColor = 'Gray'
        $Host.UI.RawUI.BackgroundColor = 'Black'
    } catch { }
}

# ═══════════════════════════════════════════════════════════════════════════
#  4. Oh My Posh initialisation
# ═══════════════════════════════════════════════════════════════════════════

function _FOS_InitOMP {
    # Locate OMP binary
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { return }

    # Determine theme config path (prefer FlowerOS shared template)
    $ompConfig = Join-Path $_fosLib "floweros.omp.json"

    # If running inside WSL-launched pwsh, the path may be a Linux path
    if (-not (Test-Path $ompConfig -ErrorAction SilentlyContinue)) {
        # Try via \\wsl.localhost mount
        $wslOmpConfig = "\\wsl.localhost\Ubuntu" + ($ompConfig -replace '\\','/')
        if (Test-Path $wslOmpConfig -ErrorAction SilentlyContinue) {
            $ompConfig = $wslOmpConfig
        } else {
            return  # no config found — let OMP use its default
        }
    }

    oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
}

# ═══════════════════════════════════════════════════════════════════════════
#  5. Public commands
# ═══════════════════════════════════════════════════════════════════════════

function Set-FlowerTheme {
    <#
    .SYNOPSIS
        Switch the active FlowerOS theme from PowerShell.
    .EXAMPLE
        Set-FlowerTheme spring
    #>
    param(
        [Parameter(Mandatory)][ValidateSet("garden","spring","autumn","night")]
        [string]$ThemeName
    )

    if (-not $_themePalettes.ContainsKey($ThemeName)) {
        Write-Host "  ✗ Unknown theme: $ThemeName" -ForegroundColor Red
        return
    }

    $palette = $_themePalettes[$ThemeName]
    $theme = @{ Name = $ThemeName; Variant = "dark"; Source = "ps-direct" } + $palette
    _FOS_ApplyTheme $theme

    # Write a manifest so the bash side can pick it up too
    $manifestDir = Join-Path $env:USERPROFILE ".floweros"
    if (-not (Test-Path $manifestDir)) { New-Item -Path $manifestDir -ItemType Directory -Force | Out-Null }
    $manifestPath = Join-Path $manifestDir "theme_sync.env"

    $dateStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $lines = @(
        ('# FlowerOS Theme Sync Manifest - auto-generated by profile_sync.ps1')
        ('# ' + $dateStamp)
        ('FLOWEROS_THEME_LOADED="' + $ThemeName + '"')
        ('FLOWEROS_THEME_VARIANT="dark"')
        ('FLOWEROS_DISTRO="windows"')
        ('FLOWEROS_OMP_PRIMARY="' + $palette.Primary + '"')
        ('FLOWEROS_OMP_SECONDARY="' + $palette.Secondary + '"')
        ('FLOWEROS_OMP_ACCENT="' + $palette.Accent + '"')
        ('FLOWEROS_OMP_WARNING="' + $palette.Warning + '"')
        ('FLOWEROS_OMP_ERROR="' + $palette.Error + '"')
        ('FLOWEROS_OMP_SUCCESS="' + $palette.Success + '"')
        ('FLOWEROS_OMP_INFO="' + $palette.Info + '"')
        ('FLOWEROS_OMP_MUTED="' + $palette.Muted + '"')
        ('FLOWEROS_OMP_BG="' + $palette.Bg + '"')
        ('FLOWEROS_OMP_FG="' + $palette.Fg + '"')
    )
    $lines | Set-Content -Path $manifestPath -Encoding UTF8

    # Also write to Pollen ~/.config/flower/ canonical location
    $pollenDir = Join-Path $env:USERPROFILE ".config\flower"
    if (-not (Test-Path $pollenDir)) { New-Item -Path $pollenDir -ItemType Directory -Force | Out-Null }
    $lines | Set-Content -Path (Join-Path $pollenDir "theme.env") -Encoding UTF8

    # Update local theme.conf too
    $confPath = Join-Path $manifestDir "theme.conf"
    if (Test-Path $confPath -ErrorAction SilentlyContinue) {
        $content = Get-Content $confPath -Raw
        $newVal = 'FLOWEROS_THEME_ACTIVE="' + $ThemeName + '"'
        $content = $content -replace 'FLOWEROS_THEME_ACTIVE="[^"]*"', $newVal
        Set-Content -Path $confPath -Value $content -Encoding UTF8
    }

    # Re-init OMP with new colours
    _FOS_InitOMP

    Write-Host ""
    Write-Host "  ✓ Theme applied: $ThemeName" -ForegroundColor Green
    Write-Host "    Source: PowerShell direct" -ForegroundColor DarkGray
    Write-Host "    Manifest: $manifestPath" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-FlowerTheme {
    <#
    .SYNOPSIS
        Show the currently active FlowerOS theme and its palette.
    #>
    $theme = _FOS_ResolveTheme

    Write-Host ""
    Write-Host "  🌿 FlowerOS Theme Status" -ForegroundColor Cyan
    Write-Host "  ════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  Theme:    $($theme.Name)" -ForegroundColor Green
    Write-Host "  Variant:  $($theme.Variant)" -ForegroundColor DarkGray
    Write-Host "  Source:   $($theme.Source)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Palette:" -ForegroundColor Yellow

    $colorKeys = @("Primary","Secondary","Accent","Warning","Error","Success","Info","Muted","Bg","Fg")
    foreach ($k in $colorKeys) {
        $hex = $theme[$k]
        if ($hex) {
            Write-Host "    $($k.PadRight(12)) $hex" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

function Install-FlowerOMP {
    <#
    .SYNOPSIS
        Install Oh My Posh via winget (if not already present).
    #>
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ oh-my-posh already installed" -ForegroundColor Green
        return
    }
    Write-Host "  🌱 Installing Oh My Posh..." -ForegroundColor Yellow
    try {
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
        Write-Host "  ✓ oh-my-posh installed - restart your terminal" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ winget install failed: $_" -ForegroundColor Red
        Write-Host "    Manual: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor DarkGray
    }
}

# ═══════════════════════════════════════════════════════════════════════════
#  6. flower command (alias for bin/flower.ps1)
# ═══════════════════════════════════════════════════════════════════════════

function flower {
    & (Join-Path $env:FLOWEROS_ROOT "bin\flower.ps1") @args
}
w
# ═══════════════════════════════════════════════════════════════════════════
#  7. Auto-run on dot-source
# ═══════════════════════════════════════════════════════════════════════════

$_resolvedTheme = _FOS_ResolveTheme
_FOS_ApplyTheme $_resolvedTheme
_FOS_InitOMP

# MOTD — show a random flower on interactive shell launch
$_fosMotd = Join-Path $_fosLib "flower_motd.ps1"
if ((Test-Path $_fosMotd) -and [Environment]::UserInteractive) {
    . $_fosMotd
    Show-FlowerMOTD
}
