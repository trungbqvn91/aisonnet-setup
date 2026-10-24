# run-tests.ps1 - chay moi *.Tests.ps1 (khong can mang, khong dong vao may that).
# Moi file dung Test-Case 'ten' { ... }. In tong so ca; ma thoat != 0 neu co ca hong.
param([string]$Filter = '*')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'lib\assert.ps1')

$fileErrors = 0
foreach ($file in (Get-ChildItem -LiteralPath $here -Filter ($Filter + '.Tests.ps1'))) {
    $before = $script:TestPass + $script:TestFail
    try {
        . $file.FullName
        $count = $script:TestPass + $script:TestFail - $before
        Write-Host ('FILE {0}: {1} ca' -f $file.Name, $count)
    } catch {
        $fileErrors++
        Write-Host ('FILE {0}: LOI NAP FILE: {1}' -f $file.Name, $_.Exception.Message)
    }
}

foreach ($failure in $script:TestFailures) { Write-Host ('FAIL ' + $failure) }
Write-Host ('TONG: PASS={0} FAIL={1} LOI-NAP-FILE={2}' -f $script:TestPass, $script:TestFail, $fileErrors)
if ($script:TestFail -gt 0 -or $fileErrors -gt 0) { exit 1 }
Write-Host 'PASS tests'
exit 0
