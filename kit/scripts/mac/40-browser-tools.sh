#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in --dry-run) DRY_RUN=1 ;; --root) ROOT="$2"; shift ;;
    *) printf 'E_CORE_BROWSER: tham so khong hop le\n'; exit 1 ;; esac
  shift
done
. "$SCRIPT_DIR/common.sh"
PYTHON="$HOME/.aisonnet/venv/bin/python"
if [ "$DRY_RUN" -eq 1 ]; then log_info 'DRY-RUN: playwright chromium'; exit 0; fi
if [ ! -x "$PYTHON" ]; then set_status BROWSER E_CORE_BROWSER 'venv missing'; exit 1; fi
if ! "$PYTHON" -m playwright install chromium; then
  set_status BROWSER E_CORE_BROWSER 'browser install failed'
  exit 1
fi
"$PYTHON" - <<'PY'
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("data:text/html,<title>ok</title>")
    assert page.title() == "ok"
    browser.close()
PY
url=$(grep -E 'claude_chrome_extension_url' "$ROOT/assets/links.json" 2>/dev/null | cut -d '"' -f 4)
if [ -n "${url:-}" ]; then log_info "Extension URL co san: $url"; fi
set_status BROWSER OK 'playwright complete'
