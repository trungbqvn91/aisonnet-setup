# AISONNET macOS scripts (DRAFT)

These scripts are DRAFT - CHUA KIEM CHUNG tren macOS that.

Run from the kit folder after copying it to `~/AISONNET`:

```bash
bash scripts/mac/00-preflight.sh
bash scripts/mac/10-install-core.sh
bash scripts/mac/20-python-libs.sh
bash scripts/mac/30-whisper.sh --model base
bash scripts/mac/40-browser-tools.sh
bash scripts/mac/50-keys-sync.sh --check-only
bash scripts/mac/60-smoke.sh
bash scripts/mac/90-export-report.sh
```

Every script accepts `--dry-run` and `--root DIR`.
Homebrew is never installed automatically. If it is missing, run the official
command shown by `10-install-core.sh` in a real Terminal and enter your own
password. Keys stay in `~/AISONNET/.env`; scripts never print their values.

Known limits: this is tested only for Bash logic on Linux. Apple Silicon,
Intel, Homebrew, Python wheels, Playwright, API checks, and macOS profiles
still need real-mac verification.
