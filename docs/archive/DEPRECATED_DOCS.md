# FlowerOS - Deprecated Documentation Index

**Last Updated:** February 07, 2026

This file tracks deprecated documentation that should no longer be referenced.

---

## ❌ Deprecated Files (To Be Removed)

### v0.x Documentation (Pre-Stable)
- None currently (v1.0 was first stable release)

### v1.0 Documentation (Superseded)
- `compile.ps1` → Use `build_native.ps1` or `build-v1.2.sh`
- Any references to manual `pipefail` handling

### Build Scripts (Legacy but Functional)
- ⚠️ `build.sh` - Still works but use `build-v1.2.sh` for multi-distro
- ⚠️ `install.sh` - Still works but use `install-v1.2.sh` for zsh support

---

## ✅ Current Documentation (Use These)

### Quick Start
- `QUICKSTART_v3.md` ← **Primary quick start guide**
- `README.md` ← Traditional documentation
- `CLI_SYNTAX_v1.2.1.md` ← Official CLI reference

### Technical
- `CHANGELOG_v1.2.1.md` ← Current version changes
- `ARCHITECTURE.md` ← System design
- `TROUBLESHOOTING.md` ← Issue resolution
- `FEATURES.md` ← Feature documentation

### Version Summaries
- `VERSION_SUMMARY_v1.1.md` ← v1.1 summary
- `VISUAL_SUMMARY.md` ← v1.0 visual summary

---

## 🔄 Migration Guide

### From v1.0/1.1 → v1.2.1

**Old:**
```bash
bash build.sh
bash install.sh
```

**New (Recommended):**
```bash
bash build-v1.2.sh      # Multi-distro aware
bash install-v1.2.sh    # Bash/Zsh aware
```

**Note:** Old syntax still works! No breaking changes.

---

## 📅 Deprecation Timeline

- **v1.2.1** (Current): All legacy scripts still supported
- **v1.3.0** (Planned): May remove `compile.ps1` references
- **v2.0.0** (Future): May require v1.2+ syntax

---

## 🗑️ Safe to Delete

None yet. All documentation is still relevant.
