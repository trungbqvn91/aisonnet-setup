#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u

# Shared helpers for the draft macOS scripts.
log_info() { printf '%s\n' "$*"; }

# Append one safe progress line to the setup log.
log_setup() {
  mkdir -p "$ROOT"
  printf '%s | %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >> "$ROOT/SETUP-LOG.md"
}

# Store machine-readable phase status without secrets.
set_status() {
  phase="$1"; code="$2"; msg="$3"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then log_info "DRY-RUN status: $phase $code $msg"; return 0; fi
  mkdir -p "$ROOT/state"
  safe_msg=$(printf '%s' "$msg" | tr '"\n\r' '   ')
  printf '{"phase":"%s","code":"%s","time":"%s","msg":"%s"}\n' \
    "$phase" "$code" "$(date '+%Y-%m-%dT%H:%M:%S')" "$safe_msg" > "$ROOT/state/status.json"
  log_setup "$phase | $code | $safe_msg"
}

# Show only the final four characters of a value.
mask_key() {
  value=${1:-}
  if [ -z "$value" ]; then printf '(trong)'; return 0; fi
  if [ "${#value}" -le 4 ]; then printf '...%s' "$value"; return 0; fi
  printf '...%s' "${value#${value%????}}"
}

# Read dotenv values with comments, CRLF, BOM, quotes, and embedded equals.
read_dotenv_value() {
  dotenv_file="$1"; dotenv_name="$2"
  [ -f "$dotenv_file" ] || return 0
  awk -v wanted="$dotenv_name" '
    NR == 1 { sub(/^\357\273\277/, "") }
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    {
      line = $0; sub(/\r$/, "", line); pos = index(line, "=")
      if (pos == 0) next
      key = substr(line, 1, pos - 1); value = substr(line, pos + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (key == wanted) {
        if ((value ~ /^".*"$/) || (value ~ /^\047.*\047$/)) {
          value = substr(value, 2, length(value) - 2)
        }
        print value; exit
      }
    }
  ' "$dotenv_file"
}

# Replace a marked block and retain the file's line ending style.
update_marker_block() {
  marker_file="$1"; marker_begin="$2"; marker_end="$3"; marker_block="$4"
  marker_dir=$(dirname "$marker_file"); marker_tmp="${marker_file}.aisonnet.$$"
  mkdir -p "$marker_dir"
  [ -f "$marker_file" ] || : > "$marker_file"
  if grep -q "$(printf '\r')" "$marker_file"; then marker_crlf=1; else marker_crlf=0; fi
  awk -v begin="$marker_begin" -v end="$marker_end" -v block="$marker_block" \
    -v crlf="$marker_crlf" '
    BEGIN { skipping = 0; inserted = 0; if (crlf == 1) ORS = "\r\n" }
    {
      line = $0; sub(/\r$/, "", line)
      if (index(line, begin) == 1) {
        while ((getline nextline < block) > 0) { sub(/\r$/, "", nextline); print nextline }
        close(block); inserted = 1; skipping = 1; next
      }
      if (skipping == 1) { if (index(line, end) == 1) skipping = 0; next }
      print line
    }
    END {
      if (inserted == 0) {
        while ((getline nextline < block) > 0) { sub(/\r$/, "", nextline); print nextline }
        close(block)
      }
    }
  ' "$marker_file" > "$marker_tmp"
  mv "$marker_tmp" "$marker_file"
}

# Redact known secret patterns and optional literal values from stdin.
redact_secrets() {
  redacted=$(cat)
  for secret in "$@"; do
    [ -n "$secret" ] || continue
    redacted=$(printf '%s' "$redacted" | sed "s|$secret|***|g")
  done
  printf '%s\n' "$redacted" | sed \
    -e 's/sk_[A-Za-z0-9][A-Za-z0-9]*/***/g' \
    -e 's/AIza[0-9A-Za-z_-][0-9A-Za-z_-]*/***/g' \
    -e 's/apify_api_[A-Za-z0-9][A-Za-z0-9]*/***/g' \
    -e 's/bot[0-9][0-9]*:[A-Za-z0-9_-][A-Za-z0-9_-]*/***/g'
}

# Execute a command unless this is a dry run.
run_or_dry() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then log_info "DRY-RUN: $*"; return 0; fi
  "$@"
}

# Test whether an executable is available.
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Return the conventional Homebrew prefix for this CPU family.
brew_prefix() {
  if [ "$(uname -m 2>/dev/null || true)" = "arm64" ]; then
    printf '%s\n' '/opt/homebrew'
  else
    printf '%s\n' '/usr/local'
  fi
}

# Fetch only a status code while headers stay in a private temporary file.
http_status() {
  http_url="$1"; shift
  http_headers=$(mktemp "${TMPDIR:-/tmp}/aisonnet.headers.XXXXXX") || return 1
  : > "$http_headers"
  while [ "$#" -gt 0 ]; do
    [ -z "$1" ] || printf '%s\n' "$1" >> "$http_headers"
    shift
  done
  if [ -s "$http_headers" ]; then
    http_code=$(curl -s -o /dev/null -w '%{http_code}' -H "@$http_headers" "$http_url" 2>/dev/null)
  else
    http_code=$(curl -s -o /dev/null -w '%{http_code}' "$http_url" 2>/dev/null)
  fi
  rm -f "$http_headers"
  printf '%s\n' "${http_code:-000}"
}

# Map HTTP status to the common key validation result.
classify_http() {
  case "$1" in
    200) printf '%s\n' 'OK' ;;
    401|403) printf '%s\n' 'E_KEY_INVALID' ;;
    429) printf '%s\n' 'E_QUOTA' ;;
    000) printf '%s\n' 'E_KEY_NETWORK' ;;
    *) printf '%s\n' 'E_KEY_INVALID' ;;
  esac
}
