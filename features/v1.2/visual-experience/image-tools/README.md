# FlowerOS Image-to-Terminal Tools

Convert images to beautiful terminal art with pastel colors.

---

## 🎨 Quick Start

### Bash/WSL
```bash
# Simple conversion
bash img2term.sh flower.png

# Custom width and pastel strength
bash img2term.sh flower.png 140 0.60 half

# Hash-based pastel mode
python3 img2term-hash.py flower.png 120
```

### PowerShell
```powershell
# Simple conversion
.\Convert-ImageToTerminal.ps1 flower.png

# Custom settings
.\Convert-ImageToTerminal.ps1 flower.png -Columns 140 -PastelStrength 0.60

# Hash-based mode
.\Convert-ImageToTerminal.ps1 flower.png -Mode hash

# Save to file
.\Convert-ImageToTerminal.ps1 flower.png -Save
```

---

## 🛠️ Tools

### `img2term.sh`
**Standard pastel converter**
- Uses HSL color space for pastel effect
- Supports full/half block modes
- Adjustable pastel strength

**Usage:**
```bash
bash img2term.sh <image> [cols] [pastel] [mode]
```

**Parameters:**
- `image` - Input image path
- `cols` - Terminal width (default: 120)
- `pastel` - Pastel strength 0-1 (default: 0.55)
- `mode` - `half` or `full` blocks (default: half)

### `img2term-hash.py`
**Hash-based pastel converter**
- Deterministic color mapping
- 1028 pastel colors
- Consistent results

**Usage:**
```bash
python3 img2term-hash.py <image> [cols]
```

### `Convert-ImageToTerminal.ps1`
**PowerShell wrapper**
- Easy Windows usage
- Auto-installs dependencies
- Can save output to file

**Parameters:**
- `-ImagePath` - Input image (required)
- `-Columns` - Width (default: 120)
- `-Mode` - `pastel` or `hash` (default: pastel)
- `-PastelStrength` - 0-1 (default: 0.55)
- `-BlockMode` - `half` or `full` (default: half)
- `-Save` - Save to `.ascii` file

---

## 💡 Examples

### Welcome Screen Art
```bash
# Convert logo for welcome screen
bash img2term.sh logo.png 80 0.50 half > ascii/custom-logo.txt
```

### Profile Pictures
```bash
# Your photo as terminal art
python3 img2term-hash.py photo.jpg 60
```

### Backgrounds
```bash
# Subtle background
bash img2term.sh background.png 200 0.40 half
```

---

## 🎯 Tips

### Best Results
- **Use high contrast images** - Better terminal representation
- **Start with 120 cols** - Good balance of detail and size
- **Adjust pastel** - Lower = more vibrant, higher = softer
- **Half blocks** - Better quality than full blocks

### Pastel Strength Guide
- `0.30` - Barely pastel (vibrant)
- `0.55` - Balanced (default)
- `0.70` - Soft pastel
- `0.90` - Very soft

### Mode Comparison
- **pastel** - Smooth gradients, natural colors
- **hash** - Deterministic, consistent across runs

---

## 📦 Requirements

- **Python 3** - Any version
- **Pillow** - Auto-installed by PowerShell wrapper
  ```bash
  python3 -m pip install --user pillow
  ```
- **Bash** - For img2term.sh (WSL on Windows)

---

## 🎨 Integration with FlowerOS

### Custom Welcome Screen
```powershell
# Convert your image
.\Convert-ImageToTerminal.ps1 mylogo.png -Columns 80 -Save

# Copy to ASCII directory
Copy-Item mylogo.ascii ../ascii/custom.txt

# Update FlowerOS-Welcome.ps1 to use it
```

### Dynamic Backgrounds
```bash
# Generate daily art
bash img2term.sh $(date +%Y%m%d).png 140 > daily.txt
```

---

## 🐛 Troubleshooting

**Python not found?**
- Install from python.org
- Add to PATH

**Pillow errors?**
```bash
python3 -m pip install --upgrade pillow
```

**Colors look wrong?**
- Check `$TERM` environment variable
- Ensure terminal supports 256 colors
- Try different terminal emulator

**Image too large?**
- Reduce columns parameter
- Use smaller source image

---

## 🌺 Examples Output

### Input: Blue Flowers
![Blue flowers photo]

### Output: Terminal Art
```
████▓▒░▓███▓▓▓▒▒▒░░░▓▓▓▓███▓░░▒▓▓▓███
███▓▒░░▒▓██▓▒░░░░░░░░▒▒▓███▓░░░░▒▓██
██▓▒░░░░▒▓█▓░░░░░░░░░░░▒▓▓▓░░░░░░▒▓█
▓▒░░░░░░░▒▓░░░  ░░  ░░░░▒▒░░░░░░░░▒▓
```

**Beautiful, pastel, professional!** 🌸

---

## 🎓 Advanced Usage

### Batch Conversion
```bash
for img in *.png; do
    bash img2term.sh "$img" 100 0.55 half > "ascii/${img%.png}.txt"
done
```

### Animation Frames
```bash
# Convert each frame
for i in {001..100}; do
    python3 img2term-hash.py "frame_$i.png" 80
    sleep 0.1
done
```

---

## 🌟 Why Two Converters?

**img2term.sh (Pastel Mode)**
- Smooth color gradients
- Natural looking
- Best for photos

**img2term-hash.py (Hash Mode)**
- Consistent results
- Deterministic colors
- Best for logos/graphics

Use whichever looks better for your image!

---

## 🌺 FlowerOS Image Tools

*Transform any image into breathtaking terminal art.*

**Every picture can bloom in your terminal.** 🌸
