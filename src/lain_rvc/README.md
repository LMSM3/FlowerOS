# Lain RVC — Voice Model Scorer
**FlowerOS subsystem** • independent project — will merge with version code eventually

Interactive 9-tile evaluation tool for comparing Lain RVC voice models.

## Sources
| Source | Link |
|---|---|
| HuggingFace | https://huggingface.co/KokoleKen/lain_model_RVC |
| GitHub | https://github.com/SuCicada/lain-voice-models |
| Engine | RVC (Retrieval-based Voice Conversion) / so-vits-svc-4.0 |

## Models

| Model | Type | Notes |
|---|---|---|
| **v1** | Singing | Original singing baseline |
| **v2** | Speech | Conversational, no pitch — good for speech, bad for singing |
| **v3.1** | Singing | Improved singing + `.index` file — best singing candidate |
| **Arisu v1.1** | Wildcard | Alternate voice by @minotaurox0832 (YouTube) |

## Quick Scores (baseline)

| Model | Speech | Singing | Pitch | Notes |
|---|---|---|---|---|
| v1 | 3 | 4 | 4 | Original singing baseline |
| v2 | 5 | 1 | 1 | Good for speech, bad for singing |
| v3.1 | 4 | 5 | 5 | Best singing candidate |
| Arisu v1.1 | ? | ? | ? | Compare by ear |

## Scoring Categories (1–5 scale)
1. Speech Clarity
2. Pitch Accuracy
3. Singing Stability
4. Natural Tone
5. Consonant Sharpness
6. Artifacts / Noise
7. Overall Resemblance / Style

## Recommended Test Order
1. **v2** on speech clip — speech specialist
2. **v1** on singing clip — older singing baseline
3. **v3.1** on same singing clip — improved singing model
4. **Arisu** on both speech and singing — wildcard

## What to Listen For

### v1
- Stable vowels
- Decent melodic tracking
- Whether it gets fuzzy on higher notes

### v2
- Natural spoken phrasing
- Whether melody collapses into monotone
- Whether it sounds dead when forced to sing

### v3.1
- Stronger pitch retention
- Smoother sustained notes
- Better transitions between notes
- Whether the `.index` improves timbre consistency

### Arisu
- Whether the timbre is cleaner or more expressive
- Whether it handles feminine/bright tone better
- Whether it breaks under strong pitch movement

## Conclusions
- **Best for speech:** v2
- **Best for singing:** v3.1
- **Baseline singing comparison:** v1
- **Alternate stylistic model:** Arisu

## Usage

### Launch the 9-tile scorer GUI
```bash
python lain_rvc.py
```

### Distribute test clips into output folders
```bash
python matrix_runner.py --input-dir ./raw_clips
```

### View test matrix status
```bash
python matrix_runner.py --status
```

## Output Folder Layout
```
output/
  test_v1/      A_speech.wav  B_singing.wav  C_mixed.wav
  test_v2/      A_speech.wav  B_singing.wav  C_mixed.wav
  test_v3_1/    A_speech.wav  B_singing.wav  C_mixed.wav
  test_arisu/   A_speech.wav  B_singing.wav  C_mixed.wav
```

## File Structure
```
FlowerOS/src/lain_rvc/
  __init__.py          subsystem marker
  models.json          model metadata, clips, test order, recommendations
  scorer.py            scoring engine (load/save/compute)
  lain_rvc.py          interactive 9-tile tkinter GUI
  matrix_runner.py     batch clip distributor + status printer
  scores.json          (generated) persisted scores
  README.md            this file
  output/              test output wav folders
```
