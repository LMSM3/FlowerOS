# FlowerOS Troubleshooting Guide

## 🔧 Common Issues & Fixes

### ❌ Error: "invalid option name: pipefail"

**Symptom:**
```
bash: line 3: set: pipefail: invalid option name
```

**Cause:** Git Bash on Windows or older bash versions don't support `set -o pipefail`

**Fix Applied:** ✅ FIXED in v1.0
```bash
# Old (breaks on Git Bash)
set -euo pipefail

# New (works everywhere)
set -eu
set -o pipefail 2>/dev/null || true
```

**Files Fixed:**
- ✓ build.sh
- ✓ install.sh
- ✓ uninstall.sh
- ✓ compile.sh
- ✓ demo.sh

---

### ❌ compile.bat window closes immediately

**Symptom:** Window flashes and closes before you can read output

**Cause:** 
1. Build errors not visible
2. Self-destruct happens too fast
3. bash exit closes window

**Fix Applied:** ✅ FIXED in v1.0
```batch
# Now uses cmd /k instead of cmd /c
# /k = keep window open
# Added timeout before self-destruct
# Shows completion message
```

**Test without self-destruct:**
```cmd
test_compile.bat
```

---

### ❌ PowerShell build preferred over bash

**Symptom:** Want to use native Windows tooling

**Solution:** ✅ NEW FEATURE in v1.0

**Native PowerShell Builder:**
```powershell
.\build_native.ps1
```

**Features:**
- No bash required
- No pipefail issues
- Native Windows experience
- Works with MSYS2/MinGW gcc
- Color output
- Progress indicators

**compile.bat now prioritizes:**
1. PowerShell (native, no issues)
2. Bash (fallback)
3. Error if neither found

---

### ❌ Build doesn't reach "steady state"

**Symptom:** Build appears to hang or doesn't complete

**Diagnosis:**
```cmd
test_compile.bat
```

**Possible Causes & Fixes:**

1. **gcc not in PATH**
   ```
   Error: gcc not found
   ```
   Fix: Install MSYS2, MinGW, or WSL
   ```powershell
   # MSYS2
   pacman -S mingw-w64-x86_64-gcc
   
   # Add to PATH
   $env:PATH += ";C:\msys64\mingw64\bin"
   ```

2. **pipefail error (old bash)**
   ```
   bash: set: pipefail: invalid option name
   ```
   Fix: ✅ Already fixed in v1.0 scripts

3. **Permission denied**
   ```
   bash: build.sh: Permission denied
   ```
   Fix:
   ```bash
   chmod +x *.sh
   ```

4. **Wrong line endings (CRLF vs LF)**
   ```
   bash: $'\r': command not found
   ```
   Fix:
   ```bash
   dos2unix *.sh
   # or
   sed -i 's/\r$//' *.sh
   ```

---

### ❌ Binaries not executing

**Windows:**
```
bash: ./random: cannot execute binary file
```

Fix: Use `.exe` extension
```bash
./random.exe .
# or in install.sh, rename:
mv random random.exe
```

**Linux:**
```
bash: ./random: Permission denied
```

Fix:
```bash
chmod +x random
```

---

### ❌ Animation flickers

**Symptom:** ASCII animation flickers or tears

**Fix:**
```bash
# Lower FPS
flower_animate file.anim 5

# Or edit .anim file
#FPS=5  # instead of 30
```

---

### ❌ Flowers don't display (����)

**Symptom:** Unicode flowers show as boxes or question marks

**Fix:**

**Windows Terminal:**
```powershell
# Settings → Profiles → Defaults → Font
# Use: "Cascadia Code", "Consolas", or "DejaVu Sans Mono"
```

**Git Bash:**
```bash
# .bashrc
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

**WSL:**
```bash
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
```

---

### ❌ bashrc not updating

**Symptom:** `install.sh` runs but functions not available

**Diagnosis:**
```bash
grep -n "FlowerOS ASCII Integration" ~/.bashrc
```

**If not found:**
```bash
# Manual install
bash install.sh
```

**If found but not working:**
```bash
# Reload
source ~/.bashrc

# Or open new terminal
```

**Check marker:**
```bash
tail -50 ~/.bashrc | grep -A5 "FlowerOS"
```

---

### ❌ Duplicate bashrc entries

**Symptom:** Multiple FlowerOS blocks in ~/.bashrc

**Fix:**
```bash
bash uninstall.sh
bash install.sh
source ~/.bashrc
```

**Manual fix:**
```bash
# Edit ~/.bashrc
nano ~/.bashrc

# Remove duplicate blocks starting with:
# # FlowerOS ASCII Integration
```

---

## 🧪 Verification Tests

### Test 1: Build System
```cmd
test_compile.bat
```
Expected: All binaries compile, no errors

### Test 2: Binaries Work
```bash
./random . 2>/dev/null || ./random.exe .
./banner "Test"
./fortune
```
Expected: Output without errors

### Test 3: Shell Functions
```bash
source ~/.bashrc
type flower_pick_ascii_line
```
Expected: Function definition shown

### Test 4: Installation Idempotency
```bash
bash install.sh
bash install.sh  # Run twice
grep -c "FlowerOS ASCII Integration" ~/.bashrc
```
Expected: Count = 1 (not 2)

### Test 5: Steady State (Complete Flow)
```cmd
# Run full installer
compile.bat
```
Expected:
1. Window opens
2. Build output shown
3. "Build complete!" message
4. Window stays open for review
5. Self-destructs after timeout
6. New terminal shows random ASCII

---

## 📊 Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (gcc missing, file not found, etc.) |
| 2 | Fallback needed (random binary returns this) |

---

## 🔍 Debug Mode

**Enable verbose output:**

```bash
# In any .sh script, add after shebang:
set -x  # Print commands as they execute

# Or run with:
bash -x build.sh
```

**Windows debug:**
```batch
# In .bat files, add:
@echo on
```

---

## ✅ Steady State Checklist

After running `compile.bat`, verify:

- [ ] gcc found and working
- [ ] All 5 C files compiled (random, animate, banner, fortune, colortest)
- [ ] Binaries created (check with `dir *.exe` or `ls -la`)
- [ ] install.sh completed without errors
- [ ] ~/.bashrc contains "FlowerOS ASCII Integration" block
- [ ] New terminal shows random ASCII
- [ ] compile.bat deleted itself
- [ ] No error messages remain

**If all checked:** 🎉 **System reached steady state!**

---

## 🆘 Still Having Issues?

1. Run diagnostics:
   ```bash
   bash demo.sh
   flower_colortest
   ```

2. Check logs:
   ```bash
   # Last build output
   bash build.sh 2>&1 | tee build.log
   ```

3. Verify files:
   ```bash
   bash tree.sh
   ```

4. Clean rebuild:
   ```bash
   rm -f random animate banner fortune colortest *.exe
   bash build.sh
   ```

5. Review documentation:
   - README.md - Quick start
   - FEATURES.md - Detailed usage
   - ARCHITECTURE.md - Technical details
   - QUICKREF.txt - Command reference

---

## 🌺 All issues resolved! System is stable and reaches steady state. ✓
