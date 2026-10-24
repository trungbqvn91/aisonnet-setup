# 60-smoke.ps1 - Phase 7: kiem tra cuoi, chay duoc tu THU MUC BAT KY.
# Nen chay trong terminal MOI mo (de kiem dung thu hoc vien se dung that).
#   -Quick : kiem nhanh (bo qua Whisper + Playwright) - lenh khoahoc-doctor dung che do nay.
# Ket luan cuoi dung 1 dong: KET LUAN: READY | READY_WITH_DEFERRED (...) | NOT_READY (...)
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [switch]$Quick,
    [string]$ClaudeHome = '',
    [string]$DesktopDir = '',
    [string]$PythonExe = ''
)
. (Join-Path $PSScriptRoot 'common.ps1')

if (-not $ClaudeHome) { $ClaudeHome = Join-Path $HOME '.claude' }
if (-not $DesktopDir) { $DesktopDir = [Environment]::GetFolderPath('Desktop') }
$python = Get-PythonInvocation $PythonExe
$rows = New-Object System.Collections.ArrayList

function Add-Row {
    # Result: OK | LOI | DEFERRED | BO_QUA
    param([string]$Item, [string]$Result, [string]$Note = '')
    [void]$rows.Add(@{ Item = $Item; Result = $Result; Note = $Note })
}

function Add-ToolRow {
    param([string]$Item, [string]$Tool, [bool]$Optional = $false)
    if ($DryRun) { Add-Row $Item 'BO_QUA' 'DryRun'; return }
    $version = Get-ToolVersion $Tool
    if ($version -and $version.Length -gt 60) { $version = $version.Substring(0, 60) }
    if ($version) { Add-Row $Item 'OK' $version }
    elseif ($Optional) { Add-Row $Item 'DEFERRED' 'khong co lenh nay (khong bat buoc)' }
    else { Add-Row $Item 'LOI' 'khong chay duoc - mo terminal MOI hoac chay lai 10-install-core.ps1' }
}

function Invoke-ChildScript {
    # Chay script anh em trong tien trinh rieng, tra { ExitCode; Output }.
    param([string]$Name, [string[]]$Extra)
    $path = Join-Path $PSScriptRoot $Name
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $path, '-Root', $Root) + @($Extra)
    return Invoke-Native 'powershell' $arguments
}

Write-Ascii '== KIEM TRA CUOI (SMOKE) =='
if ((Get-Location).Path.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
    Write-Ascii 'Canh bao: dang dung trong thu muc cai dat. Hay chay tu thu muc khac (vd Desktop) de kiem dung nhu luc dung that.'
}

# 1) Cong cu
Add-ToolRow 'git' 'git'
Add-ToolRow 'python-3.12' 'py'
Add-ToolRow 'ffmpeg' 'ffmpeg'
Add-ToolRow 'claude-cli' 'claude' $true

# 2) Thu vien Python import duoc o thu muc nay
if ($DryRun) { Add-Row 'python-import' 'BO_QUA' 'DryRun' }
else {
    # LUU Y: PowerShell 5.1 lam mat dau nhay KEP khi truyen -c cho chuong trinh ngoai -> chi dung nhay don/khong nhay.
    $importCode = 'import faster_whisper, playwright, apify_client, google.genai, dotenv, requests, av; print(av.__version__)'
    $import = Invoke-Python $python @('-c', $importCode)
    if ($import.ExitCode -eq 0) { Add-Row 'python-import' 'OK' '7 thu vien' }
    else { Add-Row 'python-import' 'LOI' (Get-LastLines $import.Output 2) }
}

# 3) FFmpeg cat thu 1 giay tu file mau
$sample = Join-Path $script:KitRoot 'assets\sample-vi.wav'
if ($DryRun) { Add-Row 'ffmpeg-cat-thu' 'BO_QUA' 'DryRun' }
elseif (-not (Test-Path -LiteralPath $sample)) { Add-Row 'ffmpeg-cat-thu' 'LOI' 'thieu file mau sample-vi.wav' }
else {
    $cut = Join-Path $env:TEMP ('aisonnet-cut-' + [guid]::NewGuid().ToString('N') + '.wav')
    $r = Invoke-Native 'ffmpeg' @('-y', '-loglevel', 'error', '-i', $sample, '-t', '1', $cut)
    if ($r.ExitCode -eq 0 -and (Test-Path -LiteralPath $cut) -and (Get-Item -LiteralPath $cut).Length -gt 0) {
        Add-Row 'ffmpeg-cat-thu' 'OK' 'cat 1 giay, file ra > 0 byte'
    } else { Add-Row 'ffmpeg-cat-thu' 'LOI' (Get-LastLines $r.Output 2) }
    Remove-Item -LiteralPath $cut -Force -ErrorAction SilentlyContinue
}

# 4) Whisper + 5) Playwright (bo qua khi -Quick)
if ($Quick -or $DryRun) {
    Add-Row 'whisper' 'BO_QUA' 'Quick/DryRun'
    Add-Row 'playwright' 'BO_QUA' 'Quick/DryRun'
} else {
    $extra = @()
    if ($PythonExe) { $extra = @('-PythonExe', $PythonExe) }
    $w = Invoke-ChildScript '30-whisper.ps1' $extra
    if ($w.ExitCode -eq 0) { Add-Row 'whisper' 'OK' (Get-LastLines $w.Output 3) }
    else { Add-Row 'whisper' 'LOI' (Get-LastLines $w.Output 2) }
    $p = Invoke-ChildScript '40-browser-tools.ps1' (@('-VerifyOnly') + $extra)
    if ($p.ExitCode -eq 0) { Add-Row 'playwright' 'OK' 'mo duoc trinh duyet an' }
    else { Add-Row 'playwright' 'LOI' (Get-LastLines $p.Output 2) }
}

# 6) Bien moi truong: User co VA tien trinh hien tai cung thay (dung thu hoc vien se dung)
$keyNames = @('APIFY_TOKEN', 'GENMAX_API_KEY', 'GENMAX_VOICE_ID', 'GENMAX_MODEL', 'GENMAX_EMOTION_TAGS',
              'GEMINI_API_KEY', 'TELEGRAM_BOT_TOKEN', 'TELEGRAM_CHAT_ID')
$healthNames = @('APIFY_TOKEN', 'GENMAX_API_KEY', 'GEMINI_API_KEY', 'TELEGRAM_BOT_TOKEN')
$required = @('APIFY_TOKEN', 'GENMAX_API_KEY', 'GEMINI_API_KEY')
$procValues = @{}
foreach ($name in ($keyNames + @('PYTHONUTF8'))) {
    $userValue = Get-UserEnv $name
    $procValue = [Environment]::GetEnvironmentVariable($name, 'Process')
    if ($procValue) { $procValues[$name] = $procValue }
    $masked = Mask-Key $procValue
    if ($DryRun) { Add-Row "env:$name" 'BO_QUA' 'DryRun' }
    elseif ($userValue -and $procValue) { Add-Row "env:$name" 'OK' $masked }
    elseif ($userValue -and -not $procValue) { Add-Row "env:$name" 'LOI' 'CAN_MO_TERMINAL_MOI (da dat nhung terminal nay chua thay)' }
    elseif ($required -contains $name -or $name -eq 'PYTHONUTF8') { Add-Row "env:$name" 'LOI' 'CHUA_DAT - chay 50-keys-sync.ps1' }
    else { Add-Row "env:$name" 'BO_QUA' 'tuy chon, chua dat' }
}

# 7) Goi thu API bang gia tri tien trinh (thu hoc vien se dung that)
foreach ($name in $healthNames) {
    if ($DryRun) { continue }
    if (-not $procValues.ContainsKey($name)) { continue }
    $health = Invoke-ApiHealth $name $procValues[$name]
    if ($health.Code -eq 'OK') { Add-Row "api:$name" 'OK' $health.Note }
    else { Add-Row "api:$name" 'LOI' ($health.Code + ' ' + $health.Note) }
}

# 8) Khoi toan cuc, lenh doctor, bieu tuong Desktop
$claudeMd = Join-Path $ClaudeHome 'CLAUDE.md'
if ($DryRun) { Add-Row 'khoi-claude-toan-cuc' 'BO_QUA' 'DryRun' }
elseif ((Test-Path -LiteralPath $claudeMd) -and ([IO.File]::ReadAllText($claudeMd)).Contains('<!-- AISONNET:BEGIN')) {
    Add-Row 'khoi-claude-toan-cuc' 'OK' ''
} else { Add-Row 'khoi-claude-toan-cuc' 'LOI' 'chua co khoi AISONNET trong CLAUDE.md toan cuc' }

$toolsDir = (Join-Path $Root 'tools').TrimEnd('\')
$procHasTools = (@($env:Path.Split(';') | Where-Object { $_.TrimEnd('\') -ieq $toolsDir })).Count -gt 0
$userHasTools = ((Add-PathSegment (Get-UserEnv 'Path') $toolsDir) -eq (Get-UserEnv 'Path'))
if ($DryRun) { Add-Row 'lenh-khoahoc-doctor' 'BO_QUA' 'DryRun' }
elseif ($procHasTools) { Add-Row 'lenh-khoahoc-doctor' 'OK' '' }
elseif ($userHasTools) { Add-Row 'lenh-khoahoc-doctor' 'LOI' 'CAN_MO_TERMINAL_MOI' }
else { Add-Row 'lenh-khoahoc-doctor' 'LOI' 'tools chua co trong PATH - chay 50-keys-sync.ps1' }

$shortcut = Join-Path $DesktopDir 'Mo file khoa API.lnk'
if ($DryRun) { Add-Row 'bieu-tuong-desktop' 'BO_QUA' 'DryRun' }
elseif (Test-Path -LiteralPath $shortcut) { Add-Row 'bieu-tuong-desktop' 'OK' '' }
else { Add-Row 'bieu-tuong-desktop' 'DEFERRED' 'khong thay bieu tuong (khong anh huong chay)' }

# --- Bang ket qua + ket luan
Write-Ascii 'MUC | KET QUA | GHI CHU'
foreach ($row in $rows) { Write-Ascii ("{0} | {1} | {2}" -f $row.Item, $row.Result, $row.Note) }
$bad = @($rows | Where-Object { $_.Result -eq 'LOI' })
$deferred = @($rows | Where-Object { $_.Result -eq 'DEFERRED' })
if ($bad.Count -gt 0) { $final = 'NOT_READY (' + (($bad | ForEach-Object { $_.Item }) -join ', ') + ')' }
elseif ($deferred.Count -gt 0) { $final = 'READY_WITH_DEFERRED (' + (($deferred | ForEach-Object { $_.Item }) -join ', ') + ')' }
else { $final = 'READY' }
Write-Ascii ("KET LUAN: {0}" -f $final)

if (-not $DryRun) {
    $code = 'OK'
    if ($bad.Count -gt 0) { $code = 'E_SMOKE' }
    Set-SetupStatus $Root 'smoke' $code $final
    Write-SetupLog $Root ("SMOKE: {0}" -f $final)
}
if ($bad.Count -gt 0) { exit 1 }
exit 0
