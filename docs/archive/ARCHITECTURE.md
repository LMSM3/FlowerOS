# FlowerOS ASCII System - Architecture Review

## 📁 File Structure
```
FlowerOS/
├── compile.bat          ⚡ Self-destructing Windows installer
├── compile.ps1          🪟 PowerShell alternative (keeps window open)
├── compile.sh           🐧 Bash compile script (visual feedback)
├── install.sh           📦 Main installer (idempotent)
├── uninstall.sh         🗑️ Safe removal with backup
├── random.c             ⚙️ Fast C line picker
├── example.ascii        🌸 Sample ASCII art
├── wisdom.txt           📜 Sample quotes
└── README.md            📖 Documentation
```

---

## 🎯 Three Installation Methods

### **1. Self-Destructing (Windows)**
```cmd
compile.bat
```
- Compiles `random.c`
- Runs `install.sh`
- Appends to `~/.bashrc` (~lines 550-551)
- **Deletes itself**
- One-shot, fire-and-forget

### **2. Manual Install (All Platforms)**
```bash
bash install.sh
source ~/.bashrc
```
- Idempotent (safe to run multiple times)
- Detects existing installation
- Creates `~/FlowerOS/ascii/`

### **3. Compile Only**
```bash
bash compile.sh          # Linux/WSL/Git Bash
./compile.ps1            # PowerShell
```

---

## 🔧 How It Works

### **Installation Flow**
```
compile.bat (double-click)
    ↓
Opens new terminal window
    ↓
gcc compiles random.c → random binary
    ↓
install.sh runs:
  - mkdir ~/FlowerOS/ascii/
  - cp random.c, *.ascii, *.txt
  - gcc compiles in target dir
  - Checks for marker in ~/.bashrc
  - Appends flower_pick_ascii_line() function
  - Appends shell hook: if interactive, show random line
    ↓
Self-destructs (del compile.bat)
    ↓
Pauses for review
```

### **Runtime Flow (Every Terminal)**
```
New bash shell starts
    ↓
~/.bashrc loads
    ↓
Checks: if [[ $- == *i* ]] (interactive?)
    ↓
Calls: flower_pick_ascii_line
    ↓
Tries: ~/FlowerOS/ascii/random (compiled C)
    ↓
Fallback: Shell version (find + cat + shuf)
    ↓
Output: Random line from .ascii/.txt files
```

---

## 🧠 Key Design Decisions

### **1. Detached Architecture**
- Install to `~/FlowerOS/` (not workspace)
- Survives workspace deletion
- Central location for all projects

### **2. Idempotent Installation**
- Marker-based detection: `# FlowerOS ASCII Integration`
- Won't duplicate if run twice
- Safe to update

### **3. Self-Destructing Installer**
- User requested "self inject and self delete"
- `compile.bat` cleans up after itself
- Prevents accidental re-runs

### **4. Dual Strategy (C + Shell)**
- **C helper**: Fast (compiled, /dev/urandom)
- **Shell fallback**: Portable (pure bash)
- Exit code 2 → shell takes over

### **5. Bashrc Integration (~550-551)**
- Appends to **end** of file
- Uses `sed -i` safe pattern (marker-based)
- Only affects interactive shells

---

## 📊 File Responsibilities

| File | Purpose | Self-Modifying |
|------|---------|----------------|
| `compile.bat` | Windows entry point | ✓ (deletes self) |
| `compile.sh` | Compile with visual feedback | ✗ |
| `compile.ps1` | PowerShell alternative | ✗ |
| `install.sh` | Main installer logic | ✗ |
| `uninstall.sh` | Remove + backup | ✓ (edits ~/.bashrc) |
| `random.c` | Fast random picker | ✗ |
| `*.ascii` / `*.txt` | Data files | ✗ |

---

## 🔒 Safety Features

### **Uninstall Safety**
```bash
bash uninstall.sh
```
- Creates `~/.bashrc.backup.<timestamp>`
- sed -i with exact marker match
- Prompts before deleting ~/FlowerOS/
- Cleans up extra blank lines

### **Install Safety**
- Checks for gcc before compiling
- Creates directories with `mkdir -p`
- Won't append duplicate blocks
- Error handling: `set -euo pipefail`

---

## 🎨 Bashrc Injection (Lines ~550-551)

**What gets appended:**
```bash

# FlowerOS ASCII Integration
flower_pick_ascii_line() {
  local dir="${FLOWEROS_ASCII_DIR:-$HOME/FlowerOS/ascii}"
  
  # Try compiled helper first
  if [[ -x "$dir/random" ]]; then
    local out
    out="$("$dir/random" "$dir" 2>/dev/null)" && [[ -n "$out" ]] && {
      printf "%s" "$out"
      return 0
    }
  fi
  
  # Shell fallback
  local files
  mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( -name '*.ascii' -o -name '*.txt' \) 2>/dev/null)
  (( ${#files[@]} )) || return 1
  
  cat "${files[@]}" 2>/dev/null | awk 'NF{print}' | shuf -n 1
}

# Show random ASCII on new shell
if [[ $- == *i* ]]; then
  flower_pick_ascii_line 2>/dev/null || true
fi
```

**Marker detection:**
```bash
grep -qF "# FlowerOS ASCII Integration" ~/.bashrc
```

---

## 🚀 Advanced Usage

### **Custom Directory**
```bash
export FLOWEROS_ASCII_DIR="$HOME/custom/path"
```

### **Manual Trigger**
```bash
flower_pick_ascii_line
```

### **Add More Art**
```bash
echo "New wisdom" >> ~/FlowerOS/ascii/more.txt
```

### **Rebuild**
```bash
cd ~/FlowerOS/ascii/
gcc -O2 -std=c11 -Wall -Wextra -o random random.c
```

---

## ✅ Testing Checklist

- [x] `compile.bat` opens new window
- [x] gcc compiles without errors
- [x] `install.sh` is idempotent
- [x] `~/.bashrc` gets marker
- [x] Function appended to ~line 550-551
- [x] New terminals show random ASCII
- [x] `uninstall.sh` creates backup
- [x] `compile.bat` self-deletes
- [x] Shell fallback works if C helper missing
- [x] No duplicate bashrc blocks

---

## 🌸 Philosophy

**Simple. Detached. Automatic.**

- **Simple**: 3 scripts, 1 C file, 2 data files
- **Detached**: Lives in ~/FlowerOS/, not workspace
- **Automatic**: Self-installing, self-destructing, self-appending

Every terminal session is a garden. 🌺
