#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  bin/flower-motd-install.sh
#  Installs the FlowerOS MOTD runner to /usr/local/bin/flower-motd and
#  hooks it into the login system (Debian update-motd.d or RHEL profile.d).
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# ── .bashrc integration helpers ──────────────────────────────────────────
_write_motd_rc() {
    printf "\n"
    printf "# BEGIN FlowerOS MOTD\n"
    printf "# Auto-run FlowerOS MOTD on interactive shells\n"
    printf '[[ $- == *i* ]] && command -v flower-motd >/dev/null 2>&1 && flower-motd\n'
    printf "# END FlowerOS MOTD\n"
}

_bashrc_prompt() {
    local rcfile="$HOME/.bashrc"
    local has_block=0
    grep -qF "# BEGIN FlowerOS MOTD" "$rcfile" 2>/dev/null && has_block=1 || true

    [[ -t 0 ]] || { printf "\n  (non-interactive \u2014 .bashrc step skipped)\n"; return 0; }

    printf "\n  %s\n" "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
    if (( has_block )); then
        printf "  FlowerOS MOTD block already exists in %s.\n" "$rcfile"
        printf "  [m]odify   append a fresh copy\n"
        printf "  [o]verwrite  remove existing and replace\n"
        printf "  [s]kip\n  > "
    else
        printf "  Add \`flower-motd\` to %s?\n" "$rcfile"
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
                _write_motd_rc >> "$rcfile"
                printf "  \xe2\x9c\x93 Appended to %s\n" "$rcfile"
            fi
            ;;
        o|overwrite)
            touch "$rcfile"
            sed '/^# BEGIN FlowerOS MOTD$/,/^# END FlowerOS MOTD$/d' \
                "$rcfile" > "${rcfile}.fos.tmp" && mv "${rcfile}.fos.tmp" "$rcfile"
            _write_motd_rc >> "$rcfile"
            printf "  \xe2\x9c\x93 Replaced FlowerOS block in %s\n" "$rcfile"
            ;;
        *)
            printf "  - Skipped. To add later, append to %s:\n" "$rcfile"
            printf "      flower-motd\n"
            ;;
    esac
    printf "  %s\n" "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
}

SRC="${ROOT_DIR}/share/motd/flower-motd.sh"
DST="/usr/local/bin/flower-motd"

if [[ ! -f "$SRC" ]]; then
    echo "ERROR: Missing source file: $SRC" >&2
    exit 1
fi

sudo install -m 0755 "$SRC" "$DST"
echo "  ✓ Installed $DST"

# ── Debian / Ubuntu — preferred via update-motd.d ─────────────────────────
if [[ -d /etc/update-motd.d ]]; then
    sudo tee /etc/update-motd.d/50-floweros >/dev/null <<'EOF'
#!/usr/bin/env bash
exec /usr/local/bin/flower-motd
EOF
    sudo chmod 0755 /etc/update-motd.d/50-floweros
    echo "  ✓ Hooked via /etc/update-motd.d/50-floweros"

    # Silence the noisy Ubuntu defaults (optional; comment out to keep them)
    for _f in 00-header 10-help-text 50-motd-news 80-livepatch \
               90-updates-available 91-contract-ua-esm-status; do
        [[ -e "/etc/update-motd.d/$_f" ]] && sudo chmod -x "/etc/update-motd.d/$_f" || true
    done
    echo "  ✓ Suppressed default Ubuntu MOTD scripts"
    _bashrc_prompt
    exit 0
fi

# ── RHEL / Alma / Rocky — profile.d fallback ─────────────────────────────
sudo tee /etc/profile.d/zz_floweros_motd.sh >/dev/null <<'EOF'
# FlowerOS MOTD — interactive shells only
case "$-" in *i*) /usr/local/bin/flower-motd ;; esac
EOF
sudo chmod 0644 /etc/profile.d/zz_floweros_motd.sh
echo "  ✓ Hooked via /etc/profile.d/zz_floweros_motd.sh"
_bashrc_prompt
