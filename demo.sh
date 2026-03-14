#!/usr/bin/env bash
# FlowerOS System Demo - Shows all features
set -eu
set -o pipefail 2>/dev/null || true

# Load shared color library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"

echo ""
echo -e "${c}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${z}"
echo -e "${c}     ✿ FlowerOS Advanced System Demo ✿${z}"
echo -e "${c}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${z}"
echo ""

# Check if built
if [[ ! -x "./random" ]]; then
  echo -e "${y}⚠ Binaries not found. Building...${z}"
  bash build.sh
  echo ""
fi

# Demo 1: Random picker
echo -e "${m}[1/6] Random Line Picker${z}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "./random" ]]; then
  for i in {1..3}; do
    echo -ne "${g}✓${z} "
    ./random . 2>/dev/null || echo "(no .ascii/.txt files)"
    sleep 0.5
  done
else
  echo -e "${r}✗ random binary not found${z}"
fi
echo ""
sleep 1

# Demo 2: Banner generator
echo -e "${m}[2/6] Banner Generator${z}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "./banner" ]]; then
  echo "Simple style:"
  ./banner -s "FlowerOS"
  echo ""
  sleep 1
  
  echo "Flower style:"
  ./banner -f "Welcome"
  echo ""
  sleep 1
  
  echo "Gradient style:"
  ./banner -g "Rainbow"
  echo ""
  sleep 1
  
  echo "Box style:"
  ./banner -b "Message"
  echo ""
else
  echo -e "${r}✗ banner binary not found${z}"
  echo ""
fi
sleep 1

# Demo 3: Fortune system
echo -e "${m}[3/6] Fortune System${z}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "./fortune" ]]; then
  echo "Tech wisdom:"
  echo -ne "${g}  ➜${z} "
  ./fortune tech
  echo ""
  sleep 1
  
  echo "Flower quotes:"
  echo -ne "${g}  ➜${z} "
  ./fortune flower
  echo ""
  sleep 1
  
  echo "Zen wisdom:"
  echo -ne "${g}  ➜${z} "
  ./fortune zen
  echo ""
else
  echo -e "${r}✗ fortune binary not found${z}"
  echo ""
fi
sleep 1

# Demo 4: Color test (brief)
echo -e "${m}[4/6] Terminal Capabilities${z}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "./colortest" ]]; then
  echo "Basic colors:"
  for i in {31..36}; do
    echo -ne "\033[${i}m■\033[0m "
  done
  echo ""
  echo ""
  echo "Unicode flowers:"
  echo "✿ ❀ ❁ ✾ ⚘ ❊ ✽ ✻"
  echo ""
  echo -e "${y}ℹ${z} Run: ${c}./colortest${z} for full diagnostics"
else
  echo -e "${r}✗ colortest binary not found${z}"
fi
echo ""
sleep 1

# Demo 5: Animation (if available)
echo -e "${m}[5/6] Animation System${z}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "./animate" ]] && [[ -f "flower.anim" ]]; then
  echo -e "${g}✓${z} flower.anim available"
  echo -e "${g}✓${z} spin.anim available"
  echo ""
  echo "Run: ${c}./animate flower.anim${z} to play"
  echo "Format:"
  cat <<'EOF'
  #FPS=10
  #LOOP=1
  ---FRAME---
  <frame 1>
  ---FRAME---
  <frame 2>
EOF
else
  echo -e "${r}✗ animate binary or .anim files not found${z}"
fi
echo ""
sleep 1

# Demo 6: System info
echo -e "${m}[6/6] System Status${z}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

binaries=0
for bin in random animate banner fortune colortest; do
  if [[ -x "./$bin" ]]; then
    size=$(du -h "$bin" 2>/dev/null | cut -f1 || echo "?")
    echo -e "${g}✓${z} $bin ($size)"
    ((binaries++))
  else
    echo -e "${r}✗${z} $bin (not built)"
  fi
done

echo ""
data=0
for ext in ascii txt anim; do
  count=$(ls -1 "*.$ext" 2>/dev/null | wc -l)
  if ((count > 0)); then
    echo -e "${g}✓${z} .$ext files: $count"
    ((data+=count))
  fi
done

echo ""
echo -e "${c}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${z}"
echo -e "   ${g}$binaries${z} binaries | ${g}$data${z} data files"
echo -e "${c}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${z}"
echo ""
echo "Next steps:"
echo "  1. ${c}bash build.sh${z}       - Compile all"
echo "  2. ${c}bash install.sh${z}     - Install to ~/FlowerOS/"
echo "  3. ${c}source ~/.bashrc${z}    - Activate"
echo ""
echo "Or just: ${c}compile.bat${z} (Windows self-installer)"
echo ""
