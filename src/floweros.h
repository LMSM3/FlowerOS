// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS — Shared Foundation  (src/floweros.h)
//
//  Include this in every C twin.  Provides:
//    • Pastel 256-colour ANSI palette  (matches lib/colors.sh exactly)
//    • ok / err / info / warn / die    (same symbols as shell counterparts)
//    • ask_yes_no                      (mirrors ask_yes_no() in post-install.sh)
//    • file_exists / dir_ensure        (POSIX helpers)
//    • run_cmd                         (exec + wait, returns exit status)
//    • flower_exec_apt                 (apt install wrapper with prompt)
//    • OS detection                    (mirrors detect_os() in post-install.sh)
//
//  Shell ↔ C mapping contract
//  ──────────────────────────
//  Every function documented here has a named counterpart in the
//  corresponding .sh file.  When the shell version changes, update
//  the C version to match and vice-versa.
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWEROS_H
#define FLOWEROS_H

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>
#include <time.h>
#include <ctype.h>
#include <pwd.h>

// ─────────────────────────────────────────────────────────────────────────
//  Version
// ─────────────────────────────────────────────────────────────────────────

#define FLOWEROS_VERSION        "1.2.5.1"
#define FLOWEROS_STATE_DIR      ".floweros"          // under $HOME
#define FLOWEROS_PREFS_FILE     "preferences.conf"
#define FLOWEROS_INSTALL_DIR    "FlowerOS"           // under $HOME
#define FLOWEROS_MARKER         "# FlowerOS ASCII Integration"

// ─────────────────────────────────────────────────────────────────────────
//  Pastel 256-colour ANSI palette
//  Mirrors lib/colors.sh — indexes must stay in sync.
// ─────────────────────────────────────────────────────────────────────────

#define FOS_RST    "\033[0m"
#define FOS_BOLD   "\033[1m"
#define FOS_DIM    "\033[38;5;245m"   // grey-245       (C_DIM in bashrc)
#define FOS_ACC    "\033[38;5;117m"   // mint-cyan-117  (C_ACC)
#define FOS_PNK    "\033[38;5;219m"   // pink-219       (C_PNK)
#define FOS_GRN    "\033[38;5;120m"   // green-120      (C_GRN / GREEN)
#define FOS_RED    "\033[38;5;210m"   // red-210        (C_RED / RED)
#define FOS_YLW    "\033[38;5;229m"   // yellow-229     (C_YLW / YELLOW)
#define FOS_BLU    "\033[38;5;111m"   // blue-111       (C_BLU)
#define FOS_MAG    "\033[38;5;183m"   // magenta-183    (MAGENTA)
#define FOS_CYN    "\033[38;5;87m"    // cyan-87        (CYAN)

// ─────────────────────────────────────────────────────────────────────────
//  Output helpers  (1:1 with lib/colors.sh)
//
//  ok()   → green   ✓     warn() → yellow  ⚠
//  err()  → red     ✗     info() → cyan    ✿
//  die()  → err() then exit(1)
// ─────────────────────────────────────────────────────────────────────────

static inline void fos_ok(const char *msg) {
    printf(FOS_GRN "✓" FOS_RST " %s\n", msg);
}
static inline void fos_err(const char *msg) {
    fprintf(stderr, FOS_RED "✗" FOS_RST " %s\n", msg);
}
static inline void fos_info(const char *msg) {
    printf(FOS_ACC "✿" FOS_RST " %s\n", msg);
}
static inline void fos_warn(const char *msg) {
    printf(FOS_YLW "⚠" FOS_RST " %s\n", msg);
}

#define fos_die(msg)  do { fos_err(msg); exit(1); } while (0)

// ─────────────────────────────────────────────────────────────────────────
//  Box headers  (1:1 with deploy.sh banner() / post-install.sh header())
// ─────────────────────────────────────────────────────────────────────────

static inline void fos_header(const char *title) {
    printf("\n");
    printf(FOS_MAG FOS_BOLD
        "═══════════════════════════════════════════════════════════════════════════\n"
        "  %s\n"
        "═══════════════════════════════════════════════════════════════════════════\n"
        FOS_RST "\n", title);
}

static inline void fos_box(const char *title, const char *color) {
    printf("\n%s"
        "╔═══════════════════════════════════════════════════════════════════════════╗\n"
        "║                                                                           ║\n"
        "║  %-73s║\n"
        "║                                                                           ║\n"
        "╚═══════════════════════════════════════════════════════════════════════════╝\n"
        FOS_RST "\n", color, title);
}

// ─────────────────────────────────────────────────────────────────────────
//  Prompt helpers  (1:1 with post-install.sh ask_yes_no / deploy.sh confirm)
// ─────────────────────────────────────────────────────────────────────────

// Returns 1 for yes, 0 for no.  'def' is 'y' or 'n'.
static inline int fos_ask_yn(const char *prompt, char def) {
    printf(FOS_YLW "%s [%s/%s]" FOS_RST " ",
        prompt,
        (def == 'y') ? "Y" : "y",
        (def == 'y') ? "n" : "N");
    fflush(stdout);
    char buf[8] = {0};
    if (!fgets(buf, sizeof buf, stdin)) return (def == 'y');
    if (buf[0] == '\n') return (def == 'y');
    return (tolower((unsigned char)buf[0]) == 'y');
}

// Pause with a message — used between tutorial steps
static inline void fos_pause(const char *msg) {
    printf(FOS_DIM "%s" FOS_RST, msg ? msg : "  Press Enter to continue...");
    fflush(stdout);
    int c; while ((c = getchar()) != '\n' && c != EOF) {}
}

// ─────────────────────────────────────────────────────────────────────────
//  OS detection  (1:1 with detect_os() in post-install.sh)
// ─────────────────────────────────────────────────────────────────────────

typedef enum { OS_LINUX, OS_DEBIAN, OS_WSL, OS_MACOS, OS_WINDOWS, OS_UNKNOWN } FosOS;

static inline FosOS fos_detect_os(void) {
    // Check WSL first
    FILE *f = fopen("/proc/version", "r");
    if (f) {
        char buf[256];
        if (fgets(buf, sizeof buf, f)) {
            fclose(f);
            if (strstr(buf, "Microsoft") || strstr(buf, "WSL"))
                return OS_WSL;
        } else { fclose(f); }
    }
    // Debian/Ubuntu
    if (access("/etc/debian_version", F_OK) == 0) return OS_DEBIAN;
    // macOS
    if (access("/usr/bin/sw_vers", F_OK) == 0) return OS_MACOS;
#ifdef _WIN32
    return OS_WINDOWS;
#endif
    return OS_LINUX;
}

static inline const char *fos_os_name(FosOS os) {
    switch (os) {
        case OS_DEBIAN:  return "Debian/Ubuntu";
        case OS_WSL:     return "WSL (Debian/Ubuntu)";
        case OS_MACOS:   return "macOS";
        case OS_WINDOWS: return "Windows";
        default:         return "Linux";
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Filesystem helpers
// ─────────────────────────────────────────────────────────────────────────

static inline int fos_file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

static inline int fos_dir_ensure(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) return 0;
    return mkdir(path, 0755);
}

// Resolve $HOME/<rel> into dst (size dstlen)
static inline void fos_home_path(char *dst, size_t dstlen, const char *rel) {
    const char *home = getenv("HOME");
    if (!home) {
        struct passwd *pw = getpwuid(getuid());
        home = pw ? pw->pw_dir : "/tmp";
    }
    snprintf(dst, dstlen, "%s/%s", home, rel);
}

// ─────────────────────────────────────────────────────────────────────────
//  run_cmd  — run a shell command, return its exit code
//  (mirrors the system() calls throughout the shell scripts)
// ─────────────────────────────────────────────────────────────────────────

static inline int fos_run(const char *cmd) {
    int rc = system(cmd);
    if (!WIFEXITED(rc)) return 127;
    return WEXITSTATUS(rc);
}

// Check if a command exists on PATH
static inline int fos_has_cmd(const char *cmd) {
    char buf[512];
    snprintf(buf, sizeof buf, "command -v %s >/dev/null 2>&1", cmd);
    return fos_run(buf) == 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  HPC execution — real parallelism wrappers
//
//  These are NOT cosmetic — they emit real compiler/env flags.
//  Shell twin: lib/run.sh  frun / frun_hpc
//  Full runner: src/runner/fos_runner.h + fos_runner.c  (flower-run binary)
//
//  fos_run_hpc(file):  compile + run with -O3 -fopenmp, OMP_NUM_THREADS=nproc
//  fos_run_gpu(file):  compile with nvcc if CUDA present, else OpenCL flags
// ─────────────────────────────────────────────────────────────────────────

// Number of logical CPUs — used for OMP_NUM_THREADS
static inline int fos_cpu_count(void) {
    FILE *f = popen("nproc 2>/dev/null", "r");
    if (!f) return 1;
    int n = 1;
    fscanf(f, "%d", &n);
    pclose(f);
    return (n > 0) ? n : 1;
}

// Compile and run a C file with HPC flags; returns program exit code
// For the full multi-language version, use flower-run --hpc
static inline int fos_compile_run_hpc(const char *src, const char *extra_args) {
    char cmd[4096];
    char tmp[256];
    int ncpu = fos_cpu_count();
    snprintf(tmp, sizeof(tmp), "/tmp/fos_hpc_%d", (int)getpid());
    snprintf(cmd, sizeof(cmd),
        "gcc -O3 -march=native -ffast-math -fopenmp -o %s %s "
        "&& OMP_NUM_THREADS=%d %s %s",
        tmp, src, ncpu, tmp, extra_args ? extra_args : "");
    int rc = fos_run(cmd);
    unlink(tmp);
    return rc;
}

// Invoke flower-run for full multi-language universal dispatch
// Falls back to bare system() if flower-run is not installed
static inline int fos_flower_run(const char *file, const char *opts) {
    if (fos_has_cmd("flower-run")) {
        char cmd[4096];
        snprintf(cmd, sizeof(cmd), "flower-run %s %s",
                 opts ? opts : "", file);
        return fos_run(cmd);
    }
    // Bare fallback: just try to execute if it looks like a script
    char cmd[4096];
    snprintf(cmd, sizeof(cmd), "bash %s", file);
    return fos_run(cmd);
}

// ─────────────────────────────────────────────────────────────────────────
//  apt install wrapper  (used by install.c, post_install.c, fp.c)
//  Mirrors the interactive apt block in post-install.sh install_*()
// ─────────────────────────────────────────────────────────────────────────

static inline int fos_apt_install(const char *packages, const char *why) {
    printf("\n" FOS_ACC "  📦 Package needed:" FOS_RST " %s\n", packages);
    if (why) printf(FOS_DIM "     %s" FOS_RST "\n", why);
    if (!fos_ask_yn("  Install now?", 'y')) {
        fos_warn("Skipped. Some features may not work.");
        return 1;
    }
    char cmd[2048];
    snprintf(cmd, sizeof cmd, "sudo apt install -y %s", packages);
    int rc = fos_run(cmd);
    if (rc == 0) fos_ok("Installed.");
    else         fos_err("apt install failed.");
    return rc;
}

// ─────────────────────────────────────────────────────────────────────────
//  curl download  — wraps curl, used by install.c for internet resources
// ─────────────────────────────────────────────────────────────────────────

#define FOS_MAX_PATH 4096

static inline int fos_curl_download(const char *url, const char *dest) {
    if (!fos_has_cmd("curl")) {
        fos_apt_install("curl", "Required to download files from the internet.");
    }
    char cmd[FOS_MAX_PATH * 2];
    snprintf(cmd, sizeof cmd,
        "curl -fsSL --progress-bar -o \"%s\" \"%s\"", dest, url);
    return fos_run(cmd);
}

#endif // FLOWEROS_H
