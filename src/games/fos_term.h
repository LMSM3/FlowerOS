// ═══════════════════════════════════════════════════════════════════════════
//  fos_term.h — FlowerOS Active Window Framework
//
//  Terminal UI substrate for all FlowerOS live-action games.
//  Single-header library — #include it, everything is static inline.
//
//  Provides:
//    • Raw mode terminal (ICANON/ECHO/ISIG off, VMIN=0)
//    • Non-blocking key input (arrows, enter, escape, chars)
//    • Alt-screen + cursor management
//    • Frame timing (nanosleep + CLOCK_MONOTONIC)
//    • SIGWINCH resize handling
//    • Fork+exec child launch with terminal restore/re-enter
//    • Palette re-exports (from floweros.h FOS_* convention)
//
//  Usage:
//    #define _POSIX_C_SOURCE 200809L   // before any includes
//    #include "fos_term.h"
//
//  All three games (chess, colony, td) plus the launcher share this.
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FOS_TERM_H
#define FOS_TERM_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <signal.h>
#include <time.h>

// ─── Palette (mirrors FOS_* in floweros.h) ───────────────────────────────

#define FT_RST "\033[0m"
#define FT_BLD "\033[1m"
#define FT_DIM "\033[38;5;245m"
#define FT_GRN "\033[38;5;120m"
#define FT_YEL "\033[38;5;229m"
#define FT_MAG "\033[38;5;183m"
#define FT_CYA "\033[38;5;117m"
#define FT_RED "\033[38;5;210m"

// ─── Key types ───────────────────────────────────────────────────────────

typedef enum {
    FK_NONE = 0,
    FK_UP, FK_DOWN, FK_LEFT, FK_RIGHT,
    FK_ENTER, FK_ESC, FK_CHAR
} FKeyType;

typedef struct { FKeyType type; char ch; } FKey;

// ─── File-scope state ────────────────────────────────────────────────────

static struct termios ft__orig;
static int ft__raw_on = 0;
static volatile int ft__cols = 80, ft__rows = 24;
static volatile sig_atomic_t ft__resized = 0;

// ─── Screen size ─────────────────────────────────────────────────────────

static void ft_size(void) {
    struct winsize w;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0)
        { ft__cols = w.ws_col; ft__rows = w.ws_row; }
}
static inline int ft_cols(void) { return ft__cols; }
static inline int ft_rows(void) { return ft__rows; }

// ─── Signal handlers ─────────────────────────────────────────────────────

static void ft__on_winch(int s) { (void)s; ft_size(); ft__resized = 1; }
static void ft__on_die(int s) {
    if (ft__raw_on) {
        tcsetattr(STDIN_FILENO, TCSANOW, &ft__orig);
        (void)!write(STDOUT_FILENO, "\033[?1049l\033[?25h\033[0m", 19);
    }
    _exit(128 + s);
}

// ─── Terminal control ────────────────────────────────────────────────────

static void ft_raw(void) {
    if (ft__raw_on) return;
    tcgetattr(STDIN_FILENO, &ft__orig);
    struct termios t = ft__orig;
    t.c_lflag &= ~(unsigned)(ICANON | ECHO | ISIG);
    t.c_iflag &= ~(unsigned)(IXON | ICRNL);
    t.c_cc[VMIN] = 0; t.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSANOW, &t);
    ft__raw_on = 1;
}
static void ft_cooked(void) {
    if (!ft__raw_on) return;
    tcsetattr(STDIN_FILENO, TCSANOW, &ft__orig);
    ft__raw_on = 0;
}

static void ft_alt(int on)     { printf(on?"\033[?1049h":"\033[?1049l"); fflush(stdout); }
static void ft_cursor(int on)  { printf(on?"\033[?25h":"\033[?25l"); fflush(stdout); }
static void ft_clear(void)     { printf("\033[2J\033[H"); fflush(stdout); }
static void ft_go(int r,int c) { printf("\033[%d;%dH",r,c); }

// ─── Init / cleanup ─────────────────────────────────────────────────────

static void ft_init(void) {
    ft_size();
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = ft__on_winch;  sigaction(SIGWINCH, &sa, NULL);
    sa.sa_handler = ft__on_die;    sigaction(SIGTERM, &sa, NULL);
    // SIGINT left to raw-mode char read (byte 0x03) so games can handle it
}

static void ft_end(void) {
    ft_cursor(1); ft_alt(0); ft_cooked();
    printf(FT_RST); fflush(stdout);
}

// ─── Non-blocking key read ───────────────────────────────────────────────

static FKey ft_key(void) {
    FKey k = {FK_NONE, 0};
    unsigned char b;
    if (read(STDIN_FILENO, &b, 1) != 1) return k;
    if (b == '\033') {
        unsigned char s[2];
        if (read(STDIN_FILENO, &s[0], 1) != 1) { k.type = FK_ESC; return k; }
        if (s[0] == '[' && read(STDIN_FILENO, &s[1], 1) == 1) {
            switch (s[1]) {
                case 'A': k.type = FK_UP;    return k;
                case 'B': k.type = FK_DOWN;  return k;
                case 'C': k.type = FK_RIGHT; return k;
                case 'D': k.type = FK_LEFT;  return k;
            }
        }
        k.type = FK_ESC; return k;
    }
    if (b == '\r' || b == '\n') { k.type = FK_ENTER; return k; }
    k.type = FK_CHAR; k.ch = (char)b;
    return k;
}

// ─── Timing ──────────────────────────────────────────────────────────────

static void ft_sleep(int ms) {
    struct timespec t = {ms/1000, (ms%1000)*1000000L};
    nanosleep(&t, NULL);
}
static long long ft_ms(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (long long)t.tv_sec * 1000 + t.tv_nsec / 1000000;
}

// ─── Fork+exec child game ───────────────────────────────────────────────
//  Restores terminal, forks, execs the game binary (cascade resolution),
//  waits, then re-enters raw/alt for the caller.
//  Returns child exit code, or 127 if binary not found.

static int ft_launch(const char *bin) {
    ft_cursor(1); ft_alt(0); ft_cooked();
    fflush(stdout);

    pid_t pid = fork();
    if (pid == 0) {
        // ── child: exec cascade ──────────────────────────────
        char *av[] = {(char*)bin, NULL};
        char buf[512];
        execvp(bin, av);                                        // 1. PATH
        snprintf(buf, sizeof buf, "./%s", bin);
        execv(buf, av);                                         // 2. ./bin
        const char *r = getenv("FLOWEROS_ROOT");
        if (r) { snprintf(buf,sizeof buf,"%s/src/%s",r,bin); execv(buf,av); }
        {   // 4. sibling of this binary
            char self[512]={0};
            ssize_t n=readlink("/proc/self/exe",self,sizeof self-1);
            if(n>0){self[n]=0;char*sl=strrchr(self,'/');
            if(sl){snprintf(sl+1,(size_t)(sizeof self-(size_t)(sl-self)-1),"%s",bin);execv(self,av);}}
        }
        fprintf(stderr,FT_RED "  \xe2\x9c\x97 %s not found\n" FT_RST,bin);
        _exit(127);
    }

    int st = 0;
    if (pid > 0) waitpid(pid, &st, 0);
    ft_raw(); ft_alt(1); ft_cursor(0); ft_clear();
    return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
}

#endif // FOS_TERM_H
