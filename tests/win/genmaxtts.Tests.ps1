# genmaxtts.Tests.ps1 - chay bo test Python cua genmax_tts.py (may chu GIA: khong goi Genmax that, khong ton credit).
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$pyTest = Join-Path $repoRoot 'tests\py\test_genmax_tts.py'

Test-Case 'genmax_tts.py: toan bo test Python (may chu gia) dat' {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = (& py -3.12 -X utf8 $pyTest 2>&1 | ForEach-Object { $_.ToString() } | Out-String)
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previous
    Assert-Equal 0 $exitCode ('test Python that bai: ' + $output)
    Assert-True ($output -match 'Ran \d+ tests') 'khong thay dong "Ran N tests"'
    Assert-True ($output -match '(?m)^OK\s*$') ('khong thay OK: ' + $output)
}

Test-Case 'genmax_tts.py: --dry-run khong can khoa, chi in cau hinh mac dinh Adam/v3' {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $tool = Join-Path $repoRoot 'kit\tools\genmax_tts.py'
    $out = (& py -3.12 -X utf8 $tool --text 'Chao' --dry-run 2>&1 | Out-String)
    $ErrorActionPreference = $previous
    Assert-Contains $out 'model=eleven_v3'
    Assert-Contains $out 'tags=True'
}
