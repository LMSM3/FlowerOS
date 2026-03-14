// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS MOTD Display  (src/motd/show_motd.c)
//  C twin of motd/show-motd.sh — 1:1 functional parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I../.. -o flower-motd show_motd.c
//  usage:  flower-motd [motd-name]
//          flower-motd --random
//          flower-motd --sysinfo
//
//  Mirrors all three functions from show-motd.sh:
//    select_motd()     — terminal-width-aware file selection
//    show_motd()       — display ASCII file or fallback
//    show_system_info()— uptime / hostname / load
// ═══════════════════════════════════════════════════════════════════════════

#include "../../src/floweros.h"
#include <sys/ioctl.h>
#include <dirent.h>

// ─────────────────────────────────────────────────────────────────────────
//  Config  (mirrors show-motd.sh top-level variables)
// ─────────────────────────────────────────────────────────────────────────

#define DEFAULT_MOTD   "01"
#define SIZE_SMALL     "small"
#define SIZE_MEDIUM    "medium"
#define SIZE_LARGE     "large"
#define WIDTH_SM       80
#define WIDTH_LG       140

// ─────────────────────────────────────────────────────────────────────────
//  get_terminal_width  (mirrors get_terminal_width() in show-motd.sh)
// ─────────────────────────────────────────────────────────────────────────

static int get_terminal_width(void) {
    // $COLUMNS first (mirrors shell version)
    const char *cols_env = getenv("COLUMNS");
    if (cols_env && *cols_env) {
        int w = atoi(cols_env);
        if (w > 0) return w;
    }
    // ioctl fallback
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0)
        return ws.ws_col;
    return 80;
}

// ─────────────────────────────────────────────────────────────────────────
//  select_motd  (mirrors select_motd() in show-motd.sh)
// ─────────────────────────────────────────────────────────────────────────

static void select_motd(char *out, size_t outlen,
                        const char *motd_dir, const char *name) {
    int width = get_terminal_width();
    const char *size;
    if      (width < WIDTH_SM) size = SIZE_SMALL;
    else if (width < WIDTH_LG) size = SIZE_MEDIUM;
    else                       size = SIZE_LARGE;

    snprintf(out, outlen, "%s/%s-%s.ascii", motd_dir, name, size);

    // Fallback to medium if selected size not found
    if (!fos_file_exists(out))
        snprintf(out, outlen, "%s/%s-%s.ascii", motd_dir, name, SIZE_MEDIUM);
}

// ─────────────────────────────────────────────────────────────────────────
//  show_motd  (mirrors show_motd() in show-motd.sh)
// ─────────────────────────────────────────────────────────────────────────

static void show_motd(const char *motd_dir, const char *name) {
    char path[FOS_MAX_PATH];
    select_motd(path, sizeof path, motd_dir, name);

    if (fos_file_exists(path)) {
        FILE *f = fopen(path, "r");
        if (f) {
            char buf[4096];
            while (fgets(buf, sizeof buf, f)) fputs(buf, stdout);
            fclose(f);
            return;
        }
    }

    // Fallback message (mirrors shell fallback block)
    printf("\n");
    printf(FOS_PNK "  ✿ FlowerOS ✿\n" FOS_RST);
    printf(FOS_DIM "  Welcome to your terminal\n" FOS_RST);
    printf("\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  show_random_motd  (mirrors show_random_motd() in show-motd.sh)
// ─────────────────────────────────────────────────────────────────────────

static void show_random_motd(const char *motd_dir) {
    DIR *d = opendir(motd_dir);
    if (!d) { show_motd(motd_dir, DEFAULT_MOTD); return; }

    // Collect base names (NN from NN-medium.ascii)
    char names[64][8];
    int count = 0;

    struct dirent *ent;
    while ((ent = readdir(d)) && count < 64) {
        char *nm = ent->d_name;
        char *med = strstr(nm, "-medium.ascii");
        if (!med) continue;
        int len = (int)(med - nm);
        if (len <= 0 || len >= 8) continue;
        strncpy(names[count], nm, (size_t)len);
        names[count][len] = '\0';
        count++;
    }
    closedir(d);

    if (count == 0) { show_motd(motd_dir, DEFAULT_MOTD); return; }

    srand((unsigned)time(NULL));
    show_motd(motd_dir, names[rand() % count]);
}

// ─────────────────────────────────────────────────────────────────────────
//  show_system_info  (mirrors show_system_info() in show-motd.sh)
// ─────────────────────────────────────────────────────────────────────────

static void show_system_info(void) {
    char hostname[256] = "unknown";
    gethostname(hostname, sizeof hostname);

    // Uptime from /proc/uptime
    char uptime_str[64] = "unknown";
    FILE *f = fopen("/proc/uptime", "r");
    if (f) {
        double secs;
        if (fscanf(f, "%lf", &secs) == 1) {
            long h = (long)(secs / 3600);
            long m = (long)((secs - h * 3600) / 60);
            snprintf(uptime_str, sizeof uptime_str, "%ld h %ld min", h, m);
        }
        fclose(f);
    }

    // Load average from /proc/loadavg
    char load[64] = "unknown";
    f = fopen("/proc/loadavg", "r");
    if (f) {
        float l1, l5, l15;
        if (fscanf(f, "%f %f %f", &l1, &l5, &l15) == 3)
            snprintf(load, sizeof load, "%.2f %.2f %.2f", l1, l5, l15);
        fclose(f);
    }

    // Current date/time
    time_t now = time(NULL);
    char datebuf[32];
    strftime(datebuf, sizeof datebuf, "%Y-%m-%d %H:%M", localtime(&now));

    printf("\n");
    printf(FOS_DIM "  ─────────────────────────────────────\n" FOS_RST);
    printf("  " FOS_ACC "System" FOS_RST "   %s\n", hostname);
    printf("  " FOS_ACC "Date  " FOS_RST "   %s\n", datebuf);
    printf("  " FOS_ACC "Uptime" FOS_RST "   %s\n", uptime_str);
    printf("  " FOS_ACC "Load  " FOS_RST "   %s\n", load);
    printf(FOS_DIM "  ─────────────────────────────────────\n" FOS_RST);
    printf("\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    // Resolve MOTD directory (mirrors MOTD_DIR in show-motd.sh)
    char motd_dir[FOS_MAX_PATH];
    const char *env_dir = getenv("MOTD_DIR");
    if (env_dir && *env_dir) {
        strncpy(motd_dir, env_dir, sizeof motd_dir - 1);
        motd_dir[sizeof motd_dir - 1] = '\0';
    } else {
        fos_home_path(motd_dir, sizeof motd_dir, "FlowerOS/motd/ascii-output");
    }

    int do_sysinfo = 0;
    int do_random  = 0;
    const char *name = DEFAULT_MOTD;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--random")  == 0) do_random  = 1;
        else if (strcmp(argv[i], "--sysinfo") == 0) do_sysinfo = 1;
        else name = argv[i];
    }

    if (do_random)
        show_random_motd(motd_dir);
    else
        show_motd(motd_dir, name);

    if (do_sysinfo)
        show_system_info();

    return 0;
}
