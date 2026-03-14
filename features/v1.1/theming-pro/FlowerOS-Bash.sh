#!/usr/bin/env bash
# FlowerOS Professional Bash Theme
# Advanced customization with git integration, smart prompts, and performance optimization

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Bash Theme Engine
# ═══════════════════════════════════════════════════════════════════════════

# Version
FLOWEROS_VERSION="1.1.1"
FLOWEROS_CONFIG_DIR="$HOME/.floweros"
FLOWEROS_THEME_FILE="$FLOWEROS_CONFIG_DIR/bash-theme.conf"

# ───────────────────────────────────────────────────────────────────────────
#  Color Definitions (True Color Support)
# ───────────────────────────────────────────────────────────────────────────

# Basic colors
C_RESET="\[\033[0m\]"
C_BOLD="\[\033[1m\]"
C_DIM="\[\033[2m\]"

# Foreground colors
C_BLACK="\[\033[30m\]"
C_RED="\[\033[31m\]"
C_GREEN="\[\033[32m\]"
C_YELLOW="\[\033[33m\]"
C_BLUE="\[\033[34m\]"
C_MAGENTA="\[\033[35m\]"
C_CYAN="\[\033[36m\]"
C_WHITE="\[\033[37m\]"
C_GRAY="\[\033[90m\]"

# Bright colors
C_BRIGHT_RED="\[\033[91m\]"
C_BRIGHT_GREEN="\[\033[92m\]"
C_BRIGHT_YELLOW="\[\033[93m\]"
C_BRIGHT_BLUE="\[\033[94m\]"
C_BRIGHT_MAGENTA="\[\033[95m\]"
C_BRIGHT_CYAN="\[\033[96m\]"
C_BRIGHT_WHITE="\[\033[97m\]"

# Symbols
SYMBOL_GIT_BRANCH="⎇"
SYMBOL_GIT_CLEAN="✓"
SYMBOL_GIT_DIRTY="±"
SYMBOL_PROMPT="❯"
SYMBOL_SUCCESS="✓"
SYMBOL_ERROR="✗"
SYMBOL_FLOWER="🌸"

# ───────────────────────────────────────────────────────────────────────────
#  Git Integration
# ───────────────────────────────────────────────────────────────────────────

__floweros_git_branch() {
    # Fast git branch detection
    git symbolic-ref --short HEAD 2>/dev/null || \
    git describe --tags --exact-match 2>/dev/null || \
    git rev-parse --short HEAD 2>/dev/null
}

__floweros_git_status() {
    # Check if we're in a git repo (fast check)
    git rev-parse --git-dir >/dev/null 2>&1 || return 1
    
    local branch=$(__floweros_git_branch)
    [[ -z "$branch" ]] && return 1
    
    # Check for changes (optimized)
    local status=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        status="${C_YELLOW}${SYMBOL_GIT_DIRTY}${C_RESET}"
    else
        status="${C_GREEN}${SYMBOL_GIT_CLEAN}${C_RESET}"
    fi
    
    echo -e "${C_GRAY}[${C_MAGENTA}${SYMBOL_GIT_BRANCH} ${branch}${C_GRAY} ${status}${C_GRAY}]${C_RESET}"
}

# ───────────────────────────────────────────────────────────────────────────
#  Smart Path Shortening
# ───────────────────────────────────────────────────────────────────────────

__floweros_short_path() {
    local path="${PWD/#$HOME/\~}"
    local max_length=50
    
    # If path is short enough, return as-is
    if [[ ${#path} -le $max_length ]]; then
        echo "$path"
        return
    fi
    
    # Shorten long paths intelligently
    local IFS='/'
    local parts=($path)
    local result=""
    
    # Keep first part (~ or /)
    if [[ "${parts[0]}" == "~" ]] || [[ "${parts[0]}" == "" ]]; then
        result="${parts[0]}"
        unset 'parts[0]'
    fi
    
    # Keep last 2 parts, abbreviate middle
    local count=${#parts[@]}
    if [[ $count -gt 3 ]]; then
        result="$result/.../$(basename "$(dirname "$PWD")")/$(basename "$PWD")"
    else
        result="$path"
    fi
    
    echo "$result"
}

# ───────────────────────────────────────────────────────────────────────────
#  Custom Prompt
# ───────────────────────────────────────────────────────────────────────────

__floweros_prompt_command() {
    local exit_code=$?
    
    # First line: user@host + path + git
    PS1=""
    
    # User@host
    PS1+="${C_CYAN}[${USER}@${HOSTNAME%%.*}]${C_RESET} "
    
    # Path (shortened)
    PS1+="${C_BLUE}$(__floweros_short_path)${C_RESET} "
    
    # Git status (if in repo)
    local git_status=$(__floweros_git_status)
    if [[ -n "$git_status" ]]; then
        PS1+="$git_status "
    fi
    
    # Newline
    PS1+="\n"
    
    # Second line: prompt character (color based on exit code)
    if [[ $exit_code -eq 0 ]]; then
        PS1+="${C_GREEN}${SYMBOL_PROMPT}${C_RESET} "
    else
        PS1+="${C_RED}${SYMBOL_PROMPT}${C_RESET} "
    fi
}

# Set prompt command
PROMPT_COMMAND="__floweros_prompt_command"

# ───────────────────────────────────────────────────────────────────────────
#  Enhanced LS Colors
# ───────────────────────────────────────────────────────────────────────────

# Modern LS_COLORS configuration
export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34'

# Aliases for ls
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi

alias ll='ls -lAh'
alias la='ls -A'
alias l='ls -CF'

# ───────────────────────────────────────────────────────────────────────────
#  Git Aliases
# ───────────────────────────────────────────────────────────────────────────

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# ───────────────────────────────────────────────────────────────────────────
#  Enhanced Navigation
# ───────────────────────────────────────────────────────────────────────────

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Quick directory stack
alias d='dirs -v'
alias pd='pushd'
alias po='popd'

# ───────────────────────────────────────────────────────────────────────────
#  Useful Functions
# ───────────────────────────────────────────────────────────────────────────

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find files by name
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directories by name
fd() {
    find . -type d -iname "*$1*" 2>/dev/null
}

# Grep with color and line numbers
search() {
    grep -rn --color=auto "$1" .
}

# Quick server (Python)
serve() {
    local port="${1:-8000}"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port"
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port"
    else
        echo "Python not found"
    fi
}

# ───────────────────────────────────────────────────────────────────────────
#  History Configuration
# ───────────────────────────────────────────────────────────────────────────

# Large history
HISTSIZE=10000
HISTFILESIZE=20000

# Avoid duplicates
HISTCONTROL=ignoreboth:erasedups

# Append to history, don't overwrite
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Correct minor typos in cd
shopt -s cdspell

# ───────────────────────────────────────────────────────────────────────────
#  Enhanced Tab Completion
# ───────────────────────────────────────────────────────────────────────────

# Case-insensitive completion
bind 'set completion-ignore-case on'

# Show all completions immediately
bind 'set show-all-if-ambiguous on'

# Color completion
bind 'set colored-stats on'

# Mark directories with /
bind 'set mark-directories on'
bind 'set mark-symlinked-directories on'

# ───────────────────────────────────────────────────────────────────────────
#  Performance Optimizations
# ───────────────────────────────────────────────────────────────────────────

# Cache git status for performance
export GIT_TERMINAL_PROMPT=1
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1

# ───────────────────────────────────────────────────────────────────────────
#  Installation Functions
# ───────────────────────────────────────────────────────────────────────────

floweros_install_bash_theme() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  FlowerOS Professional Bash Theme Installer"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Ensure config directory
    mkdir -p "$FLOWEROS_CONFIG_DIR"
    
    # Check if already installed
    if grep -q "FlowerOS Theme" "$HOME/.bashrc" 2>/dev/null; then
        echo "⚠ FlowerOS theme already installed in ~/.bashrc"
        echo ""
        return 1
    fi
    
    # Backup bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✓ Backed up ~/.bashrc"
    fi
    
    # Get theme file path
    local theme_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    # Add to bashrc
    cat >> "$HOME/.bashrc" <<EOF

# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Theme v${FLOWEROS_VERSION}
#  Loaded: $(date '+%Y-%m-%d %H:%M:%S')
# ═══════════════════════════════════════════════════════════════════════════

source "$theme_path"

EOF
    
    echo "✓ Installed to ~/.bashrc"
    echo ""
    echo "✨ Run 'source ~/.bashrc' or open a new terminal"
    echo ""
}

floweros_uninstall_bash_theme() {
    if [[ ! -f "$HOME/.bashrc" ]]; then
        echo "No ~/.bashrc found"
        return 1
    fi
    
    # Remove FlowerOS section
    sed -i.bak '/# ═.*FlowerOS Theme/,/^$/d' "$HOME/.bashrc"
    
    echo "✓ FlowerOS theme removed from ~/.bashrc"
    echo "  Backup saved as ~/.bashrc.bak"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────
#  Welcome Message
# ───────────────────────────────────────────────────────────────────────────

floweros_welcome() {
    echo ""
    echo -e "${C_CYAN}╔═══════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  ${SYMBOL_FLOWER} ${C_MAGENTA}FlowerOS Bash Theme v${FLOWEROS_VERSION}${C_RESET}$(printf '%*s' $((40 - ${#FLOWEROS_VERSION})) '')${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╚═══════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "  ${C_GRAY}Professional theming for bash & WSL${C_RESET}"
    echo -e "  ${C_GRAY}Type ${C_YELLOW}floweros_install_bash_theme${C_GRAY} to install${C_RESET}"
    echo ""
}

# Show welcome if directly sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ -z "$PS1" ]]; then
    :  # Don't show welcome in non-interactive shells
else
    # Only show once per session
    if [[ -z "$FLOWEROS_THEME_LOADED" ]]; then
        export FLOWEROS_THEME_LOADED=1
        # Don't show welcome if already in bashrc (avoid duplicate)
        if ! grep -q "FlowerOS Theme" "$HOME/.bashrc" 2>/dev/null; then
            floweros_welcome
        fi
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════
#  End of FlowerOS Bash Theme
# ═══════════════════════════════════════════════════════════════════════════
