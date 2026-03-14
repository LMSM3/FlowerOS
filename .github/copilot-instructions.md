# Copilot Instructions

## Project Guidelines
- FlowerOS is the user's "golden project." It is intended to be a real operating system with 5 installation tiers: (1) Full Linux OS installable on a fresh drive, (2) Base Kernel wrapper over existing OS, (3) WSL safe user-based installation with experimental desktop live window, (4) Windows terminal coordinator with persistent communication layer storing $USER/$DESKTOP/$DRIVE_LIST as semi-protected objects, (5) Linux power install (current implementation). All GPU work should be real physical modeling, not visual-only approximations. The project philosophy: every task executed beautifully on GPU, terminals united, fast, themed.

## Tier 4 Architecture (Windows)
- **State store:** `%LOCALAPPDATA%\FlowerOS\state\state.json` — NOT registry. JSON or SQLite for structured state.
- **IPC bus:** Named Pipe `\\.\pipe\floweros\comm` with broker process. NDJSON request/response. No custom binary protocols.
- **Protection:** ACLs + DPAPI for real security. Obscurity is annoyance only, never relied on.
- **Clients:** PowerShell, bash, exe tools all talk to broker. Everything (themes, GPU, network) is a client of this substrate.
- **Code lives in:** `tier4/` — broker.c, broker.h, client.ps1, state/