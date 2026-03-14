#!/usr/bin/env python3
"""
FlowerOS Chess GUI — tkinter board  (games/chess_gui.py)

Launches flower-chess --mode pipe as a subprocess and renders the board
in a tkinter window.  Click a square to select a piece, click another
to move.  The engine replies automatically.

Requires: python3 + tkinter (included with most Python installs).
"""

import subprocess
import sys
import os
import tkinter as tk
from tkinter import messagebox

SQ_SIZE = 64
BOARD_PX = SQ_SIZE * 8

# FlowerOS pastel palette
LIGHT_SQ = "#e8dff5"   # lavender
DARK_SQ  = "#c3aed6"   # muted purple
HL_SQ    = "#ffe0a6"   # warm highlight
W_COLOR  = "#5bcefa"   # mint-cyan (white pieces)
B_COLOR  = "#d19fd8"   # soft magenta (black pieces)
BG_COLOR = "#1e1e2e"   # dark background

PIECE_CHARS = {
    'P': '♙', 'N': '♘', 'B': '♗', 'R': '♖', 'Q': '♕', 'K': '♔',
    'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛', 'k': '♚',
}


class ChessGUI:
    def __init__(self, master, engine_path):
        self.master = master
        master.title("FlowerOS Chess")
        master.configure(bg=BG_COLOR)
        master.resizable(False, False)

        self.canvas = tk.Canvas(master, width=BOARD_PX, height=BOARD_PX,
                                bg=BG_COLOR, highlightthickness=0)
        self.canvas.pack(padx=8, pady=8)
        self.canvas.bind("<Button-1>", self.on_click)

        self.status = tk.Label(master, text="Starting engine...",
                               fg=W_COLOR, bg=BG_COLOR,
                               font=("Consolas", 11))
        self.status.pack(pady=(0, 8))

        self.board = {}       # {sq_str: piece_char}  e.g. {"e2": "P"}
        self.legal = []       # ["e2e4", ...]
        self.selected = None  # "e2" or None
        self.human_turn = True

        # Start engine subprocess
        self.proc = subprocess.Popen(
            [engine_path, "--mode", "pipe", "--depth", "4"],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, bufsize=1)

        self.master.after(100, self.read_engine)

    # ── Engine communication ────────────────────────────────────────

    def send(self, cmd):
        self.proc.stdin.write(cmd + "\n")
        self.proc.stdin.flush()

    def read_engine(self):
        while True:
            line = self.proc.stdout.readline().strip()
            if not line:
                break

            if line.startswith("pos "):
                self.parse_fen(line[4:])

            elif line.startswith("legal"):
                parts = line.split()
                self.legal = parts[1:] if len(parts) > 1 else []
                self.human_turn = True
                self.draw_board()
                side = "White" if " w " in self._last_fen else "Black"
                self.status.config(text=f"{side} to move  ·  {len(self.legal)} legal moves")
                return  # wait for user click

            elif line.startswith("eval"):
                pass  # displayed in status later

            elif line.startswith("bestmove "):
                mv = line.split()[1]
                self.status.config(text=f"Engine plays: {mv}")
                self.send(f"move {mv}")
                self.master.after(200, self.read_engine)
                return

            elif line.startswith("gameover"):
                result = line[9:]
                self.draw_board()
                self.status.config(text=f"Game over: {result}")
                messagebox.showinfo("FlowerOS Chess", f"Game over: {result}")
                return

            elif line == "ready":
                continue
            else:
                break

        self.master.after(50, self.read_engine)

    # ── FEN → board dict ────────────────────────────────────────────

    def parse_fen(self, fen):
        self._last_fen = fen
        self.board = {}
        parts = fen.split()
        rows = parts[0].split("/")
        for ri, row in enumerate(rows):
            rank = 8 - ri
            file_idx = 0
            for ch in row:
                if ch.isdigit():
                    file_idx += int(ch)
                else:
                    f = chr(ord('a') + file_idx)
                    sq = f"{f}{rank}"
                    self.board[sq] = ch
                    file_idx += 1

    # ── Drawing ─────────────────────────────────────────────────────

    def draw_board(self):
        self.canvas.delete("all")
        for r in range(8):
            for f in range(8):
                x0 = f * SQ_SIZE
                y0 = (7 - r) * SQ_SIZE
                sq = chr(ord('a') + f) + str(r + 1)
                dark = (r + f) % 2 == 1
                color = DARK_SQ if dark else LIGHT_SQ

                if self.selected == sq:
                    color = HL_SQ
                elif self.selected and any(
                    m.startswith(self.selected) and m[2:4] == sq
                    for m in self.legal
                ):
                    color = HL_SQ

                self.canvas.create_rectangle(
                    x0, y0, x0 + SQ_SIZE, y0 + SQ_SIZE,
                    fill=color, outline="")

                pc = self.board.get(sq)
                if pc:
                    ch = PIECE_CHARS.get(pc, "?")
                    fc = W_COLOR if pc.isupper() else B_COLOR
                    self.canvas.create_text(
                        x0 + SQ_SIZE // 2, y0 + SQ_SIZE // 2,
                        text=ch, font=("Segoe UI Symbol", SQ_SIZE // 2),
                        fill=fc)

        # file/rank labels
        for f in range(8):
            self.canvas.create_text(
                f * SQ_SIZE + SQ_SIZE // 2, BOARD_PX - 4,
                text=chr(ord('a') + f), font=("Consolas", 8),
                fill="#888", anchor="s")
        for r in range(8):
            self.canvas.create_text(
                4, (7 - r) * SQ_SIZE + SQ_SIZE // 2,
                text=str(r + 1), font=("Consolas", 8),
                fill="#888", anchor="w")

    # ── Click handling ──────────────────────────────────────────────

    def on_click(self, event):
        if not self.human_turn:
            return
        f = event.x // SQ_SIZE
        r = 7 - event.y // SQ_SIZE
        if not (0 <= f < 8 and 0 <= r < 8):
            return
        sq = chr(ord('a') + f) + str(r + 1)

        if self.selected is None:
            if sq in self.board:
                self.selected = sq
                self.draw_board()
        else:
            uci = self.selected + sq
            # check promotion
            if any(m.startswith(uci) and len(m) == 5 for m in self.legal):
                uci += "q"  # auto-promote to queen
            if uci in self.legal or uci[:4] in [m[:4] for m in self.legal]:
                self.human_turn = False
                self.selected = None
                self.status.config(text=f"You play: {uci}")
                self.send(f"move {uci}")
                self.master.after(100, self.engine_turn)
            else:
                self.selected = sq if sq in self.board else None
                self.draw_board()

    def engine_turn(self):
        self.send("go")
        self.status.config(text="Engine thinking...")
        self.master.after(100, self.read_engine)

    def cleanup(self):
        try:
            self.send("quit")
            self.proc.terminate()
        except Exception:
            pass


def find_engine():
    """Resolve flower-chess binary (same order as shell scripts)."""
    candidates = [
        "/opt/floweros/bin/flower-chess",
        os.path.join(os.environ.get("FLOWEROS_ROOT", ""), "src", "flower-chess"),
        os.path.join(os.path.dirname(os.path.abspath(__file__)),
                     "..", "src", "flower-chess"),
    ]
    for c in candidates:
        if c and os.path.isfile(c) and os.access(c, os.X_OK):
            return c
    return None


if __name__ == "__main__":
    engine = find_engine()
    if not engine:
        print("flower-chess binary not found. Build it first:")
        print("  cd src && gcc -O2 -std=c11 -o flower-chess games/chess_engine.c")
        sys.exit(1)

    root = tk.Tk()
    gui = ChessGUI(root, engine)
    root.protocol("WM_DELETE_WINDOW", lambda: (gui.cleanup(), root.destroy()))
    root.mainloop()
