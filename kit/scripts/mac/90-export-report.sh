#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --root) ROOT="$2"; shift ;;
    *) printf 'E_CORE_REPORT: tham so khong hop le\n'; exit 1 ;;
  esac
  shift
done
. "$SCRIPT_DIR/common.sh"
if [ "$DRY_RUN" -eq 1 ]; then log_info 'DRY-RUN: tao bao cao ho tro'; exit 0; fi
env_file="$ROOT/.env"
secrets=''
for name in APIFY_TOKEN GENMAX_API_KEY GEMINI_API_KEY TELEGRAM_BOT_TOKEN; do
  value=$(read_dotenv_value "$env_file" "$name")
  [ -z "$value" ] || secrets="$secrets $value"
done
report_tmp=$(mktemp "${TMPDIR:-/tmp}/aisonnet.report.XXXXXX") || exit 1
{
  printf 'AISONNET macOS DRAFT support report\n'
  [ -f "$ROOT/state/status.json" ] && cat "$ROOT/state/status.json"
  [ -f "$ROOT/state/preflight.json" ] && cat "$ROOT/state/preflight.json"
  [ -f "$ROOT/SETUP-LOG.md" ] && tail -n 80 "$ROOT/SETUP-LOG.md"
  for tool in git python3.12 ffmpeg brew; do
    if has_cmd "$tool"; then "$tool" --version 2>/dev/null | head -n 1; fi
  done
} > "$report_tmp"
set --
for secret in $secrets; do set -- "$@" "$secret"; done
redact_secrets "$@" < "$report_tmp" | sed "s|$HOME|~|g" > "$ROOT/bao-cao-ho-tro.txt"
rm -f "$report_tmp"
set_status REPORT OK 'support report exported'
