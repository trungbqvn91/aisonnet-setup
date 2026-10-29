# scripts.Tests.ps1 - chay that tung script o che do an toan (khong mang, khong cai gi, khong dong vao may that):
# DryRun, va sandbox (Root/Desktop/ClaudeHome = thu muc tam, bien moi truong muc Process).
$repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$winDir = Join-Path $repo 'kit\scripts\win'
$sbx = Join-Path $repo 'tests\tmp\scripts'
if (Test-Path -LiteralPath $sbx) { Remove-Item -LiteralPath $sbx -Recurse -Force }
New-Item -ItemType Directory -Path $sbx -Force | Out-Null

$fakeApify = 'apify' + '_api_' + ('x' * 30)
$fakeGenmax = 'sk' + '_' + ('a' * 40)
$fakeGemini = 'AI' + 'za' + ('B' * 35)
$fakeTele = '123456789:' + ('A' * 35)
$allFakes = @($fakeApify, $fakeGenmax, $fakeGemini, $fakeTele)

function Invoke-Script {
    # Chay script trong tien trinh powershell rieng. Tra { ExitCode; Output }.
    param([string]$Name, [string[]]$Arguments)
    $path = Join-Path $winDir $Name
    $all = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $path) + @($Arguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $text = (& powershell @all 2>&1 | Out-String)
    $code = $LASTEXITCODE
    $ErrorActionPreference = $previous
    return @{ ExitCode = $code; Output = $text }
}

# ---------------------------------------------------------------- DryRun cua moi script
$dryRoot = Join-Path $sbx 'dry'
foreach ($scriptBase in @('00-preflight', '10-install-core', '20-python-libs', '30-whisper', '40-browser-tools',
                          '50-keys-sync', '60-smoke', '90-export-report')) {
    Test-Case ("dryrun: $scriptBase thoat 0 va khong tao file") {
        $r = Invoke-Script "$scriptBase.ps1" @('-DryRun', '-Root', $dryRoot)
        Assert-Equal 0 $r.ExitCode ("output: " + $r.Output)
        Assert-True (-not (Test-Path -LiteralPath $dryRoot)) 'DryRun da tao thu muc Root'
    }
}
Test-Case 'dryrun: 55-genmax-voices (tim + ghi ID)' {
    $r = Invoke-Script '55-genmax-voices.ps1' @('-DryRun', '-Root', $dryRoot)
    Assert-Equal 0 $r.ExitCode $r.Output
    $r2 = Invoke-Script '55-genmax-voices.ps1' @('-DryRun', '-Root', $dryRoot, '-Set', 'rv30Fd6w5bnbL0kHzWlr')
    Assert-Equal 0 $r2.ExitCode $r2.Output
}
Test-Case '55-genmax-voices: -Set ghi ID vao .env, tu choi ID loi' {
    $vRoot = Join-Path $sbx 'voices'; New-Item -ItemType Directory -Path $vRoot -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $vRoot '.env'), "GENMAX_API_KEY=giu`nGENMAX_VOICE_ID=`n")
    $ok = Invoke-Script '55-genmax-voices.ps1' @('-Root', $vRoot, '-Set', 'rv30Fd6w5bnbL0kHzWlr')
    Assert-Equal 0 $ok.ExitCode $ok.Output
    $d = Read-DotEnv (Join-Path $vRoot '.env')
    Assert-Equal 'rv30Fd6w5bnbL0kHzWlr' $d['GENMAX_VOICE_ID']; Assert-Equal 'giu' $d['GENMAX_API_KEY']
    $bad = Invoke-Script '55-genmax-voices.ps1' @('-Root', $vRoot, '-Set', 'x; rm -rf')
    Assert-Equal 1 $bad.ExitCode
}
Test-Case '55-genmax-voices: chua co khoa -> CHUA_DIEN, khong goi mang' {
    $vRoot2 = Join-Path $sbx 'voices2'; New-Item -ItemType Directory -Path $vRoot2 -Force | Out-Null
    $r = Invoke-Script '55-genmax-voices.ps1' @('-Root', $vRoot2)
    Assert-Equal 1 $r.ExitCode; Assert-Contains $r.Output 'CHUA_DIEN'
}
Test-Case 'dryrun: record-answer' {
    $r = Invoke-Script 'record-answer.ps1' @('-DryRun', '-Root', $dryRoot, '-Name', 'a', '-Value', 'b')
    Assert-Equal 0 $r.ExitCode
}
Test-Case 'dryrun: 60-smoke ket luan READY (chi BO_QUA)' {
    $r = Invoke-Script '60-smoke.ps1' @('-DryRun', '-Root', $dryRoot)
    Assert-Contains $r.Output 'KET LUAN: READY'
}

# ---------------------------------------------------------------- record-answer
$rec = Join-Path $sbx 'rec'
Test-Case 'record-answer: ghi cau tra loi binh thuong' {
    $r = Invoke-Script 'record-answer.ps1' @('-Root', $rec, '-Name', 'goi_claude', '-Value', 'Pro')
    Assert-Equal 0 $r.ExitCode
    Assert-Equal 'Pro' (Get-JsonFile (Join-Path $rec 'state\interview.json')).goi_claude
}
Test-Case 'record-answer: gop nhieu cau tra loi' {
    $null = Invoke-Script 'record-answer.ps1' @('-Root', $rec, '-Name', 'may', '-Value', 'ca-nhan')
    $json = Get-JsonFile (Join-Path $rec 'state\interview.json')
    Assert-Equal 'Pro' $json.goi_claude; Assert-Equal 'ca-nhan' $json.may
}
Test-Case 'record-answer: TU CHOI khi gia tri giong khoa API' {
    $r = Invoke-Script 'record-answer.ps1' @('-Root', $rec, '-Name', 'x', '-Value', $fakeGenmax)
    Assert-Equal 1 $r.ExitCode
    Assert-NotContains ([IO.File]::ReadAllText((Join-Path $rec 'state\interview.json'))) $fakeGenmax
}

# ---------------------------------------------------------------- 50-keys-sync: -Prepare + khoa trong
$keyRoot = Join-Path $sbx 'keys'; $desk = Join-Path $sbx 'desk'; $claudeHome = Join-Path $sbx 'claude'
$env:AISONNET_ENV_SCOPE = 'Process'
Test-Case 'keys -Prepare: tao .env + bieu tuong Desktop, thoat 0' {
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $keyRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Equal 0 $r.ExitCode $r.Output
    Assert-True (Test-Path -LiteralPath (Join-Path $keyRoot '.env')) 'thieu .env'
    Assert-True (Test-Path -LiteralPath (Join-Path $desk 'Mo file khoa API.lnk')) 'thieu bieu tuong'
}
Test-Case 'keys -Prepare: chay lai KHONG ghi de .env da dien' {
    $envPath = Join-Path $keyRoot '.env'
    Set-DotEnvValue $envPath 'APIFY_TOKEN' 'giu-nguyen-gia-tri-nay'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $keyRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Equal 'giu-nguyen-gia-tri-nay' (Read-DotEnv $envPath)['APIFY_TOKEN']
}
Test-Case 'keys: khoa bat buoc con trong -> CHUA_DIEN, thoat 1, khong goi mang' {
    $blankRoot = Join-Path $sbx 'keys-blank'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $blankRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $blankRoot, '-CheckOnly', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Equal 1 $r.ExitCode
    Assert-Contains $r.Output 'CHUA_DIEN'
}
Test-Case 'keys: khoa sai DINH DANG -> E_KEY_FORMAT (khong goi mang), khoa khong lot ra man hinh' {
    $badRoot = Join-Path $sbx 'keys-bad'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $badRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Set-DotEnvValue (Join-Path $badRoot '.env') 'APIFY_TOKEN' 'abc'
    Set-DotEnvValue (Join-Path $badRoot '.env') 'GENMAX_API_KEY' ('co khoang trang ' + $fakeGenmax)
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $badRoot, '-CheckOnly', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Equal 1 $r.ExitCode
    Assert-Contains $r.Output 'E_KEY_FORMAT'
    Assert-NotContains $r.Output $fakeGenmax
}

Test-Case 'keys: giong Genmax de trong -> tu dien mac dinh Adam/v3/the cam xuc vao .env va dat bien' {
    $defRoot = Join-Path $sbx 'keys-defaults'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $defRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    $envPath = Join-Path $defRoot '.env'
    foreach ($n in @('GENMAX_VOICE_ID', 'GENMAX_MODEL', 'GENMAX_EMOTION_TAGS')) { Set-DotEnvValue $envPath $n '' }
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $defRoot, '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Equal 1 $r.ExitCode 'khoa bat buoc con trong nen phai thoat 1'
    $d = Read-DotEnv $envPath
    Assert-Equal 'pNInz6obpgDQGcFmaJgB' $d['GENMAX_VOICE_ID']
    Assert-Equal 'eleven_v3' $d['GENMAX_MODEL']
    Assert-Equal '1' $d['GENMAX_EMOTION_TAGS']
}
Test-Case 'keys: giong da doi boi hoc vien KHONG bi ghi de' {
    $keepRoot = Join-Path $sbx 'keys-keep'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $keepRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Set-DotEnvValue (Join-Path $keepRoot '.env') 'GENMAX_VOICE_ID' 'GIONG_KHAC_CUA_HOC_VIEN'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $keepRoot, '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Equal 'GIONG_KHAC_CUA_HOC_VIEN' (Read-DotEnv (Join-Path $keepRoot '.env'))['GENMAX_VOICE_ID']
}

Test-Case 'keys: -FetchTelegramChatId voi token gia khong lam hong, khong lo token' {
    $tgRoot = Join-Path $sbx 'keys-tg'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $tgRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Set-DotEnvValue (Join-Path $tgRoot '.env') 'TELEGRAM_BOT_TOKEN' $fakeTele
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $tgRoot, '-CheckOnly', '-FetchTelegramChatId', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-NotContains $r.Output $fakeTele
    Assert-Contains $r.Output 'TELEGRAM_BOT_TOKEN'
}
Test-Case 'keys: -SkipTelegram bo qua han buoc Telegram' {
    $tgRoot2 = Join-Path $sbx 'keys-tg2'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $tgRoot2, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Set-DotEnvValue (Join-Path $tgRoot2 '.env') 'TELEGRAM_BOT_TOKEN' $fakeTele
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $tgRoot2, '-CheckOnly', '-SkipTelegram', '-FetchTelegramChatId', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-NotContains $r.Output 'TELEGRAM_TEST'
    Assert-NotContains $r.Output $fakeTele
}

Test-Case 'keys: cai skill rapidapi-tiktok-api23 vao ~\.claude\skills (idempotent, giu skill khac)' {
    $skRoot = Join-Path $sbx 'keys-skill'; $skHome = Join-Path $sbx 'claude-skill'
    New-Item -ItemType Directory -Path (Join-Path $skHome 'skills\skill-cua-hoc-vien') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $skHome 'skills\skill-cua-hoc-vien\SKILL.md'), 'giu nguyen')
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $skRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $skHome)
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $skRoot, '-DesktopDir', $desk, '-ClaudeHome', $skHome)
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $skRoot, '-DesktopDir', $desk, '-ClaudeHome', $skHome)
    $dest = Join-Path $skHome 'skills\rapidapi-tiktok-api23'
    Assert-True (Test-Path -LiteralPath (Join-Path $dest 'SKILL.md')) 'chua cai SKILL.md'
    Assert-True (Test-Path -LiteralPath (Join-Path $dest 'scripts\tiktok_api.py')) 'chua cai script'
    Assert-True (Test-Path -LiteralPath (Join-Path $dest 'references\images\05-copy-key.png')) 'chua cai anh'
    Assert-Equal 'giu nguyen' ([IO.File]::ReadAllText((Join-Path $skHome 'skills\skill-cua-hoc-vien\SKILL.md')))
    $gm = [IO.File]::ReadAllText((Join-Path $skHome 'skills\genmax-dang-ky-nap-credit\SKILL.md'))
    Assert-Contains $gm 'KMGENMAX'; Assert-Contains $gm 'genmax-tts --open signup'; Assert-Contains $gm 'ref=mzkkz9'
}
Test-Case 'keys: khoa RapidAPI bat buoc, dan nham ca doan code -> E_KEY_FORMAT, khoa khong lo' {
    $rkRoot = Join-Path $sbx 'keys-rapid'; $rk = 'rapid' + ('Q' * 30)
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $rkRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Set-DotEnvValue (Join-Path $rkRoot '.env') 'TIKTOK_API23_KEY' ("x-rapidapi-key:" + $rk)
    $r = Invoke-Script '50-keys-sync.ps1' @('-Root', $rkRoot, '-CheckOnly', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    Assert-Contains $r.Output 'TIKTOK_API23_KEY | E_KEY_FORMAT'
    Assert-NotContains $r.Output $rk
}

# ---------------------------------------------------------------- 90-export-report: khong lot khoa
Test-Case 'export: bao cao KHONG chua khoa va che ten nguoi dung' {
    $exRoot = Join-Path $sbx 'export'
    $null = Invoke-Script '50-keys-sync.ps1' @('-Root', $exRoot, '-Prepare', '-DesktopDir', $desk, '-ClaudeHome', $claudeHome)
    $envPath = Join-Path $exRoot '.env'
    Set-DotEnvValue $envPath 'APIFY_TOKEN' $fakeApify
    Set-DotEnvValue $envPath 'GEMINI_API_KEY' $fakeGemini
    Write-SetupLog $exRoot ('dong nhat ky co khoa ' + $fakeGemini + ' va duong dan C:\Users\' + $env:USERNAME + '\x')
    $r = Invoke-Script '90-export-report.ps1' @('-Root', $exRoot)
    Assert-Equal 0 $r.ExitCode $r.Output
    $report = [IO.File]::ReadAllText((Join-Path $exRoot 'bao-cao-ho-tro.txt'))
    foreach ($fake in $allFakes) { Assert-NotContains $report $fake }
    $null = Invoke-Script 'record-answer.ps1' @('-Root', $exRoot, '-Name', 'ghi_chu_tu_do', '-Value', 'Toi la Nguyen Van A email a@b.com')
    $null = Invoke-Script 'record-answer.ps1' @('-Root', $exRoot, '-Name', 'vscode_now', '-Value', 'yes')
    $null = Invoke-Script '90-export-report.ps1' @('-Root', $exRoot)
    $report2 = [IO.File]::ReadAllText((Join-Path $exRoot 'bao-cao-ho-tro.txt'))
    Assert-NotContains $report2 'a@b.com'
    Assert-Contains $report2 'vscode_now: yes'
    Assert-Contains $report 'AISONNET - bao cao ho tro'
}

# ---------------------------------------------------------------- 30-whisper: thieu file mau
Test-Case 'whisper: thieu sample -> khong crash (kiem bang mau hop le cua bo cai)' {
    Assert-True (Test-Path -LiteralPath (Join-Path $repo 'kit\assets\sample-vi.wav')) 'thieu sample-vi.wav'
    Assert-True (Test-Path -LiteralPath (Join-Path $repo 'kit\assets\sample-vi.expect.txt')) 'thieu sample-vi.expect.txt'
    $keywords = @([IO.File]::ReadAllLines((Join-Path $repo 'kit\assets\sample-vi.expect.txt')) | Where-Object { $_.Trim() })
    Assert-True ($keywords.Count -ge 3) 'it hon 3 tu khoa'
    foreach ($k in $keywords) { Assert-True ($k -cmatch '^[a-z ]+$') ("tu khoa phai la chu thuong khong dau: $k") }
}
Remove-Item Env:\AISONNET_ENV_SCOPE -ErrorAction SilentlyContinue
