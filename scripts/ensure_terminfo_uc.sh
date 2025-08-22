#!/usr/bin/env bash
set -euo pipefail

: "${UC_DEBUG:=}"
log() { [[ -n "${UC_DEBUG:-}" ]] && echo "[ensure-terminfo-uc] $*" >&2 || true; }

uid="$(id -u)"
home="${HOME:-/tmp}"

# Decide output dir: $TERMINFO or $HOME/.terminfo; fallback to /tmp if not writable
outdir="${TERMINFO:-${home}/.terminfo}"
if ! (mkdir -p "$outdir" 2>/dev/null && [ -w "$outdir" ]); then
  outdir="/tmp/terminfo-${uid}"
  mkdir -p "$outdir"
fi

# Make sure ncurses searches our dir first, but still has system fallbacks
export TERMINFO="$outdir"
sys_dirs="/usr/share/terminfo:/lib/terminfo:/etc/terminfo"
if [[ -n "${TERMINFO_DIRS:-}" ]]; then
  export TERMINFO_DIRS="$outdir:$TERMINFO_DIRS:$sys_dirs"
else
  export TERMINFO_DIRS="$outdir:$sys_dirs"
fi

cur_term="${TERM:-xterm-256color}"
if [[ "$cur_term" == *-uc ]]; then
  base_term="${cur_term%-uc}"
  derived="$cur_term"
else
  base_term="$cur_term"
  derived="${cur_term}-uc"
fi
log "HOME=$home OUTDIR=$outdir CUR=$cur_term BASE=$base_term DERIVED=$derived"

have_caps() {
  infocmp -x "$1" >/dev/null 2>&1 && \
  infocmp -x "$1" | grep -q 'Smulx' && \
  infocmp -x "$1" | grep -q 'Setulc'
}

if ! have_caps "$derived"; then
  if infocmp -x "$base_term" >/dev/null 2>&1; then
    tmp="$(mktemp)"
    cat >"$tmp" <<EOF_TERM
${derived}|${base_term} with SGR underline style/color,
  use=${base_term},
  Smulx=\E[4::%p1%dm,
  Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m,
EOF_TERM
    if tic -x -o "$outdir" "$tmp"; then
      log "Compiled $derived into $outdir"
    else
      log "tic failed; continuing without derived entry"
    fi
    rm -f "$tmp"
  else
    log "Base terminfo '$base_term' not found; skip compile"
  fi
fi

export TERM="$derived"
log "TERM set to $TERM"
exec "$@"

