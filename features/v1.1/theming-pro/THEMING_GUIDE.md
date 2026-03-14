# FlowerOS Professional Theming System v1.1.1

**Transform your terminal experience with professional, git-integrated themes for PowerShell and Bash**

---

## 🎨 Features

### PowerShell Theme (VS Code Optimized)
- ✅ **Git Integration** - Branch & status in prompt
- ✅ **Smart Path Shortening** - Readable long paths
- ✅ **Syntax Highlighting** - PSReadLine integration
- ✅ **VS Code Detection** - Auto-optimizes for VS Code terminal
- ✅ **Useful Aliases** - Git shortcuts, navigation, utilities
- ✅ **Custom Prompt** - Color-coded success/failure

### Bash Theme (WSL & Linux)
- ✅ **Git Integration** - Branch, status, symbols
- ✅ **Smart Prompt** - Two-line prompt with context
- ✅ **Enhanced Navigation** - Quick directory jumping
- ✅ **Auto-completion** - Improved tab completion
- ✅ **History Management** - Large, deduped history
- ✅ **Performance Optimized** - Fast git status checks

---

## 🚀 Quick Start

### PowerShell (Windows / VS Code)

```powershell
# One-command install
.\features\v1.1\theming-pro\Install-Theme.ps1

# Then restart PowerShell or run:
. $PROFILE
```

### Bash (Linux / WSL)

```bash
# One-command install
bash features/v1.1/theming-pro/Install-Theme.sh

# Then reload:
source ~/.bashrc
```

---

## 📸 What You Get

### PowerShell Prompt

```
[username@computer] C:\Users\username\Projects\FlowerOS [git:main ✓]
❯ 
```

**Features:**
- User & computer in cyan
- Path in blue (shortened if long)
- Git branch in magenta with status symbol
- Green prompt (❯) on success, red on error

### Bash Prompt

```
[username@hostname] ~/Projects/FlowerOS [⎇ main ✓]
❯ 
```

**Features:**
- User@host in cyan
- Smart path shortening
- Git branch with status
- Color-coded prompt character

---

## 🛠️ Installation Details

### PowerShell

**What it installs:**
1. Adds theme to `$PROFILE` (usually `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`)
2. Configures PSReadLine (if available)
3. Sets up git integration
4. Adds useful aliases

**Manual installation:**
```powershell
# Load theme
. features/v1.1/theming-pro/FlowerOS-PowerShell.ps1

# Install to profile
Install-FlowerOSTheme

# Or just source it in your profile:
# Add to $PROFILE:
. "C:\path\to\FlowerOS\features\v1.1\theming-pro\FlowerOS-PowerShell.ps1"
Initialize-PSReadLine
Initialize-VSCodeIntegration
```

### Bash

**What it installs:**
1. Adds theme to `~/.bashrc`
2. Configures prompt with git
3. Sets up aliases & functions
4. Enhances tab completion

**Manual installation:**
```bash
# Add to ~/.bashrc:
source "/path/to/FlowerOS/features/v1.1/theming-pro/FlowerOS-Bash.sh"
```

---

## 🎯 Aliases & Shortcuts

### PowerShell

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Git status |
| `ga` | `git add` | Git add |
| `gc` | `git commit -m` | Git commit |
| `gp` | `git push` | Git push |
| `gl` | `git log` | Pretty git log |
| `..` | `cd ..` | Up one directory |
| `...` | `cd ../..` | Up two directories |
| `ll` | `ls -Force` | List all files |
| `c` | `Clear-Host` | Clear screen |
| `e <file>` | `code <file>` | Edit in VS Code |
| `touch <file>` | Create/update file | Like Unix touch |
| `which <cmd>` | Find command path | Like Unix which |

### Bash

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Git status |
| `ga` | `git add` | Git add |
| `gc` | `git commit -m` | Git commit |
| `gp` | `git push` | Git push |
| `gl` | `git log --graph` | Pretty git log |
| `gd` | `git diff` | Git diff |
| `..` | `cd ..` | Up one directory |
| `...` | `cd ../..` | Up two directories |
| `ll` | `ls -lAh` | List detailed |
| `mkcd <dir>` | Make & cd into dir | Create directory |
| `extract <file>` | Extract archive | Auto-detects format |
| `ff <name>` | Find files | Search by name |
| `serve` | Start HTTP server | Python HTTP server |

---

## 🎨 Customization

### PowerShell

Edit `FlowerOS-PowerShell.ps1` and modify the `$Script:FlowerOSColors` hashtable:

```powershell
$Script:FlowerOSColors = @{
    PromptUser  = 'Cyan'      # Change to your preference
    PromptPath  = 'Blue'
    PromptGit   = 'Magenta'
    PromptArrow = 'Green'
    # ... etc
}
```

### Bash

Edit `FlowerOS-Bash.sh` and modify color variables:

```bash
# Change these to customize colors
C_USER="${C_CYAN}"      # User color
C_PATH="${C_BLUE}"      # Path color
C_GIT="${C_MAGENTA}"    # Git color
# ... etc
```

---

## 🔧 Troubleshooting

### PowerShell

**Profile not loading?**
```powershell
# Check profile path
$PROFILE

# Test if file exists
Test-Path $PROFILE

# Manually run
. $PROFILE
```

**PSReadLine not working?**
```powershell
# Install PSReadLine
Install-Module PSReadLine -Force

# Then reload profile
. $PROFILE
```

**VS Code not detecting theme?**
- Restart VS Code completely
- Check terminal is set to PowerShell
- Run `. $PROFILE` manually in VS Code terminal

### Bash

**Theme not loading?**
```bash
# Check if installed
grep "FlowerOS" ~/.bashrc

# Manually reload
source ~/.bashrc
```

**Git status not showing?**
```bash
# Make sure you're in a git repo
git status

# Check git is installed
which git
```

**Colors not working?**
```bash
# Check terminal supports colors
echo $TERM

# Should be: xterm-256color or similar
```

---

## 📊 Performance

Both themes are optimized for performance:

### PowerShell
- Git status cached during prompt generation
- Path shortening uses string manipulation (fast)
- VS Code detection is one-time check

### Bash
- Git status only runs if in git repo
- Fast branch detection using symbolic-ref
- Minimal external command calls
- History configured for speed

**Typical prompt generation time: < 10ms**

---

## 🎓 Advanced Usage

### PowerShell

**Custom prompt function:**
```powershell
# Add to your $PROFILE after loading theme
function prompt {
    # Call original FlowerOS prompt
    $originalPrompt = & $Function:prompt
    
    # Add custom elements
    Write-Host "[CUSTOM]" -ForegroundColor Magenta -NoNewline
    Write-Host " " -NoNewline
    
    return $originalPrompt
}
```

### Bash

**Custom prompt additions:**
```bash
# Add to ~/.bashrc after sourcing theme

# Add custom function to prompt
__floweros_prompt_command_original="$PROMPT_COMMAND"
PROMPT_COMMAND='__floweros_prompt_command; custom_prompt_additions'

custom_prompt_additions() {
    # Add custom elements
    PS1+="${C_MAGENTA}[CUSTOM]${C_RESET} "
}
```

---

## 🔄 Updating

### PowerShell
```powershell
# Uninstall old version
.\Install-Theme.ps1 uninstall

# Install new version
.\Install-Theme.ps1 install
```

### Bash
```bash
# Uninstall old
bash Install-Theme.sh uninstall

# Install new
bash Install-Theme.sh install
```

---

## 🗑️ Uninstallation

### PowerShell
```powershell
.\features\v1.1\theming-pro\Install-Theme.ps1 uninstall
```

### Bash
```bash
bash features/v1.1/theming-pro/Install-Theme.sh uninstall
```

Both uninstallers create backups before removing!

---

## 📝 Requirements

### PowerShell
- PowerShell 5.1+ (PowerShell 7+ recommended)
- PSReadLine module (optional, for syntax highlighting)
- Git (optional, for git integration)
- VS Code (optional, for VS Code integration)

### Bash
- Bash 4.0+
- Git (optional, for git integration)
- Modern terminal with 256 color support

---

## 🌟 Tips & Tricks

### PowerShell

1. **Fast directory navigation:**
   ```powershell
   .. ; .. ; ...    # Navigate up quickly
   ```

2. **Git workflow:**
   ```powershell
   ga . ; gc "commit message" ; gp
   ```

3. **Quick edits:**
   ```powershell
   e script.ps1    # Opens in VS Code
   ```

### Bash

1. **Extract anything:**
   ```bash
   extract file.tar.gz
   extract file.zip
   ```

2. **Find files fast:**
   ```bash
   ff "*.txt"      # Find all txt files
   fd "project"    # Find directories named project
   ```

3. **Quick HTTP server:**
   ```bash
   serve 8080      # Start server on port 8080
   ```

---

## 🎨 Screenshots

### PowerShell in VS Code
```
[john@DESKTOP-PC] ~\Projects\FlowerOS [git:main ✓]
❯ gs
On branch main
Your branch is up to date with 'origin/main'.
```

### Bash in WSL
```
[john@ubuntu] ~/Projects/FlowerOS [⎇ main ✓]
❯ gl
* a1b2c3d (HEAD -> main) Add new feature
* d4e5f6g Update documentation
```

---

## 🌺 FlowerOS v1.1.1 - Professional and Powerful

*Every terminal session is a garden.*
