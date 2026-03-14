# 🖥️ FlowerOS Node Monitor & Auto-Discovery

## Live Dashboard & Network Linking System

**Version:** FlowerOS v1.3.0-EXPERIMENTAL  
**Component:** Node Monitor & Discovery

---

## ⚠️ RED WARNING: EXPERIMENTAL

**These features are EXPERIMENTAL and NOT production ready.**

DO NOT USE IN PRODUCTION ENVIRONMENTS!

---

## Overview

The FlowerOS Node Monitor and Discovery System provides:

1. **📊 Live Monitoring Dashboard**
   - Black screen with boxed interface
   - Real-time network statistics
   - Upload/download speeds
   - Hardware allocations
   - Node connections
   - Permissions and status

2. **🔍 Auto-Discovery & Linking**
   - Automatic node discovery
   - Hard-coded relationships (early version)
   - Linked list data structure
   - Automatic connection attempts
   - Gateway prioritization

---

## The Concept

### When a Computer Becomes a Node

**You asked for:**
> "When a computer is being a node, it attempts linkage to other nodes (in early versions, just hard code the relationships and network gate relations, maybe in a linked list just because...)"
>
> "All black screen, within a box some live updating text showing things like the network down and up speed, allocations for hardware, node #, perms and so on"

**We delivered:**
- ✅ Black screen TUI dashboard
- ✅ Live-updating network stats
- ✅ Hard-coded relationships in linked list
- ✅ Automatic linkage attempts
- ✅ Network gate relations
- ✅ Hardware allocations display
- ✅ Node number and permissions

---

## Node Monitor

### What It Shows

```
╔═══════════════════════════════════════════════════════════════════════════╗
║              FlowerOS Network Node Monitor                                ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  🌱 NODE INFORMATION                                                      ║
║    Hostname:     mycomputer                                               ║
║    IP Address:   192.168.1.50                                             ║
║    Port:         7777                                                     ║
║    Type:         PLANT                                                    ║
║    Status:       CONNECTED                                                ║
║                                                                           ║
║  📊 NETWORK STATISTICS                                                    ║
║    Upload:       1.24 MB/s                                                ║
║    Download:     3.56 MB/s                                                ║
║    Total Sent:   458.23 MB                                                ║
║    Total Recv:   1.23 GB                                                  ║
║                                                                           ║
║  🌳 CONNECTIONS                                                           ║
║    Root Nodes:   3                                                        ║
║    [████████████████████░░░░░░░░░░░░] 30%                                 ║
║                                                                           ║
║  ⚙️  HARDWARE ALLOCATIONS                                                 ║
║    CPU:          [████████░░░░░░░░░░] 45%                                 ║
║    Memory:       [████████████░░░░░░] 62%                                 ║
║    Network:      [█████░░░░░░░░░░░░░] 28%                                 ║
║                                                                           ║
║  🔒 PERMISSIONS                                                           ║
║    Network:      GRANTED                                                  ║
║    Routing:      GRANTED                                                  ║
║    Cluster:      GRANTED                                                  ║
║                                                                           ║
║  ⚠️  EXPERIMENTAL MODE                                                    ║
║  Last Update: 2026-02-07 14:23:45  |  Press Ctrl+C to exit               ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### Features

**🌱 Node Information:**
- Hostname
- IP address
- Port number
- Node type (SEED, SPROUT, PLANT, FLOWER, TREE, WILTED)
- Connection status

**📊 Network Statistics:**
- Real-time upload speed (bytes/sec → MB/s)
- Real-time download speed (bytes/sec → MB/s)
- Total bytes sent (formatted: B, KB, MB, GB, TB)
- Total bytes received (formatted)

**🌳 Connections:**
- Number of connected root nodes
- Visual progress bar showing connection health

**⚙️ Hardware Allocations:**
- CPU usage (progress bar + percentage)
- Memory usage (progress bar + percentage)
- Network usage (progress bar + percentage)

**🔒 Permissions:**
- Network permission status
- Routing permission status
- Cluster permission status

**⚠️ Status Bar:**
- Experimental mode indicator
- Last update timestamp
- Exit instructions

---

## Usage

### Build

```bash
cd network/
make all
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════════════════╗
║              ⚠️  RED WARNING: EXPERIMENTAL BUILD ⚠️                       ║
╚═══════════════════════════════════════════════════════════════════════════╝

🌱 Compiling Rooting.cpp...
🌱 Linking shared library libflowernetwork.so...
✓ Built: build/libflowernetwork.so
  ⚠️  WARNING: Experimental library

🌱 Creating static library libflowernetwork.a...
✓ Built: build/libflowernetwork.a

🌱 Building terminal network node...
✓ Built: build/terminal_node
  ⚠️  WARNING: Experimental terminal network

🌱 Building node monitor dashboard...
✓ Built: build/node_monitor
  ⚠️  WARNING: Experimental monitoring system

🌱 Building node discovery system...
✓ Built: build/node_discovery
  ⚠️  WARNING: Experimental auto-discovery
```

### Install

```bash
make install
```

Installs to `../bin/`:
- `node_monitor`
- `node_discovery`
- `terminal_node`
- Libraries and headers

---

## Node Monitor Usage

### Basic Usage

```bash
./build/node_monitor
```

Starts monitor on default port 7777, updates every 1 second.

### Custom Port

```bash
./build/node_monitor 7778
```

Starts monitor on port 7778.

### Custom Update Rate

```bash
./build/node_monitor 7777 500
```

Port 7777, updates every 500ms (twice per second).

### Exit

Press **Ctrl+C** to stop monitoring and exit.

---

## Node Discovery

### What It Does

The discovery system manages network node relationships using a **linked list** data structure.

**Early Version Features:**
- Hard-coded node relationships
- Linked list storage
- Gateway vs worker node types
- Automatic connection attempts
- Manual and auto-discovery modes

---

## Network Gate Relations (Linked List)

### Structure

```
Node 0: master_node_01 (192.168.1.100:7777) [GATEWAY]
  |
  v
Node 1: master_node_02 (192.168.1.101:7777) [GATEWAY]
  |
  v
Node 2: worker_node_01 (192.168.1.110:7777)
  |
  v
Node 3: worker_node_02 (192.168.1.111:7777)
  |
  v
Node 4: worker_node_03 (192.168.1.112:7777)
  |
  v
Node 5: gpu_node_01 (192.168.1.120:7777)
```

Each node contains:
- `ip_address` - IP address
- `port` - Port number
- `name` - Node name
- `is_gateway` - Gateway flag
- `next` - Pointer to next node

---

## Hard-Coded Relationships

### Default Nodes

**Gateway Nodes (Masters):**
```cpp
192.168.1.100:7777  (master_node_01)
192.168.1.101:7777  (master_node_02)
```

**Worker Nodes:**
```cpp
192.168.1.110:7777  (worker_node_01)
192.168.1.111:7777  (worker_node_02)
192.168.1.112:7777  (worker_node_03)
192.168.1.113:7777  (worker_node_04)
```

**GPU Nodes:**
```cpp
192.168.1.120:7777  (gpu_node_01)
192.168.1.121:7777  (gpu_node_02)
```

**Localhost (Testing):**
```cpp
127.0.0.1:7777      (localhost_test)
```

---

## Node Discovery Usage

### Interactive Mode

```bash
./build/node_discovery
```

**Menu:**
```
╔═══════════════════════════════════════════════════════════════════════════╗
║              FlowerOS Network Node Discovery Menu                         ║
╚═══════════════════════════════════════════════════════════════════════════╝

  1) Load hard-coded relationships
  2) Scan local network (auto-discover)
  3) Show all relations
  4) Show gateways only
  5) Auto-link to all nodes
  6) Auto-link to gateways only
  7) Clear all relations
  8) Exit

Choose option (1-8):
```

### Options Explained

**1) Load Hard-Coded Relationships**
- Loads default node list (shown above)
- Populates linked list
- Ready for linking

**2) Scan Local Network**
- Prompts for subnet (e.g., "192.168.1")
- Scans .1 through .254
- Finds active FlowerOS nodes
- Adds to linked list

**3) Show All Relations**
- Displays entire linked list
- Shows all discovered nodes
- Gateway status indicated

**4) Show Gateways Only**
- Filters to gateway nodes only
- Master/coordinator nodes
- Primary connection targets

**5) Auto-Link to All Nodes**
- Attempts connection to every node
- Shows success/failure for each
- Reports final statistics

**6) Auto-Link to Gateways Only**
- Connects only to gateways
- Faster than linking all
- Master node connections

**7) Clear All Relations**
- Removes all nodes from list
- Resets to empty state
- Start fresh

**8) Exit**
- Close discovery system
- Shutdown connections

---

## Auto-Linking Process

### Example Session

```
🌿 Attempting to link to discovered nodes...

  Trying: master_node_01 (192.168.1.100:7777) ✓ Connected
  Trying: master_node_02 (192.168.1.101:7777) ✗ Failed
  Trying: worker_node_01 (192.168.1.110:7777) ✓ Connected
  Trying: worker_node_02 (192.168.1.111:7777) ✓ Connected
  Trying: worker_node_03 (192.168.1.112:7777) ✗ Failed
  Trying: worker_node_04 (192.168.1.113:7777) ✓ Connected
  Trying: gpu_node_01 (192.168.1.120:7777) ✓ Connected
  Trying: gpu_node_02 (192.168.1.121:7777) ✗ Failed
  Trying: localhost_test (127.0.0.1:7777) ✓ Connected

Results:
  Successful: 6
  Failed:     3
```

---

## Integration Examples

### Example 1: Monitor Single Node

```bash
# Terminal 1
$ cd network/
$ ./build/node_monitor

# See live dashboard
# Black screen with boxes
# Real-time statistics
```

### Example 2: Discovery + Monitor

```bash
# Terminal 1: Discovery
$ ./build/node_discovery
> 1  # Load hard-coded relations
> 5  # Auto-link to all nodes

# Terminal 2: Monitor
$ ./build/node_monitor
# Watch connections appear in real-time
```

### Example 3: Full Network Setup

```bash
# Terminal 1: Master with monitor
$ flower_grow_tree research_cluster
$ ./build/node_monitor

# Terminal 2: Worker with discovery
$ flower_plant
$ ./build/node_discovery
> 1  # Load relations
> 6  # Link to gateways

# Terminal 3: Worker with monitor
$ flower_plant
$ flower_join_garden 192.168.1.100
$ ./build/node_monitor

# Terminal 4: Pure monitor (observer)
$ ./build/node_monitor
```

---

## Technical Details

### Monitor Implementation

**File:** `network/node_monitor.cpp`

**Key Components:**
1. `NodeMonitor` class - Main dashboard controller
2. `NetworkStats` struct - Statistics tracker
3. ANSI escape codes - Terminal control
4. Drawing functions - Box, text, progress bars
5. Real-time updates - Threaded loop

**Update Cycle:**
1. Read network statistics from Rooter
2. Calculate speeds (delta / elapsed time)
3. Clear screen (black background)
4. Draw boxes with borders
5. Render current data
6. Sleep until next update
7. Repeat

### Discovery Implementation

**File:** `network/node_discovery.cpp`

**Key Components:**
1. `NodeRelation` struct - Single node in list
2. `NetworkGate` class - Linked list manager
3. Hard-coded loading - Default relationships
4. Network scanning - Auto-discovery
5. Auto-linking - Connection automation

**Linked List Operations:**
- `add_relation()` - Append to list
- `get_all()` - Return all nodes
- `get_gateways()` - Filter gateways
- `clear()` - Delete all nodes
- `print()` - Display list

---

## Display Features

### Black Screen Mode

All output uses:
- Black background (`\033[40m`)
- Colored text (green, cyan, yellow, red, white)
- Bold for emphasis
- Box drawing characters (╔╗║╚╝═)

### Progress Bars

Format: `[████████░░░░░░░░░░] XX%`

- Filled: `█` (green)
- Empty: `░` (green)
- Percentage displayed

### Real-Time Updates

- Default: 1000ms (1 second)
- Customizable via command-line
- Smooth refresh (no flicker)
- Cursor hidden during display

---

## Node Types

All node types from Rooter system:

- 🌱 **SEED** - Not planted
- 🌿 **SPROUT** - Establishing
- 🪴 **PLANT** - Worker node
- 🌸 **FLOWER** - GPU-capable
- 🌳 **TREE** - Master/coordinator
- 🥀 **WILTED** - Disconnected

---

## Limitations

### Current Limitations

**Monitor:**
1. Terminal-dependent (requires ANSI support)
2. Hardware stats simulated (not real system data)
3. Fixed box size (doesn't fully adapt to terminal)
4. Limited error recovery

**Discovery:**
1. Hard-coded relationships (early version)
2. No persistent storage
3. Simple network scanning
4. Manual initiation required
5. No automatic reconnection

### Known Issues

1. Terminal resize not handled
2. May flicker on slow terminals
3. Network scanning incomplete
4. No encryption
5. No authentication
6. Race conditions possible

---

## Future Enhancements

### Planned Features (Not Implemented)

**Monitor:**
- [ ] Real hardware statistics (CPU, memory)
- [ ] Historical graphs
- [ ] Alert thresholds
- [ ] Multi-page dashboard
- [ ] Terminal resize handling
- [ ] Color themes
- [ ] Export statistics

**Discovery:**
- [ ] Full network scanning (mDNS, Bonjour)
- [ ] Dynamic relationship management
- [ ] Persistent storage (config file)
- [ ] Automatic reconnection
- [ ] Load balancing
- [ ] Health checks
- [ ] Reputation system

---

## 🔴 Security Warnings

### CRITICAL SECURITY ISSUES

**The monitor and discovery have NO security:**

1. ❌ **No Encryption** - All traffic plain text
2. ❌ **No Authentication** - Anyone can connect
3. ❌ **No Authorization** - No access control
4. ❌ **No Validation** - Data not validated
5. ❌ **Information Disclosure** - Stats visible to all

**DO NOT USE:**
- On untrusted networks
- With sensitive data
- In production environments
- On public internet

---

## Troubleshooting

### Monitor Won't Start

```
✗ Failed to initialize network
```

**Solutions:**
1. Check port not in use: `netstat -tuln | grep 7777`
2. Try different port: `./build/node_monitor 7778`
3. Check firewall: `sudo ufw allow 7777/tcp`

### Discovery Can't Connect

```
Trying: master_node_01 (192.168.1.100:7777) ✗ Failed
```

**Solutions:**
1. Verify target node is running
2. Check network connectivity: `ping 192.168.1.100`
3. Test port: `nc -zv 192.168.1.100 7777`
4. Update IP addresses in hard-coded list

### Monitor Display Garbled

**Solutions:**
1. Terminal must support ANSI codes
2. Use modern terminal (not Windows CMD)
3. Check terminal size (minimum 80x24)
4. Try different terminal emulator

---

## Files

```
FlowerOS Node Monitor & Discovery
├── network/node_monitor.cpp      - Live TUI dashboard
├── network/node_discovery.cpp    - Auto-discovery system
├── network/Makefile              - Build system (updated)
├── demo-node-monitor.sh          - Interactive demo
└── NODE_MONITOR.md               - This documentation
```

---

## See Also

- `TERMINAL_NETWORK.md` - Terminal-as-node system
- `NETWORK_ROUTING.md` - Core network routing
- `Rooter.hpp` - C++ routing API

---

## Conclusion

The FlowerOS Node Monitor and Discovery System provides real-time visibility into your network nodes. With a beautiful TUI dashboard and automatic node linking, managing a distributed FlowerOS network becomes effortless.

**🖥️ Every node gets a dashboard.**  
**🔍 Discovery makes the garden grow automatically.**  
**📊 Monitor everything in real-time.**

---

**FlowerOS v1.3.0 - Node Monitor & Discovery**  
**⚠️ EXPERIMENTAL - NOT PRODUCTION READY ⚠️**

*Where every node shows its roots and branches* 🌱→📊→🌳
