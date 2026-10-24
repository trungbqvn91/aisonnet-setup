# 10-install-core.ps1 - Phase 2: cai Git, Python 3.12, FFmpeg, Chrome (neu thieu) bang winget.
# Chay lai nhieu lan an toan: cai nao co roi thi bo qua.
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [switch]$WithVSCode
)
. (Join-Path $PSScriptRoot 'common.ps1')

$packages = @($script:CorePackages)
if ($WithVSCode) {
    $packages += @{ Id = 'Microsoft.VisualStudioCode'; Short = 'VSCODE'; Tool = 'code'; Scope = 'user'; MayAskUac = $false }
}

$failed = New-Object System.Collections.ArrayList
$extra = @{}
Write-Ascii '== CAI PHAN MEM NEN =='

foreach ($package in $packages) {
    $name = $package.Tool
    $already = $null
    if (-not $DryRun) { $already = Get-ToolVersion $name }
    if ($already) {
        Write-Ascii ("[{0}] da co ({1}) - bo qua." -f $package.Id, $already)
        continue
    }
    Write-Ascii ("[{0}] dang cai ..." -f $package.Id)
    $result = Invoke-WingetInstall $package -DryRun:$DryRun
    $extra[$package.Short + '_winget_exit'] = $result.ExitCode
    if ($result.Code -ne 'OK') {
        [void]$failed.Add($result.Code)
        Write-Ascii ("{0}: {1}" -f $result.Code, $result.Note)
        continue
    }
    if ($DryRun) { continue }
    $version = Get-ToolVersion $name
    if ($version) {
        Write-Ascii ("[{0}] OK ({1})" -f $package.Id, $version)
    } else {
        # Da cai nhung terminal nay chua thay: thuong chi can mo terminal moi.
        Write-Ascii ("[{0}] da cai nhung chua thay lenh - hay mo terminal MOI roi chay lai." -f $package.Id)
        [void]$failed.Add('E_PATH')
    }
}

$code = 'OK'
if ($failed.Count -gt 0) { $code = (@($failed | Select-Object -Unique) -join ',') }
if (-not $DryRun) {
    Set-SetupStatus $Root 'core' $code 'Cai Git, Python 3.12, FFmpeg, Chrome.' $extra
    Write-SetupLog $Root ("CORE: {0}" -f $code)
}
if ($code -ne 'OK') {
    Write-Ascii ("CORE: {0} - xem RECOVERY.md" -f $code)
    exit 1
}
Write-Ascii 'CORE: OK. Hay mo terminal MOI de dung cong cu vua cai.'
exit 0
