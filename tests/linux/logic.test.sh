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
# --- che khoa khong dung regex: ky tu dac biet, khoang trang, gia tri chua / | & \
special='ab/c|d&e\f g$h'
out=$(printf 'loi voi %s xong\n' "$special" | redact_secrets "$special")
expect "$out" 'loi voi *** xong' redact-special-chars
secretfile="$tmp/secrets"
printf '%s\n' 'GIATRI.CHAM*SAO' > "$secretfile"
out=$(printf 'x GIATRI.CHAM*SAO y\nGIATRIXCHAMYSAO\n' | AISONNET_SECRET_FILE="$secretfile" redact_secrets)
expect "$out" "$(printf 'x *** y\nGIATRIXCHAMYSAO')" redact-file-literal-not-regex
# --- set_dotenv_value
envf="$tmp/set.env"
printf '# giu\nA=1\nB=\n' > "$envf"
set_dotenv_value "$envf" B hai
set_dotenv_value "$envf" C ba
expect "$(read_dotenv_value "$envf" B)" hai setenv-replace
expect "$(read_dotenv_value "$envf" C)" ba setenv-append
expect "$(head -n 1 "$envf")" '# giu' setenv-keep-comment
# --- 50-keys-sync --prepare that (khong mang): tao .env, bieu tuong, mac dinh giong
fakehome="$tmp/home"; mkdir -p "$fakehome/Desktop" "$tmp/kit-root/templates"
cp "$repo/kit/templates/env.template" "$tmp/kit-root/templates/"
HOME="$fakehome" bash "$repo/kit/scripts/mac/50-keys-sync.sh" --root "$tmp/kit-root" --prepare >/dev/null 2>&1
expect "$(read_dotenv_value "$tmp/kit-root/.env" GENMAX_VOICE_ID)" pNInz6obpgDQGcFmaJgB prepare-default-voice
expect "$(read_dotenv_value "$tmp/kit-root/.env" GENMAX_MODEL)" eleven_v3 prepare-default-model
if [ -x "$fakehome/Desktop/Mo file khoa API.command" ]; then ok prepare-desktop-command; else bad prepare-desktop-command; fi
if [ -f "$tmp/kit-root/state/keys-prepare.json" ]; then ok prepare-status-file; else bad prepare-status-file; fi
# --- 90-export-report that: khong lo khoa co ky tu dac biet, che $HOME
set_dotenv_value "$tmp/kit-root/.env" APIFY_TOKEN 'tok/en|x&y\z'
expect "$(read_dotenv_value "$tmp/kit-root/.env" APIFY_TOKEN)" 'tok/en|x&y\z' export-secret-stored
mkdir -p "$tmp/kit-root/state"
printf 'ghi chu tok/en|x&y\\z va %s/thu-muc\n' "$fakehome" > "$tmp/kit-root/SETUP-LOG.md"
HOME="$fakehome" bash "$repo/kit/scripts/mac/90-export-report.sh" --root "$tmp/kit-root" >/dev/null 2>&1
report=$(cat "$tmp/kit-root/bao-cao-ho-tro.txt" 2>/dev/null)
case "$report" in *'tok/en|x&y'*) bad export-no-leak ;; *) ok export-no-leak ;; esac
case "$report" in *"$fakehome"*) bad export-masks-home ;; *) ok export-masks-home ;; esac
# --- kit/ Mac: khong con 'status.json' ghi de, global block Mac co mac dinh Adam/v3
case "$(cat "$repo/kit/templates/global-claude-block-mac.md")" in
  *pNInz6obpgDQGcFmaJgB*eleven_v3*|*eleven_v3*pNInz6obpgDQGcFmaJgB*) ok mac-global-block-voice ;;
  *) bad mac-global-block-voice ;; esac
# --- Telegram: lay chat id tu getUpdates + phan loai ket qua gui tin
updates='{"ok":true,"result":[{"update_id":1,"message":{"chat":{"id":111,"type":"private"}}},{"update_id":2,"message":{"chat":{"id":-100222,"type":"group"}}}]}'
expect "$(printf '%s' "$updates" | extract_telegram_chat_id)" '-100222' tg-chat-id-latest
expect "$(printf '%s' '{"ok":true,"result":[]}' | extract_telegram_chat_id)" '' tg-chat-id-empty
expect "$(printf '%s' '{"result":[{"message":{"chat":{"id":987654321,"first_name":"A"}}}]}' | extract_telegram_chat_id)" '987654321' tg-chat-id-positive
expect "$(classify_telegram_send 200)" OK tg-send-ok
expect "$(classify_telegram_send 401)" E_TG_TOKEN tg-send-token
expect "$(classify_telegram_send 403)" E_TG_BLOCKED tg-send-blocked
expect "$(classify_telegram_send 400)" E_TG_CHAT tg-send-chat
expect "$(classify_telegram_send 000)" E_KEY_NETWORK tg-send-network
expect "$(classify_telegram_send 502)" E_KEY_NETWORK tg-send-5xx
printf 'PASS=%s FAIL=%s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
