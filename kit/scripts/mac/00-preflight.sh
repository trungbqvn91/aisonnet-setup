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
    *) printf 'E_CORE_PREFLIGHT: tham so khong hop le\n'; exit 1 ;;
  esac
  shift
done
. "$SCRIPT_DIR/common.sh"
if [ "$DRY_RUN" -eq 1 ]; then log_info "DRY-RUN: preflight at $ROOT"; exit 0; fi
mkdir -p "$ROOT/state"
mac_ver=$(sw_vers -productVersion 2>/dev/null || printf 'unknown')
arch=$(uname -m 2>/dev/null || printf 'unknown')
ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || printf '0')
ram_gb=$((ram_bytes / 1073741824))
free_kb=$(df -k "$ROOT" 2>/dev/null | awk 'NR == 2 { print $4 }')
free_gb=$(( ${free_kb:-0} / 1048576 ))
if groups 2>/dev/null | grep -q 'admin'; then admin=true; else admin=false; fi
if xcode-select -p >/dev/null 2>&1; then clt=true; else clt=false; fi
if has_cmd brew; then brew_ok=true; else brew_ok=false; fi
if curl -fsI --max-time 8 https://github.com >/dev/null 2>&1; then
  net_github=true
else
  net_github=false
fi
if curl -fsI --max-time 8 https://genmax.io >/dev/null 2>&1; then
  net_genmax=true
else
  net_genmax=false
fi
printf '{"macos":"%s","arch":"%s","ram_gb":%s,"free_gb":%s,' \
  "$mac_ver" "$arch" "$ram_gb" "$free_gb" > "$ROOT/state/preflight.json"
printf '"admin":%s,"xcode_clt":%s,"brew":%s,' "$admin" "$clt" "$brew_ok" \
  >> "$ROOT/state/preflight.json"
printf '"net":{"github":%s,"genmax":%s}}\n' "$net_github" "$net_genmax" \
  >> "$ROOT/state/preflight.json"
log_info "macOS: $mac_ver | CPU: $arch | RAM: ${ram_gb}GB | Disk: ${free_gb}GB"
log_info "Admin: $admin | Xcode CLT: $clt | Homebrew: $brew_ok"
if [ "$arch" = "x86_64" ]; then log_info 'CANH BAO: Intel la ngoai pham vi draft'; fi
case "$mac_ver" in 10.*|11.*|12.*) log_info 'CANH BAO: macOS cu la ngoai pham vi draft' ;; esac
set_status PREFLIGHT OK 'preflight complete'
