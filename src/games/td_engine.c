// ═══════════════════════════════════════════════════════════════════════════
//  td_engine.c  —  FlowerOS Tower Defense v2  (src/games/td_engine.c)
//
//  PvZ-style lane combat.  Flower towers shoot rightward at creeps
//  marching toward your garden gate.  Visible projectiles, scaling
//  difficulty, mana that grows with each stage.
//
//  Build:  gcc -O2 -std=c11 -Wall -Wextra -o flower-td td_engine.c
//  Usage:  flower-td [--seed N]
//
//  Shell twin: games/td.sh
// ═══════════════════════════════════════════════════════════════════════════

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

// ─── Palette ─────────────────────────────────────────────────────────────

#define CR  "\033[0m"
#define CB  "\033[1m"
#define CD  "\033[38;5;245m"
#define CG  "\033[38;5;120m"
#define CY  "\033[38;5;229m"
#define CM  "\033[38;5;183m"
#define CC  "\033[38;5;117m"
#define CK  "\033[38;5;210m"
#define CE  "\033[38;5;204m"
#define CP  "\033[38;5;222m"
#define CV  "\033[38;5;99m"
#define CF  "\033[38;5;108m"
#define CDK "\033[48;5;235m"

// ─── Constants ───────────────────────────────────────────────────────────

#define LANES       7
#define COLS       30
#define MAX_TOWER  40
#define MAX_ENEMY  80
#define MAX_PROJ  120
#define NUM_WAVES  20
#define TICK_MS   140

// Tower types
enum { TW_DAISY, TW_ROSE, TW_SUNFLOWER, TW_CACTUS, TW_THORN, NUM_TW };
static const struct {
    const char *name;
    int cost, dmg, cd;
    int proj_spd, pierce;
    char icon, proj;
    const char *clr;
} TWDEF[NUM_TW] = {
    {"Daisy",     10,  3, 3,  2, 0, 'D', '*', "\033[38;5;120m"},
    {"Rose",      25,  7, 4,  1, 0, 'R', '~', "\033[38;5;210m"},
    {"Sunflower", 15,  0, 0,  0, 0, 'S', ' ', "\033[38;5;229m"},
    {"Cactus",    40, 10, 6,  1, 1, 'C', '#', "\033[38;5;117m"},
    {"Thorn",     20,  2, 2,  3, 0, 'T', '+', "\033[38;5;108m"},
};

// Enemy types
enum { EN_WEED, EN_SLUG, EN_MOTH, EN_FUNGUS, EN_LOCUST, EN_TUMBLE, EN_VINE, EN_HYDRA, NUM_EN };
static const struct {
    const char *name;
    int hp, spd, reward;
    char icon;
    const char *clr;
} ENDEF[NUM_EN] = {
    {"Weed",       8,  1,  3, 'w', "\033[38;5;148m"},
    {"Slug",      18,  1,  5, 's', "\033[38;5;139m"},
    {"Moth",       6,  2,  4, 'm', "\033[38;5;183m"},
    {"Fungus",    14,  1,  6, 'f', "\033[38;5;101m"},
    {"Locust",     5,  3,  4, 'L', "\033[38;5;214m"},
    {"Tumbleweed",22,  2,  7, 'W', "\033[38;5;180m"},
    {"Vine Boss", 50,  1, 20, 'V', "\033[38;5;196m"},
    {"Root Hydra",80,  1, 35, 'H', "\033[38;5;160m"},
};

// Stage names (retro flavour text)
static const char *STAGE_NAME[NUM_WAVES] = {
    "Dandelion Drift",   "Garden Pests",     "Stubborn Roots",
    "Mixed Trouble",     "Moth Night",       "Creeping Green",
    "Fungal Fog",        "Locust Swarm",     "Frost & Slime",
    "Tumbleweed Alley",  "Thick Growth",     "Dark Garden",
    "Wings & Thorns",    "Full Lawn Rush",   "Overgrowth",
    "Plague Wind",       "Storm Front",      "Deep Roots",
    "The Vine Lord",     "Root Hydra Rises",
};

// ─── Types ───────────────────────────────────────────────────────────────

typedef struct { int type, lane, col, cd_left, kills; } Tower;
typedef struct { int type, hp, lane, col, alive; }       Enemy;
typedef struct { int lane, col, dmg, spd, pierce, alive; char icon; } Proj;

typedef struct {
    Tower tw[MAX_TOWER]; int ntw;
    Enemy en[MAX_ENEMY]; int nen;
    Proj  pj[MAX_PROJ];  int npj;
    int   petals, lives, wave, score;
    int   alive;
    unsigned seed;
} Game;

// ─── Deterministic rand ──────────────────────────────────────────────────

static int drand(unsigned seed, int idx, int mod) {
    unsigned h = seed ^ ((unsigned)idx * 2654435761u);
    h ^= h >> 16; h *= 0x45d9f3bu; h ^= h >> 16;
    return (int)(h % (unsigned)mod);
}

// ─── Sleep ───────────────────────────────────────────────────────────────

static void msleep(int ms) {
    struct timespec ts = {ms/1000, (ms%1000)*1000000L};
    nanosleep(&ts, NULL);
}

// ─── Wave generation ─────────────────────────────────────────────────────
//  Difficulty + mana both scale with stage number.
//  Each wave's composition is procedural: more types unlock as you go.

typedef struct {
    int counts[NUM_EN];
    int total, interval, nlanes;
    int bonus;
    int lanes[LANES];
} WaveSpec;

static void gen_wave(int w, unsigned seed, WaveSpec *ws) {
    memset(ws, 0, sizeof *ws);
    ws->total    = 5 + w * 2;  if (ws->total > 35) ws->total = 35;
    ws->interval = 5 - w / 5;  if (ws->interval < 2) ws->interval = 2;
    ws->nlanes   = 2 + w / 3;  if (ws->nlanes > LANES) ws->nlanes = LANES;
    ws->bonus    = 12 + w * 5;

    // Pick active lanes (deterministic spread from center out)
    static const int LO[] = {3, 2, 4, 1, 5, 0, 6};
    for (int i = 0; i < ws->nlanes; i++) ws->lanes[i] = LO[i];

    // Distribute enemy types based on stage
    int rem = ws->total;
    if (w >= 19) { ws->counts[EN_HYDRA]  = 1; rem -= 1; }
    if (w >= 18) { ws->counts[EN_VINE]   = 2; rem -= 2; }
    if (w >= 9 && rem > 0) { int n = rem/5; ws->counts[EN_TUMBLE] = n>0?n:1; rem -= ws->counts[EN_TUMBLE]; }
    if (w >= 7 && rem > 0) { int n = rem/4; ws->counts[EN_LOCUST] = n>0?n:1; rem -= ws->counts[EN_LOCUST]; }
    if (w >= 6 && rem > 0) { int n = rem/4; ws->counts[EN_FUNGUS] = n; rem -= n; }
    if (w >= 4 && rem > 0) { int n = rem/3; ws->counts[EN_MOTH]   = n; rem -= n; }
    if (w >= 2 && rem > 0) { int n = rem/3; ws->counts[EN_SLUG]   = n; rem -= n; }
    ws->counts[EN_WEED] += rem;

    (void)seed;
}

// ─── Display ─────────────────────────────────────────────────────────────

static void draw_header(const Game *g, const WaveSpec *ws) {
    printf("\033[1;1H");
    printf(CM CB
        "  \xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\n"
        "    \xe2\x9c\xbf FlowerOS TD  \xc2\xb7  "
        "Stage %d/%d  \xc2\xb7  \xe2\x99\xa5%d  \xc2\xb7  \xe2\x9a\x98%d\n"
        "  \xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
        "\xe2\x95\x90\n" CR,
        g->wave + 1, NUM_WAVES, g->lives, g->petals);
    (void)ws;
}

static void draw_map(const Game *g) {
    // Col header
    printf("\n  " CD "   ");
    for (int c = 0; c < COLS; c++) printf("%d ", c % 10);
    printf(CR "\n");

    // Top border
    printf("  " CM "\xe2\x95\x94");
    for (int c = 0; c < COLS * 2 + 1; c++) printf("\xe2\x95\x90");
    printf("\xe2\x95\x97" CR "\n");

    for (int lane = 0; lane < LANES; lane++) {
        printf("  " CM "\xe2\x95\x91" CR " ");
        for (int col = 0; col < COLS; col++) {
            // Priority: enemy > projectile > tower > empty
            int found = 0;

            // Enemy?
            for (int i = 0; i < g->nen && !found; i++) {
                const Enemy *e = &g->en[i];
                if (e->alive && e->lane == lane && e->col == col) {
                    // Color intensity by HP ratio
                    int pct = (e->hp * 100) / ENDEF[e->type].hp;
                    if (pct > 60) printf("%s" CB, ENDEF[e->type].clr);
                    else if (pct > 30) printf("%s", ENDEF[e->type].clr);
                    else printf(CK);
                    printf("%c" CR, ENDEF[e->type].icon);
                    found = 1;
                }
            }
            // Projectile?
            for (int i = 0; i < g->npj && !found; i++) {
                const Proj *p = &g->pj[i];
                if (p->alive && p->lane == lane && p->col == col) {
                    printf(CY CB "%c" CR, p->icon);
                    found = 1;
                }
            }
            // Tower?
            for (int i = 0; i < g->ntw && !found; i++) {
                const Tower *t = &g->tw[i];
                if (t->lane == lane && t->col == col) {
                    printf("%s%c" CR, TWDEF[t->type].clr, TWDEF[t->type].icon);
                    found = 1;
                }
            }
            if (!found) printf(CD "\xc2\xb7" CR);
            printf(" ");
        }
        printf(CM "\xe2\x95\x91" CR " " CD "%d" CR "\n", lane);
    }

    // Bottom border
    printf("  " CM "\xe2\x95\x9a");
    for (int c = 0; c < COLS * 2 + 1; c++) printf("\xe2\x95\x90");
    printf("\xe2\x95\x9d" CR "\n");
}

static void draw_tower_bar(void) {
    printf("  ");
    for (int i = 0; i < NUM_TW; i++) {
        printf("%s[%c]" CR CD "%s" CR ":%d  ",
               TWDEF[i].clr, TWDEF[i].icon, TWDEF[i].name, TWDEF[i].cost);
    }
    printf("\n");
}

static void draw_full(const Game *g, const WaveSpec *ws) {
    printf("\033[2J\033[1;1H");
    draw_header(g, ws);
    draw_map(g);
    draw_tower_bar();
}

// ─── Tower placement ─────────────────────────────────────────────────────

static int place_tower(Game *g, int lane, int col, int type) {
    if (lane < 0 || lane >= LANES || col < 0 || col >= COLS - 2) return -1;
    for (int i = 0; i < g->ntw; i++)
        if (g->tw[i].lane == lane && g->tw[i].col == col) return -3;
    if (g->petals < TWDEF[type].cost) return -4;
    if (g->ntw >= MAX_TOWER) return -5;
    g->petals -= TWDEF[type].cost;
    Tower *t = &g->tw[g->ntw++];
    t->type = type; t->lane = lane; t->col = col;
    t->cd_left = 0; t->kills = 0;
    return 0;
}

// ─── Projectile mechanics ────────────────────────────────────────────────

static void spawn_proj(Game *g, int lane, int col, int type) {
    if (g->npj >= MAX_PROJ) return;
    Proj *p = &g->pj[g->npj++];
    p->lane = lane; p->col = col + 1;
    p->dmg = TWDEF[type].dmg; p->spd = TWDEF[type].proj_spd;
    p->pierce = TWDEF[type].pierce; p->alive = 1;
    p->icon = TWDEF[type].proj;
}

static void move_projs(Game *g) {
    for (int i = 0; i < g->npj; i++) {
        Proj *p = &g->pj[i];
        if (!p->alive) continue;
        for (int step = 0; step < p->spd; step++) {
            p->col++;
            if (p->col >= COLS) { p->alive = 0; break; }
            // Collision with enemies
            for (int j = 0; j < g->nen; j++) {
                Enemy *e = &g->en[j];
                if (e->alive && e->lane == p->lane && e->col == p->col) {
                    e->hp -= p->dmg;
                    if (e->hp <= 0) {
                        e->alive = 0;
                        g->petals += ENDEF[e->type].reward;
                        g->score += ENDEF[e->type].reward;
                    }
                    if (!p->pierce) { p->alive = 0; break; }
                }
            }
            if (!p->alive) break;
        }
    }
    // Compact dead projectiles
    int w = 0;
    for (int i = 0; i < g->npj; i++)
        if (g->pj[i].alive) g->pj[w++] = g->pj[i];
    g->npj = w;
}

// ─── Tower firing ────────────────────────────────────────────────────────

static void towers_fire(Game *g) {
    for (int i = 0; i < g->ntw; i++) {
        Tower *t = &g->tw[i];
        if (TWDEF[t->type].dmg == 0) continue;  // sunflower
        if (t->cd_left > 0) { t->cd_left--; continue; }

        // Any enemy to the right in this lane?
        int has_target = 0;
        for (int j = 0; j < g->nen; j++) {
            const Enemy *e = &g->en[j];
            if (e->alive && e->lane == t->lane && e->col > t->col)
                { has_target = 1; break; }
        }
        if (has_target) {
            spawn_proj(g, t->lane, t->col, t->type);
            t->cd_left = TWDEF[t->type].cd;
        }
    }
}

// ─── Enemy mechanics ─────────────────────────────────────────────────────

static void enemies_move(Game *g) {
    for (int i = 0; i < g->nen; i++) {
        Enemy *e = &g->en[i];
        if (!e->alive) continue;
        e->col -= ENDEF[e->type].spd;
        if (e->col < 0) {
            e->alive = 0;
            g->lives--;
            if (g->lives <= 0) { g->alive = 0; return; }
        }
    }
}

static int enemies_alive(const Game *g) {
    for (int i = 0; i < g->nen; i++)
        if (g->en[i].alive) return 1;
    return 0;
}

// ─── Stage intro card ────────────────────────────────────────────────────

static const char *STAGE_QUOTE[NUM_WAVES] = {
    "A few weeds poke through...",
    "Something rustles in the hedge.",
    "Roots grip the soil tight.",
    "They're coming from all sides.",
    "Wings beat in the dark.",
    "Green tendrils creep forward.",
    "Spores drift on the wind.",
    "A clicking swarm descends.",
    "Frost and slime together.",
    "Dry husks roll across the field.",
    "The undergrowth thickens.",
    "Shadows move between the rows.",
    "Chitin and thorn collide.",
    "The whole lawn stirs.",
    "The garden groans under the weight.",
    "Pestilence rides the breeze.",
    "Thunder. Then silence.",
    "Something stirs beneath the soil.",
    "Something ancient uncoils...",
    "The earth splits. Roots everywhere.",
};

static void show_stage_intro(int w) {
    printf("\033[2J\033[1;1H\n\n\n");
    printf(CD "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" CR);
    printf(CM CB "   STAGE %d", w + 1);
    printf(CD " ── ");
    printf(CY "%s\n" CR, STAGE_NAME[w]);
    printf(CD "   \"%s\"\n" CR, STAGE_QUOTE[w]);
    printf(CD "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" CR);
    msleep(1800);
}

// ─── Wave phase (animated) ───────────────────────────────────────────────

static void run_wave(Game *g, WaveSpec *ws) {
    g->nen = 0; g->npj = 0;
    int spawned = 0, spawn_timer = 0, spawn_idx = 0;

    // Build spawn queue: flatten counts into a type array
    int queue[80], qlen = 0;
    for (int t = 0; t < NUM_EN; t++)
        for (int n = 0; n < ws->counts[t] && qlen < 60; n++)
            queue[qlen++] = t;

    // Sunflower income
    for (int i = 0; i < g->ntw; i++)
        if (g->tw[i].type == TW_SUNFLOWER) g->petals += 5 + g->wave;

    for (;;) {
        // Spawn
        if (spawned < ws->total && spawn_timer <= 0 && g->nen < MAX_ENEMY) {
            int type = queue[spawned % qlen];
            int lane = ws->lanes[drand(g->seed, spawn_idx, ws->nlanes)];
            Enemy *e = &g->en[g->nen++];
            e->type = type; e->hp = ENDEF[type].hp;
            e->lane = lane; e->col = COLS - 1; e->alive = 1;
            spawned++; spawn_timer = ws->interval; spawn_idx++;
        }
        spawn_timer--;

        // Move enemies
        enemies_move(g);
        if (!g->alive) return;

        // Towers fire
        towers_fire(g);

        // Move projectiles (includes collision)
        move_projs(g);

        // Draw
        printf("\033[1;1H");
        draw_header(g, ws);
        draw_map(g);
        printf("\n  " CD "Stage %d: %s  " CE "enemies: %d/%d" CR "     \n",
               g->wave + 1, STAGE_NAME[g->wave], spawned - ws->total + ws->total, ws->total);
        msleep(TICK_MS);

        if (spawned >= ws->total && !enemies_alive(g)) break;
    }
}

// ─── Placement phase ─────────────────────────────────────────────────────

static int parse_tw(char c) {
    for (int i = 0; i < NUM_TW; i++)
        if (TWDEF[i].icon == c || TWDEF[i].icon == (c & ~32)) return i;
    return -1;
}

static void placement_phase(Game *g, WaveSpec *ws) {
    draw_full(g, ws);
    printf("  " CY "place" CR " <lane> <col> <D|R|S|C|T>"
           "   " CY "next" CR "   " CY "help" CR "   " CY "quit" CR "\n\n");

    char line[64];
    for (;;) {
        printf(CC "  stage %d > " CR, g->wave + 1);
        fflush(stdout);
        if (!fgets(line, sizeof line, stdin)) { g->alive = 0; return; }
        line[strcspn(line, "\r\n")] = 0;
        char *cmd = line; while (*cmd == ' ') cmd++;
        if (!*cmd) continue;

        if (*cmd == 'q' || *cmd == 'Q') { g->alive = 0; return; }
        if (*cmd == 'n' || *cmd == 'N') return;

        if (strncmp(cmd, "place ", 6) == 0 || strncmp(cmd, "p ", 2) == 0) {
            char *args = strchr(cmd, ' ') + 1;
            int lane, col; char tc;
            if (sscanf(args, "%d %d %c", &lane, &col, &tc) < 3) {
                printf(CK "  Usage: p <lane 0-%d> <col 0-%d> <D|R|S|C|T>" CR "\n", LANES-1, COLS-3);
                continue;
            }
            int tt = parse_tw(tc);
            if (tt < 0) { printf(CK "  Unknown tower." CR "\n"); continue; }
            int rc = place_tower(g, lane, col, tt);
            if (rc == -1) printf(CK "  Out of bounds (lane 0-%d, col 0-%d)." CR "\n", LANES-1, COLS-3);
            else if (rc == -3) printf(CK "  Cell occupied." CR "\n");
            else if (rc == -4) printf(CK "  Need %d petals (have %d)." CR "\n",
                                      TWDEF[tt].cost, g->petals);
            else {
                printf(CG "  \xe2\x9c\x93 %s placed at lane %d col %d" CR "\n",
                       TWDEF[tt].name, lane, col);
                draw_full(g, ws);
                printf("  " CY "place" CR " <lane> <col> <D|R|S|C|T>"
                       "   " CY "next" CR "   " CY "help" CR "   " CY "quit" CR "\n\n");
            }
        }
        else if (cmd[0] == 'h' || cmd[0] == 'H') {
            printf("\n" CD "  ─── Towers ──────────────────────────────────────" CR "\n");
            for (int i = 0; i < NUM_TW; i++) {
                printf("  %s[%c] %-10s" CR CD " cost:%-3d", TWDEF[i].clr, TWDEF[i].icon,
                       TWDEF[i].name, TWDEF[i].cost);
                if (TWDEF[i].dmg)
                    printf("  dmg:%-3d cd:%-2d spd:%d%s" CR,
                           TWDEF[i].dmg, TWDEF[i].cd, TWDEF[i].proj_spd,
                           TWDEF[i].pierce ? " PIERCE" : "");
                else
                    printf("  +%d\xe2\x9a\x98/wave (economy)" CR, 5 + g->wave);
                printf("\n");
            }
            printf(CD "\n  ─── Enemies ─────────────────────────────────────" CR "\n");
            for (int i = 0; i < NUM_EN; i++)
                printf("  %s%c" CR CD " %-12s hp:%-3d spd:%d  reward:%d" CR "\n",
                       ENDEF[i].clr, ENDEF[i].icon, ENDEF[i].name,
                       ENDEF[i].hp, ENDEF[i].spd, ENDEF[i].reward);
            printf("\n  " CD "Stage %d: \"%s\"  (%d enemies, %d lanes, +%d\xe2\x9a\x98 bonus)" CR "\n\n",
                   g->wave+1, STAGE_NAME[g->wave], ws->total, ws->nlanes, ws->bonus);
        }
        else printf(CD "  Try: place 2 3 D | next | help | quit" CR "\n");
    }
}

// ─── Game loop ───────────────────────────────────────────────────────────

static void run_game(unsigned seed) {
    Game g;
    memset(&g, 0, sizeof g);
    g.petals = 30; g.lives = 10; g.alive = 1; g.seed = seed;

    // Intro
    printf("\033[?1049h\033[?25l\033[2J\033[1;1H\n\n");
    printf(CM CB
        "     .~.\n"
        "   .(   ).\n"
        "  ( " CC ".~." CM " )     " CG "FlowerOS Tower Defense" CR "\n"
        CM "   `-(  )-'\n"
        "     `-'       " CY "Flowers vs Creeps\n" CR
        CD "     _|_       Retro lane combat.\n"
        "   .(" CC "^" CD ").      Place towers. Watch them shoot.\n"
        "    |=|       Save your garden.\n"
        "   / \\_\n"
        "  o   o\n" CR
    );
    msleep(2500);
    printf("\033[?1049l\033[?25h");

    for (g.wave = 0; g.wave < NUM_WAVES && g.alive; g.wave++) {
        // Mana bonus at wave start
        if (g.wave > 0) g.petals += 10 + (g.wave - 1) * 5;

        WaveSpec ws;
        gen_wave(g.wave, seed, &ws);

        // Placement (normal screen)
        placement_phase(&g, &ws);
        if (!g.alive) break;

        // Stage intro + wave (alt screen)
        printf("\033[?1049h\033[?25l");
        show_stage_intro(g.wave);
        run_wave(&g, &ws);
        printf("\033[?1049l\033[?25h");

        if (!g.alive) break;

        printf(CG "\n  \xe2\x9c\x93 Stage %d \"%s\" cleared!" CR "\n", g.wave+1, STAGE_NAME[g.wave]);
        printf(CD "    Petals: %d (+%d bonus next)  Lives: %d  Score: %d" CR "\n\n",
               g.petals, 10 + g.wave * 5, g.lives, g.score);
    }

    if (g.lives <= 0)
        printf(CK CB "\n  \xe2\x95\x90\xe2\x95\x90 GARDEN LOST \xe2\x95\x90\xe2\x95\x90"
               "  Creeps overran your garden at stage %d." CR "\n", g.wave + 1);
    else
        printf(CG CB "\n  \xe2\x95\x90\xe2\x95\x90 VICTORY \xe2\x95\x90\xe2\x95\x90"
               "  All %d stages cleared!" CR "\n", NUM_WAVES);

    printf(CD "  Score: %d   Towers: %d   Petals: %d" CR "\n\n", g.score, g.ntw, g.petals);
}

// ─── Main ────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    unsigned seed = 42;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            printf("\n" CC "  flower-td" CR " \xe2\x80\x94 FlowerOS Tower Defense v2\n\n"
                CY "  Lane-based combat. Flowers vs Creeps.\n"
                "  Visible projectiles. Scaling difficulty + mana.\n\n" CR
                CD "  Towers:  [D]aisy [R]ose [S]unflower [C]actus [T]horn\n"
                "  Enemies: weeds, slugs, moths, fungus, locusts, tumbleweeds,\n"
                "           vine boss, root hydra\n"
                "  7 lanes x 30 cols, 20 stages, 30 starting petals, 10 lives\n\n"
                "  --seed N   Deterministic seed (default 42)\n" CR "\n");
            return 0;
        }
        if (!strcmp(argv[i], "--seed") && i+1 < argc) seed = (unsigned)atoi(argv[++i]);
    }
    run_game(seed);
    return 0;
}
