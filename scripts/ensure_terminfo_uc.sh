#!/usr/bin/env bash
set -euo pipefail

# Current TERM (from host); default to xterm-256color if empty
CUR_TERM="${TERM:-xterm-256color}"

# If already '-uc', derive base; else set desired '-uc'
if [[ "$CUR_TERM" == *-uc ]]; then
  BASE_TERM="${CUR_TERM%-uc}"
  DERIVED_TERM="$CUR_TERM"
else
  BASE_TERM="$CUR_TERM"
  DERIVED_TERM="${CUR_TERM}-uc"
fi

# If derived entry exists AND has Smulx/Setulc, just switch TERM and run
if infocmp -x "$DERIVED_TERM" >/dev/null 2>&1 && \
   infocmp -x "$DERIVED_TERM" | grep -q 'Smulx' && \
   infocmp -x "$DERIVED_TERM" | grep -q 'Setulc'; then
  export TERM="$DERIVED_TERM"
  exec "$@"
fi

# If base terminfo missing, give up gracefully
if ! infocmp -x "$BASE_TERM" >/dev/null 2>&1; then
  echo "[warn] base terminfo '$BASE_TERM' not found; continuing with '$CUR_TERM'" >&2
  exec "$@"
fi

tmp="$(mktemp)"
cat >"$tmp" <<EOF
${DERIVED_TERM}|${BASE_TERM} with SGR underline style/color,
  use=${BASE_TERM},
  Smulx=\E[4::%p1%dm,
  Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m,
EOF

# Compile to user terminfo dir
tic -x -o "${HOME}/.terminfo" "$tmp" || true
rm -f "$tmp"

export TERM="$DERIVED_TERM"
exec "$@"
