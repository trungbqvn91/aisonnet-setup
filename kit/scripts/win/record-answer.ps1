# record-answer.ps1 - ghi 1 cau tra loi phong van vao state\interview.json (KHONG nhan khoa/mat khau).
# Vi du: record-answer.ps1 -Name goi_claude -Value Pro
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Value
)
. (Join-Path $PSScriptRoot 'common.ps1')

# Tu choi neu gia tri giong khoa API hoac qua dai (de tranh ghi nham bi mat).
if ((Redact-Secrets $Value) -ne $Value -or $Value.Length -gt 200) {
    Write-Ascii 'E_INTERVIEW_SECRET: day khong phai cau tra loi phong van (giong khoa/mat khau hoac qua dai). Khong ghi.'
    exit 1
}
if ($DryRun) {
    Write-Ascii '[DryRun] Se ghi cau tra loi phong van.'
    exit 0
}

New-SetupDirs $Root
$path = Join-Path $Root 'state\interview.json'
$answers = [ordered]@{}
$old = Get-JsonFile $path
if ($null -ne $old) { foreach ($p in $old.PSObject.Properties) { $answers[$p.Name] = $p.Value } }
$answers[$Name] = $Value
Save-JsonFile $path $answers
Write-Ascii ("Da ghi cau tra loi: {0}" -f $Name)
exit 0
