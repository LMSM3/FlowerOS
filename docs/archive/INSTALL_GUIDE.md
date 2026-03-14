# FlowerOS v1.2.0 - Complete Installation Guide

## 🎯 Install FlowerOS Breathtaking Experience

**Make every new Debian/WSL terminal beautiful!**

---

## 🚀 Quick Install (Recommended)

```bash
# From FlowerOS directory:
cd /mnt/c/Users/Liam/Desktop/FlowerOS

# Run full installer:
bash features/v1.2/visual-experience/Install-BreathtakingExperience.sh
```

**This installs:**
- ✅ Beautiful ASCII art welcome screen
- ✅ System info with Nerd Font icons
- ✅ Color palette display
- ✅ Wisdom quotes
- ✅ Auto-loads on every new terminal

---

## 📸 Optional: Process Your Images First

You have 12 images in `motd/Import/`. Convert them to ASCII art:

```bash
# Build ASCII art (creates 48 files)
bash build-motd.sh

# Then install
bash features/v1.2/visual-experience/Install-BreathtakingExperience.sh
```

---

## 🔧 What Gets Modified

### ~/.bashrc
The installer adds this to your `~/.bashrc`:

```bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Welcome v1.2.0
#  Installed: 2026-01-24 12:34:56
# ═══════════════════════════════════════════════════════════════════════════

source "/mnt/c/Users/Liam/Desktop/FlowerOS/features/v1.2/visual-experience/FlowerOS-Welcome.sh"
floweros_welcome auto
```

### Automatic Backup
Before modifying, it creates: `~/.bashrc.backup.YYYYMMDD_HHMMSS`

---

## ✨ After Installation

### Test Immediately
```bash
# Reload bash config
source ~/.bashrc

# You should see the welcome screen!
```

### Every New Terminal
```bash
# Open new WSL window:
wsl bash

# Beautiful welcome screen appears automatically!
```

---

## 🎨 Customization

### Use Your Own Image as Welcome Screen

```bash
# 1. Process your image
bash build-motd.sh

# 2. Copy to ASCII directory
cp motd/ascii-output/yourimage-medium.ascii \
   features/v1.2/visual-experience/ascii/custom.txt

# 3. Edit FlowerOS-Welcome.sh
nano features/v1.2/visual-experience/FlowerOS-Welcome.sh

# 4. Change the ASCII art file:
# From: cat "$ASCII_DIR/floweros-medium.txt"
# To:   cat "$ASCII_DIR/custom.txt"

# 5. Reload
source ~/.bashrc
```

### Disable for One Session
```bash
export FLOWEROS_QUIET=1
bash
```

### Change Welcome Size
```bash
# Edit ~/.bashrc and change:
floweros_welcome auto    # to:
floweros_welcome small   # or medium, or large
```

---

## 🔄 System-Wide Installation (All Users)

If you want FlowerOS for ALL users on the system:

```bash
# 1. Copy welcome script to system location
sudo mkdir -p /opt/floweros
sudo cp -r features/v1.2/visual-experience /opt/floweros/

# 2. Add to system profile
sudo tee /etc/profile.d/floweros.sh > /dev/null <<'EOF'
# FlowerOS v1.2.0
source /opt/floweros/visual-experience/FlowerOS-Welcome.sh
floweros_welcome auto
EOF

# 3. Make executable
sudo chmod +x /etc/profile.d/floweros.sh

# 4. Test
bash -l  # Login shell
```

---

## 📦 What You Get

### On Every Terminal Launch:
- 🌸 Beautiful ASCII art logo
- 📊 System information (OS, kernel, CPU, memory, etc.)
- 🎨 Color palette showcase
- 💬 Random wisdom quote
- 🔠 Nerd Font icons throughout

### After Processing Your 12 Images:
- 48 ASCII art files ready to use
- Multiple sizes for different terminal widths
- Alternative hash-mode versions
- INDEX.txt catalog of all files

---

## ✅ Verify Installation

```bash
# Check if FlowerOS is in bashrc
grep "FlowerOS" ~/.bashrc

# Should output:
#  FlowerOS Welcome v1.2.0
# source "/path/to/FlowerOS-Welcome.sh"
# floweros_welcome auto
```

---

## 🐛 Troubleshooting

### Welcome doesn't show
```bash
# Check if script exists
ls -l features/v1.2/visual-experience/FlowerOS-Welcome.sh

# Reload bashrc
source ~/.bashrc

# Check for errors
bash -x ~/.bashrc
```

### Icons show as boxes
```bash
# Install Nerd Fonts
# (Installer does this automatically, but if needed:)
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
unzip CascadiaCode.zip -d ~/.local/share/fonts/
fc-cache -f
```

### Python/Pillow errors
```bash
# Install Pillow
python3 -m pip install --user pillow

# Image tools will work after this
```

---

## 🔄 Uninstall

```bash
# 1. Remove FlowerOS section from ~/.bashrc
nano ~/.bashrc
# Delete the FlowerOS Welcome section

# 2. Or restore backup
mv ~/.bashrc.backup.YYYYMMDD_HHMMSS ~/.bashrc

# 3. Reload
source ~/.bashrc
```

---

## 🎯 One-Command Install

**Just run this and you're done:**

```bash
cd /mnt/c/Users/Liam/Desktop/FlowerOS && \
bash features/v1.2/visual-experience/Install-BreathtakingExperience.sh
```

**Then open a new terminal and enjoy!** ✨

---

## 🌺 FlowerOS v1.2.0

*Every terminal session is now a beautiful garden.* 🌸

**From boring black void → Breathtaking professional experience!**
