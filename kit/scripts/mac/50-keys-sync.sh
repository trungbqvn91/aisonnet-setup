#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
CHECK_ONLY=0
SKIP_TELEGRAM=0
FETCH_CHAT=0
PREPARE=0
OPEN_EDITOR=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --root) ROOT="$2"; shift ;;
    --check-only) CHECK_ONLY=1 ;;
    --skip-telegram) SKIP_TELEGRAM=1 ;;
    --fetch-telegram-chat-id) FETCH_CHAT=1 ;;
    --prepare) PREPARE=1 ;;
    --open-editor) OPEN_EDITOR=1 ;;
    *) printf 'E_KEY_INVALID: tham so khong hop le\n'; exit 1 ;;
  esac
  shift
done
. "$SCRIPT_DIR/common.sh"
if [ "$DRY_RUN" -eq 1 ]; then log_info 'DRY-RUN: kiem tra va dong bo khoa'; exit 0; fi
env_file="$ROOT/.env"
if [ ! -f "$env_file" ]; then
  if [ -f "$ROOT/templates/env.template" ]; then cp "$ROOT/templates/env.template" "$env_file"; else
    set_status KEYS E_KEY_INVALID 'env template missing'; exit 1
  fi
fi
# Giong doc mac dinh cua khoa hoc (Adam, ElevenLabs v3, the cam xuc): chi dien khi con trong.
if [ "$CHECK_ONLY" -eq 0 ]; then
  for pair in GENMAX_VOICE_ID=pNInz6obpgDQGcFmaJgB GENMAX_MODEL=eleven_v3 GENMAX_EMOTION_TAGS=1; do
    default_name=${pair%%=*}; default_value=${pair#*=}
    if [ -z "$(read_dotenv_value "$env_file" "$default_name")" ]; then
      set_dotenv_value "$env_file" "$default_name" "$default_value"
    fi
  done
fi
# Bieu tuong Desktop: bam dup de mo file khoa bang TextEdit.
desktop_cmd="$HOME/Desktop/Mo file khoa API.command"
if [ ! -f "$desktop_cmd" ] && [ -d "$HOME/Desktop" ]; then
  printf '#!/bin/bash\nopen -e "%s"\n' "$env_file" > "$desktop_cmd"
  chmod +x "$desktop_cmd"
fi
if [ "$OPEN_EDITOR" -eq 1 ]; then open -e "$env_file"; fi
if [ "$PREPARE" -eq 1 ]; then
  set_status KEYS-PREPARE OK 'env file and desktop shortcut created'
  log_info "Da tao file khoa: $env_file"
  log_info 'Hoc vien dien khoa, bam Cmd+S, dong TextEdit, roi bao Claude "da luu".'
  exit 0
fi
check_one() {
  key_name="$1"; key_value="$2"; key_url="$3"; key_header="$4"
  if [ -z "$key_value" ]; then
    printf '%s | CHUA_DIEN | %s\n' "$key_name" "$(mask_key "$key_value")"
    return 1
  fi
  case "$key_value" in *' '*|*"$(printf '\n')"*)
    printf '%s | LOI:format | %s\n' "$key_name" "$(mask_key "$key_value")"; return 1 ;;
  esac
  key_code=$(http_status "$key_url" "$key_header")
  key_result=$(classify_http "$key_code")
  printf '%s | %s | %s\n' "$key_name" "$key_result" "$(mask_key "$key_value")"
  [ "$key_result" = OK ]
}
apify=$(read_dotenv_value "$env_file" APIFY_TOKEN)
genmax=$(read_dotenv_value "$env_file" GENMAX_API_KEY)
voice=$(read_dotenv_value "$env_file" GENMAX_VOICE_ID)
gemini=$(read_dotenv_value "$env_file" GEMINI_API_KEY)
telegram=$(read_dotenv_value "$env_file" TELEGRAM_BOT_TOKEN)
chat_id=$(read_dotenv_value "$env_file" TELEGRAM_CHAT_ID)
failed=0
check_one APIFY_TOKEN "$apify" 'https://api.apify.com/v2/users/me' \
  "Authorization: Bearer $apify" || failed=1
check_one GENMAX_API_KEY "$genmax" 'https://api.genmax.io/v1/auth/me' \
  "xi-api-key: $genmax" || failed=1
check_one GEMINI_API_KEY "$gemini" \
  'https://generativelanguage.googleapis.com/v1beta/models?pageSize=1' \
  "x-goog-api-key: $gemini" || failed=1
if [ "$SKIP_TELEGRAM" -eq 1 ]; then
  printf 'TELEGRAM_BOT_TOKEN | BO_QUA | %s\n' "$(mask_key "$telegram")"
elif [ -n "$telegram" ]; then
  check_one TELEGRAM_BOT_TOKEN "$telegram" \
    "https://api.telegram.org/bot${telegram}/getMe" '' || failed=1
else
  printf 'TELEGRAM_BOT_TOKEN | BO_QUA | (trong)\n'
fi
if [ -n "$voice" ]; then voice_state=OK; else voice_state=BO_QUA; fi
printf 'GENMAX_VOICE_ID | %s | %s\n' "$voice_state" "$(mask_key "$voice")"
if [ -n "$chat_id" ]; then chat_state=OK; else chat_state=BO_QUA; fi
printf 'TELEGRAM_CHAT_ID | %s | %s\n' "$chat_state" "$(mask_key "$chat_id")"
if [ "$FETCH_CHAT" -eq 1 ] && [ "$SKIP_TELEGRAM" -eq 0 ] && [ -n "$telegram" ]; then
  if [ -z "$chat_id" ]; then
    updates=$(curl -s --max-time 20 "https://api.telegram.org/bot${telegram}/getUpdates" 2>/dev/null)
    chat_id=$(printf '%s' "$updates" | extract_telegram_chat_id)
    if [ -n "$chat_id" ]; then
      set_dotenv_value "$env_file" TELEGRAM_CHAT_ID "$chat_id"
      log_info 'Da tu lay chat id va ghi vao .env.'
    else
      log_info 'Chua thay tin nhan: hay bam Start, nhan bot 1 cau roi chay lai.'
    fi
  fi
  if [ -n "$chat_id" ]; then
    tg_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 --get \
      "https://api.telegram.org/bot${telegram}/sendMessage" \
      --data-urlencode "chat_id=${chat_id}" \
      --data-urlencode 'text=AISONNET: ket noi Telegram thanh cong! Ban co the bo qua tin nay.')
    printf 'TELEGRAM_TEST | %s\n' "$(classify_telegram_send "$tg_code")"
  fi
fi
if [ "$CHECK_ONLY" -eq 0 ]; then
  profile=$(mktemp "${TMPDIR:-/tmp}/aisonnet.keys.XXXXXX") || exit 1
  printf '# AISONNET:BEGIN\nexport PYTHONUTF8=1\nexport PYTHONIOENCODING=utf-8\n' > "$profile"
  for key_name in APIFY_TOKEN GENMAX_API_KEY GENMAX_VOICE_ID GENMAX_MODEL GENMAX_EMOTION_TAGS GEMINI_API_KEY; do
    key_value=$(read_dotenv_value "$env_file" "$key_name")
    [ -n "$key_value" ] || continue
    safe_value=$(printf '%s' "$key_value" | sed "s/'/'\\\\''/g")
    printf "export %s='%s'\n" "$key_name" "$safe_value" >> "$profile"
    # Ung dung mo tu Finder/Dock (vd Claude Desktop) khong doc .zprofile: dat them cho phien dang nhap.
    if has_cmd launchctl; then launchctl setenv "$key_name" "$key_value" 2>/dev/null || true; fi
  done
  for key_name in TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID; do
    key_value=$(read_dotenv_value "$env_file" "$key_name")
    [ -n "$key_value" ] || continue
    safe_value=$(printf '%s' "$key_value" | sed "s/'/'\\\\''/g")
    printf "export %s='%s'\n" "$key_name" "$safe_value" >> "$profile"
  done
  printf '# AISONNET:END\n' >> "$profile"
  update_marker_block "$HOME/.zprofile" '# AISONNET:BEGIN' '# AISONNET:END' "$profile"
  rm -f "$profile"
  global_block="$ROOT/templates/global-claude-block-mac.md"
  if [ -f "$global_block" ]; then
    update_marker_block "$HOME/.claude/CLAUDE.md" '<!-- AISONNET:BEGIN' \
      '<!-- AISONNET:END -->' "$global_block"
  fi
  log_info 'Hay DONG HAN Claude va Terminal, sau do mo lai de nhan bien moi truong.'
fi
if [ "$failed" -eq 0 ]; then set_status KEYS OK 'key check complete'; exit 0; fi
set_status KEYS E_KEY_INVALID 'one or more required keys failed'
exit 1
