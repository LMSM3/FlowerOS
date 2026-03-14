# FlowerOS v1.1 - Professional Theming

## Philosophy

**Less is more.** FlowerOS v1.1 provides two professional, minimal themes:

- **Light**: Clean, minimal light theme for bright environments
- **Grey**: Professional grey theme for reduced eye strain

Complex theming (Flower Garden, etc.) is reserved for the future **Garden** web-based installation system.

## Usage

### PowerShell
```powershell
# Load theme module
. features/v1.1/themes/theme.ps1

# Apply theme
Set-FlowerOSTheme -Theme light
Set-FlowerOSTheme -Theme grey

# Check current
Get-FlowerOSTheme
```

### Bash/WSL
```bash
# Apply theme
bash features/v1.1/themes/theme.sh light
bash features/v1.1/themes/theme.sh grey

# Check current
bash features/v1.1/themes/theme.sh get
```

## Design Principles

1. **Professional** - Clean, business-appropriate
2. **Minimal** - Only essential colors
3. **Accessible** - High contrast, readable
4. **Non-intrusive** - Doesn't distract from work

## Future: Garden (Web-Based)

Complex theming features planned for Garden:
- Visual theme builder
- Custom color schemes
- Community themes
- Theme preview/testing
- One-click installation

*"Simplicity is the ultimate sophistication." - Leonardo da Vinci*
