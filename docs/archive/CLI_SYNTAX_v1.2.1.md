# FlowerOS v1.2.1 - Official CLI Syntax Reference

**Last Updated:** February 07, 2026  
**Status:** Current (replaces all previous syntax docs)

---

## 🎯 Current CLI Syntax (v1.2.1)

### Build & Install Commands

#### **Recommended (v1.2.1 Multi-Distro)**

```bash
bash build-v1.2.sh          # Multi-distro builder with auto-detection
bash install-v1.2.sh        # Universal installer (bash/zsh aware)
bash debug-quick.sh         # 5-second diagnostic
```

#### **Legacy (Still Supported)**

```bash
bash build.sh               # Original builder (v1.0)
bash install.sh             # Original installer (v1.0)
compile.bat                 # Windows self-destruct installer
.\build_native.ps1          # PowerShell native builder
```

#### **Testing Commands**

```bash
bash stress-test.sh              # Full 10-test suite (~60s)
bash stress-test-parallel.sh     # Hammer test (100 workers)
bash stress-test-chaos.sh        # Chaos engineering
bash stress-test-wsl.sh          # Multi-distro WSL test
```

---

### Core Binary Syntax

#### **random** - Random Line Picker

```bash
# Binary usage
./random <directory>        # Pick random line from .ascii/.txt files

# Examples
./random .                  # Current directory
./random ~/FlowerOS/ascii   # Specific directory
```

#### **animate** - Animation Player

```bash
# Binary usage
./animate <file.anim> [fps] [loop]

# Examples
./animate flower.anim              # Default FPS, play once
./animate flower.anim 20           # 20 FPS
./animate spin.anim 30 1           # 30 FPS, loop forever
```

#### **banner** - Banner Generator

```bash
# Binary usage
./banner <text> [options]

# Examples
./banner "Hello"                   # Simple banner
./banner "FlowerOS" --fancy        # Fancy style (if implemented)
```

#### **fortune** - Wisdom Database

```bash
# Binary usage
./fortune [category]

# Examples
./fortune                   # Random category
./fortune tech              # Tech wisdom
./fortune life              # Life wisdom
```

#### **colortest** - Terminal Diagnostics

```bash
# Binary usage
./colortest                 # Run full color test
```

---

### Shell Function Syntax (After Installation)

#### **flower_pick_ascii_line** - Random ASCII

```bash
flower_pick_ascii_line      # Print random ASCII line
```

#### **flower_banner** - Generate Banners

```bash
flower_banner "Text"        # Generate banner
flower_banner "🌸 Unicode" # Unicode support
```

#### **flower_animate** - Play Animations

```bash
flower_animate <file> [fps] [loop]

# Examples
flower_animate flower.anim           # Default
flower_animate flower.anim 20        # Custom FPS
flower_animate flower.anim 10 1      # Loop mode
```

#### **flower_fortune** - Get Wisdom

```bash
flower_fortune [category]   # Get random wisdom
```

#### **flower_colortest** - Test Terminal

```bash
flower_colortest            # Run color diagnostics
```

---

### Environment Variables

```bash
# Core
export FLOWEROS_DIR="$HOME/FlowerOS/ascii"     # Installation directory
export FLOWEROS_ASCII_DIR="/custom/path"       # Custom ASCII directory
export FLOWEROS_QUIET=1                        # Disable auto-display

# Advanced
export FLOWEROS_VERSION="1.2.1"                # Version tracking
export FLOWEROS_DEBUG=1                        # Enable debug output
```

---

## 📊 Output Formats

### Standard Output (Current)

```
$ flower_pick_ascii_line
A flower does not think of competing with the flower next to it.
```

### Verbose Output (Debug)

```
$ FLOWEROS_DEBUG=1 flower_pick_ascii_line
[DEBUG] Loading from: /home/user/FlowerOS/ascii
[DEBUG] Found 5 files
[DEBUG] Selected: wisdom.txt, line 3
A flower does not think of competing with the flower next to it.
```

---

## ❌ Deprecated Syntax (DO NOT USE)

### Removed in v1.2.1
- ❌ `compile.ps1` (replaced by `build_native.ps1`)
- ❌ Manual pipefail handling (now automatic in `build-v1.2.sh`)
- ❌ Hardcoded gcc paths (now auto-detected)

### Deprecated but Still Works (Legacy Support)
- ⚠️ `build.sh` without distro detection (use `build-v1.2.sh`)
- ⚠️ `install.sh` without zsh support (use `install-v1.2.sh`)

---

## 🆕 New in v1.2.1

✅ Multi-distro detection  
✅ WSL auto `.exe` handling  
✅ Bash/Zsh shell detection  
✅ Automated stress testing  
✅ 5-second debugging  
✅ Build time reporting  

---

## 📚 See Also

- `QUICKSTART_v3.md` - Quick start guide
- `CHANGELOG_v1.2.1.md` - What's new
- `TROUBLESHOOTING.md` - Common issues
