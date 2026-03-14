# Flower AI

**FlowerOS's optional local desktop assistant subsystem.**

Runs entirely on the user's machine, prioritizes modern desktop GPU hardware, and provides a unified interface for shell assistance, code support, document generation, and workflow automation.

---

## Position

Flower AI is an optional local assistant layer for FlowerOS, designed to run fully on the user's machine. It is optimized for modern desktop GPUs and higher-end development systems, while still allowing reduced-capability operation on laptops and CPU-only environments where possible.

### What Flower AI is

- **Optional** — FlowerOS boots, runs, and works without it
- **Local-first** — no cloud, no API keys, no external calls
- **Desktop-capable** — optimized for real GPU hardware
- **Terminal-integrated** — shell-native, not GUI-first
- **GPU-preferred** — CUDA > Vulkan > CPU, auto-detected
- **Laptop-tolerant** — reduced mode, not broken mode

### What Flower AI is not

- Not mandatory for base FlowerOS operation
- Not a daemon that runs at startup
- Not a filesystem indexer
- Not a voice assistant
- Not "the brain" of everything

---

## Architecture

```
floweros/
├── lib/
│   └── flower_ai/
│       ├── include/
│       │   └── flower_ai.h          ← The ONLY public interface
│       ├── src/
│       │   ├── flower_ai.c          ← Core init/shutdown
│       │   ├── flower_ai_backend.cpp ← Backend abstraction (vendor firewall)
│       │   ├── flower_ai_detect.c   ← Hardware detection
│       │   └── flower_ai_session.c  ← Session/prompt state, task modes
│       ├── vendors/                  ← Upstream libraries (not checked in)
│       ├── Makefile
│       └── README.md
```

**Rule:** The rest of FlowerOS talks only to `flower_ai.h`. No vendor headers, no backend types, no model format details leak out of this directory.

---

## Public API

```c
int  flower_ai_init(const FlowerAIConfig *cfg);
int  flower_ai_detect_hardware(FlowerAIHardwareInfo *info);
int  flower_ai_model_load(const char *model_path);
int  flower_ai_prompt(const FlowerAIRequest *req, FlowerAIResponse *res);
void flower_ai_response_free(FlowerAIResponse *res);
void flower_ai_shutdown(void);
int  flower_ai_available(void);
```

---

## Hardware Tiers

| Tier | Class | VRAM | Capability |
|------|-------|------|------------|
| **A** | Desktop GPU (4070/4080/5070/5080) | ≥8 GB | Full inference, large context, rich assistant features |
| **B** | Gaming laptop / midrange GPU | 4–8 GB | Reduced context, smaller models, lower concurrency |
| **C** | CPU-only or weak iGPU | — | Diagnostics, tiny models, non-streaming / limited mode |

---

## Task Modes

| Mode | Purpose |
|------|---------|
| `assistant` | General desktop assistant |
| `shell` | Shell command generation and explanation |
| `code` | Code completion and review |
| `report` | Structured document and changelog generation |
| `summarize` | Input condensation |
| `analyze` | Systematic analysis |

---

## Build

```bash
cd lib/flower_ai

# CPU fallback only (default)
make

# With CUDA support
make FLOWER_ENABLE_AI_CUDA=1

# Diagnostic
make check

# Clean
make clean
```

### Build flags

| Flag | Default | Effect |
|------|---------|--------|
| `FLOWER_ENABLE_AI` | `1` | Master switch. If `0`, nothing compiles. |
| `FLOWER_ENABLE_AI_CPU` | `1` | CPU fallback path |
| `FLOWER_ENABLE_AI_CUDA` | `0` | CUDA backend path |
| `FLOWER_ENABLE_AI_VULKAN` | `0` | Vulkan backend path |

### Runtime behavior when AI is absent

- FlowerOS still boots
- All commands still work
- AI commands display: `Flower AI not compiled (FLOWER_ENABLE_AI not set)`
- No crashes
- No fake "feature complete" nonsense

---

## V0.1 Scope

Flower AI should only:

- ✅ Detect hardware
- ✅ Report whether AI is available
- ✅ Load one backend
- ✅ Load one model
- ✅ Run one prompt
- ✅ Return text
- ✅ Fail cleanly

It should **not** in V0.1:

- ❌ Index the filesystem
- ❌ Add voice
- ❌ Run as a daemon
- ❌ Manage desktop overlays
- ❌ Rewrite shell history
- ❌ Become "the brain" of everything

---

## Vendor Target: BitNet (Microsoft)

```bash
# Clone runtime
git clone https://github.com/microsoft/BitNet.git vendors/BitNet

# Inference weights:  microsoft/bitnet-b1.58-2B-4T-gguf
# Training weights:   microsoft/bitnet-b1.58-2B-4T-bf16
```

### Integration stages

| Stage | Action |
|-------|--------|
| 1 | Run published 1.58-bit model locally |
| 2 | Measure assistant-task quality |
| 3 | Build Flower-specific prompt dataset |
| 4 | Fine-tune BF16 master weights |
| 5 | Repack for local inference |
| 6 | Integrate into `flower_ai_backend.cpp` |

---

## Policy

This dependency is:

- **Optional at build time** — `FLOWER_ENABLE_AI=0` removes it entirely
- **Optional at runtime** — missing models produce clean notices, not crashes
- **Isolated behind one API** — `flower_ai.h` is the only public surface
- **Version-pinned** — vendor code lives in `vendors/` with explicit versions
- **Replaceable later** — swap the backend, keep the API
