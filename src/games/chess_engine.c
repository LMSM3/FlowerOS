// ═══════════════════════════════════════════════════════════════════════════
//  chess_engine.c  —  FlowerOS Chess  (src/games/chess_engine.c)
//
//  A complete chess engine with three presentation modes:
//    --mode num   Numerical:  FEN + eval (cp) + UCI moves (the math model)
//    --mode sym   Symbolic:   Pastel ASCII board + Unicode pieces (default)
//    --mode gui   Graphical:  Launches Python tkinter board
//
//  Build:  gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-chess chess_engine.c
//  Usage:  flower-chess [OPTIONS]
//
//  Implementation matches chess_model.tex exactly:
//    State  s = (B, side, castling, ep, halfmove, fullmove)
//    Action A(s) = set of legal moves  (full generation, all rules)
//    T(s,a) = s'  deterministic transition
//    U_d(s) = minimax with alpha-beta pruning + quiescence
//    V(s)   = material + piece-square evaluation
//
//  Shell twin: games/chess.sh
// ═══════════════════════════════════════════════════════════════════════════

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <unistd.h>

// ─────────────────────────────────────────────────────────────────────────
//  FlowerOS pastel palette (subset — avoids requiring floweros.h)
// ─────────────────────────────────────────────────────────────────────────

#define C_RST "\033[0m"
#define C_ACC "\033[38;5;117m"   // mint-cyan   — white pieces
#define C_MAG "\033[38;5;183m"   // soft magenta — black pieces
#define C_DIM "\033[38;5;245m"   // grey         — board frame
#define C_GRN "\033[38;5;120m"   // green        — ok
#define C_RED "\033[38;5;210m"   // red          — error
#define C_YLW "\033[38;5;229m"   // yellow       — highlight
#define C_BLD "\033[1m"
#define C_DK  "\033[48;5;236m"   // dark square background

// ─────────────────────────────────────────────────────────────────────────
//  Piece encoding — bit 3 = colour, bits 0-2 = type
// ─────────────────────────────────────────────────────────────────────────

#define EMPTY   0
#define PAWN    1
#define KNIGHT  2
#define BISHOP  3
#define ROOK    4
#define QUEEN   5
#define KING    6

#define WHITE   0
#define BLACK   8

#define PIECE_TYPE(p)  ((p) & 7)
#define PIECE_COLOR(p) ((p) & 8)

#define SQ(r,f)   ((r)*8 + (f))
#define RANK(sq)  ((sq) >> 3)
#define FILE_(sq) ((sq) & 7)
#define ON_BOARD(r,f) ((unsigned)(r)<8 && (unsigned)(f)<8)

// Castling bits
#define WK 1
#define WQ 2
#define BK 4
#define BQ 8

// Move flags
#define MF_CAPTURE 1
#define MF_CASTLE  2
#define MF_EP      4
#define MF_DOUBLE  8
#define MF_PROMO  16

#define MATE_SCORE 30000
#define MAX_MOVES  256

// ─────────────────────────────────────────────────────────────────────────
//  Types
// ─────────────────────────────────────────────────────────────────────────

typedef struct { unsigned char from, to, promo, flags; } Move;
typedef struct { Move m[MAX_MOVES]; int n; } MoveList;

typedef struct {
    int  board[64];
    int  side;          // WHITE or BLACK
    int  castle;        // bitmask WK|WQ|BK|BQ
    int  ep;            // en-passant target square or -1
    int  half;          // halfmove clock
    int  full;          // fullmove number
    int  ksq[2];        // king squares [white_idx=0, black_idx=1]
} Pos;

typedef enum { MODE_SYM, MODE_NUM, MODE_GUI, MODE_PIPE } DispMode;

// ─────────────────────────────────────────────────────────────────────────
//  Direction tables
// ─────────────────────────────────────────────────────────────────────────

static const int N_DR[] = {-2,-2,-1,-1,+1,+1,+2,+2};
static const int N_DF[] = {-1,+1,-2,+2,-2,+2,-1,+1};
static const int K_DR[] = {-1,-1,-1, 0, 0,+1,+1,+1};
static const int K_DF[] = {-1, 0,+1,-1,+1,-1, 0,+1};
static const int B_DR[] = {-1,-1,+1,+1};
static const int B_DF[] = {-1,+1,-1,+1};
static const int R_DR[] = {-1,+1, 0, 0};
static const int R_DF[] = { 0, 0,-1,+1};

// ─────────────────────────────────────────────────────────────────────────
//  Piece-square tables (from White's perspective, a1=index 0)
//  V(s) = Σ material + Σ PST — matches chess_model.tex §1.3
// ─────────────────────────────────────────────────────────────────────────

static const int MAT[] = {0, 100, 320, 330, 500, 900, 20000};

static const int PST_P[64] = {
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10,-20,-20, 10, 10,  5,
     5, -5,-10,  0,  0,-10, -5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5,  5, 10, 25, 25, 10,  5,  5,
    10, 10, 20, 30, 30, 20, 10, 10,
    50, 50, 50, 50, 50, 50, 50, 50,
     0,  0,  0,  0,  0,  0,  0,  0,
};
static const int PST_N[64] = {
   -50,-40,-30,-30,-30,-30,-40,-50,
   -40,-20,  0,  5,  5,  0,-20,-40,
   -30,  5, 10, 15, 15, 10,  5,-30,
   -30,  0, 15, 20, 20, 15,  0,-30,
   -30,  5, 15, 20, 20, 15,  5,-30,
   -30,  0, 10, 15, 15, 10,  0,-30,
   -40,-20,  0,  0,  0,  0,-20,-40,
   -50,-40,-30,-30,-30,-30,-40,-50,
};
static const int PST_B[64] = {
   -20,-10,-10,-10,-10,-10,-10,-20,
   -10,  5,  0,  0,  0,  0,  5,-10,
   -10, 10, 10, 10, 10, 10, 10,-10,
   -10,  0, 10, 10, 10, 10,  0,-10,
   -10,  5,  5, 10, 10,  5,  5,-10,
   -10,  0,  5, 10, 10,  5,  0,-10,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -20,-10,-10,-10,-10,-10,-10,-20,
};
static const int PST_R[64] = {
     0,  0,  0,  5,  5,  0,  0,  0,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     5, 10, 10, 10, 10, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0,
};
static const int PST_Q[64] = {
   -20,-10,-10, -5, -5,-10,-10,-20,
   -10,  0,  5,  0,  0,  0,  0,-10,
   -10,  5,  5,  5,  5,  5,  0,-10,
     0,  0,  5,  5,  5,  5,  0, -5,
    -5,  0,  5,  5,  5,  5,  0, -5,
   -10,  0,  5,  5,  5,  5,  0,-10,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -20,-10,-10, -5, -5,-10,-10,-20,
};
static const int PST_K[64] = {
    20, 30, 10,  0,  0, 10, 30, 20,
    20, 20,  0,  0,  0,  0, 20, 20,
   -10,-20,-20,-20,-20,-20,-20,-10,
   -20,-30,-30,-40,-40,-30,-30,-20,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
};

static const int *PST[] = {NULL, PST_P, PST_N, PST_B, PST_R, PST_Q, PST_K};

// ─────────────────────────────────────────────────────────────────────────
//  FEN parse / generate
// ─────────────────────────────────────────────────────────────────────────

static const char *START_FEN =
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

static int char_to_piece(char c) {
    const char *s = " PNBRQK  pnbrqk";
    for (int i = 1; i <= 14; i++) if (s[i] == c) return i;
    return 0;
}

static void parse_fen(Pos *p, const char *fen) {
    memset(p, 0, sizeof *p);
    p->ep = -1;
    int r = 7, f = 0, i = 0;

    while (fen[i] && fen[i] != ' ') {
        if (fen[i] == '/') { r--; f = 0; }
        else if (fen[i] >= '1' && fen[i] <= '8') f += fen[i] - '0';
        else {
            int pc = char_to_piece(fen[i]);
            int sq = SQ(r, f);
            p->board[sq] = pc;
            if (PIECE_TYPE(pc) == KING) p->ksq[PIECE_COLOR(pc) >> 3] = sq;
            f++;
        }
        i++;
    }
    i++;
    p->side = (fen[i] == 'b') ? BLACK : WHITE; i += 2;

    if (fen[i] == '-') { i += 2; }
    else {
        while (fen[i] && fen[i] != ' ') {
            if (fen[i]=='K') p->castle |= WK;
            if (fen[i]=='Q') p->castle |= WQ;
            if (fen[i]=='k') p->castle |= BK;
            if (fen[i]=='q') p->castle |= BQ;
            i++;
        }
        i++;
    }

    if (fen[i] == '-') { p->ep = -1; i += 2; }
    else { p->ep = SQ(fen[i+1]-'1', fen[i]-'a'); i += 3; }

    p->half = atoi(fen + i);
    while (fen[i] && fen[i] != ' ') i++;
    i++;
    p->full = atoi(fen + i);
}

static void to_fen(const Pos *p, char *buf, int sz) {
    static const char fc[] = " PNBRQK  pnbrqk";
    int o = 0;
    for (int r = 7; r >= 0; r--) {
        int e = 0;
        for (int f = 0; f < 8; f++) {
            int pc = p->board[SQ(r, f)];
            if (pc == EMPTY) { e++; continue; }
            if (e) { buf[o++] = '0'+e; e = 0; }
            buf[o++] = fc[pc];
        }
        if (e) buf[o++] = '0'+e;
        if (r > 0) buf[o++] = '/';
    }
    o += snprintf(buf+o, (size_t)(sz-o), " %c ", p->side==WHITE ? 'w' : 'b');
    if (!p->castle) buf[o++] = '-';
    else {
        if (p->castle&WK) buf[o++]='K';
        if (p->castle&WQ) buf[o++]='Q';
        if (p->castle&BK) buf[o++]='k';
        if (p->castle&BQ) buf[o++]='q';
    }
    if (p->ep < 0) o += snprintf(buf+o,(size_t)(sz-o)," - ");
    else o += snprintf(buf+o,(size_t)(sz-o)," %c%c ", 'a'+FILE_(p->ep), '1'+RANK(p->ep));
    snprintf(buf+o, (size_t)(sz-o), "%d %d", p->half, p->full);
}

// ─────────────────────────────────────────────────────────────────────────
//  Attack detection — is sq attacked by 'by' (WHITE or BLACK)?
// ─────────────────────────────────────────────────────────────────────────

static int attacked(const Pos *p, int sq, int by) {
    int r = RANK(sq), f = FILE_(sq);

    // Pawns
    int pd = (by == WHITE) ? -1 : 1;
    for (int df = -1; df <= 1; df += 2) {
        int pr = r+pd, pf = f+df;
        if (ON_BOARD(pr,pf) && p->board[SQ(pr,pf)] == (by|PAWN)) return 1;
    }
    // Knights
    for (int d = 0; d < 8; d++) {
        int nr = r+N_DR[d], nf = f+N_DF[d];
        if (ON_BOARD(nr,nf) && p->board[SQ(nr,nf)] == (by|KNIGHT)) return 1;
    }
    // King
    for (int d = 0; d < 8; d++) {
        int nr = r+K_DR[d], nf = f+K_DF[d];
        if (ON_BOARD(nr,nf) && p->board[SQ(nr,nf)] == (by|KING)) return 1;
    }
    // Bishop / Queen (diag)
    for (int d = 0; d < 4; d++)
        for (int s = 1; s < 8; s++) {
            int nr = r+B_DR[d]*s, nf = f+B_DF[d]*s;
            if (!ON_BOARD(nr,nf)) break;
            int pc = p->board[SQ(nr,nf)];
            if (pc) { if (pc==(by|BISHOP)||pc==(by|QUEEN)) return 1; break; }
        }
    // Rook / Queen (ortho)
    for (int d = 0; d < 4; d++)
        for (int s = 1; s < 8; s++) {
            int nr = r+R_DR[d]*s, nf = f+R_DF[d]*s;
            if (!ON_BOARD(nr,nf)) break;
            int pc = p->board[SQ(nr,nf)];
            if (pc) { if (pc==(by|ROOK)||pc==(by|QUEEN)) return 1; break; }
        }
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Move generation (pseudo-legal, then filtered for legality)
// ─────────────────────────────────────────────────────────────────────────

static void add(MoveList *ml, int fr, int to, int pr, int fl) {
    Move *m = &ml->m[ml->n++];
    m->from = (unsigned char)fr; m->to = (unsigned char)to;
    m->promo = (unsigned char)pr; m->flags = (unsigned char)fl;
}

static void add_promos(MoveList *ml, int fr, int to, int fl) {
    add(ml, fr, to, QUEEN,  fl|MF_PROMO);
    add(ml, fr, to, ROOK,   fl|MF_PROMO);
    add(ml, fr, to, BISHOP, fl|MF_PROMO);
    add(ml, fr, to, KNIGHT, fl|MF_PROMO);
}

static void gen_pseudo(const Pos *p, MoveList *ml) {
    ml->n = 0;
    int us = p->side, them = us ^ BLACK;

    for (int sq = 0; sq < 64; sq++) {
        int pc = p->board[sq];
        if (!pc || PIECE_COLOR(pc) != us) continue;
        int r = RANK(sq), f = FILE_(sq), typ = PIECE_TYPE(pc);

        if (typ == PAWN) {
            int fwd = (us==WHITE) ? 1 : -1;
            int sr  = (us==WHITE) ? 1 : 6;
            int pr  = (us==WHITE) ? 7 : 0;
            int to  = SQ(r+fwd, f);
            // single push
            if (p->board[to] == EMPTY) {
                if (r+fwd == pr) add_promos(ml, sq, to, 0);
                else {
                    add(ml, sq, to, 0, 0);
                    // double push
                    if (r == sr) {
                        int to2 = SQ(r+2*fwd, f);
                        if (p->board[to2] == EMPTY)
                            add(ml, sq, to2, 0, MF_DOUBLE);
                    }
                }
            }
            // captures
            for (int df = -1; df <= 1; df += 2) {
                int nf = f+df;
                if (nf < 0 || nf > 7) continue;
                int cs = SQ(r+fwd, nf);
                int tgt = p->board[cs];
                if (tgt && PIECE_COLOR(tgt) == them) {
                    if (r+fwd == pr) add_promos(ml, sq, cs, MF_CAPTURE);
                    else add(ml, sq, cs, 0, MF_CAPTURE);
                }
                if (cs == p->ep)
                    add(ml, sq, cs, 0, MF_EP|MF_CAPTURE);
            }
        }
        else if (typ == KNIGHT) {
            for (int d = 0; d < 8; d++) {
                int nr = r+N_DR[d], nf = f+N_DF[d];
                if (!ON_BOARD(nr,nf)) continue;
                int to = SQ(nr,nf), tgt = p->board[to];
                if (!tgt) add(ml, sq, to, 0, 0);
                else if (PIECE_COLOR(tgt)==them) add(ml, sq, to, 0, MF_CAPTURE);
            }
        }
        else if (typ == BISHOP || typ == ROOK || typ == QUEEN) {
            const int *dr = (typ==ROOK) ? R_DR : B_DR;
            const int *df = (typ==ROOK) ? R_DF : B_DF;
            int nd = 4;
            // queen: do both bishop + rook dirs
            for (int pass = 0; pass < (typ==QUEEN ? 2 : 1); pass++) {
                if (pass == 1) { dr = R_DR; df = R_DF; }
                for (int d = 0; d < nd; d++)
                    for (int s = 1; s < 8; s++) {
                        int nr = r+dr[d]*s, nf2 = f+df[d]*s;
                        if (!ON_BOARD(nr,nf2)) break;
                        int to = SQ(nr,nf2), tgt = p->board[to];
                        if (!tgt) add(ml, sq, to, 0, 0);
                        else { if (PIECE_COLOR(tgt)==them) add(ml, sq, to, 0, MF_CAPTURE); break; }
                    }
            }
        }
        else if (typ == KING) {
            for (int d = 0; d < 8; d++) {
                int nr = r+K_DR[d], nf = f+K_DF[d];
                if (!ON_BOARD(nr,nf)) continue;
                int to = SQ(nr,nf), tgt = p->board[to];
                if (!tgt) add(ml, sq, to, 0, 0);
                else if (PIECE_COLOR(tgt)==them) add(ml, sq, to, 0, MF_CAPTURE);
            }
            // Castling
            int kr = (us==WHITE) ? 0 : 7;
            if (sq == SQ(kr,4)) {
                int opp = us ^ BLACK;
                int km = (us==WHITE) ? WK : BK;
                int qm = (us==WHITE) ? WQ : BQ;
                if ((p->castle&km) &&
                    !p->board[SQ(kr,5)] && !p->board[SQ(kr,6)] &&
                    !attacked(p,SQ(kr,4),opp) &&
                    !attacked(p,SQ(kr,5),opp) &&
                    !attacked(p,SQ(kr,6),opp))
                    add(ml, sq, SQ(kr,6), 0, MF_CASTLE);
                if ((p->castle&qm) &&
                    !p->board[SQ(kr,3)] && !p->board[SQ(kr,2)] && !p->board[SQ(kr,1)] &&
                    !attacked(p,SQ(kr,4),opp) &&
                    !attacked(p,SQ(kr,3),opp) &&
                    !attacked(p,SQ(kr,2),opp))
                    add(ml, sq, SQ(kr,2), 0, MF_CASTLE);
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Make move (copy-make — no undo stack)
//  Implements T(s,a) = s'  from chess_model.tex §1.2
// ─────────────────────────────────────────────────────────────────────────

static void make(Pos *p, const Move *mv) {
    int pc = p->board[mv->from];
    p->board[mv->to]   = pc;
    p->board[mv->from] = EMPTY;

    if (mv->flags & MF_EP) {
        p->board[SQ(RANK(mv->from), FILE_(mv->to))] = EMPTY;
    }
    if (mv->flags & MF_CASTLE) {
        int kr = RANK(mv->to);
        if (FILE_(mv->to) == 6) {
            p->board[SQ(kr,5)] = p->board[SQ(kr,7)]; p->board[SQ(kr,7)] = EMPTY;
        } else {
            p->board[SQ(kr,3)] = p->board[SQ(kr,0)]; p->board[SQ(kr,0)] = EMPTY;
        }
    }
    if (mv->flags & MF_PROMO)
        p->board[mv->to] = p->side | mv->promo;

    p->ep = ((mv->flags & MF_DOUBLE) && PIECE_TYPE(pc)==PAWN)
        ? SQ((RANK(mv->from)+RANK(mv->to))/2, FILE_(mv->from)) : -1;

    if (PIECE_TYPE(pc)==KING) {
        p->ksq[p->side >> 3] = mv->to;
        if (p->side==WHITE) p->castle &= ~(WK|WQ); else p->castle &= ~(BK|BQ);
    }
    if (mv->from==SQ(0,0)||mv->to==SQ(0,0)) p->castle &= ~WQ;
    if (mv->from==SQ(0,7)||mv->to==SQ(0,7)) p->castle &= ~WK;
    if (mv->from==SQ(7,0)||mv->to==SQ(7,0)) p->castle &= ~BQ;
    if (mv->from==SQ(7,7)||mv->to==SQ(7,7)) p->castle &= ~BK;

    if (PIECE_TYPE(pc)==PAWN || (mv->flags&MF_CAPTURE)) p->half = 0; else p->half++;
    if (p->side == BLACK) p->full++;
    p->side ^= BLACK;
}

// ─────────────────────────────────────────────────────────────────────────
//  Legality filter — generate pseudo, keep only those that don't leave
//  the moving side's king in check.
// ─────────────────────────────────────────────────────────────────────────

static int is_legal(const Pos *p, const Move *mv) {
    Pos c = *p;
    make(&c, mv);
    int idx = p->side >> 3;
    return !attacked(&c, c.ksq[idx], c.side);
}

static void gen_legal(const Pos *p, MoveList *ml) {
    MoveList pseudo;
    gen_pseudo(p, &pseudo);
    ml->n = 0;
    for (int i = 0; i < pseudo.n; i++)
        if (is_legal(p, &pseudo.m[i]))
            ml->m[ml->n++] = pseudo.m[i];
}

// ─────────────────────────────────────────────────────────────────────────
//  Evaluation — V(s) from chess_model.tex §1.3
//  Material balance + piece-square tables, negamax convention.
// ─────────────────────────────────────────────────────────────────────────

static int evaluate(const Pos *p) {
    int score = 0;
    for (int sq = 0; sq < 64; sq++) {
        int pc = p->board[sq];
        if (!pc) continue;
        int t = PIECE_TYPE(pc);
        int v = MAT[t];
        if (PIECE_COLOR(pc) == WHITE) {
            v += PST[t][sq];
            score += v;
        } else {
            int fl = (7 - RANK(sq)) * 8 + FILE_(sq);
            v += PST[t][fl];
            score -= v;
        }
    }
    return (p->side == WHITE) ? score : -score;
}

// ─────────────────────────────────────────────────────────────────────────
//  Search — U_d(s) minimax with alpha-beta (chess_model.tex §2)
// ─────────────────────────────────────────────────────────────────────────

static long long g_nodes;

static void order_moves(const Pos *p, MoveList *ml) {
    // Captures first (simple swap to front)
    int front = 0;
    for (int i = 0; i < ml->n; i++)
        if (ml->m[i].flags & MF_CAPTURE) {
            Move t = ml->m[front]; ml->m[front] = ml->m[i]; ml->m[i] = t;
            front++;
        }
    (void)p;
}

static int quiesce(const Pos *p, int alpha, int beta) {
    g_nodes++;
    int stand = evaluate(p);
    if (stand >= beta) return beta;
    if (stand > alpha) alpha = stand;

    MoveList pseudo;
    gen_pseudo(p, &pseudo);
    order_moves(p, &pseudo);

    int idx = p->side >> 3;
    for (int i = 0; i < pseudo.n; i++) {
        if (!(pseudo.m[i].flags & MF_CAPTURE)) continue;
        Pos c = *p;
        make(&c, &pseudo.m[i]);
        if (attacked(&c, c.ksq[idx], c.side)) continue;
        int sc = -quiesce(&c, -beta, -alpha);
        if (sc >= beta) return beta;
        if (sc > alpha) alpha = sc;
    }
    return alpha;
}

static int negamax(const Pos *p, int depth, int ply, int alpha, int beta) {
    if (depth <= 0) return quiesce(p, alpha, beta);
    g_nodes++;

    MoveList pseudo;
    gen_pseudo(p, &pseudo);
    order_moves(p, &pseudo);

    int idx = p->side >> 3;
    int legal = 0;

    for (int i = 0; i < pseudo.n; i++) {
        Pos c = *p;
        make(&c, &pseudo.m[i]);
        if (attacked(&c, c.ksq[idx], c.side)) continue;
        legal++;
        int sc = -negamax(&c, depth-1, ply+1, -beta, -alpha);
        if (sc >= beta) return beta;
        if (sc > alpha) alpha = sc;
    }

    if (!legal) {
        if (attacked(p, p->ksq[idx], p->side ^ BLACK))
            return -(MATE_SCORE - ply);
        return 0;
    }
    return alpha;
}

static Move search(const Pos *p, int max_depth, int verbose) {
    Move best = {0};
    int best_score = -MATE_SCORE - 1;

    for (int d = 1; d <= max_depth; d++) {
        g_nodes = 0;
        MoveList pseudo;
        gen_pseudo(p, &pseudo);
        order_moves(p, &pseudo);

        int idx = p->side >> 3;
        int alpha = -MATE_SCORE - 1, beta = MATE_SCORE + 1;
        Move iter_best = {0};
        int iter_score = -MATE_SCORE - 1;

        for (int i = 0; i < pseudo.n; i++) {
            Pos c = *p;
            make(&c, &pseudo.m[i]);
            if (attacked(&c, c.ksq[idx], c.side)) continue;
            int sc = -negamax(&c, d-1, 1, -beta, -alpha);
            if (sc > iter_score) { iter_score = sc; iter_best = pseudo.m[i]; }
            if (sc > alpha) alpha = sc;
        }

        best = iter_best;
        best_score = iter_score;
        if (verbose) {
            char mv[8];
            mv[0] = 'a'+FILE_(best.from); mv[1] = '1'+RANK(best.from);
            mv[2] = 'a'+FILE_(best.to);   mv[3] = '1'+RANK(best.to);
            mv[4] = 0;
            if (best.flags & MF_PROMO) {
                const char pc[] = " .nbrq";
                mv[4] = pc[best.promo]; mv[5] = 0;
            }
            printf(C_DIM "  depth=%-2d  nodes=%-8lld  eval=%+.2f  best=%s" C_RST "\n",
                   d, g_nodes, best_score / 100.0, mv);
        }
        (void)best_score;
    }
    return best;
}

// ─────────────────────────────────────────────────────────────────────────
//  Move to/from UCI string
// ─────────────────────────────────────────────────────────────────────────

static void move_uci(const Move *mv, char *buf) {
    buf[0] = 'a'+FILE_(mv->from); buf[1] = '1'+RANK(mv->from);
    buf[2] = 'a'+FILE_(mv->to);   buf[3] = '1'+RANK(mv->to);
    buf[4] = 0;
    if (mv->flags & MF_PROMO) {
        const char pc[] = " .nbrq";
        buf[4] = pc[mv->promo]; buf[5] = 0;
    }
}

static int parse_uci(const char *s, Move *mv) {
    if (strlen(s) < 4) return 0;
    int ff = s[0]-'a', fr = s[1]-'1', tf = s[2]-'a', tr = s[3]-'1';
    if ((unsigned)ff>7||(unsigned)fr>7||(unsigned)tf>7||(unsigned)tr>7) return 0;
    mv->from = (unsigned char)SQ(fr,ff); mv->to = (unsigned char)SQ(tr,tf);
    mv->promo = 0; mv->flags = 0;
    if (s[4]) {
        switch (s[4]) {
            case 'q': mv->promo = QUEEN; break;  case 'r': mv->promo = ROOK; break;
            case 'b': mv->promo = BISHOP; break; case 'n': mv->promo = KNIGHT; break;
        }
    }
    return 1;
}

static int find_legal(const MoveList *ml, const Move *u, Move *out) {
    for (int i = 0; i < ml->n; i++)
        if (ml->m[i].from == u->from && ml->m[i].to == u->to &&
            (!u->promo || ml->m[i].promo == u->promo))
            { *out = ml->m[i]; return 1; }
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Piece-name move input  (KL, KR, B, P1-P8, Q, RL, RR, K)
//
//  Format: <Piece>[Qualifier] [<target>]
//    P1-P8  — pawn by file (P1 = a-pawn, P8 = h-pawn)
//    KL/KR  — left/right knight (from white's view: KL = b-file, KR = g-file)
//    B / BL / BR — bishop (light/dark disambiguated by L/R)
//    RL / RR — left/right rook
//    Q      — queen
//    K      — king
//    O-O / O-O-O — castling
//  If the piece has exactly one legal move, it is played immediately.
//  If multiple, the target square (e.g. "KL f3") resolves it.
//  Returns 1 on success, 0 on failure (sets *out).
// ─────────────────────────────────────────────────────────────────────────

static int parse_piece_cmd(const Pos *p, const MoveList *ml,
                           const char *s, Move *out) {
    // Skip whitespace
    while (*s == ' ') s++;
    if (!*s) return 0;

    // Castling shorthand
    if (strcmp(s, "O-O") == 0 || strcmp(s, "o-o") == 0 ||
        strcmp(s, "0-0") == 0) {
        int king_sq = (p->side == WHITE) ? SQ(0,4) : SQ(7,4);
        int to_sq   = (p->side == WHITE) ? SQ(0,6) : SQ(7,6);
        Move u = {(unsigned char)king_sq, (unsigned char)to_sq, 0, 0};
        return find_legal(ml, &u, out);
    }
    if (strcmp(s, "O-O-O") == 0 || strcmp(s, "o-o-o") == 0 ||
        strcmp(s, "0-0-0") == 0) {
        int king_sq = (p->side == WHITE) ? SQ(0,4) : SQ(7,4);
        int to_sq   = (p->side == WHITE) ? SQ(0,2) : SQ(7,2);
        Move u = {(unsigned char)king_sq, (unsigned char)to_sq, 0, 0};
        return find_legal(ml, &u, out);
    }

    int piece_type = 0, file_filter = -1;
    char target[4] = {0};

    if ((s[0] == 'P' || s[0] == 'p') && s[1] >= '1' && s[1] <= '8') {
        // P1-P8: pawn by file number
        piece_type = PAWN;
        file_filter = s[1] - '1';  // P1=file a=0, P8=file h=7
        if (s[2] == ' ' && s[3]) { target[0] = s[3]; target[1] = s[4]; }
    } else if ((s[0] == 'K' || s[0] == 'k') &&
               (s[1] == 'L' || s[1] == 'l' || s[1] == 'R' || s[1] == 'r') &&
               s[0] != 'k') {
        // KL/KR: knight left/right
        piece_type = KNIGHT;
        // KL = lower file, KR = higher file among knights
        int want_left = (s[1] == 'L' || s[1] == 'l');
        // Find all knights of this side
        int color = p->side;
        int kn_files[2], nkn = 0;
        for (int sq = 0; sq < 64 && nkn < 2; sq++) {
            if (p->board[sq] == (KNIGHT | color))
                kn_files[nkn++] = FILE_(sq);
        }
        if (nkn == 0) return 0;
        if (nkn == 1) file_filter = kn_files[0];
        else {
            int lo = (kn_files[0] < kn_files[1]) ? kn_files[0] : kn_files[1];
            int hi = (kn_files[0] < kn_files[1]) ? kn_files[1] : kn_files[0];
            file_filter = want_left ? lo : hi;
        }
        if (s[2] == ' ' && s[3]) { target[0] = s[3]; target[1] = s[4]; }
    } else {
        // Single-letter piece: K, Q, B, R  (with optional L/R qualifier)
        switch (s[0]) {
            case 'K': case 'k': piece_type = KING; break;
            case 'Q': case 'q': piece_type = QUEEN; break;
            case 'B': case 'b': piece_type = BISHOP; break;
            case 'R': case 'r': piece_type = ROOK; break;
            default: return 0;
        }
        int off = 1;
        if ((piece_type == BISHOP || piece_type == ROOK) &&
            (s[1] == 'L' || s[1] == 'l' || s[1] == 'R' || s[1] == 'r')) {
            // L = lower file, R = higher file
            int want_left = (s[1] == 'L' || s[1] == 'l');
            int color = p->side;
            int files[2], nf = 0;
            for (int sq = 0; sq < 64 && nf < 2; sq++)
                if (p->board[sq] == (piece_type | color)) files[nf++] = FILE_(sq);
            if (nf == 1) file_filter = files[0];
            else if (nf >= 2) {
                int lo = (files[0] < files[1]) ? files[0] : files[1];
                int hi = (files[0] < files[1]) ? files[1] : files[0];
                file_filter = want_left ? lo : hi;
            }
            off = 2;
        }
        if (s[off] == ' ' && s[off+1]) { target[0] = s[off+1]; target[1] = s[off+2]; }
    }

    if (piece_type == 0) return 0;

    // Parse optional target square
    int target_sq = -1;
    if (target[0] >= 'a' && target[0] <= 'h' && target[1] >= '1' && target[1] <= '8')
        target_sq = SQ(target[1]-'1', target[0]-'a');

    // Find matching legal moves
    int color = p->side;
    Move matches[MAX_MOVES];
    int nm = 0;
    for (int i = 0; i < ml->n; i++) {
        const Move *m = &ml->m[i];
        int from_piece = PIECE_TYPE(p->board[m->from]);
        int from_color = PIECE_COLOR(p->board[m->from]);
        if (from_piece != piece_type || from_color != color) continue;
        if (file_filter >= 0 && FILE_(m->from) != file_filter) continue;
        if (target_sq >= 0 && (int)m->to != target_sq) continue;
        matches[nm++] = *m;
    }

    if (nm == 1) { *out = matches[0]; return 1; }
    if (nm == 0) return 0;

    // Multiple matches — show them and pick the first (or let user add target)
    printf(C_YLW "  %d moves match. Add target square to disambiguate:" C_RST "\n ", nm);
    for (int i = 0; i < nm && i < 8; i++) {
        char u[8]; move_uci(&matches[i], u);
        printf(" %s", u);
    }
    printf("\n");
    return 0;
}
// ─────────────────────────────────────────────────────────────────────────

static const char *PIECE_UNI[] = {
    " ", "\u2659","\u2658","\u2657","\u2656","\u2655","\u2654",
    " ", " ", "\u265f","\u265e","\u265d","\u265c","\u265b","\u265a"
};

static void display_sym(const Pos *p, const Move *last) {
    printf("\n");
    printf(C_DIM "  ┌───┬───┬───┬───┬───┬───┬───┬───┐" C_RST "\n");
    for (int r = 7; r >= 0; r--) {
        printf(C_DIM "%d │" C_RST, r + 1);
        for (int f = 0; f < 8; f++) {
            int sq = SQ(r, f), pc = p->board[sq];
            int dark = (r + f) % 2 == 0;
            int hl = last && (sq == last->from || sq == last->to);
            if (hl) printf(C_YLW);
            else if (dark) printf(C_DK);
            if (!pc) printf("   ");
            else if (PIECE_COLOR(pc) == WHITE) printf(C_ACC " %s " C_RST, PIECE_UNI[pc]);
            else printf(C_MAG " %s " C_RST, PIECE_UNI[pc]);
            if (dark || hl) printf(C_RST);
            printf(C_DIM "│" C_RST);
        }
        printf("\n");
        if (r > 0) printf(C_DIM "  ├───┼───┼───┼───┼───┼───┼───┼───┤" C_RST "\n");
    }
    printf(C_DIM "  └───┴───┴───┴───┴───┴───┴───┴───┘" C_RST "\n");
    printf(C_DIM "    a   b   c   d   e   f   g   h" C_RST "\n\n");
}

static void display_num(const Pos *p, const MoveList *ml) {
    char fen[128]; to_fen(p, fen, sizeof fen);
    printf(C_DIM "FEN : " C_RST "%s\n", fen);
    printf(C_DIM "Eval: " C_RST "%+.2f cp\n", evaluate(p) / 100.0);

    int wm = 0, bm = 0;
    for (int sq = 0; sq < 64; sq++) {
        int pc = p->board[sq]; if (!pc || PIECE_TYPE(pc)==KING) continue;
        if (PIECE_COLOR(pc)==WHITE) wm += MAT[PIECE_TYPE(pc)]; else bm += MAT[PIECE_TYPE(pc)];
    }
    printf(C_DIM "Mat : " C_RST "W=%d  B=%d  Δ=%+d\n", wm, bm, wm-bm);

    printf(C_DIM "Legal:" C_RST);
    for (int i = 0; i < ml->n; i++) {
        char mv[8]; move_uci(&ml->m[i], mv);
        printf(" %s", mv);
    }
    printf("  (%d moves)\n\n", ml->n);
}

// ─────────────────────────────────────────────────────────────────────────
//  Game result check
// ─────────────────────────────────────────────────────────────────────────

static const char *game_result(const Pos *p, const MoveList *ml) {
    if (ml->n > 0) {
        if (p->half >= 100) return "Draw (50-move rule)";
        return NULL;
    }
    int idx = p->side >> 3;
    if (attacked(p, p->ksq[idx], p->side ^ BLACK)) return "Checkmate";
    return "Stalemate";
}

// ─────────────────────────────────────────────────────────────────────────
//  Pipe mode — minimal protocol for GUI communication
//  Engine -> GUI:  pos <FEN>  |  legal <uci>...  |  bestmove <uci>
//  GUI -> Engine:  move <uci>  |  quit
// ─────────────────────────────────────────────────────────────────────────

static void run_pipe(const char *start_fen, int depth) {
    Pos pos; parse_fen(&pos, start_fen);
    char line[256];

    printf("ready\n"); fflush(stdout);

    for (;;) {
        // Send position
        char fen[128]; to_fen(&pos, fen, sizeof fen);
        printf("pos %s\n", fen);

        MoveList ml; gen_legal(&pos, &ml);
        printf("legal");
        for (int i = 0; i < ml.n; i++) { char u[8]; move_uci(&ml.m[i], u); printf(" %s", u); }
        printf("\n");

        const char *res = game_result(&pos, &ml);
        if (res) { printf("gameover %s\n", res); fflush(stdout); break; }

        printf("eval %.2f\n", evaluate(&pos) / 100.0);
        fflush(stdout);

        // Read command
        if (!fgets(line, sizeof line, stdin)) break;
        line[strcspn(line, "\r\n")] = 0;

        if (strncmp(line, "quit", 4) == 0) break;
        if (strncmp(line, "go", 2) == 0) {
            Move best = search(&pos, depth, 0);
            char u[8]; move_uci(&best, u);
            printf("bestmove %s\n", u); fflush(stdout);
            make(&pos, &best);
        }
        else if (strncmp(line, "move ", 5) == 0) {
            Move u, legal;
            if (parse_uci(line+5, &u) && find_legal(&ml, &u, &legal))
                make(&pos, &legal);
            else { printf("error ILLEGAL_MOVE\n"); fflush(stdout); }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Interactive game loop
// ─────────────────────────────────────────────────────────────────────────

static void run_game(DispMode mode, int depth, int human_side,
                     int engine_both, const char *start_fen) {
    Pos pos; parse_fen(&pos, start_fen);
    Move last_move = {0}; int has_last = 0;

    for (;;) {
        MoveList ml; gen_legal(&pos, &ml);

        if (mode == MODE_SYM) display_sym(&pos, has_last ? &last_move : NULL);
        if (mode == MODE_NUM || mode == MODE_SYM) display_num(&pos, &ml);

        const char *res = game_result(&pos, &ml);
        if (res) {
            printf(C_BLD "%s!" C_RST "\n\n", res);
            break;
        }

        int is_human = !engine_both && ((int)pos.side == human_side);

        if (is_human) {
            printf(C_ACC "%s to move > " C_RST,
                   pos.side == WHITE ? "White" : "Black");
            fflush(stdout);
            char line[64];
            if (!fgets(line, sizeof line, stdin)) break;
            line[strcspn(line, "\r\n")] = 0;

            if (strcmp(line, "quit") == 0 || strcmp(line, "q") == 0) break;

            Move u, legal;
            if (parse_piece_cmd(&pos, &ml, line, &legal)) {
                // Piece-name input matched
            } else if (parse_uci(line, &u) && find_legal(&ml, &u, &legal)) {
                // UCI input matched
            } else {
                printf(C_RED "  Illegal. Try: P1-P8  KL/KR  B  RL/RR  Q  K  O-O  or UCI (e2e4)" C_RST "\n");
                continue;
            }
            make(&pos, &legal);
            last_move = legal; has_last = 1;
        } else {
            printf(C_DIM "  Engine thinking (depth %d)..." C_RST "\n", depth);
            Move best = search(&pos, depth, 1);
            char u[8]; move_uci(&best, u);
            printf(C_GRN "  Engine plays: %s" C_RST "\n\n", u);
            make(&pos, &best);
            last_move = best; has_last = 1;
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Help / main
// ─────────────────────────────────────────────────────────────────────────

static void print_help(void) {
    printf("\n" C_ACC "  flower-chess" C_RST " — FlowerOS terminal chess\n\n"
        C_DIM "  Usage:" C_RST "  flower-chess [OPTIONS]\n\n"
        "  " C_YLW "--mode num" C_RST "    Numerical: FEN + eval + UCI (the math model)\n"
        "  " C_YLW "--mode sym" C_RST "    Symbolic:  ASCII board + Unicode pieces (default)\n"
        "  " C_YLW "--mode gui" C_RST "    Graphical: launch Python tkinter board\n"
        "  " C_YLW "--depth N" C_RST "     Search depth, 1-8 (default 4)\n"
        "  " C_YLW "--play white" C_RST "  Human plays White (default)\n"
        "  " C_YLW "--play black" C_RST "  Human plays Black\n"
        "  " C_YLW "--auto" C_RST "        Engine vs Engine\n"
        "  " C_YLW "--fen \"...\"" C_RST "  Start from custom FEN\n"
        "  " C_YLW "--help" C_RST "        This message\n\n"
        C_DIM "  Moves: P1-P8 (pawns by file) · KL/KR (knights) · B BL/BR · RL/RR · Q · K" C_RST "\n"
        C_DIM "  Also: O-O O-O-O castling · UCI (e2e4 g1f3 e7e8q) · quit" C_RST "\n\n");
}

int main(int argc, char **argv) {
    DispMode mode = MODE_SYM;
    int depth = 4, human_side = WHITE, engine_both = 0;
    const char *fen = START_FEN;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { print_help(); return 0; }
        if (!strcmp(argv[i], "--mode") && i+1 < argc) {
            i++;
            if (!strcmp(argv[i], "num")) mode = MODE_NUM;
            else if (!strcmp(argv[i], "sym")) mode = MODE_SYM;
            else if (!strcmp(argv[i], "gui")) mode = MODE_GUI;
            else if (!strcmp(argv[i], "pipe")) mode = MODE_PIPE;
        }
        if (!strcmp(argv[i], "--depth") && i+1 < argc) {
            depth = atoi(argv[++i]);
            if (depth < 1) depth = 1;
            if (depth > 8) depth = 8;
        }
        if (!strcmp(argv[i], "--play") && i+1 < argc) {
            i++;
            if (!strcmp(argv[i], "black")) human_side = BLACK;
        }
        if (!strcmp(argv[i], "--auto")) engine_both = 1;
        if (!strcmp(argv[i], "--fen") && i+1 < argc) fen = argv[++i];
    }

    if (mode == MODE_GUI) {
        // Resolve Python GUI path relative to binary
        const char *root = getenv("FLOWEROS_ROOT");
        char path[512];
        if (root) snprintf(path, sizeof path, "%s/games/chess_gui.py", root);
        else snprintf(path, sizeof path, "games/chess_gui.py");
        execlp("python3", "python3", path, NULL);
        fprintf(stderr, C_RED "✗ python3 not found. Use --mode sym instead." C_RST "\n");
        return 1;
    }

    if (mode == MODE_PIPE) { run_pipe(fen, depth); return 0; }

    printf("\n" C_MAG C_BLD
        "  ═══════════════════════════════════════\n"
        "    ♛  FlowerOS Chess  ♛\n"
        "  ═══════════════════════════════════════\n"
        C_RST "\n");

    run_game(mode, depth, human_side, engine_both, fen);
    return 0;
}
