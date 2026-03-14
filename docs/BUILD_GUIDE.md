# FlowerOS MOTD Builder

**Generate pre-rendered ASCII art from images for instant terminal display**

---

## 🎯 Purpose

The MOTD (Message of the Day) builder creates multiple sizes of ASCII art from your images:
- **Small** (60 cols) - Compact display
- **Medium** (120 cols) - Standard
- **Large** (160 cols) - Full screen
- **Hash mode** - Alternative style

---

## 🚀 Quick Start

### 1. Add Images
```bash
# Copy images to Import directory
cp yourimage.png motd/Import/
```

### 2. Build MOTD
```bash
# Bash/WSL
chmod +x build-motd.sh
bash build-motd.sh

# PowerShell
.\build-motd.ps1
```

### 3. Use ASCII Art
```bash
# View the output
cat motd/ascii-output/yourimage-medium.ascii

# See all options
cat motd/ascii-output/INDEX.txt
```

---

## 📊 What Gets Generated

For each image in `motd/Import/`, you get:

```
yourimage.png → 
  ├── yourimage-small.ascii (60 cols)
  ├── yourimage-medium.ascii (120 cols)
  ├── yourimage-large.ascii (160 cols)
  └── yourimage-hash.ascii (alternative style)
```

Plus:
- `INDEX.txt` - Complete catalog
- Config files in `cache/` for easy scripting

---

## 🎨 Example Output

### Input Image
```
motd/Import/flower.png
```

### Build Command
```bash
bash build-motd.sh
```

### Output
```
╔══════════════════════════════════════════════════════════════════════════╗
║     🌸 FlowerOS MOTD Builder v1.2.0 🌸                                  ║
╚══════════════════════════════════════════════════════════════════════════╝

📸 Scanning for Images
──────────────────────────────────────────────────────────────────────────
✓ Found 1 image(s)

🎨 Building ASCII Art (Multiple Sizes)
──────────────────────────────────────────────────────────────────────────

Processing: flower.png
  → Small (60 cols)... ✓
  → Medium (120 cols)... ✓
  → Large (160 cols)... ✓
  → Hash mode (120 cols)... ✓

📋 Generating Index
──────────────────────────────────────────────────────────────────────────
✓ Index created: motd/ascii-output/INDEX.txt

✨ Build Summary
──────────────────────────────────────────────────────────────────────────

Successfully generated 4 ASCII art file(s)

Output Directory:
  /path/to/FlowerOS/motd/ascii-output

Generated Files:
  • flower-small.ascii (60 cols)
  • flower-medium.ascii (120 cols)
  • flower-large.ascii (160 cols)
  • flower-hash.ascii (hash mode)

🌺 MOTD build complete! 🌺
```

---

## 💡 Use Cases

### 1. Welcome Screens
```bash
# Build your logo
cp company-logo.png motd/Import/
bash build-motd.sh

# Use in welcome screen
cp motd/ascii-output/company-logo-medium.ascii \
   features/v1.2/visual-experience/ascii/custom-logo.txt
```

### 2. Multiple Themes
```bash
# Create seasonal MOTDs
cp winter.png spring.png summer.png fall.png motd/Import/
bash build-motd.sh

# Switch between them
cp motd/ascii-output/winter-medium.ascii features/v1.2/visual-experience/ascii/active.txt
```

### 3. Dynamic Content
```bash
# Generate daily art
cp daily-$(date +%Y%m%d).png motd/Import/
bash build-motd.sh

# Auto-display
cat motd/ascii-output/daily-*-medium.ascii
```

---

## 🔧 Advanced Usage

### Build Specific Sizes Only

Edit `build-motd.sh` to skip sizes:
```bash
# Comment out sizes you don't need
# output_small=...
output_medium="$OUTPUT_DIR/${name}-medium.ascii"
# output_large=...
```

### Custom Dimensions

Modify the column counts:
```bash
# In build-motd.sh, change:
bash "$IMAGE_TOOLS/img2term.sh" "$img" 80 0.55 half > "$output_small"  # Was 60
bash "$IMAGE_TOOLS/img2term.sh" "$img" 140 0.55 half > "$output_medium" # Was 120
```

### Different Pastel Strength

```bash
# More vibrant (0.3)
bash "$IMAGE_TOOLS/img2term.sh" "$img" 120 0.3 half > output.ascii

# Softer (0.7)
bash "$IMAGE_TOOLS/img2term.sh" "$img" 120 0.7 half > output.ascii
```

---

## 📋 Directory Structure

```
motd/
├── Import/              ← Put images here
│   ├── logo.png
│   └── flower.jpg
├── ascii-output/        ← Generated ASCII art
│   ├── logo-small.ascii
│   ├── logo-medium.ascii
│   ├── logo-large.ascii
│   ├── logo-hash.ascii
│   ├── flower-small.ascii
│   └── INDEX.txt
└── cache/               ← Generated configs
    ├── logo-config.sh
    └── flower-config.sh
```

---

## 🎯 Integration Examples

### Bash Profile
```bash
# Add to ~/.bashrc
motd_file="$HOME/FlowerOS/motd/ascii-output/welcome-medium.ascii"
[[ -f "$motd_file" ]] && cat "$motd_file"
```

### PowerShell Profile
```powershell
# Add to $PROFILE
$motdFile = "$HOME\FlowerOS\motd\ascii-output\welcome-medium.ascii"
if (Test-Path $motdFile) { Get-Content $motdFile }
```

### Dynamic Size Selection
```bash
# Bash: Auto-select size based on terminal width
show_motd() {
    local width=${COLUMNS:-120}
    local base="$HOME/FlowerOS/motd/ascii-output/welcome"
    
    if [[ $width -lt 80 ]]; then
        cat "${base}-small.ascii"
    elif [[ $width -lt 140 ]]; then
        cat "${base}-medium.ascii"
    else
        cat "${base}-large.ascii"
    fi
}

show_motd
```

---

## 🐛 Troubleshooting

### "No images found"
- Check images are in `motd/Import/`
- Verify supported formats (PNG, JPG, JPEG, GIF, BMP)

### Build fails
- Install dependencies: `python3 -m pip install --user pillow`
- Check bash is available (for PowerShell users)

### Poor quality output
- Use higher contrast source images
- Try different pastel strengths
- Compare pastel vs hash mode

---

## 🔄 Batch Operations

### Process New Images Only
```bash
# Check modification times
for img in motd/Import/*.png; do
    name=$(basename "$img" .png)
    output="motd/ascii-output/${name}-medium.ascii"
    
    if [[ ! -f "$output" ]] || [[ "$img" -nt "$output" ]]; then
        echo "Processing $img..."
        bash build-motd.sh
        break
    fi
done
```

### Clean and Rebuild
```bash
# Remove old ASCII art
rm -rf motd/ascii-output/*
rm -rf motd/cache/*

# Rebuild everything
bash build-motd.sh
```

---

## 📊 Performance

| Images | Build Time | Output Size |
|--------|------------|-------------|
| 1 | ~4 seconds | ~40 KB |
| 5 | ~20 seconds | ~200 KB |
| 10 | ~40 seconds | ~400 KB |

---

## 🌺 FlowerOS MOTD Builder

**Pre-render ASCII art for instant terminal display!**

*Build once, display instantly.* 🌸
