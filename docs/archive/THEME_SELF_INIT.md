## FlowerOS Theme System - Self-Initialization

## Overview

The FlowerOS theme system automatically initializes on first use, creating all necessary configuration files and default themes for new users. This prevents errors when theme data is missing.

---

## Problem Solved

**Issue:** First-time users or users with missing theme data would encounter errors when FlowerOS tried to load themes.

**Solution:** Automatic self-initialization with error recovery:
- Detects first-run condition
- Creates user directories
- Generates default configuration
- Installs default themes
- Rebuilds cache
- Silent recovery if data is missing

---

## Architecture

### Components

1. **`theme_self_init.sh`** - Core initialization system
2. **`theme_loader.sh`** - Integration wrapper
3. **User config** - `~/.floweros/theme.conf`
4. **User themes** - `~/.floweros/theme/*.theme`
5. **Theme cache** - `~/.floweros/theme.cache`

### Flow Diagram

```
User opens terminal
        ↓
.bashrc sources .flowerrc
        ↓
.flowerrc sources theme_loader.sh
        ↓
theme_loader checks if initialized
        ↓
    ┌───────────────┐
    │ First run?    │
    └───────────────┘
         ↓       ↓
        Yes      No
         ↓       ↓
    Initialize  Validate
         ↓       ↓
    Create      Check
    defaults    files
         ↓       ↓
         └───┬───┘
             ↓
        Load theme
             ↓
        Ready!
```

---

## First-Time Initialization

### What Happens

When a new user first runs FlowerOS:

1. **Detection** - Checks for `~/.floweros/.first_run_complete` marker
2. **Directory Creation** - Creates `~/.floweros/` and subdirectories
3. **Config Generation** - Writes `theme.conf` with defaults
4. **Theme Installation** - Creates 4 default themes:
   - Garden (green, natural)
   - Spring (light, fresh)
   - Autumn (warm, golden)
   - Night (cool, moonlit)
5. **Cache Building** - Creates theme cache for fast loading
6. **Marker Creation** - Writes first-run marker to prevent re-initialization

### Silent Operation

The initialization runs silently in the background. Users see:
- No errors
- Smooth theme loading
- Default garden theme

---

## Configuration File

### Location

`~/.floweros/theme.conf`

### Auto-Generated Content

```bash
# FlowerOS Theme Configuration
# Generated automatically on first run

# Active theme (garden, spring, autumn, night)
FLOWEROS_THEME_ACTIVE="garden"

# Unicode symbols enabled (true/false)
FLOWEROS_THEME_UNICODE="true"

# Color palette (1=botanical, 2=flowers)
FLOWEROS_THEME_PALETTE="1"

# Theme features
FLOWEROS_THEME_COLORS="true"
FLOWEROS_THEME_GRADIENT="true"
FLOWEROS_THEME_ANIMATIONS="true"

# ASCII art preferences
FLOWEROS_THEME_ASCII_STYLE="pastel"
FLOWEROS_THEME_ASCII_WIDTH="120"

# Welcome message
FLOWEROS_THEME_WELCOME="true"
FLOWEROS_THEME_MOTD="true"

# Advanced
FLOWEROS_THEME_DEBUG="false"
FLOWEROS_THEME_CACHE_ENABLED="true"
```

---

## Default Themes

### Garden Theme (Default)

```bash
name="Garden"
description="Natural garden colors - green leaves, colorful flowers"

color_primary="\033[32m"      # Green (leaves)
color_secondary="\033[35m"    # Magenta (flowers)
color_accent="\033[36m"       # Cyan (water)
color_warning="\033[33m"      # Yellow (sun)
color_error="\033[31m"        # Red (caution)
color_success="\033[92m"      # Bright green (growth)
color_info="\033[34m"         # Blue (sky)
color_muted="\033[90m"        # Gray (stones)

symbol_seed="🌱"
symbol_leaf="🌿"
symbol_flower="✿"
symbol_bloom="🌸"
symbol_tree="🌳"
```

### Spring Theme

Light, fresh colors of new growth and cherry blossoms.

### Autumn Theme

Warm golden and red colors of fall harvest.

### Night Theme

Cool moonlit colors for night garden ambiance.

---

## Error Recovery

### Missing Data Detection

The system validates theme data on every load:

```bash
flower_theme_validate_data() {
    # Check theme directory
    # Check user config directory
    # Check theme config file
    # Return status
}
```

### Auto-Recovery

If validation fails:

```bash
if ! flower_theme_validate_data; then
    echo "🌱 Theme data missing - auto-initializing..."
    flower_theme_self_init "false" "false"
fi
```

### Recovery Scenarios

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| First-time user | No `.first_run_complete` | Full initialization |
| Missing config | No `theme.conf` | Generate defaults |
| Missing themes | No `.theme` files | Install defaults |
| Corrupted cache | Invalid cache | Rebuild cache |
| Partial install | Some files missing | Re-initialize |

---

## User Commands

### Check Theme Status

```bash
flower_theme_info
```

Output:
```
FlowerOS Theme System
════════════════════════════════════════
Config:  /home/user/.floweros/theme.conf
Themes:  /home/user/.floweros/theme
Cache:   /home/user/.floweros/theme.cache

Active theme: garden
Unicode:      true
Colors:       true
```

### List Available Themes

```bash
flower_theme_list
```

Output:
```
Available themes:
  • garden
  • spring
  • autumn
  • night
```

### Change Theme

```bash
flower_theme_set spring
```

Output:
```
✓ Theme set to: spring
  Reload shell to apply: source ~/.bashrc
```

### Reset to Defaults

```bash
flower_theme_reset
```

Output:
```
🌱 Resetting theme to defaults...
✓ Theme reset complete
```

### Force Re-Initialization

```bash
flower_theme_self_init true false
```

---

## Integration with FlowerOS

### .flowerrc Integration

Add to `.flowerrc`:

```bash
# Load theme system (with auto-initialization)
[[ -f "${FLOWEROS_LIB}/theme_loader.sh" ]] && source "${FLOWEROS_LIB}/theme_loader.sh"
```

### Load Order

1. `.bashrc` sources `.flowerrc`
2. `.flowerrc` sources `theme_loader.sh`
3. `theme_loader.sh` sources `theme_self_init.sh`
4. Auto-initialization runs if needed
5. Active theme loads
6. Theme variables exported

---

## Theme File Format

### Structure

```bash
# Theme metadata
name="Theme Name"
description="Theme description"
palette="1"  # 1=botanical, 2=flowers

# Color definitions
color_primary="\033[32m"
color_secondary="\033[35m"
# ... more colors

# Unicode symbols
symbol_seed="🌱"
symbol_leaf="🌿"
# ... more symbols
```

### Custom Themes

Users can create custom themes:

1. Create file: `~/.floweros/theme/mytheme.theme`
2. Copy template from existing theme
3. Modify colors and symbols
4. Set active: `flower_theme_set mytheme`

---

## Advanced Features

### Environment Variables

Set before loading FlowerOS:

```bash
# Override theme directory
export FLOWEROS_THEME_DIR="/custom/themes"

# Override user theme directory
export FLOWEROS_THEME_USER="/custom/user/themes"

# Disable auto-initialization
export FLOWEROS_THEME_NO_AUTO_INIT=1
```

### Debugging

Enable debug mode:

```bash
# In theme.conf
FLOWEROS_THEME_DEBUG="true"
```

Shows:
- Initialization steps
- File operations
- Theme loading
- Validation results

### Cache Management

```bash
# Rebuild cache manually
flower_theme_rebuild_cache

# Disable cache
# In theme.conf:
FLOWEROS_THEME_CACHE_ENABLED="false"
```

---

## Troubleshooting

### Theme Not Loading

**Symptom:** Default theme used instead of selected theme

**Solution:**
```bash
# Check theme exists
flower_theme_list

# Reset and try again
flower_theme_reset
flower_theme_set yourtheme
source ~/.bashrc
```

### Initialization Loop

**Symptom:** Initialization runs every time

**Solution:**
```bash
# Check marker file
ls -la ~/.floweros/.first_run_complete

# If missing, check permissions
chmod 755 ~/.floweros
flower_theme_mark_initialized
```

### Missing Colors

**Symptom:** No colors in terminal

**Solution:**
```bash
# Check terminal support
echo $TERM  # Should be xterm-256color

# Enable colors in config
# Edit ~/.floweros/theme.conf:
FLOWEROS_THEME_COLORS="true"
```

---

## Performance

### Initialization Time

- First run: ~0.5 seconds
- Subsequent loads: <0.1 seconds
- Cache hit: ~0.01 seconds

### File Operations

- Config write: 1 file
- Theme install: 4 files
- Cache rebuild: 1 file
- Total: 6 files created

### Memory Usage

- Theme system: ~2 KB
- Loaded theme: ~1 KB
- Total impact: negligible

---

## Security

### File Permissions

```
~/.floweros/              755 (user:user)
~/.floweros/theme.conf    644 (user:user)
~/.floweros/theme/*.theme 644 (user:user)
~/.floweros/theme.cache   644 (user:user)
~/.floweros/.first_run    644 (user:user)
```

### No Sudo Required

All operations run as user - no root privileges needed.

### Safe Defaults

- No network access
- No system modifications
- User-space only
- Fail-safe behavior

---

## Future Enhancements

### Planned Features

- [ ] Theme import/export
- [ ] Online theme repository
- [ ] Theme preview before apply
- [ ] Animated theme transitions
- [ ] Per-application themes
- [ ] Theme synchronization across machines
- [ ] Dark/light mode auto-switching
- [ ] Seasonal theme auto-rotation

---

## API Reference

### Functions

```bash
flower_theme_self_init [force] [quiet]
  # Initialize theme system
  # force: "true" to force re-init
  # quiet: "true" for silent operation

flower_theme_load <theme_name>
  # Load specific theme
  # Auto-recovers if data missing

flower_theme_validate_data
  # Check if theme data is valid
  # Returns: 0=valid, 1=invalid

flower_theme_is_first_run
  # Check if this is first run
  # Returns: 0=first run, 1=not first run

flower_theme_list
  # List available themes

flower_theme_set <theme_name>
  # Set active theme

flower_theme_reset
  # Reset to defaults (force re-init)

flower_theme_info
  # Show theme system information

flower_theme_rebuild_cache
  # Rebuild theme cache

flower_theme_mark_initialized
  # Mark initialization complete

flower_theme_generate_config
  # Generate default config

flower_theme_generate_defaults
  # Generate default theme files
```

---

## See Also

- `PERMANENT_INSTALL.md` - System installation
- `kernel/README_KERNEL.md` - Kernel documentation
- `UNIVERSAL_CAPABILITIES.md` - Compute system

---

**🌸 FlowerOS v1.3.0 - Theme System**  
*Auto-initializing garden themes* 🌱

**Every user gets a garden. Every terminal blooms with color.**
