# build-release.ps1 - dong goi kit\ thanh dist\aisonnet-setup.zip (cong cu cua nguoi phat hanh, KHONG nam trong ZIP).
# Quy trinh: chay lint + test -> kiem file bat buoc / khong lot file nhay cam -> nen (ten entry dung dau /).
# Ten file CO DINH aisonnet-setup.zip de link GitHub .../releases/latest/download/aisonnet-setup.zip khong doi.
param([switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$kit = Join-Path $repo 'kit'
$dist = Join-Path $repo 'dist'
$zipPath = Join-Path $dist 'aisonnet-setup.zip'

if (-not $SkipTests) {
    foreach ($check in @('tests\win\lint.ps1', 'tests\win\run-tests.ps1')) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo $check)
        if ($LASTEXITCODE -ne 0) { throw "Kiem tra that bai: $check - khong dong goi." }
    }
}

$required = @('CLAUDE.md', 'SETUP.md', 'INTERVIEW.md', 'RECOVERY.md', 'VERSION',
              'assets\sample-vi.wav', 'assets\sample-vi.expect.txt', 'assets\links.json',
              'templates\env.template', 'templates\global-claude-block.md', 'tools\khoahoc-doctor.cmd',
              'tools\genmax_tts.py', 'tools\genmax-tts.cmd',
              'scripts\win\common.ps1', 'scripts\win\00-preflight.ps1', 'scripts\win\10-install-core.ps1',
              'scripts\win\20-python-libs.ps1', 'scripts\win\30-whisper.ps1', 'scripts\win\40-browser-tools.ps1',
              'scripts\win\50-keys-sync.ps1', 'scripts\win\55-genmax-voices.ps1', 'scripts\win\60-smoke.ps1',
              'scripts\win\90-export-report.ps1', 'scripts\win\record-answer.ps1')
foreach ($rel in $required) {
    $p = Join-Path $kit $rel
    if (-not (Test-Path -LiteralPath $p) -or (Get-Item -LiteralPath $p).Length -eq 0) { throw "Thieu/rong: $rel" }
}

# Don rac do Python sinh ra (khong bao gio duoc dong goi).
Get-ChildItem -LiteralPath $kit -Recurse -Directory -Filter '__pycache__' |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Khong duoc lot file nhay cam vao ZIP.
$forbidden = @(Get-ChildItem -LiteralPath $kit -Recurse -File | Where-Object {
    $_.Name -in @('.env', 'bao-cao-ho-tro.txt', 'SETUP-LOG.md', 'status.json') -or
    $_.Extension -in @('.zip', '.log', '.pyc')
})
if ($forbidden.Count -gt 0) { throw ('File khong duoc dong goi: ' + ($forbidden.FullName -join ', ')) }

# Script bash phai la LF (CRLF lam hong tren Mac/Linux).
foreach ($sh in (Get-ChildItem -LiteralPath $kit -Recurse -Filter '*.sh')) {
    if ([IO.File]::ReadAllText($sh.FullName).Contains("`r")) { throw "File .sh co CRLF: $($sh.FullName)" }
}

New-Item -ItemType Directory -Path $dist -Force | Out-Null
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    $kitFull = (Resolve-Path -LiteralPath $kit).Path.TrimEnd('\')
    # Ban phat hanh v0.1 CHI Windows: script Mac la ban nhap chua kiem chung nen khong dua vao ZIP.
    foreach ($file in (Get-ChildItem -LiteralPath $kit -Recurse -File | Where-Object { $_.FullName -notmatch '\\scripts\\mac\\' })) {
        $entryName = $file.FullName.Substring($kitFull.Length + 1).Replace('\', '/')
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName,
            [IO.Compression.CompressionLevel]::Optimal)
    }
} finally {
    $zip.Dispose()
}

$version = ([IO.File]::ReadAllText((Join-Path $kit 'VERSION'))).Trim()
$info = Get-Item -LiteralPath $zipPath
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
Write-Host ("Da dong goi: {0}" -f $zipPath)
Write-Host ("Phien ban {0} | {1:N0} KB | SHA-256 {2}" -f $version, ($info.Length / 1KB), $hash)
