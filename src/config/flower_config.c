// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Config Manager  (src/config/flower_config.c)
//  C twin of floweros-config.sh — 1:1 functional parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-config flower_config.c
//  usage:  flower-config get  <KEY>
//          flower-config set  <KEY> <value>
//          flower-config list
//          flower-config init          (re-write defaults)
//          flower-config reset         (restore all defaults)
//
//  Prefs file: ~/.floweros/preferences.conf  (same path as shell version)
//  Format:     KEY="value"  — exactly what bash `source` can read
// ═══════════════════════════════════════════════════════════════════════════

#include "../floweros.h"

// ─────────────────────────────────────────────────────────────────────────
//  Resolved paths
// ─────────────────────────────────────────────────────────────────────────

static char g_state_dir[FOS_MAX_PATH];
static char g_prefs[FOS_MAX_PATH];

static void resolve_paths(void) {
    fos_home_path(g_state_dir, sizeof g_state_dir, FLOWEROS_STATE_DIR);
    snprintf(g_prefs, sizeof g_prefs, "%s/%s", g_state_dir, FLOWEROS_PREFS_FILE);
}

// ─────────────────────────────────────────────────────────────────────────
//  init_config  (mirrors init_config() in floweros-config.sh)
// ─────────────────────────────────────────────────────────────────────────

static int cmd_init(int overwrite) {
    fos_dir_ensure(g_state_dir);

    if (!overwrite && fos_file_exists(g_prefs)) {
        fos_ok("Preferences already exist. Use 'flower-config reset' to restore defaults.");
        return 0;
    }

    char date_buf[32];
    time_t now = time(NULL);
    strftime(date_buf, sizeof date_buf, "%Y-%m-%d", localtime(&now));

    FILE *f = fopen(g_prefs, "w");
    if (!f) { fos_err("Cannot write preferences."); return 1; }

    fprintf(f,
        "# FlowerOS User Preferences\n"
        "# Generated: %s\n"
        "# Edit freely — or use: flower-config set <KEY> <value>\n"
        "\n"
        "# ── Theme ──────────────────────────────────────────────\n"
        "FLOWEROS_THEME=\"garden\"\n"
        "FLOWEROS_THEME_AUTO_APPLY=\"true\"\n"
        "\n"
        "# ── MOTD ────────────────────────────────────────────────\n"
        "FLOWEROS_MOTD_ENABLED=\"true\"\n"
        "FLOWEROS_MOTD_SIZE=\"medium\"\n"
        "FLOWEROS_MOTD_CUSTOM=\"\"\n"
        "\n"
        "# ── Welcome screen ──────────────────────────────────────\n"
        "FLOWEROS_WELCOME_SHOW_SYSTEM_INFO=\"true\"\n"
        "FLOWEROS_WELCOME_SHOW_COLORS=\"true\"\n"
        "FLOWEROS_WELCOME_SHOW_WISDOM=\"true\"\n"
        "FLOWEROS_WELCOME_STYLE=\"auto\"\n"
        "\n"
        "# ── Visual ──────────────────────────────────────────────\n"
        "FLOWEROS_NERD_FONTS_ENABLED=\"true\"\n"
        "FLOWEROS_COLOR_SCHEME=\"dracula\"\n"
        "FLOWEROS_IMAGE_COLS=\"120\"\n"
        "FLOWEROS_IMAGE_PASTEL=\"0.55\"\n"
        "FLOWEROS_IMAGE_MODE=\"half\"\n"
        "\n"
        "# ── Installation ────────────────────────────────────────\n"
        "FLOWEROS_INSTALLED_DATE=\"%s\"\n"
        "FLOWEROS_VERSION=\"%s\"\n"
        "FLOWEROS_USER=\"%s\"\n",
        date_buf, date_buf, FLOWEROS_VERSION,
        getenv("USER") ? getenv("USER") : "");

    fclose(f);

    char msg[FOS_MAX_PATH];
    snprintf(msg, sizeof msg, "Preferences written to %s", g_prefs);
    fos_ok(msg);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  get_pref  (mirrors get_pref() in floweros-config.sh)
// ─────────────────────────────────────────────────────────────────────────

static int cmd_get(const char *key) {
    if (!fos_file_exists(g_prefs)) {
        fos_err("No preferences file. Run: flower-config init");
        return 1;
    }

    FILE *f = fopen(g_prefs, "r");
    if (!f) { fos_err("Cannot read preferences."); return 1; }

    char line[1024];
    int found = 0;
    while (fgets(line, sizeof line, f)) {
        // Skip comments and blank lines
        char *p = line; while (isspace((unsigned char)*p)) p++;
        if (*p == '#' || *p == '\0') continue;

        // Match KEY="value" or KEY=value
        size_t klen = strlen(key);
        if (strncmp(p, key, klen) == 0 && p[klen] == '=') {
            char *val = p + klen + 1;
            // Strip surrounding quotes and trailing newline
            if (*val == '"') val++;
            char *end = val + strlen(val) - 1;
            while (end > val && (*end == '"' || *end == '\n' || *end == '\r'))
                *end-- = '\0';
            printf("%s\n", val);
            found = 1;
            break;
        }
    }
    fclose(f);

    if (!found) {
        char msg[256];
        snprintf(msg, sizeof msg, "Key not found: %s", key);
        fos_warn(msg);
        return 1;
    }
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  set_pref  (mirrors set_pref() in floweros-config.sh)
//  Identical logic: sed in-place if key exists, append if not.
// ─────────────────────────────────────────────────────────────────────────

static int cmd_set(const char *key, const char *value) {
    fos_dir_ensure(g_state_dir);

    if (!fos_file_exists(g_prefs)) cmd_init(0);

    // Check if key already present
    char grep_cmd[FOS_MAX_PATH * 2];
    snprintf(grep_cmd, sizeof grep_cmd,
        "grep -q '^%s=' \"%s\" 2>/dev/null", key, g_prefs);
    int exists = (fos_run(grep_cmd) == 0);

    if (exists) {
        // sed in-place replace — mirrors:  sed -i "s|^$key=.*|$key=\"$value\"|"
        char sed_cmd[FOS_MAX_PATH * 3];
        snprintf(sed_cmd, sizeof sed_cmd,
            "sed -i 's|^%s=.*|%s=\"%s\"|' \"%s\"", key, key, value, g_prefs);
        if (fos_run(sed_cmd) != 0) {
            fos_err("sed failed during set.");
            return 1;
        }
    } else {
        // Append new key
        FILE *f = fopen(g_prefs, "a");
        if (!f) { fos_err("Cannot open preferences for writing."); return 1; }
        fprintf(f, "%s=\"%s\"\n", key, value);
        fclose(f);
    }

    char msg[512];
    snprintf(msg, sizeof msg, "Set %s = %s", key, value);
    fos_ok(msg);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  list  — print all key=value pairs (no shell equivalent, C bonus)
// ─────────────────────────────────────────────────────────────────────────

static int cmd_list(void) {
    if (!fos_file_exists(g_prefs)) {
        fos_err("No preferences file. Run: flower-config init");
        return 1;
    }

    printf("\n" FOS_PNK "  🌸 FlowerOS Preferences" FOS_RST
           "  " FOS_DIM "(%s)" FOS_RST "\n", g_prefs);
    printf(FOS_DIM "  ─────────────────────────────────────────────────\n" FOS_RST);

    FILE *f = fopen(g_prefs, "r");
    if (!f) { fos_err("Cannot read preferences."); return 1; }

    char line[1024];
    while (fgets(line, sizeof line, f)) {
        char *p = line; while (isspace((unsigned char)*p)) p++;
        if (*p == '#') {
            // Print section headers dimmed
            char *nl = strchr(p, '\n'); if (nl) *nl = '\0';
            printf(FOS_DIM "  %s" FOS_RST "\n", p);
            continue;
        }
        if (*p == '\0' || *p == '\n') { printf("\n"); continue; }

        char *eq = strchr(p, '=');
        if (!eq) continue;

        *eq = '\0';
        char *val = eq + 1;
        char *nl = strchr(val, '\n'); if (nl) *nl = '\0';
        // Strip quotes
        if (*val == '"') { val++; char *e = val + strlen(val) - 1; if (*e == '"') *e = '\0'; }

        printf("  " FOS_ACC "%-42s" FOS_RST " %s\n", p, val);
    }
    fclose(f);
    printf(FOS_DIM "  ─────────────────────────────────────────────────\n" FOS_RST "\n");
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  help
// ─────────────────────────────────────────────────────────────────────────

static void print_help(void) {
    printf("\n" FOS_PNK "  🌸 flower-config" FOS_RST " — FlowerOS preference manager\n");
    printf(FOS_DIM "  ─────────────────────────────────────────────────\n" FOS_RST);
    printf("  " FOS_ACC "init" FOS_RST "              Write default preferences\n");
    printf("  " FOS_ACC "reset" FOS_RST "             Overwrite with fresh defaults\n");
    printf("  " FOS_ACC "list" FOS_RST "              Show all settings\n");
    printf("  " FOS_ACC "get" FOS_RST "  <KEY>        Print a single value\n");
    printf("  " FOS_ACC "set" FOS_RST "  <KEY> <val>  Change a value\n");
    printf(FOS_DIM "  ─────────────────────────────────────────────────\n" FOS_RST);
    printf("  File: " FOS_DIM "%s" FOS_RST "\n\n", g_prefs);
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    resolve_paths();

    if (argc < 2) { print_help(); return 0; }

    const char *cmd = argv[1];

    if (strcmp(cmd, "init")  == 0) return cmd_init(0);
    if (strcmp(cmd, "reset") == 0) return cmd_init(1);
    if (strcmp(cmd, "list")  == 0) return cmd_list();
    if (strcmp(cmd, "get")   == 0) {
        if (argc < 3) { fos_err("Usage: flower-config get <KEY>"); return 1; }
        return cmd_get(argv[2]);
    }
    if (strcmp(cmd, "set") == 0) {
        if (argc < 4) { fos_err("Usage: flower-config set <KEY> <value>"); return 1; }
        return cmd_set(argv[2], argv[3]);
    }
    if (strcmp(cmd, "help") == 0 || strcmp(cmd, "-h") == 0) {
        print_help(); return 0;
    }

    fprintf(stderr, FOS_RED "  ✗" FOS_RST " Unknown command: %s\n", cmd);
    print_help();
    return 1;
}
