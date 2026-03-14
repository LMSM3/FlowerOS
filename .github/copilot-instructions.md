# Copilot Instructions

## Project Guidelines
- FlowerOS is the user's "golden project." It is intended to be a real operating system with 5 installation tiers: (1) Full Linux OS installable on a fresh drive, (2) Base Kernel wrapper over existing OS, (3) WSL safe user-based installation with experimental desktop live window, (4) Windows terminal coordinator with persistent communication layer storing $USER/$DESKTOP/$DRIVE_LIST as semi-protected objects, (5) Linux power install (current implementation). All GPU work should be real physical modeling, not visual-only approximations. The project philosophy: every task executed beautifully on GPU, terminals united, fast, themed.

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
