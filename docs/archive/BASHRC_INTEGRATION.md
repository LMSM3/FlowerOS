# FlowerOS .bashrc Integration Guide

**Fix your .bashrc and add FlowerOS subsystems!**

---

## 🔧 Step 1: Fix Syntax Error (Line 521)

Open ~/.bashrc and find line 521:
```bash
nano ~/.bashrc
# Go to line 521 (Ctrl+_ then type 521)
```

**Change from:**
```bash
for lib in /build/*.so* 2>/dev/null; do
```

**To:**
```bash
for lib in /build/*.so* 2>/dev/null; do
```

Make sure there's a space before `do`. Save with `Ctrl+O`, exit with `Ctrl+X`.

---

## 🌸 Step 2: Add FlowerOS (Copy-Paste This)

Open your .bashrc:
```bash
nano ~/.bashrc
```

Scroll to the end and paste this:

```bash

# ═══════════════════════════════════════════════════════════════════════════
#  🌸 FlowerOS v1.2.0 - Professional Terminal Experience
# ═══════════════════════════════════════════════════════════════════════════

# FlowerOS configuration
export FLOWEROS_DIR="/mnt/c/Users/Liam/Desktop/FlowerOS"

# Load user preferences
if [ -f "$HOME/.floweros/preferences.conf" ]; then
    source "$HOME/.floweros/preferences.conf"
fi

# Apply theme (if enabled)
if [ "${FLOWEROS_THEME_AUTO_APPLY:-true}" = "true" ] && [ -n "$PS1" ]; then
    source "$FLOWEROS_DIR/features/v1.1/theming-pro/FlowerOS-Bash.sh"
fi

# Show welcome screen (MOTD with ASCII art)
if [ "${FLOWEROS_MOTD_ENABLED:-true}" = "true" ] && [ -n "$PS1" ]; then
    if [ -z "$FLOWEROS_WELCOME_SHOWN" ]; then
        export FLOWEROS_WELCOME_SHOWN=1
        
        # Use FlowerOS welcome screen
        if [ -f "$FLOWEROS_DIR/features/v1.2/visual-experience/FlowerOS-Welcome.sh" ]; then
            source "$FLOWEROS_DIR/features/v1.2/visual-experience/FlowerOS-Welcome.sh"
            floweros_welcome "${FLOWEROS_WELCOME_STYLE:-auto}"
        fi
    fi
fi

# FlowerOS aliases
alias flower='floweros-tree'
alias fconf='floweros-config'
alias fbuild='cd $FLOWEROS_DIR && bash build-motd.sh'
alias ftest='cd $FLOWEROS_DIR && bash test-all.sh'

# 🌺 FlowerOS: Every terminal session is a garden 🌺
```

Save and exit.

---

## ✅ Step 3: Reload Bash

```bash
source ~/.bashrc
```

---

## 🎯 What You Get

### **Theme System** (Subsystem 1)
- Auto-applies professional git-integrated theme
- 2-line prompt with branch status
- Beautiful colors

### **MOTD with ASCII Art** (Subsystem 2)
- Beautiful FlowerOS ASCII logo
- System information display
- Shows on every new terminal

### **New Aliases**
```bash
flower     # Show FlowerOS structure
fconf      # Configure preferences
fbuild     # Build ASCII art from images
ftest      # Run all tests
```

---

## 🎨 Customize

### Change Theme
```bash
floweros-config set FLOWEROS_THEME tokyo-night
source ~/.bashrc
```

### Change MOTD Size
```bash
floweros-config set FLOWEROS_WELCOME_STYLE small   # or medium, large, full
source ~/.bashrc
```

### Disable MOTD
```bash
floweros-config set FLOWEROS_MOTD_ENABLED false
source ~/.bashrc
```

### Use Custom MOTD
```bash
# Build your own ASCII art
cd /mnt/c/Users/Liam/Desktop/FlowerOS
bash build-motd.sh

# Set custom MOTD
floweros-config set FLOWEROS_MOTD_CUSTOM "$HOME/FlowerOS/motd/ascii-output/yourimage-medium.ascii"
source ~/.bashrc
```

---

## 🐛 Troubleshooting

### "command not found: floweros-tree"
```bash
cd /mnt/c/Users/Liam/Desktop/FlowerOS
sudo install -m 755 tree.sh /usr/local/bin/floweros-tree
```

### "command not found: floweros-config"
```bash
cd /mnt/c/Users/Liam/Desktop/FlowerOS
sudo install -m 755 floweros-config.sh /usr/local/bin/floweros-config
```

### Welcome screen doesn't show
```bash
# Check if file exists
ls -l /mnt/c/Users/Liam/Desktop/FlowerOS/features/v1.2/visual-experience/FlowerOS-Welcome.sh

# Test manually
source /mnt/c/Users/Liam/Desktop/FlowerOS/features/v1.2/visual-experience/FlowerOS-Welcome.sh
floweros_welcome medium
```

### Theme doesn't apply
```bash
# Test manually
source /mnt/c/Users/Liam/Desktop/FlowerOS/features/v1.1/theming-pro/FlowerOS-Bash.sh
```

---

## 🌺 FlowerOS .bashrc Integration

**Your terminal is about to become a beautiful garden!** 🌸✨

Follow the steps above and reload bash to see the magic!
