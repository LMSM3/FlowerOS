// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Post-Install Tutorial  (src/install/post_install.c)
//  C twin of lib/post-install.sh — 1:1 functional parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-postinstall post_install.c
//  usage:  ./flower-postinstall
//
//  Runs after the main installer.  Walks the user through optional
//  tools one by one, explaining each before offering to install.
//  Every section mirrors the install_*() functions in post-install.sh.
// ═══════════════════════════════════════════════════════════════════════════

#include "../floweros.h"

// ─────────────────────────────────────────────────────────────────────────
//  open_url — cross-platform URL open (mirrors post-install.sh open logic)
// ─────────────────────────────────────────────────────────────────────────

static void open_url(const char *url, FosOS os) {
    char cmd[FOS_MAX_PATH * 2];
    switch (os) {
        case OS_WSL:
            snprintf(cmd, sizeof cmd, "wslview \"%s\" 2>/dev/null || "
                "powershell.exe -Command \"Start-Process '%s'\" 2>/dev/null || true", url, url);
            break;
        case OS_MACOS:
            snprintf(cmd, sizeof cmd, "open \"%s\" 2>/dev/null || true", url);
            break;
        default:
            snprintf(cmd, sizeof cmd, "xdg-open \"%s\" 2>/dev/null || true", url);
            break;
    }
    fos_run(cmd);
    printf(FOS_DIM "  (Or visit manually: %s)" FOS_RST "\n", url);
}

// ─────────────────────────────────────────────────────────────────────────
//  Each section = one optional tool  (mirrors install_*() in post-install.sh)
// ─────────────────────────────────────────────────────────────────────────

// ── 1. build-essential  (gcc / make) ─────────────────────────────────────

static void section_build_essential(FosOS os) {
    fos_header("Build Tools (gcc / make)");
    printf(
        "  FlowerOS C binaries need a compiler to build from source.\n\n"
        "  What it provides:\n"
        "    • gcc   — C compiler (builds all FlowerOS tools)\n"
        "    • make  — build automation\n"
        "    • ar    — static library tool\n\n");

    if (fos_has_cmd("gcc")) { fos_ok("gcc already installed."); return; }

    if (os == OS_DEBIAN || os == OS_WSL) {
        fos_apt_install("build-essential",
            "Compiler toolchain — needed to build FlowerOS binaries.");
    } else if (os == OS_MACOS) {
        if (!fos_ask_yn("  Install Xcode Command Line Tools?", 'y')) return;
        fos_run("xcode-select --install");
    } else {
        fos_info("Install gcc via your package manager (e.g. pacman -S gcc).");
    }
}

// ── 2. pdflatex / TeX Live ────────────────────────────────────────────────

static void section_pdflatex(FosOS os) {
    fos_header("LaTeX / pdflatex  (for FlowerPublish / fp)");
    printf(
        "  fp is the FlowerOS document tool. It compiles .tex to PDF.\n\n"
        "  What it provides:\n"
        "    • pdflatex     — LaTeX → PDF compiler\n"
        "    • texlive      — macro packages (geometry, hyperref, …)\n"
        "    • lmodern      — modern font set\n\n"
        "  Typical document workflow:\n"
        "    fp new paper   →  fp edit paper.tex  →  fp build paper.tex\n\n");

    if (fos_has_cmd("pdflatex")) { fos_ok("pdflatex already installed."); return; }

    if (!fos_ask_yn("  Install pdflatex? (~400 MB)", 'y')) {
        fos_info("Skipped. Run later:  fp deps");
        return;
    }

    if (os == OS_DEBIAN || os == OS_WSL) {
        fos_apt_install(
            "texlive-latex-base texlive-latex-recommended texlive-fonts-recommended",
            "Full TeX Live base — everything fp needs.");
    } else if (os == OS_MACOS) {
        if (fos_has_cmd("brew"))
            fos_run("brew install --cask mactex-no-gui");
        else
            open_url("https://tug.org/mactex/", os);
    } else {
        fos_info("Install TeX Live: https://tug.org/texlive/");
    }
}

// ── 3. Ollama (local LLM)  (mirrors install_ollama() in post-install.sh) ──

static void section_ollama(FosOS os) {
    fos_header("Ollama — Local AI Models (optional)");
    printf(
        "  Run AI models entirely on your machine — no cloud, no account.\n\n"
        "  What it provides:\n"
        "    • llama3.2, mistral, codellama, phi3, …\n"
        "    • REST API on localhost:11434\n"
        "    • Full privacy — nothing leaves your machine\n"
        "    • Typical model size: 2–8 GB\n\n");

    if (fos_has_cmd("ollama")) {
        fos_ok("Ollama already installed.");
        if (fos_ask_yn("  Pull recommended model (llama3.2)?", 'n'))
            fos_run("ollama pull llama3.2");
        return;
    }

    if (!fos_ask_yn("  Install Ollama?", 'n')) {
        fos_info("Skipped. Visit: https://ollama.com");
        return;
    }

    switch (os) {
        case OS_DEBIAN:
        case OS_WSL:
            fos_info("Installing Ollama via curl...");
            fos_run("curl -fsSL https://ollama.com/install.sh | sh");
            break;
        case OS_MACOS:
            if (fos_has_cmd("brew"))
                fos_run("brew install ollama");
            else
                open_url("https://ollama.com/download", os);
            break;
        default:
            open_url("https://ollama.com/download", os);
            break;
    }
}

// ── 4. fzf (fuzzy finder)  (mirrors install_fzf() in post-install.sh) ─────

static void section_fzf(FosOS os) {
    fos_header("fzf — Fuzzy Finder");
    printf(
        "  Supercharges your terminal search.\n\n"
        "  What it provides:\n"
        "    • Ctrl+R    — fuzzy command history search\n"
        "    • Ctrl+T    — fuzzy file picker\n"
        "    • Alt+C     — fuzzy cd\n"
        "    • Works with flower_fortune, flower_todo, etc.\n\n");

    if (fos_has_cmd("fzf")) { fos_ok("fzf already installed."); return; }

    if (!fos_ask_yn("  Install fzf?", 'y')) return;

    if (os == OS_DEBIAN || os == OS_WSL) {
        fos_apt_install("fzf", "Fuzzy finder — terminal productivity.");
    } else if (os == OS_MACOS) {
        fos_run("brew install fzf && $(brew --prefix)/opt/fzf/install --all");
    } else {
        open_url("https://github.com/junegunn/fzf", os);
    }
}

// ── 5. inotify-tools (for fp watch) ──────────────────────────────────────

static void section_inotify(FosOS os) {
    if (os != OS_DEBIAN && os != OS_WSL && os != OS_LINUX) return;

    fos_header("inotify-tools  (for fp watch)");
    printf(
        "  Enables fp watch — auto-rebuild LaTeX on save.\n\n"
        "  What it provides:\n"
        "    • inotifywait — watches files for changes\n"
        "    • fp watch paper.tex will recompile whenever you save\n\n");

    if (fos_has_cmd("inotifywait")) { fos_ok("inotifywait already installed."); return; }

    if (!fos_ask_yn("  Install inotify-tools?", 'y')) return;
    fos_apt_install("inotify-tools", "File-change watcher — used by fp watch.");
}

// ── 6. Oh-My-Posh (terminal theme engine) ────────────────────────────────

static void section_omp(FosOS os) {
    fos_header("Oh-My-Posh — Shell Prompt Engine (optional)");
    printf(
        "  Upgrades your terminal prompt with powerline glyphs.\n\n"
        "  What it provides:\n"
        "    • Nerd Font glyph support\n"
        "    • Git branch / status in prompt\n"
        "    • Language version display (Python, Node, …)\n"
        "    • FlowerOS pastel theme preset\n\n"
        "  Note: FlowerOS has its own built-in prompt that works\n"
        "  without any extras.  This is purely cosmetic.\n\n");

    if (!fos_ask_yn("  Install Oh-My-Posh?", 'n')) {
        fos_info("Skipped. Enable later: Flower-EnablePosh (PowerShell) or oh-my-posh init bash | eval");
        return;
    }

    switch (os) {
        case OS_WSL:
        case OS_LINUX:
        case OS_DEBIAN:
            fos_run("curl -s https://ohmyposh.dev/install.sh | bash -s");
            break;
        case OS_MACOS:
            fos_run("brew install jandedobbeleer/oh-my-posh/oh-my-posh");
            break;
        default:
            open_url("https://ohmyposh.dev/docs/installation/windows", os);
            break;
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(void) {
    FosOS os = fos_detect_os();

    fos_box("🌸  FlowerOS Post-Install Setup  🌸", FOS_PNK);

    printf(
        FOS_DIM "  This wizard walks you through optional tools.\n"
                "  Each one is explained before you decide.\n"
                "  You can safely skip anything — run this again any time.\n\n"
        FOS_RST);

    printf(FOS_DIM "  Detected: " FOS_RST FOS_ACC "%s" FOS_RST "\n\n",
        fos_os_name(os));

    if (!fos_ask_yn("  Begin optional setup?", 'y')) {
        fos_info("Run this again any time: flower-postinstall");
        return 0;
    }

    section_build_essential(os);  fos_pause(NULL);
    section_pdflatex(os);         fos_pause(NULL);
    section_inotify(os);
    section_fzf(os);              fos_pause(NULL);
    section_ollama(os);           fos_pause(NULL);
    section_omp(os);

    printf("\n");
    fos_box("✓  Post-install complete!", FOS_GRN);
    printf(FOS_DIM
        "  Re-run any time:   flower-postinstall\n"
        "  Change settings:   flower-config set <KEY> <value>\n"
        "  LaTeX docs:        fp help\n"
        "  To-do list:        flower-todo help\n\n"
        FOS_RST);

    return 0;
}
