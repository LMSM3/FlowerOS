"""
scorer.py — Lain RVC voice-model scoring engine
1–5 scale across seven categories, persisted as JSON.
"""

import json
import os
from datetime import datetime

CATEGORIES = [
    "speech_clarity",
    "pitch_accuracy",
    "singing_stability",
    "natural_tone",
    "consonant_sharpness",
    "artifacts_noise",
    "overall_resemblance",
]

CATEGORY_LABELS = {
    "speech_clarity":       "Speech Clarity",
    "pitch_accuracy":       "Pitch Accuracy",
    "singing_stability":    "Singing Stability",
    "natural_tone":         "Natural Tone",
    "consonant_sharpness":  "Consonant Sharpness",
    "artifacts_noise":      "Artifacts / Noise",
    "overall_resemblance":  "Overall Resemblance / Style",
}

MODELS = ["v1", "v2", "v3.1", "arisu"]
CLIPS  = ["A", "B", "C"]
CLIP_LABELS = {"A": "Speech", "B": "Singing", "C": "Mixed"}

SCORE_FILE = os.path.join(os.path.dirname(__file__), "scores.json")


def _empty_card():
    return {cat: None for cat in CATEGORIES}


def load_scores():
    if os.path.exists(SCORE_FILE):
        with open(SCORE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    scores = {}
    for m in MODELS:
        scores[m] = {}
        for c in CLIPS:
            scores[m][c] = _empty_card()
    return scores


def save_scores(scores):
    payload = {"updated": datetime.now().isoformat(), "scores": scores}
    with open(SCORE_FILE, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def set_score(scores, model, clip, category, value):
    if value is not None and not (1 <= value <= 5):
        raise ValueError("Score must be 1–5 or None")
    scores[model][clip][category] = value


def cell_average(scores, model, clip):
    vals = [v for v in scores[model][clip].values() if v is not None]
    return round(sum(vals) / len(vals), 2) if vals else None


def model_average(scores, model):
    vals = []
    for c in CLIPS:
        vals.extend(v for v in scores[model][c].values() if v is not None)
    return round(sum(vals) / len(vals), 2) if vals else None


def summary_table(scores):
    rows = []
    for m in MODELS:
        row = {"model": m}
        for c in CLIPS:
            row[c] = cell_average(scores, m, c)
        row["avg"] = model_average(scores, m)
        rows.append(row)
    return rows
