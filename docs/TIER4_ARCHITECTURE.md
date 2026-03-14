# FlowerOS — 5-Tier Architecture

**FlowerOS: The Universal Operating System**

Every task executed beautifully on GPU, terminals united, fast, themed.

---

## The 5 Tiers

| Tier | Target | What It Is | Status |
|------|--------|-----------|--------|
| **1** | Fresh Linux drive | **Full OS.** Boot into FlowerOS. | Planned |
| **2** | Existing Linux/Windows | **Base Kernel wrapper.** Intercepts and beautifies. | Prototype (`kernel/`) |
| **3** | WSL (safe) | **User sandbox + experimental desktop live window.** | Partial |
| **4** | Windows native | **State store + IPC bus.** Every terminal is a client. | **Scaffolded** (`tier4/`) |
| **5** | Linux / WSL power | **Current implementation.** Network, GPU, themes. | Active (`v1.3.X`) |

---

## Tier 4: Windows Substrate

Two things, not mixed:

### A) Persistent State Store

```
%LOCALAPPDATA%\FlowerOS\state\
├── state.json      ← authoritative state
├── schema.json     ← validation
└── audit.log       ← optional change log
```

**What's stored:**

| Object | Example |
|--------|---------|
| `system.USER` | `"alice"` |
| `system.DESKTOP` | `"C:\Users\alice\Desktop"` |
| `system.HOSTNAME` | `"WORKSTATION-01"` |
| `drives.DRIVE_LIST` | `[{"letter":"C:","type":"fixed"}, ...]` |
| `shell.DEFAULT_SHELL` | `"pwsh.exe"` |
| `shell.TERMINAL_PROFILES` | `[{"name":"Windows Terminal","exe":"wt.exe"}, ...]` |
| `features.gpu_enabled` | `true` |
| `features.theme` | `"botanical"` |
| `floweros.TIER` | `4` |

**Why not registry:**
- Awful for structured state, diffing, backup, sync, tooling.
- You'll hate yourself the first time you try to migrate it.

### B) IPC Bus (Named Pipe)

```
\\.\pipe\floweros\comm
```

- **Broker process** owns the pipe and the authoritative state.
- **Clients** (PowerShell, bash, exe tools) send NDJSON requests.
- **Message format:** One JSON object per line, terminated by `\n`.

```
→  {"op":"get","key":"system.USER"}
←  {"ok":true,"value":"alice"}

→  {"op":"set","key":"features.gpu_enabled","value":true}
←  {"ok":true}

→  {"op":"snapshot"}
←  {"ok":true,"state":{...}}

→  {"op":"refresh_drives"}
←  {"ok":true,"drives":[...]}

→  {"op":"ping"}
←  {"ok":true,"pong":true}
```

### C) Protection

**Real protection (the part that matters):**
- ACLs on `%LOCALAPPDATA%\FlowerOS\` — only the user can read/write.
- DPAPI for anything sensitive (tokens, keys) — encrypted bound to user context.

**Obscurity (optional, not relied on):**
- Non-obvious paths, filenames — annoyance only, not security.

---

## Tier 4 Files

```
tier4/
├── broker.h          ← API header
├── broker.c          ← Broker implementation (named pipe server + state)
├── client.ps1        ← PowerShell client (how terminals talk to broker)
├── Makefile          ← Build
└── state/
    ├── state.json    ← Default state template
    └── schema.json   ← JSON schema for validation
```

### Build

```cmd
cd tier4
gcc -O2 -o broker.exe broker.c -ladvapi32 -lcrypt32
```

### Run

```cmd
:: Start broker (Terminal 1)
broker.exe

:: Connect from PowerShell (Terminal 2)
. .\client.ps1
flower_status
flower_drives
flower_user
```

### Operations

| Op | Request | What It Does |
|----|---------|-------------|
| `ping` | `{"op":"ping"}` | Health check |
| `get` | `{"op":"get","key":"system.USER"}` | Read state value |
| `set` | `{"op":"set","key":"...","value":...}` | Write state value |
| `snapshot` | `{"op":"snapshot"}` | Full state dump |
| `refresh_drives` | `{"op":"refresh_drives"}` | Re-detect drives |
| `shutdown` | `{"op":"shutdown"}` | Stop broker |

---

## How Tiers Connect

```
Tier 1 (Full OS)
  └── Tier 2 (Kernel wrapper)
        └── Tier 5 (Linux power)     ← network, GPU, themes
              └── Tier 3 (WSL safe)  ← desktop live window
        └── Tier 4 (Windows)         ← state + IPC bus
              └── All terminals are clients
```

**Tier 4 is the substrate.** Everything else is a client.

On Windows, when FlowerOS starts:
1. Broker launches (pipe opens, state loads)
2. System detection runs (USER, DESKTOP, DRIVES, TERMINALS)
3. Each terminal sources `client.ps1` on startup
4. Terminals can read/write shared state
5. Theme/GPU/network features coordinate through the bus

---

## What's Next

- [ ] Broker → background service (no visible window)
- [ ] Tray icon for status / quick controls
- [ ] WSL client (bash talking to Windows pipe via `/mnt/c/` or `socat`)
- [ ] State versioning (migration between FlowerOS versions)
- [ ] Multi-user support (per-user broker instances)
- [ ] Tier 3 desktop live window prototype
- [ ] Tier 1 bootable ISO research
