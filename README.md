<div align="center">

# FlowerOS
**Structured Terminal Environment for Development, Publishing, and System Control**

[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![OS](https://img.shields.io/badge/OS-Linux%20%7C%20WSL-blue.svg)](#system-requirements)
[![Interface](https://img.shields.io/badge/Interface-Terminal%20Native-purple.svg)](#overview)
[![Status](https://img.shields.io/badge/Status-Active%20Development-orange.svg)](#current-status)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A shell-native operating layer that unifies theming, install logic, workflow tools, and startup behavior into one coherent terminal experience**

[Quick Start](#quick-start) · [Featured Tools](#featured-tools) · [Architecture](#architecture) · [Repository Structure](#repository-structure) · [Design Principles](#design-principles)

</div>

---

## Overview

FlowerOS is a terminal-first shell environment designed to make local development, document publishing, system orchestration, and themed interaction feel structured rather than improvised. It is not a kernel replacement. It is a layered shell ecosystem: a shared install engine, runtime helpers, themed output conventions, utility frontends, and environment scaffolding assembled into a single coherent layer.

The current implementation (Tier 5, v1.3.0) runs on Linux, WSL2, and Windows (PowerShell).

**What ships in v1.3.0:**
- **Shared install engine** (`lib/install-core.sh`) — unified build, deploy, inject, download, auth, and remove logic shared across all install modes
- **PowerShell install mirror** (`install.ps1`) — native Windows install that mirrors the bash install exactly, using the same directory layout, sentinel markers, and version tracking
- **Shell publishing** — bash and PowerShell profile scripts are published as a pair: same palette, same environment variables, same theme manifests, one truth across both shells
- **Universal language runner** (`flower-run`) — auto-detects and runs C, C++, CUDA, Python, Julia, Rust, Go, Fortran, and more with optional HPC and GPU flags
- **Publishing workflow** (`fp`) — LaTeX document tool: `new`, `edit`, `build`, `view`, `watch`, `deps`
- **Shell environment layer** (`.flowerrc`, `lib/shell_extras.sh`) — structured aliases, lazy-loaded tools, safe defaults, and themed MOTD
- **Profile sync** (`lib/profile_sync.sh`, `lib/profile_sync.ps1`) — theme state published bidirectionally between bash and PowerShell via shared manifests
- **Games suite** — chess with alpha-beta engine, colony hex survival, tower defense, interactive launcher
- **MOTD system** (`share/motd/`) — composable data providers for weather, stocks, news, and random facts
- **Theming layer** — consistent color palette, stage indicators, progress bars, and terminal formatting rules applied uniformly across all tools

> **Guiding principle:**
> *Every script has a place. Every layer justifies its existence. The terminal should feel deliberate.*

---

## Featured Tools

| Tool | Binary | Description |
|------|--------|-------------|
| Entry point | `flower` | Version info, installed layout, and system status |
| Publisher | `fp` | LaTeX workflow — create, compile, preview, and watch |
| Runner | `flower-run` | Auto-detect and run 16+ languages with HPC / GPU flags |
| To-do | `flower-todo` | Shell-native task notepad |
| Character | `flower-guy` | ASCII character display with `--random` mode |
| Animation | `flower-walk` | Animated character sprite in the terminal |
| Banner | `banner` | Dynamic ASCII banner generator |
| Fortune | `fortune` | Rotating lines from `.ascii` / `.txt` asset files |
| Color test | `colortest` | 256-color palette verification |
| Chess | `flower-chess` | Alpha-beta engine, full terminal board |
| Colony | `flower-colony` | Hex grid survival strategy |
| Tower defense | `flower-td` | Terminal tower defense |
| Launcher | `flower-play` | Interactive game launcher menu |
| MOTD | `flower-motd` | Startup message with pluggable data providers |

---

## Quick Start

**Local install** — user mode, installs to `~/FlowerOS`, grafts into `~/.bashrc`:

```bash
git clone https://github.com/LMSM3/FlowerOS.git
cd FlowerOS
bash install.sh
source ~/.bashrc
```

**Permanent install** — system mode, installs to `/opt/floweros`, requires root:

```bash
sudo bash install-permanent.sh
```

**Build all binaries from source:**

```bash
bash build.sh
```

**Remove:**

```bash
bash uninstall.sh              # user mode
sudo bash remove-permanent.sh  # system mode
```

**Publishing workflow (`fp`):**

```bash
fp new  report.tex      # create .tex from template
fp edit report.tex      # open in $EDITOR
fp build report.tex     # compile to PDF via pdflatex
fp view  report.pdf     # open PDF viewer
fp watch report.tex     # rebuild on save (requires inotifywait)
fp deps                 # install pdflatex and friends (Debian / Ubuntu)
```

**Run any file with auto-detection (`flower-run`):**

```bash
flower-run main.c                 # compile and run C
flower-run script.py              # run Python
flower-run solver.cu              # compile and run CUDA
flower-run --hpc --time main.c    # HPC flags + timing
flower-run --gpu --hpc main.cpp   # GPU + HPC + timing
```

---

## Architecture

FlowerOS is organized as a layered shell environment. Each tier is a distinct deployment model with its own scope and install path.

### Tier Model

| Tier | Target | Description | Status |
|------|--------|-------------|--------|
| 1 | Fresh Linux drive | Full OS — boot directly into FlowerOS | Planned |
| 2 | Existing Linux | Base kernel wrapper — intercept and enhance | Prototype (`src/kernel/`) |
| 3 | WSL safe mode | User sandbox + experimental desktop window | Partial |
| 4 | Windows native | Persistent state store + named-pipe IPC bus | Scaffolded (`tier4/`) |
| 5 | Linux / WSL / Windows | **Current implementation** — tools, themes, network, GPU, PowerShell mirror | **Active** (v1.3.0) |

### Tier 4 — Windows Substrate

The Windows coordination layer is built on two non-overlapping components:

- **State store:** `%LOCALAPPDATA%\FlowerOS\state\state.json` — structured JSON tracking `$USER`, `$DESKTOP`, `$DRIVE_LIST`, theme, GPU flags, and shell profiles. Not the registry.
- **IPC bus:** Named pipe `\\.\pipe\floweros\comm` — a broker process owns the pipe; PowerShell, bash, and exe tools are all equal NDJSON clients.

### Install Engine

`lib/install-core.sh` is the single source of truth for all install and uninstall logic. All four install scripts source it — no logic is duplicated:

```
acquire  →  verify  →  build  →  graft  →  bloom
```

The engine provides nine layers: presentation, sentinel markers, binary manifests, build helpers, asset copying, network download with checksum verification, account auth, `.bashrc` injection and removal, and version writing.

---

## Repository Structure

```plaintext
FlowerOS/
├── bin/                        User-facing entry points
│   └── flower                  Main control frontend (version, tree, help)
│
├── src/                        C and C++ source
│   ├── utils/                  Core binaries
│   │   ├── random.c            Random line picker
│   │   ├── animate.c           ASCII animation engine
│   │   ├── banner.c            Dynamic banner generator
│   │   ├── fortune.c           Fortune line printer
│   │   ├── colortest.c         256-color palette test
│   │   └── visual.c            Visual output helper
│   ├── publish/                fp — LaTeX workflow tool
│   ├── runner/                 flower-run — universal language runner
│   ├── games/                  Chess, colony, tower defense, launcher
│   ├── tools/                  flower-todo
│   ├── network/                Terminal network layer (experimental)
│   ├── kernel/                 Tier 2 kernel wrapper prototype
│   └── tier4/                  Windows IPC broker (broker.c / broker.h)
│
├── lib/                        Shared shell library
│   ├── install-core.sh         Unified install / remove engine
│   ├── colors.sh               Color palette and output functions
│   ├── shell_extras.sh         Aliases, watchers, dev-mode gate, fhelp
│   ├── run.sh                  Shell twin of flower-run (frun / frun_hpc)
│   ├── theme_loader.sh         Theme loading and palette management
│   ├── post-install.sh         Optional post-install setup prompts
│   └── flower_ai/              Optional local AI subsystem
│       ├── include/flower_ai.h Public API (only interface to rest of FlowerOS)
│       ├── src/                Core, backend, detection, session
│       ├── vendors/            Upstream inference libraries (not checked in)
│       └── Makefile            Optional build with feature flags
│
├── share/motd/                 MOTD system
│   ├── flower-motd.sh          Main MOTD script
│   └── inject.d/               Composable providers (weather, stocks, news, facts)
│
├── tier4/                      Windows substrate
│   ├── broker.c / broker.h     IPC broker
│   ├── client.ps1              PowerShell client
│   └── state/                  state.json, schema.json
│
├── features/                   Optional theming modules (v1.1+)
├── tools/                      flower-todo, flower-blossom
├── docs/                       Architecture notes, changelogs, design references
│
├── .flowerrc                   Shell integration file (sourced by .bashrc)
├── install.sh                  User-mode install
├── install-permanent.sh        System-level install (requires root)
├── uninstall.sh                User-mode removal
├── remove-permanent.sh         System-level removal
└── build.sh                    Full source build
```

---

## Design Principles

**Terminal first**
The shell is the primary interface, not a fallback. Everything is designed to be operated from a terminal without requiring a GUI or a browser.

**Structured over improvised**
Files belong to defined layers. `lib/install-core.sh` is sourced by four scripts rather than copied four times. Logic has one home.

**Readable systems win**
A smaller system with transparent behavior is better than a fashionable black box. The install engine is plain readable shell script.

**Theme is part of usability**
Consistent color, spacing, and output formatting improve scan speed and orientation. It is not cosmetic — it is information design.

**Extension without collapse**
New tools slot into the existing architecture without touching unrelated parts. New binaries go in `src/`, new shell functions go in `lib/`, new MOTD data goes in `share/motd/inject.d/`.

**Optional layers stay optional**
Flower AI is an optional local desktop assistant subsystem. `FLOWER_ENABLE_AI=0` removes it entirely. If AI is absent, FlowerOS still boots, commands still work, AI commands display a clean notice. No crashes, no fake promises.

**Local control matters**
The user knows exactly what was installed, where it lives, and how to remove every trace of it cleanly.

---

## Shell Publishing

Shell publishing is a design technique, not a feature. It is the principle that makes FlowerOS installations permanent across both bash and PowerShell without either shell being a second-class citizen.

### The Problem

A shell environment installed into `~/.bashrc` on Linux disappears the moment the user opens PowerShell on Windows. Environment variables, theme palettes, path exports, and version tracking all evaporate. The install is "permanent" in one shell and invisible in the other. Cross-platform tools that solve this usually do it by picking one shell as the source of truth and treating the other as a sync target — which means one side is always stale, always late, always a copy.

### The Technique

Shell publishing treats bash and PowerShell as two **publication targets** of a single environment specification. The install engine does not install *into* a shell. It **publishes** the environment *to* both shells simultaneously, using each shell's native mechanisms:

```
                     ┌──────────────────┐
                     │  install-core.sh │   (single source of truth)
                     │  Directory layout │
                     │  Version tracking │
                     │  Sentinel markers │
                     └────────┬─────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        install.sh      install.ps1    install-permanent.sh
              │               │               │
              ▼               ▼               ▼
        ~/.bashrc       $PROFILE        /etc/bash.bashrc
        .flowerrc     profile_sync.ps1  /etc/profile.d/
```

**What gets published (identically) to both shells:**
- `FLOWEROS_ROOT`, `FLOWEROS_BIN`, `FLOWEROS_LIB` — same paths, same layout
- `FLOWEROS_VERSION` — same version string, read from the same `VERSION` file
- Theme palette — same hex values, same variable names (`FLOWEROS_OMP_PRIMARY`, etc.)
- Sentinel markers — same comment blocks mark the injected region in both `.bashrc` and `$PROFILE`

**What is native to each shell:**
- Bash gets `source .flowerrc` and `export` statements
- PowerShell gets `$env:` assignments, Oh My Posh init, and `Set-PSReadLineOption` theming
- Each shell's integration is written in that shell's idiom — no wrapper layers, no translation shims

### Why It Matters

The result is that `flower --version` returns the same answer whether called from bash or PowerShell. The theme looks the same. The paths resolve to the same directories. The install is not "bash-first with a PowerShell adapter" — it is a single environment state published to two shells.

This is what makes the install **permanent across the system**, not just permanent within one profile file. The technique extends to any shell that can set environment variables and source a profile script — zsh, fish, or nushell would each become another publication target with the same pattern.

### Manifest Files

The bridge between shells is a set of plain key-value manifest files:

| File | Written By | Read By | Purpose |
|------|-----------|---------|---------|
| `~/.floweros/theme_sync.env` | `profile_sync.sh` | `profile_sync.ps1` | Theme palette state |
| `~/.config/flower/theme.env` | Both | Both | Canonical cross-platform palette |
| `~/.floweros/VERSION` | Install engine | `bin/flower`, both profile syncs | Version + build type |

No database. No registry. No IPC. Just files that both shells can read and write.

---

## Version Progression

| Version | Highlights |
|---------|------------|
| v1.0 | Initial user-mode install, ASCII utilities, `.flowerrc` grafting |
| v1.1 | Theming engine, PowerShell integration, feature modules |
| v1.2.x | **Stable** — games suite, `flower-run`, `fp`, core customization |
| v1.2.5.1 | Shared install engine, permanent install, network layer, MOTD providers, Tier 4 scaffolding, Flower AI subsystem (optional) |
| **v1.3.0** | **Current** — PowerShell install mirror, shell publishing (bash↔PS profile sync), cross-platform permanent installs, profile_sync.sh/.ps1, version selector, cleanup and stabilization |
| v1.3+ | Tier 4 IPC broker, cross-platform state sync, expanded runner, package update handling |

> **Stability note:** v1.3.0 is the current stable release. The network routing layer (`src/network/`) is explicitly experimental. All experimental output is printed in red in the terminal.

---

## System Requirements

| Requirement | Detail |
|-------------|--------|
| OS | Linux, WSL2, or compatible Unix-like environment |
| Shell | Bash 4.x or later |
| Compiler | GCC for C binaries; G++ for network / runner; `nvcc` optional for CUDA |
| Build tools | `make`, standard POSIX userland |
| Optional | `pdflatex` for `fp`; `inotifywait` for `fp watch`; Python 3 for MOTD providers; 256-color terminal |

---

## Current Status

**Stable for:**
- User-mode shell customization and environment grafting
- `fp` LaTeX document publishing workflow
- `flower-run` multi-language execution with HPC flags
- Terminal games and ASCII utility tools
- MOTD and themed startup behavior
- Script-based install and clean removal

**Experimental in v1.3.0:**
- Network routing layer (`src/network/`)
- Tier 4 IPC broker and Windows state store

**Planned:**
- Full Tier 4 IPC implementation (`tier4/broker.c` → production)
- Tier 3 WSL desktop window
- Remote and node-aware execution flows
- More formal package and update handling

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Acknowledgments

GNU Bash and the POSIX shell ecosystem. The LaTeX and `pdflatex` toolchain. Terminal theming traditions that proved plain text does not need to look miserable. Every overly ambitious personal systems project that refused to stay "just a few scripts."

---

<div align="center">

[Quick Start](#quick-start) · [Architecture](#architecture) · [Design Principles](#design-principles) · [GitHub](https://github.com/LMSM3/FlowerOS)

*FlowerOS is not a generic prompt theme. It is a structured shell environment for people who expect their terminal to behave like an instrument.*

</div>
