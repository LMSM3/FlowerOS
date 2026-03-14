# FlowerOS Theme Installation Script (PowerShell/WSL Compatible)
# Run with: bash install-themes-wsl.sh

Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                                           ║" -ForegroundColor Green
Write-Host "║         🌱 FlowerOS Theme Installation (WSL) 🌱                           ║" -ForegroundColor Cyan
Write-Host "║                                                                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Step 1: Setting up environment..." -ForegroundColor Yellow

# Set FlowerOS environment variables
$env:FLOWEROS_ROOT = (Get-Location).Path
$env:FLOWEROS_LIB = "$env:FLOWEROS_ROOT/lib"
$env:FLOWEROS_BIN = "$env:FLOWEROS_ROOT/bin"
$env:FLOWEROS_ASCII = "$env:FLOWEROS_ROOT/ascii"

Write-Host "  ✓ FLOWEROS_ROOT = $env:FLOWEROS_ROOT" -ForegroundColor Green
Write-Host "  ✓ FLOWEROS_LIB = $env:FLOWEROS_LIB`n" -ForegroundColor Green

Write-Host "Step 2: Creating user directories..." -ForegroundColor Yellow

# Create user directories
$userFlowerDir = "$env:USERPROFILE/.floweros"
$themeDir = "$userFlowerDir/theme"

if (-not (Test-Path $userFlowerDir)) {
    New-Item -Path $userFlowerDir -ItemType Directory -Force | Out-Null
    Write-Host "  ✓ Created $userFlowerDir" -ForegroundColor Green
} else {
    Write-Host "  ✓ Directory exists: $userFlowerDir" -ForegroundColor Green
}

if (-not (Test-Path $themeDir)) {
    New-Item -Path $themeDir -ItemType Directory -Force | Out-Null
    Write-Host "  ✓ Created $themeDir`n" -ForegroundColor Green
} else {
    Write-Host "  ✓ Directory exists: $themeDir`n" -ForegroundColor Green
}

Write-Host "Step 3: Generating theme configuration..." -ForegroundColor Yellow

# Generate theme.conf
$themeConfig = "$userFlowerDir/theme.conf"
$configContent = @"
# FlowerOS Theme Configuration
# Generated automatically

# Active theme (garden, spring, autumn, night)
FLOWEROS_THEME_ACTIVE="garden"

# Unicode symbols enabled (true/false)
FLOWEROS_THEME_UNICODE="true"

# Color palette (1=botanical, 2=flowers)
FLOWEROS_THEME_PALETTE="1"

# Theme features
FLOWEROS_THEME_COLORS="true"
FLOWEROS_THEME_GRADIENT="true"
FLOWEROS_THEME_ANIMATIONS="true"

# ASCII art preferences
FLOWEROS_THEME_ASCII_STYLE="pastel"
FLOWEROS_THEME_ASCII_WIDTH="120"

# Welcome message
FLOWEROS_THEME_WELCOME="true"
FLOWEROS_THEME_MOTD="true"

# Advanced
FLOWEROS_THEME_DEBUG="false"
FLOWEROS_THEME_CACHE_ENABLED="true"

# Version info
FLOWEROS_THEME_VERSION="1.3.0"
FLOWEROS_THEME_INIT_DATE="$(Get-Date -Format 'yyyy-MM-dd')"
FLOWEROS_THEME_INIT_USER="$env:USERNAME"
"@

Set-Content -Path $themeConfig -Value $configContent -Encoding UTF8
Write-Host "  ✓ Created theme.conf`n" -ForegroundColor Green

Write-Host "Step 4: Installing default themes..." -ForegroundColor Yellow

# Garden theme
$gardenTheme = @"
# FlowerOS Garden Theme (Default)
# Botanical colors inspired by nature

name="Garden"
description="Natural garden colors - green leaves, colorful flowers"
palette="1"

# Colors
color_primary="\033[32m"      # Green (leaves)
color_secondary="\033[35m"    # Magenta (flowers)
color_accent="\033[36m"       # Cyan (water)
color_warning="\033[33m"      # Yellow (sun)
color_error="\033[31m"        # Red (caution)
color_success="\033[92m"      # Bright green (growth)
color_info="\033[34m"         # Blue (sky)
color_muted="\033[90m"        # Gray (stones)
color_reset="\033[0m"

# Unicode symbols
symbol_seed="🌱"
symbol_leaf="🌿"
symbol_flower="✿"
symbol_bloom="🌸"
symbol_tree="🌳"
"@

Set-Content -Path "$themeDir/garden.theme" -Value $gardenTheme -Encoding UTF8
Write-Host "  ✓ Installed garden.theme" -ForegroundColor Green

# Spring theme
$springTheme = @"
# FlowerOS Spring Theme
# Fresh growth and cherry blossoms

name="Spring Bloom"
description="Light, fresh colors of spring"
palette="1"

color_primary="\033[92m"      # Light green
color_secondary="\033[95m"    # Light magenta
color_accent="\033[96m"       # Light cyan
color_warning="\033[93m"      # Light yellow
color_error="\033[91m"        # Light red
color_success="\033[32m"      # Green
color_info="\033[94m"         # Light blue
color_muted="\033[37m"        # White
color_reset="\033[0m"

symbol_seed="🌱"
symbol_leaf="🌿"
symbol_flower="🌸"
symbol_bloom="🌺"
symbol_tree="🌳"
"@

Set-Content -Path "$themeDir/spring.theme" -Value $springTheme -Encoding UTF8
Write-Host "  ✓ Installed spring.theme" -ForegroundColor Green

# Autumn theme
$autumnTheme = @"
# FlowerOS Autumn Theme
# Golden leaves and harvest colors

name="Autumn Harvest"
description="Warm colors of fall"
palette="1"

color_primary="\033[33m"      # Yellow
color_secondary="\033[31m"    # Red
color_accent="\033[35m"       # Magenta
color_warning="\033[93m"      # Bright yellow
color_error="\033[91m"        # Bright red
color_success="\033[32m"      # Green
color_info="\033[34m"         # Blue
color_muted="\033[90m"        # Gray
color_reset="\033[0m"

symbol_seed="🍂"
symbol_leaf="🍁"
symbol_flower="🌾"
symbol_bloom="🍄"
symbol_tree="🎃"
"@

Set-Content -Path "$themeDir/autumn.theme" -Value $autumnTheme -Encoding UTF8
Write-Host "  ✓ Installed autumn.theme" -ForegroundColor Green

# Night theme
$nightTheme = @"
# FlowerOS Night Garden Theme
# Moonlit garden with night flowers

name="Night Garden"
description="Cool colors of the night garden"
palette="1"

color_primary="\033[34m"      # Blue
color_secondary="\033[35m"    # Magenta
color_accent="\033[36m"       # Cyan
color_warning="\033[33m"      # Yellow
color_error="\033[31m"        # Red
color_success="\033[32m"      # Green
color_info="\033[94m"         # Light blue
color_muted="\033[90m"        # Dark gray
color_reset="\033[0m"

symbol_seed="🌙"
symbol_leaf="⭐"
symbol_flower="✨"
symbol_bloom="🌟"
symbol_tree="🌌"
"@

Set-Content -Path "$themeDir/night.theme" -Value $nightTheme -Encoding UTF8
Write-Host "  ✓ Installed night.theme`n" -ForegroundColor Green

Write-Host "Step 5: Creating first-run marker..." -ForegroundColor Yellow
$marker = "$userFlowerDir/.first_run_complete"
Get-Date -UFormat %s | Set-Content -Path $marker -Encoding UTF8
Write-Host "  ✓ First-run marker created`n" -ForegroundColor Green

Write-Host "Step 6: Building theme cache..." -ForegroundColor Yellow
$cache = "$userFlowerDir/theme.cache"
$cacheContent = @"
# FlowerOS Theme Cache
# Generated: $(Get-Date)

theme_garden="$themeDir/garden.theme"
theme_spring="$themeDir/spring.theme"
theme_autumn="$themeDir/autumn.theme"
theme_night="$themeDir/night.theme"
"@

Set-Content -Path $cache -Value $cacheContent -Encoding UTF8
Write-Host "  ✓ Cache built`n" -ForegroundColor Green

Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                                           ║" -ForegroundColor Green
Write-Host "║                    ✓ Installation Complete! ✓                            ║" -ForegroundColor Cyan
Write-Host "║                                                                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Installation Summary:" -ForegroundColor Yellow
Write-Host "  📁 Config:  $themeConfig" -ForegroundColor Cyan
Write-Host "  📁 Themes:  $themeDir" -ForegroundColor Cyan
Write-Host "  📁 Cache:   $cache`n" -ForegroundColor Cyan

Write-Host "Available themes:" -ForegroundColor Yellow
Write-Host "  🌿 garden   - Natural green & flowers (default)" -ForegroundColor Green
Write-Host "  🌸 spring   - Light & fresh colors" -ForegroundColor Magenta
Write-Host "  🍂 autumn   - Warm golden colors" -ForegroundColor Yellow
Write-Host "  🌙 night    - Cool moonlit colors`n" -ForegroundColor Blue

Write-Host "🌸 Theme system ready!" -ForegroundColor Green
Write-Host "To use in bash: source lib/theme_loader.sh`n" -ForegroundColor Cyan
