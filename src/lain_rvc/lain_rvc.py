#!/usr/bin/env python3
"""
lain_rvc.py — Interactive 9-tile (+ Arisu wildcard column) voice-model scorer
FlowerOS subsystem  •  Lain RVC Voice Model Evaluation

Layout
──────
             v1          v2         v3.1       Arisu
  Speech   [ tile ]    [ tile ]   [ tile ]   [ tile ]
  Singing  [ tile ]    [ tile ]   [ tile ]   [ tile ]
  Mixed    [ tile ]    [ tile ]   [ tile ]   [ tile ]

Each tile shows:
  • play button (if wav exists in output/<model>/)
  • seven 1–5 sliders (scoring categories)
  • cell average
  • "listen-for" hints from models.json

Sources
───────
HuggingFace : https://huggingface.co/KokoleKen/lain_model_RVC
GitHub      : https://github.com/SuCicada/lain-voice-models
"""

import json
import os
import sys
import tkinter as tk
from tkinter import ttk, messagebox

# ---------------------------------------------------------------------------
# paths
# ---------------------------------------------------------------------------
HERE       = os.path.dirname(os.path.abspath(__file__))
MODEL_JSON = os.path.join(HERE, "models.json")
OUTPUT_DIR = os.path.join(HERE, "output")

sys.path.insert(0, HERE)
from scorer import (
    CATEGORIES, CATEGORY_LABELS, MODELS, CLIPS, CLIP_LABELS,
    load_scores, save_scores, set_score, cell_average, summary_table,
)

# ---------------------------------------------------------------------------
# optional audio playback
# ---------------------------------------------------------------------------
_play_available = False
try:
    import winsound
    _play_available = True
except ImportError:
    pass

if not _play_available:
    try:
        import subprocess
        def _play_posix(path):
            subprocess.Popen(["aplay", "-q", path],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        _play_available = True
    except Exception:
        pass


def play_wav(path):
    if not os.path.isfile(path):
        return False
    try:
        if sys.platform == "win32":
            winsound.PlaySound(path, winsound.SND_FILENAME | winsound.SND_ASYNC)
        else:
            _play_posix(path)
        return True
    except Exception:
        return False


# ---------------------------------------------------------------------------
# load model metadata
# ---------------------------------------------------------------------------
with open(MODEL_JSON, "r", encoding="utf-8") as _f:
    META = json.load(_f)

MODEL_META = META["models"]
CLIP_META  = META["clips"]


def _wav_path(model_key, clip_key):
    folder_map = {"v1": "test_v1", "v2": "test_v2",
                  "v3.1": "test_v3_1", "arisu": "test_arisu"}
    fname = CLIP_META[clip_key]["file"]
    return os.path.join(OUTPUT_DIR, folder_map[model_key], fname)


# ---------------------------------------------------------------------------
# colour helpers
# ---------------------------------------------------------------------------
BG          = "#1a1a2e"
BG_TILE     = "#16213e"
BG_HEADER   = "#0f3460"
FG          = "#e0e0e0"
ACCENT      = "#e94560"
ACCENT_DIM  = "#533483"
BTN_BG      = "#0f3460"
SCORE_COLORS = {1: "#e94560", 2: "#e97345", 3: "#e9b545",
                4: "#87c38f", 5: "#45e980"}


# ===================================================================
# main application
# ===================================================================
class LainRVCApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Lain RVC — Voice Model Scorer")
        self.configure(bg=BG)
        self.minsize(960, 680)
        self.scores = load_scores()
        self._slider_vars = {}   # (model, clip, cat) -> IntVar
        self._avg_labels  = {}   # (model, clip) -> Label

        self._build_header()
        self._build_grid()
        self._build_footer()

    # ------------------------------------------------------------------
    # header
    # ------------------------------------------------------------------
    def _build_header(self):
        hdr = tk.Frame(self, bg=BG_HEADER, pady=6)
        hdr.pack(fill="x")
        tk.Label(hdr, text="🔊  Lain RVC Voice Model Scorer",
                 font=("Segoe UI", 14, "bold"), bg=BG_HEADER, fg=FG
                 ).pack(side="left", padx=12)
        tk.Label(hdr, text="independent subsystem  •  FlowerOS",
                 font=("Segoe UI", 9), bg=BG_HEADER, fg=ACCENT_DIM
                 ).pack(side="right", padx=12)

    # ------------------------------------------------------------------
    # 4-column × 3-row tile grid  (v1 · v2 · v3.1 · arisu) × (A · B · C)
    # ------------------------------------------------------------------
    def _build_grid(self):
        container = tk.Frame(self, bg=BG)
        container.pack(fill="both", expand=True, padx=8, pady=4)

        # column headers
        tk.Label(container, text="", bg=BG).grid(row=0, column=0, sticky="nsew")
        for ci, m in enumerate(MODELS):
            info = MODEL_META.get(m, MODEL_META.get(m.replace(".", "")))
            lbl_text = info["label"] if info else m
            tk.Label(container, text=lbl_text, font=("Segoe UI", 10, "bold"),
                     bg=BG_HEADER, fg=FG, padx=8, pady=4
                     ).grid(row=0, column=ci + 1, sticky="nsew", padx=2, pady=2)

        # row headers + tiles
        for ri, clip in enumerate(CLIPS):
            tk.Label(container, text=f"Clip {clip}\n{CLIP_LABELS[clip]}",
                     font=("Segoe UI", 10, "bold"), bg=BG_HEADER, fg=FG,
                     padx=6, pady=4
                     ).grid(row=ri + 1, column=0, sticky="nsew", padx=2, pady=2)
            for ci, model in enumerate(MODELS):
                tile = self._make_tile(container, model, clip)
                tile.grid(row=ri + 1, column=ci + 1,
                          sticky="nsew", padx=2, pady=2)

        # let columns stretch equally
        for c in range(len(MODELS) + 1):
            container.columnconfigure(c, weight=1)
        for r in range(len(CLIPS) + 1):
            container.rowconfigure(r, weight=1)

    # ------------------------------------------------------------------
    # single tile widget
    # ------------------------------------------------------------------
    def _make_tile(self, parent, model, clip):
        frame = tk.Frame(parent, bg=BG_TILE, bd=1, relief="groove",
                         padx=6, pady=4)

        # --- play button ---
        wav = _wav_path(model, clip)
        wav_exists = os.path.isfile(wav)
        btn_text = "▶  Play" if wav_exists else "—  no wav"
        btn = tk.Button(frame, text=btn_text, font=("Segoe UI", 9),
                        bg=BTN_BG, fg=FG, activebackground=ACCENT,
                        state="normal" if wav_exists else "disabled",
                        command=lambda p=wav: play_wav(p))
        btn.pack(fill="x", pady=(0, 4))

        # --- score sliders ---
        for cat in CATEGORIES:
            row = tk.Frame(frame, bg=BG_TILE)
            row.pack(fill="x", pady=1)
            tk.Label(row, text=CATEGORY_LABELS[cat], font=("Segoe UI", 7),
                     bg=BG_TILE, fg=FG, width=18, anchor="w").pack(side="left")

            var = tk.IntVar(value=self.scores[model][clip].get(cat) or 0)
            self._slider_vars[(model, clip, cat)] = var

            scale = ttk.Scale(row, from_=0, to=5, variable=var,
                              length=90,
                              command=lambda v, m=model, c=clip, ca=cat:
                                  self._on_slide(m, c, ca))
            scale.pack(side="left", padx=2)

            val_lbl = tk.Label(row, textvariable=var, font=("Segoe UI", 8, "bold"),
                               bg=BG_TILE, fg=ACCENT, width=2)
            val_lbl.pack(side="left")

        # --- cell average label ---
        avg = cell_average(self.scores, model, clip)
        avg_text = f"avg {avg}" if avg else "—"
        avg_lbl = tk.Label(frame, text=avg_text, font=("Segoe UI", 9, "bold"),
                           bg=BG_TILE, fg=ACCENT)
        avg_lbl.pack(pady=(4, 0))
        self._avg_labels[(model, clip)] = avg_lbl

        # --- listen-for hints (tooltip-style) ---
        meta = MODEL_META.get(model, MODEL_META.get(model.replace(".", "")))
        if meta and meta.get("listen_for"):
            hints = "\n".join(f"• {h}" for h in meta["listen_for"])
            hint_lbl = tk.Label(frame, text=hints, font=("Segoe UI", 7),
                                bg=BG_TILE, fg="#888888", justify="left",
                                wraplength=180)
            hint_lbl.pack(anchor="w", pady=(2, 0))

        return frame

    # ------------------------------------------------------------------
    # slider callback
    # ------------------------------------------------------------------
    def _on_slide(self, model, clip, category):
        raw = self._slider_vars[(model, clip, category)].get()
        value = raw if raw >= 1 else None
        set_score(self.scores, model, clip, category, value)
        # refresh cell average
        avg = cell_average(self.scores, model, clip)
        self._avg_labels[(model, clip)].config(
            text=f"avg {avg}" if avg else "—")

    # ------------------------------------------------------------------
    # footer: save / summary / test-order
    # ------------------------------------------------------------------
    def _build_footer(self):
        foot = tk.Frame(self, bg=BG, pady=4)
        foot.pack(fill="x")

        tk.Button(foot, text="💾  Save Scores", font=("Segoe UI", 10, "bold"),
                  bg=ACCENT, fg="white", activebackground="#c33",
                  command=self._save).pack(side="left", padx=12)

        tk.Button(foot, text="📋  Summary", font=("Segoe UI", 10),
                  bg=BTN_BG, fg=FG, command=self._show_summary
                  ).pack(side="left", padx=4)

        tk.Button(foot, text="📖  Test Order", font=("Segoe UI", 10),
                  bg=BTN_BG, fg=FG, command=self._show_test_order
                  ).pack(side="left", padx=4)

        tk.Button(foot, text="🏆  Recommendations", font=("Segoe UI", 10),
                  bg=BTN_BG, fg=FG, command=self._show_recommendations
                  ).pack(side="left", padx=4)

        tk.Button(foot, text="🧠  AI Analyze", font=("Segoe UI", 10),
                  bg=ACCENT_DIM, fg=FG, command=self._ai_analyze
                  ).pack(side="left", padx=4)

        self._ai_status_lbl = tk.Label(foot, text="", font=("Segoe UI", 8),
                                        bg=BG, fg="#888888")
        self._ai_status_lbl.pack(side="right", padx=8)
        self._refresh_ai_status()

    def _refresh_ai_status(self):
        try:
            bridge_path = os.path.normpath(
                os.path.join(HERE, "..", "..", "..", "AI", "experimental"))
            sys.path.insert(0, bridge_path)
            from models.voice_bridge import VoiceBridge
            b = VoiceBridge()
            name = b.status()["dispatcher"]["active_backend"]
            self._ai_status_lbl.config(text=f"⚡ backend: {name}")
            b.release()
        except Exception:
            self._ai_status_lbl.config(text="⚡ backend: offline")

    def _ai_analyze(self):
        try:
            bridge_path = os.path.normpath(
                os.path.join(HERE, "..", "..", "..", "AI", "experimental"))
            sys.path.insert(0, bridge_path)
            from models.voice_bridge import VoiceBridge
            with VoiceBridge() as bridge:
                bridge.load()
                results = bridge.batch_analyze(OUTPUT_DIR)
            if results:
                self.scores = load_scores()
                for (m, c) in self._avg_labels:
                    avg = cell_average(self.scores, m, c)
                    self._avg_labels[(m, c)].config(
                        text=f"avg {avg}" if avg else "—")
                    for cat in CATEGORIES:
                        val = self.scores[m][c].get(cat) or 0
                        self._slider_vars[(m, c, cat)].set(val)
                messagebox.showinfo("AI Analyze",
                    f"Analyzed {len(results)} clip(s).\n"
                    f"Scores written and refreshed.")
            else:
                messagebox.showwarning("AI Analyze",
                    "No wav files found in output folders.\n"
                    "Place clips first, then analyze.")
        except Exception as exc:
            messagebox.showerror("AI Analyze",
                f"Inference failed:\n{exc}\n\n"
                "Ensure AI/experimental is available.")

    def _save(self):
        save_scores(self.scores)
        messagebox.showinfo("Saved", f"Scores saved to\n{os.path.basename(os.path.dirname(__file__))}/scores.json")

    def _show_summary(self):
        rows = summary_table(self.scores)
        lines = [f"{'Model':<10} {'Speech':>7} {'Singing':>8} {'Mixed':>7} {'Avg':>6}"]
        lines.append("─" * 42)
        for r in rows:
            def f(v): return f"{v:5.1f}" if v else "  —  "
            lines.append(f"{r['model']:<10} {f(r['A']):>7} {f(r['B']):>8} {f(r['C']):>7} {f(r['avg']):>6}")
        messagebox.showinfo("Score Summary", "\n".join(lines))

    def _show_test_order(self):
        order = META.get("test_order", [])
        lines = ["Recommended test order:\n"]
        for i, step in enumerate(order, 1):
            lines.append(f"  {i}. {step['model']}  on  clip {step['clip']}  "
                         f"— {step['reason']}")
        messagebox.showinfo("Test Order", "\n".join(lines))

    def _show_recommendations(self):
        rec = META.get("recommendations", {})
        conc = META.get("conclusions", {})
        lines = ["Conclusions:\n"]
        for k, v in conc.items():
            lines.append(f"  {k.replace('_', ' ').title()}: {v}")
        lines.append("\nPractical recommendations:\n")
        for k, v in rec.items():
            lines.append(f"  {k.replace('_', ' ')} → {v}")
        messagebox.showinfo("Recommendations", "\n".join(lines))


# ===================================================================
if __name__ == "__main__":
    app = LainRVCApp()
    app.mainloop()
