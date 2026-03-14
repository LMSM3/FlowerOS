// ═══════════════════════════════════════════════════════════════════════════
//  flower_walk.c  —  Tier 5 production walk animation engine
//  C twin of experimental/animations/flower_walk_demo.sh — 1:1 functional parity
//
//  Build:   gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-walk flower_walk.c
//  Install: /opt/floweros/bin/flower-walk  (via install-permanent.sh)
//  Usage:   flower-walk [--fps N] [--help]
//
// ───────────────────────────────────────────────────────────────────────────
//  Tier 5 improvements over the shell bootstrap (flower_walk_demo.sh)
//
//  Shell                          │  This file
//  ───────────────────────────────┼──────────────────────────────────────────
//  sleep via awk subprocess       │  nanosleep() — exact, zero forks
//  max ~14 fps (awk overhead)     │  60 fps capable, default 30 fps
//  no resize support              │  SIGWINCH handler, live resize
//  assoc-array erase loop         │  write() frame buffer, one syscall/frame
//  COLUMNS/LINES env only         │  ioctl(TIOCGWINSZ) — real terminal size
//  set -euo pipefail exits on err │  graceful signal handling, always restores
//
// ───────────────────────────────────────────────────────────────────────────
//  Sprite contract
//  Each frame is a const char*[SPRITE_H] array.
//  Color tokens are embedded as ANSI literals (compile-time concatenation).
//  Art is 1:1 with frame_R* / frame_L* in experimental/animations/flower_walk_demo.sh.
//  To swap in better art: edit ONLY the frames_R / frames_L tables.
//  Engine does not care about visual content — only line count matters.
//
//  Shell ↔ C architecture note (one line):
//    goal: gcc $(bash2c flower_walk_demo.sh) -o flower-walk
// ═══════════════════════════════════════════════════════════════════════════

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <stdarg.h>
#include <errno.h>

// ─────────────────────────────────────────────────────────────────────────
//  Color palette  (matches FOS_* in src/floweros.h and flower_c() fallback
//  in lib/flower_ascii.sh — all three must stay in sync)
// ─────────────────────────────────────────────────────────────────────────

#define CA  "\033[38;5;117m"   // primary   — mint-cyan
#define CB  "\033[38;5;183m"   // secondary — soft magenta
#define CM  "\033[38;5;245m"   // muted     — grey
#define CR  "\033[0m"          // reset

// ─────────────────────────────────────────────────────────────────────────
//  Sprite dimensions
//  SPRITE_H:  line count — must match every frame array exactly
//  SPRITE_VW: visual column width (excluding ANSI codes) — used for erase
// ─────────────────────────────────────────────────────────────────────────

#define SPRITE_H   10
#define SPRITE_VW  20    // generous bounding box; covers trailing spaces

// ─────────────────────────────────────────────────────────────────────────
//  Frame tables — RIGHT-FACING  (4 frames)
//  Walk cycle: R0 → R1 → R2 → R3 → R0 → …
//
//  Lines 0-6: petals + head (constant)  — only colour tokens change
//  Line  7:   torso connector (constant)
//  Lines 8-9: legs               — only lines that differ between frames
//
//  Leg key:
//    R0  neutral      / \     both feet flat
//    R1  L push-off  _/ \     left heel rises, right swings forward
//    R2  float        / \     mid-float (face expression switches to ~)
//    R3  R push-off   / \_    right heel rises, left swings forward
// ─────────────────────────────────────────────────────────────────────────

static const char *frames_R[4][SPRITE_H] = {
    { /* R0 — neutral */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB " (" CA " .~. " CB ")       ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CM "  .(" CA "^" CM ")." CB ">       ",
        CM "   |=|          ",
        CM "   / \\         ",
        CM "  o   o         " CR,
    },
    { /* R1 — left push-off */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB " (" CA " .~. " CB ")       ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CM "  .(" CA "^" CM ")." CB ">       ",
        CM "   |=|          ",
        CM "  _/ \\         ",
        CM "  o   o         " CR,
    },
    { /* R2 — mid-float */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB " (" CA " .~. " CB ")       ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CM "  .(" CA "~" CM ")." CB ">       ",  /* ~ = float expression */
        CM "   |=|          ",
        CM "   / \\         ",
        CM "  o   o         " CR,
    },
    { /* R3 — right push-off */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB " (" CA " .~. " CB ")       ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CM "  .(" CA "^" CM ")." CB ">       ",
        CM "   |=|          ",
        CM "   / \\_        ",
        CM "  o   o         " CR,
    },
};

// ─────────────────────────────────────────────────────────────────────────
//  Frame tables — LEFT-FACING  (4 frames)
//  Mirror of RIGHT frames:
//    • direction indicator  >  →  <  (moved to left side of head)
//    • leg lean inverted:  R1 _/ \ mirrors to L1 / \_  and vice versa
//    • Walk phase offset by 2 on bounce so stride is continuous
// ─────────────────────────────────────────────────────────────────────────

static const char *frames_L[4][SPRITE_H] = {
    { /* L0 — neutral */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB "       (" CA " .~. " CB ")  ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CB "<" CM ".(" CA "^" CM ").         ",
        CM "   |=|          ",
        CM "   / \\         ",
        CM "  o   o         " CR,
    },
    { /* L1 — right push-off (mirror of R1 _/ \) */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB "       (" CA " .~. " CB ")  ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CB "<" CM ".(" CA "^" CM ").         ",
        CM "   |=|          ",
        CM "   / \\_        ",
        CM "  o   o         " CR,
    },
    { /* L2 — mid-float */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB "       (" CA " .~. " CB ")  ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CB "<" CM ".(" CA "~" CM ").         ",  /* ~ = float expression */
        CM "   |=|          ",
        CM "   / \\         ",
        CM "  o   o         " CR,
    },
    { /* L3 — left push-off (mirror of R3 / \_) */
        CB "    .~.          ",
        CB "  .(   ).        ",
        CB "       (" CA " .~. " CB ")  ",
        CB "  `-(   )-'      ",
        CB "    `-'          ",
        CM "    _|_          ",
        CB "<" CM ".(" CA "^" CM ").         ",
        CM "   |=|          ",
        CM "  _/ \\         ",
        CM "  o   o         " CR,
    },
};

// ─────────────────────────────────────────────────────────────────────────
//  Frame buffer  — double-buffer technique
//  All drawing for a tick is accumulated here, then written with one
//  write() syscall.  This is what eliminates the flicker that the shell
//  version gets from many small printf() calls.
// ─────────────────────────────────────────────────────────────────────────

#define FB_SIZE (1 << 17)   // 128 KB — more than enough for terminal art

static char  g_fb[FB_SIZE];
static int   g_fb_len;

static void fb_reset(void) { g_fb_len = 0; }

static void fb_append(const char *s, int len) {
    if (g_fb_len + len >= FB_SIZE) return;
    memcpy(g_fb + g_fb_len, s, (size_t)len);
    g_fb_len += len;
}

static void fb_printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(g_fb + g_fb_len, (size_t)(FB_SIZE - g_fb_len), fmt, ap);
    va_end(ap);
    if (n > 0) g_fb_len += n;
}

// Move cursor and append string — mirrors the shell's $(printf '\033[r;cH%s')
static void fb_at(int row, int col, const char *s) {
    fb_printf("\033[%d;%dH%s", row, col, s);
}

static void fb_flush(void) {
    write(STDOUT_FILENO, g_fb, (size_t)g_fb_len);
    g_fb_len = 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Global state
// ─────────────────────────────────────────────────────────────────────────

static volatile sig_atomic_t g_done   = 0;
static volatile sig_atomic_t g_resize = 0;

static int W, H;                      // terminal dimensions
static struct termios g_term_save;    // saved terminal state
static int            g_term_changed = 0;

// ─────────────────────────────────────────────────────────────────────────
//  Signal handlers
// ─────────────────────────────────────────────────────────────────────────

static void handle_exit(int sig) { (void)sig; g_done   = 1; }
static void handle_winch(int sig){ (void)sig; g_resize = 1; }

// ─────────────────────────────────────────────────────────────────────────
//  Terminal setup / teardown
// ─────────────────────────────────────────────────────────────────────────

static void get_term_size(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0) {
        W = ws.ws_col;
        H = ws.ws_row > 2 ? ws.ws_row - 2 : 10;
    } else {
        W = 80; H = 22;
    }
}

static void term_setup(void) {
    tcgetattr(STDIN_FILENO, &g_term_save);
    struct termios raw = g_term_save;
    raw.c_lflag &= (tcflag_t)~(ECHO | ICANON);   // no echo, no line-buffer
    raw.c_cc[VMIN]  = 0;
    raw.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSANOW, &raw);
    g_term_changed = 1;
}

static void term_restore(void) {
    if (!g_term_changed) return;
    write(STDOUT_FILENO, "\033[?1049l", 8);   // leave alternate screen
    write(STDOUT_FILENO, "\033[?25h",   6);   // show cursor
    write(STDOUT_FILENO, CR, sizeof(CR) - 1);
    tcsetattr(STDIN_FILENO, TCSANOW, &g_term_save);
    g_term_changed = 0;
}

static void cleanup(void) { term_restore(); }

// ─────────────────────────────────────────────────────────────────────────
//  Erase sprite bounding box  (mirrors erase_sprite() in shell version)
//  Writes SPRITE_VW spaces at each row of the sprite's old position.
// ─────────────────────────────────────────────────────────────────────────

static const char BLANK[SPRITE_VW + 1] =
    "                    ";   // SPRITE_VW spaces

static void erase_at(int ox, int oy) {
    for (int r = 0; r < SPRITE_H; r++) {
        int row = oy + r;
        if (row >= 1 && row <= H)
            fb_at(row, ox, BLANK);
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Draw sprite at (ox, oy) — mirrors draw_sprite() in shell version
// ─────────────────────────────────────────────────────────────────────────

typedef enum { DIR_RIGHT = 0, DIR_LEFT = 1 } Dir;

static void draw_at(int ox, int oy, Dir dir, int frame_idx) {
    const char *(*frame)[SPRITE_H] =
        (dir == DIR_RIGHT) ? &frames_R[frame_idx] : &frames_L[frame_idx];

    for (int r = 0; r < SPRITE_H; r++) {
        int row = oy + r;
        if (row >= 1 && row <= H)
            fb_at(row, ox, (*frame)[r]);
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Ground line  (single ─ rule across full width)
// ─────────────────────────────────────────────────────────────────────────

static void draw_ground(void) {
    int row = H + 1;
    fb_printf("\033[%d;1H" CM, row);
    for (int i = 0; i < W; i++) fb_append("\xe2\x94\x80", 3); // U+2500 ─
    fb_append(CR, sizeof(CR) - 1);
}

// ─────────────────────────────────────────────────────────────────────────
//  Status bar  (bottom row, same info as shell version)
// ─────────────────────────────────────────────────────────────────────────

static void draw_status(Dir dir, int x, int fps) {
    const char *arrow = (dir == DIR_RIGHT) ? "\xe2\x86\x92" : "\xe2\x86\x90";
    fb_printf("\033[%d;2H" CM "  %s  x=%-4d  fps=%-3d  q=quit" CR,
              H + 2, arrow, x, fps);
}

// ─────────────────────────────────────────────────────────────────────────
//  Timing — nanosleep wrapper
//  Replaces the shell's:  sleep "$(awk -v ns="$DT_NS" 'BEGIN{...}')"
//  No subprocess. No awk. Exact nanosecond precision.
// ─────────────────────────────────────────────────────────────────────────

static void frame_sleep(int fps) {
    struct timespec ts;
    long ns = 1000000000L / fps;
    ts.tv_sec  = 0;
    ts.tv_nsec = ns;
    nanosleep(&ts, NULL);
}

// ─────────────────────────────────────────────────────────────────────────
//  Help
// ─────────────────────────────────────────────────────────────────────────

static void print_help(const char *prog) {
    printf("\n" CB "  flower-walk" CR " — FlowerOS Tier 5 walk animation\n\n"
           "  " CM "Usage:" CR "  %s [--fps N] [--help]\n\n"
           "  " CM "--fps N" CR "   Target frame rate (1–60, default 30)\n"
           "  " CM "--help" CR "    This message\n\n"
           "  Installed: " CM "/opt/floweros/bin/flower-walk" CR "\n"
           "  Shell twin: " CM "experimental/animations/flower_walk_demo.sh" CR "\n\n", prog);
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    int fps = 30;

    // Parse args
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            print_help(argv[0]); return 0;
        }
        if (strcmp(argv[i], "--fps") == 0 && i + 1 < argc) {
            fps = atoi(argv[++i]);
            if (fps < 1 || fps > 60) { fprintf(stderr, "fps must be 1-60\n"); return 1; }
        }
    }

    // Signals
    signal(SIGINT,  handle_exit);
    signal(SIGTERM, handle_exit);
    signal(SIGHUP,  handle_exit);
    signal(SIGWINCH, handle_winch);

    // Terminal
    get_term_size();
    term_setup();
    atexit(cleanup);

    // Enter alternate screen, hide cursor, clear
    write(STDOUT_FILENO, "\033[?1049h\033[?25l\033[2J",
          sizeof("\033[?1049h\033[?25l\033[2J") - 1);

    // ── Physics state ───────────────────────────────────────────────────
    // Fixed-point x (×2) for sub-column precision — same as shell version
    int x2       = 8;           // x * 2 = column 4
    int py       = H / 2 - SPRITE_H / 2;
    int vx2      = 2;           // +2 = move 1 col/tick rightward
    Dir   dir    = DIR_RIGHT;
    int   tick   = 0;
    int   frame_idx = 0;
    int   prev_x = x2 / 2;

    const int FRAME_COUNT      = 4;
    const int TICKS_PER_FRAME  = 5;   // matches shell version default

    // Static elements (drawn once, redrawn only on resize)
    fb_reset();
    draw_ground();
    fb_flush();

    // ── Main loop ────────────────────────────────────────────────────────
    while (!g_done) {

        // Non-blocking keyboard read for 'q'
        {
            char key = 0;
            if (read(STDIN_FILENO, &key, 1) == 1 && key == 'q') break;
        }

        // Handle terminal resize (SIGWINCH)
        if (g_resize) {
            get_term_size();
            g_resize = 0;
            // Clamp py to new height
            py = H / 2 - SPRITE_H / 2;
            if (py < 1) py = 1;
            // Redraw static elements
            fb_reset();
            fb_append("\033[2J", 4);
            draw_ground();
            fb_flush();
        }

        fb_reset();

        // Erase old position
        erase_at(prev_x, py);

        // Advance position (fixed-point)
        x2 += vx2;
        int cx = x2 / 2;

        // Bounce — same logic as shell version, phase-offset on flip
        if (vx2 > 0 && cx + SPRITE_VW >= W) {
            x2  = (W - SPRITE_VW - 1) * 2;
            cx  = x2 / 2;
            vx2 = -2;
            dir = DIR_LEFT;
            frame_idx = (frame_idx + 2) % FRAME_COUNT;
        } else if (vx2 < 0 && cx <= 1) {
            x2  = 4;
            cx  = 2;
            vx2 = 2;
            dir = DIR_RIGHT;
            frame_idx = (frame_idx + 2) % FRAME_COUNT;
        }

        // Advance walk frame
        tick++;
        if (tick % TICKS_PER_FRAME == 0) {
            frame_idx = (frame_idx + 1) % FRAME_COUNT;
        }

        // Draw new position
        draw_at(cx, py, dir, frame_idx);
        draw_status(dir, cx, fps);

        prev_x = cx;

        fb_flush();

        frame_sleep(fps);
    }

    return 0;
}
