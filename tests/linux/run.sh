#!/usr/bin/env bash
set -u
failed=0
if ! shellcheck -S warning kit/scripts/mac/*.sh; then failed=1; fi
if ! bash tests/linux/logic.test.sh; then failed=1; fi
if [ "$failed" -eq 0 ]; then printf 'PASS: linux checks\n'; else printf 'FAIL: linux checks\n'; fi
exit "$failed"
