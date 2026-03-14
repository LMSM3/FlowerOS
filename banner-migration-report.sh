#!/usr/bin/env bash
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  FlowerOS Banner Library Migration Tool
#  Scans codebase and reports files needing conversion to lib/banners.sh
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/banners.sh"

clear

fos_banner_title "ðŸ“Š FlowerOS Banner Library Migration Report" "Finding hand-rolled banners in codebase"

echo ""
echo -e "${_FOS_CYAN}Scanning all .sh files for hand-rolled banners...${_FOS_RESET}"
echo ""

# Files to scan (excluding lib/banners.sh itself)
FILES_WITH_BOXES=()
FILES_WITH_COLORS=()
ALREADY_CONVERTED=()

# Scan for box-drawing characters
while IFS= read -r -d '' file; do
    rel_path="${file#$SCRIPT_DIR/}"
    
    # Skip the banner library itself
    [[ "$rel_path" == "lib/banners.sh" ]] && continue
    
    # Check if already sources lib/banners.sh
    if grep -q "source.*lib/banners.sh" "$file" 2>/dev/null; then
        ALREADY_CONVERTED+=("$rel_path")
        continue
    fi
    
    # Check for box-drawing characters (â•” â•— â•š â• â• â•‘)
    if grep -q "[â•”â•—â•šâ•â•â•‘]" "$file" 2>/dev/null; then
        box_count=$(grep -o "[â•”â•—â•šâ•]" "$file" 2>/dev/null | wc -l)
        FILES_WITH_BOXES+=("$rel_path:$box_count")
    fi
    
    # Check for manual color codes like RED='\033[31m'
    if grep -qE "(RED|GREEN|YELLOW|CYAN|RESET)=.*\\\\033\[" "$file" 2>/dev/null; then
        FILES_WITH_COLORS+=("$rel_path")
    fi
done < <(find "$SCRIPT_DIR" -name "*.sh" -type f -print0 2>/dev/null)

# Report
fos_banner_section "MIGRATION STATUS" "$_FOS_GREEN"

echo -e "${_FOS_GREEN}âœ“ Already using lib/banners.sh:${_FOS_RESET} ${#ALREADY_CONVERTED[@]} files"
if [ ${#ALREADY_CONVERTED[@]} -gt 0 ]; then
    for file in "${ALREADY_CONVERTED[@]}"; do
        echo "  â€¢ $file"
    done
fi
echo ""

fos_banner_section "FILES NEEDING CONVERSION" "$_FOS_YELLOW"

echo -e "${_FOS_YELLOW}âš  Files with hand-rolled boxes (â•”â•â•—):${_FOS_RESET} ${#FILES_WITH_BOXES[@]} files"
if [ ${#FILES_WITH_BOXES[@]} -gt 0 ]; then
    # Sort by box count (descending)
    printf '%s\n' "${FILES_WITH_BOXES[@]}" | sort -t: -k2 -nr | while IFS=: read -r file count; do
        printf "  â€¢ %-50s [%2d boxes]\n" "$file" "$count"
    done
fi
echo ""

echo -e "${_FOS_CYAN}â„¹ Files with manual color definitions:${_FOS_RESET} ${#FILES_WITH_COLORS[@]} files"
if [ ${#FILES_WITH_COLORS[@]} -gt 0 ]; then
    for file in "${FILES_WITH_COLORS[@]}"; do
        echo "  â€¢ $file"
    done
fi
echo ""

fos_banner_section "CONVERSION PATTERNS" "$_FOS_MAGENTA"

echo "Common patterns to replace:"
echo ""
echo "1. Manual box banners:"
echo -e "   ${_FOS_DIM}echo -e \"\${CYAN}â•”â•â•â•...â•â•â•â•—\${RESET}\"${_FOS_RESET}"
echo "   â†’  fos_banner_box \"Title\""
echo ""

echo "2. Section dividers:"
echo -e "   ${_FOS_DIM}echo -e \"\${YELLOW}â•â•â•â•â•â•â•...â•â•â•â•â•â•â•\${RESET}\"${_FOS_RESET}"
echo "   â†’  fos_banner_section \"Text\" \"\$_FOS_YELLOW\""
echo ""

echo "3. Header lines:"
echo -e "   ${_FOS_DIM}echo -e \"\${CYAN}â•â•â• TITLE â•â•â•\${RESET}\"${_FOS_RESET}"
echo "   â†’  fos_banner_header \"TITLE\" \"\$_FOS_CYAN\""
echo ""

echo "4. Color definitions:"
echo -e "   ${_FOS_DIM}RED='\\033[31m'${_FOS_RESET}"
echo "   â†’  (remove, use \$_FOS_RED from lib/banners.sh)"
echo ""

echo "5. Status messages:"
echo -e "   ${_FOS_DIM}echo -e \"\${GREEN}âœ“ Success\${RESET}\"${_FOS_RESET}"
echo "   â†’  fos_status_ok \"Success\""
echo ""

fos_banner_section "RECOMMENDED ACTION" "$_FOS_GREEN"

echo "For each file listed above:"
echo ""
echo "1. Add banner library source at top:"
echo -e "   ${_FOS_DIM}SCRIPT_DIR=\"\\\$(cd \\\"\\\$(dirname \\\"\${BASH_SOURCE[0]}\\\")" && pwd)\"${_FOS_RESET}"
echo -e "   ${_FOS_DIM}source \"\${SCRIPT_DIR}/lib/banners.sh\"${_FOS_RESET}"
echo ""

echo "2. Remove manual color definitions"
echo "3. Replace hand-rolled boxes with fos_banner_* functions"
echo "4. Replace color codes:"
echo "   \${RED}   â†’ \${_FOS_RED}"
echo "   \${GREEN} â†’ \${_FOS_GREEN}"
echo "   etc."
echo ""

fos_banner_section "PRIORITY FILES" "$_FOS_RED"

echo "High-priority files (>3 boxes):"
echo ""

# Show files with most boxes
printf '%s\n' "${FILES_WITH_BOXES[@]}" | sort -t: -k2 -nr | head -10 | while IFS=: read -r file count; do
    if [ "$count" -gt 3 ]; then
        printf "  ${_FOS_RED}ðŸ”¥${_FOS_RESET} %-50s [%2d boxes]\n" "$file" "$count"
    fi
done

echo ""

fos_tagline
echo -e "${_FOS_DIM}[Report complete. Ready to migrate banners.]${_FOS_RESET}"
echo ""
