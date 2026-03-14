#!/usr/bin/env bash
# FlowerOS v1.2.1 - Visual Output Wrapper
# Automatically switches to visual output after batch calculations
set -eu

# Colors
r='\033[31m' g='\033[32m' y='\033[33m' b='\033[34m' m='\033[35m' c='\033[36m' z='\033[0m'

# Check if visual binary exists
VISUAL_BIN="./visual"
[[ -x ./visual.exe ]] && VISUAL_BIN="./visual.exe"

if [[ ! -x "$VISUAL_BIN" ]]; then
  echo -e "${r}✗${z} Visual binary not found. Build first:"
  echo "  gcc -O2 -std=c11 -Wall -Wextra -o visual lib/visual.c"
  exit 1
fi

# Visual mode switch (default: auto)
VISUAL_MODE="${FLOWEROS_VISUAL:-auto}"

# Function: Run command and visualize output
visualize_command() {
  local cmd="$1"
  local output_file=$(mktemp)
  
  echo -e "${c}➜${z} Running: $cmd"
  
  # Execute command
  eval "$cmd" > "$output_file" 2>&1
  local exit_code=$?
  
  # Show output
  cat "$output_file"
  
  # If command succeeded and visual mode enabled, show visualization
  if [[ $exit_code -eq 0 ]] && [[ "$VISUAL_MODE" != "off" ]]; then
    echo ""
    echo -e "${m}━━━ Visual Summary ━━━${z}"
    
    # Auto-detect best visualization based on output
    if grep -q "test.*pass\|success" "$output_file"; then
      # Test results - bar chart
      $VISUAL_BIN bar
    elif grep -q "building\|compiling" "$output_file"; then
      # Build progress
      $VISUAL_BIN progress
    else
      # Default: demo all visualizations
      $VISUAL_BIN demo
    fi
  fi
  
  rm -f "$output_file"
  return $exit_code
}

# Main
case "${1:-help}" in
  help)
    echo "FlowerOS Visual Output System"
    echo ""
    echo "Usage:"
    echo "  visualize.sh <command>        Run command with visual output"
    echo "  visualize.sh demo             Show visualization demo"
    echo "  visualize.sh build            Build with visualization"
    echo "  visualize.sh test             Test with visualization"
    echo ""
    echo "Environment:"
    echo "  FLOWEROS_VISUAL=auto          Auto-detect (default)"
    echo "  FLOWEROS_VISUAL=on            Always show visual"
    echo "  FLOWEROS_VISUAL=off           Disable visual"
    ;;
  
  demo)
    $VISUAL_BIN demo
    ;;
  
  build)
    visualize_command "bash build-v1.2.sh"
    ;;
  
  test)
    visualize_command "bash stress-test.sh"
    ;;
  
  *)
    visualize_command "$*"
    ;;
esac
