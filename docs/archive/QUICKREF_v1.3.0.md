# FlowerOS v1.3.0 Quick Reference

## Installation Commands

```bash
# Standard User Install (Removable)
bash build.sh && bash install.sh && source ~/.bashrc

# Permanent System Install (Root Level)
bash build.sh && sudo bash install-permanent.sh

# Check Status
floweros-info
floweros-status
```

## File Locations

### System Install
- **Binaries:** `/opt/floweros/bin/` (in PATH)
- **Config:** `/etc/floweros/.flowerrc` (line 12 of bashrc)
- **ASCII:** `/opt/floweros/ascii/`
- **System bashrc:** `/etc/bash.bashrc` (modified at line ~12)
- **Profile.d:** `/etc/profile.d/floweros.sh`
- **User symlink:** `~/.flowerrc` → `/etc/floweros/.flowerrc`
- **User bashrc:** `~/.bashrc` (modified at line ~12)

### User Install
- **Location:** `~/FlowerOS/ascii/`
- **Config:** Lines in `~/.bashrc`

## Core Functions

```bash
flower_pick_ascii_line    # Random ASCII art
flower_banner "Text"      # Generate banner
flower_animate file.anim  # Play animation (FPS, loop)
flower_fortune [category] # Wisdom quotes
flower_colortest          # Terminal diagnostics
flower_visual [mode]      # Visual output system
```

## System Commands (v1.3.0)

```bash
floweros-info             # Show version info
floweros-status           # Show system status
floweros-reload           # Reload configuration
```

## Environment Variables

```bash
# System Paths
$FLOWEROS_ROOT            # /opt/floweros
$FLOWEROS_BIN             # /opt/floweros/bin
$FLOWEROS_LIB             # /opt/floweros/lib
$FLOWEROS_ASCII           # /opt/floweros/ascii
$FLOWEROS_CONFIG          # /etc/floweros

# Status
$FLOWEROS_LOADED          # 1 (prevents double-loading)
$FLOWEROS_VERSION         # 1.3.0
$FLOWEROS_SYSTEM_INTEGRATION  # NATIVE
$FLOWEROS_BUILD_TYPE      # PERMANENT_ROOT

# Control
$FLOWEROS_QUIET           # Set to 1 to disable auto-ASCII
```

## Configuration

### Disable for One Session
```bash
export FLOWEROS_QUIET=1
bash
```

### Check Integration
```bash
# System level
cat /etc/bash.bashrc | grep -A5 "FLOWEROS"
ls -la /etc/floweros/
ls -la /etc/profile.d/floweros.sh

# User level
ls -la ~/.flowerrc
grep "flowerrc" ~/.bashrc
```

## Removal

### User Install
```bash
bash uninstall.sh
```

### System Install (Emergency Only)
```bash
sudo bash remove-permanent.sh

# Or manually:
sudo chattr -i /etc/floweros/.flowerrc
sudo sed -i '/FLOWEROS/,/flowerrc/d' /etc/bash.bashrc
sudo rm -f /etc/profile.d/floweros.sh
sed -i '/flowerrc/d' ~/.bashrc
sudo rm -rf /opt/floweros /etc/floweros
```

## Troubleshooting

### "FlowerOS not loading"
```bash
# Check if sourced
grep "flowerrc" ~/.bashrc

# Manually source
source ~/.flowerrc

# Or from system
source /etc/floweros/.flowerrc
```

### "Permission denied"
```bash
# System install requires root
sudo bash install-permanent.sh

# Check permissions
ls -la /opt/floweros/bin/
```

### "Command not found"
```bash
# Check PATH
echo $PATH | grep floweros

# Add to PATH manually
export PATH="/opt/floweros/bin:$PATH"
```

## Examples

### Generate Banner
```bash
flower_banner "FlowerOS v1.3.0"
flower_banner -f "Welcome"
flower_banner -g "Rainbow"
```

### Play Animation
```bash
flower_animate flower.anim           # Default
flower_animate spin.anim 20          # 20 FPS
flower_animate flower.anim 10 1      # 10 FPS, loop forever
```

### Get Wisdom
```bash
flower_fortune                       # Random
flower_fortune tech                  # Tech quotes
flower_fortune zen                   # Zen wisdom
flower_fortune -l                    # List categories
```

### Visual Output
```bash
./visual demo                        # All modes
./visual bar                         # Bar chart
./visual table                       # ASCII table
./visual progress                    # Progress bars
```

## Integration Points

1. **System boot:** systemd `floweros.service`
2. **Login shell:** `/etc/profile.d/floweros.sh`
3. **Interactive bash:** `/etc/bash.bashrc` line 12
4. **User shell:** `~/.bashrc` line 12
5. **Result:** FlowerOS active in every terminal

## Version Info

```bash
# Show version
floweros-info

# Check files
cat /etc/floweros/VERSION
cat /opt/floweros/REMOVAL_WARNING.txt

# System status
floweros-status
systemctl status floweros.service
```

## Security

### File Permissions
```
/opt/floweros/       755 root:root
/opt/floweros/bin/*  755 root:root (executable)
/etc/floweros/       755 root:root
/etc/floweros/.flowerrc  644 root:root (+i immutable)
~/.flowerrc          777 (symlink, user-owned)
```

### Immutable Files
```bash
# Check immutable status
lsattr /etc/floweros/.flowerrc

# Remove immutability (if needed)
sudo chattr -i /etc/floweros/.flowerrc

# Restore immutability
sudo chattr +i /etc/floweros/.flowerrc
```

## Aliases (Auto-loaded)

```bash
alias floweros-info='cat "$FLOWEROS_CONFIG/VERSION"'
alias floweros-status='systemctl status floweros.service 2>/dev/null || echo "FlowerOS native integration active"'
alias floweros-reload='source ~/.flowerrc && echo "FlowerOS reloaded"'
```

## Build System

```bash
# Standard build
bash build.sh

# Components built:
# - random.c    → random
# - animate.c   → animate
# - banner.c    → banner
# - fortune.c   → fortune
# - colortest.c → colortest
# - visual.c    → visual (optional)
```

## Documentation

- **PERMANENT_INSTALL.md** - Complete installation guide
- **CHANGELOG_v1.3.0.md** - What's new
- **README.md** - Main documentation
- **TROUBLESHOOTING.md** - Issue resolution

---

**FlowerOS v1.3.0 - Root Integration**  
🌸 Every terminal session is a garden
