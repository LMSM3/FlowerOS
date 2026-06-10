#!/usr/bin/env python3
"""
matrix_runner.py — batch test-matrix executor for Lain RVC models

Expects input clips to exist somewhere (--input-dir) and copies / renames
them into the output folder tree so the scorer GUI can find them.

Usage:
    python matrix_runner.py --input-dir ./raw_clips

Folder layout produced:
    output/
      test_v1/    A_speech.wav   B_singing.wav   C_mixed.wav
      test_v2/    A_speech.wav   B_singing.wav   C_mixed.wav
      test_v3_1/  A_speech.wav   B_singing.wav   C_mixed.wav
      test_arisu/ A_speech.wav   B_singing.wav   C_mixed.wav
"""

import argparse
import json
import os
import shutil

HERE       = os.path.dirname(os.path.abspath(__file__))
MODEL_JSON = os.path.join(HERE, "models.json")
OUTPUT_DIR = os.path.join(HERE, "output")

FOLDER_MAP = {
    "v1":    "test_v1",
    "v2":    "test_v2",
    "v3.1":  "test_v3_1",
    "arisu": "test_arisu",
}

CLIP_FILES = {
    "A": "A_speech.wav",
    "B": "B_singing.wav",
    "C": "C_mixed.wav",
}

# Recommended test order (from spec)
TEST_ORDER = [
    ("v2",    "A", "speech specialist"),
    ("v1",    "B", "older singing baseline"),
    ("v3.1",  "B", "improved singing model"),
    ("arisu", "A", "wildcard — speech"),
    ("arisu", "B", "wildcard — singing"),
]


def ensure_dirs():
    for folder in FOLDER_MAP.values():
        os.makedirs(os.path.join(OUTPUT_DIR, folder), exist_ok=True)


def distribute_clips(input_dir):
    """Copy raw input clips into every model's output folder."""
    ensure_dirs()
    found = 0
    for clip_key, fname in CLIP_FILES.items():
        src = os.path.join(input_dir, fname)
        if not os.path.isfile(src):
            print(f"  [skip] {fname} not found in {input_dir}")
            continue
        for model_key, folder in FOLDER_MAP.items():
            dst = os.path.join(OUTPUT_DIR, folder, fname)
            shutil.copy2(src, dst)
            print(f"  [copy] {fname} -> {folder}/")
            found += 1
    return found


def print_matrix():
    with open(MODEL_JSON, "r", encoding="utf-8") as f:
        meta = json.load(f)

    print("\n╔══════════════════════════════════════════════╗")
    print("║    Lain RVC — Fast Test Matrix               ║")
    print("╠══════════════════════════════════════════════╣")
    print("║  Clip A : speech          A_speech.wav       ║")
    print("║  Clip B : clean singing   B_singing.wav      ║")
    print("║  Clip C : mixed           C_mixed.wav        ║")
    print("╠══════════════════════════════════════════════╣")

    print("║  Recommended run order:                      ║")
    for i, (m, c, reason) in enumerate(TEST_ORDER, 1):
        line = f"║   {i}. {m:<8} clip {c}  — {reason}"
        print(f"{line:<47}║")

    print("╠══════════════════════════════════════════════╣")
    header = f"║  {'Model':<10} {'Speech':>7} {'Singing':>8} {'Pitch':>6}  Notes"
    print(f"{header:<47}║")
    print("║  " + "─" * 43 + " ║")
    for mk, info in meta["models"].items():
        bs = info["baseline_scores"]
        sp = bs["speech_clarity"]  or "?"
        sg = bs["singing_stability"] or "?"
        pt = bs["pitch_accuracy"] or "?"
        line = f"║  {info['short']:<10} {sp:>7} {sg:>8} {pt:>6}  {info['notes']}"
        print(f"{line:<47}║")

    print("╚══════════════════════════════════════════════╝\n")

    # file status
    print("Output folder status:")
    for model_key, folder in FOLDER_MAP.items():
        d = os.path.join(OUTPUT_DIR, folder)
        wavs = [f for f in os.listdir(d) if f.endswith(".wav")] if os.path.isdir(d) else []
        status = ", ".join(wavs) if wavs else "(empty)"
        print(f"  {folder}/  {status}")
    print()


def main():
    parser = argparse.ArgumentParser(description="Lain RVC test-matrix runner")
    parser.add_argument("--input-dir", type=str, default=None,
                        help="Directory containing raw A/B/C wav clips to distribute")
    parser.add_argument("--status", action="store_true",
                        help="Just print the matrix and folder status")
    args = parser.parse_args()

    if args.status or args.input_dir is None:
        print_matrix()
        if args.input_dir is None and not args.status:
            print("Tip: pass --input-dir <path> to distribute clips into output folders.")
        return

    print(f"Distributing clips from {args.input_dir} ...")
    n = distribute_clips(args.input_dir)
    print(f"Done — {n} file(s) copied.\n")
    print_matrix()


if __name__ == "__main__":
    main()
