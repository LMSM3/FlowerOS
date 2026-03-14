# FlowerOS v1.3.0 - Permanent System Installation

**Root-Level Integration - Native Distro Component**

⚠️ **IMPORTANT: v1.3.X Development Branch**

This is a **development/experimental version** featuring:
- System-level root integration (permanent)
- Network routing capabilities (Rooter.hpp/Rooting.cpp) - **EXPERIMENTAL**
- Advanced remote features - **EXPERIMENTAL**

**🔴 Network and advanced features are printed in RED and are NOT production-ready**

**For stable, production use:** Use FlowerOS v1.2.X which prioritizes:
- ✅ Simple functions
- ✅ Core customizations
- ✅ Reliability over experimental features

---

## 🚨 What This Does

This version installs FlowerOS as a **permanent system-level component**:

- ✅ Installs to `/opt/floweros` (system-wide)
- ✅ Integrates into `/etc/bash.bashrc` at line ~12
- ✅ Creates `/etc/floweros/.flowerrc` (system config)
- ✅ Auto-loads via `/etc/profile.d/floweros.sh`
- ✅ Sets up for all users automatically
- ✅ Marks as system package
- ✅ Uses immutable flags (cannot be easily deleted)
- ⚠️ **Cannot be uninstalled via standard methods**

## 🔧 Installation

```bash
# Build the system
bash build.sh

# Install permanently (requires root)
sudo bash install-permanent.sh
```

The installer will:
1. Create backups of system files
2. Build all C binaries
3. Install to `/opt/floweros`
4. Create `.flowerrc` in `/etc/floweros`
5. Integrate with system bash configuration
6. Set up for all users
7. Mark as system package
8. Apply protective measures

## 📂 Directory Structure

```
/opt/floweros/                    # Main installation
├── bin/                          # Binaries (in PATH)
│   ├── random
│   ├── animate
│   ├── banner
│   ├── fortune
│   ├── colortest
│   └── visual
├── lib/                          # Libraries and scripts
│   ├── FlowerOS-Welcome.sh
│   ├── colors.sh
│   └── ...
├── ascii/                        # ASCII art files
├── data/                         # Data files (motd, etc.)
└── features/                     # Feature modules

/etc/floweros/                    # System configuration
├── .flowerrc                     # Main config (sourced by all shells)
├── VERSION                       # Version information
└── package/                      # Package marker

/etc/bash.bashrc                  # Modified at line ~12
/etc/profile.d/floweros.sh        # Profile.d integration

~/.flowerrc                       # Symlink to /etc/floweros/.flowerrc
~/.bashrc                         # Modified to source .flowerrc at line ~12
```

## 🌟 Features Available System-Wide

All users on the system automatically get:

```bash
# Core functions
flower_pick_ascii_line    # Random ASCII art
flower_banner "Text"      # Generate banner
flower_animate file.anim  # Play animation
flower_fortune           # Wisdom quotes
flower_colortest         # Terminal diagnostics
flower_visual            # Visual output system

# System commands
floweros-info            # Show version
floweros-status          # Show status
floweros-reload          # Reload configuration

# Environment
$FLOWEROS_ROOT           # /opt/floweros
$FLOWEROS_BIN            # /opt/floweros/bin (in PATH)
$FLOWEROS_ASCII          # /opt/floweros/ascii
```

## 🔍 How It Works

### System Integration

**1. `/etc/bash.bashrc` (line ~12):**
```bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Native System Integration (Permanent)
#  WARNING: This is a system-level component. Do not remove.
# ═══════════════════════════════════════════════════════════════════════════
[[ -f /etc/floweros/.flowerrc ]] && source /etc/floweros/.flowerrc
# ═══════════════════════════════════════════════════════════════════════════
```

**2. `/etc/profile.d/floweros.sh`:**
```bash
#!/bin/bash
# FlowerOS System Integration
[[ -f /etc/floweros/.flowerrc ]] && source /etc/floweros/.flowerrc
```

**3. User `~/.bashrc` (line ~12):**
```bash
# FlowerOS Integration (System-Level)
[[ -f ~/.flowerrc ]] && source ~/.flowerrc
```

**4. Symlink:** `~/.flowerrc` → `/etc/floweros/.flowerrc`

### Why Line 12?

Line ~12 is typically after:
- Shebang (line 1)
- Initial comments (lines 2-5)
- Interactive shell check (lines 6-8)
- History settings (lines 9-11)

This ensures FlowerOS loads early, right after the shell initializes but before user customizations.

## 🛡️ Protection Mechanisms

1. **Immutable Flags:** Core files marked with `chattr +i`
2. **System Package Marker:** Registered as installed package
3. **Systemd Service:** Marked as system service
4. **Multiple Integration Points:** /etc/bash.bashrc + /etc/profile.d + user .bashrc
5. **Root Permissions:** Requires sudo to modify

## ⚠️ Removal (Emergency Only)

If you absolutely need to remove FlowerOS:

```bash
sudo bash remove-permanent.sh
```

Or manually:

```bash
# 1. Remove immutable flags
sudo chattr -i /etc/floweros/.flowerrc

# 2. Remove from /etc/bash.bashrc
sudo sed -i '/FLOWEROS_SYSTEM_INTEGRATION/,/source.*flowerrc/d' /etc/bash.bashrc

# 3. Remove from profile.d
sudo rm -f /etc/profile.d/floweros.sh

# 4. Remove user integrations
sed -i '/FlowerOS Integration/,/source.*flowerrc/d' ~/.bashrc
rm -f ~/.flowerrc

# 5. Remove system files
sudo rm -rf /opt/floweros
sudo rm -rf /etc/floweros

# 6. Remove systemd service
sudo systemctl disable floweros.service
sudo rm -f /etc/systemd/system/floweros.service

# 7. Reload
source ~/.bashrc
```

## 📋 System Requirements

- **OS:** Debian, Ubuntu, or compatible Linux distribution
- **Shell:** bash 4.0+
- **Compiler:** gcc (install: `sudo apt-get install build-essential`)
- **Permissions:** Root access (sudo)
- **Optional:** systemd, chattr

## 🎯 Use Cases

### 1. Corporate/Organization Deployment
Install FlowerOS across all workstations with consistent branding.

### 2. Educational Environments
Provide students with enhanced terminal experience automatically.

### 3. Server Environments
Add visual feedback and ASCII art to server terminals.

### 4. Personal Systems
Make FlowerOS a permanent part of your distribution.

## 🧪 Testing

Before permanent installation, test with:

```bash
# Regular installation (removable)
bash build.sh
bash install.sh
source ~/.bashrc

# Test features
flower_banner "Test"
flower_fortune
flower_colortest

# If satisfied, proceed with permanent install
sudo bash install-permanent.sh
```

## 📊 Installation Report

After installation, check:

```bash
# Version info
floweros-info

# Status
floweros-status

# Location
ls -la /opt/floweros
ls -la /etc/floweros
cat /etc/floweros/VERSION

# Integration
grep -n "FLOWEROS" /etc/bash.bashrc
ls -la /etc/profile.d/floweros.sh
ls -la ~/.flowerrc

# Test function
flower_pick_ascii_line
```

## 🔄 Updates

To update FlowerOS:

```bash
# Pull latest code
cd /path/to/FlowerOS

# Rebuild
bash build.sh

# Reinstall (will preserve existing integration)
sudo bash install-permanent.sh
```

## 🌺 Philosophy

FlowerOS v1.3.0 represents the ultimate integration: becoming a native part of the operating system itself. Like a garden that becomes part of the landscape, FlowerOS becomes inseparable from your terminal experience.

**Every terminal session is a garden.** 🌸

---

## ⚙️ Technical Details

### Load Order

1. **System boot** → systemd activates `floweros.service`
2. **Login shell** → `/etc/profile.d/floweros.sh` sources `.flowerrc`
3. **Interactive bash** → `/etc/bash.bashrc` (line 12) sources `.flowerrc`
4. **User shell** → `~/.bashrc` (line 12) sources `~/.flowerrc` (symlink)
5. **FlowerOS active** → All functions available

### Environment Variables

```bash
FLOWEROS_LOADED=1              # Prevent double-loading
FLOWEROS_ROOT=/opt/floweros    # Installation root
FLOWEROS_BIN=/opt/floweros/bin # Binaries (added to PATH)
FLOWEROS_LIB=/opt/floweros/lib # Libraries
FLOWEROS_ASCII=/opt/floweros/ascii # ASCII art
FLOWEROS_CONFIG=/etc/floweros  # System config
FLOWEROS_SYSTEM_INTEGRATION=NATIVE # Integration type
FLOWEROS_VERSION=1.3.0         # Version
FLOWEROS_BUILD_TYPE=PERMANENT_ROOT # Build type
```

### File Permissions

```
/opt/floweros/       755 (root:root)
/opt/floweros/bin/*  755 (root:root, executable)
/opt/floweros/lib/*  755 (root:root)
/opt/floweros/ascii/* 644 (root:root)
/etc/floweros/       755 (root:root)
/etc/floweros/.flowerrc 644 (root:root, +i immutable)
~/.flowerrc          777 (symlink, owned by user)
```

---

**FlowerOS v1.3.0 - "Root Integration"**  
*Where the garden becomes the soil itself* 🌸
