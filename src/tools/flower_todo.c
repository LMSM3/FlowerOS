// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS To-Do Notepad  (src/tools/flower_todo.c)
//  C twin of tools/flower-todo.sh — 1:1 functional parity
//
//  build:  gcc -O2 -std=c11 -Wall -Wextra -I../.. -o flower-todo flower_todo.c
//  usage:  flower-todo add  <text>
//          flower-todo list
//          flower-todo done <id>
//          flower-todo undo <id>
//          flower-todo rm   <id>
//          flower-todo clear
//          flower-todo help
//
//  Data: ~/.config/floweros/todo.json  (same path as shell version)
//  Format: JSON array of {id, text, done, created}
// ═══════════════════════════════════════════════════════════════════════════

#include "../../src/floweros.h"
#include <stdint.h>

// ─────────────────────────────────────────────────────────────────────────
//  Task model  — one entry in todo.json
// ─────────────────────────────────────────────────────────────────────────

#define MAX_TASKS    256
#define MAX_TEXT_LEN 512
#define MAX_TS_LEN   32

typedef struct {
    int  id;
    char text[MAX_TEXT_LEN];
    int  done;
    char created[MAX_TS_LEN];
} Task;

static Task  g_tasks[MAX_TASKS];
static int   g_count = 0;
static char  g_todo_file[FOS_MAX_PATH];

// ─────────────────────────────────────────────────────────────────────────
//  Minimal JSON  — parse and emit todo.json without any library
//  Mirrors the jq-less fallback path in flower-todo.sh
// ─────────────────────────────────────────────────────────────────────────

// Advance past whitespace
static const char *skip_ws(const char *p) {
    while (p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    return p;
}

// Parse a JSON string value — returns pointer past closing quote
static const char *parse_str(const char *p, char *out, size_t outlen) {
    if (!p || *p != '"') return p;
    p++;
    size_t i = 0;
    while (*p && *p != '"') {
        if (*p == '\\') p++;  // skip escape
        if (i < outlen - 1) out[i++] = *p;
        p++;
    }
    out[i] = '\0';
    return (*p == '"') ? p + 1 : p;
}

// Load tasks from todo.json  (mirrors Load-Tasks in flower-todo.ps1 / jq path in .sh)
static void load_tasks(void) {
    g_count = 0;
    FILE *f = fopen(g_todo_file, "r");
    if (!f) return;

    // Read whole file
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    rewind(f);
    if (sz <= 0) { fclose(f); return; }

    char *buf = malloc((size_t)sz + 1);
    if (!buf) { fclose(f); return; }
    fread(buf, 1, (size_t)sz, f);
    buf[sz] = '\0';
    fclose(f);

    const char *p = skip_ws(buf);
    if (*p != '[') { free(buf); return; }
    p++;

    while (g_count < MAX_TASKS) {
        p = skip_ws(p);
        if (*p == ']' || *p == '\0') break;
        if (*p == ',') { p++; continue; }
        if (*p != '{') { p++; continue; }
        p++;

        Task t = {0};
        // Parse key/value pairs in object
        while (*p && *p != '}') {
            p = skip_ws(p);
            if (*p == ',') { p++; continue; }
            if (*p != '"') { p++; continue; }

            char key[64];
            p = parse_str(p, key, sizeof key);
            p = skip_ws(p);
            if (*p == ':') p++;
            p = skip_ws(p);

            if (strcmp(key, "id") == 0) {
                t.id = atoi(p);
                while (*p && *p != ',' && *p != '}') p++;
            } else if (strcmp(key, "text") == 0) {
                p = parse_str(p, t.text, sizeof t.text);
            } else if (strcmp(key, "done") == 0) {
                t.done = (strncmp(p, "true", 4) == 0);
                while (*p && *p != ',' && *p != '}') p++;
            } else if (strcmp(key, "created") == 0) {
                p = parse_str(p, t.created, sizeof t.created);
            } else {
                // skip unknown value
                while (*p && *p != ',' && *p != '}') p++;
            }
        }
        if (*p == '}') p++;
        g_tasks[g_count++] = t;
    }
    free(buf);
}

// Save tasks to todo.json  (mirrors Save-Tasks / jq emission in shell version)
static void save_tasks(void) {
    FILE *f = fopen(g_todo_file, "w");
    if (!f) { fos_err("Cannot write todo file."); return; }

    if (g_count == 0) { fputs("[]", f); fclose(f); return; }

    fputs("[\n", f);
    for (int i = 0; i < g_count; i++) {
        fprintf(f, "  {\"id\":%d,\"text\":\"%s\",\"done\":%s,\"created\":\"%s\"}%s\n",
            g_tasks[i].id,
            g_tasks[i].text,
            g_tasks[i].done ? "true" : "false",
            g_tasks[i].created,
            (i < g_count - 1) ? "," : "");
    }
    fputs("]\n", f);
    fclose(f);
}

static int next_id(void) {
    int max = 0;
    for (int i = 0; i < g_count; i++)
        if (g_tasks[i].id > max) max = g_tasks[i].id;
    return max + 1;
}

static void timestamp(char *buf, size_t len) {
    time_t now = time(NULL);
    strftime(buf, len, "%Y-%m-%dT%H:%M:%SZ", gmtime(&now));
}

// ─────────────────────────────────────────────────────────────────────────
//  Commands  — 1:1 with cmd_* in flower-todo.sh
// ─────────────────────────────────────────────────────────────────────────

static void cmd_add(int argc, char **argv) {
    if (argc == 0) { fos_err("Usage: flower-todo add <text>"); return; }

    // Join all remaining args as the task text
    char text[MAX_TEXT_LEN] = {0};
    for (int i = 0; i < argc; i++) {
        if (i > 0) strncat(text, " ", sizeof text - strlen(text) - 1);
        strncat(text, argv[i], sizeof text - strlen(text) - 1);
    }

    load_tasks();
    if (g_count >= MAX_TASKS) { fos_err("Task list full (max 256)."); return; }

    Task t;
    t.id   = next_id();
    t.done = 0;
    strncpy(t.text, text, MAX_TEXT_LEN - 1);
    t.text[MAX_TEXT_LEN - 1] = '\0';
    timestamp(t.created, sizeof t.created);

    g_tasks[g_count++] = t;
    save_tasks();

    printf(FOS_GRN "✓" FOS_RST " Added #%d: " FOS_ACC "%s" FOS_RST "\n", t.id, t.text);
}

static void cmd_list(void) {
    load_tasks();
    if (g_count == 0) {
        printf("\n  " FOS_DIM "🌸 No tasks yet. Add one with:" FOS_RST
               " " FOS_YLW "flower-todo add <task>" FOS_RST "\n\n");
        return;
    }
    printf("\n  " FOS_PNK "🌸 FlowerOS To-Do" FOS_RST
           "  " FOS_DIM "(%d tasks)" FOS_RST "\n", g_count);
    printf("  " FOS_DIM "─────────────────────────────────────" FOS_RST "\n");
    for (int i = 0; i < g_count; i++) {
        if (g_tasks[i].done) {
            printf("  " FOS_DIM " ✔  #%-3d %s" FOS_RST "\n",
                g_tasks[i].id, g_tasks[i].text);
        } else {
            printf("  " FOS_GRN " ○" FOS_RST "  " FOS_ACC "#%-3d" FOS_RST " %s\n",
                g_tasks[i].id, g_tasks[i].text);
        }
    }
    printf("  " FOS_DIM "─────────────────────────────────────" FOS_RST "\n\n");
}

static void cmd_done(int id) {
    load_tasks();
    int found = 0;
    for (int i = 0; i < g_count; i++) {
        if (g_tasks[i].id == id) { g_tasks[i].done = 1; found = 1; }
    }
    if (!found) { fos_err("Task not found."); return; }
    save_tasks();
    printf(FOS_GRN "✔" FOS_RST " Task #%d marked done.\n", id);
}

static void cmd_undo(int id) {
    load_tasks();
    int found = 0;
    for (int i = 0; i < g_count; i++) {
        if (g_tasks[i].id == id) { g_tasks[i].done = 0; found = 1; }
    }
    if (!found) { fos_err("Task not found."); return; }
    save_tasks();
    printf(FOS_YLW "○" FOS_RST " Task #%d reopened.\n", id);
}

static void cmd_remove(int id) {
    load_tasks();
    int found = 0;
    int new_count = 0;
    for (int i = 0; i < g_count; i++) {
        if (g_tasks[i].id == id) { found = 1; continue; }
        g_tasks[new_count++] = g_tasks[i];
    }
    if (!found) { fos_err("Task not found."); return; }
    g_count = new_count;
    save_tasks();
    printf(FOS_RED "✗" FOS_RST " Task #%d removed.\n", id);
}

static void cmd_clear(void) {
    g_count = 0;
    save_tasks();
    fos_ok("All tasks cleared.");
}

static void cmd_help(void) {
    printf("\n  " FOS_PNK "🌸 flower-todo" FOS_RST " — FlowerOS To-Do Notepad\n");
    printf("  " FOS_DIM "─────────────────────────────────────\n" FOS_RST);
    printf("  " FOS_ACC "add" FOS_RST "  <text>   Add a new task\n");
    printf("  " FOS_ACC "list" FOS_RST "          Show all tasks\n");
    printf("  " FOS_ACC "done" FOS_RST " <id>     Mark complete\n");
    printf("  " FOS_ACC "undo" FOS_RST " <id>     Reopen a task\n");
    printf("  " FOS_ACC "rm" FOS_RST "   <id>     Remove a task\n");
    printf("  " FOS_ACC "clear" FOS_RST "         Remove all tasks\n");
    printf("  " FOS_ACC "help" FOS_RST "          This message\n");
    printf("  " FOS_DIM "─────────────────────────────────────\n" FOS_RST);
    printf("  Data: " FOS_DIM "%s" FOS_RST "\n\n", g_todo_file);
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    // Resolve data path (same as shell version: ~/.config/floweros/todo.json)
    char cfg_dir[FOS_MAX_PATH];
    fos_home_path(cfg_dir, sizeof cfg_dir, ".config/floweros");
    fos_dir_ensure(cfg_dir);
    snprintf(g_todo_file, sizeof g_todo_file, "%s/todo.json", cfg_dir);

    // Seed file if absent
    if (!fos_file_exists(g_todo_file)) {
        FILE *f = fopen(g_todo_file, "w");
        if (f) { fputs("[]", f); fclose(f); }
    }

    const char *cmd = (argc > 1) ? argv[1] : "list";

    if (strcmp(cmd, "add")  == 0) { cmd_add(argc - 2, argv + 2); return 0; }
    if (strcmp(cmd, "list") == 0 || strcmp(cmd, "ls") == 0) { cmd_list(); return 0; }
    if (strcmp(cmd, "done") == 0) {
        if (argc < 3) { fos_err("Usage: flower-todo done <id>"); return 1; }
        cmd_done(atoi(argv[2])); return 0;
    }
    if (strcmp(cmd, "undo") == 0) {
        if (argc < 3) { fos_err("Usage: flower-todo undo <id>"); return 1; }
        cmd_undo(atoi(argv[2])); return 0;
    }
    if (strcmp(cmd, "rm") == 0 || strcmp(cmd, "remove") == 0 || strcmp(cmd, "del") == 0) {
        if (argc < 3) { fos_err("Usage: flower-todo rm <id>"); return 1; }
        cmd_remove(atoi(argv[2])); return 0;
    }
    if (strcmp(cmd, "clear") == 0) { cmd_clear(); return 0; }
    if (strcmp(cmd, "help")  == 0 || strcmp(cmd, "-h") == 0) { cmd_help(); return 0; }

    fprintf(stderr, FOS_RED "  ✗" FOS_RST " Unknown command: %s\n", cmd);
    cmd_help();
    return 1;
}
