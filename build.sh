#!/usr/bin/env bash
# FlowerOS Advanced Build System
set -eu
# pipefail not supported in all bash versions (Git Bash on Windows)
set -o pipefail 2>/dev/null || true

# Load shared color library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"

main() {
  echo ""
  info "FlowerOS Advanced Build System"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Check for gcc
  check_gcc || exit 1
  echo ""
  
  # Build flags
  local CFLAGS="-O2 -std=c11 -Wall -Wextra -pedantic"
  local FEATURES=""
  
  # Feature detection
  if command -v tput >/dev/null 2>&1; then
    FEATURES="$FEATURES -DHAS_TERMCAP"
    ok "Feature: Terminal capabilities (tput)"
  fi
  
  if [[ -c /dev/urandom ]]; then
    FEATURES="$FEATURES -DHAS_URANDOM"
    ok "Feature: /dev/urandom"
  fi
  
  echo ""
  info "Compiling C subsystems..."
  echo ""
  
  # 1. Random picker (core)
  if [[ -f "src/utils/random.c" ]]; then
    info "[1/5] Building random (core line picker)..."
    gcc $CFLAGS $FEATURES -o random src/utils/random.c || die "Failed to compile random.c"
    ok "Built: random ($(du -h random | cut -f1))"
  else
    err "src/utils/random.c not found!"
  fi
  
  # 2. Animation player
  if [[ -f "src/utils/animate.c" ]]; then
    info "[2/5] Building animate (ASCII animation engine)..."
    gcc $CFLAGS $FEATURES -o animate src/utils/animate.c || die "Failed to compile animate.c"
    ok "Built: animate ($(du -h animate | cut -f1))"
  else
    echo "   ${y}⚠${z} src/utils/animate.c not found (skipping)"
  fi
  
  # 3. Banner generator
  if [[ -f "src/utils/banner.c" ]]; then
    info "[3/5] Building banner (dynamic banner generator)..."
    gcc $CFLAGS $FEATURES -o banner src/utils/banner.c || die "Failed to compile banner.c"
    ok "Built: banner ($(du -h banner | cut -f1))"
  else
    echo "   ${y}⚠${z} src/utils/banner.c not found (skipping)"
  fi
  
  # 4. Fortune system
  if [[ -f "src/utils/fortune.c" ]]; then
    info "[4/5] Building fortune (wisdom database)..."
    gcc $CFLAGS $FEATURES -o fortune src/utils/fortune.c || die "Failed to compile fortune.c"
    ok "Built: fortune ($(du -h fortune | cut -f1))"
  else
    echo "   ${y}⚠${z} src/utils/fortune.c not found (skipping)"
  fi
  
  # 5. Color tester
  if [[ -f "src/utils/colortest.c" ]]; then
    info "[5/5] Building colortest (terminal diagnostics)..."
    gcc $CFLAGS $FEATURES -o colortest src/utils/colortest.c || die "Failed to compile colortest.c"
    ok "Built: colortest ($(du -h colortest | cut -f1))"
  else
    echo "   ${y}⚠${z} src/utils/colortest.c not found (skipping)"
  fi
  
  echo ""
  info "Testing binaries..."
  echo ""
  
  # Test random
  if [[ -x ./random ]]; then
    local test_output
    test_output=$(./random . 2>/dev/null || echo "")
    if [[ -n "$test_output" ]]; then
      ok "random: ${test_output:0:40}..."
    else
      echo "   ${y}⚠${z} random: No output (needs .ascii/.txt files)"
    fi
  fi
  
  # Test animate
  if [[ -x ./animate ]]; then
    ok "animate: Ready (use: animate <file.anim>)"
  fi
  
  # Test banner
  if [[ -x ./banner ]]; then
    ok "banner: Ready (use: banner 'Text')"
  fi
  
  # 6. FlowerPublish (fp)
  if [[ -f "src/publish/fp.c" ]]; then
    info "[6] Building FlowerPublish (fp — LaTeX workflow)..."
    gcc $CFLAGS -o fp src/publish/fp.c || warn "Failed to compile fp.c (optional, skipping)"
    [[ -x ./fp ]] && ok "Built: fp ($(du -h fp | cut -f1))"
  else
    echo "   ${y}⚠${z} src/publish/fp.c not found (skipping)"
  fi

  # 7. flower-run — universal language runner + HPC dispatcher
  if [[ -f "src/runner/fos_runner.c" ]]; then
    info "[7] Building flower-run (universal runner: C/C++/Python/Julia/Rust/Go/…)..."
    gcc $CFLAGS -I src/ -o flower-run src/runner/fos_runner.c || \
      warn "Failed to compile flower-run (optional, skipping)"
    [[ -x ./flower-run ]] && ok "Built: flower-run ($(du -h flower-run | cut -f1))"
  fi

  # 8. flower-chess — terminal chess engine (num/sym/gui modes)
  if [[ -f "src/games/chess_engine.c" ]]; then
    info "[8] Building flower-chess (chess: alpha-beta + 3 display modes)..."
    gcc $CFLAGS -o flower-chess src/games/chess_engine.c || \
      warn "Failed to compile flower-chess (optional, skipping)"
    [[ -x ./flower-chess ]] && ok "Built: flower-chess ($(du -h flower-chess | cut -f1))"
  fi

  # 9. flower-colony — colony survival game
  if [[ -f "src/games/colony_engine.c" ]]; then
    info "[9] Building flower-colony (colony: hex grid + cadence production)..."
    gcc $CFLAGS -o flower-colony src/games/colony_engine.c || \
      warn "Failed to compile flower-colony (optional, skipping)"
    [[ -x ./flower-colony ]] && ok "Built: flower-colony ($(du -h flower-colony | cut -f1))"
  fi

  # 10. flower-td — tower defense game
  if [[ -f "src/games/td_engine.c" ]]; then
    info "[10] Building flower-td (tower defense: garden vs bugs)..."
    gcc $CFLAGS -o flower-td src/games/td_engine.c || \
      warn "Failed to compile flower-td (optional, skipping)"
    [[ -x ./flower-td ]] && ok "Built: flower-td ($(du -h flower-td | cut -f1))"
  fi

  # 11. flower-play — game launcher menu
  if [[ -f "src/games/play.c" ]]; then
    info "[11] Building flower-play (game launcher)..."
    gcc $CFLAGS -o flower-play src/games/play.c || \
      warn "Failed to compile flower-play (optional, skipping)"
    [[ -x ./flower-play ]] && ok "Built: flower-play ($(du -h flower-play | cut -f1))"
  fi

  # 12. Optional: Build network components (v1.3.X experimental)
  if [[ -d "network" ]] && [[ -f "network/Makefile" ]]; then
    echo ""
    if command -v g++ >/dev/null 2>&1; then
      info "Building network components (experimental)..."
      echo -e "  ${r}⚠  RED WARNING: Network features are EXPERIMENTAL${z}"
      (cd network && mkdir -p build && make all 2>&1) && \
        ok "Network: built (network/build/)" || \
        warn "Network build failed (optional, skipping)"
    else
      warn "g++ not found — skipping network build (install g++ for v1.3.X features)"
    fi
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  local core_count
  core_count=$(ls -1 random animate banner fortune colortest fp flower-run 2>/dev/null | wc -l)
  local net_count=0
  [[ -f "network/build/node_monitor" ]] && net_count=$(ls -1 network/build/node_monitor network/build/node_discovery network/build/terminal_node 2>/dev/null | wc -l)
  ok "Build complete! $core_count core binaries + $net_count network binaries ready"
  echo ""
}

main "$@"
