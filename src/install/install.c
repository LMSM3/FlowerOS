// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Installer  (src/install/install.c)
//  C twin of install.sh — 1:1 functional parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-install install.c
//  usage:  ./flower-install [--silent] [--no-bashrc] [--tutorial]
//
//  End-user path:
//    1) Download this binary (or build from source)
//    2) Run it — it walks through every step interactively
//    3) Each step explains what it does and why before acting
//    4) Missing packages are detected and offered for install via apt
// ═══════════════════════════════════════════════════════════════════════════

#include "../floweros.h"
#include <dirent.h>
#include <libgen.h>

// ─────────────────────────────────────────────────────────────────────────
//  Installer state  (mirrors install.sh readonly globals)
// ─────────────────────────────────────────────────────────────────────────

static struct {
    char install_dir[FOS_MAX_PATH];   // $HOME/FlowerOS
    char ascii_dir[FOS_MAX_PATH];     // $HOME/FlowerOS/ascii
    char bashrc[FOS_MAX_PATH];        // $HOME/.bashrc
    char state_dir[FOS_MAX_PATH];     // $HOME/.floweros
    char prefs_file[FOS_MAX_PATH];    // $HOME/.floweros/preferences.conf
    int  silent;
    int  no_bashrc;
    int  tutorial;
    int  step_total;
    int  step_current;
} g;

// ─────────────────────────────────────────────────────────────────────────
//  Step header — numbered, pastel, mirroring deploy.sh banner()
// ─────────────────────────────────────────────────────────────────────────

static void step(const char *title) {
    g.step_current++;
    printf("\n" FOS_MAG FOS_BOLD
        "  ── Step %d/%d: %s ──" FOS_RST "\n\n",
        g.step_current, g.step_total, title);
}

static void tutorial_explain(const char *text) {
    if (!g.tutorial) return;
    printf(FOS_DIM
        "  ╭─ Why? ───────────────────────────────────────────────────\n"
        "  │  %s\n"
        "  ╰─────────────────────────────────────────────────────────\n"
        FOS_RST "\n", text);
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 1: Dependency check  (mirrors install.sh gcc detection block)
// ─────────────────────────────────────────────────────────────────────────

static int step_check_deps(void) {
    step("Check dependencies");
    tutorial_explain(
        "FlowerOS compiles small C programs to drive your terminal.\n"
        "  │  We need gcc (the C compiler) and make to build them.\n"
        "  │  Without these, nothing runs — this is the foundation.");

    int ok = 1;

    struct { const char *cmd; const char *pkg; const char *why; } deps[] = {
        {"gcc",  "build-essential", "C compiler — builds all FlowerOS binaries"},
        {"make", "build-essential", "Build automation — same package as gcc"},
        {"git",  "git",             "Version control — for future updates"},
        {"curl", "curl",            "Downloads files from the internet"},
        {NULL, NULL, NULL}
    };

    for (int i = 0; deps[i].cmd; i++) {
        if (fos_has_cmd(deps[i].cmd)) {
            char msg[256];
            snprintf(msg, sizeof msg, "Found: %s", deps[i].cmd);
            fos_ok(msg);
        } else {
            char msg[256];
            snprintf(msg, sizeof msg, "Missing: %s", deps[i].cmd);
            fos_warn(msg);
            if (fos_apt_install(deps[i].pkg, deps[i].why) != 0) {
                ok = 0;
            }
        }
    }

    return ok ? 0 : 1;
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 2: Create directories  (mirrors install.sh step 1)
// ─────────────────────────────────────────────────────────────────────────

static int step_make_dirs(void) {
    step("Create directory structure");
    tutorial_explain(
        "FlowerOS lives entirely inside your home directory — no root.\n"
        "  │  ~/FlowerOS/ascii  holds compiled binaries and art files.\n"
        "  │  ~/.floweros       holds your personal preferences.");

    const char *dirs[] = {
        g.install_dir,
        g.ascii_dir,
        g.state_dir,
        NULL
    };

    for (int i = 0; dirs[i]; i++) {
        if (fos_dir_ensure(dirs[i]) == 0) {
            char msg[FOS_MAX_PATH];
            snprintf(msg, sizeof msg, "Directory ready: %s", dirs[i]);
            fos_ok(msg);
        } else if (errno != EEXIST) {
            char msg[FOS_MAX_PATH];
            snprintf(msg, sizeof msg, "Failed to create %s: %s",
                dirs[i], strerror(errno));
            fos_err(msg);
            return 1;
        }
    }
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 3: Build/copy binaries  (mirrors install.sh step 2)
// ─────────────────────────────────────────────────────────────────────────

static int step_install_binaries(void) {
    step("Install FlowerOS binaries");
    tutorial_explain(
        "These small C programs are the engine of FlowerOS:\n"
        "  │   random    — picks random ASCII art lines\n"
        "  │   animate   — plays terminal animations\n"
        "  │   banner    — generates pastel ASCII banners\n"
        "  │   fortune   — displays themed wisdom\n"
        "  │   colortest — diagnoses terminal colour support\n"
        "  │   fp        — LaTeX document workflow\n"
        "  │   flower-install  — this installer (self-hosted)");

    const char *bins[] = {
        "random", "animate", "banner", "fortune", "colortest", "fp", NULL
    };

    int copied = 0;
    for (int i = 0; bins[i]; i++) {
        // Look for pre-built binary next to installer
        char src[FOS_MAX_PATH], dst[FOS_MAX_PATH];
        snprintf(src, sizeof src, "./%s", bins[i]);
        snprintf(dst, sizeof dst, "%s/%s", g.ascii_dir, bins[i]);

        if (fos_file_exists(src)) {
            char cmd[FOS_MAX_PATH * 2];
            snprintf(cmd, sizeof cmd, "cp \"%s\" \"%s\" && chmod 755 \"%s\"",
                src, dst, dst);
            if (fos_run(cmd) == 0) {
                char msg[FOS_MAX_PATH];
                snprintf(msg, sizeof msg, "Installed: %s", bins[i]);
                fos_ok(msg);
                copied++;
            }
        }
    }

    if (copied == 0) {
        fos_warn("No pre-built binaries found — building from source...");
        tutorial_explain(
            "Building from source means we compile the C files right here.\n"
            "  │  This takes a few seconds. You only do this once.");

        // Check for src directory
        char src_utils[FOS_MAX_PATH];
        snprintf(src_utils, sizeof src_utils, "%s/src/utils", g.install_dir);

        if (!fos_file_exists("build.sh")) {
            fos_warn("build.sh not found — binaries will be built on first use.");
            return 0;
        }

        if (fos_run("bash build.sh") != 0) {
            fos_err("Build failed. Check gcc is installed and try again.");
            return 1;
        }

        // Retry copy after build
        for (int i = 0; bins[i]; i++) {
            char src[FOS_MAX_PATH], dst[FOS_MAX_PATH];
            snprintf(src, sizeof src, "./%s", bins[i]);
            snprintf(dst, sizeof dst, "%s/%s", g.ascii_dir, bins[i]);
            if (fos_file_exists(src)) {
                char cmd[FOS_MAX_PATH * 2];
                snprintf(cmd, sizeof cmd, "cp \"%s\" \"%s\" && chmod 755 \"%s\"",
                    src, dst, dst);
                if (fos_run(cmd) == 0) copied++;
            }
        }
    }

    // Copy data files (*.ascii, *.txt, *.anim)
    if (fos_run("ls *.ascii >/dev/null 2>&1") == 0)
        fos_run("cp *.ascii \"" FOS_GRN "\"" FOS_RST);

    char cp_data[FOS_MAX_PATH * 2];
    snprintf(cp_data, sizeof cp_data,
        "cp *.ascii *.anim *.txt \"%s/\" 2>/dev/null; true", g.ascii_dir);
    fos_run(cp_data);
    fos_ok("Copied art/animation data files.");

    char msg[64];
    snprintf(msg, sizeof msg, "%d binaries installed to %s", copied, g.ascii_dir);
    fos_info(msg);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 4: Write ~/.bashrc block  (mirrors install.sh step 4)
//  Idempotent — same FLOWEROS_MARKER guard as shell version.
// ─────────────────────────────────────────────────────────────────────────

static const char *bashrc_block =
    "\n"
    FLOWEROS_MARKER "\n"
    "# Paths\n"
    "export FLOWEROS_VERSION=\"" FLOWEROS_VERSION "\"\n"
    "export FLOWEROS_ROOT=\"${HOME}/FlowerOS\"\n"
    "export FLOWEROS_DIR=\"${FLOWEROS_ROOT}/ascii\"\n"
    "\n"
    "# Add FlowerOS bin/ to PATH (flower-run, flower-walk, flower-motd…)\n"
    "[[ -d \"${FLOWEROS_ROOT}/bin\" ]] && export PATH=\"${FLOWEROS_ROOT}/bin:${PATH}\"\n"
    "\n"
    "# Shell libraries — load in order: colors → run → welcome\n"
    "[[ -f \"${FLOWEROS_ROOT}/lib/flower_ascii.sh\" ]] && source \"${FLOWEROS_ROOT}/lib/flower_ascii.sh\"\n"
    "[[ -f \"${FLOWEROS_ROOT}/lib/run.sh\"          ]] && source \"${FLOWEROS_ROOT}/lib/run.sh\"\n"
    "[[ -f \"${FLOWEROS_ROOT}/lib/welcome.sh\"      ]] && source \"${FLOWEROS_ROOT}/lib/welcome.sh\"\n"
    "\n"
    "# Core command aliases\n"
    "alias flower-walk='bash \"${FLOWEROS_ROOT}/experimental/animations/flower_walk_demo.sh\"'\n"
    "alias flower-motd='\"${FLOWEROS_ROOT}/bin/flower-motd\" 2>/dev/null || true'\n"
    "\n"
    "# Legacy helpers (kept for backward compat)\n"
    "flower_banner()  { [[ -x \"${FLOWEROS_DIR}/banner\"  ]] && \"${FLOWEROS_DIR}/banner\"  \"$@\" || echo \"$*\"; }\n"
    "flower_animate() { [[ -x \"${FLOWEROS_DIR}/animate\" ]] && \"${FLOWEROS_DIR}/animate\" \"${FLOWEROS_DIR}/${1:-flower.anim}\" \"${2:-10}\" \"${3:-0}\"; }\n"
    "flower_fortune() { [[ -x \"${FLOWEROS_DIR}/fortune\" ]] && \"${FLOWEROS_DIR}/fortune\" \"$@\" || true; }\n"
    "flower_todo()    { bash \"${FLOWEROS_ROOT}/tools/flower-todo.sh\" \"$@\" 2>/dev/null || true; }\n"
    "flower_fp()      { \"${FLOWEROS_DIR}/fp\" \"$@\" 2>/dev/null || true; }\n"
    "alias fp='flower_fp'\n";

static int step_patch_bashrc(void) {
    step("Register with ~/.bashrc");
    tutorial_explain(
        "Adding a small block to ~/.bashrc means FlowerOS functions\n"
        "  │  are available in every new terminal automatically.\n"
        "  │  The block is guarded by a marker comment so it is\n"
        "  │  never written twice (idempotent, safe to re-run).");

    if (g.no_bashrc) {
        fos_info("--no-bashrc flag set, skipping.");
        return 0;
    }

    // Already installed?
    char grep_cmd[FOS_MAX_PATH * 2];
    snprintf(grep_cmd, sizeof grep_cmd,
        "grep -qF '%s' \"%s\" 2>/dev/null", FLOWEROS_MARKER, g.bashrc);
    if (fos_run(grep_cmd) == 0) {
        fos_ok("~/.bashrc already contains FlowerOS block (skipping).");
        return 0;
    }

    FILE *f = fopen(g.bashrc, "a");
    if (!f) {
        char msg[FOS_MAX_PATH];
        snprintf(msg, sizeof msg, "Cannot open %s: %s", g.bashrc, strerror(errno));
        fos_err(msg);
        return 1;
    }
    fputs(bashrc_block, f);
    fclose(f);
    fos_ok("FlowerOS block appended to ~/.bashrc.");
    fos_info("Run:  source ~/.bashrc  (or open a new terminal)");
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 5: Write default preferences  (mirrors floweros-config.sh init_config)
// ─────────────────────────────────────────────────────────────────────────

static int step_write_prefs(void) {
    step("Write default preferences");
    tutorial_explain(
        "~/.floweros/preferences.conf stores your personal settings:\n"
        "  │  theme, MOTD style, colour scheme, etc.\n"
        "  │  Edit it any time with a text editor, or use\n"
        "  │    flower-config set <key> <value>");

    if (fos_file_exists(g.prefs_file)) {
        fos_ok("Preferences file already exists (keeping yours).");
        return 0;
    }

    // Get current date for FLOWEROS_INSTALLED_DATE
    char date_buf[32];
    time_t now = time(NULL);
    strftime(date_buf, sizeof date_buf, "%Y-%m-%d", localtime(&now));

    FILE *f = fopen(g.prefs_file, "w");
    if (!f) {
        fos_err("Cannot write preferences file.");
        return 1;
    }

    fprintf(f,
        "# FlowerOS User Preferences\n"
        "# Auto-generated by flower-install on %s\n"
        "# Edit freely — flower-config reads this on startup.\n"
        "\n"
        "# Theme\n"
        "FLOWEROS_THEME=\"garden\"\n"
        "FLOWEROS_THEME_AUTO_APPLY=\"true\"\n"
        "\n"
        "# MOTD\n"
        "FLOWEROS_MOTD_ENABLED=\"true\"\n"
        "FLOWEROS_MOTD_SIZE=\"medium\"\n"
        "FLOWEROS_MOTD_CUSTOM=\"\"\n"
        "\n"
        "# Welcome screen\n"
        "FLOWEROS_WELCOME_SHOW_SYSTEM_INFO=\"true\"\n"
        "FLOWEROS_WELCOME_SHOW_COLORS=\"true\"\n"
        "FLOWEROS_WELCOME_SHOW_WISDOM=\"true\"\n"
        "FLOWEROS_WELCOME_STYLE=\"auto\"\n"
        "\n"
        "# Visual\n"
        "FLOWEROS_NERD_FONTS_ENABLED=\"true\"\n"
        "FLOWEROS_COLOR_SCHEME=\"dracula\"\n"
        "\n"
        "# Installation\n"
        "FLOWEROS_INSTALLED_DATE=\"%s\"\n"
        "FLOWEROS_VERSION=\"%s\"\n"
        "FLOWEROS_USER=\"%s\"\n",
        date_buf, date_buf, FLOWEROS_VERSION,
        getenv("USER") ? getenv("USER") : "unknown");

    fclose(f);
    char msg[FOS_MAX_PATH];
    snprintf(msg, sizeof msg, "Preferences written to %s", g.prefs_file);
    fos_ok(msg);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 6: Post-install tutorial  (mirrors lib/post-install.sh)
// ─────────────────────────────────────────────────────────────────────────

static void step_tutorial(void) {
    step("Tour — what you just installed");

    printf(FOS_ACC "  FlowerOS is now active.  Here is everything you can do:\n" FOS_RST "\n");

    struct { const char *cmd; const char *desc; } tour[] = {
        // ── Running code ─────────────────────────────────────────────
        {"frun hello.c",                    "Compile and run C (or any of 17 languages)"},
        {"frun --hpc simulate.c",           "Same, with -O3 -march=native -fopenmp"},
        {"frun --gpu particles.cu",         "Same, with CUDA / nvcc"},
        {"frun --time model.py",            "Show compile + run duration"},
        {"frun_list",                       "Print the full language table"},
        // ── Terminal ─────────────────────────────────────────────────
        {"flower-walk",                     "Walking flower animation (press q to quit)"},
        {"flower-motd",                     "System info dashboard"},
        {"flower_fortune",                  "Print a themed wisdom quote"},
        {"flower_banner 'hello'",           "Pastel ASCII banner"},
        // ── Documents ────────────────────────────────────────────────
        {"fp new my-paper",                 "Create a new LaTeX document"},
        {"fp build my-paper.tex",           "Compile it to PDF"},
        // ── Configuration ────────────────────────────────────────────
        {"flower-config set FLOWEROS_THEME spring", "Change your colour theme"},
        {"flower-todo add 'do a thing'",    "Add a to-do item"},
        // ── Help ─────────────────────────────────────────────────────
        {"fhelp",                           "Show the welcome screen any time"},
        {"fhelp -l",                        "Welcome screen + full language table"},
        {NULL, NULL}
    };

    for (int i = 0; tour[i].cmd; i++) {
        printf("  " FOS_YLW "%-42s" FOS_RST " %s\n", tour[i].cmd, tour[i].desc);
    }

    printf("\n" FOS_DIM
        "  Full docs:    ~/FlowerOS/\n"
        "  Preferences:  ~/.floweros/preferences.conf\n"
        "  Source code:  ~/FlowerOS/src/\n"
        "  Reset welcome screen:  rm ~/.floweros/welcomed\n" FOS_RST "\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  Parse args
// ─────────────────────────────────────────────────────────────────────────

static void parse_args(int argc, char **argv) {
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--silent")    == 0) g.silent    = 1;
        if (strcmp(argv[i], "--no-bashrc") == 0) g.no_bashrc = 1;
        if (strcmp(argv[i], "--tutorial")  == 0) g.tutorial  = 1;
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    parse_args(argc, argv);

    // Resolve paths (mirrors readonly vars in install.sh)
    fos_home_path(g.install_dir, sizeof g.install_dir, FLOWEROS_INSTALL_DIR);
    snprintf(g.ascii_dir,   sizeof g.ascii_dir,   "%s/ascii",  g.install_dir);
    fos_home_path(g.bashrc,      sizeof g.bashrc,      ".bashrc");
    fos_home_path(g.state_dir,   sizeof g.state_dir,   FLOWEROS_STATE_DIR);
    snprintf(g.prefs_file,  sizeof g.prefs_file,  "%s/%s",
        g.state_dir, FLOWEROS_PREFS_FILE);

    g.step_total   = 6;
    g.step_current = 0;
    g.tutorial     = 1; // on by default — can be silenced with --silent

    if (g.silent) g.tutorial = 0;

    // Welcome
    fos_box("🌸  FlowerOS Installer  v" FLOWEROS_VERSION "  🌸", FOS_GRN);
    printf(FOS_DIM "  This installer will set up FlowerOS on your machine.\n"
                   "  Each step explains what it does before acting.\n"
                   "  Nothing requires root except optional package installs.\n\n"
           FOS_RST);

    FosOS os = fos_detect_os();
    printf(FOS_DIM "  Detected OS: " FOS_RST FOS_ACC "%s" FOS_RST "\n",
        fos_os_name(os));
    printf(FOS_DIM "  Install dir: " FOS_RST "%s\n\n", g.install_dir);

    if (!g.silent) {
        if (!fos_ask_yn("  Ready to begin?", 'y')) {
            fos_info("Installation cancelled.");
            return 0;
        }
    }

    // Run steps
    if (step_check_deps()     != 0) fos_die("Dependency check failed.");
    if (step_make_dirs()      != 0) fos_die("Could not create directories.");
    if (step_install_binaries()!= 0) fos_die("Binary install failed.");
    if (step_patch_bashrc()   != 0) fos_die("~/.bashrc update failed.");
    if (step_write_prefs()    != 0) fos_warn("Preferences not written (non-fatal).");
    step_tutorial();

    // Done
    fos_box("✓  Installation complete!", FOS_GRN);
    printf(FOS_GRN "  Next: " FOS_RST "source ~/.bashrc\n"
           FOS_YLW "  Then: " FOS_RST "flower_fortune\n\n");

    return 0;
}
