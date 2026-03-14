# Place your images here to convert to ASCII art

Supported formats:
- PNG (.png)
- JPEG (.jpg, .jpeg)
- GIF (.gif)
- BMP (.bmp)

## Quick Start

1. Copy images to this directory
2. Run: `bash process-images.sh`
3. Find ASCII art in `motd/ascii-output/`

## Examples

```bash
# Copy your image
cp ~/Pictures/flower.jpg motd/Import/

# Process all images
bash process-images.sh

# View result
cat motd/ascii-output/flower.ascii
```

## Tips

- Use high contrast images for best results
- Logos work great at 60-80 columns wide
- Photos look good at 120-140 columns
- Try both pastel and hash modes

🌸 **Every image can become terminal art!**
