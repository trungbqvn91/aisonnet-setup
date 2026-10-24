# 40-browser-tools.ps1 - Phase 4: Playwright + Chromium, va trang cai extension Claude cho Chrome.
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [switch]$VerifyOnly,
    [switch]$OpenExtensionPage,
    [string]$PythonExe = ''
)
. (Join-Path $PSScriptRoot 'common.ps1')

# Mo Chromium an (headless), vao trang data:, doc tieu de. In OK neu chay duoc.
$verifySource = @'
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto('data:text/html,<title>aisonnet-ok</title>')
    print('TITLE=' + page.title())
    browser.close()
'@

Write-Ascii '== TRINH DUYET: PLAYWRIGHT =='
if ($DryRun) {
    Write-Ascii '[DryRun] Se chay: python -m playwright install chromium, roi mo thu 1 trang.'
    exit 0
}

$python = Get-PythonInvocation $PythonExe
$code = 'OK'
$detail = ''

if (-not $VerifyOnly) {
    Write-Ascii 'Dang tai Chromium cho Playwright (lan dau co the mat vai phut) ...'
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $install = Invoke-Python $python @('-m', 'playwright', 'install', 'chromium')
        if ($install.ExitCode -eq 0) { $code = 'OK'; break }
        $code = 'E_PLAYWRIGHT'
        $detail = Get-LastLines $install.Output 3
        if (-not (Test-NetworkErrorText $install.Output)) { break }
        Start-Sleep -Seconds 5
    }
}

if ($code -eq 'OK') {
    $tmp = Join-Path $env:TEMP ('aisonnet-pw-' + [guid]::NewGuid().ToString('N') + '.py')
    [IO.File]::WriteAllText($tmp, $verifySource, (New-Object System.Text.UTF8Encoding($false)))
    try { $verify = Invoke-Python $python @($tmp) } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    if ($verify.ExitCode -ne 0 -or $verify.Output -notmatch 'TITLE=aisonnet-ok') {
        $code = 'E_PLAYWRIGHT'
        $detail = Get-LastLines $verify.Output 3
    } else {
        Write-Ascii 'Playwright mo duoc trinh duyet an: OK.'
    }
}

# Trang cai extension Claude cho Chrome: chi mo khi da co URL chinh thuc trong assets\links.json.
$url = ''
$links = Get-JsonFile (Join-Path $script:KitRoot 'assets\links.json')
if ($null -ne $links -and ($links.PSObject.Properties.Name -contains 'claude_chrome_extension_url')) {
    $url = [string]$links.claude_chrome_extension_url
}
if ([string]::IsNullOrWhiteSpace($url)) {
    Write-Ascii 'Chua co link extension trong links.json: Claude hay tu tim TRANG CHINH THUC, khong tu bia link.'
} elseif ($OpenExtensionPage) {
    Start-Process $url
    Write-Ascii 'Da mo trang cai extension - hoc vien bam "Them vao Chrome".'
}

Set-SetupStatus $Root 'browser-tools' $code $detail
Write-SetupLog $Root ("BROWSER-TOOLS: {0} {1}" -f $code, $detail)
if ($code -ne 'OK') {
    Write-Ascii ("{0}: {1}" -f $code, $detail)
    exit 1
}
exit 0
