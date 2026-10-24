# 00-preflight.ps1 - Phase 1: do may. KHONG thay doi may.
# Ket qua: bang tren man hinh + state\preflight.json (may doc duoc) + state\status.json
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET'
)
. (Join-Path $PSScriptRoot 'common.ps1')

$errors = New-Object System.Collections.ArrayList
$warnings = New-Object System.Collections.ArrayList

Write-Ascii '== DO MAY AISONNET =='
$prereq = Get-Prereq
if (-not $prereq.Ok) { [void]$warnings.Add('khong-doc-duoc-cim') }

# --- He dieu hanh, CPU, RAM, o dia
$isWin11 = ($prereq.Build -ge 22000)
Write-Ascii ("Windows build {0} | CPU {1} | RAM {2} GB | o trong {3} GB" -f
    $prereq.Build, $prereq.Arch, $prereq.RamGB, $prereq.FreeGB)
if ($prereq.Ok) {
    if ($prereq.Build -lt 17763) {
        [void]$errors.Add('E_OS_UNSUPPORTED')
        Write-Ascii 'E_OS_UNSUPPORTED: Windows qua cu (can Windows 10 ban 1809 tro len).'
    } elseif (-not $isWin11) {
        [void]$warnings.Add('windows-10')
        Write-Ascii 'Canh bao: Windows 10 - bo cai chua duoc kiem chung day du, co the gap loi.'
    }
    if ($prereq.FreeGB -lt 8) {
        [void]$errors.Add('E_DISK')
        Write-Ascii 'E_DISK: o dia con it hon 8 GB trong. Can don dep truoc khi cai.'
    }
}
if ($prereq.Arch -match 'ARM') {
    [void]$warnings.Add('arm64')
    Write-Ascii 'Canh bao: CPU ARM64 - ngoai pham vi ho tro cua bo cai nay.'
}
if ($prereq.Domain) {
    [void]$warnings.Add('may-cong-ty')
    Write-Ascii 'Canh bao: may tham gia domain/cong ty - co the bi chinh sach chan cai dat.'
}
Write-Ascii ("Quyen admin: {0}" -f $prereq.IsAdmin)

# --- Duong dan co rui ro (dau tieng Viet, khoang trang, OneDrive chuyen huong Desktop/Documents)
$desktop = [Environment]::GetFolderPath('Desktop')
$documents = [Environment]::GetFolderPath('MyDocuments')
$risks = @(Test-PathRisk @($env:USERPROFILE, $desktop, $documents, $Root))
if ($risks.Count -gt 0) {
    [void]$warnings.Add('duong-dan: ' + ($risks -join ','))
    Write-Ascii ('Canh bao duong dan: ' + ($risks -join ', '))
}

# --- winget
$hasWinget = Test-Winget
Write-Ascii ("winget: {0}" -f $(if ($hasWinget) { 'co' } else { 'khong thay' }))
if (-not $hasWinget) {
    [void]$errors.Add('E_WINGET')
    Write-Ascii 'E_WINGET: chua co winget. Mo Microsoft Store, cap nhat "App Installer", roi chay lai.'
}

# --- Mang
$net = [ordered]@{ github = 'bo-qua'; genmax = 'bo-qua' }
if ($DryRun) {
    Write-Ascii '[DryRun] Khong kiem tra mang.'
} else {
    foreach ($site in @('github', 'genmax')) {
        $url = 'https://{0}.{1}' -f $site, $(if ($site -eq 'github') { 'com' } else { 'io' })
        $reply = Invoke-ApiRequest $url @{}
        if ($reply.Status -gt 0) { $net[$site] = 'ok' } else { $net[$site] = 'loi' }
    }
    Write-Ascii ("Mang: github={0} genmax={1}" -f $net.github, $net.genmax)
    if ($net.github -ne 'ok' -and $net.genmax -ne 'ok') {
        [void]$errors.Add('E_NETWORK')
        Write-Ascii 'E_NETWORK: khong ra duoc Internet. Kiem tra Wi-Fi/VPN/proxy roi chay lai.'
    }
}

# --- Cong cu da co
$tools = [ordered]@{}
foreach ($tool in @('git', 'py', 'ffmpeg', 'chrome', 'code', 'claude', 'node')) {
    $version = Get-ToolVersion $tool
    if ($version) { $tools[$tool] = $version } else { $tools[$tool] = $null }
    Write-Ascii ("{0,-7}: {1}" -f $tool, $(if ($version) { $version } else { 'chua thay' }))
}

# --- Ghi ket qua may doc duoc
$code = 'OK'
if ($errors.Count -gt 0) { $code = ($errors -join ',') }
if (-not $DryRun) {
    New-SetupDirs $Root
    $report = [ordered]@{
        version = (Get-KitVersion); windows_build = $prereq.Build; is_win11 = $isWin11
        arch = $prereq.Arch; ram_gb = $prereq.RamGB; free_gb = $prereq.FreeGB
        is_admin = $prereq.IsAdmin; domain = $prereq.Domain; winget = $hasWinget
        path_risks = $risks; net = $net; tools = $tools
        errors = @($errors); warnings = @($warnings)
    }
    Save-JsonFile (Join-Path $Root 'state\preflight.json') $report
    Set-SetupStatus $Root 'preflight' $code ('canh bao: ' + ($warnings -join '; '))
    Write-SetupLog $Root ("PREFLIGHT: {0} (canh bao: {1})" -f $code, ($warnings -join '; '))
}
Write-Ascii ("PREFLIGHT: {0}" -f $code)
if ($errors.Count -gt 0) { exit 1 }
exit 0
