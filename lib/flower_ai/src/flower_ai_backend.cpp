// ═══════════════════════════════════════════════════════════════════════════
//  Flower AI — Backend Abstraction  (lib/flower_ai/src/flower_ai_backend.cpp)
//
//  This is the firewall between FlowerOS and whatever cursed vendor stack
//  the industry invents next. The rest of the project never touches raw
//  backend calls — it talks to the C API in flower_ai.h, which calls
//  through here.
//
//  V0.1: stub backend that validates the call chain and returns canned
//  responses for integration testing. Real vendor integration (BitNet,
//  llama.cpp, etc.) goes into vendors/ and gets called from here.
//
//  C++ is used here because upstream inference libraries (BitNet, etc.)
//  expose C++ APIs. This file is the only place that touches them.
// ═══════════════════════════════════════════════════════════════════════════

#ifdef FLOWER_ENABLE_AI

#include <cstdio>
#include <cstdlib>
#include <cstring>

// Expose C linkage for the functions flower_ai.c calls
extern "C" {

#include "flower_ai.h"

// ─────────────────────────────────────────────────────────────────────────
//  Internal backend state
// ─────────────────────────────────────────────────────────────────────────

static FlowerAIBackendType g_active_backend = FLOWER_AI_BACKEND_NONE;
static int                 g_backend_ready  = 0;
static int                 g_model_ready    = 0;
static char                g_model_path[512] = {0};

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_backend_init
//
//  Select and initialize the compute backend.
//  V0.1: accepts the selection, stores it, does not link vendor code yet.
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_backend_init(FlowerAIBackendType backend) {
    if (backend == FLOWER_AI_BACKEND_NONE)
        return FLOWER_AI_ERR_NO_BACKEND;

    g_active_backend = backend;
    g_backend_ready  = 1;

    const char *name = "unknown";
    switch (backend) {
        case FLOWER_AI_BACKEND_CPU:    name = "CPU";    break;
        case FLOWER_AI_BACKEND_CUDA:   name = "CUDA";   break;
        case FLOWER_AI_BACKEND_VULKAN: name = "Vulkan"; break;
        default: break;
    }
    fprintf(stderr, "[flower-ai] backend initialized: %s\n", name);

    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_backend_load
//
//  Load model weights from disk.
//  V0.1: validates path exists, stores it, does not parse weights.
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_backend_load(const char *model_path, int max_context) {
    if (!g_backend_ready) return FLOWER_AI_ERR_INIT;
    if (!model_path)      return FLOWER_AI_ERR_NO_MODEL;

    // Verify file exists
    FILE *f = fopen(model_path, "rb");
    if (!f) {
        fprintf(stderr, "[flower-ai] model file not found: %s\n", model_path);
        return FLOWER_AI_ERR_NO_MODEL;
    }
    fclose(f);

    snprintf(g_model_path, sizeof(g_model_path), "%s", model_path);
    g_model_ready = 1;

    fprintf(stderr, "[flower-ai] model loaded: %s (context=%d)\n",
            model_path, max_context);

    // ──────────────────────────────────────────────────────────────────
    //  TODO: Real vendor integration goes here.
    //  When BitNet / llama.cpp / other runtime is wired in:
    //    1. #include the vendor header
    //    2. Initialize the runtime context
    //    3. Load the model weights
    //    4. Set context window from max_context
    //  All vendor headers stay in vendors/. No leaks into flower_ai.h.
    // ──────────────────────────────────────────────────────────────────

    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_backend_infer
//
//  Run one prompt through the loaded model.
//  V0.1: returns a stub response confirming the pipeline works end-to-end.
//  Caller owns out_text and must free it.
// ─────────────────────────────────────────────────────────────────────────

int flower_ai_backend_infer(const char *prompt, const char *system_prompt,
                             int max_tokens, float temperature,
                             char **out_text, int *out_tokens) {
    if (!g_backend_ready || !g_model_ready)
        return FLOWER_AI_ERR_INIT;
    if (!prompt || !out_text || !out_tokens)
        return FLOWER_AI_ERR_GENERAL;

    (void)system_prompt;
    (void)max_tokens;
    (void)temperature;

    // ──────────────────────────────────────────────────────────────────
    //  V0.1 stub: echo back a diagnostic response.
    //  Replace this block with real inference when vendor is wired in.
    // ──────────────────────────────────────────────────────────────────

    const char *backend_name = "none";
    switch (g_active_backend) {
        case FLOWER_AI_BACKEND_CPU:    backend_name = "CPU";    break;
        case FLOWER_AI_BACKEND_CUDA:   backend_name = "CUDA";   break;
        case FLOWER_AI_BACKEND_VULKAN: backend_name = "Vulkan"; break;
        default: break;
    }

    char buf[1024];
    snprintf(buf, sizeof(buf),
             "[flower-ai stub] backend=%s model=%s prompt_len=%d\n"
             "Real inference not yet connected. Pipeline validation OK.",
             backend_name, g_model_path, (int)strlen(prompt));

    *out_text   = strdup(buf);
    *out_tokens = 0;

    if (!*out_text) return FLOWER_AI_ERR_OOM;

    return FLOWER_AI_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_backend_unload
// ─────────────────────────────────────────────────────────────────────────

void flower_ai_backend_unload(void) {
    g_model_ready = 0;
    g_model_path[0] = '\0';
    fprintf(stderr, "[flower-ai] model unloaded\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_backend_shutdown
// ─────────────────────────────────────────────────────────────────────────

void flower_ai_backend_shutdown(void) {
    if (g_model_ready) {
        flower_ai_backend_unload();
    }
    g_active_backend = FLOWER_AI_BACKEND_NONE;
    g_backend_ready  = 0;
    fprintf(stderr, "[flower-ai] backend shutdown\n");
}

} // extern "C"

#endif /* FLOWER_ENABLE_AI */
