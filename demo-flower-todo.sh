#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS To-Do Notepad Demo
#  Walks through every command of flower-todo
# ═══════════════════════════════════════════════════════════════════════════

clear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODO="$SCRIPT_DIR/tools/flower-todo.sh"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║         🌸 FlowerOS To-Do Notepad Demo 🌸                                 ║"
echo "║              Task 1/8 — every petal accounted for                         ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
sleep 1

echo -e "\033[33m═══ HELP ═══\033[0m"
bash "$TODO" help
sleep 2

echo -e "\033[33m═══ ADDING TASKS ═══\033[0m"
bash "$TODO" add "Design pastel color palette for GPU shaders"
sleep 0.5
bash "$TODO" add "Wire broker named-pipe IPC (tier 4)"
sleep 0.5
bash "$TODO" add "Write unit tests for node_discovery.cpp"
sleep 0.5
bash "$TODO" add "Update README with Tier 4 architecture notes"
sleep 1

echo ""
echo -e "\033[33m═══ LISTING ═══\033[0m"
bash "$TODO" list
sleep 2

echo -e "\033[33m═══ MARKING DONE ═══\033[0m"
bash "$TODO" done 1
bash "$TODO" done 3
sleep 1

echo ""
echo -e "\033[33m═══ LIST AFTER DONE ═══\033[0m"
bash "$TODO" list
sleep 2

echo -e "\033[33m═══ UNDO ═══\033[0m"
bash "$TODO" undo 3
sleep 1

echo -e "\033[33m═══ REMOVE ═══\033[0m"
bash "$TODO" rm 4
sleep 1

echo ""
echo -e "\033[33m═══ FINAL STATE ═══\033[0m"
bash "$TODO" list
sleep 1

echo -e "\033[33m═══ CLEANUP ═══\033[0m"
bash "$TODO" clear
echo ""

echo -e "\033[36m✿ Demo complete.\033[0m"
echo -e "\033[245mUsage:  bash tools/flower-todo.sh <command> [args]\033[0m"
echo -e "\033[245mPowerShell:  powershell -File tools\\flower-todo.ps1 <command> [args]\033[0m"
echo ""
