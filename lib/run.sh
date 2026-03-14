#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  lib/run.sh  —  FlowerOS universal run shell twin
#
#  Shell twin of src/runner/fos_runner.c  (flower-run binary)
#  1:1 language table parity — both must stay in sync.
#
#  Source this file or drop it in ~/.bashrc:
#    source /opt/floweros/lib/run.sh
#
#  Functions:
#    frun  [OPTIONS] <file>     detect language, compile if needed, run
#    frun_hpc  <file>           shorthand: frun --hpc --time
#    frun_time <file>           shorthand: frun --time
#    frun_list                  print language table
#    frun_gpu  <file>           shorthand: frun --gpu --hpc --time
#
#  Delegates to flower-run binary when available — same resolution order
#  as experimental/animations/flower_walk_demo.sh: permanent install → user build → shell fallback.
#
# ───────────────────────────────────────────────────────────────────────────
#  HPC contract (real flags, not cosmetic):
#    C/C++/Fortran  -O3 -march=native -ffast-math -fopenmp  OMP_NUM_THREADS=nproc
#    Python         OMP_NUM_THREADS=nproc  (NumPy/SciPy BLAS)
#    Julia          --threads $(nproc)
#    Go             GOMAXPROCS=$(nproc)
#    CUDA           nvcc --use_fast_math -O3
#
#  Architecture note (one line):
#    frun hello.c  →  any language, Tier 5 — same contract as flower-run
# ═══════════════════════════════════════════════════════════════════════════

[[ -n "${_FOS_RUN_LOADED:-}" ]] && return 0
_FOS_RUN_LOADED=1

# ── Delegate to compiled binary if present ───────────────────────────────
# Same resolution order used across all FlowerOS shell bootstraps.
_FOS_RUN_BIN=""
for _b in \
    "/opt/floweros/bin/flower-run" \
    "${FLOWEROS_DIR:+${FLOWEROS_DIR}/../bin/flower-run}" \
    "$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/../src/runner/flower-run"
do
    [[ -x "${_b:-}" ]] && { _FOS_RUN_BIN="$_b"; break; }
done
unset _b

# ── Color helpers (reuse flower_c if loaded, else inline) ────────────────
if ! declare -f flower_c >/dev/null 2>&1; then
    _rc() {
        case "${1:-reset}" in
            primary)   printf '\033[38;5;117m' ;;
            secondary) printf '\033[38;5;183m' ;;
            accent)    printf '\033[38;5;117m' ;;
            muted)     printf '\033[38;5;245m' ;;
            green)     printf '\033[38;5;120m' ;;
            red)       printf '\033[38;5;210m' ;;
            yellow)    printf '\033[38;5;229m' ;;
            reset|*)   printf '\033[0m' ;;
        esac
    }
else
    _rc() { flower_c "$1"; }
fi

_frun_ok()   { printf '%s✓%s %s\n' "$(_rc green)"  "$(_rc reset)" "$*"; }
_frun_err()  { printf '%s✗%s %s\n' "$(_rc red)"    "$(_rc reset)" "$*" >&2; }
_frun_info() { printf '%s✿%s %s\n' "$(_rc accent)" "$(_rc reset)" "$*"; }
_frun_warn() { printf '%s⚠%s %s\n' "$(_rc yellow)" "$(_rc reset)" "$*"; }

# ── CPU count for HPC mode ───────────────────────────────────────────────
_frun_nproc() { nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 1; }

# ── Nanosecond timer (bash 5+: $EPOCHREALTIME, else date) ────────────────
_frun_ns() {
    if (( BASH_VERSINFO[0] >= 5 )); then
        printf '%.0f' "$(awk "BEGIN{printf \"%.0f\", ${EPOCHREALTIME} * 1e9}")"
    else
        date +%s%N 2>/dev/null || echo 0
    fi
}

_frun_print_duration() {
    local label="$1" ns="$2"
    if   (( ns < 1000000 ));    then printf '  %s%s:%s  %s%.3f µs%s\n' "$(_rc muted)" "$label" "$(_rc reset)" "$(_rc yellow)" "$(awk "BEGIN{printf \"%.3f\", $ns / 1000}")" "$(_rc reset)"
    elif (( ns < 1000000000 )); then printf '  %s%s:%s  %s%.3f ms%s\n' "$(_rc muted)" "$label" "$(_rc reset)" "$(_rc yellow)" "$(awk "BEGIN{printf \"%.3f\", $ns / 1e6}")"   "$(_rc reset)"
    else                             printf '  %s%s:%s  %s%.3f s%s\n'  "$(_rc muted)" "$label" "$(_rc reset)" "$(_rc yellow)" "$(awk "BEGIN{printf \"%.3f\", $ns / 1e9}")"   "$(_rc reset)"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Language dispatch table
#  Mirrors FOS_LANG_TABLE in src/runner/fos_runner.h exactly.
#  Format: "ext:name:compiler:base_cflags:hpc_cflags:runner:hpc_env:hpc_capable"
#  Fields with no value use "-" as placeholder.
# ═══════════════════════════════════════════════════════════════════════════

declare -A _FRUN_EXT_MAP   # ext → table index
declare -a _FRUN_TABLE=(
    "c:C:gcc:-O2 -std=c11 -Wall -Wextra:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "cpp:C++:g++:-O2 -std=c++17 -Wall -Wextra:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "cc:C++:g++:-O2 -std=c++17 -Wall -Wextra:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "cxx:C++:g++:-O2 -std=c++17 -Wall -Wextra:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "cu:CUDA:nvcc:-O2:-O3 --use_fast_math -Xcompiler -fopenmp:-:OMP_NUM_THREADS:1"
    "rs:Rust:rustc:-O:-O:-:- :0"
    "f90:Fortran:gfortran:-O2 -Wall:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "f95:Fortran:gfortran:-O2 -Wall:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "for:Fortran:gfortran:-O2 -Wall:-O3 -march=native -ffast-math -fopenmp:-:OMP_NUM_THREADS:1"
    "java:Java:javac:-:-:java:-:0"
    "hs:Haskell:-:-:-:runghc:-:0"
    "py:Python:-:-:-:python3:OMP_NUM_THREADS:1"
    "pyw:Python:-:-:-:python3:OMP_NUM_THREADS:1"
    "jl:Julia:-:-:--threads N:julia:-:1"
    "go:Go:-:-:-:go run:GOMAXPROCS:1"
    "sh:Shell:-:-:-:bash:-:0"
    "bash:Shell:-:-:-:bash:-:0"
    "js:JavaScript:-:-:-:node:-:0"
    "mjs:JavaScript:-:-:-:node:-:0"
    "rb:Ruby:-:-:-:ruby:-:0"
    "lua:Lua:-:-:-:lua:-:0"
    "pl:Perl:-:-:-:perl:-:0"
    "r:R:-:-:-:Rscript:-:0"
    "m:Octave:-:-:-:octave:-:0"
)

# Build ext → index lookup map
for _i in "${!_FRUN_TABLE[@]}"; do
    _ext="${_FRUN_TABLE[$_i]%%:*}"
    _FRUN_EXT_MAP["$_ext"]=$_i
done
unset _i _ext

# ── Language lookup ───────────────────────────────────────────────────────
_frun_detect() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"   # lowercase
    local idx="${_FRUN_EXT_MAP[$ext]:-}"
    [[ -n "$idx" ]] || return 1
    printf '%s' "${_FRUN_TABLE[$idx]}"
}

# Field extractor (1-indexed, colon-separated)
_frun_field() { echo "$1" | cut -d: -f"$2"; }

# ═══════════════════════════════════════════════════════════════════════════
#  frun  —  main universal run function
#
#  Usage:  frun [--hpc] [--gpu] [--time] [--debug] [--verbose] [--keep] <file>
# ═══════════════════════════════════════════════════════════════════════════

frun() {
    # ── Delegate to C binary if present ──────────────────────────────
    if [[ -n "${_FOS_RUN_BIN:-}" ]]; then
        "${_FOS_RUN_BIN}" "$@"
        return $?
    fi

    # ── Pure shell implementation ────────────────────────────────────
    local file="" hpc=0 gpu=0 show_time=0 debug=0 verbose=0 keep=0
    local extra_args=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hpc)     hpc=1 ;;
            --gpu)     gpu=1 ;;
            --time)    show_time=1 ;;
            --debug)   debug=1 ;;
            --verbose) verbose=0 ;;  # verbose=1 -- disabled: set to 0, use 1 for verbose
            --keep)    keep=1 ;;
            --list)    frun_list; return 0 ;;
            --help|-h) _frun_help; return 0 ;;
            --)        shift; extra_args="$*"; break ;;
            *)         [[ -z "$file" ]] && file="$1" ;;
        esac
        shift
    done

    if [[ -z "$file" ]]; then
        _frun_err "No source file specified."
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        _frun_err "Cannot read: $file"
        return 1
    fi

    (( hpc && debug )) && { _frun_warn "--hpc and --debug conflict; using --debug."; hpc=0; }

    local row
    row="$(_frun_detect "$file")" || {
        _frun_err "Unknown extension: .${file##*.}  (run frun_list)"
        return 1
    }

    local lang      ; lang="$(_frun_field "$row" 2)"
    local compiler  ; compiler="$(_frun_field "$row" 3)"
    local base_flags; base_flags="$(_frun_field "$row" 4)"
    local hpc_flags ; hpc_flags="$(_frun_field "$row" 5)"
    local runner    ; runner="$(_frun_field "$row" 6)"
    local hpc_env   ; hpc_env="$(_frun_field "$row" 7)"
    local hpc_cap   ; hpc_cap="$(_frun_field "$row" 8)"
    local ncpu      ; ncpu="$(_frun_nproc)"
    local tmp_bin   ; tmp_bin="/tmp/frun_$$"
    local compile_t0 compile_t1 run_t0 run_t1

    # ── Compile ───────────────────────────────────────────────────────
    local cflags="$base_flags"
    [[ "$base_flags" == "-" ]] && cflags=""
    if (( hpc )) && [[ "$hpc_flags" != "-" ]]; then
        cflags="$cflags $hpc_flags"
    fi
    [[ $debug -eq 1 ]] && cflags="-g -O0"

    if [[ "$compiler" != "-" ]]; then
        _frun_info "[${lang}]  Compiling ${file}..."

        local compile_cmd
        if [[ "$lang" == "Java" ]]; then
            compile_cmd="${compiler} ${file}"
        else
            compile_cmd="${compiler} ${cflags} -o ${tmp_bin} ${file}"
        fi

        (( verbose )) && printf '%s  $ %s%s\n' "$(_rc muted)" "$compile_cmd" "$(_rc reset)"

        compile_t0="$(_frun_ns)"
        if ! eval "$compile_cmd" 2>&1; then
            _frun_err "Compilation failed."
            return 1
        fi
        compile_t1="$(_frun_ns)"

        (( show_time )) && _frun_print_duration "Compile" $(( compile_t1 - compile_t0 ))
        _frun_ok "Compiled."
    fi

    # ── Environment + run command ──────────────────────────────────────
    local env_prefix=""
    if (( hpc )) && [[ "$hpc_env" != "-" ]] && (( hpc_cap )); then
        env_prefix="${hpc_env}=${ncpu} "
    fi

    local run_cmd
    if [[ "$compiler" != "-" ]] && [[ "$lang" != "Java" ]]; then
        run_cmd="${env_prefix}${tmp_bin} ${extra_args}"
    elif [[ "$lang" == "Java" ]]; then
        local classname; classname="${file%.*}"; classname="${classname##*/}"
        local dir; dir="$(dirname "$file")"
        run_cmd="cd '${dir}' && ${env_prefix}java ${classname} ${extra_args}"
    elif [[ "$lang" == "Julia" ]] && (( hpc )); then
        run_cmd="${runner} --threads ${ncpu} ${file} ${extra_args}"
    else
        run_cmd="${env_prefix}${runner} ${file} ${extra_args}"
    fi

    (( verbose )) && printf '%s  $ %s%s\n' "$(_rc muted)" "$run_cmd" "$(_rc reset)"

    (( hpc && hpc_cap )) && _frun_info "HPC: ${ncpu} threads"

    printf '%s🌱 Running...%s\n' "$(_rc accent)" "$(_rc reset)"
    printf '%s────────────────────────────────%s\n' "$(_rc muted)" "$(_rc reset)"

    run_t0="$(_frun_ns)"
    eval "$run_cmd"
    local exit_code=$?
    run_t1="$(_frun_ns)"

    printf '%s────────────────────────────────%s\n' "$(_rc muted)" "$(_rc reset)"

    (( show_time )) && _frun_print_duration "Run" $(( run_t1 - run_t0 ))
    (( show_time && compiler != "-" && lang != "Java" )) && \
        _frun_print_duration "Total" $(( (compile_t1 - compile_t0) + (run_t1 - run_t0) ))

    if (( exit_code == 0 )); then
        _frun_ok "Exit 0"
    else
        _frun_err "Exit ${exit_code}"
    fi

    # Cleanup temp binary
    (( keep == 0 )) && [[ -f "$tmp_bin" ]] && rm -f "$tmp_bin"

    return $exit_code
}

# ── Convenience shorthands ────────────────────────────────────────────────

frun_hpc()  { frun --hpc  --time "$@"; }
frun_time() { frun --time         "$@"; }
frun_gpu()  { frun --gpu  --hpc --time "$@"; }

frun_list() {
    if [[ -n "${_FOS_RUN_BIN:-}" ]]; then
        "${_FOS_RUN_BIN}" --list
        return
    fi
    printf '\n%s  frun — supported languages%s\n' "$(_rc secondary)" "$(_rc reset)"
    printf '%s  ──────────────────────────────────────────────────────%s\n' \
        "$(_rc muted)" "$(_rc reset)"
    printf '  %s%-8s  %-14s  %-8s  %s%s\n' \
        "$(_rc muted)" "Ext" "Language" "Compiler" "HPC" "$(_rc reset)"
    printf '%s  ──────────────────────────────────────────────────────%s\n' \
        "$(_rc muted)" "$(_rc reset)"
    for row in "${_FRUN_TABLE[@]}"; do
        local ext lang compiler hpc_cap
        ext="$(_frun_field "$row" 1)"
        lang="$(_frun_field "$row" 2)"
        compiler="$(_frun_field "$row" 3)"
        hpc_cap="$(_frun_field "$row" 8)"
        local cc_disp="interp"
        [[ "$compiler" != "-" ]] && cc_disp="$compiler"
        local hpc_disp="${_rc muted}—${_rc reset}"
        [[ "$hpc_cap" == "1" ]] && hpc_disp="${_rc green}✓${_rc reset}"
        printf '  %s%-8s%s  %-14s  %-8s  %b\n' \
            "$(_rc accent)" "$ext" "$(_rc reset)" \
            "$lang" "$cc_disp" "$hpc_disp"
    done
    printf '\n'
}

_frun_help() {
    printf '\n%sfrun%s — FlowerOS universal run\n\n' "$(_rc accent)" "$(_rc reset)"
    printf '%sUsage:%s  frun [--hpc] [--gpu] [--time] [--debug] [--keep] <file>\n\n' \
        "$(_rc muted)" "$(_rc reset)"
    printf '  %s--hpc%s    -O3 -fopenmp, OMP_NUM_THREADS=nproc\n' \
        "$(_rc accent)" "$(_rc reset)"
    printf '  %s--gpu%s    GPU flags (nvcc / OpenCL)\n' \
        "$(_rc accent)" "$(_rc reset)"
    printf '  %s--time%s   Show timing\n' \
        "$(_rc accent)" "$(_rc reset)"
    printf '  %s--debug%s  -g -O0\n' \
        "$(_rc accent)" "$(_rc reset)"
    printf '  %s--keep%s   Keep compiled binary\n' \
        "$(_rc accent)" "$(_rc reset)"
    printf '  %sfrun_list%s  Print language table\n\n' \
        "$(_rc accent)" "$(_rc reset)"
    printf '%sExamples:%s\n' "$(_rc muted)" "$(_rc reset)"
    printf '  frun hello.c\n'
    printf '  frun_hpc simulate.f90\n'
    printf '  frun_gpu particles.cu\n'
    printf '  frun_time model.py\n\n'
}
