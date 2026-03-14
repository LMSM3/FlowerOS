# FlowerOS MOTD System

**Display beautiful ASCII art when you open your terminal**

---

## Ideal Terminal Features

- **Auto-sizing**: Automatically selects small/medium/large ASCII art based on terminal width
- **Random selection**: Shows a different image each time you open a terminal
- **12 pre-rendered images**: Ready to use (01-12)
- **Manual control**: Commands to show specific images, disable/enable, etc.
- **System info**: Optional system information display 

### **Quick Install**

```bash
# 1. Copy motd-bashrc.sh content to your ~/.bashrc
cat ~/FlowerOS/motd/motd-bashrc.sh >> ~/.bashrc

# 2. Reload your bashrc
source ~/.bashrc

# 3. Test it!
motd
```

### Manual Installation

Add to the end of your `~/.bashrc`:

```bash
# ============================================================================
# FlowerOS MOTD Integration
# ============================================================================
export FLOWEROS_MOTD_ENABLED=1
export FLOWEROS_MOTD_DIR="${HOME}/FlowerOS/motd/ascii-output"
export FLOWEROS_MOTD_SCRIPT="${HOME}/FlowerOS/motd/show-motd.sh"

# MOTD display function
floweros_motd() {
    if [ "$FLOWEROS_MOTD_ENABLED" != "1" ]; then
        return
    fi
    
    if [ ! -f "$FLOWEROS_MOTD_SCRIPT" ]; then
        return
    fi
    
    # Only show on interactive shells
    if [[ $- == *i* ]]; then
        bash "$FLOWEROS_MOTD_SCRIPT" random
    fi
}

# Auto-display MOTD on new shell
if [ -z "$FLOWEROS_NO_AUTO_MOTD" ]; then
    floweros_motd
fi

# Manual MOTD commands
alias motd='bash "${FLOWEROS_MOTD_SCRIPT}" random'
alias motd-info='bash "${FLOWEROS_MOTD_SCRIPT}" info'
alias motd-list='bash "${FLOWEROS_MOTD_SCRIPT}" list'
alias motd-off='export FLOWEROS_MOTD_ENABLED=0'
alias motd-on='export FLOWEROS_MOTD_ENABLED=1'

# Show specific MOTD by number
motd-show() {
    if [ -z "$1" ]; then
        echo "Usage: motd-show <number>"
        echo "Example: motd-show 01"
        return 1
    fi
    bash "${FLOWEROS_MOTD_SCRIPT}" "$1"
}

export -f motd-show
```

---

## 🎯 Usage

### View Random MOTD
```bash
motd
```

### View Specific MOTD
```bash
motd-show 01   # Show MOTD #1
motd-show 05   # Show MOTD #5
motd-show 12   # Show MOTD #12
```

### List Available MOTDs
```bash
motd-list
```

### Show System Information
```bash
motd-info
```

### Disable/Enable Auto-MOTD
```bash
motd-off   # Disable automatic MOTD display
motd-on    # Re-enable automatic MOTD display
```

### Temporary Disable (One Session)
```bash
FLOWEROS_NO_AUTO_MOTD=1 bash
```

---

## 📐 Terminal Width Auto-Sizing

The MOTD system automatically selects the appropriate size:

- **< 80 columns**: Small (60 cols)
- **80-139 columns**: Medium (120 cols)
- **≥ 140 columns**: Large (160 cols)

---

## 🖼️ Available Images

You currently have **12 pre-rendered images** (01-12), each in 3 sizes:

- `01-small.ascii`, `01-medium.ascii`, `01-large.ascii`
- `02-small.ascii`, `02-medium.ascii`, `02-large.ascii`
- ... through ...
- `12-small.ascii`, `12-medium.ascii`, `12-large.ascii`

Plus hash-mode alternatives (`01-hash.ascii`, etc.)

---

## 🎨 Adding Custom Images

### 1. Place Your Image
```bash
cp yourimage.png ~/FlowerOS/motd/Import/
```

### 2. Generate ASCII Art

Using the FlowerOS build-motd script:
```bash
cd ~/FlowerOS
bash build-motd.ps1  # PowerShell
# OR
bash build-motd.sh   # Bash
```

This generates:
- `yourimage-small.ascii` (60 cols)
- `yourimage-medium.ascii` (120 cols)
- `yourimage-large.ascii` (160 cols)
- `yourimage-hash.ascii` (alternative style)

### 3. Use Your Custom MOTD
```bash
motd-show yourimage
```

---

## 🔧 Configuration

### Change Default MOTD Directory
```bash
export FLOWEROS_MOTD_DIR="/path/to/your/motd/folder"
```

### Change Default Image
Edit `show-motd.sh` and change:
```bash
DEFAULT_MOTD="01"  # Change to your preferred default
```

---

## 🚀 Advanced Features

### System Information Display

The MOTD system can also display system info:

```bash
motd-info
```

Shows:
- Hostname
- Uptime
- Logged-in users
- System load average

### Integration with SSH

Add to `/etc/ssh/sshd_config`:
```
PrintMotd no
```

Then add to `/etc/update-motd.d/99-floweros`:
```bash
#!/bin/bash
/home/youruser/FlowerOS/motd/show-motd.sh random
```

Make executable:
```bash
chmod +x /etc/update-motd.d/99-floweros
```

---

## 🛠️ Troubleshooting

### MOTD Not Showing
1. Check if script exists:
   ```bash
   ls -l ~/FlowerOS/motd/show-motd.sh
   ```

2. Make script executable:
   ```bash
   chmod +x ~/FlowerOS/motd/show-motd.sh
   ```

3. Check if MOTD is enabled:
   ```bash
   echo $FLOWEROS_MOTD_ENABLED
   ```

4. Test manually:
   ```bash
   bash ~/FlowerOS/motd/show-motd.sh random
   ```

### ASCII Art Looks Broken
- Ensure your terminal supports 256 colors
- Try a different terminal emulator
- Check terminal width: `tput cols`
- Try different size: `motd-show 01`

### Specific Image Not Found
```bash
motd-list  # Check available images
ls ~/FlowerOS/motd/ascii-output/
```

---

## 📋 File Structure

```
FlowerOS/motd/
├── show-motd.sh           # Main MOTD display script
├── motd-bashrc.sh         # Bashrc integration snippet
├── MOTD_SETUP.md          # This file
├── ascii-output/          # Pre-rendered ASCII art
│   ├── 01-small.ascii
│   ├── 01-medium.ascii
│   ├── 01-large.ascii
│   ├── 01-hash.ascii
│   ├── 02-small.ascii
│   └── ... (through 12)
├── Import/                # Place images here for conversion
└── cache/                 # Build cache
```

---

## 🌺 Tips

1. **Different MOTD per session type**: 
   ```bash
   # In ~/.bashrc (local)
   export DEFAULT_MOTD="01"
   
   # In ~/.bash_profile (login)
   export DEFAULT_MOTD="05"
   ```

2. **Time-based MOTD**:
   ```bash
   hour=$(date +%H)
   if [ $hour -lt 12 ]; then
       motd-show 01  # Morning
   elif [ $hour -lt 18 ]; then
       motd-show 05  # Afternoon
   else
       motd-show 10  # Evening
   fi
   ```

3. **Combined with fortune**:
   ```bash
   motd
   echo ""
   flower_fortune
   ```

---

## 🎉 Enjoy Your Beautiful Terminal!

Every login is now a visual experience. 🌸
