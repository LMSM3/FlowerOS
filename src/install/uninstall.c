// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Uninstaller  (src/install/uninstall.c)
//  C twin of uninstall.sh — 1:1 functional parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-uninstall uninstall.c
//  usage:  ./flower-uninstall [--force]
// ═══════════════════════════════════════════════════════════════════════════

#include "../floweros.h"

static struct {
    char install_dir[FOS_MAX_PATH];
    char bashrc[FOS_MAX_PATH];
    char state_dir[FOS_MAX_PATH];
    int  force;
} g;

// ─────────────────────────────────────────────────────────────────────────
//  Remove FlowerOS block from ~/.bashrc  (mirrors uninstall.sh step 1)
//  Uses the same FLOWEROS_MARKER guard as the installer.
// ─────────────────────────────────────────────────────────────────────────

static int remove_bashrc_block(void) {
    fos_info("Removing FlowerOS block from ~/.bashrc...");

    char grep_cmd[FOS_MAX_PATH * 2];
    snprintf(grep_cmd, sizeof grep_cmd,
        "grep -qF '%s' \"%s\" 2>/dev/null", FLOWEROS_MARKER, g.bashrc);

    if (fos_run(grep_cmd) != 0) {
        fos_info("Not found in ~/.bashrc (already clean).");
        return 0;
    }

    // Backup first (same as uninstall.sh)
    char backup[FOS_MAX_PATH];
    snprintf(backup, sizeof backup, "%s.backup.%ld", g.bashrc, (long)time(NULL));
    char cp_cmd[FOS_MAX_PATH * 2];
    snprintf(cp_cmd, sizeof cp_cmd, "cp \"%s\" \"%s\"", g.bashrc, backup);
    if (fos_run(cp_cmd) != 0) {
        fos_err("Failed to backup ~/.bashrc");
        return 1;
    }
    char msg[FOS_MAX_PATH];
    snprintf(msg, sizeof msg, "Backed up ~/.bashrc → %s", backup);
    fos_ok(msg);

    // Remove block from MARKER to closing 'fi' — same sed pattern as shell
    char sed_cmd[FOS_MAX_PATH * 2];
    snprintf(sed_cmd, sizeof sed_cmd,
        "sed -i '/^%s$/,/^fi$/d' \"%s\"", FLOWEROS_MARKER, g.bashrc);
    if (fos_run(sed_cmd) != 0) {
        fos_err("sed failed — restoring backup.");
        snprintf(cp_cmd, sizeof cp_cmd, "cp \"%s\" \"%s\"", backup, g.bashrc);
        fos_run(cp_cmd);
        return 1;
    }

    fos_ok("FlowerOS block removed from ~/.bashrc.");
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Remove install directory  (mirrors uninstall.sh step 2)
// ─────────────────────────────────────────────────────────────────────────

static int remove_install_dir(void) {
    if (!fos_file_exists(g.install_dir)) {
        fos_info("Install directory not found (already removed).");
        return 0;
    }

    printf(FOS_YLW "  Delete %s?" FOS_RST "\n", g.install_dir);
    if (!g.force && !fos_ask_yn("  This removes all FlowerOS binaries and data.", 'n')) {
        fos_info("Kept install directory.");
        return 0;
    }

    char cmd[FOS_MAX_PATH * 2];
    snprintf(cmd, sizeof cmd, "rm -rf \"%s\"", g.install_dir);
    if (fos_run(cmd) != 0) {
        fos_err("Failed to remove install directory.");
        return 1;
    }
    char msg[FOS_MAX_PATH];
    snprintf(msg, sizeof msg, "Removed %s", g.install_dir);
    fos_ok(msg);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Remove preferences  (not in shell version — bonus C feature)
// ─────────────────────────────────────────────────────────────────────────

static void remove_prefs(void) {
    if (!fos_file_exists(g.state_dir)) return;

    if (!g.force && !fos_ask_yn("  Remove ~/.floweros preferences?", 'n')) {
        fos_info("Kept ~/.floweros.");
        return;
    }
    char cmd[FOS_MAX_PATH * 2];
    snprintf(cmd, sizeof cmd, "rm -rf \"%s\"", g.state_dir);
    fos_run(cmd);
    fos_ok("Removed ~/.floweros.");
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--force") == 0) g.force = 1;
    }

    fos_home_path(g.install_dir, sizeof g.install_dir, FLOWEROS_INSTALL_DIR);
    fos_home_path(g.bashrc,      sizeof g.bashrc,      ".bashrc");
    fos_home_path(g.state_dir,   sizeof g.state_dir,   FLOWEROS_STATE_DIR);

    fos_box("FlowerOS Uninstaller", FOS_RED);

    if (!g.force) {
        printf(FOS_DIM "  Install dir: %s\n" FOS_RST, g.install_dir);
        if (!fos_ask_yn("  Proceed with uninstall?", 'n')) {
            fos_info("Uninstall cancelled.");
            return 0;
        }
    }

    if (remove_bashrc_block() != 0) return 1;
    if (remove_install_dir()  != 0) return 1;
    remove_prefs();

    printf("\n");
    fos_ok("Uninstallation complete.");
    fos_info("Run:  source ~/.bashrc  to apply changes.");
    printf("\n");
    return 0;
}
