#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  bin/flower-motd-inject-install.sh
#  Installs the Layer-1 shell injectors and Layer-2 Python provider package
#  to /usr/local/lib/floweros/motd/.
#
#  The Python package is intentionally isolated from all C and shell engine
#  code — it lives entirely under /usr/local/lib/floweros/motd/py/ and is
#  treated as an optional "web-installable" helper bundle.
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# ── .bashrc widget config helpers ──────────────────────────────────────
_write_widgets_rc() {
    printf "\n"
    printf "# BEGIN FlowerOS MOTD widgets\n"
    printf "# Uncomment to enable optional MOTD widgets:\n"
    printf "# export FLOWER_MOTD_RANDOM=1        # science fact\n"
    printf "# export FLOWER_RANDOM_KIND=mix      # element|chemical|plant|mix\n"
    printf "# export FLOWER_MOTD_WEATHER=1       # wttr.in weather\n"
    printf "# export FLOWER_WEATHER_LOC=''       # city name\n"
    printf "# export FLOWER_MOTD_STOCKS=1        # stock tickers\n"
    printf "# export FLOWER_STOCKS='AAPL,MSFT'  # tickers\n"
    printf "# export FLOWER_MOTD_NEWS=1          # RSS headlines\n"
    printf "# export FLOWER_NEWS_N=2             # count\n"
    printf "# export FLOWER_MOTD_NO_TD=1         # silence TD reminder\n"
    printf "# END FlowerOS MOTD widgets\n"
}

_bashrc_widgets_prompt() {
    local rcfile="$HOME/.bashrc"
    local has_block=0
    grep -qF "# BEGIN FlowerOS MOTD widgets" "$rcfile" 2>/dev/null && has_block=1 || true

    [[ -t 0 ]] || { printf "\n  (non-interactive \u2014 .bashrc step skipped)\n"; return 0; }

    printf "\n  %s\n" "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
    if (( has_block )); then
        printf "  FlowerOS widget config already exists in %s.\n" "$rcfile"
        printf "  [m]odify   append a fresh copy\n"
        printf "  [o]verwrite  remove existing and replace\n"
        printf "  [s]kip\n  > "
    else
        printf "  Write widget env-var config to %s?\n" "$rcfile"
        printf "  (All lines commented out \u2014 uncomment what you want)\n"
        printf "  [m]odify  [s]kip\n  > "
    fi

    local ans="s"
    read -r ans 2>/dev/null || ans="s"

    case "${ans,,}" in
        m|modify)
            if (( has_block )); then
                printf "  ! Already present \u2014 use [o]verwrite to replace.\n"
            else
                touch "$rcfile"
                _write_widgets_rc >> "$rcfile"
                printf "  \xe2\x9c\x93 Appended to %s\n" "$rcfile"
            fi
            ;;
        o|overwrite)
            touch "$rcfile"
            sed '/^# BEGIN FlowerOS MOTD widgets$/,/^# END FlowerOS MOTD widgets$/d' \
                "$rcfile" > "${rcfile}.fos.tmp" && mv "${rcfile}.fos.tmp" "$rcfile"
            _write_widgets_rc >> "$rcfile"
            printf "  \xe2\x9c\x93 Replaced widget config in %s\n" "$rcfile"
            ;;
        *)
            printf "  - Skipped. See widget env vars listed above.\n"
            ;;
    esac
    printf "  %s\n" "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
}

LIB="/usr/local/lib/floweros/motd"
INJ="$LIB/inject.d"
PY="$LIB/py"

sudo mkdir -p "$INJ" "$PY"
echo "  ✓ Created $LIB"

# ── Python provider package ───────────────────────────────────────────────
_py_files=(
    "__init__.py"
    "_data.py"
    "_wiki.py"
    "provider_random.py"
    "provider_weather.py"
    "provider_stocks.py"
    "provider_news.py"
)
for _p in "${_py_files[@]}"; do
    _src="${ROOT_DIR}/share/motd/py/${_p}"
    if [[ -f "$_src" ]]; then
        sudo install -m 0644 "$_src" "$PY/$_p"
        echo "  ✓ py/$_p"
    else
        echo "  ! Warning: missing $_src — skipping"
    fi
done
# Make provider scripts directly executable
for _p in provider_random.py provider_weather.py provider_stocks.py provider_news.py; do
    [[ -f "$PY/$_p" ]] && sudo chmod 0755 "$PY/$_p"
done

# ── Layer-1 shell injectors ───────────────────────────────────────────────
_sh_files=(
    "20-weather.sh"
    "30-stocks.sh"
    "40-news.sh"
    "50-td-reminder.sh"
    "90-randomfacts.sh"
)
for _s in "${_sh_files[@]}"; do
    _src="${ROOT_DIR}/share/motd/inject.d/${_s}"
    if [[ -f "$_src" ]]; then
        sudo install -m 0755 "$_src" "$INJ/$_s"
        echo "  ✓ inject.d/$_s"
    else
        echo "  ! Warning: missing $_src — skipping"
    fi
done

echo ""
echo "Installation complete → $LIB"
echo ""
echo "Optional Python deps (for web widgets):"
echo "  Debian/Ubuntu:  sudo apt-get install -y python3 python3-requests"
echo "  RHEL/Alma:      sudo dnf install -y python3 python3-requests"
echo ""
echo "Enable widgets in ~/.bashrc or /etc/environment:"
echo "  export FLOWER_MOTD_RANDOM=1              # 🌸 science fact (with wiki enrichment)"
echo "  export FLOWER_RANDOM_KIND=mix            # element|chemical|plant|mix"
echo "  export FLOWER_MOTD_WEATHER=1             # 🌦 wttr.in"
echo "  export FLOWER_WEATHER_LOC='Chico'        # optional city"
echo "  export FLOWER_MOTD_STOCKS=1              # 💹 stock tickers"
echo "  export FLOWER_STOCKS='AAPL,MSFT,NVDA'   # optional tickers"
echo "  export FLOWER_MOTD_NEWS=1                # 🗞 RSS headlines"
echo "  export FLOWER_NEWS_N=2                   # optional headline count"
echo "  export FLOWER_MOTD_NO_TD=1               # silence Tower Defense reminder"
echo "  FLOWER_TD_FORCE=1 flower-motd           # force-show reminder right now"

_bashrc_widgets_prompt
