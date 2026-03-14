// ═══════════════════════════════════════════════════════════════════════════
//  colony_engine.c  —  FlowerOS Colony  (src/games/colony_engine.c)
//
//  Colony-building survival strategy on a 19-hex island.
//  Backend matches backend_model.tex exactly:
//    Map: hex graph with terrain, resources, adjacency  (§1)
//    Resources: Food, Wood, Stone, Ore, Fiber           (§2)
//    Production: cadence-based deterministic pay         (§3, §9)
//    Settlers: skill vector + fatigue model              (§5)
//    Turn loop: env → produce → consume → train → act   (§7)
//
//  Build:  gcc -O2 -std=c11 -Wall -Wextra -o flower-colony colony_engine.c
//  Usage:  flower-colony [--mode num|sym] [--seed N]
//
//  Shell twin: games/colony.sh
// ═══════════════════════════════════════════════════════════════════════════

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>

// ─── FlowerOS pastel palette ─────────────────────────────────────────────

#define CR "\033[0m"
#define CB "\033[1m"
#define CD "\033[38;5;245m"
#define CG "\033[38;5;120m"
#define CY "\033[38;5;229m"
#define CM "\033[38;5;183m"
#define CC "\033[38;5;117m"
#define CO "\033[38;5;69m"     // ocean blue
#define CF "\033[38;5;34m"     // forest dark green
#define CH "\033[38;5;229m"    // hill yellow
#define CK "\033[38;5;210m"    // red / danger
#define CW "\033[38;5;159m"    // coast / water cyan

// ─── Constants ───────────────────────────────────────────────────────────

#define NUM_HEX       19
#define MAX_SETTLERS   8
#define MAX_BUILDINGS 16
#define NRES           5

// Resource indices (match R(t) vector in backend_model.tex §2)
enum { RI_FOOD, RI_WOOD, RI_STONE, RI_ORE, RI_FIBER };
static const char *RES_NAME[] = {"Food","Wood","Stone","Ore","Fiber"};
static const char *RES_SHORT[] = {"Fd","Wd","St","Or","Fb"};

// Terrain
enum { T_OCEAN, T_COAST, T_PLAINS, T_FOREST, T_HILL, T_MOUNTAIN, T_RIVER };
static const char *TER_ABR[] = {"~~~","Cst","Pln","For","Hil","Mtn","Rvr"};
static const char *TER_CLR[] = {
    "\033[38;5;69m", "\033[38;5;159m", "\033[38;5;120m",
    "\033[38;5;34m", "\033[38;5;229m", "\033[38;5;245m", "\033[38;5;75m"
};

// Building types
enum { B_CAMP, B_FARM, B_LUMBER, B_QUARRY, B_MINE,
       B_DOCK, B_WORKSHOP, B_SHELTER, NUM_BTYPE };
static const char *BLD_NAME[] = {
    "Camp","Farm","Lumber","Quarry","Mine","Dock","Workshop","Shelter"
};
//                          Fd  Wd  St  Or  Fb
static const int BLD_COST[NUM_BTYPE][NRES] = {
    { 0, 0, 0, 0, 0},  // camp (free)
    { 0, 2, 0, 0, 0},  // farm
    { 0, 3, 0, 0, 0},  // lumber
    { 0, 2, 2, 0, 0},  // quarry
    { 0, 3, 3, 0, 0},  // mine
    { 0, 5, 0, 0, 2},  // dock
    { 0, 3, 2, 1, 0},  // workshop
    { 0, 4, 2, 0, 0},  // shelter
};
// Production per cadence tick (resource index, amount)
static const int BLD_PROD_RES[NUM_BTYPE] = {
    RI_FOOD, RI_FOOD, RI_WOOD, RI_STONE, RI_ORE, RI_FOOD, -1, -1
};
static const int BLD_PROD_AMT[NUM_BTYPE] = {
    1, 3, 3, 2, 2, 2, 0, 0
};

// Settler tasks
enum { TASK_IDLE, TASK_FARM, TASK_LOG, TASK_MINE, NUM_TASKS };
static const char *TASK_NAME[] = {"idle","farm","log","mine"};

// Skills (match S(t) in backend_model.tex §5)
enum { SK_BUILD, SK_FARM, SK_LOG, SK_MINE, SK_COMBAT, SK_SAIL, NUM_SKILLS };

// ─── Types ───────────────────────────────────────────────────────────────

typedef struct {
    int terrain, resource, base_yield;
    int owner, visible;
    int nbr[6];
    int token;     // cadence class 2-12
    int next_pay;  // next payout turn
} Hex;

typedef struct {
    int skills[NUM_SKILLS];
    int task, fatigue, health;
    char name[12];
} Settler;

typedef struct {
    int type, active;
} Building;

typedef struct {
    Hex       hex[NUM_HEX];
    int       res[NRES];
    int       delta[NRES];    // last turn change
    Building  bld[MAX_BUILDINGS];
    int       nbld;
    Settler   set[MAX_SETTLERS];
    int       nset, max_pop;
    int       colony;         // colony hex id
    int       turn;
    unsigned  seed;
    int       workshop;       // workshop efficiency bonus count
    int       alive;
} Game;

typedef enum { MODE_SYM, MODE_NUM } DMode;

// ─── Hex layout: 19-hex Catan grid, rows 3-4-5-4-3 ──────────────────────

static const int ROW_W[]   = {3, 4, 5, 4, 3};
static const int ROW_OFF[] = {0, 3, 7, 12, 16};
#define NROWS 5

static void hex_rc(int id, int *r, int *c) {
    for (int i = 0; i < NROWS; i++)
        if (id >= ROW_OFF[i] && id < ROW_OFF[i] + ROW_W[i])
            { *r = i; *c = id - ROW_OFF[i]; return; }
    *r = *c = -1;
}
static int hex_id(int r, int c) {
    if (r < 0 || r >= NROWS || c < 0 || c >= ROW_W[r]) return -1;
    return ROW_OFF[r] + c;
}

// Physical x-position (scaled ×2 to stay integer)
static int hex_x2(int id) {
    int r, c; hex_rc(id, &r, &c);
    return (5 - ROW_W[r]) + 2 * c;
}

static void compute_adj(Hex h[]) {
    for (int i = 0; i < NUM_HEX; i++) {
        int ni = 0, r1, c1; hex_rc(i, &r1, &c1);
        int x1 = hex_x2(i);
        // same-row neighbors
        int l = hex_id(r1, c1-1); if (l >= 0) h[i].nbr[ni++] = l;
        int ri2 = hex_id(r1, c1+1); if (ri2 >= 0) h[i].nbr[ni++] = ri2;
        // adjacent rows
        for (int dr = -1; dr <= 1; dr += 2) {
            int r2 = r1 + dr;
            if (r2 < 0 || r2 >= NROWS) continue;
            for (int c2 = 0; c2 < ROW_W[r2]; c2++) {
                int j = hex_id(r2, c2);
                if (abs(x1 - hex_x2(j)) <= 1) h[i].nbr[ni++] = j;
            }
        }
        while (ni < 6) h[i].nbr[ni++] = -1;
    }
}

// ─── Deterministic jitter (backend_model.tex §9) ─────────────────────────
// Hash-based — matches the scheduled-next-pay method (§9.4.B).
// Full trig-polynomial upgrade (§9.3) is a drop-in replacement.

static int det_jitter(unsigned seed, int hex, int turn, int amp) {
    unsigned h = seed ^ ((unsigned)hex * 2654435761u) ^ ((unsigned)turn * 40503u);
    h ^= h >> 16; h *= 0x45d9f3bu; h ^= h >> 16;
    int v = (int)(h & 0xFFFF) - 32768;
    return (v * amp) / 32768;
}

// Token → base interval (turns between payouts) — §9.2
static int token_interval(int tok) {
    static const int W[] = {0,0,1,2,3,4,5,0,5,4,3,2,1};
    int w = (tok >= 2 && tok <= 12) ? W[tok] : 0;
    if (w == 0) return 99;
    return 8 - (w * 6 + 2) / 5;  // k_min=2, k_max=8
}

static void schedule_pay(Hex *h, unsigned seed, int turn) {
    int k = token_interval(h->token);
    int j = det_jitter(seed, (int)(h - (Hex *)0), turn, 2); // [-2,+2]
    int d = k + j; if (d < 1) d = 1;
    h->next_pay = turn + d;
}

// ─── Island template ─────────────────────────────────────────────────────

static const int TER_T[19] = {
    T_OCEAN, T_COAST, T_OCEAN,
    T_COAST, T_FOREST, T_HILL, T_COAST,
    T_OCEAN, T_PLAINS, T_PLAINS, T_FOREST, T_OCEAN,
    T_COAST, T_MOUNTAIN, T_RIVER, T_COAST,
    T_OCEAN, T_COAST, T_OCEAN
};
static const int RES_T[19] = {
    -1, RI_FOOD, -1,
    RI_FOOD, RI_WOOD, RI_STONE, RI_FIBER,
    -1, RI_FOOD, -1, RI_WOOD, -1,
    RI_FIBER, RI_ORE, RI_FOOD, RI_WOOD,
    -1, RI_STONE, -1
};
static const int YLD_T[19] = {
    0,2,0,  2,3,2,2,  0,3,0,3,0,  2,2,2,2,  0,2,0
};
static const int TOK_T[19] = {
    0,8,0,  6,5,9,11,  0,4,0,6,0,  10,3,8,5,  0,12,0
};

// ─── Init ────────────────────────────────────────────────────────────────

static void init_game(Game *g, unsigned seed) {
    memset(g, 0, sizeof *g);
    g->seed = seed; g->turn = 1; g->alive = 1;
    g->colony = 1;  // coast hex, top-center
    g->max_pop = 3;

    for (int i = 0; i < NUM_HEX; i++) {
        Hex *h = &g->hex[i];
        h->terrain = TER_T[i]; h->resource = RES_T[i];
        h->base_yield = YLD_T[i]; h->owner = -1;
        h->visible = 1; h->token = TOK_T[i];
        h->next_pay = token_interval(h->token) + 1;
    }
    g->hex[g->colony].owner = 0;
    compute_adj(g->hex);

    // Starting resources: R(0) = [10, 8, 3, 0, 2]
    g->res[RI_FOOD] = 10; g->res[RI_WOOD] = 8;
    g->res[RI_STONE] = 3; g->res[RI_FIBER] = 2;

    // Camp (free building)
    g->bld[0].type = B_CAMP; g->bld[0].active = 1; g->nbld = 1;

    // Two starting settlers
    static const char *names[] = {"Ada","Ben","Cal","Dee","Eve","Fin","Gus","Hel"};
    g->nset = 2;
    for (int i = 0; i < g->nset; i++) {
        Settler *s = &g->set[i];
        s->health = 100; s->fatigue = 0; s->task = TASK_IDLE;
        for (int j = 0; j < NUM_SKILLS; j++) s->skills[j] = 5;
        strncpy(s->name, names[i], sizeof s->name - 1);
    }
}

// ─── Turn processing (game loop pipeline — §7) ──────────────────────────

static void tick_turn(Game *g) {
    memset(g->delta, 0, sizeof g->delta);

    // 1. Camp base yield: +1 Food, +1 Wood (always)
    g->delta[RI_FOOD] += 1; g->delta[RI_WOOD] += 1;

    // 2. Building production (cadence ticks)
    int eff = 1 + g->workshop;  // workshop bonus
    for (int i = 0; i < g->nbld; i++) {
        Building *b = &g->bld[i];
        if (!b->active) continue;
        int bt = b->type;
        if (bt == B_CAMP) continue;  // camp handled above
        int ri = BLD_PROD_RES[bt];
        if (ri < 0) continue;
        // Check cadence: does the colony hex pay this turn?
        Hex *h = &g->hex[g->colony];
        if (g->turn >= h->next_pay) {
            g->delta[ri] += BLD_PROD_AMT[bt] * eff;
        }
    }
    // Reschedule cadence if it fired
    {
        Hex *h = &g->hex[g->colony];
        if (g->turn >= h->next_pay)
            schedule_pay(h, g->seed, g->turn);
    }

    // 3. Dock fishing bonus
    for (int i = 0; i < g->nbld; i++)
        if (g->bld[i].active && g->bld[i].type == B_DOCK)
            g->delta[RI_FOOD] += 2;

    // 4. Consumption: 2 food per settler per turn
    g->delta[RI_FOOD] -= 2 * g->nset;

    // 5. Apply deltas
    for (int i = 0; i < NRES; i++) g->res[i] += g->delta[i];

    // 6. Starvation check
    if (g->res[RI_FOOD] < 0) {
        g->res[RI_FOOD] = 0;
        for (int i = 0; i < g->nset; i++) {
            g->set[i].health -= 15;
            if (g->set[i].health <= 0) {
                printf(CK "  ✗ %s has perished from starvation!" CR "\n", g->set[i].name);
                // Remove settler (shift array)
                for (int j = i; j < g->nset - 1; j++) g->set[j] = g->set[j+1];
                g->nset--; i--;
            }
        }
        if (g->nset <= 0) {
            printf(CK CB "\n  ══ COLONY LOST ══  All settlers have perished on turn %d.\n" CR, g->turn);
            g->alive = 0; return;
        }
    }

    // 7. Settler training (§5): S_j(t+1) = S_j(t) + α·exposure - β·fatigue
    for (int i = 0; i < g->nset; i++) {
        Settler *s = &g->set[i];
        int sk = -1;
        switch (s->task) {
            case TASK_FARM: sk = SK_FARM; break;
            case TASK_LOG:  sk = SK_LOG;  break;
            case TASK_MINE: sk = SK_MINE; break;
        }
        if (sk >= 0 && s->skills[sk] < 100) s->skills[sk] += 2;
        // Fatigue
        if (s->task != TASK_IDLE) {
            s->fatigue += 5;
            if (s->fatigue > 80) s->health -= 3;
        } else {
            if (s->fatigue > 0) s->fatigue -= 10;
            if (s->fatigue < 0) s->fatigue = 0;
            if (s->health < 100) s->health += 5;
            if (s->health > 100) s->health = 100;
        }
    }

    // 8. Events (deterministic — §9)
    int ev = det_jitter(g->seed, 99, g->turn, 20);
    if (ev > 16) {
        printf(CY "  ⚡ Storm! Lost 2 Wood and 1 Food." CR "\n");
        g->res[RI_WOOD] -= 2; if (g->res[RI_WOOD] < 0) g->res[RI_WOOD] = 0;
        g->res[RI_FOOD] -= 1; if (g->res[RI_FOOD] < 0) g->res[RI_FOOD] = 0;
    } else if (ev < -16) {
        printf(CG "  ✿ Good harvest! Bonus +3 Food." CR "\n");
        g->res[RI_FOOD] += 3;
    }

    g->turn++;
}

// ─── Display ─────────────────────────────────────────────────────────────

static void display_map(const Game *g) {
    static const int INDENT[] = {9, 6, 3, 6, 9};
    printf("\n");
    for (int r = 0; r < NROWS; r++) {
        printf("%*s", INDENT[r], "");
        for (int c = 0; c < ROW_W[r]; c++) {
            int id = hex_id(r, c);
            const Hex *h = &g->hex[id];
            int is_col = (id == g->colony);
            const char *clr = TER_CLR[h->terrain];

            if (is_col) printf(CM CB);
            else printf("%s", clr);

            if (h->terrain == T_OCEAN)
                printf(" ~~~  ");
            else if (is_col)
                printf("[%s]\xe2\x98\xba", TER_ABR[h->terrain]);
            else
                printf(" %s  ", TER_ABR[h->terrain]);
            printf(CR);
        }
        printf("\n");

        // Resource / population line
        printf("%*s", INDENT[r], "");
        for (int c = 0; c < ROW_W[r]; c++) {
            int id = hex_id(r, c);
            const Hex *h = &g->hex[id];
            if (id == g->colony)
                printf(CM " pop:" CB "%d" CR " ", g->nset);
            else if (h->terrain == T_OCEAN || h->resource < 0)
                printf("      ");
            else
                printf(CD " %s:%d " CR, RES_SHORT[h->resource], h->base_yield);
        }
        printf("\n");
    }
}

static void display_resources(const Game *g) {
    printf(CD "  ─── Resources ────────────────────────────" CR "\n  ");
    for (int i = 0; i < NRES; i++) {
        int d = g->delta[i];
        if (d > 0) printf(CG "%-6s" CR "%-3d" CG "(+%d) " CR, RES_NAME[i], g->res[i], d);
        else if (d < 0) printf(CK "%-6s" CR "%-3d" CK "(%d) " CR, RES_NAME[i], g->res[i], d);
        else printf(CD "%-6s" CR "%-5d", RES_NAME[i], g->res[i]);
    }
    printf("\n");
}

static void display_buildings(const Game *g) {
    printf(CD "  ─── Buildings ────────────────────────────" CR "\n  ");
    for (int i = 0; i < g->nbld; i++) {
        if (!g->bld[i].active) continue;
        if (i > 0) printf(CD " · " CR);
        printf(CC "%s" CR, BLD_NAME[g->bld[i].type]);
    }
    printf("\n");
}

static void display_settlers(const Game *g) {
    printf(CD "  \xe2\x94\x80\xe2\x94\x80\xe2\x94\x80 Population " CM CB "%d" CR CD "/%d \xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80" CR "\n", g->nset, g->max_pop);
    for (int i = 0; i < g->nset; i++) {
        const Settler *s = &g->set[i];
        const char *hc = (s->health > 60) ? CG : (s->health > 30) ? CY : CK;
        printf("  " CC "\xe2\x98\xba%d" CR " task:" CY "%-5s" CR " hp:%s%d" CR " fat:%d",
               i+1, TASK_NAME[s->task], hc, s->health, s->fatigue);
        int bsk = 0;
        for (int j = 1; j < NUM_SKILLS; j++) if (s->skills[j] > s->skills[bsk]) bsk = j;
        static const char *sk_names[] = {"bld","frm","log","min","cmb","sal"};
        printf(CD " %s:%d" CR "\n", sk_names[bsk], s->skills[bsk]);
    }
}

static void display_sym(const Game *g) {
    printf(CM CB
        "\n  ═══════════════════════════════════════════\n"
        "    ✿  FlowerOS Colony  ·  Turn %-3d ·  Pop %d/%d\n"
        "  ═══════════════════════════════════════════\n" CR,
        g->turn, g->nset, g->max_pop);
    display_map(g);
    display_resources(g);
    display_buildings(g);
    display_settlers(g);
    printf("\n");
}

static void display_num(const Game *g) {
    printf(CD "Turn: " CR "%d  " CD "Pop: " CR "%d/%d  " CD "Colony hex: " CR "%d\n",
           g->turn, g->nset, g->max_pop, g->colony);
    printf(CD "R(t)=" CR "[");
    for (int i = 0; i < NRES; i++) printf("%s%d", i?",":"", g->res[i]);
    printf("]  " CD "ΔR=" CR "[");
    for (int i = 0; i < NRES; i++) printf("%s%+d", i?",":"", g->delta[i]);
    printf("]\n");
    printf(CD "Buildings:" CR);
    for (int i = 0; i < g->nbld; i++)
        if (g->bld[i].active) printf(" %s", BLD_NAME[g->bld[i].type]);
    printf("\n");
    for (int i = 0; i < g->nset; i++) {
        const Settler *s = &g->set[i];
        printf(CD "Settler %d:" CR " %s task=%s hp=%d fat=%d S=[",
               i+1, s->name, TASK_NAME[s->task], s->health, s->fatigue);
        for (int j = 0; j < NUM_SKILLS; j++) printf("%s%d", j?",":"", s->skills[j]);
        printf("]\n");
    }
    printf("\n");
}

// ─── Commands ────────────────────────────────────────────────────────────

static int has_building(const Game *g, int type) {
    for (int i = 0; i < g->nbld; i++)
        if (g->bld[i].active && g->bld[i].type == type) return 1;
    return 0;
}

static void cmd_build(Game *g, const char *arg) {
    int bt = -1;
    for (int i = 0; i < NUM_BTYPE; i++)
        if (strcasecmp(arg, BLD_NAME[i]) == 0) { bt = i; break; }
    if (bt < 0) { printf(CK "  Unknown building. Try: farm lumber quarry mine dock workshop shelter" CR "\n"); return; }
    if (has_building(g, bt)) { printf(CK "  Already built %s." CR "\n", BLD_NAME[bt]); return; }
    if (g->nbld >= MAX_BUILDINGS) { printf(CK "  Building limit reached." CR "\n"); return; }
    // Check cost
    for (int i = 0; i < NRES; i++) {
        if (g->res[i] < BLD_COST[bt][i]) {
            printf(CK "  Not enough %s (need %d, have %d)." CR "\n",
                   RES_NAME[i], BLD_COST[bt][i], g->res[i]); return;
        }
    }
    for (int i = 0; i < NRES; i++) g->res[i] -= BLD_COST[bt][i];
    g->bld[g->nbld].type = bt; g->bld[g->nbld].active = 1; g->nbld++;
    if (bt == B_WORKSHOP) g->workshop++;
    if (bt == B_SHELTER) g->max_pop += 2;
    printf(CG "  ✓ Built %s!" CR "\n", BLD_NAME[bt]);
}

static void cmd_assign(Game *g, const char *arg) {
    int n = 0; char task[16] = {0};
    if (sscanf(arg, "%d %15s", &n, task) < 2 || n < 1 || n > g->nset) {
        printf(CK "  Usage: assign <N> idle|farm|log|mine" CR "\n"); return;
    }
    int ti = -1;
    for (int i = 0; i < NUM_TASKS; i++)
        if (strcasecmp(task, TASK_NAME[i]) == 0) { ti = i; break; }
    if (ti < 0) { printf(CK "  Unknown task. Try: idle farm log mine" CR "\n"); return; }
    // Check if relevant building exists
    if (ti == TASK_FARM && !has_building(g, B_FARM))
        { printf(CK "  Build a Farm first." CR "\n"); return; }
    if (ti == TASK_LOG && !has_building(g, B_LUMBER))
        { printf(CK "  Build Lumber first." CR "\n"); return; }
    if (ti == TASK_MINE && !has_building(g, B_MINE))
        { printf(CK "  Build a Mine first." CR "\n"); return; }
    g->set[n-1].task = ti;
    printf(CG "  ✓ %s assigned to %s." CR "\n", g->set[n-1].name, TASK_NAME[ti]);
}

static void cmd_recruit(Game *g) {
    if (g->nset >= g->max_pop) {
        printf(CK "  Population cap (%d). Build Shelter for +2." CR "\n", g->max_pop); return;
    }
    if (g->nset >= MAX_SETTLERS) { printf(CK "  Max settlers reached." CR "\n"); return; }
    if (g->res[RI_FOOD] < 5) { printf(CK "  Need 5 Food to recruit." CR "\n"); return; }
    g->res[RI_FOOD] -= 5;
    static const char *names[] = {"Ada","Ben","Cal","Dee","Eve","Fin","Gus","Hel"};
    Settler *s = &g->set[g->nset];
    memset(s, 0, sizeof *s);
    s->health = 100; s->task = TASK_IDLE;
    for (int j = 0; j < NUM_SKILLS; j++) s->skills[j] = 3;
    strncpy(s->name, names[g->nset % 8], sizeof s->name - 1);
    g->nset++;
    printf(CG "  ✓ Recruited %s!" CR "\n", s->name);
}

static void cmd_help(void) {
    printf("\n" CD "  ─── Commands ────────────────────────────────────" CR "\n"
        "  " CY "build" CR " <type>      Build: " CC "farm lumber quarry mine dock workshop shelter" CR "\n"
        "  " CY "assign" CR " <N> <job>  Assign settler: " CC "idle farm log mine" CR "\n"
        "  " CY "recruit" CR "          New settler (cost 5 Food)\n"
        "  " CY "status" CR "           Detailed status\n"
        "  " CY "end" CR "              End turn  →  produce / consume / train\n"
        "  " CY "quit" CR "             Exit game\n"
        "  " CY "help" CR "             This screen\n\n");
}

// ─── Game loop ───────────────────────────────────────────────────────────

static void run_game(DMode mode, unsigned seed) {
    Game g; init_game(&g, seed);

    printf(CM CB
        "\n  ════════════════════════════════════════════════════════\n"
        "    ⚓  Your ship has landed on an uncharted island.\n"
        "    🏕  A small camp is established on the coast.\n"
        "    🌾  Survive.  Build.  Explore.\n"
        "  ════════════════════════════════════════════════════════\n" CR "\n");

    if (mode == MODE_SYM) display_sym(&g); else display_num(&g);
    cmd_help();

    char line[128];
    while (g.alive) {
        printf(CC "  turn %d > " CR, g.turn);
        fflush(stdout);
        if (!fgets(line, sizeof line, stdin)) break;
        line[strcspn(line, "\r\n")] = 0;

        // Trim leading spaces
        char *cmd = line;
        while (*cmd == ' ') cmd++;
        if (!*cmd) continue;

        if (strcasecmp(cmd, "quit") == 0 || strcasecmp(cmd, "q") == 0) break;
        else if (strcasecmp(cmd, "help") == 0 || strcasecmp(cmd, "h") == 0) cmd_help();
        else if (strcasecmp(cmd, "end") == 0 || strcasecmp(cmd, "e") == 0) {
            tick_turn(&g);
            if (mode == MODE_SYM) display_sym(&g); else display_num(&g);
        }
        else if (strcasecmp(cmd, "status") == 0 || strcasecmp(cmd, "s") == 0) {
            if (mode == MODE_SYM) display_sym(&g);
            display_num(&g);
        }
        else if (strcasecmp(cmd, "recruit") == 0 || strcasecmp(cmd, "r") == 0)
            cmd_recruit(&g);
        else if (strncasecmp(cmd, "build ", 6) == 0) cmd_build(&g, cmd + 6);
        else if (strncasecmp(cmd, "assign ", 7) == 0) cmd_assign(&g, cmd + 7);
        else printf(CD "  Unknown command. Type 'help'." CR "\n");
    }

    printf(CD "\n  Colony survived %d turns.  Final resources: [", g.turn);
    for (int i = 0; i < NRES; i++) printf("%s%d", i?",":"", g.res[i]);
    printf("]\n" CR "\n");
}

// ─── Help / main ─────────────────────────────────────────────────────────

static void print_help(void) {
    printf("\n" CC "  flower-colony" CR " — FlowerOS colony-building survival game\n\n"
        CD "  Usage:" CR "  flower-colony [OPTIONS]\n\n"
        "  " CY "--mode num" CR "    Numerical: state vectors + formulas\n"
        "  " CY "--mode sym" CR "    Symbolic:  pastel hex map (default)\n"
        "  " CY "--seed N" CR "      Deterministic seed (default: 42)\n"
        "  " CY "--help" CR "        This message\n\n"
        CD "  Based on backend_model.tex — deterministic cadence, settler skills, hex graph." CR "\n\n");
}

int main(int argc, char **argv) {
    DMode mode = MODE_SYM;
    unsigned seed = 42;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { print_help(); return 0; }
        if (!strcmp(argv[i], "--mode") && i+1 < argc) {
            i++;
            if (!strcmp(argv[i], "num")) mode = MODE_NUM;
        }
        if (!strcmp(argv[i], "--seed") && i+1 < argc) seed = (unsigned)atoi(argv[++i]);
    }

    run_game(mode, seed);
    return 0;
}
