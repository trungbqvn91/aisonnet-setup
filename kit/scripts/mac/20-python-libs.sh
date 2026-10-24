#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
# shellcheck disable=SC2034  # ROOT duoc common.sh (set_status, log_setup) doc
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --root) ROOT="$2"; shift ;;
    *) printf 'E_PIP: tham so khong hop le\n'; exit 1 ;;
  esac
  shift
done
. "$SCRIPT_DIR/common.sh"
VENV="$HOME/.aisonnet/venv"
BIN_DIR="$HOME/.aisonnet/bin"
if [ "$DRY_RUN" -eq 1 ]; then
  log_info "DRY-RUN: tao venv $VENV va cai Python libraries"
  exit 0
fi
if ! has_cmd python3.12; then
  set_status PYTHON E_PIP 'python3.12 missing'
  printf 'E_PIP: can chay 10-install-core.sh truoc\n'
  exit 1
fi
if [ ! -x "$VENV/bin/python" ]; then
  mkdir -p "$(dirname "$VENV")"
  python3.12 -m venv "$VENV" || { set_status PYTHON E_PIP 'venv failed'; exit 1; }
fi
"$VENV/bin/python" -m pip install \
  'faster-whisper==1.2.1' 'av==16.1.0' playwright apify-client google-genai \
  python-dotenv requests || { set_status PYTHON E_PIP 'pip install failed'; exit 1; }
mkdir -p "$BIN_DIR"
printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$VENV/bin/python" > "$BIN_DIR/aisonnet-python"
printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$VENV/bin/pip" > "$BIN_DIR/aisonnet-pip"
chmod +x "$BIN_DIR/aisonnet-python" "$BIN_DIR/aisonnet-pip"
block=$(mktemp "${TMPDIR:-/tmp}/aisonnet.profile.XXXXXX") || exit 1
printf '# AISONNET:BEGIN\nexport PATH="%s:$PATH"\nexport PYTHONUTF8=1\n# AISONNET:END\n' \
  "$BIN_DIR" > "$block"
update_marker_block "$HOME/.zprofile" '# AISONNET:BEGIN' '# AISONNET:END' "$block"
rm -f "$block"
"$VENV/bin/python" -X utf8 -c \
  'import av, faster_whisper, playwright, apify_client, google.genai, dotenv, requests' \
  || { set_status PYTHON E_PIP 'import check failed'; exit 1; }
set_status PYTHON OK 'venv and libraries complete'
