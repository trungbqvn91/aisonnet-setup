#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
QUICK=0
while [ "$#" -gt 0 ]; do
  case "$1" in --dry-run) DRY_RUN=1 ;; --root) ROOT="$2"; shift ;;
    --quick) QUICK=1 ;; *) printf 'E_CORE_SMOKE: tham so khong hop le\n'; exit 1 ;; esac
  shift
done
. "$SCRIPT_DIR/common.sh"
if [ "$DRY_RUN" -eq 1 ]; then log_info 'DRY-RUN: smoke test'; exit 0; fi
result=0
row() { printf '%s | %s | %s\n' "$1" "$2" "$3"; }
for tool in git python3.12 ffmpeg; do
  if has_cmd "$tool"; then row "$tool" OK 'co san'; else row "$tool" LOI 'thieu'; result=1; fi
done
if has_cmd claude; then row claude OK 'co san'; else row claude DEFERRED 'CLI khong bat buoc'; fi
python="$HOME/.aisonnet/venv/bin/python"
if [ -x "$python" ] && "$python" -X utf8 -c \
  'import faster_whisper,playwright,apify_client,google.genai,dotenv,requests'; then
  row python-libs OK 'import du'; else row python-libs LOI 'import loi'; result=1; fi
if [ -f "$ROOT/assets/sample-vi.wav" ] && has_cmd ffmpeg; then
  out=$(mktemp "${TMPDIR:-/tmp}/aisonnet.smoke.XXXXXX.wav")
  ffmpeg -y -t 1 -i "$ROOT/assets/sample-vi.wav" "$out" >/dev/null 2>&1
  if [ -s "$out" ]; then
    row ffmpeg-sample OK 'cat duoc 1 giay'
  else
    row ffmpeg-sample LOI 'file rong'
    result=1
  fi
  rm -f "$out"
fi
if [ "$QUICK" -eq 0 ]; then
  "$SCRIPT_DIR/30-whisper.sh" --root "$ROOT" || result=1
  "$SCRIPT_DIR/40-browser-tools.sh" --root "$ROOT" || result=1
else
  row whisper BO_QUA 'quick'; row playwright BO_QUA 'quick'
fi
for key_name in APIFY_TOKEN GENMAX_API_KEY GEMINI_API_KEY; do
  key_value=$(printenv "$key_name" 2>/dev/null || true)
  if [ -n "$key_value" ]; then
    row "$key_name" OK "$(mask_key "$key_value")"
  else
    row "$key_name" BO_QUA '(trong)'
  fi
done
if grep -q '<!-- AISONNET:BEGIN' "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  row global-block OK 'co'
else
  row global-block BO_QUA 'chua co'
fi
if [ "$result" -eq 0 ]; then
  log_info 'KET LUAN: READY_WITH_DEFERRED (claude hoac key tuy chon)'
  set_status SMOKE OK 'smoke complete'
  exit 0
fi
log_info 'KET LUAN: NOT_READY (xem dong LOI)'
set_status SMOKE E_CORE_SMOKE 'smoke failed'
exit 1
