# Flower AI — Vendor Dependencies

This directory holds upstream inference libraries used by the Flower AI backend.

**No vendor code is checked in.** Clone or download dependencies here at build time.

## Current target: BitNet (Microsoft)

```bash
# Clone the runtime
git clone https://github.com/microsoft/BitNet.git

# Inference weights (GGUF):
#   microsoft/bitnet-b1.58-2B-4T-gguf
#
# Training / fine-tune weights (BF16):
#   microsoft/bitnet-b1.58-2B-4T-bf16
```

## Rules

- Vendor headers are included **only** from `flower_ai_backend.cpp`
- No vendor types leak into `flower_ai.h`
- The rest of FlowerOS never touches this directory
- Version-pin all dependencies
- If a vendor disappears, only this backend layer needs rewriting
