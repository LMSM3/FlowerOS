# FlowerOS Advanced System - Complete Feature Guide

## 🎯 All Features at a Glance

```
5 C Subsystems:
├── random      Random line picker (core)
├── animate     ASCII animation engine
├── banner      Dynamic banner generator
├── fortune     Wisdom database (3 categories)
└── colortest   Terminal diagnostics

8 Shell Functions:
├── flower_pick_ascii_line     Core random picker
├── flower_banner              Generate styled banners
├── flower_animate             Play .anim files
├── flower_fortune             Get categorized wisdom
└── flower_colortest           Terminal diagnostics

3 Installation Methods:
├── compile.bat                Self-destructing (Windows)
├── build.sh + install.sh      Manual (All platforms)
└── compile.sh                 Simple compile only
```

---

## 📚 Detailed Usage

### **1. Random Line Picker (`random`)**

**Auto-runs on every new terminal**

Manual usage:
```bash
flower_pick_ascii_line
# or direct:
~/FlowerOS/ascii/random ~/FlowerOS/ascii/
```

**How it works:**
- Scans `*.ascii` and `*.txt` files
- Uses `/dev/urandom` for true randomness
- Falls back to shell if binary missing
- Exit code 2 = "use shell fallback"

**Add your own quotes:**
```bash
echo "New wisdom" >> ~/FlowerOS/ascii/myquotes.txt
```

---

### **2. Animation Player (`animate`)**

**Format:** `.anim` files

**Basic usage:**
```bash
flower_animate flower.anim          # Play once
flower_animate flower.anim 20       # 20 FPS
flower_animate spin.anim 30 1       # 30 FPS, loop forever
```

**Direct binary:**
```bash
~/FlowerOS/ascii/animate ~/FlowerOS/ascii/flower.anim
```

**Create custom animations:**
```bash
cat > explosion.anim <<'EOF'
#FPS=30
#LOOP=0
---FRAME---
    .
---FRAME---
   .*.
---FRAME---
  .***.
---FRAME---
 *******
---FRAME---
  *****
---FRAME---
   ***
---FRAME---
    *
EOF

flower_animate explosion.anim
```

**Animation format:**
```
#FPS=10           # Frames per second (directive)
#LOOP=1           # 0=once, 1=forever (directive)
---FRAME---       # Frame delimiter
<frame content>   # ASCII art for this frame
---FRAME---       # Next frame
<frame content>
```

**Features:**
- Clear screen at start
- Cursor home positioning (fast refresh)
- Per-frame timing support
- Loop control
- Command-line FPS override

---

### **3. Banner Generator (`banner`)**

**4 Styles:**

**Simple (default):**
```bash
flower_banner "FlowerOS"
# Output:
✿━━━━━━━━━━━━━✿
✿   FlowerOS   ✿
✿━━━━━━━━━━━━━✿
```

**Flower decoration:**
```bash
flower_banner -f "Welcome"
# Output:
✿ ❀ ✾ 
Welcome
✾ ❀ ✿ 
```

**Gradient:**
```bash
flower_banner -g "Rainbow"
# Output: (each letter different color)
```

**Box:**
```bash
flower_banner -b "Message"
# Output:
✿────────────❀
│  Message  │
✾────────────✻
```

**With custom color:**
```bash
flower_banner -c 31 "Red Text"      # Red (31)
flower_banner -c 32 "Green Text"    # Green (32)
flower_banner -c 36 "Cyan Text"     # Cyan (36)
```

**Color codes:**
- 31 = Red
- 32 = Green
- 33 = Yellow
- 34 = Blue
- 35 = Magenta
- 36 = Cyan

---

### **4. Fortune System (`fortune`)**

**3 built-in categories:**

**Tech wisdom:**
```bash
flower_fortune tech
# "The best code is no code at all."
# "Premature optimization is the root of all evil. - Donald Knuth"
```

**Flower quotes:**
```bash
flower_fortune flower
# "A flower does not think of competing with the flower next to it."
```

**Zen wisdom:**
```bash
flower_fortune zen
# "The obstacle is the path."
```

**Random category:**
```bash
flower_fortune
```

**List all:**
```bash
flower_fortune -l
# Available categories:
#   tech       (5 entries)
#   flower     (5 entries)
#   zen        (5 entries)
```

**Extend fortune.c:**
```c
// Add this to fortune.c
static const char *wisdom_custom[] = {
  "Your custom wisdom",
  "Another quote",
  NULL  // Always end with NULL
};

// Add to categories array
static category_t categories[] = {
  {"tech", wisdom_tech},
  {"flower", wisdom_flower},
  {"zen", wisdom_zen},
  {"custom", wisdom_custom},  // New category
  {NULL, NULL}
};
```

Then rebuild:
```bash
cd ~/FlowerOS/ascii/
gcc -O2 -std=c11 -Wall -Wextra -o fortune fortune.c
```

---

### **5. Color Test (`colortest`)**

**Terminal diagnostics:**
```bash
flower_colortest
```

**Output:**
- Terminal info (TERM, COLORTERM, size)
- Basic 16 colors (30-37, 90-97)
- Background colors (40-47)
- Full 256-color palette
- Unicode flower symbols
- Box drawing characters

**Use cases:**
- Check color support before deploying
- Debug terminal issues
- Verify Unicode rendering
- Test SSH/remote terminals

---

## 🔧 Environment Variables

```bash
# Custom install directory
export FLOWEROS_ASCII_DIR="$HOME/custom/path"

# Disable auto-ASCII on shell start
export FLOWEROS_QUIET=1

# Then reload
source ~/.bashrc
```

---

## 🎨 Integration Examples

### **In Shell Scripts**

```bash
#!/usr/bin/env bash
source ~/.bashrc  # Load FlowerOS functions

flower_banner -g "Deployment Script"
echo ""

flower_fortune tech
echo ""

# Your script logic...

flower_banner -f "Complete!"
```

### **In Login Motd**

```bash
# /etc/profile.d/floweros.sh
if [[ -f "$HOME/.bashrc" ]]; then
  source "$HOME/.bashrc"
  flower_banner "Welcome $(whoami)"
  flower_fortune
fi
```

### **In Git Hooks**

```bash
# .git/hooks/post-commit
#!/bin/bash
source ~/.bashrc
flower_banner -f "Commit Successful"
flower_fortune tech
```

### **Terminal Multiplexer (tmux)**

```bash
# ~/.tmux.conf
set-option -g default-command "bash -c 'source ~/.bashrc && flower_fortune && exec bash'"
```

---

## 🚀 Performance Notes

**C subsystems are FAST:**
- `random`: ~0.5ms on 1000 lines
- `animate`: 60 FPS capable
- `banner`: Instant (<1ms)
- `fortune`: In-memory, instant

**Shell fallback:**
- `flower_pick_ascii_line`: ~10-50ms (depends on file count)

**Optimization tips:**
- Use C binaries when available
- Keep `.ascii` files small (<10KB each)
- Limit animation frames to <100 per file
- Use `FLOWEROS_QUIET=1` for non-interactive scripts

---

## 📦 Distribution

**Share your setup:**
```bash
# Package it
tar -czf floweros-system.tar.gz \
  random.c animate.c banner.c fortune.c colortest.c \
  build.sh install.sh uninstall.sh \
  *.ascii *.txt *.anim \
  README.md FEATURES.md

# Install elsewhere
tar -xzf floweros-system.tar.gz
cd floweros-system
bash build.sh && bash install.sh
```

---

## 🌺 Every feature is a petal. Every terminal is a garden.
