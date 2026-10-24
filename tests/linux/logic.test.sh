#!/usr/bin/env bash
set -u
repo=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ROOT="$tmp/root"
DRY_RUN=1
. "$repo/kit/scripts/mac/common.sh"
pass=0
fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail + 1)); }
expect() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3"; fi; }
dotenv="$tmp/env"
printf '# note\nA=one\nB = two \nC="three"\nD=a=b\n\nBROKEN\n' > "$dotenv"
expect "$(read_dotenv_value "$dotenv" A)" one dotenv-comment
expect "$(read_dotenv_value "$dotenv" B)" two dotenv-space
expect "$(read_dotenv_value "$dotenv" C)" three dotenv-quote
expect "$(read_dotenv_value "$dotenv" D)" a=b dotenv-equals
expect "$(read_dotenv_value "$dotenv" NONE)" '' dotenv-missing
printf '\357\273\277E=five\r\nF= six \r\n' > "$dotenv"
expect "$(read_dotenv_value "$dotenv" E)" five dotenv-bom
expect "$(read_dotenv_value "$dotenv" F)" six dotenv-crlf
expect "$(mask_key '')" '(trong)' mask-empty
expect "$(mask_key abc)" ...abc mask-short
expect "$(mask_key abcdef)" ...cdef mask-long
block="$tmp/block"
printf '# BEGIN\nnew\n# END\n' > "$block"
file="$tmp/marker"
update_marker_block "$file" '# BEGIN' '# END' "$block"
expect "$(cat "$file")" "$(cat "$block")" marker-new
printf 'before\nold\n# BEGIN\nwrong\n# END\nafter\n' > "$file"
update_marker_block "$file" '# BEGIN' '# END' "$block"
grep -q '^before$' "$file" && ok marker-keep-before || bad marker-keep-before
grep -q '^after$' "$file" && ok marker-keep-after || bad marker-keep-after
grep -q '^new$' "$file" && ok marker-replace || bad marker-replace
first=$(cat "$file")
update_marker_block "$file" '# BEGIN' '# END' "$block"
expect "$(cat "$file")" "$first" marker-idempotent
printf 'x\r\n# BEGIN\r\ny\r\n# END\r\nz\r\n' > "$file"
update_marker_block "$file" '# BEGIN' '# END' "$block"
if grep -q "$(printf '\r')" "$file"; then ok marker-crlf; else bad marker-crlf; fi
expect "$(printf 'sk_abcdefgh secret' | redact_secrets)" '*** secret' redact-sk
expect "$(printf 'AIzaabcdefghijklmnopqrst xyz' | redact_secrets)" '*** xyz' redact-aiza
expect "$(printf 'apify_api_abcdef xyz' | redact_secrets)" '*** xyz' redact-apify
expect "$(printf 'bot123456:abcdefghijklmnopqrst xyz' | redact_secrets)" '*** xyz' redact-bot
expect "$(classify_http 200)" OK http-200
expect "$(classify_http 401)" E_KEY_INVALID http-401
expect "$(classify_http 403)" E_KEY_INVALID http-403
expect "$(classify_http 429)" E_QUOTA http-429
expect "$(classify_http 000)" E_KEY_NETWORK http-000
before=$(find "$tmp" -type f | sort)
for script in "$repo"/kit/scripts/mac/[0-9]*.sh; do
  HOME="$tmp/home" bash "$script" --dry-run --root "$tmp/root" >/dev/null || bad "dry-$(basename "$script")"
  HOME="$tmp/home" bash "$script" --dry-run --root "$tmp/root" >/dev/null && ok "dry-$(basename "$script")"
done
after=$(find "$tmp" -type f | sort)
expect "$after" "$before" dry-no-files
printf 'PASS=%s FAIL=%s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
