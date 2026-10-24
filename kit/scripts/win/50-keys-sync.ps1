# 50-keys-sync.ps1 - Phase 5 (KHOA) + Phase 6 (GLOBAL).
#
# Cach dung (Claude chay theo thu tu):
#   1) -Prepare -OpenEditor : tao .env tu mau + bieu tuong Desktop, mo Notepad cho hoc vien dien khoa.
#   2) (khong tham so)      : doc .env, kiem tra tung khoa bang API that, dat bien moi truong muc
#                             User cho khoa PASS, them tools vao PATH, ghi khoi vao ~\.claude\CLAUDE.md.
#   -CheckOnly: chi kiem tra, khong dat bien/khong ghi gi.
# Gia tri khoa GIU NGUYEN trong .env (hoc vien xem lai duoc). KHONG BAO GIO in gia tri khoa.
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [switch]$Prepare,
    [switch]$OpenEditor,
    [switch]$CheckOnly,
    [switch]$SkipTelegram,
    [switch]$FetchTelegramChatId,
    [switch]$TelegramTest,
    [string]$ClaudeHome = '',
    [string]$DesktopDir = ''
)
. (Join-Path $PSScriptRoot 'common.ps1')

# Thu tu hien thi. Required = bat buoc co khoa de coi la xong.
$keys = @(
    @{ Name = 'APIFY_TOKEN';        Required = $true  },
    @{ Name = 'GENMAX_API_KEY';     Required = $true  },
    @{ Name = 'GENMAX_VOICE_ID';    Required = $false },
    @{ Name = 'GENMAX_MODEL';       Required = $false },
    @{ Name = 'GENMAX_EMOTION_TAGS'; Required = $false },
    @{ Name = 'GEMINI_API_KEY';     Required = $true  },
    @{ Name = 'TELEGRAM_BOT_TOKEN'; Required = $false },
    @{ Name = 'TELEGRAM_CHAT_ID';   Required = $false }
)
$envFile = Join-Path $Root '.env'
if (-not $DesktopDir) { $DesktopDir = [Environment]::GetFolderPath('Desktop') }
if (-not $ClaudeHome) { $ClaudeHome = Join-Path $HOME '.claude' }

function New-KeyFileAndShortcut {
    # Tao .env tu template (khong ghi de neu da co) + bieu tuong Desktop mo bang Notepad.
    $template = Join-Path $script:KitRoot 'templates\env.template'
    if (-not (Test-Path -LiteralPath $envFile)) {
        if (-not (Test-Path -LiteralPath $template)) { return 'E_TEMPLATE' }
        if ($DryRun) { Write-Ascii '[DryRun] Se tao .env tu env.template.' }
        else { New-SetupDirs $Root; Copy-Item -LiteralPath $template -Destination $envFile }
    }
    $linkPath = Join-Path $DesktopDir 'Mo file khoa API.lnk'
    if ($DryRun) {
        Write-Ascii ('[DryRun] Se tao bieu tuong: ' + $linkPath)
        return 'OK'
    }
    try {
        if (-not (Test-Path -LiteralPath $DesktopDir)) { New-Item -ItemType Directory -Path $DesktopDir -Force | Out-Null }
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($linkPath)
        $link.TargetPath = 'notepad.exe'
        $link.Arguments = '"' + $envFile + '"'
        $link.Description = 'Mo file khoa API cua khoa hoc AISONNET'
        $link.Save()
    } catch {
        Write-Ascii 'Canh bao: khong tao duoc bieu tuong Desktop (khong anh huong cai dat).'
    }
    return 'OK'
}

function Get-TelegramChatId {
    # Lay chat id tu getUpdates (hoc vien da nhan bot 1 cau). Tra chuoi id hoac ''.
    param([string]$Token)
    Write-Ascii 'Luu y: lay chat id se danh dau cac tin nhan bot da nhan la da doc (khong anh huong gi khac).'
    $reply = Invoke-ApiRequest ('https://api.telegram.org/bot' + $Token + '/getUpdates') @{}
    if ($reply.Status -ne 200) { return '' }
    try {
        $data = $reply.Body | ConvertFrom-Json
        $items = @($data.result)
        for ($i = $items.Count - 1; $i -ge 0; $i--) {
            $msg = $items[$i].message
            if ($null -ne $msg -and $null -ne $msg.chat) { return [string]$msg.chat.id }
        }
    } catch { }
    return ''
}

Write-Ascii '== KHOA API + CAI DAT TOAN CUC =='
$prepared = New-KeyFileAndShortcut
if ($prepared -ne 'OK') {
    Write-Ascii 'E_TEMPLATE: thieu templates\env.template trong bo cai.'
    exit 1
}
if ($OpenEditor -and -not $DryRun) { Start-Process notepad.exe -ArgumentList ('"' + $envFile + '"') }

if ($Prepare) {
    if (-not $DryRun) {
        Set-SetupStatus $Root 'keys-prepare' 'OK' 'Da tao .env va bieu tuong Desktop.'
        Write-SetupLog $Root 'KEYS-PREPARE: OK'
    }
    Write-Ascii ("Da tao file khoa: " + $envFile)
    Write-Ascii 'Hoc vien dien khoa vao file, bam Ctrl+S, dong Notepad, roi bao Claude "da luu".'
    exit 0
}

# --- Kiem tra tung khoa
$values = Read-DotEnv $envFile
# Giong doc mac dinh (Adam, v3, the cam xuc): dien vao .env neu hoc vien de trong (khong ghi khi -CheckOnly).
foreach ($defaultName in $script:GenmaxDefaults.Keys) {
    $current = ''
    if ($values.Contains($defaultName)) { $current = [string]$values[$defaultName] }
    if (-not $current) {
        $values[$defaultName] = $script:GenmaxDefaults[$defaultName]
        if (-not $DryRun -and -not $CheckOnly) { Set-DotEnvValue $envFile $defaultName $script:GenmaxDefaults[$defaultName] }
    }
}
$results = New-Object System.Collections.ArrayList
foreach ($key in $keys) {
    $name = $key.Name
    $value = ''
    if ($values.Contains($name)) { $value = [string]$values[$name] }
    if ($SkipTelegram -and $name -like 'TELEGRAM_*') { $value = '' }
    if ($name -eq 'TELEGRAM_CHAT_ID' -and -not $value -and $FetchTelegramChatId -and -not $DryRun) {
        $token = ''
        if ($values.Contains('TELEGRAM_BOT_TOKEN')) { $token = [string]$values['TELEGRAM_BOT_TOKEN'] }
        $health = Invoke-ApiHealth 'TELEGRAM_BOT_TOKEN' $token
        if ($health.Code -eq 'OK') {
            $found = Get-TelegramChatId $token
            if ($found) {
                Set-DotEnvValue $envFile 'TELEGRAM_CHAT_ID' $found
                $values['TELEGRAM_CHAT_ID'] = $found
                $value = $found
                Write-Ascii 'Da tu lay chat id va ghi vao .env.'
            } else {
                Write-Ascii 'Chua thay tin nhan nao: hay nhan bot 1 cau roi chay lai.'
            }
        }
    }
    $health = Invoke-ApiHealth $name $value $key.Required -DryRun:$DryRun
    [void]$results.Add(@{ Name = $name; Required = $key.Required; Value = $value; Code = $health.Code; Note = $health.Note })
}

# Gui tin thu Telegram (sau khi lay chat id, hoac khi chay rieng voi -TelegramTest).
if (($FetchTelegramChatId -or $TelegramTest) -and -not $DryRun -and -not $SkipTelegram) {
    $tgToken = ''
    $tgChat = ''
    if ($values.Contains('TELEGRAM_BOT_TOKEN')) { $tgToken = [string]$values['TELEGRAM_BOT_TOKEN'] }
    if ($values.Contains('TELEGRAM_CHAT_ID')) { $tgChat = [string]$values['TELEGRAM_CHAT_ID'] }
    if ($tgToken -and $tgChat) {
        $sent = Send-TelegramTest $tgToken $tgChat
        Write-Ascii ("TELEGRAM_TEST | {0} | {1}" -f $sent.Code, $sent.Note)
    } elseif ($tgToken) {
        Write-Ascii 'TELEGRAM_TEST | BO_QUA | chua co chat id: hay bam Start, nhan bot 1 cau roi chay lai'
    }
}

$failCode = 'OK'
$extra = @{}
Write-Ascii 'TEN | TRANG THAI | GHI CHU | KHOA'
foreach ($r in $results) {
    $extra[$r.Name] = $r.Code
    Write-Ascii ("{0} | {1} | {2} | {3}" -f $r.Name, $r.Code, $r.Note, (Mask-Key $r.Value))
    $bad = ($r.Code -ne 'OK' -and $r.Code -ne 'BO_QUA')
    if ($r.Required -and $bad -and $failCode -eq 'OK') { $failCode = $r.Code }
}

# --- Dat bien moi truong muc User (chi khoa PASS) + PYTHONUTF8 + PATH + khoi CLAUDE.md toan cuc
if (-not $CheckOnly) {
    foreach ($r in $results) {
        if ($r.Code -eq 'OK' -and $r.Value) { Set-UserEnv $r.Name $r.Value -DryRun:$DryRun }
    }
    Set-UserEnv 'PYTHONUTF8' '1' -DryRun:$DryRun
    Set-UserEnv 'PYTHONIOENCODING' 'utf-8' -DryRun:$DryRun

    $toolsDir = Join-Path $Root 'tools'
    $newPath = Add-PathSegment (Get-UserEnv 'Path') $toolsDir
    Set-UserEnv 'Path' $newPath -DryRun:$DryRun

    $blockFile = Join-Path $script:KitRoot 'templates\global-claude-block.md'
    $claudeMd = Join-Path $ClaudeHome 'CLAUDE.md'
    if ($DryRun) {
        Write-Ascii ('[DryRun] Se ghi khoi AISONNET vao ' + $claudeMd)
    } elseif (Test-Path -LiteralPath $blockFile) {
        $block = [IO.File]::ReadAllText($blockFile)
        Update-MarkerBlock $claudeMd '<!-- AISONNET:BEGIN' '<!-- AISONNET:END -->' $block
        Write-Ascii 'Da ghi khoi ghi chu AISONNET vao CLAUDE.md toan cuc (phan cu giu nguyen).'
    } else {
        Write-Ascii 'Canh bao: thieu templates\global-claude-block.md, bo qua khoi toan cuc.'
    }
    Write-Ascii 'QUAN TRONG: hay DONG HAN Claude va terminal roi mo lai de nhan bien moi truong.'
}

if ($DryRun) {
    Write-Ascii '[DryRun] Chi in ke hoach, khong kiem tra khoa that.'
    exit 0
}
if (-not $DryRun) {
    Set-SetupStatus $Root 'keys-global' $failCode 'Kiem tra khoa, dat bien moi truong, khoi toan cuc.' $extra
    Write-SetupLog $Root ("KEYS: {0}" -f $failCode)
}
if ($failCode -ne 'OK') {
    Write-Ascii ("KEYS: {0} - xem RECOVERY.md" -f $failCode)
    exit 1
}
Write-Ascii 'KEYS: OK'
exit 0
