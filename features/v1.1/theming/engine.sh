#!/usr/bin/env bash
# FlowerOS Theme Engine (Bash/WSL)
# Universal theming system for bash terminals

set -eu
set -o pipefail 2>/dev/null || true

# Theme engine configuration
THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/themes" && pwd)"
CONFIG_FILE="$HOME/.floweros/theme.conf"
BACKUP_FILE="$HOME/.floweros/theme.backup.conf"

# Color conversion utilities
hex_to_ansi() {
    local hex="$1"
    hex="${hex#\#}"
    
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    
    printf "\033[38;2;%d;%d;%dm" "$r" "$g" "$b"
}

hex_to_ansi_bg() {
    local hex="$1"
    hex="${hex#\#}"
    
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    
    printf "\033[48;2;%d;%d;%dm" "$r" "$g" "$b"
}

# List available themes
list_themes() {
    [[ ! -d "$THEME_DIR" ]] && { echo "Theme directory not found"; return 1; }
    
    echo ""
    echo "Available Themes:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for theme_file in "$THEME_DIR"/*.json; do
        [[ ! -f "$theme_file" ]] && continue
        
        local name=$(basename "$theme_file" .json)
        local display_name=$(jq -r '.name' "$theme_file")
        local description=$(jq -r '.description' "$theme_file")
        
        printf "  \033[36m%-20s\033[0m %s\n" "$display_name" "$description"
    done
    
    echo ""
}

# Load theme
load_theme() {
    local theme_name="$1"
    local theme_file="$THEME_DIR/${theme_name}.json"
    
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: Theme '$theme_name' not found" >&2
        return 1
    fi
    
    # Validate JSON
    if ! jq empty "$theme_file" 2>/dev/null; then
        echo "Error: Invalid theme file" >&2
        return 1
    fi
    
    echo "$theme_file"
}

# Validate theme structure
validate_theme() {
    local theme_file="$1"
    
    local required=("name" "version" "colors" "terminal")
    for field in "${required[@]}"; do
        if ! jq -e ".$field" "$theme_file" >/dev/null 2>&1; then
            echo "Error: Theme missing required field: $field" >&2
            return 1
        fi
    done
    
    return 0
}

# Apply theme to bash
apply_theme_to_bash() {
    local theme_file="$1"
    
    echo ""
    echo -e "\033[36m🎨 Applying theme: $(jq -r '.name' "$theme_file")\033[0m"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Extract colors
    local fg=$(jq -r '.terminal.foreground' "$theme_file")
    local bg=$(jq -r '.terminal.background' "$theme_file")
    
    # Generate bash color configuration
    local config_dir=$(dirname "$CONFIG_FILE")
    [[ ! -d "$config_dir" ]] && mkdir -p "$config_dir"
    
    # Backup existing config
    [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    # Write theme config
    cat > "$CONFIG_FILE" <<EOF
# FlowerOS Theme Configuration
# Generated: $(date)
# Theme: $(jq -r '.name' "$theme_file")

FLOWEROS_THEME="$(basename "$theme_file" .json)"
FLOWEROS_THEME_VERSION="$(jq -r '.version' "$theme_file")"

# Terminal colors
export FLOWEROS_FG="$fg"
export FLOWEROS_BG="$bg"

# Syntax colors
export FLOWEROS_COLOR_COMMAND="$(jq -r '.colors.command' "$theme_file")"
export FLOWEROS_COLOR_STRING="$(jq -r '.colors.string' "$theme_file")"
export FLOWEROS_COLOR_COMMENT="$(jq -r '.colors.comment' "$theme_file")"
export FLOWEROS_COLOR_KEYWORD="$(jq -r '.colors.keyword' "$theme_file")"
export FLOWEROS_COLOR_VARIABLE="$(jq -r '.colors.variable' "$theme_file")"
export FLOWEROS_COLOR_OPERATOR="$(jq -r '.colors.operator' "$theme_file")"
export FLOWEROS_COLOR_NUMBER="$(jq -r '.colors.number' "$theme_file")"
export FLOWEROS_COLOR_PROMPT="$(jq -r '.colors.prompt' "$theme_file")"
export FLOWEROS_COLOR_PATH="$(jq -r '.colors.path' "$theme_file")"

# Apply colors to terminal (if supported)
if [[ -n "\${TERM}" ]] && command -v tput >/dev/null 2>&1; then
    # Set terminal colors using ANSI escape sequences
    printf "\033]10;%s\007" "$fg"  # foreground
    printf "\033]11;%s\007" "$bg"  # background
fi

# Custom prompt (if defined)
if command -v jq >/dev/null 2>&1 && jq -e '.prompt' "$theme_file" >/dev/null 2>&1; then
    export FLOWEROS_PROMPT_TEMPLATE="$(jq -r '.prompt.template' "$theme_file")"
fi
EOF
    
    echo "✓ Theme configuration written to: $CONFIG_FILE"
    
    # Generate prompt function
    if jq -e '.prompt' "$theme_file" >/dev/null 2>&1; then
        local prompt_file="$config_dir/prompt.sh"
        cat > "$prompt_file" <<'PROMPT_EOF'
# FlowerOS Custom Prompt

__floweros_prompt() {
    local last_status=$?
    local reset="\[\033[0m\]"
    
    # Color conversions (using theme colors)
    local prompt_color=$(hex_to_ansi "$FLOWEROS_COLOR_PROMPT")
    local path_color=$(hex_to_ansi "$FLOWEROS_COLOR_PATH")
    local error_color="\[\033[31m\]"
    local success_color="\[\033[32m\]"
    
    # Build prompt
    local status_indicator=""
    if [[ $last_status -eq 0 ]]; then
        status_indicator="${success_color}✓${reset}"
    else
        status_indicator="${error_color}✗${reset}"
    fi
    
    # Use template or default
    if [[ -n "${FLOWEROS_PROMPT_TEMPLATE:-}" ]]; then
        PS1="${status_indicator} ${prompt_color}${FLOWEROS_PROMPT_TEMPLATE}${reset} "
    else
        PS1="${status_indicator} ${path_color}\w${reset} ${prompt_color}❯${reset} "
    fi
}

PROMPT_COMMAND="__floweros_prompt"
PROMPT_EOF
        
        echo "✓ Custom prompt generated"
    fi
    
    echo ""
    echo -e "\033[35m✨ Theme applied successfully!\033[0m"
    echo ""
    echo "To activate in current session:"
    echo "  source $CONFIG_FILE"
    echo ""
    echo "To persist across sessions, add to ~/.bashrc:"
    echo "  echo 'source $CONFIG_FILE' >> ~/.bashrc"
    echo ""
}

# Show theme preview
show_theme_preview() {
    local theme_file="$1"
    
    echo ""
    echo -e "\033[36m╔════════════════════════════════════════════════╗\033[0m"
    printf "\033[36m║\033[0m  Theme Preview: %-30s\033[36m║\033[0m\n" "$(jq -r '.name' "$theme_file")"
    echo -e "\033[36m╚════════════════════════════════════════════════╝\033[0m"
    echo ""
    
    echo -e "\033[33mColors:\033[0m"
    jq -r '.colors | to_entries[] | "\(.key)=\(.value)"' "$theme_file" | while IFS='=' read -r name hex; do
        local color=$(hex_to_ansi "$hex")
        local reset="\033[0m"
        printf "  %-15s : %b█████████%b %s\n" "$name" "$color" "$reset" "$hex"
    done
    
    echo ""
    echo -e "\033[33mTerminal:\033[0m"
    echo "  Background  : $(jq -r '.terminal.background' "$theme_file")"
    echo "  Foreground  : $(jq -r '.terminal.foreground' "$theme_file")"
    
    if jq -e '.prompt' "$theme_file" >/dev/null 2>&1; then
        echo ""
        echo -e "\033[33mPrompt:\033[0m"
        echo "  Template    : $(jq -r '.prompt.template' "$theme_file")"
    fi
    
    echo ""
}

# Get current theme
get_current_theme() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "No theme configured"
        return 1
    fi
    
    source "$CONFIG_FILE"
    echo "${FLOWEROS_THEME:-unknown}"
}

# CLI interface
case "${1:-}" in
    list)
        list_themes
        ;;
    apply)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 apply <theme-name>"; exit 1; }
        theme_file=$(load_theme "$2")
        validate_theme "$theme_file" && apply_theme_to_bash "$theme_file"
        ;;
    preview)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 preview <theme-name>"; exit 1; }
        theme_file=$(load_theme "$2")
        show_theme_preview "$theme_file"
        ;;
    current)
        get_current_theme
        ;;
    *)
        echo "FlowerOS Theme Engine v1.1"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  list              List available themes"
        echo "  apply <name>      Apply theme"
        echo "  preview <name>    Preview theme"
        echo "  current           Show current theme"
        echo ""
        ;;
esac
