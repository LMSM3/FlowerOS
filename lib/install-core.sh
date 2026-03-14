#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  lib/install-core.sh  —  FlowerOS Installation Engine                   ║
# ║                                                                          ║
# ║  Sourced by:  install.sh · install-permanent.sh                         ║
# ║               uninstall.sh · remove-permanent.sh                        ║
# ║                                                                          ║
# ║  Sections:                                                               ║
# ║    I.    Presentation   fos_draw_header, fos_stage, fos_progress_bar    ║
# ║    II.   Sentinels      FOS_MARKER_BEGIN / FOS_MARKER_END               ║
# ║    III.  Manifests      FOS_CORE_BINS[], FOS_CORE_SRCS[]                ║
# ║    IV.   Build          fos_build_core, fos_install_core_bins           ║
# ║    V.    Assets         fos_copy_assets, fos_copy_libs                  ║
# ║    VI.   Network        fos_download, fos_verify_checksum               ║
# ║    VII.  Auth           fos_auth_prompt, fos_auth_check                 ║
# ║    VIII. Bashrc         fos_inject_bashrc, fos_remove_bashrc_block      ║
# ║    IX.   Version        fos_write_version                               ║
# ║                                                                          ║
# ║  Architecture:  acquire  →  verify  →  build  →  graft  →  bloom       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

[[ -n "${_FOS_INSTALL_CORE:-}" ]] && return 0
_FOS_INSTALL_CORE=1

# ── Source shared colors ──────────────────────────────────────────────────
_FOS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$_FOS_LIB_DIR/colors.sh" ]]; then
  source "$_FOS_LIB_DIR/colors.sh"
else
  # Inline fallback — keeps scripts functional without the lib dir
  ok()   { printf "\033[32m✓\033[0m %s\n" "$*"; }
  err()  { printf "\033[31m✗\033[0m %s\n" "$*" >&2; }
  info() { printf "\033[36m✿\033[0m %s\n" "$*"; }
  warn() { printf "\033[33m⚠\033[0m %s\n" "$*"; }
  die()  { err "$*"; exit 1; }
fi

# Private color aliases — safe alongside colors.sh (which uses 1-letter vars)
_fm='\033[35m'         # magenta  — brand / borders
_fm2='\033[38;5;183m'  # soft magenta — accent
_fc='\033[36m'         # cyan  — labels
_fg='\033[38;5;120m'   # bright green — values
_fy='\033[33m'         # yellow — warn / prompt
_fd='\033[2m'          # dim — secondary text
_fdim='\033[38;5;245m' # true dim gray
_fk='\033[1m'          # bold
_fz='\033[0m'          # reset

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  I.  PRESENTATION LAYER                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# Full-width branded header.  Call once at the top of each installer.
#   fos_draw_header [title] [subtitle]
fos_draw_header() {
  local title="${1:-Installation Engine}"
  local sub="${2:-acquire  →  verify  →  build  →  graft  →  bloom}"
  echo ""
  echo -e "${_fm2}╔══════════════════════════════════════════════════════════════╗${_fz}"
  echo -e "${_fm2}║${_fz}                                                              ${_fm2}║${_fz}"
  echo -e "${_fm2}║${_fz}  ${_fm}${_fk}✿  FlowerOS${_fz}  ${_fdim}—${_fz}  ${_fk}${title}${_fz}"
  echo -e "${_fm2}║${_fz}     ${_fdim}${sub}${_fz}"
  echo -e "${_fm2}║${_fz}                                                              ${_fm2}║${_fz}"
  echo -e "${_fm2}╚══════════════════════════════════════════════════════════════╝${_fz}"
  echo ""
}

# Themed stage banner — call before each major install phase.
#   fos_stage <n> <total> <label>
fos_stage() {
  local n="$1"
  local total="$2"
  local label="$3"
  printf "\n  ${_fm2}❊${_fz}  ${_fdim}[${_fz}${_fk}%s${_fz}${_fdim}/%s${_fz}${_fdim}]${_fz}  ${_fdim}────────────────────────────────${_fz}  ${_fc}%s${_fz}\n" \
    "$n" "$total" "$label"
}

# ASCII progress bar.
#   fos_progress_bar <current> <total> [label]
fos_progress_bar() {
  local current="$1"
  local total="$2"
  local label="${3:-}"
  local bar_width=28
  (( total < 1 )) && total=1
  local filled=$(( current * bar_width / total ))
  local empty=$(( bar_width - filled ))
  local bar=""
  local i
  for (( i = 0; i < filled; i++ )); do bar+="█"; done
  for (( i = 0; i < empty;  i++ )); do bar+="░"; done
  printf "  ${_fdim}%s${_fz}  ${_fc}%3d%%${_fz}  %s\n" \
    "$bar" "$(( current * 100 / total ))" "$label"
}

# Thin themed divider with an optional label.
#   fos_divider [label]
fos_divider() {
  local label="${1:-}"
  if [[ -n "$label" ]]; then
    printf "\n  ${_fm2}─${_fz}  ${_fdim}%s${_fz}\n\n" "$label"
  else
    printf "\n  ${_fdim}──────────────────────────────────────────────────────────────${_fz}\n\n"
  fi
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  II.  SENTINEL MARKERS  (one definition — every installer / uninstaller) ║
# ╚══════════════════════════════════════════════════════════════════════════╝

readonly FOS_MARKER_BEGIN="# BEGIN FlowerOS"
readonly FOS_MARKER_END="# END FlowerOS"

# Legacy markers — recognised during removal for upgrade safety
readonly _FOS_LEGACY_MARKER_1="# FlowerOS ASCII Integration"
readonly _FOS_LEGACY_MARKER_2="FLOWEROS_SYSTEM_INTEGRATION"

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  III.  BINARY MANIFESTS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

FOS_CORE_BINS=(random animate banner fortune colortest)
FOS_CORE_SRCS=(src/utils/random.c src/utils/animate.c src/utils/banner.c
               src/utils/fortune.c src/utils/colortest.c)

# Extended binaries — built by build.sh, not by fos_build_core.
# Listed here so fos_install_extended_bins can find them.
FOS_EXTENDED_BINS=(visual flower-guy flower-walk fp flower-run
                   flower-chess flower-colony flower-td flower-play)

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  IV.  BUILD HELPERS                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# Detect feature flags once (cached in FOS_FEATURES).
fos_detect_features() {
  FOS_FEATURES=""
  [[ -c /dev/urandom ]]                && FOS_FEATURES+=" -DHAS_URANDOM"
  command -v tput >/dev/null 2>&1      && FOS_FEATURES+=" -DHAS_TERMCAP"
}

# Build the 5 core C binaries in the current directory.
# Accepts optional extra CFLAGS (e.g. "-pedantic").
fos_build_core() {
  local extra="${1:-}"
  local cflags="-O2 -std=c11 -Wall -Wextra $extra"

  command -v gcc >/dev/null 2>&1 \
    || die "gcc not found.  Install build-essential."

  [[ -n "${FOS_FEATURES+x}" ]] || fos_detect_features

  local total="${#FOS_CORE_SRCS[@]}"
  local built=0
  for i in "${!FOS_CORE_SRCS[@]}"; do
    local src="${FOS_CORE_SRCS[$i]}"
    local bin="${FOS_CORE_BINS[$i]}"
    if [[ -f "$src" ]]; then
      info "Compiling $src..."
      gcc $cflags $FOS_FEATURES -o "$bin" "$src" \
        || die "Failed to compile $src"
      built=$(( built + 1 ))
      fos_progress_bar "$built" "$total" "$bin"
    fi
  done
}

# Copy (or build-then-copy) core binaries into $1.
fos_install_core_bins() {
  local target_dir="$1"
  mkdir -p "$target_dir"

  local copied=0
  for bin in "${FOS_CORE_BINS[@]}"; do
    if [[ -x "./$bin" ]]; then
      install -m 755 "./$bin" "$target_dir/" && copied=$(( copied + 1 ))
    fi
  done

  if (( copied > 0 )); then
    ok "Installed $copied core binaries to $target_dir"
  else
    info "No pre-built binaries; building from source..."
    fos_build_core
    for bin in "${FOS_CORE_BINS[@]}"; do
      [[ -x "./$bin" ]] && install -m 755 "./$bin" "$target_dir/"
    done
    ok "Built and installed core binaries to $target_dir"
  fi
}

# Install any available extended binaries into $1.
fos_install_extended_bins() {
  local target_dir="$1"
  mkdir -p "$target_dir"

  for bin in "${FOS_EXTENDED_BINS[@]}"; do
    local found=""
    for cand in "./$bin" "src/$bin"; do
      [[ -x "$cand" ]] && { found="$cand"; break; }
    done
    if [[ -n "$found" ]]; then
      install -m 755 "$found" "$target_dir/" && ok "Installed: $bin"
    fi
  done
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  V.  ASSET HELPERS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# Copy .ascii, .txt, .anim from CWD into $1.
fos_copy_assets() {
  local target_dir="$1"
  mkdir -p "$target_dir"

  local count=0
  for pat in '*.ascii' '*.txt' '*.anim'; do
    for f in $pat; do
      [[ -f "$f" ]] || continue
      cp "$f" "$target_dir/" && count=$(( count + 1 ))
    done
  done
  (( count > 0 )) && ok "Copied $count asset files to $target_dir"
}

# Copy lib/ tree into $1 (preserves structure).
fos_copy_libs() {
  local target_dir="$1"
  [[ -d "lib" ]] || return 0
  mkdir -p "$target_dir"
  cp -r lib/* "$target_dir/" 2>/dev/null || true
  ok "Installed library files to $target_dir"
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  VI.  NETWORK / DOWNLOAD LAYER                                           ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# Base URL for release tarballs (override via env for mirrors / staging).
FOS_REGISTRY_URL="${FOS_REGISTRY_URL:-https://github.com/floweros/floweros/releases/download}"

# Detect which downloader is available.  Prints 'curl', 'wget', or ''.
fos_check_downloader() {
  if   command -v curl >/dev/null 2>&1; then printf 'curl'
  elif command -v wget >/dev/null 2>&1; then printf 'wget'
  else                                       printf ''
  fi
}

# Download a URL to a local path with a labelled progress line.
#   fos_download <url> <dest> [label]
# Returns 0 on success, 1 on failure.
fos_download() {
  local url="$1"
  local dest="$2"
  local label="${3:-$(basename "$dest")}"

  local dl; dl="$(fos_check_downloader)"
  if [[ -z "$dl" ]]; then
    warn "No downloader found (curl / wget).  Skipping: $label"
    return 1
  fi

  info "Downloading $label..."
  local tmp; tmp="$(mktemp)"
  local rc=0

  case "$dl" in
    curl) curl -fsSL --progress-bar "$url" -o "$tmp" 2>&1 || rc=$? ;;
    wget) wget -q --show-progress -O "$tmp" "$url"   2>&1 || rc=$? ;;
  esac

  if (( rc != 0 )) || [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    err "Download failed: $label"
    return 1
  fi

  mv "$tmp" "$dest"
  ok "Downloaded: $label"
}

# Verify the SHA-256 checksum of a file.
#   fos_verify_checksum <file> <expected_sha256>
fos_verify_checksum() {
  local file="$1"
  local expected="$2"

  if ! command -v sha256sum >/dev/null 2>&1 && \
     ! command -v shasum    >/dev/null 2>&1; then
    warn "sha256sum / shasum not found — skipping integrity check"
    return 0
  fi

  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  fi

  if [[ "$actual" != "$expected" ]]; then
    err "Checksum mismatch: $(basename "$file")"
    err "  expected : $expected"
    err "  got      : $actual"
    return 1
  fi

  ok "Verified: $(basename "$file")"
}

# Download a versioned FlowerOS release tarball, verify, and extract.
#   fos_fetch_release <version> <dest_dir> [sha256]
#
#   version  — e.g. "v1.3.0"
#   dest_dir — directory to extract into (created if absent)
#   sha256   — optional expected checksum
fos_fetch_release() {
  local version="${1:-v1.3.0}"
  local dest_dir="$2"
  local checksum="${3:-}"

  local tarball="floweros-${version}.tar.gz"
  local url="${FOS_REGISTRY_URL}/${version}/${tarball}"
  local tmp_tar; tmp_tar="$(mktemp --suffix=.tar.gz)"

  fos_download "$url" "$tmp_tar" "$tarball" || return 1

  if [[ -n "$checksum" ]]; then
    fos_verify_checksum "$tmp_tar" "$checksum" || { rm -f "$tmp_tar"; return 1; }
  fi

  mkdir -p "$dest_dir"
  info "Extracting $tarball..."
  tar -xzf "$tmp_tar" -C "$dest_dir" --strip-components=1 \
    || { err "Extraction failed"; rm -f "$tmp_tar"; return 1; }

  rm -f "$tmp_tar"
  ok "Release $version ready in $dest_dir"
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  VII.  AUTH / LOGIN LAYER                                                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# Auth state file — owner-readable only (chmod 600).
FOS_AUTH_FILE="${FOS_AUTH_FILE:-${HOME}/.floweros/auth}"

# FlowerOS account endpoint (override for dev / staging).
FOS_AUTH_URL="${FOS_AUTH_URL:-https://floweros.dev/api/v1/auth}"

# ── Credential persistence ────────────────────────────────────────────────

# Load persisted credentials into FOS_AUTH_USER / FOS_AUTH_TOKEN.
# Returns 0 if both are non-empty, 1 otherwise.
fos_auth_load() {
  FOS_AUTH_USER=""
  FOS_AUTH_TOKEN=""
  [[ -f "$FOS_AUTH_FILE" ]] || return 1

  local key val
  while IFS='=' read -r key val; do
    case "$key" in
      user)  FOS_AUTH_USER="$val"  ;;
      token) FOS_AUTH_TOKEN="$val" ;;
    esac
  done < "$FOS_AUTH_FILE"

  [[ -n "$FOS_AUTH_USER" && -n "$FOS_AUTH_TOKEN" ]]
}

# Persist credentials to the auth file (mode 600).
#   fos_auth_save <user> <token>
fos_auth_save() {
  local user="$1"
  local token="$2"
  mkdir -p "$(dirname "$FOS_AUTH_FILE")"
  printf 'user=%s\ntoken=%s\n' "$user" "$token" > "$FOS_AUTH_FILE"
  chmod 600 "$FOS_AUTH_FILE"
  ok "Credentials saved for ${user}"
}

# Returns 0 when a valid session is already on disk.
fos_auth_check() {
  fos_auth_load && [[ -n "$FOS_AUTH_USER" ]]
}

# ── Interactive login prompt ──────────────────────────────────────────────

# Present a styled login prompt, attempt remote verification when a
# downloader is available, and persist the result.
#
#   fos_auth_prompt [--optional]
#
#   --optional  allows the user to press Enter to skip (offline installs).
fos_auth_prompt() {
  local optional=0
  [[ "${1:-}" == "--optional" ]] && optional=1

  # Already authenticated — nothing to do.
  if fos_auth_check; then
    ok "Signed in as ${_fg}${FOS_AUTH_USER}${_fz}"
    return 0
  fi

  echo ""
  echo -e "${_fm2}╔══════════════════════════════════════════════════════════════╗${_fz}"
  echo -e "${_fm2}║${_fz}  ${_fm}${_fk}✿  FlowerOS Account${_fz}                                        ${_fm2}║${_fz}"
  echo -e "${_fm2}║${_fz}     ${_fdim}Sign in to sync themes, preferences, and updates.${_fz}     ${_fm2}║${_fz}"
  if (( optional )); then
    echo -e "${_fm2}║${_fz}     ${_fdim}Press Enter on any field to continue offline.${_fz}         ${_fm2}║${_fz}"
  fi
  echo -e "${_fm2}╚══════════════════════════════════════════════════════════════╝${_fz}"
  echo ""

  local user token
  printf "  ${_fc}Username / email  :${_fz}  "
  read -r user

  if [[ -z "$user" ]] && (( optional )); then
    info "Continuing offline — account features skipped"
    return 0
  fi

  printf "  ${_fc}Token / password  :${_fz}  "
  read -rs token
  echo ""

  if [[ -z "$user" || -z "$token" ]]; then
    warn "Empty credentials — login skipped"
    return 1
  fi

  # Attempt remote verification when a downloader is present.
  local dl; dl="$(fos_check_downloader)"
  if [[ -n "$dl" ]]; then
    info "Authenticating with FlowerOS servers..."
    local http_code=""

    case "$dl" in
      curl)
        http_code="$(
          curl -s -o /dev/null -w "%{http_code}" \
            -X POST "${FOS_AUTH_URL}/login" \
            -H "Content-Type: application/json" \
            -d "{\"user\":\"${user}\",\"token\":\"${token}\"}" \
            --connect-timeout 6 --max-time 12 2>/dev/null
        )" ;;
      wget)
        http_code="$(
          wget -q -O /dev/null \
            --post-data="{\"user\":\"${user}\",\"token\":\"${token}\"}" \
            --server-response \
            "${FOS_AUTH_URL}/login" 2>&1 \
            | awk '/HTTP\//{print $2}' | tail -1
        )" ;;
    esac

    case "${http_code:-000}" in
      200|201)
        fos_auth_save "$user" "$token"
        ok "Authenticated  —  welcome, ${_fg}${user}${_fz}" ;;
      401|403)
        err "Invalid credentials (${http_code})"
        return 1 ;;
      ""|000)
        warn "Server unreachable  —  credentials saved for offline use"
        fos_auth_save "$user" "$token" ;;
      *)
        warn "Unexpected response (${http_code})  —  saved for offline use"
        fos_auth_save "$user" "$token" ;;
    esac
  else
    warn "No downloader available  —  credentials saved locally (unverified)"
    fos_auth_save "$user" "$token"
  fi
}

# Clear the persisted auth session.
fos_auth_logout() {
  if [[ -f "$FOS_AUTH_FILE" ]]; then
    rm -f "$FOS_AUTH_FILE"
    ok "Logged out"
  else
    info "No active session"
  fi
  FOS_AUTH_USER=""
  FOS_AUTH_TOKEN=""
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  VIII.  BASHRC INJECT / REMOVE                                           ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# Inject a sentinel-guarded block into a rc file.
#
#   fos_inject_bashrc <file> <content_func> [line_number]
#
#   content_func: function that prints the block body (no sentinels).
#   line_number:  if set, insert at that line; else append.
fos_inject_bashrc() {
  local rcfile="$1"
  local content_func="$2"
  local at_line="${3:-}"
  touch "$rcfile"

  if grep -qF "$FOS_MARKER_BEGIN" "$rcfile" 2>/dev/null; then
    ok "Already integrated in $rcfile"
    return 0
  fi

  local block
  block="$(
    echo "$FOS_MARKER_BEGIN"
    "$content_func"
    echo "$FOS_MARKER_END"
  )"

  if [[ -n "$at_line" ]]; then
    local tmp; tmp=$(mktemp)
    head -n "$at_line"              "$rcfile" > "$tmp"
    printf '\n%s\n' "$block"                 >> "$tmp"
    tail -n +"$(( at_line + 1 ))"  "$rcfile" >> "$tmp"
    mv "$tmp" "$rcfile"
  else
    printf '\n%s\n' "$block" >> "$rcfile"
  fi
  ok "Integrated into $rcfile"
}

# Remove the sentinel block (and any legacy blocks) from a rc file.
fos_remove_bashrc_block() {
  local rcfile="$1"
  [[ -f "$rcfile" ]] || return 0

  local changed=0

  # Current sentinel
  if grep -qF "$FOS_MARKER_BEGIN" "$rcfile" 2>/dev/null; then
    local tmp; tmp=$(mktemp)
    sed "/^${FOS_MARKER_BEGIN}$/,/^${FOS_MARKER_END}$/d" "$rcfile" > "$tmp"
    mv "$tmp" "$rcfile"
    changed=1
  fi

  # Legacy marker 1: install.sh old format (marker → fi)
  if grep -qF "$_FOS_LEGACY_MARKER_1" "$rcfile" 2>/dev/null; then
    local tmp; tmp=$(mktemp)
    sed "/^${_FOS_LEGACY_MARKER_1}$/,/^fi$/d" "$rcfile" > "$tmp"
    mv "$tmp" "$rcfile"
    changed=1
  fi

  # Legacy marker 2: install-permanent.sh old format
  if grep -qF "$_FOS_LEGACY_MARKER_2" "$rcfile" 2>/dev/null; then
    local tmp; tmp=$(mktemp)
    sed "/${_FOS_LEGACY_MARKER_2}/,/source.*flowerrc/d" "$rcfile" > "$tmp"
    mv "$tmp" "$rcfile"
    changed=1
  fi

  (( changed )) && ok "Removed FlowerOS block(s) from $rcfile"
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  IX.  VERSION FILE                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

fos_write_version() {
  local target_file="$1"
  local build_type="${2:-user}"
  cat > "$target_file" <<EOF
FlowerOS v1.3.0
Build: ${build_type}
Installed: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
EOF
  ok "Wrote VERSION to $target_file"
}

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  End lib/install-core.sh                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝
