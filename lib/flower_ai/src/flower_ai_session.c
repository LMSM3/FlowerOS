// ═══════════════════════════════════════════════════════════════════════════
//  Flower AI — Session Management  (lib/flower_ai/src/flower_ai_session.c)
//
//  Manages prompt/session state, system prompt templates per task mode,
//  and context window tracking.
//
//  V0.1: mode-aware system prompt selection. No persistent history.
// ═══════════════════════════════════════════════════════════════════════════

#ifdef FLOWER_ENABLE_AI

#include "flower_ai.h"

#include <stdio.h>
#include <string.h>

// ─────────────────────────────────────────────────────────────────────────
//  System prompt templates per task mode
//
//  These give the model shape instead of raw open-ended generation.
//  Kept simple for V0.1 — expanded when real inference is connected.
// ─────────────────────────────────────────────────────────────────────────

static const char *mode_system_prompts[] = {
    // FLOWER_AI_MODE_ASSISTANT
    "You are Flower AI, a local desktop assistant for FlowerOS. "
    "Be concise, accurate, and terminal-friendly.",

    // FLOWER_AI_MODE_SHELL
    "You are a shell command assistant. Respond with valid shell commands. "
    "Prefer POSIX-compatible syntax. Explain briefly if asked.",

    // FLOWER_AI_MODE_CODE
    "You are a code assistant. Respond with clean, correct code. "
    "Follow the conventions of the language being discussed.",

    // FLOWER_AI_MODE_REPORT
    "You are a report generator. Produce structured, readable output "
    "suitable for documents or changelogs.",

    // FLOWER_AI_MODE_SUMMARIZE
    "You are a summarizer. Condense the input into key points. "
    "Be precise and avoid filler.",

    // FLOWER_AI_MODE_ANALYZE
    "You are an analysis assistant. Examine the input systematically "
    "and provide structured observations.",
};

#define MODE_COUNT (sizeof(mode_system_prompts) / sizeof(mode_system_prompts[0]))

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_session_get_system_prompt
//
//  Returns the system prompt for the given mode.
//  If the request already provides a system_prompt, that takes priority.
// ─────────────────────────────────────────────────────────────────────────

const char *flower_ai_session_get_system_prompt(const FlowerAIRequest *req) {
    if (!req) return mode_system_prompts[0];

    // Explicit system prompt overrides mode default
    if (req->system_prompt && req->system_prompt[0] != '\0') {
        return req->system_prompt;
    }

    int idx = (int)req->mode;
    if (idx < 0 || idx >= (int)MODE_COUNT) {
        idx = 0;
    }
    return mode_system_prompts[idx];
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_ai_session_mode_name
//
//  Human-readable name for a task mode.
// ─────────────────────────────────────────────────────────────────────────

const char *flower_ai_session_mode_name(FlowerAIMode mode) {
    switch (mode) {
        case FLOWER_AI_MODE_ASSISTANT: return "assistant";
        case FLOWER_AI_MODE_SHELL:     return "shell";
        case FLOWER_AI_MODE_CODE:      return "code";
        case FLOWER_AI_MODE_REPORT:    return "report";
        case FLOWER_AI_MODE_SUMMARIZE: return "summarize";
        case FLOWER_AI_MODE_ANALYZE:   return "analyze";
        default:                       return "unknown";
    }
}

#endif /* FLOWER_ENABLE_AI */
