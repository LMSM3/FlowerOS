# FlowerOS v1.3.0 - Decision Tree & User Input Reference

**Visual guide to all decision points and required inputs**

---

## 🌳 Master Decision Tree

```
                              ┌─────────────────────┐
                              │  START: FlowerOS    │
                              │  Deployment         │
                              └──────────┬──────────┘
                                         │
                          ┌──────────────┴──────────────┐
                          │  DECISION 1:                │
                          │  Installation Type?         │
                          └──┬─────────┬────────────┬───┘
                             │         │            │
                ┌────────────┴─┐   ┌──┴───────┐   ┌┴──────────────┐
                │  Quick Test  │   │   User   │   │  Permanent    │
                │  (5 min)     │   │  Install │   │  System-Wide  │
                └──────┬───────┘   │  (10min) │   │  (20 min)     │
                       │           └────┬─────┘   └───────┬────────┘
                       │                │                  │
                       │                │         ┌────────┴────────┐
                       │                │         │  WARNING:       │
                       │                │         │  • Requires sudo│
                       │                │         │  • Modifies /etc│
                       │                │         │  • Immutable    │
                       │                │         └────────┬────────┘
                       │                │                  │
                       └────────────────┴──────────────────┘
                                        │
                          ┌─────────────┴──────────────┐
                          │  DECISION 2:               │
                          │  Enable Network Features?  │
                          └──┬──────────────────────┬──┘
                             │ YES                  │ NO
                   ┌─────────┴───────┐              │
                   │  Network Setup  │              │
                   │  (15 min)       │              │
                   └─────────┬───────┘              │
                             │                       │
                   ┌─────────┴───────────┐          │
                   │  DECISION 3:        │          │
                   │  Network Mode?      │          │
                   └─┬─────┬──────┬────┬─┘          │
                     │     │      │    │            │
               ┌─────┴┐  ┌─┴────┐ │  ┌─┴─────┐     │
               │Single│  │Local │ │  │Cluster│     │
               │ Host │  │ LAN  │ │  │ Multi │     │
               └──────┘  └──────┘ │  └───────┘     │
                                  │                │
                   ┌──────────────┴─────┐          │
                   │  DECISION 4:       │          │
                   │  Which Tools?      │          │
                   └─┬──────────┬──────┬┘          │
                     │          │      │           │
            ┌────────┴─┐  ┌─────┴──┐  ├───────┐   │
            │Terminal  │  │Monitor │  │Discov│   │
            │As Node   │  │Dashbrd │  │ery   │   │
            └──────────┘  └────────┘  └──────┘   │
                                                  │
                       ┌──────────────────────────┘
                       │
          ┌────────────┴─────────────┐
          │  DECISION 5:             │
          │  Enable GPU Features?    │
          └──┬────────────────────┬──┘
             │ YES                │ NO
    ┌────────┴─────────┐          │
    │  GPU Setup       │          │
    │  (10 min)        │          │
    └────────┬─────────┘          │
             │                     │
    ┌────────┴───────────┐        │
    │  DECISION 6:       │        │
    │  Batch Size?       │        │
    └─┬──────┬────────┬──┘        │
      │      │        │           │
   ┌──┴─┐ ┌──┴──┐  ┌──┴────┐     │
   │Small│ │Med  │  │Large/ │     │
   │ 32  │ │128  │  │Custom │     │
   └─────┘ └─────┘  └───────┘     │
                                   │
       ┌───────────────────────────┘
       │
  ┌────┴──────────────────┐
  │  DECISION 7:          │
  │  Post-Config Options  │
  └─┬──────────┬──────┬───┘
    │          │      │
 ┌──┴────┐ ┌──┴──┐ ┌─┴────┐
 │Theme  │ │Start│ │Shell │
 │Select │ │Mode │ │Integ │
 └───────┘ └─────┘ └──────┘
                │
         ┌──────┴───────┐
         │   COMPLETE   │
         │   FlowerOS   │
         │   Deployed   │
         └──────────────┘
```

---

## 📊 User Input Requirements by Section

### INPUT SET 1: Basic Installation

```
┌─────────────────────────────────────────────────────────────┐
│ REQUIRED INPUTS FOR BASIC INSTALLATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 1. Installation Type                                        │
│    Input: [A/B/C] _____                                     │
│    Options:                                                 │
│      A = Quick test                                         │
│      B = User install                                       │
│      C = System permanent                                   │
│                                                             │
│ 2. Installation Location (if not using defaults)           │
│    Input: /path/to/location _____                           │
│    Example: /home/user/software/FlowerOS                    │
│                                                             │
│ 3. Sudo Password (for system install only)                 │
│    Input: ********                                          │
│                                                             │
│ 4. Confirm Permanent Install (if type C)                   │
│    Input: I UNDERSTAND THE RISKS                            │
│    Must type exactly: "I UNDERSTAND THE RISKS"              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### INPUT SET 2: Network Configuration

```
┌─────────────────────────────────────────────────────────────┐
│ REQUIRED INPUTS FOR NETWORK SETUP                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 1. Enable Network?                                          │
│    Input: [Y/N] _____                                       │
│                                                             │
│ 2. Network Deployment Mode (if Y)                          │
│    Input: [S/L/C/N] _____                                   │
│    Options:                                                 │
│      S = Single machine (localhost)                         │
│      L = Local network (LAN)                                │
│      C = Cluster/multi-machine                              │
│      N = No network                                         │
│                                                             │
│ 3. Network Port Number                                      │
│    Input: _____ (default: 7777)                             │
│    Range: 1024-65535                                        │
│                                                             │
│ 4. Network Tools Selection                                  │
│    Input: [1,2,3,4] _____ (comma-separated)                 │
│    Options:                                                 │
│      1 = Terminal-as-node                                   │
│      2 = Node monitor                                       │
│      3 = Node discovery                                     │
│      4 = All tools                                          │
│                                                             │
│ 5. Node Type (if terminal-as-node)                         │
│    Input: [P/T/J] _____                                     │
│    Options:                                                 │
│      P = Plant (worker)                                     │
│      T = Tree (master) → requires cluster name              │
│      J = Join (worker) → requires master IP                 │
│                                                             │
│ 6. Cluster Name (if Tree)                                  │
│    Input: _____________ (e.g., "research_cluster")          │
│                                                             │
│ 7. Master IP Address (if Join)                             │
│    Input: ___.___.___.___                                   │
│    Example: 192.168.1.100                                   │
│                                                             │
│ 8. Configure Hardcoded Relationships?                       │
│    Input: [Y/N] _____                                       │
│                                                             │
│ 9. Node IPs (if Y to #8, for each node)                    │
│    Master IPs: ___.___.___.___  (one per line)              │
│    Worker IPs: ___.___.___.___  (one per line)              │
│    GPU IPs:    ___.___.___.___  (one per line)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### INPUT SET 3: GPU Configuration

```
┌─────────────────────────────────────────────────────────────┐
│ REQUIRED INPUTS FOR GPU SETUP                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 1. Enable GPU?                                              │
│    Input: [Y/N] _____                                       │
│                                                             │
│ 2. GPU Architecture (if Y)                                  │
│    Input: sm___ (e.g., sm_75, sm_86)                        │
│    Find yours: nvidia-smi                                   │
│                                                             │
│ 3. Batch Size                                               │
│    Input: [S/M/L/C] _____                                   │
│    Options:                                                 │
│      S = Small (32 items)                                   │
│      M = Medium (128 items)                                 │
│      L = Large (512 items)                                  │
│      C = Custom → requires number                           │
│                                                             │
│ 4. Custom Batch Size (if C)                                │
│    Input: _____ (number of items)                           │
│    Recommended: 32-1024                                     │
│                                                             │
│ 5. GPU Memory Limit                                         │
│    Input: _____ MB (optional)                               │
│    Default: auto-detect                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### INPUT SET 4: Post-Deployment Configuration

```
┌─────────────────────────────────────────────────────────────┐
│ REQUIRED INPUTS FOR POST-DEPLOYMENT SETUP                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 1. Shell Integration                                        │
│    Input: [B/Z/F/A] _____ (can select multiple)             │
│    Options:                                                 │
│      B = Bash                                               │
│      Z = Zsh                                                │
│      F = Fish                                               │
│      A = All available                                      │
│                                                             │
│ 2. Startup Behavior                                         │
│    Input: [Q/W/F/C] _____                                   │
│    Options:                                                 │
│      Q = Quiet (no output)                                  │
│      W = Welcome message                                    │
│      F = Full banner + fortune                              │
│      C = Custom → requires message                          │
│                                                             │
│ 3. Custom Startup Message (if C)                           │
│    Input: ________________________________                   │
│                                                             │
│ 4. Theme Selection                                          │
│    Input: [1/2/3/4/5/N] _____                               │
│    Options:                                                 │
│      1 = Botanical                                          │
│      2 = Ocean                                              │
│      3 = Sunset                                             │
│      4 = Matrix                                             │
│      5 = Custom → requires color codes                      │
│      N = No theme (default)                                 │
│                                                             │
│ 5. Custom Theme Colors (if 5)                              │
│    Primary:   #______ (hex color)                           │
│    Secondary: #______ (hex color)                           │
│    Accent:    #______ (hex color)                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### INPUT SET 5: Multi-Machine Deployment

```
┌─────────────────────────────────────────────────────────────┐
│ REQUIRED INPUTS FOR MULTI-MACHINE DEPLOYMENT                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 1. Deployment Strategy                                      │
│    Input: [S/P/M] _____                                     │
│    Options:                                                 │
│      S = Sequential                                         │
│      P = Parallel (Ansible)                                 │
│      M = Manual                                             │
│                                                             │
│ 2. Target Machines (if S or P)                             │
│    Machine 1: username@___.___.___.___                      │
│    Machine 2: username@___.___.___.___                      │
│    Machine 3: username@___.___.___.___                      │
│    ... (add as many as needed)                              │
│                                                             │
│ 3. SSH Password/Key (for each machine)                     │
│    Method: [Password/Key] _____                             │
│    If Password: ********                                    │
│    If Key: /path/to/key _____                               │
│                                                             │
│ 4. Install Type for All Machines                           │
│    Input: [User/System] _____                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Decision Path Calculator

### Use this flowchart to calculate your path:

```
START
  │
  ├─ Installation Type? ────────────────────────┐
  │  • Quick Test [A]        = 5 min            │
  │  • User Install [B]      = 10 min           │
  │  • Permanent System [C]  = 20 min           │
  │                                             │
  ├─ Network Features? ─────────────────────────┤
  │  • Yes [Y]               = +15 min          │
  │  • No [N]                = +0 min           │
  │                                             │
  ├─ GPU Features? ──────────────────────────────┤
  │  • Yes [Y]               = +10 min          │
  │  • No [N]                = +0 min           │
  │                                             │
  ├─ Post-Config? ───────────────────────────────┤
  │  • Themes [T]            = +5 min           │
  │  • Full config [F]       = +10 min          │
  │  • Skip [S]              = +0 min           │
  │                                             │
  └─ TOTAL TIME = Sum of all choices            │
                                                 │
EXAMPLE PATHS:                                   │
                                                 │
Path 1: Quick Test, No extras                   │
  A + N + N + S = 5 min                         │
                                                 │
Path 2: User install with network               │
  B + Y + N + S = 25 min                        │
                                                 │
Path 3: Full system with everything             │
  C + Y + Y + F = 55 min                        │
```

---

## 📝 Input Validation Rules

### Port Numbers
```
Valid range: 1024-65535
Reserved ports: 1-1023 (require root)
Common FlowerOS port: 7777
Avoid: 22 (SSH), 80 (HTTP), 443 (HTTPS), 3306 (MySQL)

Validation:
  if port < 1024: REJECT (requires root)
  if port > 65535: REJECT (invalid)
  if port in [22,80,443,3306,...]: WARN (commonly used)
  else: ACCEPT
```

### IP Addresses
```
Format: XXX.XXX.XXX.XXX
Valid range per octet: 0-255

Private ranges (recommended):
  10.0.0.0 - 10.255.255.255
  172.16.0.0 - 172.31.255.255
  192.168.0.0 - 192.168.255.255

Validation:
  if not matching pattern: REJECT
  if public IP: WARN (security risk)
  if private IP: ACCEPT
```

### Cluster Names
```
Valid characters: a-z, A-Z, 0-9, _ (underscore), - (hyphen)
Length: 3-32 characters
Cannot start with: number, hyphen
Cannot end with: hyphen

Examples:
  ✓ research_cluster
  ✓ lab-01
  ✓ my_gpu_farm
  ✗ 1cluster (starts with number)
  ✗ -cluster (starts with hyphen)
  ✗ cluster- (ends with hyphen)
```

### Theme Colors
```
Format: #RRGGBB
Valid characters: 0-9, A-F (hex)

Examples:
  ✓ #00FF00 (green)
  ✓ #FF5733 (orange-red)
  ✗ #GG0000 (invalid hex)
  ✗ 00FF00 (missing #)
```

---

## 🎯 Common Decision Patterns

### Pattern 1: Developer Workstation
```
Decisions:
  - Install: User [B]
  - Network: Yes, Local [Y, L]
  - Tools: Terminal-as-node + Monitor [1,2]
  - GPU: No [N]
  - Shell: Bash + Zsh [B,Z]
  - Startup: Quiet [Q]
  - Theme: Matrix [4]

Time: ~25 minutes
Complexity: Medium
```

### Pattern 2: Production Server
```
Decisions:
  - Install: Permanent System [C]
  - Network: No [N] (security)
  - GPU: No [N]
  - Shell: Bash only [B]
  - Startup: Quiet [Q]
  - Theme: None [N]

Time: ~20 minutes
Complexity: Low
```

### Pattern 3: ML/AI Cluster
```
Decisions:
  - Install: Permanent System [C]
  - Network: Yes, Cluster [Y, C]
  - Tools: All [4]
  - Node Type: Tree [T]
  - Cluster Name: ml_cluster
  - GPU: Yes [Y]
  - Batch: Large [L]
  - Multi-machine: Parallel [P]

Time: ~60 minutes
Complexity: High
```

### Pattern 4: Educational Lab
```
Decisions:
  - Install: Permanent System [C]
  - Network: Yes, Local [Y, L]
  - Tools: All [4]
  - Node Type: Tree [T]
  - GPU: No [N]
  - Shell: All [A]
  - Startup: Full [F]
  - Theme: Botanical [1]
  - Multi-machine: Parallel [P]

Time: ~50 minutes per batch
Complexity: Medium-High
```

---

## 📋 Pre-Deployment Checklist

Before starting, ensure you have:

```
□ System Requirements
  □ Linux OS (Debian/Ubuntu/similar)
  □ Bash 4.0 or newer
  □ GCC compiler (build-essential)
  □ Root access (for system install)
  □ 50MB free disk space

□ Network Requirements (if enabling network)
  □ Network connectivity
  □ Firewall rules configured
  □ IP addresses documented
  □ Port 7777 available (or custom port)

□ GPU Requirements (if enabling GPU)
  □ NVIDIA GPU present
  □ CUDA installed
  □ nvidia-smi working
  □ GPU architecture known

□ Documentation Review
  □ Read README.md
  □ Read RED_WARNING_SUMMARY.md
  □ Understand permanent install implications

□ Backup Preparation
  □ Backup ~/.bashrc
  □ Backup /etc/bash.bashrc (system install)
  □ Document current configuration
  □ Test restore process

□ Access Credentials
  □ Sudo password ready
  □ SSH keys configured (multi-machine)
  □ Git access configured

□ Time Allocation
  □ Estimated time calculated
  □ Uninterrupted time block scheduled
  □ Rollback time budgeted (if needed)
```

---

## 🚨 Critical Decision Points

### These decisions CANNOT be easily reversed:

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║  PERMANENT DECISIONS (Cannot easily undo)                     ║
║                                                               ║
║  1. Permanent System Installation                            ║
║     Once installed with immutable flags, requires            ║
║     manual removal process                                    ║
║                                                               ║
║  2. System File Modifications                                ║
║     Changes to /etc/bash.bashrc affect all users             ║
║     immediately                                               ║
║                                                               ║
║  3. Multi-Machine Deployment                                  ║
║     Parallel deployment to multiple machines is              ║
║     difficult to roll back                                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

RECOMMENDATION: Test on single machine first!
```

---

## 📊 Decision Matrix Reference

| Feature | Quick Test | User Install | System Install |
|---------|-----------|--------------|----------------|
| Time | 5 min | 10 min | 20 min |
| Scope | Current session | User account | All users |
| Permissions | User | User | Root |
| Reversible | ✓ Easy | ✓ Medium | ✗ Difficult |
| Network | Optional | Optional | Optional |
| GPU | Optional | Optional | Optional |
| Production | ✗ No | ✓ Limited | ✓ Yes |

---

**FlowerOS v1.3.0 - Decision Tree & User Input Reference**  
*Every decision documented. Every input defined.* 📊🌱
