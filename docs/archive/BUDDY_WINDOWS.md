# 🪟 FlowerOS Buddy Window System

**Automated multi-terminal testing for network features**

Automatically opens and manages multiple terminal windows for testing FlowerOS network relay, clustering, and distributed features.

---

## 🚀 Quick Start

### One-Command Relay Test

```bash
bash relay-auto-test.sh
```

Opens 3 windows automatically:
- Master Node (port 7777)
- Relay Node (port 7778)  
- Worker Node (port 7779)

Press Ctrl+C to close all windows.

### Manual Control

```bash
# Open buddy windows
bash buddy-windows.sh open

# Close all buddy windows
bash buddy-windows.sh close

# Check status
bash buddy-windows.sh status
```

### Test Presets

```bash
bash buddy-presets.sh
```

Choose from preset configurations:
1. **Relay Test** - 3 windows (Master → Relay → Worker)
2. **Cluster Test** - 4 windows (Master + 3 Workers)
3. **Discovery Test** - 2 windows (Monitor + Discovery)
4. **GPU Cluster** - 3 windows (GPU testing)
5. **Development** - 2 windows (Editor + Test terminal)

---

## 📦 Components

### `buddy-windows.sh`

Core buddy window manager.

**Commands:**
```bash
bash buddy-windows.sh open     # Open 3-window relay test
bash buddy-windows.sh close    # Close all buddy windows
bash buddy-windows.sh status   # Show status
```

**Features:**
- Auto-detects terminal emulator (gnome-terminal, konsole, xterm, etc.)
- Arranges windows automatically
- Tracks PIDs for clean shutdown
- Configures each window with appropriate commands

### `relay-auto-test.sh`

One-command relay testing.

**Usage:**
```bash
bash relay-auto-test.sh
```

**Does:**
1. Builds network components if needed
2. Opens 3 buddy windows
3. Starts relay test automatically
4. Waits for Ctrl+C to close all

### `buddy-presets.sh`

Interactive menu for different test scenarios.

**Usage:**
```bash
bash buddy-presets.sh
```

**Presets:**
- Relay testing (3 windows)
- Cluster testing (4 windows)
- Network discovery (2 windows)
- GPU batch testing (3 windows)
- Development mode (2 windows)

---

## 🎯 Use Cases

### Testing Relay System

```bash
bash relay-auto-test.sh
```

Opens Master → Relay → Worker topology.  
Watch messages flow between nodes.

### Testing Cluster

```bash
bash buddy-presets.sh
# Choose: [2] Cluster Test
```

Opens Master + 3 Workers in 2x2 grid.  
Test cluster operations.

### Interactive Discovery

```bash
bash buddy-presets.sh
# Choose: [3] Discovery Test
```

Opens Monitor + Discovery side-by-side.  
Explore network interactively.

### GPU Batch Testing

```bash
bash buddy-presets.sh
# Choose: [4] GPU Cluster
```

Opens GPU-focused windows.  
Test GPU batch operations.

### Development

```bash
bash buddy-presets.sh
# Choose: [5] Development
```

Opens editor + test terminal.  
Code and test side-by-side.

---

## 🛠️ Technical Details

### Window Layout

**Relay Test (3 windows):**
```
┌─────────────┬─────────────┬─────────────┐
│   Master    │    Relay    │   Worker    │
│   :7777     │    :7778    │    :7779    │
└─────────────┴─────────────┴─────────────┘
```

**Cluster Test (4 windows):**
```
┌─────────────┬─────────────┐
│   Master    │  Worker-1   │
│   :7777     │   :7778     │
├─────────────┼─────────────┤
│  Worker-2   │  Worker-3   │
│   :7779     │   :7780     │
└─────────────┴─────────────┘
```

### Terminal Support

Auto-detects and supports:
- `gnome-terminal` (GNOME)
- `konsole` (KDE)
- `xterm` (Universal)
- `xfce4-terminal` (XFCE)
- `tilix` (Tilix)

### Process Management

- PIDs stored in `/tmp/floweros_buddy_windows.pid`
- Clean shutdown with `bash buddy-windows.sh close`
- Auto-cleanup on exit
- Graceful termination

### Window Positioning

Automatically arranges windows:
- Relay test: Side-by-side (left, center, right)
- Cluster test: 2x2 grid
- Discovery test: Side-by-side
- GPU cluster: Side-by-side
- Development: Side-by-side (wide)

---

## 🎨 Customization

### Custom Window Configurations

Edit `buddy-windows.sh` to customize:

```bash
# Change window size
--geometry=80x24+0+0
          ^^^^^
          width x height + x-pos + y-pos

# Change port numbers
./network/build/node_monitor 7777
                             ^^^^
```

### Custom Presets

Add your own presets to `buddy-presets.sh`:

```bash
preset_custom() {
    echo "Opening Custom configuration..."
    
    gnome-terminal --title="Custom Window 1" \
                   --geometry=80x30+0+0 \
                   -- bash -c "
        cd '$SCRIPT_DIR'
        # Your commands here
        bash
    " &
    
    gnome-terminal --title="Custom Window 2" \
                   --geometry=80x30+700+0 \
                   -- bash -c "
        cd '$SCRIPT_DIR'
        # Your commands here
        bash
    " &
}
```

### Custom Commands

Modify what runs in each window by editing the `bash -c` sections.

---

## 🔧 Troubleshooting

### No terminal emulator detected

**Problem:** Script says "No supported terminal emulator found"

**Solution:** Install one:
```bash
# Ubuntu/Debian
sudo apt-get install gnome-terminal

# Fedora
sudo dnf install gnome-terminal

# Arch
sudo pacman -S gnome-terminal
```

### Windows don't close

**Problem:** `bash buddy-windows.sh close` doesn't work

**Solution:** Manually kill processes:
```bash
# Find PIDs
ps aux | grep node_monitor

# Kill them
kill <PID>

# Clean PID file
rm /tmp/floweros_buddy_windows.pid
```

### Windows overlap

**Problem:** Windows open on top of each other

**Solution:** Adjust geometry in `buddy-windows.sh`:
```bash
# Spread windows further apart
--geometry=80x24+0+0      # Window 1
--geometry=80x24+800+0    # Window 2 (increased from 600)
--geometry=80x24+1600+0   # Window 3 (increased from 1200)
```

### Build errors

**Problem:** Network components won't build

**Solution:**
```bash
cd network/
make clean
make all
cd ..
```

---

## 📖 Examples

### Quick Relay Test

```bash
# One command
bash relay-auto-test.sh

# Watch the 3 windows
# Press Ctrl+C to close all
```

### Manual Relay Test

```bash
# Open windows
bash buddy-windows.sh open

# Watch network activity
# Each window shows node monitor

# Close when done
bash buddy-windows.sh close
```

### Cluster Test

```bash
# Open presets menu
bash buddy-presets.sh

# Choose [2] Cluster Test
# See 4 nodes in 2x2 grid

# Close from menu [C]
```

### Development Workflow

```bash
# Open dev windows
bash buddy-presets.sh
# Choose [5] Development

# Left window: Edit code
# Right window: Test changes

# Edit → Test → Repeat
```

---

## 🎯 Tips

1. **Use presets** for common scenarios
2. **Customize geometry** for your screen size
3. **Check status** to see active windows
4. **Close properly** to avoid zombie processes
5. **Save layouts** that work well for you

---

## 🌺 Philosophy

**Multi-terminal testing made simple.**

No more manually opening terminals, typing commands, and arranging windows. Buddy windows automate the tedious parts so you can focus on testing.

Every test session is a garden. 🌸

---

## 📚 See Also

- `test-internet-relay.sh` - Manual relay testing
- `test-linux-network.sh` - Complete network tests
- `NETWORK_ROUTING.md` - Network documentation
- `NODE_MONITOR.md` - Monitor documentation
