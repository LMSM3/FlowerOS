// ═══════════════════════════════════════════════════════════════════════════
//  Flower AI — Hardware Detection  (lib/flower_ai/src/flower_ai_detect.c)
//
//  Detects GPU availability, VRAM tier, and recommends backend.
//  Uses sysfs on Linux, nvidia-smi probe, and Vulkan availability.
//  No vendor headers required — probes via filesystem and process exec.
//
//  V0.1: detect → classify → recommend. No runtime linkage.
// ═══════════════════════════════════════════════════════════════════════════

#ifdef FLOWER_ENABLE_AI

#define _POSIX_C_SOURCE 200809L

#include "flower_ai.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ─────────────────────────────────────────────────────────────────────────
//  Internal helpers
// ─────────────────────────────────────────────────────────────────────────

// Run a command and capture the first line of output.
// Returns 0 on success, -1 on failure.
static int run_capture(const char *cmd, char *buf, int buf_len) {
    FILE *fp = popen(cmd, "r");
    if (!fp) return -1;

    buf[0] = '\0';
    if (fgets(buf, buf_len, fp) != NULL) {
        // Strip trailing newline
        int len = (int)strlen(buf);
        while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r'))
            buf[--len] = '\0';
    }

    int status = pclose(fp);
    return (status == 0 && buf[0] != '\0') ? 0 : -1;
}

// ─────────────────────────────────────────────────────────────────────────
//  NVIDIA detection via nvidia-smi
// ─────────────────────────────────────────────────────────────────────────

static int detect_nvidia(FlowerAIHardwareInfo *info) {
    // Check if nvidia-smi is available
    char name_buf[128] = {0};
    if (run_capture("nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1",
                    name_buf, sizeof(name_buf)) != 0) {
        return -1;
    }

    // GPU found
    info->gpu_available = 1;
    snprintf(info->gpu_name, sizeof(info->gpu_name), "%s", name_buf);

    // Query VRAM
    char vram_buf[64] = {0};
    if (run_capture("nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1",
                    vram_buf, sizeof(vram_buf)) == 0) {
        info->vram_mb = (unsigned long long)atoll(vram_buf);
    }

    // Classify tier by VRAM
    if (info->vram_mb >= 8000) {
        info->tier               = FLOWER_AI_TIER_A;
        info->recommended_backend = FLOWER_AI_BACKEND_CUDA;
        snprintf(info->backend_name, sizeof(info->backend_name), "cuda");
    } else if (info->vram_mb >= 4000) {
        info->tier               = FLOWER_AI_TIER_B;
        info->recommended_backend = FLOWER_AI_BACKEND_CUDA;
        snprintf(info->backend_name, sizeof(info->backend_name), "cuda");
    } else {
        info->tier               = FLOWER_AI_TIER_B;
        info->recommended_backend = FLOWER_AI_BACKEND_CUDA;
        snprintf(info->backend_name, sizeof(info->backend_name), "cuda");
    }

    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Vulkan detection (vulkaninfo probe)
// ─────────────────────────────────────────────────────────────────────────

static int detect_vulkan(FlowerAIHardwareInfo *info) {
    char vk_buf[128] = {0};
    if (run_capture("vulkaninfo --summary 2>/dev/null | grep 'deviceName' | head -1 | sed 's/.*= //'",
                    vk_buf, sizeof(vk_buf)) != 0) {
        return -1;
    }

    if (!info->gpu_available) {
        // Vulkan found but NVIDIA wasn't — use Vulkan as backend
        info->gpu_available      = 1;
        info->recommended_backend = FLOWER_AI_BACKEND_VULKAN;
        info->tier               = FLOWER_AI_TIER_B;
        snprintf(info->gpu_name, sizeof(info->gpu_name), "%s", vk_buf);
        snprintf(info->backend_name, sizeof(info->backend_name), "vulkan");
    }

    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Public entry point — called from flower_ai.c
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_detect_gpu(FlowerAIHardwareInfo *info) {
    if (!info) return FLOWER_AI_ERR_GENERAL;

    // Try NVIDIA first (most common for local inference)
    if (detect_nvidia(info) == 0) {
        return FLOWER_AI_OK;
    }

    // Try Vulkan (AMD, Intel, etc.)
    if (detect_vulkan(info) == 0) {
        return FLOWER_AI_OK;
    }

    // No GPU detected — CPU fallback already set by caller
    return FLOWER_AI_ERR_NO_BACKEND;
}

#endif /* FLOWER_ENABLE_AI */
