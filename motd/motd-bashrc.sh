#!/usr/bin/env bash
# FlowerOS MOTD Integration for ~/.bashrc
# Add this to your .bashrc for automatic MOTD display

# FlowerOS MOTD Configuration
export FLOWEROS_MOTD_ENABLED=${FLOWEROS_MOTD_ENABLED:-1}
export FLOWEROS_MOTD_DIR="${HOME}/FlowerOS/motd/ascii-output"
export FLOWEROS_MOTD_SCRIPT="${HOME}/FlowerOS/motd/show-motd.sh"

# MOTD display function
floweros_motd() {
    if [ "$FLOWEROS_MOTD_ENABLED" != "1" ]; then
        return
    fi
    
    if [ ! -f "$FLOWEROS_MOTD_SCRIPT" ]; then
        return
    fi
    
    # Only show on interactive shells
    if [[ $- == *i* ]]; then
        bash "$FLOWEROS_MOTD_SCRIPT" random
    fi
}

# Auto-display MOTD on new shell (unless disabled)
if [ -z "$FLOWEROS_NO_AUTO_MOTD" ]; then
    floweros_motd
fi

# Manual MOTD commands
alias motd='bash "${FLOWEROS_MOTD_SCRIPT}" random'
alias motd-info='bash "${FLOWEROS_MOTD_SCRIPT}" info'
alias motd-list='bash "${FLOWEROS_MOTD_SCRIPT}" list'
alias motd-off='export FLOWEROS_MOTD_ENABLED=0'
alias motd-on='export FLOWEROS_MOTD_ENABLED=1'

# Show specific MOTD by number
motd-show() {
    if [ -z "$1" ]; then
        echo "Usage: motd-show <number>"
        echo "Example: motd-show 01"
        return 1
    fi
    bash "${FLOWEROS_MOTD_SCRIPT}" "$1"
}

export -f motd-show
