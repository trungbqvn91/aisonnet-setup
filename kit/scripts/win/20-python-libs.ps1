# 20-python-libs.ps1 - Phase 3a: cai thu vien Python cho NGUOI DUNG (dung duoc o moi thu muc).
# Co ghim faster-whisper==1.2.1 va av==16.1.0 (xem common.ps1). KHONG nang cap pip.
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [string]$PythonExe = ''
)
. (Join-Path $PSScriptRoot 'common.ps1')

$python = Get-PythonInvocation $PythonExe
$code = 'OK'
$detail = ''
Write-Ascii '== CAI THU VIEN PYTHON =='

if ($DryRun) {
    Write-Ascii '[DryRun] Se cai (cho nguoi dung): '
    foreach ($p in $script:PythonPackages) { Write-Ascii ('  ' + $p) }
    exit 0
}

$version = Invoke-Python $python @('--version')
if ($version.ExitCode -ne 0) {
    $code = 'E_PY_MISSING'
    $detail = 'chua co Python 3.12 - chay 10-install-core.ps1 truoc'
}

if ($code -eq 'OK') {
    $installArgs = @('-m', 'pip', 'install', '--disable-pip-version-check')
    if ($python.UseUser) { $installArgs += '--user' }
    $installArgs += $script:PythonPackages
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        Write-Ascii ("Dang cai (lan {0}) - co the mat vai phut ..." -f $attempt)
        $install = Invoke-Python $python $installArgs
        if ($install.ExitCode -eq 0) { $code = 'OK'; break }
        $code = 'E_PIP'
        $detail = Get-LastLines $install.Output 3
        if (-not (Test-NetworkErrorText $install.Output)) { break }
        if ($attempt -lt 3) { Start-Sleep -Seconds 5 }
    }
}

if ($code -eq 'OK') {
    $importCode = 'import faster_whisper, playwright, apify_client, google.genai, dotenv, requests, av; print(av.__version__)'
    $check = Invoke-Python $python @('-c', $importCode)
    if ($check.ExitCode -ne 0) {
        $code = 'E_PIP'
        $detail = 'cai xong nhung import loi: ' + (Get-LastLines $check.Output 2)
    } elseif ($check.Output.Trim() -notmatch '^16\.') {
        $code = 'E_PIP'
        $detail = 'phien ban av khong dung ban da ghim (can 16.x): ' + $check.Output.Trim()
    }
}

Set-SetupStatus $Root 'python-libs' $code $detail
Write-SetupLog $Root ("PYTHON-LIBS: {0} {1}" -f $code, $detail)
if ($code -ne 'OK') {
    Write-Ascii ("{0}: {1}" -f $code, $detail)
    exit 1
}
Write-Ascii 'PYTHON-LIBS: OK (7 thu vien da cai va import duoc).'
exit 0
