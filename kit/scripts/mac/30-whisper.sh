#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
MODEL=base
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --root) ROOT="$2"; shift ;;
    --model) MODEL="$2"; shift ;;
    *) printf 'E_WHISPER_RUN: tham so khong hop le\n'; exit 1 ;;
  esac
  shift
done
. "$SCRIPT_DIR/common.sh"
PYTHON="$HOME/.aisonnet/venv/bin/python"
if [ "$DRY_RUN" -eq 1 ]; then log_info "DRY-RUN: whisper model $MODEL"; exit 0; fi
if [ ! -x "$PYTHON" ]; then set_status WHISPER E_WHISPER_RUN 'venv missing'; exit 1; fi
sample="$ROOT/assets/sample-vi.wav"
expect="$ROOT/assets/sample-vi.expect.txt"
if [ ! -f "$sample" ] || [ ! -f "$expect" ]; then
  set_status WHISPER E_WHISPER_RUN 'sample assets missing'
  exit 1
fi
worker=$(mktemp "${TMPDIR:-/tmp}/aisonnet.whisper.XXXXXX.py") || exit 1
cat > "$worker" <<'PY'
import sys, unicodedata
from faster_whisper import WhisperModel
model_name, sample, expected = sys.argv[1:]
try:
    model = WhisperModel(model_name, device="cpu", compute_type="int8")
except Exception:
    sys.exit(20)
try:
    segments, _ = model.transcribe(sample)
    text = " ".join(s.text for s in segments)
except Exception:
    sys.exit(21)
def plain(value):
    value = value.replace("đ", "d").replace("Đ", "D")
    return "".join(c for c in unicodedata.normalize("NFD", value.lower())
                   if unicodedata.category(c) != "Mn")
keys = [plain(x.strip()) for x in open(expected, encoding="utf-8") if x.strip()]
hits = sum(1 for key in keys if key in plain(text))
print("Transcript (rut gon): " + plain(text)[:180])
print("HITS=" + str(hits))
sys.exit(0 if hits >= 2 else 22)
PY
"$PYTHON" -X utf8 "$worker" "$MODEL" "$sample" "$expect"
result=$?
rm -f "$worker"
case "$result" in
  0) set_status WHISPER OK 'sample transcript passed' ;;
  20) set_status WHISPER E_WHISPER_DOWNLOAD 'model download failed'; exit 1 ;;
  *) set_status WHISPER E_WHISPER_RUN 'transcript failed'; exit 1 ;;
esac
