#!/usr/bin/env bash
# FlowerOS MOTD Display System
# Auto-selects appropriate ASCII art based on terminal width

set -e

# Configuration
MOTD_DIR="${MOTD_DIR:-/home/clear/FlowerOS/motd/ascii-output}"
DEFAULT_MOTD="01"

# Get terminal width
get_terminal_width() {
    if [ -n "${COLUMNS}" ]; then
        echo "${COLUMNS}"
    else
        tput cols 2>/dev/null || echo "80"
    fi
}

# Select appropriate ASCII file based on terminal width
select_motd() {
    local motd_name="${1:-$DEFAULT_MOTD}"
    local width=$(get_terminal_width)
    local size

    if [ "$width" -lt 80 ]; then
        size="small"
    elif [ "$width" -lt 140 ]; then
        size="medium"
    else
        size="large"
    fi

    local motd_file="${MOTD_DIR}/${motd_name}-${size}.ascii"
    
    if [ -f "$motd_file" ]; then
        echo "$motd_file"
    else
        # Fallback to medium if specific size not found
        echo "${MOTD_DIR}/${motd_name}-medium.ascii"
    fi
}

# Display the MOTD
show_motd() {
    local motd_file=$(select_motd "$1")
    
    if [ -f "$motd_file" ]; then
        cat "$motd_file"
    else
        # Fallback message if no MOTD found
        echo ""
        echo "  ✿ FlowerOS ✿"
        echo "  Welcome to your terminal"
        echo ""
    fi
}

# Random MOTD from available options
show_random_motd() {
    # Find all unique MOTD base names (01, 02, etc.)
    local motd_files=($(ls ${MOTD_DIR}/*-medium.ascii 2>/dev/null | sed 's/-medium.ascii//' | xargs -n1 basename))
    
    if [ ${#motd_files[@]} -eq 0 ]; then
        show_motd "$DEFAULT_MOTD"
        return
    fi
    
    local random_index=$((RANDOM % ${#motd_files[@]}))
    show_motd "${motd_files[$random_index]}"
}

# System information display
show_system_info() {
    local uptime_str=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    local users=$(who | wc -l)
    local load=$(uptime | awk -F'load average:' '{print $2}')
    
    echo ""
    echo "  System: $(hostname)"
    echo "  Uptime: $uptime_str"
    echo "  Users:  $users logged in"
    echo "  Load:   $load"
    echo ""
}

# Main execution
main() {
    case "${1:-show}" in
        random)
            show_random_motd
            ;;
        info)
            show_system_info
            ;;
        list)
            echo "Available MOTD images:"
            ls ${MOTD_DIR}/*-medium.ascii 2>/dev/null | sed 's/-medium.ascii//' | xargs -n1 basename | sort -u
            ;;
        *)
            show_motd "$1"
            ;;
    esac
}

main "$@"
