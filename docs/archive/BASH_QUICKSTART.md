# FlowerOS v1.2.0 - Quick Start (Bash/WSL)

**Get your terminal working in 3 commands!**

---

## 🚀 Fast Install

```bash
# 1. Make scripts executable
chmod +x features/v1.2/visual-experience/FlowerOS-Welcome.sh
chmod +x features/v1.2/visual-experience/Install-BreathtakingExperience.sh

# 2. Run installer
bash features/v1.2/visual-experience/Install-BreathtakingExperience.sh

# 3. Reload bash
source ~/.bashrc
```

**That's it! Your terminal is now breathtaking!** ✨

---

## 🧪 Test First

```bash
# Make test script executable
chmod +x test-floweros.sh

# Run test
bash test-floweros.sh
```

This checks if all files are in place.

---

## 🎨 Manual Install (If Installer Fails)

### Step 1: Add to ~/.bashrc

```bash
# Open bashrc
nano ~/.bashrc

# Add at the end:
source "/mnt/c/Users/Liam/Desktop/FlowerOS/features/v1.2/visual-experience/FlowerOS-Welcome.sh"
floweros_welcome auto
```

### Step 2: Reload

```bash
source ~/.bashrc
```

---

## 🖼️ Convert Images

```bash
# Make image tools executable
chmod +x features/v1.2/visual-experience/image-tools/img2term.sh

# Convert an image
bash features/v1.2/visual-experience/image-tools/img2term.sh yourimage.png 120
```

---

## 🐛 Troubleshooting

### "motd: No such file or directory"

```bash
# Create missing directory
mkdir -p motd
```

### "Permission denied"

```bash
# Make all scripts executable
find features/v1.2 -name "*.sh" -exec chmod +x {} \;
chmod +x test-floweros.sh
```

### "Python not found"

```bash
# Install Python
sudo apt-get update
sudo apt-get install python3 python3-pip
```

### "Pillow not installed"

```bash
# Install Pillow
python3 -m pip install --user pillow
```

---

## 📝 What The Installer Does

1. **Installs Nerd Fonts** - Downloads Cascadia Code Nerd Font
2. **Adds to ~/.bashrc** - Sources FlowerOS-Welcome.sh on startup
3. **Installs Pillow** - For image conversion tools
4. **Creates backup** - Backs up your ~/.bashrc first

---

## ✅ Verify Installation

```bash
# Check if FlowerOS is in bashrc
grep "FlowerOS" ~/.bashrc

# Should output something like:
# source "/path/to/FlowerOS-Welcome.sh"
# floweros_welcome auto
```

---

## 🎯 Quick Commands

```bash
# Show welcome screen manually
bash features/v1.2/visual-experience/FlowerOS-Welcome.sh show medium

# Install with no prompt
bash features/v1.2/visual-experience/Install-BreathtakingExperience.sh <<< "Y"

# Convert image to terminal art
bash features/v1.2/visual-experience/image-tools/img2term.sh flower.png 100
```

---

## 🌺 Next Steps After Install

Once installed and ~/.bashrc is reloaded:

1. **Open new terminal** - Should see FlowerOS ASCII art
2. **Try image conversion** - Convert your photos to terminal art
3. **Customize** - Edit FlowerOS-Welcome.sh to change colors

---

## 💡 Pro Tips

### Disable Welcome For One Session
```bash
export FLOWEROS_QUIET=1
bash
```

### Change Welcome Size
Edit FlowerOS-Welcome.sh and change:
```bash
floweros_welcome auto    # to:
floweros_welcome small   # or medium, or full
```

### Use Custom ASCII Art
```bash
# Convert your image
bash features/v1.2/visual-experience/image-tools/img2term.sh mylogo.png 80 > custom.txt

# Copy to ASCII directory
cp custom.txt features/v1.2/visual-experience/ascii/custom.txt

# Edit FlowerOS-Welcome.sh to use it
```

---

## 🔄 Uninstall

```bash
# Remove FlowerOS from bashrc
nano ~/.bashrc
# Delete the FlowerOS section

# Or restore backup
mv ~/.bashrc.backup.YYYYMMDD_HHMMSS ~/.bashrc

# Reload
source ~/.bashrc
```

---

## 🌸 Your Terminal Should Look Like:

```
 _____ _                       ___  _____ 
|  ___| | _____      _____ _ __|   \/ ____|
| |_  | |/ _ \ \ /\ / / _ \ '__| |) \___ \ 
|  _| | | (_) \ V  V /  __/ |  |___/ ___) |
|_|   |_|\___/ \_/\_/ \___|_|  |____/|____/ 

      🌺 Every Session Is A Garden 🌺

   OS              Ubuntu 22.04.1 LTS
   User            liam@DESKTOP-G0UNQ2K
   Kernel          5.15.0-46-generic
   Shell           bash 5.0.17
   ...

  🌸 Every terminal session is a garden 🌸

liam@DESKTOP-G0UNQ2K ~/Desktop/FlowerOS
❯ 
```

---

## 📞 Still Not Working?

1. **Check files exist:**
   ```bash
   ls -la features/v1.2/visual-experience/
   ```

2. **Run test script:**
   ```bash
   bash test-floweros.sh
   ```

3. **Manual verification:**
   ```bash
   # Test welcome directly
   bash features/v1.2/visual-experience/FlowerOS-Welcome.sh show small
   ```

---

## 🌺 FlowerOS v1.2.0 - Breathtaking Terminals!

**Every session is a garden.** 🌸
