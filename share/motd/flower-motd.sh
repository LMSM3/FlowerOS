#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  share/motd/flower-motd.sh  —  FlowerOS MOTD  (Layer 0)
#
#  Prints: ASCII mascot | system info (side-by-side), colour palette,
#          one random 🌸 science fact (pure-bash, no python needed).
#
#  Layer 1 (inject.d/*.sh) and Layer 2 (py/provider_*.py) are appended
#  at the bottom when the inject framework is present and env flags are set.
#
#  Install:  ./bin/flower-motd-install.sh
#  Silence:  export FLOWER_MOTD_QUIET=1
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail
shopt -s extglob   # required for ANSI-strip pattern *([0-9;])

# Interactive-only guard
case "$-" in *i*) ;; *) exit 0 ;; esac
[[ -n "${FLOWER_MOTD_QUIET:-}" ]] && exit 0

have() { command -v "$1" >/dev/null 2>&1; }

# ── Cache infrastructure ─────────────────────────────────────────────────
# run_cached <name> <ttl_seconds> <command...>
# Writes command stdout to ~/.cache/floweros/motd/<name>.txt.
# On cache hit (file exists and age < ttl) serves from disk — no exec.
# On miss/stale: runs fresh; on failure, serves stale rather than nothing.
_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/floweros/motd"

run_cached() {
    local name="$1" ttl="$2"
    shift 2
    local cache_file="$_CACHE_DIR/${name}.txt" tmp
    mkdir -p "$_CACHE_DIR"

    if [[ -f "$cache_file" && -s "$cache_file" ]]; then
        local mtime now
        mtime="$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)"
        now="$(date +%s)"
        if (( now - mtime < ttl )); then
            cat "$cache_file"
            return 0
        fi
    fi

    tmp="${cache_file}.tmp"
    if "$@" 2>/dev/null > "$tmp"; then
        if [[ -s "$tmp" ]]; then
            mv "$tmp" "$cache_file"
            cat "$cache_file"
        else
            rm -f "$tmp"
            [[ -f "$cache_file" ]] && cat "$cache_file"  # serve stale
        fi
    else
        rm -f "$tmp"
        [[ -f "$cache_file" ]] && cat "$cache_file"      # serve stale on error
    fi
}

# Widget helper — run_cached + truncate + indent via _wline (defined later)
_run_widget() {
    local name="$1" ttl="$2"; shift 2
    local out
    out="$(run_cached "$name" "$ttl" "$@" 2>/dev/null)" || true
    [[ -n "$out" ]] && _wline "$out"
}

# ── Python lib path (dev fallback: run from source tree without install) ──
_MOTD_PY_LIB="/usr/local/lib/floweros/motd/py"
if [[ ! -d "$_MOTD_PY_LIB" ]]; then
    _script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -d "$_script_dir/py" ]] && _MOTD_PY_LIB="$_script_dir/py"
fi

# ── System info (fallback-first, /proc before tools) ────────────────────

hostname_short="$(hostname 2>/dev/null | cut -d. -f1 || echo "host")"
user="${USER:-$(id -un 2>/dev/null || echo user)}"

os_pretty="Linux"
[[ -r /etc/os-release ]] && { . /etc/os-release; os_pretty="${PRETTY_NAME:-${NAME:-Linux}}"; }

kernel="$(uname -r 2>/dev/null || echo "?")"

cpu="Unknown CPU"
if [[ -r /proc/cpuinfo ]]; then
    cpu="$(awk -F: '/model name/{gsub(/^[ \t]+/,"",$2);print $2;exit}' /proc/cpuinfo)"
fi
if [[ -z "$cpu" || "$cpu" == "Unknown CPU" ]] && have lscpu; then
    cpu="$(lscpu | awk -F: '/Model name/{gsub(/^[ \t]+/,"",$2);print $2;exit}')"
fi
cpu="${cpu:-Unknown CPU}"

cores="?"
if have nproc; then
    cores="$(nproc 2>/dev/null || echo "?")"
elif [[ -r /proc/cpuinfo ]]; then
    cores="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "?")"
fi

mem_used="?" mem_total="?"
if [[ -r /proc/meminfo ]]; then
    _tk="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
    _ak="$(awk '/MemAvailable/{print $2}' /proc/meminfo)"
    if [[ "${_tk:-0}" -gt 0 ]]; then
        mem_total="$((_tk/1024))"
        mem_used="$(((_tk-_ak)/1024))"
    fi
elif have free; then
    read -r _ mem_total mem_used _ < <(free -m | awk '/Mem:/{print $1,$2,$3,$4;exit}')
fi
# WSL2: /proc/meminfo shows VM slice only — query Windows for real host total
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    _wk=""
    if have powershell.exe; then
        _wk="$(powershell.exe -NoProfile -Command \
            '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB' \
            2>/dev/null | tr -d '\r\n ')"
        # powershell returns a decimal like 48986.484375 — round to int
        [[ "$_wk" =~ ^[0-9]+(\.[0-9]+)?$ ]] && mem_total="$(printf '%.0f' "$_wk")"
    elif have wmic.exe; then
        _wk="$(wmic.exe OS get TotalVisibleMemorySize /value 2>/dev/null \
            | grep -i TotalVisible | tr -d '\r\n ' | cut -d= -f2)"
        [[ "${_wk:-0}" -gt 0 ]] && mem_total="$(( _wk / 1024 ))"
    fi
fi

gpu="?"
if have nvidia-smi; then
    gpu="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')" || true
fi
if [[ -z "${gpu:-}" || "$gpu" == "?" ]]; then
    have lspci && gpu="$(lspci | awk -F': ' '/VGA compatible controller|3D controller|Display controller/{print $2;exit}' 2>/dev/null)" || true
fi
if [[ -z "${gpu:-}" || "$gpu" == "?" ]]; then
    [[ -n "${WSL_DISTRO_NAME:-}" ]] && gpu="WSL/DXG (install nvidia-smi for real GPU)"
fi
gpu="${gpu:-Unknown GPU}"

uptime_str="?"
if [[ -r /proc/uptime ]]; then
    _us="$(awk '{printf "%d",$1}' /proc/uptime)"
    if [[ "${_us:-0}" -gt 0 ]]; then
        _uh=$((_us/3600)); _um=$(((_us%3600)/60))
        if [[ $_uh -gt 0 ]]; then
            uptime_str="${_uh}h ${_um}m"
        else
            uptime_str="${_um}m"
        fi
    fi
elif have uptime; then
    uptime_str="$(uptime -p 2>/dev/null | sed 's/^up //' || echo "?")"
fi

shell_label="$(basename "${SHELL:-bash}")"
if [[ "$shell_label" == "bash" ]]; then
    shell_label="bash ${BASH_VERSION%%(*}"
elif [[ "$shell_label" == "zsh" && -n "${ZSH_VERSION:-}" ]]; then
    shell_label="zsh $ZSH_VERSION"
fi

flower_user="${FLOWER_USER:-$user}"
flower_theme="${FLOWER_THEME:-pastel}"

# ── Display helpers ─────────────────────────────────────────────────────────

_MOTD_COLS="$(tput cols 2>/dev/null || echo 90)"
(( _MOTD_COLS < 60 )) && _MOTD_COLS=60
(( _MOTD_COLS > 120 )) && _MOTD_COLS=120

# ASCII-safe icons by default.  Set FLOWER_MOTD_EMOJI=1 to enable emoji.
if [[ "${FLOWER_MOTD_EMOJI:-0}" == "1" ]]; then
    _I_ELEM="⚗"; _I_CHEM="🧪"; _I_PLANT="🌱"
    _I_WX="🌦";   _I_STK="💹";   _I_NEWS="🗞"
else
    _I_ELEM="*"; _I_CHEM="~"; _I_PLANT="+"
    _I_WX="~";   _I_STK="$";   _I_NEWS="!"
fi

# _wline TEXT — strip ANSI for length, truncate to terminal width, print indented
_wline() {
    local s="$1"
    local plain="${s//$'\033['*([0-9;])m/}"
    local max=$(( _MOTD_COLS - 2 ))
    (( max < 20 )) && max=20
    if (( ${#plain} > max )); then
        printf "  %s…\n" "${plain:0:$(( max - 1 ))}"
    else
        printf "  %s\n" "$s"
    fi
}

# Fixed gutter: art column padded to exactly this width.
# Info block always starts at column (_GUTTER + 4) regardless of art line length.
_GUTTER=34

# ── Layer-0 random fact  (pure bash, $RANDOM = 0..32767, truly random) ──

_FACTS=(
    "$_I_ELEM Element: Hydrogen (Z=1) — Lightest element; main fuel of stars."
    "$_I_ELEM Element: Helium (Z=2) — Inert noble gas; superfluid below 2.17 K."
    "$_I_ELEM Element: Lithium (Z=3) — Lightest metal; key to rechargeable batteries."
    "$_I_ELEM Element: Carbon (Z=6) — Backbone of organic chemistry and many materials."
    "$_I_ELEM Element: Oxygen (Z=8) — Most abundant element in Earth's crust."
    "$_I_ELEM Element: Silicon (Z=14) — Semiconductor basis of modern electronics."
    "$_I_ELEM Element: Iron (Z=26) — Core of terrestrial planets; most structural metal."
    "$_I_ELEM Element: Copper (Z=29) — Highest electrical conductivity of common metals."
    "$_I_ELEM Element: Tungsten (Z=74) — Highest melting point of all metals: 3422 °C."
    "$_I_ELEM Element: Gold (Z=79) — Noble metal; corrosion-resistant, excellent conductor."
    "$_I_ELEM Element: Mercury (Z=80) — Only metal liquid at room temperature."
    "$_I_ELEM Element: Uranium (Z=92) — Actinide; fission releases ~200 MeV per nucleus."
    "$_I_ELEM Element: Neodymium (Z=60) — Rare-earth used in the strongest permanent magnets."
    "$_I_ELEM Element: Osmium (Z=76) — Densest naturally occurring element: 22.59 g/cm³."
    "$_I_CHEM Chemical: Ammonia (NH₃) — Trigonal pyramidal; most-produced inorganic compound."
    "$_I_CHEM Chemical: Caffeine (C₈H₁₀N₄O₂) — Adenosine receptor antagonist; ~60 plant species."
    "$_I_CHEM Chemical: Aspirin (C₉H₈O₄) — Anti-inflammatory; inhibits COX-1/COX-2 enzymes."
    "$_I_CHEM Chemical: Water (H₂O) — Anomalous density maximum at 4 °C; universal solvent."
    "$_I_CHEM Chemical: Glucose (C₆H₁₂O₆) — Primary cellular fuel; product of photosynthesis."
    "$_I_CHEM Chemical: Ozone (O₃) — Stratospheric UV shield; absorbs 97–99% of solar UV."
    "$_I_CHEM Chemical: Benzene (C₆H₆) — Archetypical aromatic ring; carcinogenic solvent."
    "$_I_CHEM Chemical: ATP (C₁₀H₁₆N₅O₁₃P₃) — Universal cellular energy currency."
    "$_I_CHEM Chemical: Penicillin G — First beta-lactam antibiotic; Fleming 1928."
    "$_I_PLANT Plant: Venus flytrap (Dionaea muscipula) — Snap-trap closes in ~100 ms."
    "$_I_PLANT Plant: Bamboo (Bambusoideae) — Fastest-growing plant; up to 91 cm/day."
    "$_I_PLANT Plant: Baobab (Adansonia) — Stores >100,000 L water; lives 3,000+ years."
    "$_I_PLANT Plant: Welwitschia (Welwitschia mirabilis) — Two leaves; lives 2,000+ years."
    "$_I_PLANT Plant: Corpse flower (Amorphophallus titanum) — Largest unbranched inflorescence."
    "$_I_PLANT Plant: Ginkgo (Ginkgo biloba) — Living fossil; unchanged 200 million years."
    "$_I_PLANT Plant: Rafflesia (Rafflesia arnoldii) — Largest individual flower; no stems."
    "$_I_PLANT Plant: Mimosa (Mimosa pudica) — Folds leaves on touch; thigmonastic response."
    "$_I_PLANT Plant: Foxglove (Digitalis purpurea) — Source of digoxin; treats heart conditions."
    "$_I_PLANT Plant: Quinine tree (Cinchona officinalis) — Bark yields first antimalarial."
    "$_I_PLANT Plant: Opium poppy (Papaver somniferum) — Source of morphine, codeine, heroin."
    "$_I_PLANT Plant: Creosote bush (Larrea tridentata) — Clone ring ~11,700 years old."
)

_fact_idx=$(( RANDOM % ${#_FACTS[@]} ))
_random_fact="${_FACTS[$_fact_idx]}"

# ── Character art via flower_guy system ─────────────────────────────────
# Priority: compiled flower-guy binary → Python provider → fallback art.
# Cached 1 h so the same character is shown all session.

_char_art=()
_PY_CHAR="$_MOTD_PY_LIB/provider_character.py"
_char_raw=""
if have flower-guy; then
    _char_raw="$(run_cached character 3600 flower-guy --random 2>/dev/null || true)"
elif [[ -f "$_PY_CHAR" ]]; then
    _char_raw="$(run_cached character 3600 python3 "$_PY_CHAR" 2>/dev/null || true)"
fi

if [[ -n "$_char_raw" ]]; then
    mapfile -t _char_art <<< "$_char_raw"
else
    _char_art=(
        "    .-(.-).."
        "  (  (.-)-.)"
        "   -(  ( )-, "
        "     '-(-)-'"
        ""
        "      __|__"
        "     ( ) ( )"
        "      \\ _ /"
        "  ____ |=| ____"
        "   o   o   o"
    )
fi

# ── Colour escapes ────────────────────────────────────────────────────────

c0=$'\033[0m'
c_bold=$'\033[1m'
c_user=$'\033[1;37m'
c_at=$'\033[0;90m'
c_label=$'\033[0;90m'
c_val=$'\033[0m'
c_fact=$'\033[1;35m'
c_art=$'\033[38;5;183m'

# ── Info block ───────────────────────────────────────────────────────────

_info=(
    "${c_user}${flower_user}${c_at}@${c_user}${hostname_short}${c0}"
    "${c_label}──────────────────${c0}"
    "${c_label}OS:${c0}       ${os_pretty}"
    "${c_label}Kernel:${c0}   ${kernel}"
    "${c_label}Uptime:${c0}   ${uptime_str}"
    "${c_label}Shell:${c0}    ${shell_label}"
    "${c_label}CPU:${c0}      ${cpu} (${cores})"
)
if [[ "$mem_used" != "?" && "$mem_total" != "?" ]]; then
    _info+=("${c_label}Memory:${c0}   ${mem_used} MiB / ${mem_total} MiB")
else
    _info+=("${c_label}Memory:${c0}   ?")
fi
_info+=(
    "${c_label}GPU:${c0}      ${gpu}"
    "${c_label}FlowerOS:${c0} ${flower_theme}"
)

# ── Side-by-side render ──────────────────────────────────────────────────
# Fixed gutter: info column always starts at position (_GUTTER + 4).
# pad = _GUTTER - visible_art_width  ⇒  col = 2 + visible + pad + 2 = _GUTTER + 4.

_rows=$(( ${#_char_art[@]} > ${#_info[@]} ? ${#_char_art[@]} : ${#_info[@]} ))

printf "\n"
for (( i=0; i<_rows; i++ )); do
    _a="${_char_art[$i]:-}"
    _iv="${_info[$i]:-}"
    _av="${_a//$'\033['*([0-9;])m/}"
    _pad=$(( _GUTTER - ${#_av} ))
    (( _pad < 0 )) && _pad=0
    printf "  %s%*s  %s\n" "$_a" "$_pad" "" "$_iv"
done

# Colour palette bar
printf "\n  "
for _cc in 1 2 3 4 5 6 7 0; do
    printf "\033[4%dm    " "$_cc"
done
printf "%s\n" "$c0"

# Layer-0 random fact
printf "\n"
_wline "${c_fact}${_random_fact}${c0}"

# ── Injection framework (Layer 2 — Python widgets, centrally cached) ──────
# TTLs: random 24 h · weather 15 min · stocks 5 min · news 10 min
# run_cached is defined above; caches to ~/.cache/floweros/motd/<name>.txt

if [[ -z "${FLOWER_MOTD_NO_INJECT:-}" && -d "$_MOTD_PY_LIB" ]]; then
    if [[ -n "${FLOWER_MOTD_RANDOM:-}" && -f "$_MOTD_PY_LIB/provider_random.py" ]]; then
        _run_widget random  86400 python3 "$_MOTD_PY_LIB/provider_random.py"  || true
    fi
    if [[ -n "${FLOWER_MOTD_WEATHER:-}" && -f "$_MOTD_PY_LIB/provider_weather.py" ]]; then
        _run_widget weather   900 python3 "$_MOTD_PY_LIB/provider_weather.py" || true
    fi
    if [[ -n "${FLOWER_MOTD_STOCKS:-}" && -f "$_MOTD_PY_LIB/provider_stocks.py" ]]; then
        _run_widget stocks    300 python3 "$_MOTD_PY_LIB/provider_stocks.py"  || true
    fi
    if [[ -n "${FLOWER_MOTD_NEWS:-}" && -f "$_MOTD_PY_LIB/provider_news.py" ]]; then
        _run_widget news      600 python3 "$_MOTD_PY_LIB/provider_news.py"    || true
    fi
fi

# ── Tower Defense daily reminder (pure-bash, no Python required) ──────────
# Fires when: uptime < 10 min  OR  last shown > 24 h  OR  FLOWER_TD_FORCE=1.
# Stamp: ~/.cache/floweros/motd/td_last   Disable: export FLOWER_MOTD_NO_TD=1
if [[ -z "${FLOWER_MOTD_NO_TD:-}" ]]; then
    _td_stamp="$_CACHE_DIR/td_last"
    _td_show=0
    if [[ -n "${FLOWER_TD_FORCE:-}" ]]; then
        _td_show=1
    else
        _td_up=99999
        if [[ -r /proc/uptime ]]; then
            _td_up="$(awk '{printf "%d",$1}' /proc/uptime 2>/dev/null || echo 99999)"
        fi
        if (( _td_up < 600 )); then
            _td_show=1
        elif [[ ! -f "$_td_stamp" ]]; then
            _td_show=1
        else
            _td_now="$(date +%s)"
            _td_mt="$(stat -c %Y "$_td_stamp" 2>/dev/null || echo 0)"
            if (( _td_now - _td_mt >= 86400 )); then
                _td_show=1
            fi
        fi
    fi
    if (( _td_show )); then
        _td_bin=""
        if command -v flower-td >/dev/null 2>&1; then _td_bin="flower-td"; fi
        printf "\n"
        _wline "${c_bold}\033[38;5;183m✿ FlowerOS Tower Defense${c0}  \033[38;5;245mv2 · PvZ-style lane combat${c0}"
        if [[ -n "$_td_bin" ]]; then
            _wline "\033[38;5;120mflower-td${c0}  \033[38;5;245m[D]aisy [R]ose [S]unflower [C]actus [T]horn${c0}"
            _wline "\033[38;5;245m7 lanes · 20 stages · 30 petals · 10 lives   \033[38;5;117mflower-td --help${c0}"
        else
            _wline "\033[38;5;245mgcc -O2 -std=c11 -o flower-td src/games/td_engine.c${c0}"
            _wline "\033[38;5;245m7 lanes · 20 stages · flowers vs creeps${c0}"
        fi
        touch "$_td_stamp"
    fi
fi

printf "\n"
