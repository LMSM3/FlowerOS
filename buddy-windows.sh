#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS - Buddy Window Manager
#  Automatically open/close multiple terminals for network testing
# ═══════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/banners.sh"

PID_FILE="/tmp/floweros_buddy_windows.pid"

# ═══════════════════════════════════════════════════════════════════════════
#  Detect Terminal Emulator
# ═══════════════════════════════════════════════════════════════════════════

detect_terminal() {
    if command -v gnome-terminal &> /dev/null; then
        echo "gnome-terminal"
    elif command -v konsole &> /dev/null; then
        echo "konsole"
    elif command -v xterm &> /dev/null; then
        echo "xterm"
    elif command -v xfce4-terminal &> /dev/null; then
        echo "xfce4-terminal"
    elif command -v tilix &> /dev/null; then
        echo "tilix"
    else
        echo "none"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Open Buddy Windows
# ═══════════════════════════════════════════════════════════════════════════

open_buddy_windows() {
    local terminal=$(detect_terminal)

    if [ "$terminal" == "none" ]; then
        fos_banner_error "No supported terminal emulator found"
        echo "Install one of: gnome-terminal, konsole, xterm, xfce4-terminal, tilix"
        exit 1
    fi

    echo -e "${_FOS_CYAN}Opening buddy windows with $terminal...${_FOS_RESET}"
    echo ""
    
    # Clear old PID file
    > "$PID_FILE"
    
    # Window 1: Master Node (port 7777)
    echo -e "${_FOS_GREEN}[1/3]${_FOS_RESET} Opening Master Node window (port 7777)..."
    case "$terminal" in
        gnome-terminal)
            gnome-terminal --title="FlowerOS Master Node (7777)" \
                          --geometry=80x24+0+0 \
                          -- bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Master Node (Port 7777)              ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                echo 'Initializing master node...'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_grow_tree buddy_test 2>/dev/null || echo 'Node initialized'
                echo ''
                echo 'Starting monitor...'
                echo 'Press Ctrl+C to stop'
                echo ''
                ./network/build/node_monitor 7777 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
            
        konsole)
            konsole --title="FlowerOS Master Node (7777)" \
                   --geometry 80x24+0+0 \
                   -e bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Master Node (Port 7777)              ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_grow_tree buddy_test 2>/dev/null || echo 'Node initialized'
                echo ''
                ./network/build/node_monitor 7777 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
            
        xterm|xfce4-terminal|tilix)
            $terminal -T "FlowerOS Master Node (7777)" \
                     -geometry 80x24+0+0 \
                     -e bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Master Node (Port 7777)              ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_grow_tree buddy_test 2>/dev/null || echo 'Node initialized'
                echo ''
                ./network/build/node_monitor 7777 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
    esac
    
    sleep 2
    
    # Window 2: Relay Node (port 7778)
    echo -e "${_FOS_GREEN}[2/3]${_FOS_RESET} Opening Relay Node window (port 7778)..."
    case "$terminal" in
        gnome-terminal)
            gnome-terminal --title="FlowerOS Relay Node (7778)" \
                          --geometry=80x24+600+0 \
                          -- bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Relay Node (Port 7778)               ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                echo 'Initializing relay node...'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_join_garden 127.0.0.1 2>/dev/null || echo 'Relay initialized'
                echo ''
                echo 'Starting monitor...'
                echo 'Press Ctrl+C to stop'
                echo ''
                ./network/build/node_monitor 7778 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
            
        konsole)
            konsole --title="FlowerOS Relay Node (7778)" \
                   --geometry 80x24+600+0 \
                   -e bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Relay Node (Port 7778)               ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_join_garden 127.0.0.1 2>/dev/null || echo 'Relay initialized'
                echo ''
                ./network/build/node_monitor 7778 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
            
        xterm|xfce4-terminal|tilix)
            $terminal -T "FlowerOS Relay Node (7778)" \
                     -geometry 80x24+600+0 \
                     -e bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Relay Node (Port 7778)               ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_join_garden 127.0.0.1 2>/dev/null || echo 'Relay initialized'
                echo ''
                ./network/build/node_monitor 7778 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
    esac
    
    sleep 2
    
    # Window 3: Worker Node (port 7779)
    echo -e "${_FOS_GREEN}[3/3]${_FOS_RESET} Opening Worker Node window (port 7779)..."
    case "$terminal" in
        gnome-terminal)
            gnome-terminal --title="FlowerOS Worker Node (7779)" \
                          --geometry=80x24+1200+0 \
                          -- bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Worker Node (Port 7779)              ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                echo 'Initializing worker node...'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_join_garden 127.0.0.1 2>/dev/null || echo 'Worker initialized'
                echo ''
                echo 'Starting monitor...'
                echo 'Press Ctrl+C to stop'
                echo ''
                ./network/build/node_monitor 7779 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
            
        konsole)
            konsole --title="FlowerOS Worker Node (7779)" \
                   --geometry 80x24+1200+0 \
                   -e bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Worker Node (Port 7779)              ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_join_garden 127.0.0.1 2>/dev/null || echo 'Worker initialized'
                echo ''
                ./network/build/node_monitor 7779 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
            
        xterm|xfce4-terminal|tilix)
            $terminal -T "FlowerOS Worker Node (7779)" \
                     -geometry 80x24+1200+0 \
                     -e bash -c "
                cd '$SCRIPT_DIR'
                echo '╔═══════════════════════════════════════════════════════╗'
                echo '║        FlowerOS Worker Node (Port 7779)              ║'
                echo '╚═══════════════════════════════════════════════════════╝'
                echo ''
                source lib/terminal_network.sh 2>/dev/null || true
                flower_join_garden 127.0.0.1 2>/dev/null || echo 'Worker initialized'
                echo ''
                ./network/build/node_monitor 7779 2>/dev/null || sleep infinity
            " &
            echo $! >> "$PID_FILE"
            ;;
    esac
    
    echo ""
    echo -e "${_FOS_GREEN}✓ All buddy windows opened!${_FOS_RESET}"
    echo ""
    echo "Windows:"
    echo "  [1] Master Node  - 127.0.0.1:7777 (left)"
    echo "  [2] Relay Node   - 127.0.0.1:7778 (center)"
    echo "  [3] Worker Node  - 127.0.0.1:7779 (right)"
    echo ""
    echo "To close all windows, run:"
    echo "  bash $0 close"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Close Buddy Windows
# ═══════════════════════════════════════════════════════════════════════════

close_buddy_windows() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${_FOS_YELLOW}No buddy windows to close${_FOS_RESET}"
        exit 0
    fi
    
    echo -e "${_FOS_CYAN}Closing buddy windows...${_FOS_RESET}"
    echo ""
    
    while read -r pid; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "Closing window (PID: $pid)"
            kill "$pid" 2>/dev/null || true
        fi
    done < "$PID_FILE"
    
    rm -f "$PID_FILE"
    
    echo ""
    echo -e "${_FOS_GREEN}✓ All buddy windows closed${_FOS_RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Status
# ═══════════════════════════════════════════════════════════════════════════

show_status() {
    if [ ! -f "$PID_FILE" ]; then
        echo "No buddy windows currently open"
        exit 0
    fi
    
    echo "Buddy windows status:"
    echo ""
    
    local count=0
    while read -r pid; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            count=$((count + 1))
            echo "  Window $count: Running (PID: $pid)"
        fi
    done < "$PID_FILE"
    
    if [ $count -eq 0 ]; then
        echo "  No active windows"
        rm -f "$PID_FILE"
    fi
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-open}" in
    open)
        open_buddy_windows
        ;;
    close)
        close_buddy_windows
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {open|close|status}"
        echo ""
        echo "Commands:"
        echo "  open    - Open buddy windows for network testing"
        echo "  close   - Close all buddy windows"
        echo "  status  - Show status of buddy windows"
        echo ""
        exit 1
        ;;
esac
