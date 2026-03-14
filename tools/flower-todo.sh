#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS To-Do Notepad  🌸
#  Pastel-themed task manager stored in ~/.config/floweros/todo.json
#  Part of FlowerOS — every petal accounted for.
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── source shared colors if available ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"
if [[ -f "$LIB_DIR/colors.sh" ]]; then
    # shellcheck source=../lib/colors.sh
    source "$LIB_DIR/colors.sh"
else
    g="\033[32m"; r="\033[31m"; c="\033[36m"; y="\033[33m"; m="\033[35m"; z="\033[0m"
    ok()   { printf "${g}✓${z} %s\n" "$*"; }
    err()  { printf "${r}✗${z} %s\n" "$*" >&2; }
    info() { printf "${c}✿${z} %s\n" "$*"; }
    warn() { printf "${y}⚠${z} %s\n" "$*"; }
fi

# ── pastel palette (256-color) ──
C_DIM=245; C_ACC=117; C_PNK=219; C_GRN=120; C_RED=210; C_YLW=229
fg() { printf '\033[38;5;%sm' "$1"; }
rs() { printf '\033[0m'; }

# ── paths ──
FLOWER_DIR="${HOME}/.config/floweros"
TODO_FILE="${FLOWER_DIR}/todo.json"
mkdir -p "$FLOWER_DIR" 2>/dev/null

# ── ensure todo file exists ──
if [[ ! -f "$TODO_FILE" ]]; then
    printf '[]' > "$TODO_FILE"
fi

# ── helpers: minimal JSON without jq dependency ──
_has_jq() { command -v jq >/dev/null 2>&1; }

_count_tasks() {
    if _has_jq; then
        jq 'length' "$TODO_FILE"
    else
        grep -c '"text"' "$TODO_FILE" 2>/dev/null || echo 0
    fi
}

_next_id() {
    if _has_jq; then
        local max; max=$(jq '[.[].id] | if length == 0 then 0 else max end' "$TODO_FILE")
        echo $(( max + 1 ))
    else
        local max=0 id
        while IFS= read -r id; do
            (( id > max )) && max=$id
        done < <(grep -oP '"id"\s*:\s*\K[0-9]+' "$TODO_FILE" 2>/dev/null)
        echo $(( max + 1 ))
    fi
}

_timestamp() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

# ═══════════════════════════════════════════════════════════════════════════
#  Commands
# ═══════════════════════════════════════════════════════════════════════════

cmd_add() {
    local text="$*"
    [[ -z "$text" ]] && { err "Usage: flower-todo add <task text>"; return 1; }

    local id; id=$(_next_id)
    local ts; ts=$(_timestamp)

    if _has_jq; then
        jq --arg t "$text" --argjson i "$id" --arg ts "$ts" \
            '. += [{"id":$i,"text":$t,"done":false,"created":$ts}]' \
            "$TODO_FILE" > "${TODO_FILE}.tmp" && mv "${TODO_FILE}.tmp" "$TODO_FILE"
    else
        # fallback: simple append
        local content; content=$(cat "$TODO_FILE")
        if [[ "$content" == "[]" ]]; then
            printf '[{"id":%d,"text":"%s","done":false,"created":"%s"}]' \
                "$id" "$text" "$ts" > "$TODO_FILE"
        else
            # remove trailing ] and append
            content="${content%]}"
            printf '%s,{"id":%d,"text":"%s","done":false,"created":"%s"}]' \
                "$content" "$id" "$text" "$ts" > "$TODO_FILE"
        fi
    fi

    printf "$(fg $C_GRN)✓$(rs) Added #%d: $(fg $C_ACC)%s$(rs)\n" "$id" "$text"
}

cmd_list() {
    local count; count=$(_count_tasks)
    if [[ "$count" -eq 0 ]]; then
        printf "\n  $(fg $C_DIM)🌸 No tasks yet. Add one with:$(rs) $(fg $C_YLW)flower-todo add <task>$(rs)\n\n"
        return 0
    fi

    printf "\n  $(fg $C_PNK)🌸 FlowerOS To-Do$(rs)  $(fg $C_DIM)(%s tasks)$(rs)\n" "$count"
    printf "  $(fg $C_DIM)─────────────────────────────────────$(rs)\n"

    if _has_jq; then
        jq -r '.[] | "\(.id)|\(.done)|\(.text)"' "$TODO_FILE" | while IFS='|' read -r id done text; do
            if [[ "$done" == "true" ]]; then
                printf "  $(fg $C_DIM) ✔  #%-3d %s$(rs)\n" "$id" "$text"
            else
                printf "  $(fg $C_GRN) ○$(rs)  $(fg $C_ACC)#%-3d$(rs) %s\n" "$id" "$text"
            fi
        done
    else
        # fallback grep parser
        local id done text
        while IFS= read -r line; do
            id=$(echo "$line" | grep -oP '"id"\s*:\s*\K[0-9]+')
            done=$(echo "$line" | grep -oP '"done"\s*:\s*\K(true|false)')
            text=$(echo "$line" | grep -oP '"text"\s*:\s*"\K[^"]+')
            if [[ "$done" == "true" ]]; then
                printf "  $(fg $C_DIM) ✔  #%-3d %s$(rs)\n" "$id" "$text"
            else
                printf "  $(fg $C_GRN) ○$(rs)  $(fg $C_ACC)#%-3d$(rs) %s\n" "$id" "$text"
            fi
        done < <(grep -oP '\{[^}]+\}' "$TODO_FILE")
    fi

    printf "  $(fg $C_DIM)─────────────────────────────────────$(rs)\n\n"
}

cmd_done() {
    local id="${1:-}"
    [[ -z "$id" ]] && { err "Usage: flower-todo done <id>"; return 1; }

    if _has_jq; then
        local exists; exists=$(jq --argjson i "$id" '[.[] | select(.id == $i)] | length' "$TODO_FILE")
        [[ "$exists" -eq 0 ]] && { err "Task #$id not found."; return 1; }

        jq --argjson i "$id" \
            'map(if .id == $i then .done = true else . end)' \
            "$TODO_FILE" > "${TODO_FILE}.tmp" && mv "${TODO_FILE}.tmp" "$TODO_FILE"
    else
        # simple sed toggle
        sed -i "s/\"id\":${id},\(.*\)\"done\":false/\"id\":${id},\1\"done\":true/" "$TODO_FILE"
    fi

    printf "$(fg $C_GRN)✔$(rs) Task #%d marked done.\n" "$id"
}

cmd_undo() {
    local id="${1:-}"
    [[ -z "$id" ]] && { err "Usage: flower-todo undo <id>"; return 1; }

    if _has_jq; then
        jq --argjson i "$id" \
            'map(if .id == $i then .done = false else . end)' \
            "$TODO_FILE" > "${TODO_FILE}.tmp" && mv "${TODO_FILE}.tmp" "$TODO_FILE"
    else
        sed -i "s/\"id\":${id},\(.*\)\"done\":true/\"id\":${id},\1\"done\":false/" "$TODO_FILE"
    fi

    printf "$(fg $C_YLW)○$(rs) Task #%d reopened.\n" "$id"
}

cmd_remove() {
    local id="${1:-}"
    [[ -z "$id" ]] && { err "Usage: flower-todo rm <id>"; return 1; }

    if _has_jq; then
        jq --argjson i "$id" 'map(select(.id != $i))' \
            "$TODO_FILE" > "${TODO_FILE}.tmp" && mv "${TODO_FILE}.tmp" "$TODO_FILE"
    else
        # crude but functional: rebuild without the matching block
        local tmp; tmp=$(grep -oP '\{[^}]+\}' "$TODO_FILE" | grep -v "\"id\":${id},")
        if [[ -z "$tmp" ]]; then
            printf '[]' > "$TODO_FILE"
        else
            printf '[%s]' "$(echo "$tmp" | paste -sd ',')" > "$TODO_FILE"
        fi
    fi

    printf "$(fg $C_RED)✗$(rs) Task #%d removed.\n" "$id"
}

cmd_clear() {
    printf '[]' > "$TODO_FILE"
    ok "All tasks cleared."
}

cmd_help() {
    printf "\n"
    printf "  $(fg $C_PNK)🌸 FlowerOS To-Do Notepad$(rs)\n"
    printf "  $(fg $C_DIM)─────────────────────────────────────$(rs)\n"
    printf "  $(fg $C_ACC)add$(rs) <text>     Add a new task\n"
    printf "  $(fg $C_ACC)list$(rs)           Show all tasks\n"
    printf "  $(fg $C_ACC)done$(rs) <id>      Mark task complete\n"
    printf "  $(fg $C_ACC)undo$(rs) <id>      Reopen a task\n"
    printf "  $(fg $C_ACC)rm$(rs) <id>        Remove a task\n"
    printf "  $(fg $C_ACC)clear$(rs)          Remove all tasks\n"
    printf "  $(fg $C_ACC)help$(rs)           Show this help\n"
    printf "  $(fg $C_DIM)─────────────────────────────────────$(rs)\n"
    printf "  Data: $(fg $C_DIM)%s$(rs)\n" "$TODO_FILE"
    printf "\n"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Main dispatch
# ═══════════════════════════════════════════════════════════════════════════

main() {
    local cmd="${1:-list}"
    shift 2>/dev/null || true

    case "$cmd" in
        add)    cmd_add "$@" ;;
        list|ls) cmd_list ;;
        done)   cmd_done "$@" ;;
        undo)   cmd_undo "$@" ;;
        rm|remove|del) cmd_remove "$@" ;;
        clear)  cmd_clear ;;
        help|-h|--help) cmd_help ;;
        *)      err "Unknown command: $cmd"; cmd_help; return 1 ;;
    esac
}

main "$@"
