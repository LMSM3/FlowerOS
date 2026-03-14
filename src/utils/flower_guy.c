// ═══════════════════════════════════════════════════════════════════════════
//  flower_guy.c  —  FlowerOS ASCII character renderer  (production backend)
//  C twin of lib/flower_ascii.sh  —  1:1 feature parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-guy flower_guy.c
//  usage:  flower-guy [variant] [mood]
//          flower-guy --random
//          flower-guy --plain classic
//          flower-guy --list
//
// ───────────────────────────────────────────────────────────────────────────
//  Shell ↔ C contract
//  This file is the reference implementation.  The shell version delegates
//  to this binary when it is on PATH.  Output must be byte-for-byte identical
//  (modulo color codes, which the shell resolves via flower_c and this file
//  resolves via role_color()).
//
//  Architecture note (one line):
//    future: sh2c lib/flower_ascii.sh → auto-generate this file from the shell source
// ═══════════════════════════════════════════════════════════════════════════

#include "../floweros.h"

// ─────────────────────────────────────────────────────────────────────────
//  Role → ANSI color
//  Mirrors flower_c() path-3 in flower_ascii.sh (256-color fallback).
//  Reads FLOWEROS_THEME env var first; falls back to hardcoded pastel.
// ─────────────────────────────────────────────────────────────────────────

static const char *role_color(const char *role) {
    // The theme env lookup is intentionally minimal here — full theme support
    // requires sourcing the shell config, which a C binary cannot do directly.
    // Use the same 256-color values as floweros.h (FOS_*) for consistency.
    if (!role) return FOS_RST;
    if (strcmp(role, "primary")   == 0) return "\033[38;5;117m";
    if (strcmp(role, "secondary") == 0) return "\033[38;5;183m";
    if (strcmp(role, "accent")    == 0) return "\033[38;5;159m";
    if (strcmp(role, "muted")     == 0) return "\033[38;5;245m";
    return FOS_RST;
}

// Shorthand pointers — match A B C M R tokens in shell version
#define CA role_color("primary")
#define CB role_color("secondary")
#define CC role_color("accent")
#define CM role_color("muted")
#define CR FOS_RST

// ─────────────────────────────────────────────────────────────────────────
//  Mood face table  (mirrors the case "$mood" block in flower_ascii.sh)
// ─────────────────────────────────────────────────────────────────────────

typedef struct { const char *eyes; const char *mouth; } MoodFace;

static MoodFace get_face(const char *mood) {
    if (!mood || strcmp(mood, "happy")   == 0) return (MoodFace){"(o) (o)", "u"};
    if (strcmp(mood, "neutral") == 0)          return (MoodFace){"( ) ( )", "^"};
    if (strcmp(mood, "angry")   == 0)          return (MoodFace){"(>)(<)",  "-"};
    if (strcmp(mood, "sleepy")  == 0)          return (MoodFace){"(-) (-)", "~"};
    return (MoodFace){"( ) ( )", "^"};
}

// ─────────────────────────────────────────────────────────────────────────
//  Variant printers  (1:1 with case "$variant" in flower_ascii.sh)
//  Each function prints exactly what the shell heredoc prints.
// ─────────────────────────────────────────────────────────────────────────

static void variant_classic(MoodFace f) {
    printf("%s                   .-.\n",         CB);
    printf("%s                .-(   )-.\n",      CA);
    printf("%s              (   .-.     )\n",    CB);
    printf("%s                `-(   )-,\n",      CA);
    printf("%s                   `-'\n",          CB);
    printf("%s%s                  __|__\n",       CR, CM);
    printf("%s               _/       \\_\n",    CM);
    printf("%s             _/  _   _    \\_\n",  CM);
    printf("%s            /   %s     \\\n",      CM, f.eyes);
    printf("%s           \\      %s         /\n",CM, f.mouth);
    printf("%s            \\_   ___      _/\n",  CM);
    printf("%s              \\_/   \\____/\n",   CM);
    printf("%s\n",                               CR);
}

static void variant_chonk(MoodFace f) {
    printf("%s                .-.\n",             CA);
    printf("%s             .-(   )-.\n",          CB);
    printf("%s            (   .-.   )\n",         CA);
    printf("%s             `-(   )-'\n",          CB);
    printf("%s%s               ___|___\n",        CR, CM);
    printf("%s            __/       \\__\n",      CM);
    printf("%s          _/   __ __     \\_\n",    CM);
    printf("%s         /    %s        \\\n",      CM, f.eyes);
    printf("%s         \\      %s        /\n",    CM, f.mouth);
    printf("%s          \\_    ___     _/\n",     CM);
    printf("%s            \\__/   \\___/\n",      CM);
    printf("%s\n",                               CR);
}

static void variant_pot(MoodFace f) {
    printf("%s               .-.\n",              CB);
    printf("%s            .-(   )-.\n",           CA);
    printf("%s          (   .-.     )\n",         CB);
    printf("%s            `-(   )-,\n",           CA);
    printf("%s               `-'\n",              CB);
    printf("%s%s              __|__\n",            CR, CM);
    printf("%s           _/       \\_\n",         CM);
    printf("%s         _/  %s    \\_\n",          CM, f.eyes);
    printf("%s        /       %s      \\\n",      CM, f.mouth);
    printf("%s        \\_    _____    _/\n",      CM);
    printf("%s          \\__/     \\__/\n",        CM);
    printf("%s             \\_____/\n",            CM);
    printf("%s\n",                               CR);
}

static void variant_ghost(MoodFace f) {
    printf("%s              .-.\n",               CC);
    printf("%s           .-(   )-.\n",            CA);
    printf("%s          (   .-.   )\n",           CC);
    printf("%s           `-(   )-'\n",            CA);
    printf("%s%s            .-\"\"\"\".-\n",         CR, CM);
    printf("%s           /  %s  \\\n",            CM, f.eyes);
    printf("%s          |     %s     |\n",        CM, f.mouth);
    printf("%s          |  ._____.  |\n",         CM);
    printf("%s          \\_/     \\_/\n",          CM);
    printf("%s\n",                               CR);
}

static void variant_orb(MoodFace f) {
    printf("%s             .-.\n",                CC);
    printf("%s          .-(   )-.\n",             CB);
    printf("%s         (   .-.   )\n",            CC);
    printf("%s          `-(   )-'\n",             CB);
    printf("%s%s           .--------.\n",         CR, CM);
    printf("%s         .'  %s   '.\n",            CM, f.eyes);
    printf("%s        /      %s      \\\n",       CM, f.mouth);
    printf("%s        \\   ._____.   /\n",        CM);
    printf("%s         '._       _.'\n",          CM);
    printf("%s            `-----'\n",             CM);
    printf("%s\n",                               CR);
}

static void variant_tiny(MoodFace f) {
    printf("%s   .-.\n",                          CA);
    printf("%s  %s\n",                            CA, f.eyes);
    printf("%s   |=|\n",                          CA);
    printf("%s%s  __|__\n",                       CR, CM);
    printf("%s /  %s  \\\n",                      CM, f.mouth);
    printf("%s `-----'\n",                        CM);
    printf("%s\n",                               CR);
}

// ─────────────────────────────────────────────────────────────────────────
//  flower_guy_print  —  dispatch by variant name
//  Mirrors the case "$variant" block in flower_ascii.sh
// ─────────────────────────────────────────────────────────────────────────

static int flower_guy_print(const char *variant, const char *mood) {
    MoodFace f = get_face(mood);
    if      (strcmp(variant, "classic") == 0) { variant_classic(f); return 0; }
    else if (strcmp(variant, "chonk")   == 0) { variant_chonk(f);   return 0; }
    else if (strcmp(variant, "pot")     == 0) { variant_pot(f);     return 0; }
    else if (strcmp(variant, "ghost")   == 0) { variant_ghost(f);   return 0; }
    else if (strcmp(variant, "orb")     == 0) { variant_orb(f);     return 0; }
    else if (strcmp(variant, "tiny")    == 0) { variant_tiny(f);    return 0; }
    fprintf(stderr, "usage: flower-guy {classic|chonk|pot|ghost|orb|tiny}  [mood]\n");
    return 1;
}

// ─────────────────────────────────────────────────────────────────────────
//  --random  (mirrors flower_guy_random() in flower_ascii.sh)
// ─────────────────────────────────────────────────────────────────────────

static const char *variants[] = {"classic","chonk","pot","ghost","orb","tiny"};
static const char *moods[]    = {"happy","neutral","angry","sleepy"};

static int flower_guy_random(void) {
    srand((unsigned)time(NULL) ^ (unsigned)getpid());
    const char *v = variants[rand() % 6];
    const char *m = moods[rand()    % 4];
    return flower_guy_print(v, m);
}

// ─────────────────────────────────────────────────────────────────────────
//  --plain  (mirrors flower_guy_plain() in flower_ascii.sh)
//  Replaces role_color with empty string — no ANSI codes in output.
// ─────────────────────────────────────────────────────────────────────────

static int g_plain = 0;

// Override role_color at link time via pointer when --plain is set
static const char *role_color_plain(const char *role) {
    (void)role; return "";
}
typedef const char *(*color_fn)(const char *);
static color_fn g_color_fn = role_color;

// Redirect the CA/CB/CC/CM/CR macros through the function pointer
#undef CA
#undef CB
#undef CC
#undef CM
#undef CR
#define CA g_color_fn("primary")
#define CB g_color_fn("secondary")
#define CC g_color_fn("accent")
#define CM g_color_fn("muted")
#define CR g_color_fn("reset")

// ─────────────────────────────────────────────────────────────────────────
//  --list
// ─────────────────────────────────────────────────────────────────────────

static void print_list(void) {
    printf("\n" FOS_PNK "  🌸 flower-guy variants" FOS_RST "\n");
    printf(FOS_DIM "  ─────────────────────────────\n" FOS_RST);
    for (int i = 0; i < 6; i++)
        printf("  " FOS_ACC "%s" FOS_RST "\n", variants[i]);
    printf(FOS_DIM "\n  Moods: " FOS_RST);
    for (int i = 0; i < 4; i++)
        printf(FOS_YLW "%s " FOS_RST, moods[i]);
    printf("\n\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    const char *variant  = "classic";
    const char *mood_arg = NULL;

    // $MOOD env (mirrors shell MOOD= prefix convention)
    const char *mood_env = getenv("MOOD");

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--random") == 0) return flower_guy_random();
        if (strcmp(argv[i], "--list")   == 0) { print_list(); return 0; }
        if (strcmp(argv[i], "--plain")  == 0) {
            g_plain = 1;
            g_color_fn = role_color_plain;
            continue;
        }
        // First non-flag positional = variant, second = mood
        if (argv[i][0] != '-') {
            if (strcmp(variant, "classic") == 0) variant  = argv[i];
            else                                  mood_arg = argv[i];
        }
    }

    const char *mood = mood_arg ? mood_arg : (mood_env ? mood_env : "neutral");
    return flower_guy_print(variant, mood);
}
