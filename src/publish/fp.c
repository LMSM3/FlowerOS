// ═══════════════════════════════════════════════════════════════════════════
//  FlowerPublish (FP) — LaTeX Workflow Tool for FlowerOS
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -o fp fp.c
//  usage:  fp new  <name>       Create .tex from template
//          fp edit <file.tex>   Open in $EDITOR
//          fp build <file.tex>  Compile to PDF via pdflatex
//          fp view <file.pdf>   Open PDF viewer
//          fp watch <file.tex>  Rebuild on save (inotifywait)
//          fp deps              Install pdflatex + friends (Debian)
//          fp help              Show this
//
//  "Every document is a garden. pdflatex is the rain."
// ═══════════════════════════════════════════════════════════════════════════

#define _POSIX_C_SOURCE 200809L
#include "fp.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>
#include <time.h>
#include <libgen.h>

// ─────────────────────────────────────────────────────────────────────────
//   ✿  Banner  (the "showout")
// ─────────────────────────────────────────────────────────────────────────
//
//   Built-in splash — because every tool deserves a moment in the sun.
//   This block is the small showout requested in the source.
//
//        ╔═══════════════════════════════════╗
//        ║        🌸  FlowerPublish  🌸       ║
//        ║     pdflatex · Debian · WSL       ║
//        ║   "typeset beautifully or not     ║
//        ║        at all." — FP v1.0         ║
//        ╚═══════════════════════════════════╝
//
//   Architecture note:
//     FP does NOT embed its own editor.  It orchestrates:
//       1) Template scaffolding   →  fp new
//       2) $EDITOR delegation     →  fp edit
//       3) pdflatex compilation   →  fp build   (the real work)
//       4) PDF viewer launch      →  fp view
//       5) inotifywait loop       →  fp watch
//       6) Debian dep bootstrap   →  fp deps
//
//   pdflatex is invoked in non-stop mode with -interaction=nonstopmode
//   so FP can capture the full log and pretty-print errors in pastel.
//
//   Output lands in ./bloom/ (FlowerOS plant naming convention).
//
// ─────────────────────────────────────────────────────────────────────────

void fp_banner(void) {
    printf("\n");
    printf(FP_DIM "  ╔═══════════════════════════════════════════════╗\n");
    printf("  ║" FP_RST "                                               " FP_DIM "║\n");
    printf("  ║" FP_RST "       " FP_PNK "🌸  FlowerPublish" FP_RST "  " FP_ACC "v" FP_VERSION FP_RST "  " FP_PNK "🌸" FP_RST "          " FP_DIM "║\n");
    printf("  ║" FP_RST "       " FP_DIM "pdflatex · Debian · WSL" FP_RST "            " FP_DIM "║\n");
    printf("  ║" FP_RST "                                               " FP_DIM "║\n");
    printf("  ║" FP_RST "   " FP_DIM "\"typeset beautifully or not at all.\"" FP_RST "   " FP_DIM "║\n");
    printf("  ║" FP_RST "                                               " FP_DIM "║\n");
    printf("  ╚═══════════════════════════════════════════════╝" FP_RST "\n");
    printf("\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────

static void fp_ok(const char *msg)   { fprintf(stdout, FP_GRN "  ✓ " FP_RST "%s\n", msg); }
static void fp_err(const char *msg)  { fprintf(stderr, FP_RED "  ✗ " FP_RST "%s\n", msg); }
static void fp_info(const char *msg) { fprintf(stdout, FP_ACC "  ✿ " FP_RST "%s\n", msg); }
static void fp_warn(const char *msg) { fprintf(stdout, FP_YLW "  ⚠ " FP_RST "%s\n", msg); }

static int file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

static int has_command(const char *cmd) {
    char buf[FP_MAX_PATH];
    snprintf(buf, sizeof buf, "command -v %s >/dev/null 2>&1", cmd);
    return system(buf) == 0;
}

// Swap extension: "paper.tex" → "paper.pdf"
static void swap_ext(char *dst, size_t dstlen, const char *src, const char *newext) {
    strncpy(dst, src, dstlen - 1);
    dst[dstlen - 1] = '\0';
    char *dot = strrchr(dst, '.');
    if (dot) *dot = '\0';
    strncat(dst, newext, dstlen - strlen(dst) - 1);
}

// Basename without extension
static void stem(char *dst, size_t dstlen, const char *path) {
    char tmp[FP_MAX_PATH];
    strncpy(tmp, path, sizeof tmp - 1);
    tmp[sizeof tmp - 1] = '\0';
    char *b = basename(tmp);
    strncpy(dst, b, dstlen - 1);
    dst[dstlen - 1] = '\0';
    char *dot = strrchr(dst, '.');
    if (dot) *dot = '\0';
}

static void ensure_build_dir(void) {
    mkdir(FP_BUILD_DIR, 0755);
}

// ─────────────────────────────────────────────────────────────────────────
//  LaTeX template
// ─────────────────────────────────────────────────────────────────────────

static const char *latex_template =
    "\\documentclass[12pt,a4paper]{article}\n"
    "\n"
    "%% ── FlowerOS document template ──\n"
    "\\usepackage[utf8]{inputenc}\n"
    "\\usepackage[T1]{fontenc}\n"
    "\\usepackage{lmodern}\n"
    "\\usepackage{geometry}\n"
    "\\geometry{margin=1in}\n"
    "\\usepackage{hyperref}\n"
    "\\usepackage{graphicx}\n"
    "\\usepackage{xcolor}\n"
    "\n"
    "\\definecolor{flowerpink}{HTML}{FFB7D5}\n"
    "\\definecolor{flowermint}{HTML}{87D7FF}\n"
    "\n"
    "\\title{%s}\n"
    "\\author{FlowerOS}\n"
    "\\date{\\today}\n"
    "\n"
    "\\begin{document}\n"
    "\\maketitle\n"
    "\n"
    "\\section{Introduction}\n"
    "Your content here.\n"
    "\n"
    "\\end{document}\n";

// ─────────────────────────────────────────────────────────────────────────
//  fp new <name>
// ─────────────────────────────────────────────────────────────────────────

int fp_cmd_new(const char *name) {
    if (!name || !*name) {
        fp_err("Usage: fp new <document-name>");
        return FP_ERR_ARGS;
    }

    char filename[FP_MAX_PATH];
    snprintf(filename, sizeof filename, "%s.tex", name);

    if (file_exists(filename)) {
        char msg[FP_MAX_PATH];
        snprintf(msg, sizeof msg, "%s already exists.", filename);
        fp_warn(msg);
        return FP_ERR_IO;
    }

    FILE *f = fopen(filename, "w");
    if (!f) {
        fp_err("Cannot create file.");
        return FP_ERR_IO;
    }

    // Pretty title: replace underscores/hyphens with spaces
    char title[256];
    strncpy(title, name, sizeof title - 1);
    title[sizeof title - 1] = '\0';
    for (char *p = title; *p; p++) {
        if (*p == '_' || *p == '-') *p = ' ';
    }

    fprintf(f, latex_template, title);
    fclose(f);

    char msg[FP_MAX_PATH];
    snprintf(msg, sizeof msg, "Created %s", filename);
    fp_ok(msg);
    fp_info("Next: fp edit / fp build");
    return FP_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  fp edit <file>
// ─────────────────────────────────────────────────────────────────────────

int fp_cmd_edit(const char *file) {
    if (!file || !*file) {
        fp_err("Usage: fp edit <file.tex>");
        return FP_ERR_ARGS;
    }
    if (!file_exists(file)) {
        char msg[FP_MAX_PATH];
        snprintf(msg, sizeof msg, "File not found: %s", file);
        fp_err(msg);
        return FP_ERR_IO;
    }

    const char *editor = getenv("EDITOR");
    if (!editor || !*editor) {
        // Debian defaults
        if (has_command("nano"))      editor = "nano";
        else if (has_command("vi"))   editor = "vi";
        else if (has_command("vim"))  editor = "vim";
        else {
            fp_err("No $EDITOR set and no nano/vi found.");
            return FP_ERR_DEPS;
        }
    }

    char cmd[FP_MAX_PATH];
    snprintf(cmd, sizeof cmd, "%s \"%s\"", editor, file);

    char msg[FP_MAX_PATH];
    snprintf(msg, sizeof msg, "Opening %s in %s...", file, editor);
    fp_info(msg);

    int rc = system(cmd);
    return WIFEXITED(rc) ? WEXITSTATUS(rc) : FP_ERR_IO;
}

// ─────────────────────────────────────────────────────────────────────────
//  fp build <file>   — the core: invoke pdflatex
// ─────────────────────────────────────────────────────────────────────────

static void print_log_tail(const char *logpath, int max_lines) {
    FILE *f = fopen(logpath, "r");
    if (!f) return;

    // Count lines
    int total = 0;
    char line[FP_MAX_LINE];
    while (fgets(line, sizeof line, f)) total++;
    rewind(f);

    int skip = total > max_lines ? total - max_lines : 0;
    int cur = 0;
    printf("\n" FP_DIM "  ── pdflatex log (last %d lines) ──" FP_RST "\n", max_lines);
    while (fgets(line, sizeof line, f)) {
        if (cur++ < skip) continue;
        // Highlight errors / warnings
        if (strstr(line, "!") == line || strstr(line, "Error"))
            printf(FP_RED "  │ %s" FP_RST, line);
        else if (strstr(line, "Warning") || strstr(line, "Overfull") || strstr(line, "Underfull"))
            printf(FP_YLW "  │ %s" FP_RST, line);
        else
            printf(FP_DIM "  │ %s" FP_RST, line);
    }
    printf(FP_DIM "  ── end ──" FP_RST "\n\n");
    fclose(f);
}

int fp_cmd_build(const char *file, int clean) {
    if (!file || !*file) {
        fp_err("Usage: fp build <file.tex>");
        return FP_ERR_ARGS;
    }
    if (!file_exists(file)) {
        char msg[FP_MAX_PATH];
        snprintf(msg, sizeof msg, "File not found: %s", file);
        fp_err(msg);
        return FP_ERR_IO;
    }
    if (!has_command("pdflatex")) {
        fp_err("pdflatex not found. Run: fp deps");
        return FP_ERR_DEPS;
    }

    ensure_build_dir();

    char name[256];
    stem(name, sizeof name, file);

    // pdflatex invocation: non-stop, output to bloom/
    char cmd[FP_MAX_PATH];
    snprintf(cmd, sizeof cmd,
        "pdflatex -interaction=nonstopmode -halt-on-error "
        "-output-directory=%s \"%s\" > /dev/null 2>&1",
        FP_BUILD_DIR, file);

    printf(FP_ACC "  🌸 Building" FP_RST " %s" FP_DIM " → " FP_RST "%s/%s.pdf\n", file, FP_BUILD_DIR, name);

    // Run twice for references/TOC
    int rc1 = system(cmd);
    int rc2 = system(cmd);
    (void)rc1; // first pass seeds aux

    int ok = WIFEXITED(rc2) && WEXITSTATUS(rc2) == 0;

    char logpath[FP_MAX_PATH];
    snprintf(logpath, sizeof logpath, "%s/%s.log", FP_BUILD_DIR, name);

    if (ok) {
        char pdfpath[FP_MAX_PATH];
        snprintf(pdfpath, sizeof pdfpath, "%s/%s.pdf", FP_BUILD_DIR, name);

        // File size
        struct stat st;
        const char *size_str = "?";
        char size_buf[64];
        if (stat(pdfpath, &st) == 0) {
            if (st.st_size < 1024)
                snprintf(size_buf, sizeof size_buf, "%ld B", (long)st.st_size);
            else if (st.st_size < 1024*1024)
                snprintf(size_buf, sizeof size_buf, "%.1f KB", st.st_size / 1024.0);
            else
                snprintf(size_buf, sizeof size_buf, "%.2f MB", st.st_size / (1024.0*1024.0));
            size_str = size_buf;
        }

        char msg[FP_MAX_PATH];
        snprintf(msg, sizeof msg, "%s  (%s)", pdfpath, size_str);
        fp_ok(msg);
    } else {
        fp_err("pdflatex failed.");
        print_log_tail(logpath, FP_LOG_LINES);
        return FP_ERR_LATEX;
    }

    // Optionally clean aux files
    if (clean) {
        const char *exts[] = {".aux", ".log", ".out", ".toc", ".lof", ".lot", NULL};
        for (int i = 0; exts[i]; i++) {
            char tmp[FP_MAX_PATH];
            snprintf(tmp, sizeof tmp, "%s/%s%s", FP_BUILD_DIR, name, exts[i]);
            unlink(tmp);
        }
        fp_info("Cleaned auxiliary files.");
    }

    return FP_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  fp view <file>
// ─────────────────────────────────────────────────────────────────────────

int fp_cmd_view(const char *file) {
    char pdfpath[FP_MAX_PATH];

    if (file && *file) {
        // If user passed .tex, swap to .pdf in bloom/
        if (strstr(file, ".tex")) {
            char name[256];
            stem(name, sizeof name, file);
            snprintf(pdfpath, sizeof pdfpath, "%s/%s.pdf", FP_BUILD_DIR, name);
        } else {
            strncpy(pdfpath, file, sizeof pdfpath - 1);
            pdfpath[sizeof pdfpath - 1] = '\0';
        }
    } else {
        fp_err("Usage: fp view <file.tex|file.pdf>");
        return FP_ERR_ARGS;
    }

    if (!file_exists(pdfpath)) {
        char msg[FP_MAX_PATH];
        snprintf(msg, sizeof msg, "PDF not found: %s  (run fp build first?)", pdfpath);
        fp_err(msg);
        return FP_ERR_IO;
    }

    // Try viewers in order
    const char *viewers[] = {"xdg-open", "evince", "okular", "zathura", "mupdf", NULL};
    for (int i = 0; viewers[i]; i++) {
        if (has_command(viewers[i])) {
            char cmd[FP_MAX_PATH];
            snprintf(cmd, sizeof cmd, "%s \"%s\" &", viewers[i], pdfpath);
            char msg[FP_MAX_PATH];
            snprintf(msg, sizeof msg, "Opening %s with %s", pdfpath, viewers[i]);
            fp_info(msg);
            return system(cmd) == 0 ? FP_OK : FP_ERR_IO;
        }
    }

    // WSL fallback: try Windows viewer
    if (has_command("wslview")) {
        char cmd[FP_MAX_PATH];
        snprintf(cmd, sizeof cmd, "wslview \"%s\"", pdfpath);
        fp_info("Opening with wslview (WSL → Windows)");
        return system(cmd) == 0 ? FP_OK : FP_ERR_IO;
    }

    fp_warn("No PDF viewer found. Install evince: sudo apt install evince");
    char msg[FP_MAX_PATH];
    snprintf(msg, sizeof msg, "PDF ready at: %s", pdfpath);
    fp_ok(msg);
    return FP_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  fp watch <file>   — rebuild on save via inotifywait
// ─────────────────────────────────────────────────────────────────────────

int fp_cmd_watch(const char *file) {
    if (!file || !*file) {
        fp_err("Usage: fp watch <file.tex>");
        return FP_ERR_ARGS;
    }
    if (!file_exists(file)) {
        fp_err("File not found.");
        return FP_ERR_IO;
    }
    if (!has_command("inotifywait")) {
        fp_warn("inotifywait not found. Install: sudo apt install inotify-tools");
        return FP_ERR_DEPS;
    }

    printf(FP_PNK "  🌸 Watching" FP_RST " %s" FP_DIM "  (Ctrl+C to stop)" FP_RST "\n\n", file);

    // Initial build
    fp_cmd_build(file, 0);

    char cmd[FP_MAX_PATH];
    while (1) {
        snprintf(cmd, sizeof cmd,
            "inotifywait -qq -e close_write \"%s\" 2>/dev/null", file);
        int rc = system(cmd);
        if (!WIFEXITED(rc)) break;

        time_t now = time(NULL);
        struct tm *t = localtime(&now);
        char ts[32];
        strftime(ts, sizeof ts, "%H:%M:%S", t);
        printf(FP_DIM "  [%s] change detected" FP_RST "\n", ts);

        fp_cmd_build(file, 0);
    }

    return FP_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  fp deps  — install pdflatex + friends on Debian / Ubuntu
// ─────────────────────────────────────────────────────────────────────────

int fp_cmd_deps(void) {
    printf("\n");
    fp_info("FlowerPublish dependency installer (Debian/Ubuntu)");
    printf(FP_DIM "  ─────────────────────────────────────" FP_RST "\n");

    struct { const char *cmd; const char *pkg; const char *desc; } deps[] = {
        {"pdflatex",    "texlive-latex-base",       "LaTeX compiler"},
        {NULL,          "texlive-latex-recommended", "LaTeX packages (geometry, hyperref, …)"},
        {NULL,          "texlive-fonts-recommended", "Standard fonts (lmodern, etc.)"},
        {"inotifywait", "inotify-tools",            "File watcher (fp watch)"},
        {"nano",        "nano",                     "Fallback editor"},
        {NULL, NULL, NULL}
    };

    // Check which are missing
    int need_install = 0;
    char install_list[2048] = {0};

    for (int i = 0; deps[i].pkg; i++) {
        int present = 0;
        if (deps[i].cmd) {
            present = has_command(deps[i].cmd);
        } else {
            // Check dpkg
            char chk[512];
            snprintf(chk, sizeof chk, "dpkg -s %s >/dev/null 2>&1", deps[i].pkg);
            present = system(chk) == 0;
        }

        if (present) {
            char msg[512];
            snprintf(msg, sizeof msg, "%-32s %s", deps[i].pkg, deps[i].desc);
            fp_ok(msg);
        } else {
            char msg[512];
            snprintf(msg, sizeof msg, "%-32s %s", deps[i].pkg, deps[i].desc);
            fp_warn(msg);
            strncat(install_list, deps[i].pkg, sizeof install_list - strlen(install_list) - 2);
            strcat(install_list, " ");
            need_install = 1;
        }
    }

    if (!need_install) {
        printf("\n");
        fp_ok("All dependencies satisfied.");
        printf("\n");
        return FP_OK;
    }

    printf("\n");
    printf(FP_ACC "  Install missing packages?" FP_RST "\n");
    printf(FP_DIM "  sudo apt install %s" FP_RST "\n", install_list);
    printf("\n  [y/N] ");
    fflush(stdout);

    int c = getchar();
    if (c == 'y' || c == 'Y') {
        char cmd[2048];
        snprintf(cmd, sizeof cmd, "sudo apt install -y %s", install_list);
        printf("\n");
        int rc = system(cmd);
        if (WIFEXITED(rc) && WEXITSTATUS(rc) == 0) {
            printf("\n");
            fp_ok("Dependencies installed.");
        } else {
            printf("\n");
            fp_err("apt install failed.");
            return FP_ERR_DEPS;
        }
    } else {
        printf("\n");
        fp_info("Skipped. Run manually:");
        printf(FP_YLW "    sudo apt install %s" FP_RST "\n\n", install_list);
    }

    return FP_OK;
}

// ─────────────────────────────────────────────────────────────────────────
//  Command dispatch
// ─────────────────────────────────────────────────────────────────────────

FpCommand fp_parse_command(const char *arg) {
    if (!arg) return CMD_HELP;
    if (strcmp(arg, "new")   == 0) return CMD_NEW;
    if (strcmp(arg, "edit")  == 0) return CMD_EDIT;
    if (strcmp(arg, "build") == 0) return CMD_BUILD;
    if (strcmp(arg, "view")  == 0) return CMD_VIEW;
    if (strcmp(arg, "watch") == 0) return CMD_WATCH;
    if (strcmp(arg, "deps")  == 0) return CMD_DEPS;
    if (strcmp(arg, "help")  == 0) return CMD_HELP;
    if (strcmp(arg, "-h")    == 0) return CMD_HELP;
    if (strcmp(arg, "--help")== 0) return CMD_HELP;
    return CMD_UNKNOWN;
}

void fp_help(void) {
    fp_banner();
    printf(FP_DIM "  ─────────────────────────────────────" FP_RST "\n");
    printf("  " FP_ACC "new" FP_RST "   <name>       Create .tex from template\n");
    printf("  " FP_ACC "edit" FP_RST "  <file.tex>   Open in $EDITOR (nano fallback)\n");
    printf("  " FP_ACC "build" FP_RST " <file.tex>   Compile to PDF via pdflatex\n");
    printf("  " FP_ACC "view" FP_RST "  <file>       Open PDF viewer\n");
    printf("  " FP_ACC "watch" FP_RST " <file.tex>   Rebuild on save (inotifywait)\n");
    printf("  " FP_ACC "deps" FP_RST "              Install pdflatex on Debian/Ubuntu\n");
    printf("  " FP_ACC "help" FP_RST "              This message\n");
    printf(FP_DIM "  ─────────────────────────────────────" FP_RST "\n");
    printf("  Output dir: " FP_DIM "./%s/" FP_RST "\n", FP_BUILD_DIR);
    printf("\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    if (argc < 2) {
        fp_help();
        return FP_OK;
    }

    FpCommand cmd = fp_parse_command(argv[1]);
    const char *arg = (argc > 2) ? argv[2] : NULL;

    switch (cmd) {
        case CMD_HELP:    fp_help();                return FP_OK;
        case CMD_NEW:     return fp_cmd_new(arg);
        case CMD_EDIT:    return fp_cmd_edit(arg);
        case CMD_BUILD:   return fp_cmd_build(arg, 0);
        case CMD_VIEW:    return fp_cmd_view(arg);
        case CMD_WATCH:   return fp_cmd_watch(arg);
        case CMD_DEPS:    return fp_cmd_deps();
        case CMD_UNKNOWN:
        default:
            fprintf(stderr, FP_RED "  ✗ " FP_RST "Unknown command: %s\n", argv[1]);
            fp_help();
            return FP_ERR_ARGS;
    }
}
