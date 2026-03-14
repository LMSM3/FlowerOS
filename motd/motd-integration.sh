
# ============================================================================
# FlowerOS MOTD Template System
# Sourced from ~/.bashrc via flower-install.
# All paths resolve from FLOWEROS_ROOT — no hardcoded machine paths.
# ============================================================================

# FLOWEROS_ROOT is set by the bashrc block written by flower-install.
# Fallback: assume standard install location.
_FOS_ROOT="${FLOWEROS_ROOT:-${HOME}/FlowerOS}"

export FLOWEROS_MOTD_ENABLED="${FLOWEROS_MOTD_ENABLED:-1}"
export FLOWEROS_MOTD_TEMPLATE="${FLOWEROS_MOTD_TEMPLATE:-sysinfo}"
export FLOWEROS_MOTD_DIR="${FLOWEROS_MOTD_DIR:-${_FOS_ROOT}/motd}"

# Load ASCII character library if not already loaded
if ! declare -f flower_c >/dev/null 2>&1; then
    _FOS_ASCII_LIB="${_FOS_ROOT}/lib/flower_ascii.sh"
    [[ -f "$_FOS_ASCII_LIB" ]] && source "$_FOS_ASCII_LIB"
fi

floweros_motd() {
    [[ "${FLOWEROS_MOTD_ENABLED}" != "1" ]] && return 0
    [[ $- == *i* ]] || return 0

    declare -f flower_guy_motd >/dev/null 2>&1 && flower_guy_motd

    local template="${FLOWEROS_MOTD_TEMPLATE:-sysinfo}"
    local script="${FLOWEROS_MOTD_DIR}/${template}.py"

    if [[ -f "$script" ]]; then
        python3 "$script" 2>/dev/null || true
    elif command -v flower-motd >/dev/null 2>&1; then
        # Fall back to compiled motd binary if Python script not found
        flower-motd 2>/dev/null || true
    fi
}

[[ -z "${FLOWEROS_NO_AUTO_MOTD:-}" ]] && floweros_motd

alias motd-sysinfo='python3 "${FLOWEROS_MOTD_DIR}/sysinfo.py" 2>/dev/null || flower-motd'
alias motd-weather='python3 "${FLOWEROS_MOTD_DIR}/weather.py" 2>/dev/null || true'
alias motd-stocks='python3 "${FLOWEROS_MOTD_DIR}/stocks.py"  2>/dev/null || true'
alias motd-off='export FLOWEROS_MOTD_ENABLED=0'
alias motd-on='export FLOWEROS_MOTD_ENABLED=1'
alias motd-walk='flower-walk 2>/dev/null || bash "${_FOS_ROOT}/experimental/animations/flower_walk_demo.sh"'

motd-set() {
    if [[ -z "${1:-}" ]]; then
        printf 'Usage: motd-set <template>\nAvailable: sysinfo, weather, stocks\n'
        return 1
    fi
    export FLOWEROS_MOTD_TEMPLATE="$1"
    printf '✓ MOTD template set to: %s\n' "$1"
}
export -f motd-set

unset _FOS_ROOT
