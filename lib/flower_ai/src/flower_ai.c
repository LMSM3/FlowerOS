// ═══════════════════════════════════════════════════════════════════════════
//  Flower AI — Core  (lib/flower_ai/src/flower_ai.c)
//
//  Master init, shutdown, availability check, and status strings.
//  V0.1 scope: init → detect → load → prompt → shutdown → fail cleanly.
// ═══════════════════════════════════════════════════════════════════════════

#ifdef FLOWER_ENABLE_AI

#include "flower_ai.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ─────────────────────────────────────────────────────────────────────────
//  Internal state  (file-scoped, not exported)
// ─────────────────────────────────────────────────────────────────────────

static int              g_initialized   = 0;
static int              g_model_loaded  = 0;
static FlowerAIConfig   g_config;
static FlowerAIHardwareInfo g_hw;

// Forward declarations — implemented in sibling translation units
extern int  flower_ai_backend_init(FlowerAIBackendType backend);
extern int  flower_ai_backend_load(const char *model_path, int max_context);
extern int  flower_ai_backend_infer(const char *prompt, const char *system_prompt,
                                     int max_tokens, float temperature,
                                     char **out_text, int *out_tokens);
extern void flower_ai_backend_unload(void);
extern void flower_ai_backend_shutdown(void);

extern int  flower_ai_detect_gpu(FlowerAIHardwareInfo *info);

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_init
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_init(const FlowerAIConfig *cfg) {
    if (!cfg) return FLOWER_AI_ERR_INIT;
    if (g_initialized) return FLOWER_AI_OK;  // idempotent

    memcpy(&g_config, cfg, sizeof(FlowerAIConfig));

    // Detect hardware first
    memset(&g_hw, 0, sizeof(g_hw));
    flower_ai_detect_hardware(&g_hw);

    // Select backend
    FlowerAIBackendType backend = cfg->backend;
    if (backend == FLOWER_AI_BACKEND_NONE) {
        backend = g_hw.recommended_backend;
    }
    if (backend == FLOWER_AI_BACKEND_NONE) {
        // Nothing available at all
        fprintf(stderr, "[flower-ai] no usable backend detected\n");
        return FLOWER_AI_ERR_NO_BACKEND;
    }

    int rc = flower_ai_backend_init(backend);
    if (rc != FLOWER_AI_OK) {
        fprintf(stderr, "[flower-ai] backend init failed (%d)\n", rc);
        return rc;
    }

    g_initialized = 1;
    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_detect_hardware
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_detect_hardware(FlowerAIHardwareInfo *info) {
    if (!info) return FLOWER_AI_ERR_GENERAL;
    memset(info, 0, sizeof(*info));

    // CPU fallback is always available
    info->cpu_fallback_available = 1;
    info->recommended_backend    = FLOWER_AI_BACKEND_CPU;
    info->tier                   = FLOWER_AI_TIER_C;
    snprintf(info->backend_name, sizeof(info->backend_name), "cpu");

    // Try GPU detection (implemented in flower_ai_detect.c)
    int gpu_rc = flower_ai_detect_gpu(info);
    if (gpu_rc == FLOWER_AI_OK && info->gpu_available) {
        info->ai_enabled = 1;
    } else {
        // CPU fallback is fine
        info->ai_enabled = 1;
    }

    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_model_load
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_model_load(const char *model_path) {
    if (!g_initialized) return FLOWER_AI_ERR_INIT;
    if (!model_path)    return FLOWER_AI_ERR_NO_MODEL;
    if (g_model_loaded) {
        flower_ai_backend_unload();
        g_model_loaded = 0;
    }

    int rc = flower_ai_backend_load(model_path, g_config.max_context);
    if (rc != FLOWER_AI_OK) {
        fprintf(stderr, "[flower-ai] model load failed: %s (%d)\n", model_path, rc);
        return rc;
    }

    g_model_loaded = 1;
    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_prompt
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_prompt(const FlowerAIRequest *req, FlowerAIResponse *res) {
    if (!g_initialized)   return FLOWER_AI_ERR_INIT;
    if (!g_model_loaded)  return FLOWER_AI_ERR_NO_MODEL;
    if (!req || !res)     return FLOWER_AI_ERR_GENERAL;

    memset(res, 0, sizeof(*res));

    char *out_text = NULL;
    int   out_tokens = 0;

    int rc = flower_ai_backend_infer(
        req->prompt,
        req->system_prompt,
        g_config.max_tokens,
        g_config.temperature,
        &out_text,
        &out_tokens
    );

    if (rc != FLOWER_AI_OK) {
        res->status_code = rc;
        return rc;
    }

    res->text        = out_text;   // caller frees via flower_ai_response_free
    res->tokens_used = out_tokens;
    res->status_code = FLOWER_AI_OK;
    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_response_free
// ─────────────────────────────────────────────────────────────────────────

void flower_ai_response_free(FlowerAIResponse *res) {
    if (res && res->text) {
        free(res->text);
        res->text = NULL;
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_shutdown
// ─────────────────────────────────────────────────────────────────────────

void flower_ai_shutdown(void) {
    if (!g_initialized) return;
    if (g_model_loaded) {
        flower_ai_backend_unload();
        g_model_loaded = 0;
    }
    flower_ai_backend_shutdown();
    g_initialized = 0;
    memset(&g_config, 0, sizeof(g_config));
    memset(&g_hw, 0, sizeof(g_hw));
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_available
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_available(void) {
    return g_initialized && g_model_loaded;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_status_string
// ─────────────────────────────────────────────────────────────────────────

const char *flower_ai_status_string(int status_code) {
    switch (status_code) {
        case FLOWER_AI_OK:             return "OK";
        case FLOWER_AI_ERR_GENERAL:    return "general error";
        case FLOWER_AI_ERR_NO_MODEL:   return "no model loaded";
        case FLOWER_AI_ERR_NO_BACKEND: return "no backend available";
        case FLOWER_AI_ERR_OOM:        return "out of memory";
        case FLOWER_AI_ERR_INIT:       return "not initialized";
        case FLOWER_AI_DISABLED:       return "Flower AI not compiled";
        default:                       return "unknown error";
    }
}

#endif /* FLOWER_ENABLE_AI */
