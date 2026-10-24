# assert.ps1 - bo assert don gian + Test-Case (dem so ca PASS/FAIL, in tung ca hong).
$script:TestPass = 0
$script:TestFail = 0
$script:TestFailures = New-Object System.Collections.ArrayList

function Test-Case {
    # LUU Y: ten tham so dat la $CaseName/$CaseBody (khac $Name/$Body) vi scriptblock cua test
    # nhin thay bien cua ham nay (dynamic scope) - tham so trung ten se che bien cua test.
    param([string]$CaseName, [scriptblock]$CaseBody)
    try {
        & $CaseBody
        $script:TestPass++
    } catch {
        $script:TestFail++
        [void]$script:TestFailures.Add(('{0}: {1}' -f $CaseName, $_.Exception.Message))
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message = 'Gia tri khong bang nhau')
    if ($Expected -ne $Actual) { throw "$Message. Expected=[$Expected] Actual=[$Actual]" }
}

function Assert-True {
    param([bool]$Condition, [string]$Message = 'Dieu kien sai')
    if (-not $Condition) { throw $Message }
}

function Assert-Contains {
    param([string]$Text, [string]$Part, [string]$Message = 'Khong thay doan can co')
    if (-not $Text.Contains($Part)) { throw "$Message. Part=[$Part]" }
}

function Assert-NotContains {
    param([string]$Text, [string]$Part, [string]$Message = 'Thay doan KHONG duoc co')
    if ($Text.Contains($Part)) { throw "$Message. Part=[$Part]" }
}

function Assert-Throws {
    param([scriptblock]$Script, [string]$Message = 'Can co loi')
    try { & $Script } catch { return }
    throw $Message
}
