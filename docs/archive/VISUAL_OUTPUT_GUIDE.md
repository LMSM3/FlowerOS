# FlowerOS v1.2.1 - Visual Output System

**Real-time visualizations for batch calculations and discovery**

---

## 🎨 Features

✅ **Auto-visualization** - Automatically shows visual output after batch operations  
✅ **Multiple modes** - Bar charts, tables, trees, progress bars, sparklines  
✅ **Live dashboards** - Real-time updating displays  
✅ **ANSI colors** - Full color support in terminal  
✅ **Unicode graphics** - Modern terminal eye-candy  

---

## 🚀 Quick Start

### Build Visual System

```bash
gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c
```

### Run Demo

```bash
./visual demo
```

### Auto-Visualize Build

```bash
bash lib/visualize.sh build
```

### Auto-Visualize Tests

```bash
bash lib/visualize.sh test
```

---

## 📊 Visualization Modes

### 1. Bar Chart

```bash
./visual bar

# Output:
Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 1               ████████████████████████████ 85.50%
Test 2               ███████████████████████████████ 92.30%
Test 3               ████████████████████████ 78.10%
Test 4               █████████████████████████████████ 95.70%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. ASCII Table

```bash
./visual table

# Output:
Source Files
┌────────────────────┬────────────────┬──────────┐
│ Label              │ Value          │ Unit     │
├────────────────────┼────────────────┼──────────┤
│ random.c           │           2.40 │ KB       │
│ animate.c          │           3.10 │ KB       │
│ banner.c           │           2.80 │ KB       │
│ visual.c           │           4.50 │ KB       │
└────────────────────┴────────────────┴──────────┘
```

### 3. Progress Bars

```bash
./visual progress

# Output:
Building             [████████████████████████████░░░░] 75.0%
Testing              [██████████████████░░░░░░░░░░░░░░] 45.0%
Installing           [████████████████████████████████░] 90.0%
```

### 4. Sparklines (Inline Mini-Graphs)

```bash
./visual sparkline

# Output:
CPU:    ▂▃▃▄▅▆▆▇▇██▇ (last 12 hours)
Memory: ▃▄▄▅▆▆▇▆▅▆▇█ (last 12 hours)
```

### 5. Live Dashboard

```bash
./visual live

# Updates every second with real-time data
```

---

## ⚙️ Configuration

### Enable/Disable Visual Output

```bash
# Auto-detect (default)
export FLOWEROS_VISUAL=auto

# Always show
export FLOWEROS_VISUAL=on

# Disable
export FLOWEROS_VISUAL=off
```

### Custom Visual Preferences

```bash
# In ~/.bashrc
export FLOWEROS_VISUAL=auto
export FLOWEROS_VISUAL_WIDTH=80    # Chart width
export FLOWEROS_VISUAL_COLOR=1     # Enable colors
```

---

## 🔧 Integration Examples

### Build with Visualization

```bash
bash lib/visualize.sh build
```

**Output:**

```
➜ Running: bash build-v1.2.sh
[... build output ...]

━━━ Visual Summary ━━━
Build Time
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
random.c             ████████████ 1.2s
animate.c            ███████████████ 1.5s
banner.c             ██████████ 1.0s
fortune.c            ████████████ 1.2s
visual.c             ████████████████████ 2.0s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 6.9s ✓
```

### Test with Visualization

```bash
bash lib/visualize.sh test
```

**Output:**

```
➜ Running: bash stress-test.sh
[... test output ...]

━━━ Visual Summary ━━━
Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Binaries             ██████████████████████████████████ 100%
Functionality        ██████████████████████████████████ 100%
Rapid Execution      ██████████████████████████████████ 100%
Concurrent           ██████████████████████████████████ 100%
Edge Cases           ███████████████████████████████ 95%
Memory Leaks         ██████████████████████████████████ 100%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Overall: 99% ✓
```

---

## 📈 Use Cases

### 1. Build Progress Visualization

```bash
# Show real-time build progress
bash lib/visualize.sh build
```

### 2. Test Result Dashboards

```bash
# Visual test results after stress tests
bash lib/visualize.sh "bash stress-test.sh"
```

### 3. System Discovery

```bash
# Visual system information
bash lib/visualize.sh "bash debug-quick.sh"
```

### 4. Performance Monitoring

```bash
# Live performance dashboard
./visual live
```

---

## 🎯 Default Switches

FlowerOS automatically switches to visual output when:

✅ Batch calculation completes (build, test)  
✅ Discovery operation finishes (debug, scan)  
✅ Terminal supports colors (`$TERM` check)  
✅ Not in quiet mode (`FLOWEROS_QUIET` not set)  

---

## 📚 Advanced

### Custom Visualizations

Create custom data files and visualize them:

```bash
# data.txt format:
# label,value,unit
cat > data.txt <<EOF
CPU,65.5,%
Memory,4.2,GB
Disk,128.7,MB/s
EOF

# Visualize (extend visual.c to read files)
./visual bar --file data.txt
```

### Integration with Existing Tools

```bash
# Pipe output to visualizer
bash stress-test.sh | ./visual-parser.sh
```

---

## 🌸 Philosophy

**Visual output after calculations** - See results, not just text  
**Real-time feedback** - Know what's happening now  
**No fake physics** - Real data, real visualizations  
**5-6 second understanding** - Glance and know status  

---

**FlowerOS v1.2.1** - Because terminal output can be beautiful. 🎨
