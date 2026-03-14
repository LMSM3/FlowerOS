# FlowerOS ASCII System

**Advanced 3-script architecture with C subsystems, ASCII animations, visual output, and integrated features**

**Version:** 1.3.0 (Root Integration) - 🔴 **EXPERIMENTAL**  
**Status:** Development Branch - Not Production Ready

⚠️ **IMPORTANT VERSION NOTICE**

- **v1.3.X** = 🔴 **EXPERIMENTAL** - Network routing, system integration, advanced features
  - Network features printed in RED
  - Permanent system installation
  - NOT for production use

- **v1.2.X** = ✅ **STABLE** - Production ready, simple functions prioritized
  - Recommended for daily use
  - User-level installation
  - Well-tested and documented

**📖 See `februarylogs/VERSION_POLICY.md` for complete version differences**

---

## Overview

```
compile.bat  →  build.sh  →  install.sh  →  ~/.bashrc
                    ↓
        ┌───────────┴───────────┐
        ↓           ↓           ↓
    random.c    animate.c   banner.c
    fortune.c   colortest.c
        ↓
    ~/FlowerOS/ascii/
        ├── random      (binary)
        ├── animate     (binary)
        ├── banner      (binary)
        ├── fortune     (binary)
        ├── colortest   (binary)
        ├── *.ascii     (data)
        ├── *.txt       (data)
        └── *.anim      (animations)
```

---

## Quick Start

### Stable Version (v1.2.X - Recommended for Production)

```bash
# User-level installation (removable)
bash build.sh
bash install.sh
source ~/.bashrc
```

### Experimental Version (v1.3.X - Development Only)

```bash
# System-level permanent installation
bash build.sh
sudo bash install-permanent.sh  # ⚠️ PERMANENT! Cannot be easily removed
source ~/.bashrc

# Check advanced features (shown in RED)
flower_advanced_check
```

**⚠️ v1.3.X includes experimental features:**
- 🔴 Network routing (Rooter.hpp/Rooting.cpp)
- 🔴 **GPU batch processing for HPC workloads** ⚡
- 🔴 System-level integration

**All advanced features are printed in RED to indicate experimental status**


### 🪟 Quick Network Test (v1.3.X)

```bash
# One-command relay test with auto buddy windows
bash relay-auto-test.sh

# Opens 3 terminals automatically: Master → Relay → Worker
# Press Ctrl+C to close all windows
```

**See `februarylogs/BUDDY_WINDOWS.md` for complete buddy window documentation**

---

## 🌸 Features

### **Core Subsystems (C)**

| Binary | Purpose | Usage |
|--------|---------|-------|
| `random` | Fast line picker from `.ascii`/`.txt` | Auto-runs on shell start |
| `animate` | ASCII animation player | `flower_animate flower.anim` |
| `banner` | Dynamic banner generator | `flower_banner "Text"` |
| `fortune` | Wisdom database | `flower_fortune tech` |
| `colortest` | Terminal diagnostics | `flower_colortest` |
| `visual` | **NEW!** Visual output system | `./visual demo` |

### **GPU Batch Processing** 🆕 (v1.3.X EXPERIMENTAL)

**FlowerOS isn't just an OS layer—it's for HPC!**

GPU-accelerated batch processing for simple functions:

```bash
# Check GPU status
flower_gpu_status

# Batch generate 1000 ASCII variations (54x faster)
flower_gpu_batch ascii 1000

# Generate 500 banners (53x faster)
flower_gpu_batch banner "FlowerOS" 500 --styles all

# Colorize ASCII files (58x faster)
flower_gpu_batch colorize *.ascii --palette rainbow

# Render animations (286x faster)
flower_gpu_batch animate *.anim --fps 60 --export-frames

# Mass fortune generation (42x faster)
flower_gpu_batch fortune --generate 10000
```

**🔴 Status: EXPERIMENTAL (v1.3.X only)**
- Requires CUDA-capable GPU
- Hardware detection via special hardware layer
- 10-300x speedup over CPU
- Not production-ready (use v1.2.X for production)

**See `februarylogs/GPU_FEATURES.md` for complete documentation**

### **Visual Output System** 🆕 (v1.2.4)

Real-time visualizations after batch operations:

```bash
# Build visual system
gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c

# See all visualizations
./visual demo

# Individual modes
./visual bar          # Bar charts
./visual table        # ASCII tables
./visual progress     # Progress bars
./visual live         # Live dashboard

# Auto-visualize commands
bash lib/visualize.sh build    # Build with visualization
bash lib/visualize.sh test     # Test with visualization
```

**Features:**
- Bar charts with auto-scaling
- ASCII tables with box-drawing
- Progress bars with color coding
- Sparklines (inline mini-graphs)
- Live updating dashboards
- Animated spinners

See `februarylogs/VISUAL_OUTPUT_GUIDE.md` for complete documentation.

### **Shell Functions** (auto-loaded)

```bash
flower_pick_ascii_line    # Random ASCII line
flower_banner "Text"      # Generate banner
flower_animate file.anim  # Play animation
flower_fortune [category] # Get wisdom
flower_colortest          # Test terminal
```

### **Animation System**

Self-encoded `.anim` format:
```
#FPS=10
#LOOP=1
---FRAME---
<frame 1>
---FRAME---
<frame 2>
```

**Included animations:**
- `flower.anim` - Blooming flower
- `spin.anim` - Spinning loader

---

## 📦 Installation

### **Method 1: Standard User Installation (Recommended)** ✅
```bash
bash build.sh       # Compile all 5 C binaries
bash install.sh     # Install to ~/FlowerOS/ascii/
source ~/.bashrc    # Reload shell
```
Installs to `~/FlowerOS/ascii/` with `.bashrc` integration. Fully removable with `bash uninstall.sh`.

### **Method 2: Permanent System Installation (Root Level)**
```bash
bash build.sh                    # Compile binaries first (optional — installer also builds)
sudo bash install-permanent.sh   # Install to /opt/floweros
```
**What this does:**
- Installs to `/opt/floweros` (system-wide)
- Creates `/etc/floweros/.flowerrc` (sourced at line ~12 of bashrc)
- Integrates with `/etc/bash.bashrc` and `/etc/profile.d`
- Available for all users automatically
- Marks as system package (like native distro component)
- **Cannot be easily uninstalled** (permanent integration)
- ⚠️ `uninstall.sh` does **not** undo this method — see `februarylogs/PERMANENT_INSTALL.md` for manual removal

📖 **See `februarylogs/PERMANENT_INSTALL.md` for complete documentation**

### **Method 3: Interactive Guided Deployment** 🆕
```bash
bash deploy.sh      # Step-by-step interactive wizard
```
Walks you through choosing install type, network features, and GPU features with prompts at each step.

### **Method 4: Self-Destructing (Windows)**
```cmd
compile.bat         # Compiles, installs, deletes itself
```
Requires Git Bash or WSL for the install step.

### **Method 5: Native Windows Build**
```powershell
.\build_native.ps1  # PowerShell-native build (requires gcc via MSYS2/MinGW)
bash install.sh     # Then install (requires Git Bash or WSL)
```

### **Method 6: Test Without Self-Destruct**
```cmd
test_compile.bat    # Test build without deleting itself
```

---

## USER GUIDE (v1.2.X) demos and usage examples


```bash
# Automatic - just open new terminal
✿ FlowerOS blooming with power
```

### **Generate Banners**
```bash
flower_banner "FlowerOS"
flower_banner -f "Welcome"      # Flower style
flower_banner -g "Rainbow"      # Gradient
flower_banner -b "Box"          # Box with flowers
```

### **Play Animations**
```bash
flower_animate flower.anim      # Play once
flower_animate flower.anim 20   # 20 FPS
flower_animate spin.anim 30 1   # 30 FPS, loop forever
```

### **Get Wisdom**
```bash
flower_fortune              # Random category
flower_fortune tech         # Tech wisdom
flower_fortune flower       # Flower quotes
flower_fortune zen          # Zen wisdom
flower_fortune -l           # List categories
```

### **Test Terminal**
```bash
flower_colortest            # Full diagnostics
```

### **Quiet Mode**
```bash
export FLOWEROS_QUIET=1     # Disable auto-ASCII
```

## 📝 Creating Animations

```bash
cat > myanimation.anim <<'EOF'
#FPS=15
#LOOP=1
---FRAME---
  Frame 1
---FRAME---
  Frame 2
EOF

flower_animate myanimation.anim
```

---

## Advanced Setup and customization options.

### **Custom Directory**
```bash
export FLOWEROS_ASCII_DIR="$HOME/custom/path"
```

### **Add New Wisdom**
Edit `fortune.c`, add to arrays, rebuild:
```c
static const char *wisdom_custom[] = {
  "Your wisdom here",
  NULL
};
```

### **Rebuild All**
```bash
cd ~/FlowerOS/ascii/
bash build.sh
```

---

## 🗑️ Uninstall 🗑️

### **User Installation (Method 1)**
```bash
bash uninstall.sh
```
- Creates `~/.bashrc` backup
- Removes FlowerOS block
- Optionally deletes `~/FlowerOS/`

### **Permanent Installation (Method 2)**
⚠️ `uninstall.sh` does **not** cover permanent installs. See `/opt/floweros/REMOVAL_WARNING.txt` or `februarylogs/PERMANENT_INSTALL.md` for manual removal steps.

---

## 📚 Documentation

All documentation has been moved to `februarylogs/` to keep the root clean.

### Quick Reference
- **`februarylogs/CLI_SYNTAX_v1.2.1.md`** - Complete CLI command reference
- **`februarylogs/VISUAL_OUTPUT_GUIDE.md`** - Visual system guide
- **`februarylogs/CHANGELOG_v1.2.4.md`** - What's new in v1.2.4
- **`februarylogs/GPU_FEATURES.md`** - GPU batch processing docs
- **`februarylogs/BUDDY_WINDOWS.md`** - Buddy window testing system

### Technical Docs
- **`februarylogs/ARCHITECTURE.md`** - System design
- **`februarylogs/FEATURES.md`** - Feature documentation
- **`februarylogs/TROUBLESHOOTING.md`** - Issue resolution
- **`februarylogs/NETWORK_ROUTING.md`** - Network routing system
- **`februarylogs/PERMANENT_INSTALL.md`** - Permanent install details

### Version History
- **`februarylogs/CHANGELOG_v1.3.0.md`** - v1.3.0 experimental
- **`februarylogs/CHANGELOG_v1.2.4.md`** - v1.2.4 visual system
- **`februarylogs/CHANGELOG_v1.2.0.md`** - v1.2.0 stable
- **`februarylogs/VERSION_POLICY.md`** - Version differences

### Scripts Location
- **Core scripts:** Root directory
- **Archived scripts:** `~/bin_F/` (see `~/bin_F/INDEX.md`)

---

## What's New in v1.2.4

### Visual Output System
Real-time visualizations with bar charts, tables, progress bars, sparklines, and live dashboards.

### Complete Documentation
Official CLI syntax reference and visual system guide.

### Clean Structure
60% reduction in root directory clutter (33 scripts → 14 core scripts).

### Archive System
21 legacy scripts preserved in `~/bin_F/` for reference and emergency use.

See `februarylogs/CHANGELOG_v1.2.4.md` for complete details.

---

**🌺 Flower Garden Philosophy 🌺**

**Simple. Detached. Automatic. Powerful. Visual.**

Every terminal session is a garden. 🌸
