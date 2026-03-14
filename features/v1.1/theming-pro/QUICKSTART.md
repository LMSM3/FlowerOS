# 🚀 FlowerOS v1.1.1 - Quick Start

**Get professional terminal theming in 60 seconds**

---

## PowerShell (Windows / VS Code)

```powershell
# Step 1: Navigate to FlowerOS
cd C:\path\to\FlowerOS

# Step 2: Run installer
.\features\v1.1\theming-pro\Install-Theme.ps1

# Step 3: Reload
. $PROFILE

# Done! You should now see:
# [username@computer] C:\path [git:branch ✓]
# ❯
```

**You get:**
- Git-aware prompt
- Smart path shortening  
- 10+ git/nav aliases
- Syntax highlighting

---

## Bash (Linux / WSL)

```bash
# Step 1: Navigate to FlowerOS
cd /path/to/FlowerOS

# Step 2: Run installer  
bash features/v1.1/theming-pro/Install-Theme.sh

# Step 3: Reload
source ~/.bashrc

# Done! You should now see:
# [username@hostname] ~/path [⎇ branch ✓]
# ❯
```

**You get:**
- Git-integrated prompt
- Two-line layout
- 10+ useful functions
- Enhanced completion

---

## ⚡ Quick Test

### PowerShell
```powershell
# Git shortcuts
gs              # git status
ga .            # git add all
gc "message"    # git commit

# Navigation
..              # cd ..
...             # cd ../..

# Utilities
ll              # list all files
touch test.txt  # create file
which git       # find command path
```

### Bash
```bash
# Git shortcuts
gs              # git status
gl              # pretty git log
gd              # git diff

# Navigation
...             # cd ../..
mkcd newdir     # make & cd

# Utilities
extract file.zip    # extract archives
ff "*.txt"          # find files
serve 8000          # HTTP server
```

---

## 📚 Learn More

- **Full Guide:** `features/v1.1/theming-pro/THEMING_GUIDE.md`
- **Changes:** `CHANGELOG_v1.1.1.md`
- **Customize:** Edit theme files to change colors

---

## 🎨 Preview

### Before
```
PS C:\Projects\FlowerOS>
```

### After
```
[john@DESKTOP-PC] ~\Projects\FlowerOS [git:main ✓]
❯
```

Much better! 🌸

---

## ℹ️ Status Check

```powershell
# PowerShell
.\features\v1.1\theming-pro\Install-Theme.ps1 status
```

```bash
# Bash
bash features/v1.1/theming-pro/Install-Theme.sh status
```

---

## 🗑️ Uninstall

```powershell
# PowerShell
.\features\v1.1\theming-pro\Install-Theme.ps1 uninstall
```

```bash
# Bash
bash features/v1.1/theming-pro/Install-Theme.sh uninstall
```

*Backups are created automatically!*

---

## 🌺 Enjoy Your Garden

**Every terminal session is now a beautiful, productive experience.**
