# 🌸 FlowerOS v1.2.0 - Breathtaking Visual Experience

**Transform your terminal from a boring black void to a stunning, professional workspace!**

---

## 🎨 What You Get

### Before
```
PS C:\Users\john>
```

### After
```
    ___________                             ____  _____
   / ____/ / /___ _      _____  _____     / __ \/ ___/
  / /_  / / __/ | | /| / / _ \/ ___/    / / / /\__ \ 
 / __/ / / /_ | |/ |/ /  __/ /        / /_/ /___/ / 
/_/   /_/\__/ |__/|__/\___/_/         \____//____/  
                                                      
    🌸 Professional Terminal Experience 🌸

   OS              Windows 11 Pro 22H2
   User            john@DESKTOP-PC
   Kernel          10.0.22621
   Shell           PowerShell 7.3.0
   Terminal        Windows Terminal
   CPU             Intel i7-8750H
   GPU             NVIDIA GTX 1060
   Memory          16.00 GB
   Disk            250.00 GB free
   Uptime          2h 15m

 Color Palette  ████████

  🌸 Every terminal session is a garden 🌸
```

---

## ✨ Features

### 🎨 Stunning Visuals
- **ASCII Art Welcome** - Beautiful FlowerOS logo on every launch
- **System Info Display** - Neofetch-style with Nerd Font icons
- **Semi-Transparent Background** - Acrylic effects in Windows Terminal
- **3 Gorgeous Themes** - Dracula, Tokyo Night, Nord color schemes
- **Nerd Font Icons** - Professional icons throughout

### 🖼️ Customization Options
- **Background Images** - Set custom terminal backgrounds
- **Adjustable Transparency** - 70-100% opacity control
- **Multiple ASCII Styles** - Small, medium, large art options
- **Color Palette Display** - See your colors at a glance

### ⚡ Performance
- **Fast** - Welcome screen loads in < 100ms
- **Lightweight** - No impact on shell performance
- **Optional** - Can disable with environment variable

---

## 🚀 One-Command Installation

### PowerShell (Recommended)
```powershell
.\features\v1.2\visual-experience\Install-BreathtakingExperience.ps1
```

**This installs:**
1. ✅ Nerd Fonts (Cascadia Code)
2. ✅ Windows Terminal configuration (transparency, themes)
3. ✅ Welcome system (ASCII art, system info)
4. ✅ PowerShell profile integration

### Manual Steps

If you prefer manual installation:

#### 1. Install Nerd Font
```powershell
# Download from: https://www.nerdfonts.com/font-downloads
# Install: CaskaydiaCove Nerd Font
```

#### 2. Configure Windows Terminal
```powershell
# Copy settings from:
features/v1.2/visual-experience/windows-terminal-settings.json

# Paste into:
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

#### 3. Install Welcome System
```powershell
. features/v1.2/visual-experience/FlowerOS-Welcome.ps1
Install-FlowerOSWelcome
```

---

## 🎨 Customization

### Change Welcome Style

```powershell
# Small (just logo + quote)
Show-Welcome -Style small

# Medium (logo + system info)
Show-Welcome -Style medium

# Large (big logo + full info)
Show-Welcome -Style large

# Full (everything)
Show-Welcome -Style full
```

### Disable Welcome Screen

Add to your profile before the FlowerOS Welcome load:
```powershell
$env:FLOWEROS_QUIET = 1
```

### Change Colors

Edit `FlowerOS-Welcome.ps1`:
```powershell
$Colors = @{
    Primary = "Magenta"      # Change to your preference
    Secondary = "Cyan"
    Accent = "Yellow"
    # ... etc
}
```

### Change ASCII Art

Replace files in `features/v1.2/visual-experience/ascii/`:
- `floweros-small.txt`
- `floweros-medium.txt`
- `floweros-large.txt`

---

## 🖼️ Terminal Themes

### Dracula
**Dark purple theme with vibrant colors**
- Background: `#282A36`
- Foreground: `#F8F8F2`
- Accent: Purple/Pink

### Tokyo Night
**Modern dark blue theme**
- Background: `#1A1B26`
- Foreground: `#C0CAF5`
- Accent: Blue/Cyan

### Nord
**Arctic blue-grey theme**
- Background: `#2E3440`
- Foreground: `#D8DEE9`
- Accent: Frost blues

---

## 🎯 VS Code Integration

### Add to `settings.json`:

```jsonc
{
    "terminal.integrated.fontFamily": "CaskaydiaCove Nerd Font",
    "terminal.integrated.fontSize": 12,
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.gpuAcceleration": "on"
}
```

Or copy from: `features/v1.2/visual-experience/vscode-terminal-settings.json`

---

## 📸 Screenshots

### Windows Terminal with Dracula Theme
- Semi-transparent background
- Acrylic blur effect
- Beautiful ASCII art welcome
- System info with icons

### Bash with Neofetch
- Custom FlowerOS ASCII art
- Colorful system stats
- Nerd Font icons
- Color palette display

---

## 🛠️ Requirements

### Windows
- **Windows 10/11** (for transparency features)
- **Windows Terminal** (latest version)
- **PowerShell 7+** (recommended)
- **Administrator rights** (for font installation)

### Optional
- **VS Code** (for enhanced terminal experience)
- **Neofetch** (for Bash welcome screen)
- **WSL** (for Bash support)

---

## 🎓 Advanced Tips

### 1. Background Images

Add to Windows Terminal profile:
```json
"backgroundImage": "C:\\Path\\To\\Image.jpg",
"backgroundImageOpacity": 0.3,
"backgroundImageStretchMode": "uniformToFill"
```

### 2. Custom Animations

Enable in `FlowerOS-Welcome.ps1`:
```powershell
$Script:Config = @{
    AnimateWelcome = $true  # Animated ASCII art reveal
}
```

### 3. Dynamic Quotes

Add your own quotes in `Show-Wisdom` function:
```powershell
$quotes = @(
    "Your custom quote here 🌸",
    "Another inspiring message 💎"
)
```

### 4. Weather Integration

Install a weather module and add to system info:
```powershell
# Example with wttr.in
$weather = (Invoke-RestMethod "wttr.in/?format=3")
```

---

## 🐛 Troubleshooting

### Icons not showing?
- Install Nerd Font: https://www.nerdfonts.com/
- Set terminal font to "CaskaydiaCove Nerd Font"
- Restart terminal

### Transparency not working?
- Update Windows Terminal to latest version
- Check "Use acrylic material" in terminal settings
- Ensure Windows Aero is enabled

### Welcome screen too slow?
- Disable system info: `$Script:Config.ShowSystemInfo = $false`
- Use smaller ASCII art: `Show-Welcome -Style small`
- Cache system info

### Colors look wrong?
- Set `$env:TERM = "xterm-256color"`
- Check terminal supports 256 colors
- Try different color scheme

---

## 🔄 Updating

```powershell
# Uninstall old
# (Welcome system can be re-installed safely)

# Install new
.\features\v1.2\visual-experience\Install-BreathtakingExperience.ps1 -Force
```

---

## 🗑️ Uninstallation

### Remove Welcome System
```powershell
# Edit $PROFILE and remove FlowerOS Welcome section
notepad $PROFILE
```

### Revert Windows Terminal Settings
```powershell
# Restore from backup
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
# Find .backup file and rename to settings.json
```

### Remove Fonts
- Windows Settings → Fonts
- Search "CaskaydiaCove"
- Uninstall

---

## 📚 Files Included

| File | Purpose |
|------|---------|
| `FlowerOS-Welcome.ps1` | PowerShell welcome system |
| `FlowerOS-Welcome.sh` | Bash welcome system |
| `Install-BreathtakingExperience.ps1` | One-command installer |
| `windows-terminal-settings.json` | Terminal themes & config |
| `vscode-terminal-settings.json` | VS Code terminal config |
| `ascii/floweros-*.txt` | ASCII art files |
| `VISUAL_EXPERIENCE_GUIDE.md` | This documentation |

---

## 🌟 Inspiration

This breathtaking experience is inspired by:
- **neofetch** - System info display
- **r/unixporn** - Terminal aesthetics
- **Starship** - Beautiful prompts
- **Oh-My-Posh** - Windows Terminal theming
- **Nord/Dracula/Tokyo Night** - Color schemes

---

## 🎨 Design Philosophy

**"A terminal should be as beautiful as the code you write in it."**

We believe:
- Aesthetics improve productivity
- Beautiful tools inspire beautiful work
- Your environment affects your mood
- Customization is self-expression

---

## 💎 What Makes This Different?

### Other tools:
- Complex configuration
- Require learning new languages
- Performance overhead
- Platform-specific

### FlowerOS v1.2:
- ✅ One-command installation
- ✅ Pure PowerShell/Bash
- ✅ Zero performance impact
- ✅ Cross-platform (PS1 + Bash)
- ✅ Beautiful defaults
- ✅ Easy customization

---

## 🌺 FlowerOS v1.2.0 - Breathtaking by Design

*Transform your terminal from a tool into an experience.*

**Every session is a garden. Make it beautiful.** 🌸

---

## 🚀 Get Started Now

```powershell
# One command to transform your terminal
.\features\v1.2\visual-experience\Install-BreathtakingExperience.ps1
```

**Then restart your terminal and prepare to be amazed!** ✨

---

# FlowerOS Professional Theming System v1.2.0

**Transform your terminal experience with professional, git-integrated themes for PowerShell and Bash**

---

## 🎨 Features

### PowerShell Theme (VS Code Optimized)
- **Integrated with VS Code** - Seamless experience between editor and terminal
- **Dracula, Tokyo Night, Nord** - Stunning color themes
- **Customizable** - Easily adjust colors, font size, and more
- **Works with Git** - Shows branch and status in prompt
- **Rich prompts** - Directory navigation, git info, and more

### Bash Theme (WSL & Linux)
- **Beautiful prompts** - Informative and easy-to-read
- **Git integration** - Branch and status indicators
- **Customizable** - Change colors, fonts, and elements
- **Powerline support** - Extra visual flair if you like it

### Image-to-Terminal Tools ✨ NEW!
- **Convert any image** - Photos, logos, artwork to terminal art
- **Pastel mode** - Beautiful soft colors
- **Hash mode** - Deterministic consistent colors
- **Two renderers** - Choose quality vs style
- **PowerShell wrapper** - Easy Windows usage

---

## 🚀 Quick Start

```powershell
# To install all features including themes and image tools
.\features\v1.2\visual-experience\Install-BreathtakingExperience.ps1

# To use image-to-terminal tools only
.\features\v1.2\visual-experience\image-tools\Convert-ImageToTerminal.ps1
```

---

## 🖼️ Image Conversion

### Convert Your Own Images

**PowerShell:**
```powershell
# Basic conversion
.\image-tools\Convert-ImageToTerminal.ps1 myimage.png

# Custom settings
.\image-tools\Convert-ImageToTerminal.ps1 myimage.png -Columns 140 -PastelStrength 0.60

# Save to file
.\image-tools\Convert-ImageToTerminal.ps1 myimage.png -Save
```

**Bash:**
```bash
# Standard pastel mode
bash image-tools/img2term.sh myimage.png 120 0.55 half

# Hash-based mode (consistent colors)
python3 image-tools/img2term-hash.py myimage.png 140
```

### Use Custom Images in Welcome Screen

1. Convert your image:
   ```powershell
   .\image-tools\Convert-ImageToTerminal.ps1 logo.png -Columns 80 -Save
   ```

2. Copy to ASCII directory:
   ```powershell
   Copy-Item logo.ascii ascii/custom-logo.txt
   ```

3. Edit `FlowerOS-Welcome.ps1` to use your custom art

### Best Practices

- **Use high contrast images** - Better terminal representation
- **Start with 120 columns** - Good balance of detail/size
- **Adjust pastel strength** - 0.4-0.6 works best
- **Try both modes** - Pastel vs hash for different styles

---
