# 90-export-report.ps1 - xuat bao cao ho tro (DA LOC KHOA) de hoc vien gui cho giang vien.
# Loc bang: moi gia tri khoa trong .env + bien moi truong + cac mau chuoi giong khoa + ten nguoi dung.
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET'
)
. (Join-Path $PSScriptRoot 'common.ps1')

if ($DryRun) {
    Write-Ascii '[DryRun] Se tao bao cao da loc khoa: bao-cao-ho-tro.txt'
    exit 0
}

# Gom moi gia tri bi mat da biet de thay bang ***.
$secrets = New-Object System.Collections.ArrayList
$dotenv = Read-DotEnv (Join-Path $Root '.env')
foreach ($v in $dotenv.Values) { if ($v) { [void]$secrets.Add([string]$v) } }
foreach ($name in @('APIFY_TOKEN', 'GENMAX_API_KEY', 'GENMAX_VOICE_ID', 'GEMINI_API_KEY', 'TIKTOK_API23_KEY', 'TELEGRAM_BOT_TOKEN', 'TELEGRAM_CHAT_ID')) {
    foreach ($scope in @('User', 'Process')) {
        $v = [Environment]::GetEnvironmentVariable($name, $scope)
        if ($v) { [void]$secrets.Add($v) }
    }
}

$sections = New-Object System.Collections.ArrayList
[void]$sections.Add('AISONNET - bao cao ho tro (khong chua khoa API)')
[void]$sections.Add('Bo cai phien ban: ' + (Get-KitVersion))
foreach ($tool in @('git', 'py', 'ffmpeg', 'claude', 'node')) {
    $version = Get-ToolVersion $tool
    [void]$sections.Add(("{0}: {1}" -f $tool, $(if ($version) { $version } else { 'khong thay' })))
}
# Phong van: CHI xuat cac truong ky thuat (khong xuat cau tra loi tu do co the chua ten/email).
$interview = Get-JsonFile (Join-Path $Root 'state\interview.json')
if ($null -ne $interview) {
    [void]$sections.Add("")
    [void]$sections.Add('[phong van - chi truong ky thuat]')
    foreach ($field in @('claude_plan', 'machine_owner', 'telegram_needed', 'confidence_level', 'uac_available', 'vscode_now', 'extension_now')) {
        $answer = Get-JsonProp $interview $field
        if ($null -ne $answer) { [void]$sections.Add(("{0}: {1}" -f $field, $answer)) }
    }
}
foreach ($file in @('state\preflight.json', 'state\status.json')) {
    $path = Join-Path $Root $file
    if (Test-Path -LiteralPath $path) {
        [void]$sections.Add("")
        [void]$sections.Add("[$file]")
        [void]$sections.Add([IO.File]::ReadAllText($path))
    }
}
$logPath = Join-Path $Root 'SETUP-LOG.md'
if (Test-Path -LiteralPath $logPath) {
    [void]$sections.Add("")
    [void]$sections.Add('[SETUP-LOG.md - 80 dong cuoi]')
    [void]$sections.Add((([IO.File]::ReadAllLines($logPath) | Select-Object -Last 80) -join "`r`n"))
}

$text = ($sections -join "`r`n")
$text = [regex]::Replace($text, '(?i)(\\Users\\)' + [regex]::Escape($env:USERNAME), '$1%USERNAME%')
$text = Redact-Secrets $text @($secrets)
$out = Join-Path $Root 'bao-cao-ho-tro.txt'
[IO.File]::WriteAllText($out, $text, (New-Object System.Text.UTF8Encoding($false)))
Write-Ascii ('Da tao bao cao (da loc khoa): ' + $out)
Write-Ascii 'Hoc vien gui NOI DUNG file nay cho giang vien. KHONG gui file .env.'
exit 0
