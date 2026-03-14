# 🪟 Buddy Window System - Complete Summary

**Automated multi-terminal management for FlowerOS network testing**

---

## ✅ What's Been Created

### Core Scripts

1. **`buddy-windows.sh`** - Main buddy window manager
   - Opens 3 windows for relay testing
   - Closes all windows cleanly
   - Shows status of active windows
   - Auto-detects terminal emulator
   - Tracks PIDs for management

2. **`relay-auto-test.sh`** - One-command relay test
   - Builds network if needed
   - Opens buddy windows automatically
   - Starts relay test
   - Ctrl+C to close everything

3. **`buddy-presets.sh`** - Interactive preset menu
   - 5 preset configurations
   - Custom window layouts
   - Easy preset switching

### Documentation

4. **`BUDDY_WINDOWS.md`** - Complete documentation
   - Usage guide
   - Customization
   - Troubleshooting
   - Examples

5. **`BUDDY_WINDOWS_QUICK_REF.txt`** - Quick reference card
   - Commands at a glance
   - Visual layouts
   - Keyboard shortcuts
   - Tips & tricks

6. **Updated `README.md`** - Main readme updated
   - Buddy windows mentioned in features
   - Quick start command added

---

## 🚀 How to Use

### Simplest Way (One Command)

```bash
bash relay-auto-test.sh
```

This:
1. Builds network components (if needed)
2. Opens 3 terminal windows automatically
3. Configures: Master (7777) → Relay (7778) → Worker (7779)
4. Starts monitoring in each window
5. Press Ctrl+C to close all

### Manual Control

```bash
# Open 3 relay windows
bash buddy-windows.sh open

# Do your testing...

# Close all windows
bash buddy-windows.sh close

# Check what's running
bash buddy-windows.sh status
```

### Interactive Presets

```bash
bash buddy-presets.sh
```

Menu offers:
- **[1]** Relay Test (3 windows)
- **[2]** Cluster Test (4 windows) 
- **[3]** Discovery Test (2 windows)
- **[4]** GPU Cluster (3 windows)
- **[5]** Development (2 windows)

---

## 🎯 What It Does

### Problem Solved

**Before buddy windows:**
```bash
# Terminal 1
cd FlowerOS
source lib/terminal_network.sh
flower_grow_tree test
./network/build/node_monitor 7777

# Terminal 2  
cd FlowerOS
source lib/terminal_network.sh
flower_join_garden 127.0.0.1
./network/build/node_monitor 7778

# Terminal 3
cd FlowerOS
source lib/terminal_network.sh
flower_join_garden 127.0.0.1
./network/build/node_monitor 7779

# Repeat for each test... 😫
```

**After buddy windows:**
```bash
bash relay-auto-test.sh
# Done! 🎉
```

### Features

✅ **Automatic window opening**  
✅ **Automatic positioning** (side-by-side or grid)  
✅ **Automatic configuration** (master, relay, worker)  
✅ **Automatic cleanup** (close all with one command)  
✅ **PID tracking** (no zombie processes)  
✅ **Terminal detection** (works with gnome-terminal, konsole, xterm, etc.)  
✅ **Preset layouts** (5 different configurations)  
✅ **One-command testing** (relay-auto-test.sh)

---

## 📊 Window Layouts

### Relay Test (Default)

```
┌─────────────┬─────────────┬─────────────┐
│   Master    │    Relay    │   Worker    │
│  127.0.0.1  │  127.0.0.1  │  127.0.0.1  │
│   :7777     │    :7778    │    :7779    │
│   (TREE)    │   (PLANT)   │   (PLANT)   │
└─────────────┴─────────────┴─────────────┘
```

Shows:
- Master broadcasting messages
- Relay forwarding to worker
- Worker receiving relayed data
- Real-time network statistics

### Cluster Test (4 Windows)

```
┌─────────────┬─────────────┐
│   Master    │  Worker-1   │
│   :7777     │   :7778     │
├─────────────┼─────────────┤
│  Worker-2   │  Worker-3   │
│   :7779     │   :7780     │
└─────────────┴─────────────┘
```

Shows:
- 1 master coordinating 3 workers
- Cluster management
- Distributed operations

### Discovery Test (2 Windows)

```
┌──────────────────┬──────────────────┐
│   Node Monitor   │  Node Discovery  │
│                  │                  │
│  Live stats      │  Interactive     │
│  Network graph   │  Network map     │
│  Real-time       │  Manual control  │
└──────────────────┴──────────────────┘
```

Shows:
- Live monitoring + interactive discovery
- Side-by-side comparison

---

## 🔧 Technical Details

### Terminal Support

Auto-detects:
- `gnome-terminal` (GNOME Desktop)
- `konsole` (KDE Desktop)
- `xterm` (Universal fallback)
- `xfce4-terminal` (XFCE Desktop)
- `tilix` (Tilix terminal)

Falls back gracefully if none found.

### Process Management

- PIDs stored in `/tmp/floweros_buddy_windows.pid`
- Clean shutdown kills all processes
- No zombie processes
- Graceful exit handling

### Window Positioning

Geometry format: `WIDTHxHEIGHT+XPOS+YPOS`

Example:
- `80x24+0+0` - 80 cols, 24 rows, top-left
- `80x24+600+0` - Same size, 600px right
- `80x24+1200+0` - Same size, 1200px right

Automatically arranged for your screen.

### Commands Run in Each Window

**Master Node:**
```bash
cd FlowerOS/
source lib/terminal_network.sh
flower_grow_tree buddy_test
./network/build/node_monitor 7777
```

**Relay Node:**
```bash
cd FlowerOS/
source lib/terminal_network.sh
flower_join_garden 127.0.0.1
./network/build/node_monitor 7778
```

**Worker Node:**
```bash
cd FlowerOS/
source lib/terminal_network.sh
flower_join_garden 127.0.0.1
./network/build/node_monitor 7779
```

---

## 🎨 Customization

### Change Window Size

Edit `buddy-windows.sh`:

```bash
--geometry=80x24+0+0
# Change to:
--geometry=100x30+0+0  # Wider and taller
```

### Change Ports

Edit `buddy-windows.sh`:

```bash
./network/build/node_monitor 7777
# Change to:
./network/build/node_monitor 8000
```

### Add Custom Preset

Edit `buddy-presets.sh`:

```bash
preset_custom() {
    echo "Opening Custom configuration..."
    
    gnome-terminal --title="My Window" \
                   --geometry=80x30+0+0 \
                   -- bash -c "
        cd '$SCRIPT_DIR'
        # Your commands here
        bash
    " &
}
```

Then add to menu.

---

## 🐛 Troubleshooting

### No Terminal Emulator Found

**Error:** `No supported terminal emulator found`

**Fix:**
```bash
sudo apt-get install gnome-terminal
# or
sudo dnf install gnome-terminal
# or  
sudo pacman -S gnome-terminal
```

### Windows Don't Close

**Error:** Windows still open after `buddy-windows.sh close`

**Fix:**
```bash
# Find processes
ps aux | grep node_monitor

# Kill them
kill <PID1> <PID2> <PID3>

# Clean PID file
rm /tmp/floweros_buddy_windows.pid
```

### Build Fails

**Error:** `network/build/node_monitor not found`

**Fix:**
```bash
cd network/
make clean
make all
cd ..
```

### Windows Overlap

**Problem:** All windows open in same position

**Fix:** Adjust geometry positions in `buddy-windows.sh`:
```bash
# Increase horizontal spacing
--geometry=80x24+0+0      # Window 1: x=0
--geometry=80x24+800+0    # Window 2: x=800 (was 600)
--geometry=80x24+1600+0   # Window 3: x=1600 (was 1200)
```

---

## 📖 Usage Examples

### Example 1: Quick Relay Test

```bash
$ bash relay-auto-test.sh

🌐 FLOWEROS RELAY TEST - AUTO BUDDY WINDOWS 🌐

This will automatically:
  1. Build network components (if needed)
  2. Open 3 terminal windows
  3. Configure each as: Master → Relay → Worker
  4. Start network monitoring

Press Ctrl+C in this terminal to close all windows

Press Enter to start...

Building network components...
✓ Build complete

Opening buddy windows...
[1/3] Opening Master Node window (port 7777)...
[2/3] Opening Relay Node window (port 7778)...
[3/3] Opening Worker Node window (port 7779)...

✓ All buddy windows opened!

═══════════════════════════════════════════════════════════════
  Buddy windows are now open!

  Watch the 3 terminal windows to see:
    • Master node broadcasting
    • Relay node forwarding messages
    • Worker node receiving relayed data

  Press Ctrl+C here to close all windows
═══════════════════════════════════════════════════════════════

[Waiting... Press Ctrl+C]
^C
Closing buddy windows...
✓ All buddy windows closed
```

### Example 2: Manual Control

```bash
$ bash buddy-windows.sh open
Opening buddy windows with gnome-terminal...

[1/3] Opening Master Node window (port 7777)...
[2/3] Opening Relay Node window (port 7778)...
[3/3] Opening Worker Node window (port 7779)...

✓ All buddy windows opened!

Windows:
  [1] Master Node  - 127.0.0.1:7777 (left)
  [2] Relay Node   - 127.0.0.1:7778 (center)
  [3] Worker Node  - 127.0.0.1:7779 (right)

To close all windows, run:
  bash buddy-windows.sh close

# [Do your testing...]

$ bash buddy-windows.sh status
Buddy windows status:

  Window 1: Running (PID: 12345)
  Window 2: Running (PID: 12346)
  Window 3: Running (PID: 12347)

$ bash buddy-windows.sh close
Closing buddy windows...

Closing window (PID: 12345)
Closing window (PID: 12346)
Closing window (PID: 12347)

✓ All buddy windows closed
```

### Example 3: Using Presets

```bash
$ bash buddy-presets.sh

╔═══════════════════════════════════════════════════════════════╗
║         FlowerOS Buddy Window Presets                         ║
╚═══════════════════════════════════════════════════════════════╝

Choose a test configuration:

  [1] Relay Test (3 windows)
      Master → Relay → Worker
      Ports: 7777, 7778, 7779

  [2] Cluster Test (4 windows)
      Master + 3 Workers
      Ports: 7777, 7778, 7779, 7780

  [3] Discovery Test (2 windows)
      Monitor + Discovery
      Interactive network exploration

  [4] GPU Cluster (3 windows)
      Master + GPU Worker + Monitor
      For GPU batch testing

  [5] Development (2 windows)
      Code editor + Test terminal
      Side-by-side development

  [C] Close all windows
  [Q] Quit

Your choice: 2

Opening Cluster Test configuration (4 windows)...
✓ Cluster test windows opened (4 windows in 2x2 grid)

Press Enter to continue...
```

---

## 🎯 Best Practices

1. **Use `relay-auto-test.sh`** for quick tests
2. **Use `buddy-presets.sh`** for exploring different setups
3. **Always close properly** with `buddy-windows.sh close`
4. **Check status** before opening more windows
5. **Customize geometry** for your screen size
6. **Build first** if you modify network code

---

## 🌱 Philosophy

**Testing should be automatic.**

Opening terminals, typing commands, arranging windows—that's tedious work. Buddy windows automate the boring parts so you can focus on testing network features.

Every test session is a garden. 🌸

---

## 📚 Related Documentation

- `NETWORK_ROUTING.md` - Network routing documentation
- `NODE_MONITOR.md` - Node monitor guide
- `TERMINAL_NETWORK.md` - Terminal network functions
- `test-internet-relay.sh` - Manual relay tests
- `test-linux-network.sh` - Complete network tests

---

## 🔴 Experimental Warning

Buddy windows are part of FlowerOS v1.3.X experimental features.

**Status:** EXPERIMENTAL  
**Use:** Development and testing only  
**Production:** Not recommended

See `RED_WARNING_SUMMARY.md` for details.

---

## ✅ Summary

**Before:**
- Manually open 3+ terminals
- Type commands in each
- Arrange windows manually
- Test network features
- Close each terminal individually
- **Time:** 5+ minutes setup

**After:**
```bash
bash relay-auto-test.sh
```
- **Time:** 10 seconds setup
- Press Ctrl+C to close all

**Saved:** 4+ minutes per test session 🎉

---

**🪟 Buddy Windows System - Making multi-terminal testing simple. 🌱**
