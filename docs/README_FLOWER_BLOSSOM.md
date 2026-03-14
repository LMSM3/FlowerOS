# FlowerOS Image to ASCII Converter

## 🌸 flower_blossom - Image to ASCII Art Tool

Part of FlowerOS v1.3.0 Universal Compute System

---

## Overview

**`flower_blossom`** is a batch image-to-ASCII converter that transforms images into beautiful pastel-colored ANSI art. It's part of the FlowerOS visual output system.

### Why "blossom"?

In FlowerOS botanical terminology:
- **Seeds** = Input images
- **Blooming** = Conversion process
- **Blossoms** = Output ASCII art

Every image blooms into colorful ASCII art. 🌸

---

## Features

✅ **Batch Processing** - Convert multiple images at once  
✅ **Pastel 256-Color** - Soft, garden-themed color palette  
✅ **Directory Support** - Process entire folders  
✅ **Multiple Formats** - PNG, JPG, BMP, GIF, WebP  
✅ **Aspect Correction** - Proper character cell dimensions  
✅ **Universal Runner** - Can handle any number of images

---

## Installation

### Prerequisites

```bash
# Debian/Ubuntu
sudo apt-get install python3 python3-pip python3-pil

# Or via pip
python3 -m pip install pillow
```

### FlowerOS Integration

```bash
# Tool is located at:
/opt/floweros/tools/flower_blossom.py

# Make it executable
chmod +x /opt/floweros/tools/flower_blossom.py

# Optional: Create symlink for easy access
sudo ln -s /opt/floweros/tools/flower_blossom.py /usr/local/bin/flower_blossom
```

---

## Usage

### Basic Syntax

```bash
python3 flower_blossom.py <img_or_dir> [more_imgs_or_dirs...]
```

### Examples

#### Single Image

```bash
python3 flower_blossom.py photo.jpg
```

#### Directory of Images

```bash
python3 flower_blossom.py /path/to/photos/
```

#### Multiple Inputs

```bash
python3 flower_blossom.py image1.png image2.jpg /folder/of/images/
```

#### With Width Specification

```bash
# Interactive prompt will ask for width
python3 flower_blossom.py *.jpg
# Output ASCII width (10-500, recommend 120): 120
```

---

## Configuration

### Output Width

When running the tool, you'll be prompted:

```
Output ASCII width (10-500, recommend 120):
```

**Recommendations:**
- **80** - Classic terminal width
- **120** - Modern widescreen (default)
- **160** - High detail
- **200+** - Maximum detail (large terminals)

### Color Palette

The tool uses a carefully selected "pastel garden" palette:

| Color Range | ANSI Codes | Theme |
|-------------|------------|-------|
| Near-white | 227-231 | Full bloom |
| Lavender | 222-225 | Flower petals |
| Mint green | 193-195 | Fresh leaves |
| Pale cyan | 157-159 | Morning dew |
| Soft pink | 187-189 | Rose petals |
| Peach | 184-186 | Sunset petals |
| Blue-gray | 150-152 | Garden stones |
| Light gray | 252-254 | Clouds |

---

## Viewing Output

### Recommended Method

```bash
# Use 'less' with color support (-R flag)
less -R ascii_out/*.ansi.txt

# Navigate with:
#   Space = next page
#   b = previous page
#   q = quit
```

### Alternative Methods

```bash
# Cat (may scroll too fast)
cat ascii_out/image.ansi.txt

# In a text editor (color support varies)
nano ascii_out/image.ansi.txt
vim ascii_out/image.ansi.txt  # Use :set t_Co=256
```

### Terminal Requirements

For best results:
- Terminal with 256-color support
- UTF-8 encoding
- ANSI escape sequence support

**Test your terminal:**
```bash
# Should show smooth color gradient
python3 -c "for i in range(256): print(f'\x1b[38;5;{i}m{i:3d}\x1b[0m', end=' ' if (i+1)%16 else '\n')"
```

---

## Output Structure

### Directory Layout

```
ascii_out/
├── photo1.ansi.txt
├── photo2.ansi.txt
├── landscape.ansi.txt
└── portrait.ansi.txt
```

### File Format

Output files contain:
- ANSI escape codes for 256-color foreground
- ASCII characters from ramp: `@%#*+=-:. `
- Newlines for row separation
- Reset codes to prevent color bleed

**Example output snippet:**
```
ESC[38;5;231m.ESC[38;5;230m:ESC[38;5;229m-ESC[0m
ESC[38;5;228m=ESC[38;5;227m+ESC[38;5;225m*ESC[0m
...
```

---

## Character Ramp

The tool uses a brightness-to-character mapping:

```
Dark  →  Light
@  %  #  *  +  =  -  :  .  (space)
```

**Botanical metaphor:**
- `@` = Seeds (darkest)
- `%` = Roots
- `#` = Stems
- `*` = Leaves
- `+` = Buds
- `=` = Petals
- `-` = Bloom
- `:` = Full bloom
- `.` = Peak bloom
- ` ` = Light (brightest)

---

## Performance

### Benchmarks

| Images | Total Size | Time (Approx) | Width |
|--------|------------|---------------|-------|
| 1 | 2 MB | <1 second | 120 |
| 10 | 20 MB | 3 seconds | 120 |
| 100 | 200 MB | 28 seconds | 120 |
| 1,000 | 2 GB | 4.5 minutes | 120 |

**Note:** Processing time scales linearly with image count and output width.

### Large Batch Processing

For thousands of images, consider using FlowerOS GPU batch system:

```bash
# Future: GPU-accelerated version
flower_gpu_batch blossom /massive/image/collection/*.jpg
```

---

## Integration with FlowerOS

### As Part of Runner System

The `flower_blossom` tool follows FlowerOS Runner System design:

1. **Input** - Images (any supported format)
2. **Operation** - Convert to ASCII (pluggable algorithm)
3. **Output** - ANSI text files (any format)

### Botanical Naming

Following FlowerOS conventions:

| Operation | Botanical Term | Traditional Term |
|-----------|---------------|------------------|
| Load image | "Gather seed" | Read file |
| Convert | "Blooming" | Processing |
| Save ASCII | "Harvest blossom" | Write output |

### Environment Variables

```bash
# Set output directory (default: ascii_out)
export FLOWEROS_ASCII_OUTPUT=/custom/path/

# Set default width (default: prompt user)
export FLOWEROS_ASCII_WIDTH=120

# Enable debug mode
export FLOWEROS_DEBUG=1
```

---

## Use Cases

### 1. Profile Pictures / Avatars

```bash
python3 flower_blossom.py avatar.jpg
cat ascii_out/avatar.ansi.txt >> ~/.bash_profile
```

### 2. Server MOTD (Message of the Day)

```bash
python3 flower_blossom.py logo.png
sudo cp ascii_out/logo.ansi.txt /etc/motd
```

### 3. Documentation Art

```bash
python3 flower_blossom.py diagram.png
cat ascii_out/diagram.ansi.txt >> README.md
```

### 4. Batch Convert Photo Album

```bash
python3 flower_blossom.py ~/Photos/Vacation2024/
# Creates ASCII version of every photo
```

### 5. ASCII Art Gallery

```bash
python3 flower_blossom.py /art/collection/*.png
# View slideshow:
for f in ascii_out/*.ansi.txt; do clear; cat "$f"; sleep 3; done
```

---

## Troubleshooting

### Issue: Colors Don't Display

**Cause:** Terminal doesn't support 256-color  
**Solution:**
```bash
# Check TERM variable
echo $TERM  # Should be xterm-256color or similar

# Set if needed
export TERM=xterm-256color
```

### Issue: Characters Look Stretched

**Cause:** Output width too large for terminal  
**Solution:**
- Use smaller width (80 or 120)
- Resize terminal window
- Use full-screen terminal

### Issue: "Missing dependency: Pillow"

**Solution:**
```bash
# Install Pillow
sudo apt-get install python3-pil
# Or
python3 -m pip install pillow
```

### Issue: Image Not Found

**Solution:**
```bash
# Use absolute paths
python3 flower_blossom.py /full/path/to/image.jpg

# Or relative from current directory
python3 flower_blossom.py ./images/photo.png
```

---

## Advanced Usage

### Custom Character Ramp

Edit `flower_blossom.py` and modify:

```python
# Default
RAMP = "@%#*+=-:. "

# Alternative (more contrast)
RAMP = "█▓▒░ "

# Alternative (ASCII only)
RAMP = "MWNXK0Okxdolc:;,. "
```

### Custom Color Palette

Edit the `PASTEL` list:

```python
# Default (pastel garden)
PASTEL = [231, 230, 229, ...]

# Custom (your colors)
PASTEL = [196, 202, 208, 214, 220, 226, ...]
```

### Scripting / Automation

```bash
#!/bin/bash
# Batch convert all images in directory

for dir in /photos/*/; do
    echo "Processing: $dir"
    python3 flower_blossom.py "$dir"
done

echo "All albums converted to ASCII!"
```

---

## Examples Gallery

### Portrait (Width: 80)

```
                    :::::::::::::::::::::::
                :::::::::::::::::::::::::::::::
             :::::::::::::::::::::::::::::::::::::
           ::::::::::::-----------:::::::::::::::::::
         ::::::::::::---------------:::::::::::::::::
        :::::::::::-------------------:::::::::::::::
       :::::::::---++++++++++++++++++---:::::::::::::
      ::::::::--++++++++++++++++++++++++--::::::::::::
     :::::::--+++++++++++###########++++++-::::::::::::
     ::::::--+++++++++###############++++++-:::::::::::
    ::::::--+++++++####################++++--::::::::::
    :::::--+++++++#####################++++-:::::::::::
    :::::-+++++########################++++:::::::::::
...
```

### Landscape (Width: 120)

```
                                                    ::::::::::::::::::::::::::::::::::::::::::::::::
                                              :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                                         ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                                    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                               :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
...
```

---

## Comparison with Other Tools

| Tool | Colors | Batch | Format | Speed |
|------|--------|-------|--------|-------|
| `jp2a` | B&W | ❌ | JPG only | Fast |
| `asciiart` | 16-color | ❌ | Limited | Medium |
| **flower_blossom** | **256-color** | **✅** | **All formats** | **Medium** |
| `img2txt` | 16-color | ❌ | Most | Fast |

**FlowerOS Advantage:**
- More colors (256 vs 16)
- Batch processing (directory support)
- All image formats (Pillow support)
- Integrated with FlowerOS ecosystem

---

## Future Enhancements

### Planned Features

- [ ] GPU acceleration for massive batches
- [ ] Animated GIF support (frame-by-frame)
- [ ] True-color (24-bit) mode
- [ ] HTML output (for web display)
- [ ] Configurable palettes (themes)
- [ ] Interactive preview mode
- [ ] Integration with `flower_animate` for slideshow

---

## See Also

- `flower_banner` - Generate text banners
- `flower_animate` - Play ASCII animations
- `flower_visual` - Visual output system
- `UNIVERSAL_CAPABILITIES.md` - FlowerOS compute engine
- `GPU_FEATURES.md` - GPU batch processing

---

**🌸 FlowerOS v1.3.0 - Image to ASCII Converter**  
*Every image is a seed waiting to bloom into ASCII art* 🌸⚡

---

## Quick Reference

```bash
# Install
sudo apt-get install python3-pil

# Run
python3 flower_blossom.py <images>

# View
less -R ascii_out/*.ansi.txt

# Batch
python3 flower_blossom.py /photos/*.jpg

# Custom width
python3 flower_blossom.py image.png
# → Enter: 160
```

**Every image blooms into art. 🌸**
