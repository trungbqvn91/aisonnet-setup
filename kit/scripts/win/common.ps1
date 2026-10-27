# common.ps1 - ham dung chung cua bo cai AISONNET (Windows PowerShell 5.1)
#
# Quy uoc:
#  - Moi thong diep script in ra la tieng Viet KHONG DAU (ASCII). Claude se dien giai
#    lai co dau cho hoc vien. Ly do: dau tieng Viet de hong khi di qua pipe/console.
#  - KHONG BAO GIO in gia tri khoa API. Chi in TEN va 4 ky tu cuoi (Mask-Key).
#  - Moi ham co the chay lai nhieu lan (idempotent).
Set-StrictMode -Version 2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Thu muc goc cua bo cai (chua VERSION, assets, templates, scripts). scripts\win -> len 2 cap.
$script:KitRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:DefaultRoot = 'C:\AISONNET'

function Get-KitVersion {
    # Doc so phien ban tu file VERSION.
    $file = Join-Path $script:KitRoot 'VERSION'
    if (Test-Path -LiteralPath $file) { return ([IO.File]::ReadAllText($file)).Trim() }
    return '0.0.0'
}

# Thu vien Python cai cho nguoi dung. GHIM av va faster-whisper: pip lay av moi nhat
# (19.x) lam faster-whisper 1.2.1 hong (loi metadata_errors). Bo ghim nay da chay that.
$script:PythonPackages = @(
    'faster-whisper==1.2.1',
    'av==16.1.0',
    'playwright',
    'apify-client',
    'google-genai',
    'python-dotenv',
    'requests'
)

# Cau hinh giong doc MAC DINH cua khoa hoc (khong phai bi mat): Adam (ElevenLabs), model v3,
# tu them the cam xuc. Hoc vien chi doi khi can. Dien vao .env neu de trong.
$script:GenmaxDefaults = [ordered]@{
    GENMAX_VOICE_ID     = 'pNInz6obpgDQGcFmaJgB'
    GENMAX_MODEL        = 'eleven_v3'
    GENMAX_EMOTION_TAGS = '1'
}

# Cac phan mem cai bang winget. Short dung lam ma loi (E_CORE_<Short>).
# Scope: user = uu tien cai cho rieng nguoi dung (khong can quyen admin).
$script:CorePackages = @(
    @{ Id = 'Git.Git';             Short = 'GIT';    Tool = 'git';    Scope = 'user';    MayAskUac = $true  },
    @{ Id = 'Python.Python.3.12';  Short = 'PYTHON'; Tool = 'py';     Scope = 'user';    MayAskUac = $false },
    @{ Id = 'Gyan.FFmpeg';         Short = 'FFMPEG'; Tool = 'ffmpeg'; Scope = 'user';    MayAskUac = $false },
    @{ Id = 'Google.Chrome';       Short = 'CHROME'; Tool = 'chrome'; Scope = 'machine'; MayAskUac = $true  }
)

# ---------------------------------------------------------------- Van ban / in an
function Remove-Diacritics {
    # Bo dau tieng Viet (a-z), doi d-gach thanh d.
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $decomposed = $Text.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $decomposed.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($ch)
        }
    }
    $plain = $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
    $plain = $plain.Replace([string][char]0x0111, 'd').Replace([string][char]0x0110, 'D')
    return $plain
}

function Write-Ascii {
    # In 1 dong, dam bao chi co ky tu ASCII.
    param([AllowNull()][string]$Message)
    $plain = Remove-Diacritics $Message
    $plain = [regex]::Replace($plain, '[^\x00-\x7F]', '?')
    Write-Host $plain
}

function Mask-Key {
    # Chi cho thay 4 ky tu cuoi cua khoa.
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '(trong)' }
    $v = $Value.Trim()
    if ($v.Length -le 4) { return ('...' + $v) }
    return ('...' + $v.Substring($v.Length - 4))
}

function Get-SecretPatterns {
    # Mau chuoi giong khoa API (dung de loc nhat ky/bao cao). Ghep chuoi de khong tu khop.
    return @(
        ('sk' + '_[A-Za-z0-9]{8,}'),
        ('AI' + 'za[0-9A-Za-z_\-]{20,}'),
        ('apify' + '_api_[A-Za-z0-9]+'),
        ('bot[0-9]{6,}:' + '[A-Za-z0-9_\-]{20,}')
    )
}

function Redact-Secrets {
    # Thay moi gia tri bi mat (da biet) va moi chuoi giong khoa bang ***.
    param([AllowNull()][string]$Text, [string[]]$Secrets)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $out = $Text
    foreach ($secret in @($Secrets)) {
        if ($secret -and $secret.Length -ge 4) { $out = $out.Replace($secret, '***') }
    }
    foreach ($pattern in (Get-SecretPatterns)) {
        $out = [regex]::Replace($out, $pattern, '***')
    }
    return $out
}

# ---------------------------------------------------------------- Nhat ky + trang thai
function New-SetupDirs {
    param([string]$Root)
    foreach ($dir in @($Root, (Join-Path $Root 'state'))) {
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }
}

function Write-SetupLog {
    # Them 1 dong vao SETUP-LOG.md (UTF-8 khong BOM).
    param([string]$Root, [string]$Message)
    New-SetupDirs $Root
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), (Redact-Secrets $Message)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::AppendAllText((Join-Path $Root 'SETUP-LOG.md'), $line + "`r`n", $encoding)
}

function Get-JsonFile {
    # Doc file JSON thanh PSCustomObject; loi/khong co file thi tra $null.
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { return ([IO.File]::ReadAllText($Path) | ConvertFrom-Json) } catch { return $null }
}

function Save-JsonFile {
    param([string]$Path, $Data)
    $json = $Data | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Set-SetupStatus {
    # Ghi ket qua 1 phase vao state\status.json (gop voi cac phase truoc). KHONG chua khoa.
    param([string]$Root, [string]$Phase, [string]$Code, [string]$Message, [hashtable]$Extra)
    New-SetupDirs $Root
    $path = Join-Path $Root 'state\status.json'
    $phases = [ordered]@{}
    $old = Get-JsonFile $path
    if ($null -ne $old -and ($old.PSObject.Properties.Name -contains 'phases')) {
        foreach ($p in $old.phases.PSObject.Properties) {
            $entry = [ordered]@{}
            foreach ($f in $p.Value.PSObject.Properties) { $entry[$f.Name] = $f.Value }
            $phases[$p.Name] = $entry
        }
    }
    $entry = [ordered]@{
        code    = $Code
        time    = (Get-Date).ToString('o')
        message = (Redact-Secrets $Message)
    }
    if ($Extra) { foreach ($k in $Extra.Keys) { $entry[$k] = $Extra[$k] } }
    $phases[$Phase] = $entry
    Save-JsonFile $path ([ordered]@{ version = (Get-KitVersion); phases = $phases })
}

# ---------------------------------------------------------------- File .env
function Read-DotEnv {
    # Doc .env: bo dong trong / dong # / dong hong; cat khoang trang; bo cap nhay bao quanh.
    param([string]$Path)
    $result = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Path)) { return $result }
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $text = $line.Trim()
        if ($text.Length -eq 0) { continue }
        if ($text.StartsWith('#')) { continue }
        $index = $text.IndexOf('=')
        if ($index -lt 1) { continue }
        $name = $text.Substring(0, $index).Trim()
        $value = $text.Substring($index + 1).Trim()
        $quoted = ($value.StartsWith('"') -and $value.EndsWith('"')) -or
                  ($value.StartsWith("'") -and $value.EndsWith("'"))
        if ($value.Length -ge 2 -and $quoted) { $value = $value.Substring(1, $value.Length - 2).Trim() }
        if ($name.Length -gt 0) { $result[$name] = $value }
    }
    return $result
}

function Set-DotEnvValue {
    # Doi gia tri 1 bien trong .env (giu nguyen chu thich va thu tu); chua co thi them cuoi.
    param([string]$Path, [string]$Name, [string]$Value)
    $lines = New-Object System.Collections.ArrayList
    if (Test-Path -LiteralPath $Path) { foreach ($l in [IO.File]::ReadAllLines($Path)) { [void]$lines.Add($l) } }
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ('^\s*' + [regex]::Escape($Name) + '\s*=')) {
            $lines[$i] = $Name + '=' + $Value
            $found = $true
            break
        }
    }
    if (-not $found) { [void]$lines.Add($Name + '=' + $Value) }
    $text = ($lines -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

# ---------------------------------------------------------------- Khoi co danh dau (CLAUDE.md toan cuc)
function Update-MarkerBlock {
    # Chen/thay khoi nam giua BeginMarker...EndMarker. Giu nguyen noi dung khac, kieu xuong dong
    # va BOM cua file goc. Chay 2 lan cho cung ket qua.
    param([string]$Path, [string]$BeginMarker, [string]$EndMarker, [string]$Block)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $hasBom = $false
    $content = ''
    $newline = "`r`n"
    if (Test-Path -LiteralPath $Path) {
        $bytes = [IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $hasBom = $true
            $content = [Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
        } else {
            $content = [Text.Encoding]::UTF8.GetString($bytes)
        }
        if ($content.Contains("`r`n")) { $newline = "`r`n" }
        elseif ($content.Contains("`n")) { $newline = "`n" }
    }
    $normalized = ($Block -replace "`r?`n", $newline).TrimEnd("`r", "`n")
    $start = $content.IndexOf($BeginMarker, [StringComparison]::Ordinal)
    $end = -1
    if ($start -ge 0) {
        $end = $content.IndexOf($EndMarker, $start + $BeginMarker.Length, [StringComparison]::Ordinal)
    }
    if ($start -ge 0 -and $end -ge 0) {
        $endAfter = $end + $EndMarker.Length
        $content = $content.Substring(0, $start) + $normalized + $content.Substring($endAfter)
    } else {
        if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) { $content += $newline }
        if ($content.Length -gt 0) { $content += $newline }
        $content += $normalized + $newline
    }
    [IO.File]::WriteAllText($Path, $content, (New-Object System.Text.UTF8Encoding($hasBom)))
}

# ---------------------------------------------------------------- PATH + bien moi truong
function Add-PathSegment {
    # Ham thuan: them 1 thu muc vao chuoi PATH neu chua co (khong phan biet hoa thuong).
    param([AllowNull()][string]$PathValue, [string]$Segment)
    $parts = @()
    if ($PathValue) { $parts = @($PathValue.Split(';') | Where-Object { $_.Trim().Length -gt 0 }) }
    $wanted = $Segment.TrimEnd('\')
    foreach ($p in $parts) {
        if ($p.TrimEnd('\') -ieq $wanted) { return ($parts -join ';') }
    }
    return (($parts + $Segment) -join ';')
}

function Refresh-SessionPath {
    # Nap lai PATH (Machine + User) vao tien trinh hien tai de thay phan mem vua cai.
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $joined = @($machine, $user) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $env:Path = ($joined -join ';')
}

function Get-EnvScope {
    # Mac dinh 'User'. Test dat AISONNET_ENV_SCOPE=Process de KHONG dong vao may that.
    if ($env:AISONNET_ENV_SCOPE -eq 'Process') { return 'Process' }
    return 'User'
}

function Get-UserEnv {
    param([string]$Name)
    return [Environment]::GetEnvironmentVariable($Name, (Get-EnvScope))
}

function Set-UserEnv {
    param([string]$Name, [AllowNull()][string]$Value, [switch]$DryRun)
    if ($DryRun) {
        Write-Ascii ("[DryRun] Se dat bien moi truong {0} (muc {1})." -f $Name, (Get-EnvScope))
        return
    }
    [Environment]::SetEnvironmentVariable($Name, $Value, (Get-EnvScope))
}

# ---------------------------------------------------------------- Chay lenh ngoai
function Invoke-Native {
    # Chay chuong trinh ngoai, thu stdout+stderr, tra { ExitCode; Output }.
    param([string]$Exe, [string[]]$Arguments)
    $global:LASTEXITCODE = 0
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $lines = @()
    try {
        $lines = @(& $Exe @Arguments 2>&1 | ForEach-Object { $_.ToString() })
        $code = $LASTEXITCODE
    } catch {
        $lines = @($_.Exception.Message)
        $code = 1
    } finally {
        $ErrorActionPreference = $previous
    }
    return @{ ExitCode = $code; Output = ($lines -join "`n").TrimEnd() }
}

function Get-PythonInvocation {
    # Mac dinh: py -3.12 -X utf8. Co -PythonExe (vd venv de test) thi dung file do va KHONG --user.
    param([string]$PythonExe)
    # Python co the vua duoc cai o buoc truoc (tien trinh khac) -> nap lai PATH de thay 'py'.
    Refresh-SessionPath
    $env:PYTHONUTF8 = '1'
    if ($PythonExe) { return @{ Exe = $PythonExe; Prefix = @('-X', 'utf8'); UseUser = $false } }
    return @{ Exe = 'py'; Prefix = @('-3.12', '-X', 'utf8'); UseUser = $true }
}

function Invoke-Python {
    param($Invocation, [string[]]$Arguments)
    return Invoke-Native $Invocation.Exe (@($Invocation.Prefix) + @($Arguments))
}

function Get-LastLines {
    # Lay N dong cuoi cua mot doan van ban, da loc khoa.
    param([string]$Text, [int]$Count = 3)
    $lines = @(($Text -split "`r?`n") | Where-Object { $_.Trim().Length -gt 0 })
    if ($lines.Count -gt $Count) { $lines = $lines[($lines.Count - $Count)..($lines.Count - 1)] }
    return (Redact-Secrets ($lines -join ' | '))
}

function Test-NetworkErrorText {
    # Dau hieu loi mang tam thoi trong dau ra cua pip/winget.
    param([string]$Text)
    return ($Text -match '(?i)(connection|timed out|timeout|temporary failure|name resolution|ssl|network|0x80072ee|0x80072ef|read timed)')
}

# ---------------------------------------------------------------- winget
function Test-Winget {
    return ($null -ne (Get-Command winget.exe -ErrorAction SilentlyContinue))
}

function Get-WingetOutcome {
    # Ham thuan: phan loai ket qua winget tu ma thoat + noi dung dau ra.
    # Tra: OK | ALREADY | NO_INSTALLER | UAC_DECLINED | NETWORK | SOURCE | OTHER
    param([int]$ExitCode, [AllowNull()][string]$Output)
    $text = ''
    if ($Output) { $text = $Output }
    if ($ExitCode -eq 0) {
        if ($text -match '(?i)already installed') { return 'ALREADY' }
        return 'OK'
    }
    if ($text -match '(?i)(already installed|no newer package)') { return 'ALREADY' }
    if ($ExitCode -eq -1978335216 -or $text -match '(?i)no applicable installer') { return 'NO_INSTALLER' }
    if ($text -match '(?i)(exit code:\s*1223|cancel|declined|denied by the user|0x800704c7)') { return 'UAC_DECLINED' }
    if (Test-NetworkErrorText $text) { return 'NETWORK' }
    if ($text -match '(?i)(source|0x8a15000f)') { return 'SOURCE' }
    return 'OTHER'
}

function Invoke-WingetInstall {
    # Cai 1 goi bang winget. Tra { Code; ExitCode; Note }. Code = OK | E_WINGET | E_UAC_DECLINED |
    # E_NETWORK | E_WINGET_SOURCE | E_CORE_<Short>.
    param([hashtable]$Package, [switch]$DryRun)
    $id = $Package.Id
    if ($DryRun) {
        Write-Ascii ("[DryRun] Se cai {0} (uu tien scope {1})." -f $id, $Package.Scope)
        return @{ Code = 'OK'; ExitCode = 0; Note = 'dryrun' }
    }
    if (-not (Test-Winget)) { return @{ Code = 'E_WINGET'; ExitCode = -1; Note = 'khong co winget' } }
    $listed = Invoke-Native 'winget' @('list', '--id', $id, '--exact', '--accept-source-agreements')
    if ($listed.ExitCode -eq 0) { return @{ Code = 'OK'; ExitCode = 0; Note = 'da cai san' } }
    if ($Package.MayAskUac) { Write-Ascii 'Luu y: Windows co the hien hop thoai xin quyen - hay bam Yes (Co).' }
    $scopes = @('')
    if ($Package.Scope -eq 'user') { $scopes = @('user', '') }
    elseif ($Package.Scope -eq 'machine') { $scopes = @('machine') }
    $last = @{ ExitCode = 1; Output = '' }
    foreach ($scope in $scopes) {
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            $args = @('install', '--exact', '--id', $id,
                      '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
            if ($scope) { $args += @('--scope', $scope) }
            $last = Invoke-Native 'winget' $args
            $outcome = Get-WingetOutcome $last.ExitCode $last.Output
            if ($outcome -eq 'OK' -or $outcome -eq 'ALREADY') { return @{ Code = 'OK'; ExitCode = $last.ExitCode; Note = "scope=$scope" } }
            if ($outcome -eq 'UAC_DECLINED') { return @{ Code = 'E_UAC_DECLINED'; ExitCode = $last.ExitCode; Note = (Get-LastLines $last.Output 2) } }
            if ($outcome -eq 'SOURCE') { return @{ Code = 'E_WINGET_SOURCE'; ExitCode = $last.ExitCode; Note = (Get-LastLines $last.Output 2) } }
            if ($outcome -eq 'NO_INSTALLER') { break }
            if ($outcome -eq 'NETWORK' -and $attempt -lt 2) { Start-Sleep -Seconds 5; continue }
            if ($outcome -eq 'NETWORK') { return @{ Code = 'E_NETWORK'; ExitCode = $last.ExitCode; Note = (Get-LastLines $last.Output 2) } }
            break
        }
    }
    return @{ Code = ('E_CORE_' + $Package.Short); ExitCode = $last.ExitCode; Note = (Get-LastLines $last.Output 3) }
}

# ---------------------------------------------------------------- Do may
function Find-Chrome {
    # Tim Chrome bang duong dan file + registry (KHONG dung Get-Command chrome).
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
    )
    foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
    $reg = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
    if (Test-Path $reg) {
        $value = (Get-ItemProperty $reg).'(default)'
        if ($value -and (Test-Path -LiteralPath $value)) { return $value }
    }
    return $null
}

function Find-FfmpegLinks {
    # ffmpeg (portable) duoc winget dat o thu muc Links; them vao PATH tien trinh neu thieu.
    $links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
    if ((Test-Path -LiteralPath (Join-Path $links 'ffmpeg.exe')) -and ($env:Path -notlike "*$links*")) {
        $env:Path = $env:Path + ';' + $links
    }
}

function Get-ToolVersion {
    # Tra chuoi phien ban (dong dau) hoac $null neu khong chay duoc.
    param([string]$Tool)
    Refresh-SessionPath
    Find-FfmpegLinks
    switch ($Tool) {
        'git'    { $r = Invoke-Native 'git' @('--version') }
        'py'     { $r = Invoke-Native 'py' @('-3.12', '--version') }
        'ffmpeg' { $r = Invoke-Native 'ffmpeg' @('-version') }
        'claude' { $r = Invoke-Native 'claude' @('--version') }
        'node'   { $r = Invoke-Native 'node' @('--version') }
        'chrome' {
            $path = Find-Chrome
            if ($path) { return 'chrome (co file)' }
            return $null
        }
        'code' {
            $path = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'
            if (Test-Path -LiteralPath $path) { return 'vscode (co file)' }
            $r = Invoke-Native 'code' @('--version')
        }
        default  { return $null }
    }
    if ($null -eq $r -or $r.ExitCode -ne 0) { return $null }
    return (($r.Output -split "`n")[0]).Trim()
}

function Get-Prereq {
    # Doc thong tin may qua CIM. Tung muc loi se la $null (khong lam hong ca ham).
    $info = [ordered]@{
        Build = 0; Arch = $env:PROCESSOR_ARCHITECTURE; RamGB = 0; FreeGB = 0; Domain = $false
        IsAdmin = $false; Ok = $true
    }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $drive = (Split-Path -Qualifier $env:SystemDrive)
        $disk = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $drive) -ErrorAction Stop
        $info.Build = [int]$os.BuildNumber
        $info.RamGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        $info.FreeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
        $info.Domain = [bool]$cs.PartOfDomain
    } catch {
        $info.Ok = $false
    }
    try {
        $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        $info.IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { }
    return $info
}

function Test-PathRisk {
    # Ham thuan: tra danh sach canh bao cho cac duong dan (OneDrive, ky tu co dau, khoang trang, dai).
    param([string[]]$Paths)
    $risks = New-Object System.Collections.ArrayList
    foreach ($p in @($Paths)) {
        if ([string]::IsNullOrEmpty($p)) { continue }
        if ($p -match '(?i)onedrive') { [void]$risks.Add('OneDrive') }
        if ($p -match '[^\x00-\x7F]') { [void]$risks.Add('ky-tu-co-dau') }
        if ($p -match '\s') { [void]$risks.Add('khoang-trang') }
        if ($p.Length -gt 180) { [void]$risks.Add('duong-dan-dai') }
    }
    return @($risks | Select-Object -Unique)
}

# ---------------------------------------------------------------- Kiem tra khoa API
function Test-KeyFormat {
    # Ham thuan: tra '' neu hop le, nguoc lai tra ghi chu ngan (khong chua khoa).
    param([string]$Name, [AllowNull()][string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return '' }
    if ($Name -eq 'TIKTOK_API23_KEY') {
        if ($Value -match '(?i)rapidapi|header|curl') { return 'dan nham ca doan code: chi copy chuoi sau x-rapidapi-key' }
    }
    if ($Value -match '\s') { return 'co khoang trang/xuong dong ben trong' }
    if ($Value -match '^["''<]|["''>]$') { return 'con dau nhay hoac dau <> bao quanh' }
    if ($Name -eq 'GENMAX_VOICE_ID') { return '' }
    if ($Name -eq 'GENMAX_MODEL') {
        if ($Value -notmatch '^[A-Za-z0-9_.\-]{3,60}$') { return 'ten model chi gom chu, so, dau _ . -' }
        return ''
    }
    if ($Name -eq 'GENMAX_EMOTION_TAGS') {
        if ($Value -notmatch '^(0|1)$') { return 'chi nhan 1 (bat) hoac 0 (tat)' }
        return ''
    }
    if ($Name -eq 'TELEGRAM_CHAT_ID') {
        if ($Value -notmatch '^-?\d+$') { return 'chat id phai la so' }
        return ''
    }
    if ($Value.Length -lt 12) { return 'qua ngan, co the chua copy du' }
    if ($Name -eq 'TELEGRAM_BOT_TOKEN' -and $Value -notmatch '^\d{6,}:[A-Za-z0-9_\-]{20,}$') {
        return 'token bot phai co dang so:chuoi'
    }
    if ($Name -ne 'GEMINI_API_KEY' -and $Value -match '^AIza') { return 'day la khoa Gemini, khong phai khoa nay' }
    if ($Name -ne 'GENMAX_API_KEY' -and $Value -match '^sk_') { return 'day la khoa Genmax, khong phai khoa nay' }
    return ''
}

function Get-ApiErrorCode {
    # Ham thuan: ma HTTP + noi dung phan hoi -> OK | E_KEY_INVALID | E_KEY_EXPIRED | E_QUOTA | E_KEY_NETWORK.
    param([int]$Status, [AllowNull()][string]$Body)
    $text = ''
    if ($Body) { $text = $Body }
    if ($Status -ge 200 -and $Status -lt 300) { return 'OK' }
    if ($Status -eq 0 -or $Status -ge 500) { return 'E_KEY_NETWORK' }
    if ($Status -eq 429 -or $Status -eq 402) { return 'E_QUOTA' }
    if ($text -match '(?i)expired') { return 'E_KEY_EXPIRED' }
    if ($text -match '(?i)(quota|insufficient credit|rate limit)') { return 'E_QUOTA' }
    return 'E_KEY_INVALID'
}

function Get-ApiSpec {
    # Dia chi + header goi thu cho tung khoa (khong in ra man hinh). $null = khong co health check.
    param([string]$Name, [string]$Value)
    switch ($Name) {
        'APIFY_TOKEN' {
            return @{ Url = 'https://api.apify.com/v2/users/me'; Headers = @{ Authorization = ('Bearer ' + $Value) } }
        }
        'GENMAX_API_KEY' {
            return @{ Url = 'https://api.genmax.io/v1/auth/me'; Headers = @{ 'xi-api-key' = $Value } }
        }
        'GEMINI_API_KEY' {
            $url = 'https://generativelanguage.googleapis.com/v1beta/models?pageSize=1'
            return @{ Url = $url; Headers = @{ 'x-goog-api-key' = $Value } }
        }
        'TIKTOK_API23_KEY' {
            # Goi user-info tiktok (tru 1 trong 100 luot/thang cua goi BASIC). UA trinh duyet de tranh Cloudflare 1010.
            $ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36'
            return @{ Url = 'https://tiktok-api23.p.rapidapi.com/api/user/info?uniqueId=tiktok'
                      Headers = @{ 'x-rapidapi-key' = $Value; 'x-rapidapi-host' = 'tiktok-api23.p.rapidapi.com'; 'User-Agent' = $ua } }
        }
        'TELEGRAM_BOT_TOKEN' {
            return @{ Url = ('https://api.telegram.org/bot' + $Value + '/getMe'); Headers = @{} }
        }
        default { return $null }
    }
}

function Invoke-ApiRequest {
    # Goi GET, tra { Status; Body }. Khong bao gio nem loi, khong in URL/khoa.
    param([string]$Url, [hashtable]$Headers)
    try {
        $r = Invoke-WebRequest -Uri $Url -Headers $Headers -UseBasicParsing -TimeoutSec 25
        return @{ Status = [int]$r.StatusCode; Body = [string]$r.Content }
    } catch {
        $response = $null
        try { $response = $_.Exception.Response } catch { }
        if ($null -eq $response) { return @{ Status = 0; Body = '' } }
        $body = ''
        try {
            $reader = New-Object IO.StreamReader($response.GetResponseStream())
            $body = $reader.ReadToEnd()
            $reader.Close()
        } catch { }
        return @{ Status = [int]$response.StatusCode; Body = $body }
    }
}

function Get-JsonProp {
    # Doc 1 thuoc tinh cua doi tuong JSON, thieu thi tra $null (an toan voi StrictMode).
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
    return $null
}

function Get-VoiceRows {
    # Ham thuan: JSON danh sach giong cua Genmax -> mang { Id; Name; Gender; Note }.
    # elevenlabs: voices[]; minimax: voice_list[] (voice_name, tag_list); capcut: voice_list[] (name, tags).
    param([string]$Provider, [AllowNull()][string]$Json)
    $rows = New-Object System.Collections.ArrayList
    if ([string]::IsNullOrWhiteSpace($Json)) { return @() }
    try { $data = $Json | ConvertFrom-Json } catch { return @() }
    if ($Provider -eq 'elevenlabs') {
        foreach ($v in @(Get-JsonProp $data 'voices')) {
            if ($null -eq $v) { continue }
            [void]$rows.Add(@{
                Id = [string](Get-JsonProp $v 'voice_id'); Name = [string](Get-JsonProp $v 'name')
                Gender = [string](Get-JsonProp $v 'gender'); Note = [string](Get-JsonProp $v 'description')
            })
        }
    } else {
        foreach ($v in @(Get-JsonProp $data 'voice_list')) {
            if ($null -eq $v) { continue }
            $name = [string](Get-JsonProp $v 'voice_name')
            if (-not $name) { $name = [string](Get-JsonProp $v 'name') }
            $tags = @(Get-JsonProp $v 'tag_list') + @(Get-JsonProp $v 'tags') | Where-Object { $_ }
            $gender = [string](Get-JsonProp $v 'gender')
            if (-not $gender -and ($tags -contains 'Female')) { $gender = 'female' }
            if (-not $gender -and ($tags -contains 'Male')) { $gender = 'male' }
            $note = [string](Get-JsonProp $v 'description')
            if (-not $note) { $note = ($tags -join ', ') }
            [void]$rows.Add(@{ Id = [string](Get-JsonProp $v 'voice_id'); Name = $name; Gender = $gender; Note = $note })
        }
    }
    return @($rows | Where-Object { $_.Id })
}

function Get-TelegramSendOutcome {
    # Ham thuan: ma HTTP khi gui tin thu -> OK | E_TG_BLOCKED | E_TG_CHAT | E_TG_TOKEN | E_KEY_NETWORK | E_TG_SEND.
    param([int]$Status, [AllowNull()][string]$Body)
    $text = ''
    if ($Body) { $text = $Body }
    if ($Status -ge 200 -and $Status -lt 300) { return 'OK' }
    if ($Status -eq 0 -or $Status -ge 500) { return 'E_KEY_NETWORK' }
    if ($Status -eq 401 -or $Status -eq 404) { return 'E_TG_TOKEN' }
    if ($Status -eq 403 -or $text -match '(?i)(blocked|kicked|forbidden)') { return 'E_TG_BLOCKED' }
    if ($Status -eq 400 -and $text -match '(?i)chat not found') { return 'E_TG_CHAT' }
    return 'E_TG_SEND'
}

function Send-TelegramTest {
    # Gui 1 tin thu toi chat cua hoc vien. Tra { Code; Note }. KHONG bao gio in token/URL.
    param([string]$Token, [string]$ChatId)
    $message = [uri]::EscapeDataString('AISONNET: ket noi Telegram thanh cong! Ban co the bo qua tin nay.')
    $url = 'https://api.telegram.org/bot' + $Token + '/sendMessage?chat_id=' + [uri]::EscapeDataString($ChatId) + '&text=' + $message
    $reply = Invoke-ApiRequest $url @{}
    $code = Get-TelegramSendOutcome $reply.Status $reply.Body
    $note = 'http=' + $reply.Status
    if ($code -eq 'OK') { $note = 'da gui tin thu - hay kiem tra Telegram' }
    return @{ Code = $code; Note = $note }
}

function Invoke-ApiHealth {
    # Kiem tra 1 khoa. Tra { Name; Code; Note }. Code = OK | E_KEY_* | BO_QUA | CHUA_DIEN.
    param([string]$Name, [AllowNull()][string]$Value, [bool]$Required = $false, [switch]$DryRun)
    if ([string]::IsNullOrEmpty($Value)) {
        $empty = 'BO_QUA'
        if ($Required) { $empty = 'CHUA_DIEN' }
        return @{ Name = $Name; Code = $empty; Note = '' }
    }
    $formatNote = Test-KeyFormat $Name $Value
    if ($formatNote) { return @{ Name = $Name; Code = 'E_KEY_FORMAT'; Note = $formatNote } }
    $spec = Get-ApiSpec $Name $Value
    if ($null -eq $spec) { return @{ Name = $Name; Code = 'OK'; Note = 'khong co health check' } }
    if ($DryRun) { return @{ Name = $Name; Code = 'BO_QUA'; Note = 'DryRun' } }
    $response = Invoke-ApiRequest $spec.Url $spec.Headers
    $code = Get-ApiErrorCode $response.Status $response.Body
    $note = ''
    if ($code -eq 'OK' -and $Name -eq 'GENMAX_API_KEY') {
        try { $note = 'credit=' + [string](($response.Body | ConvertFrom-Json).credit_balance) } catch { }
    }
    if ($code -ne 'OK') { $note = 'http=' + $response.Status }
    return @{ Name = $Name; Code = $code; Note = $note }
}
