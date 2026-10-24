#!/usr/bin/env bash
# DRAFT - CHUA KIEM CHUNG tren macOS that
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$HOME/AISONNET"
DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in --dry-run) DRY_RUN=1 ;; --root) ROOT="$2"; shift ;;
    *) printf 'E_CORE_INSTALL: tham so khong hop le\n'; exit 1 ;; esac
  shift
done
. "$SCRIPT_DIR/common.sh"
if [ "$DRY_RUN" -eq 1 ]; then
  log_info "DRY-RUN: install core at $ROOT"
  exit 0
fi
if ! has_cmd brew; then
  log_info 'E_BREW: Homebrew chua co. Mo Terminal that va chay lenh chinh thuc:'
  log_info '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/'
  log_info 'install/HEAD/install.sh)"'
  log_info 'Tu nhap mat khau neu macOS hoi, sau do chay lai script nay.'
  set_status CORE E_BREW 'Homebrew missing'
  exit 1
fi
for package in git python@3.12 ffmpeg; do
  if brew list --versions "$package" >/dev/null 2>&1; then
    log_info "$package: da co"
  elif ! run_or_dry brew install "$package"; then
    set_status CORE E_CORE_INSTALL "brew install $package failed"
    exit 1
  fi
done
brew_bin="$(brew_prefix)/bin/brew"
log_info "Neu lenh chua thay, chay: eval \"\$($brew_bin shellenv)\""
for tool in git python3.12 ffmpeg; do
  if has_cmd "$tool"; then "$tool" --version 2>/dev/null | head -n 1; else
    log_info "E_CORE_${tool}: chua thay sau cai dat"
    set_status CORE "E_CORE_${tool}" 'tool missing'
    exit 1
  fi
done
set_status CORE OK 'core tools complete'
