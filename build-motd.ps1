#!/usr/bin/env pwsh
# FlowerOS MOTD Builder (PowerShell)
# Generates pre-rendered ASCII art from images in motd/Import/

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
$IMPORT_DIR = "$SCRIPT_DIR/motd/Import"
$OUTPUT_DIR = "$SCRIPT_DIR/motd/ascii-output"
$CACHE_DIR = "$SCRIPT_DIR/motd/cache"
$IMAGE_TOOLS = "$SCRIPT_DIR/features/v1.2/visual-experience/image-tools"

function Show-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║     🌸 FlowerOS MOTD Builder v1.2.0 🌸                                  ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Show-Step($Message) {
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ("─" * 70) -ForegroundColor DarkGray
}

function Show-Success($Message) {
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Show-Warning($Message) {
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Create directories
New-Item -ItemType Directory -Path $IMPORT_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $CACHE_DIR -Force | Out-Null

Show-Header

# Check for images
Show-Step "📸 Scanning for Images"

$images = Get-ChildItem -Path $IMPORT_DIR -Include *.png,*.jpg,*.jpeg,*.gif,*.bmp -File

if ($images.Count -eq 0) {
    Show-Warning "No images found in $IMPORT_DIR"
    Write-Host ""
    Write-Host "Add images to motd/Import/ and run again."
    Write-Host ""
    Write-Host "Supported formats: PNG, JPG, JPEG, GIF, BMP"
    Write-Host ""
    exit 0
}

Show-Success "Found $($images.Count) image(s)"

# Check for Python
$pythonCmd = $null
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
}

# Process each image
Show-Step "🎨 Building ASCII Art (Multiple Sizes)"

$totalGenerated = 0

foreach ($img in $images) {
    $name = $img.BaseName
    
    Write-Host ""
    Write-Host "Processing: $($img.Name)" -ForegroundColor Cyan
    
    # Small (60 cols)
    $outputSmall = Join-Path $OUTPUT_DIR "$name-small.ascii"
    Write-Host "  → Small (60 cols)... " -NoNewline
    try {
        bash "$IMAGE_TOOLS/img2term.sh" $img.FullName 60 0.55 half > $outputSmall 2>$null
        Write-Host "✓" -ForegroundColor Green
        $totalGenerated++
    } catch {
        Write-Host "✗" -ForegroundColor Red
    }
    
    # Medium (120 cols)
    $outputMedium = Join-Path $OUTPUT_DIR "$name-medium.ascii"
    Write-Host "  → Medium (120 cols)... " -NoNewline
    try {
        bash "$IMAGE_TOOLS/img2term.sh" $img.FullName 120 0.55 half > $outputMedium 2>$null
        Write-Host "✓" -ForegroundColor Green
        $totalGenerated++
    } catch {
        Write-Host "✗" -ForegroundColor Red
    }
    
    # Large (160 cols)
    $outputLarge = Join-Path $OUTPUT_DIR "$name-large.ascii"
    Write-Host "  → Large (160 cols)... " -NoNewline
    try {
        bash "$IMAGE_TOOLS/img2term.sh" $img.FullName 160 0.55 half > $outputLarge 2>$null
        Write-Host "✓" -ForegroundColor Green
        $totalGenerated++
    } catch {
        Write-Host "✗" -ForegroundColor Red
    }
    
    # Hash mode
    if ($pythonCmd) {
        $outputHash = Join-Path $OUTPUT_DIR "$name-hash.ascii"
        Write-Host "  → Hash mode (120 cols)... " -NoNewline
        try {
            & $pythonCmd "$IMAGE_TOOLS/img2term-hash.py" $img.FullName 120 > $outputHash 2>$null
            Write-Host "✓" -ForegroundColor Green
            $totalGenerated++
        } catch {
            Write-Host "✗" -ForegroundColor Red
        }
    }
}

# Generate index
Show-Step "📋 Generating Index"

$indexFile = Join-Path $OUTPUT_DIR "INDEX.txt"
$indexContent = @"
FlowerOS MOTD - ASCII Art Index
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Available ASCII Art Files:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@

foreach ($img in $images) {
    $name = $img.BaseName
    $indexContent += "`n$name:`n"
    
    if (Test-Path "$OUTPUT_DIR/$name-small.ascii") {
        $indexContent += "  - $name-small.ascii (60 cols)`n"
    }
    if (Test-Path "$OUTPUT_DIR/$name-medium.ascii") {
        $indexContent += "  - $name-medium.ascii (120 cols)`n"
    }
    if (Test-Path "$OUTPUT_DIR/$name-large.ascii") {
        $indexContent += "  - $name-large.ascii (160 cols)`n"
    }
    if (Test-Path "$OUTPUT_DIR/$name-hash.ascii") {
        $indexContent += "  - $name-hash.ascii (hash mode)`n"
    }
    $indexContent += "`n"
}

$indexContent += @"

Usage:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View ASCII art:
  Get-Content motd/ascii-output/yourfile.ascii

Use in welcome screen:
  Copy-Item motd/ascii-output/yourfile.ascii features/v1.2/visual-experience/ascii/

Preview all:
  Get-ChildItem motd/ascii-output/*.ascii | ForEach-Object { Write-Host "=== `$_ ==="; Get-Content `$_; Write-Host "" }

"@

Set-Content -Path $indexFile -Value $indexContent -Encoding UTF8

Show-Success "Index created: $indexFile"

# Summary
Show-Step "✨ Build Summary"

Write-Host ""
Write-Host "Successfully generated $totalGenerated ASCII art file(s)" -ForegroundColor Green
Write-Host ""
Write-Host "Output Directory:" -ForegroundColor Cyan
Write-Host "  $OUTPUT_DIR"
Write-Host ""
Write-Host "Generated Files:" -ForegroundColor Cyan

foreach ($img in $images) {
    $name = $img.BaseName
    Write-Host "  • $name-small.ascii (60 cols)"
    Write-Host "  • $name-medium.ascii (120 cols)"
    Write-Host "  • $name-large.ascii (160 cols)"
    if (Test-Path "$OUTPUT_DIR/$name-hash.ascii") {
        Write-Host "  • $name-hash.ascii (hash mode)"
    }
}

Write-Host ""
Write-Host "Quick Preview:" -ForegroundColor Yellow
Write-Host "  Get-Content motd/ascii-output/INDEX.txt"
Write-Host ""
Write-Host "View ASCII Art:" -ForegroundColor Yellow

$firstName = $images[0].BaseName
Write-Host "  Get-Content motd/ascii-output/$firstName-medium.ascii"

Write-Host ""
Write-Host "Use in Welcome Screen:" -ForegroundColor Yellow
Write-Host "  Copy-Item motd/ascii-output/yourfile.ascii features/v1.2/visual-experience/ascii/"
Write-Host "  # Edit FlowerOS-Welcome.ps1 to use it"
Write-Host ""

Write-Host "🌺 MOTD build complete! 🌺" -ForegroundColor Magenta
Write-Host ""
