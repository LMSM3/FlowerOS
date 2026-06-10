# Claude Instructions

## Project Guidelines
- FlowerOS is the user's "golden project." It is intended to be a real operating system with 5 installation tiers: (1) Full Linux OS installable on a fresh drive, (2) Base Kernel wrapper over existing OS, (3) WSL safe user-based installation with experimental desktop live window, (4) Windows terminal coordinator with persistent communication layer storing $USER/$DESKTOP/$DRIVE_LIST as semi-protected objects, (5) Linux power install (current implementation). All GPU work should be real physical modeling, not visual-only approximations. The project philosophy: every task executed beautifully on GPU, terminals united, fast, themed.

## Version Roadmap

### 🌼 Pollen — Beta (March 2026)
- **Status:** 🟡 Beta — Active Development
- **Branch:** `pollen-beta`
- **Target:** March 2026
- **Focus:** Foundation release consolidating v1.2.X stable features with early v1.3.X experimental integrations into a unified beta. Establishes the baseline for the next-generation FlowerOS release cycle.
- **Includes:**
  - Core FlowerOS subsystems (ASCII, theming, terminal integration)
  - Tier 4 Windows broker architecture
  - Flower AI subsystem (optional, isolated)
  - GPU physical modeling pipeline
  - Early system-level integration (from v1.3.X, stabilized)

### 🌻 SunFlower — Release (End of April 2026)
- **Status:** 📋 Planned
- **Branch:** `sunflower-release`
- **Target:** End of April 2026
- **Focus:** Production-ready release derived from Pollen Beta. Stability, documentation completeness, and full tier support. The "dependable daily driver" edition.
- **Goals:**
  - All Pollen Beta features hardened and production-ready
  - Complete documentation and installation guides for all 5 tiers
  - Full test coverage for core subsystems
  - Performance-tuned GPU pipeline
  - Polished theming and visual experience

### 🌸 Wildflower — Release (End of April 2026)
- **Status:** 📋 Planned
- **Branch:** `wildflower-release`
- **Target:** End of April 2026
- **Focus:** Experimental/advanced companion release alongside SunFlower. Pushes boundaries with cutting-edge features, system-deep integration, and network capabilities. The "adventurous power user" edition.
- **Goals:**
  - All SunFlower features as baseline
  - Advanced network routing and remote sync (stabilized from v1.3.X)
  - Deep system-level integration and permanent installation
  - Extended Flower AI task modes and model support
  - Experimental desktop live window (Tier 3 WSL)

### Release Flow
```
Pollen (Beta, March 2026)
    │
    ├──► SunFlower (Stable Release, End of April 2026)
    │
    └──► Wildflower (Advanced Release, End of April 2026)
```

---

## Recent Ideas & Work → Version Mapping

The following features and subsystems have been built or prototyped in the workspace.
Each is mapped to its target release.

### 🌼 Pollen Beta Candidates (March 2026 baseline)

| Area | Work Done | Files / Location | Notes |
|------|-----------|------------------|-------|
| **Core 5 C Subsystems** | ✅ Complete | `src/` — random, animate, banner, fortune, colortest | Stable since v1.2.X. Pollen baseline. |
| **Shell Functions (8)** | ✅ Complete | `.flowerrc` — flower_pick_ascii_line, flower_banner, flower_animate, flower_fortune, flower_colortest | Production-ready, theme-aware. |
| **Banner Library** | ✅ Complete | `lib/banners.sh`, `lib/banners.py` | Unified box/section/status API; bash + Python parity. Several demo scripts still need migration (see `BANNER_LIBRARY_STATUS.md`). |
| **Visual Output System** | ✅ Complete | `lib/visual.c`, `lib/visualize.sh` | Bar charts, sparklines, progress bars, live dashboards. Added in v1.2.4 "Clarity." |
| **Breathtaking Experience** | ✅ Complete | `features/v1.2/visual-experience/` | ASCII art welcome, Nerd Font icons, 3 themes (Dracula/Tokyo Night/Nord), transparency, Windows Terminal + VS Code settings. |
| **Theming Engine** | ✅ Complete | `features/v1.1/theming/`, `features/v1.1/theming-pro/` | Bash + PowerShell engines, theme installer, pro theming guide. |
| **Flower Walk Animation** | ✅ Dual impl | `features/flower_walk.sh` ↔ `src/utils/flower_walk.c` | Shell bootstrap + C backend (60fps). Color-token architecture, auto-delegates to compiled binary. |
| **Code Cleanup / Dedup** | ✅ Audited | `docs/archive/changes_20260124.md` | Duplicate helpers (ok/err/info), GCC checks across compile.sh/build.sh. Recommendation: extract `lib/colors.sh` + `lib/helpers.ps1`. Finish for Pollen. |
| **Build System (PS1)** | ✅ Complete | `build-complete.ps1` | Compiles broker, all 5 core utils, GPU detection, network. GCC toolchain required. |
| **Flower AI — API Skeleton** | ✅ Scaffolded | `lib/flower_ai/` | `flower_ai.h` public API, detect/session/backend split, Makefile, CUDA optional. Ready for model integration in Pollen. |
| **MOTD Injection System** | ✅ Complete | `share/motd/inject.d/`, `bin/flower-motd-inject-install.sh` | Layer-1 shell injectors (weather, stocks, news, reminders, random facts) + Layer-2 Python providers. Precedent for the Bee Injection architecture. |
| **Cross-Tier Translation Layer** | 📋 Designed | `translate-sh-to-ps1.ps1` (proposed) | Tier 0 bash↔PowerShell dual-execution tooling. Tokenizer → IR → codegen with embedded bash fallback. Produces hybrid scripts with `# REVIEW MANUALLY` markers. Enables Tier 3/4 Windows ↔ Tier 5 Linux compatibility. |

### 🌻 SunFlower Release Candidates (End of April 2026 — Stable)

| Area | Work Done | Target for SunFlower | Notes |
|------|-----------|----------------------|-------|
| **Tier 4 Windows Broker** | ✅ Scaffolded | Harden & ship | `src/tier4/broker.c` (500+ lines), named pipe IPC, NDJSON, DPAPI. Needs production hardening, error recovery, installer. |
| **State Store + Schema** | ✅ Complete | Ship as-is | `tier4/state/state.json` + `schema.json`. System/drive/shell/feature/network objects. |
| **GPU Detection Utility** | ✅ Complete | Ship as stable | `src/utils/gpu-detect.c` (400+ lines). Windows SetupAPI / Linux lspci. Honest "CPU fallback" messaging. |
| **5-Tier Architecture Doc** | ✅ Written | Finalize for all tiers | `docs/TIER4_ARCHITECTURE.md`. Tier 1-5 matrix, IPC protocol spec, state schema. |
| **Banner Migration** | 🟡 Partial | Complete all scripts | 4 high-priority demo scripts still use hand-rolled boxes (`demo-bare-metal-hpc.sh`, `demo-network-routing.sh`, `demo-node-monitor.sh`, `demo-terminal-network.sh`). |
| **Flower AI — Hardware Tiers** | ✅ Designed | Wire detection → session | Tier A/B/C auto-detect exists in `flower_ai_detect.c`. Needs end-to-end path: detect → configure → load model → prompt. |
| **Documentation Sweep** | 🟡 In Progress | All tiers documented | 15+ archive docs exist. Consolidate into a single coherent guide per tier for SunFlower. |
| **Version Selector** | ✅ Exists | Update for new codenames | `version-selector.sh`, `version-selector.ps1`. Currently selects v1.2.X/v1.3.X. Extend to Pollen/SunFlower/Wildflower. |
| **VSEPR Molecular Viz** | ✅ Feature-complete | Polish & integrate | Interactive 3D viz with ImGui (Windows 11 theme, ray-casting picker, 118-element DB, analysis panel, PBC, animations). Candidates for Tier 3 desktop window. |
| **Environment + Identity Layer** | 📋 Designed | Wire into broker + state | Managed runtime identity system: node_id, environment tiers (0→5), config validation phases. Assigning meaning to machines — what platforms do. Wire into Tier 4 state store and node coordination. |
| **Cross-Tier Translation** | 📋 Designed | Ship Tier 0 tooling | `translate-sh-to-ps1.ps1` for auto-converting low-risk scripts. PowerShell wrappers (`build.ps1`, `test-all.ps1`) that delegate to bash/WSL. Dual-execution output with native + fallback blocks. |

### 🌸 Wildflower Release Candidates (End of April 2026 — Advanced)

| Area | Work Done | Target for Wildflower | Notes |
|------|-----------|----------------------|-------|
| **Network Routing** | ✅ Implemented | Stabilize & ship | `network/Rooter.hpp` + `Rooting.cpp` (900+ lines). Botanical node naming, socket routing, discovery, cluster management. RED/experimental today — graduate to Wildflower. |
| **Node Monitor TUI** | ✅ Implemented | Stabilize & ship | `network/node_monitor.cpp` (470 lines). Black-screen live dashboard: up/down speeds, hardware bars, node info, permissions. Exactly the user's vision. |
| **Auto-Discovery & Linkage** | ✅ Implemented | Stabilize & ship | Hard-coded relationships in linked list (early version), network gate relations. Ready for dynamic discovery in Wildflower. |
| **Buddy Window System** | ✅ Complete | Ship with network | `buddy-windows.sh`, `relay-auto-test.sh`, `buddy-presets.sh`. Multi-terminal management for relay testing. 5 preset layouts. |
| **Permanent System Install** | ✅ Implemented | Ship as advanced option | `install-permanent.sh` → `/opt/floweros`, `/etc/floweros/.flowerrc`, immutable flags, systemd service. v1.3.X experimental → Wildflower supported. |
| **Kernel Subsystem** | ✅ Prototype | Continue development | `kernel/flower_kernel.{h,c}`, user DB (XML), botanical permission model (Seed→Root), IPC "Pollination." |
| **GPU Batch / HPC** | ✅ Documented | Wire real CUDA paths | GPU_FEATURES.md shows 42-286x speedup targets. Currently CPU-only. Wildflower target: real CUDA kernels for ASCII/banner/animation batch. |
| **Flower AI — Full Inference** | 🟡 Skeleton | Model loading + prompt | Backend firewall (`flower_ai_backend.cpp`) ready for BitNet vendor integration. Wildflower target: real local inference with Tier A GPU. |
| **Tier 3 WSL Desktop Window** | 📋 Planned | Prototype | VSEPR interactive viz (ImGui/OpenGL) is the technology proof. Wildflower target: experimental desktop live window in WSL. |
| **Bare Metal / Tier 1 OS** | 📋 Planned | Early exploration | `demo-bare-metal-hpc.sh` documents the vision. Wildflower opens the door to early bootloader experiments. |
| **🐝 FlowerOS Injection Layer** | 📋 Designed | Phase 1 target | See dedicated section below. Bee Injection Runtime (BIR) / Apis Layer. One bee, one body, one renderer, one telemetry mapping, one update loop. |

### Summary: What's Ready vs. What Needs Work

```
Ready for Pollen (March 2026):
  ✅ Core 5 C subsystems          ✅ Shell functions (.flowerrc)
  ✅ Banner library (sh + py)     ✅ Visual output system
  ✅ Theming engine               ✅ Breathtaking experience
  ✅ Flower walk (sh + C)         ✅ Build system (ps1)
  ✅ Flower AI skeleton           ✅ MOTD injection system
  🟡 Code dedup (finish extraction)
  📋 Cross-tier translation layer (design ready)

Harden for SunFlower (April 2026):
  ✅→🔧 Tier 4 broker             ✅→🔧 GPU detection
  ✅→🔧 State store               🟡 Banner migration (4 scripts)
  🟡 Doc consolidation            ✅→🔧 Version selector update
  ✅→🔧 VSEPR viz polish          ✅→🔧 AI hardware→session wiring
  📋 Environment + identity layer  📋 Cross-tier translation (ship)

Graduate for Wildflower (April 2026):
  🔴→🟡 Network routing           🔴→🟡 Node monitor TUI
  🔴→🟡 Auto-discovery            🔴→🟡 Permanent install
  🔴→🟡 Kernel prototype          🔴→🟡 GPU batch/HPC (real CUDA)
  🟡 AI full inference             📋 Tier 3 WSL desktop
  📋 Tier 1 bare metal             📋 Bee AI Phase 1 (injection layer)
```

---

## Tier 4 Architecture (Windows)
- **State store:** `%LOCALAPPDATA%\FlowerOS\state\state.json` — NOT registry. JSON or SQLite for structured state.
- **IPC bus:** Named Pipe `\\.\pipe\floweros\comm` with broker process. NDJSON request/response. No custom binary protocols.
- **Protection:** ACLs + DPAPI for real security. Obscurity is annoyance only, never relied on.
- **Clients:** PowerShell, bash, exe tools all talk to broker. Everything (themes, GPU, network) is a client of this substrate.
- **Code lives in:** `tier4/` — broker.c, broker.h, client.ps1, state/

## Python Script Guidelines
- Write Python scripts only if they are reusable and will be used at least twice. Avoid creating one-off Python scripts just to perform a single task (e.g., writing a file).

## Flower AI Subsystem
- Flower AI is an **optional** local desktop inference subsystem. It is NOT mandatory for base FlowerOS operation.
- **Architecture:** All AI code lives in `lib/flower_ai/`. The rest of FlowerOS talks only to `flower_ai.h`. No vendor headers, no backend types, no model formats leak outside that directory.
- **Build isolation:** `FLOWER_ENABLE_AI=0` removes it entirely. If AI is absent, FlowerOS still boots, commands still work, AI commands display a clean notice. No crashes.
- **Backend firewall:** `flower_ai_backend.cpp` is the only file that touches vendor/upstream libraries. Do not let raw backend calls spread across the codebase.
- **Hardware tiers:**
  - Tier A (desktop GPU, ≥8GB VRAM)
  - Tier B (laptop/midrange)
  - Tier C (CPU fallback). Auto-detected, graceful degradation.
- **Task modes:** assistant, shell, code, report, summarize, analyze. Not just chat.
- **Vendor target:** BitNet (Microsoft) via `vendors/`. Version-pinned, replaceable.
- **Policy:** Optional at build time, optional at runtime, isolated behind one API, version-pinned, replaceable later.

---

## 🐝 FlowerOS Injection Layer — Live Digital Bee AI

### Definition

**FlowerOS Injection** is a runtime coupling framework in which the FlowerOS environment continuously supplies identity, telemetry, theme, and environmental state into a VSEPR-SIM-driven digital organism. The OS does not merely launch the Bee AI — it continuously feeds, styles, hosts, and projects it. The bee is not an app. It becomes a **resident system organism**.

### Formal Name Options
- **Bee Injection Runtime (BIR)** — A FlowerOS runtime subsystem that maps system telemetry and environmental state into a VSEPR-SIM-driven live bee entity.
- **Apis Layer** — A biologically themed projection layer for FlowerOS identity and telemetry.

### What "Injection" Means Here

Not malware. FlowerOS injects into the bee system:
- **Runtime state:** temperature, time of day, node load, local theme, user mode, hardware profile
- **Identity:** rose / seed / GPU phase, palette family, node role, deployment tier
- **Display surfaces:** terminal shell, telemetry petals, live graph stream, renderer window, logging interface
- **Behavior modifiers:** chaos factor, motion mode, swarm density, energy ceiling, local intelligence profile

### VSEPR-SIM Version Split

| Version | Role | Purpose |
|---------|------|---------|
| **v3.0.1.1** | Formation engine | Bead/body structure generation, initial morphology, deterministic base organism layout |
| **v3.0.1.2** | Live update engine | Behavioral perturbation, injection-aware environment response, swarm/runtime adaptation |

> v3.0.1.1 = **form the bee**. v3.0.1.2 = **make it live**.

This is a rare case where version splitting is actually useful instead of ceremonial.

### Why VSEPR-SIM Is the Right Base

The VSEPR-SIM engine already thinks in terms of:
- discrete state
- structured interactions
- environment-dependent evolution
- deterministic or semi-stochastic progression
- layered scales

For Bee AI, the claim is NOT "a bee is literally chemistry." The engine is used as a **multi-state formation and behavior kernel** — the correct abstraction.

### Bee Model Layers

#### 1. Structural Layer (bead hierarchy)
- **Body parts:** head, thorax, abdomen, wing anchors, leg chains, antennae, optional pollen payload nodes
- **Per-bead properties:** position, orientation, mass-like weight, response type, color/material tag, interaction radius, local energy state

#### 2. Motion Layer (never static)
- Wing oscillation model
- Body tilt
- Landing / crawl / hover / pollination postures

#### 3. Intelligence Layer (not AGI — just local decisions)
- Local target selection + flower attraction
- Obstacle avoidance
- Return-to-base behavior
- Energy seeking
- Swarm alignment

#### 4. Environmental Injection Layer (FlowerOS feeds)

| FlowerOS Signal | Bee Behavior Effect |
|-----------------|---------------------|
| CPU/GPU load | Activity intensity |
| Weather signal | Movement aggressiveness |
| Phase/palette | Color accents |
| Time cycle | Sleep/rest cycle |
| Node health | Swarm count |
| User-selected mode | Display verbosity |

### What the Bee AI Actually Does

**A. System mascot with real state** — not fake ASCII wallpaper:
- Low load → relaxed hover
- High GPU load → rapid wing state, hotter color
- Network activity → directional flight trails
- Autumn theme → muted copper/amber palette
- Node stress → erratic pathing or "warning swarm"

**B. Visualization agent** — the bee carries information:
- Abdomen band brightness = GPU utilization
- Wingbeat frequency = CPU load
- Path curvature = network jitter
- Pollen count = queued jobs/tasks
- Hive state = system health index

**C. Research / simulation front-end** — legitimate demo for:
- Live bead animation, emergent motion
- AI-local behavior, formation and transition logic
- Environment-injected digital life

### Architecture

```
FlowerOS
 ├── flower-node
 ├── live-state shell
 ├── telemetry / theme engine
 ├── injection manager
 └── render broker
          │
          ▼
VSEPR-SIM Bee Core
 ├── bead body model
 ├── wing dynamics
 ├── pathing / local decisions
 ├── environment response
 ├── memory / state record
 └── swarm extension hooks
          │
          ▼
Bee AI Projection Layer
 ├── terminal identity
 ├── 2.5D / 3D renderer
 ├── graph stream
 ├── event logs
 └── behavior summaries
```

### Module Layout

```
floweros/
├── core/injection/
│   ├── bee_inject.sh
│   ├── bee_inject.ps1
│   ├── bee_state_bridge.py
│   └── bee_profile.conf
├── core/logic/
│   └── bee_runtime.c
├── share/bee/
│   ├── bee_palette.conf
│   ├── bee_modes.conf
│   ├── bee_ascii.txt
│   └── bee_render_defaults.conf
├── logs/
│   └── bee_state.log
└── system/
    └── flower-bee.service
```

### Implementation Phases

**Phase 1** (Wildflower target — do not skip to Phase 3):
- One bee, one body state, one renderer
- One telemetry mapping set, one update loop

**Phase 2:**
- Flower target objects
- Perch / hover / move states
- CPU/GPU-driven motion modulation

**Phase 3:**
- Multiple bees, hive logic
- Distributed telemetry roles
- Job-queue or cluster mapping

### Runtime Flow
1. FlowerOS boots
2. Injection manager reads local phase/palette
3. Telemetry snapshot is collected
4. VSEPR-SIM bee state is initialized (v3.0.1.1 formation)
5. Renderer receives bead/body state
6. Live shell receives summary state
7. Periodic updates modify motion, color, and behavior (v3.0.1.2 live engine)

---

## Cross-Tier Translation Layer (Tier 0 Tooling)

A translation layer in Tier 0 produces dual-execution scripts that preserve semantic intent across heterogeneous shell environments.

### Strategy
- **Auto-translate low-risk scripts:** version-selector.sh, floweros-config.sh, tree.sh, test-themes.sh
- **Do NOT auto-convert heavy orchestrators:** deploy.sh, install-permanent.sh, demo-bare-metal-hpc.sh (keep as bash, run via `bash .\script.sh`)
- **Rewrite only user-facing entrypoints** in PowerShell: flower.ps1, demo.ps1, test-all.ps1

### Translation Pipeline
1. **Tokenization:** `echo "hi"` → `[CMD echo] [STRING "hi"]`
2. **Intermediate Representation (IR):** Structured JSON AST
3. **Code Generation:** PowerShell output with native + bash fallback blocks

### Hybrid Output Pattern
```powershell
try {
    # Native translated block
    ...
} catch {
    # Fallback to bash execution
    if (Get-Command bash -ErrorAction SilentlyContinue) { bash ./original.sh }
    elseif (Get-Command wsl -ErrorAction SilentlyContinue) { wsl bash ./original.sh }
    else { Write-Error "No fallback available" }
}
```

### Safe Translation Matrix

| Feature | Convert? | Notes |
|---------|----------|-------|
| echo | ✅ | trivial |
| variables | ✅ | careful with quoting |
| if/test | ✅ | limited operators |
| for loops (simple) | ✅ | space-separated only |
| functions | ⚠️ | simple only |
| pipes | ❌ | leaves as fallback |
| sed/awk/grep | ❌ | do NOT translate |
| process substitution | ❌ | absolutely not |

---

## Environment + Identity Layer

A managed runtime identity system — not just config files.

- **Node identity:** `node_id` — unique per machine/environment
- **Environment tiers:** 0 → 5 (matching the 5-tier architecture)
- **Config + validation phases:** structured lifecycle from detection → validation → runtime
- Assigns meaning to machines and environments. That is what platforms do.
- Wires into Tier 4 state store (`state.json`) and node coordination (network routing).
