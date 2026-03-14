# FlowerOS Post-Installation Experience

## Overview

After installation, FlowerOS asks users a series of optional questions to customize their experience and install helpful companion tools.

---

## Installation Outcomes by Version

### Quick Install (Q)
- **Post-install:** Skipped (minimal prompts)
- **Outcome:** Basic FlowerOS only
- **Optional tools:** None offered
- **Configuration:** Defaults only

### User Install (U) - v1.2.X Stable
- **Post-install:** Full interactive flow
- **Outcome:** User-level installation with customization
- **Optional tools offered:**
  - fzf (fuzzy finder)
  - bat (syntax highlighting)
  - neofetch (system info)
  - lolcat (rainbow colors)
  - MSYS2 (Windows only, if gcc missing)
- **Configuration questions:**
  - Quiet mode (disable auto-ASCII)
  - Custom ASCII directory

### Permanent Install (S) - v1.3.X Experimental
- **Post-install:** Full interactive flow + advanced options
- **Outcome:** System-level integration with all features
- **Optional tools offered:**
  - All from User Install, plus:
  - Ollama (local AI models)
- **Configuration questions:**
  - All from User Install, plus:
  - Network features (experimental)
  - GPU batch processing settings

---

## Post-Install Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     POST-INSTALL SETUP                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. OPTIONAL TOOLS                                                  │
│     "Would you like to see optional tool recommendations?" [Y/n]    │
│                                                                     │
│     If yes:                                                         │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ [Windows only, if no gcc]                                   │ │
│     │ MSYS2 - Unix tools for Windows                              │ │
│     │ "Open MSYS2 download page?" [y/N]                           │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ fzf - Fuzzy finder                                          │ │
│     │ "Install fzf?" [y/N]                                        │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ bat - Syntax highlighting                                   │ │
│     │ "Install bat?" [y/N]                                        │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ neofetch - System info                                      │ │
│     │ "Install neofetch?" [y/N]                                   │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ lolcat - Rainbow output                                     │ │
│     │ "Install lolcat?" [y/N]                                     │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ [Permanent install only, or if interested in AI]           │ │
│     │ Ollama - Local AI models                                    │ │
│     │ "Install Ollama?" [y/N]                                     │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  2. CONFIGURATION                                                   │
│     "Configure FlowerOS settings now?" [Y/n]                        │
│                                                                     │
│     If yes:                                                         │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ Quiet Mode                                                  │ │
│     │ "Enable quiet mode (no auto-ASCII)?" [y/N]                  │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ Custom Directory                                            │ │
│     │ "Use custom ASCII directory?" [y/N]                         │ │
│     │ If yes: "Enter path: ___________"                           │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ [Permanent install only]                                    │ │
│     │ Network Features (EXPERIMENTAL)                             │ │
│     │ "Enable network features?" [y/N]                            │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  3. SUMMARY                                                         │
│     Shows what was installed/configured                             │
│     Displays quick command reference                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Tools Offered

| Tool | Purpose | Platforms | When Offered |
|------|---------|-----------|--------------|
| MSYS2 | Unix tools for Windows | Windows | If gcc not found |
| fzf | Fuzzy finder | All | Always |
| bat | Syntax highlighting | All | Always |
| neofetch | System info display | All | Always |
| lolcat | Rainbow colorizer | All | Always |
| Ollama | Local AI models | All | Permanent install, or if interested |

---

## Configuration Options

| Option | What It Does | Default |
|--------|--------------|---------|
| Quiet Mode | Disables auto-ASCII on terminal open | Off (shows ASCII) |
| Custom Directory | Use different path for ASCII files | ~/FlowerOS/ascii |
| Network Features | Enable v1.3.X experimental networking | Off |

---

## Running Post-Install Later

If you skipped post-install or want to reconfigure:

```bash
# Run post-install for user install
bash lib/post-install.sh user

# Run post-install for permanent install
bash lib/post-install.sh permanent

# Run post-install for quick test
bash lib/post-install.sh quick
```

---

## Differences by Install Type

| Feature | Quick (Q) | User (U) | Permanent (S) |
|---------|-----------|----------|---------------|
| Post-install prompts | Skip all | Full flow | Full + advanced |
| Optional tools | None | 5 tools | 6 tools (+ Ollama) |
| Quiet mode config | No | Yes | Yes |
| Custom dir config | No | Yes | Yes |
| Network config | No | No | Yes |
| Ollama offered | No | If interested | Always |
| MSYS2 (Windows) | No | If no gcc | If no gcc |

---

## Philosophy

**Respect user time:** Don't force long setup on quick installs.
**Offer value:** Suggest tools that genuinely improve the experience.
**Default to minimal:** All tools are optional, defaults are sensible.
**Version-aware:** Different features for stable vs experimental.
