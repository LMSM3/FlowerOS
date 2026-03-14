// ═══════════════════════════════════════════════════════════════════════════
//  Flower AI — Public Internal API  (lib/flower_ai/include/flower_ai.h)
//
//  Optional local desktop inference subsystem for FlowerOS.
//  Runs entirely on the user's machine. GPU-preferred, laptop-tolerant.
//
//  This header is the ONLY interface the rest of FlowerOS touches.
//  Everything behind it — backends, vendors, sessions — is private.
//
//  Build flags:
//    -DFLOWER_ENABLE_AI          Master switch (required)
//    -DFLOWER_ENABLE_AI_CUDA     Enable CUDA backend path
//    -DFLOWER_ENABLE_AI_VULKAN   Enable Vulkan backend path
//    -DFLOWER_ENABLE_AI_CPU      Enable CPU fallback path
//
//  If FLOWER_ENABLE_AI is not defined, every function in this header
//  compiles to a safe no-op or returns FLOWER_AI_DISABLED.
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWER_AI_H
#define FLOWER_AI_H

#ifdef __cplusplus
extern "C" {
#endif

// ─────────────────────────────────────────────────────────────────────────
//  Status codes
// ─────────────────────────────────────────────────────────────────────────

#define FLOWER_AI_OK              0
#define FLOWER_AI_ERR_GENERAL    -1
#define FLOWER_AI_ERR_NO_MODEL   -2
#define FLOWER_AI_ERR_NO_BACKEND -3
#define FLOWER_AI_ERR_OOM        -4
#define FLOWER_AI_ERR_INIT       -5
#define FLOWER_AI_DISABLED       -99

// ─────────────────────────────────────────────────────────────────────────
//  Hardware tiers
//
//  Tier A — Desktop GPU (4070/4080/5070/5080 class). Full capability.
//  Tier B — Gaming laptop / midrange GPU. Reduced context, smaller models.
//  Tier C — CPU-only or weak iGPU. Diagnostics, tiny models, limited mode.
// ─────────────────────────────────────────────────────────────────────────

typedef enum {
    FLOWER_AI_TIER_UNKNOWN = 0,
    FLOWER_AI_TIER_A       = 1,   // Desktop GPU — full inference
    FLOWER_AI_TIER_B       = 2,   // Laptop / midrange — reduced
    FLOWER_AI_TIER_C       = 3    // CPU fallback — minimal
} FlowerAITier;

// ─────────────────────────────────────────────────────────────────────────
//  Task modes
//
//  Gives the system shape instead of "send text in, pray text out."
// ─────────────────────────────────────────────────────────────────────────

typedef enum {
    FLOWER_AI_MODE_ASSISTANT  = 0,
    FLOWER_AI_MODE_SHELL      = 1,
    FLOWER_AI_MODE_CODE       = 2,
    FLOWER_AI_MODE_REPORT     = 3,
    FLOWER_AI_MODE_SUMMARIZE  = 4,
    FLOWER_AI_MODE_ANALYZE    = 5
} FlowerAIMode;

// ─────────────────────────────────────────────────────────────────────────
//  Backend identifiers
// ─────────────────────────────────────────────────────────────────────────

typedef enum {
    FLOWER_AI_BACKEND_NONE   = 0,
    FLOWER_AI_BACKEND_CPU    = 1,
    FLOWER_AI_BACKEND_CUDA   = 2,
    FLOWER_AI_BACKEND_VULKAN = 3
} FlowerAIBackendType;

// ─────────────────────────────────────────────────────────────────────────
//  Structures
// ─────────────────────────────────────────────────────────────────────────

typedef struct {
    int                  ai_enabled;
    int                  gpu_available;
    int                  cpu_fallback_available;
    unsigned long long   vram_mb;
    char                 backend_name[64];
    char                 gpu_name[128];
    FlowerAITier         tier;
    FlowerAIBackendType  recommended_backend;
} FlowerAIHardwareInfo;

typedef struct {
    const char          *model_path;
    int                  use_gpu;
    int                  max_context;
    int                  max_tokens;
    float                temperature;
    FlowerAIMode         mode;
    FlowerAIBackendType  backend;
} FlowerAIConfig;

typedef struct {
    const char *prompt;
    const char *system_prompt;
    FlowerAIMode mode;
} FlowerAIRequest;

typedef struct {
    char *text;
    int   status_code;
    int   tokens_used;
} FlowerAIResponse;

// ─────────────────────────────────────────────────────────────────────────
//  Public API
//
//  The rest of FlowerOS talks ONLY to these functions.
//  Backend details are private. Vendor headers stay in vendors/.
// ─────────────────────────────────────────────────────────────────────────

#ifdef FLOWER_ENABLE_AI

int  flower_ai_init(const FlowerAIConfig *cfg);
int  flower_ai_detect_hardware(FlowerAIHardwareInfo *info);
int  flower_ai_model_load(const char *model_path);
int  flower_ai_prompt(const FlowerAIRequest *req, FlowerAIResponse *res);
void flower_ai_response_free(FlowerAIResponse *res);
void flower_ai_shutdown(void);

// Convenience: human-readable status string
const char *flower_ai_status_string(int status_code);

// Convenience: check if AI subsystem is available at runtime
int  flower_ai_available(void);

#else
// ─────────────────────────────────────────────────────────────────────────
//  Stubs when AI is not compiled in.
//  FlowerOS still builds, still runs, AI commands print a clean notice.
// ─────────────────────────────────────────────────────────────────────────

static inline int  flower_ai_init(const FlowerAIConfig *cfg)
    { (void)cfg; return FLOWER_AI_DISABLED; }
static inline int  flower_ai_detect_hardware(FlowerAIHardwareInfo *info)
    { (void)info; return FLOWER_AI_DISABLED; }
static inline int  flower_ai_model_load(const char *model_path)
    { (void)model_path; return FLOWER_AI_DISABLED; }
static inline int  flower_ai_prompt(const FlowerAIRequest *req, FlowerAIResponse *res)
    { (void)req; (void)res; return FLOWER_AI_DISABLED; }
static inline void flower_ai_response_free(FlowerAIResponse *res)
    { (void)res; }
static inline void flower_ai_shutdown(void)
    { }
static inline const char *flower_ai_status_string(int status_code)
    { (void)status_code; return "Flower AI not compiled (FLOWER_ENABLE_AI not set)"; }
static inline int  flower_ai_available(void)
    { return 0; }

#endif /* FLOWER_ENABLE_AI */

#ifdef __cplusplus
}
#endif

#endif /* FLOWER_AI_H */
