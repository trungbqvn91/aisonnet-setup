# lint.ps1 - kiem tra tinh cac file .ps1 cua bo cai (khong chay code that).
# Quy tac (xem AGENTS.md):
#  a) co BOM UTF-8          b) parse khong loi         c) khong dung cu phap chi co o PowerShell 7
#  d) khong Set-ExecutionPolicy   e) Invoke-WebRequest phai co -UseBasicParsing
#  f) khong co chuoi giong khoa API that (KHONG co ngoai le)
#  g) script trong kit\scripts\win chi chua ASCII (thong diep tieng Viet khong dau)
#  h) khong dung Write-Host tran trong kit\scripts\win (phai qua Write-Ascii; chi common.ps1 duoc dung Write-Host)
#  i) khong in bien co ten giong khoa (Value/Token/Secret/Key) tru khi qua Mask-Key
$repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$errors = New-Object System.Collections.ArrayList

$syntaxRules = @(
    @{ Name = 'toan-tu-andand'; Pattern = [regex]::Escape('&' + '&') },
    @{ Name = 'toan-tu-oror'; Pattern = [regex]::Escape('|' + '|') },
    @{ Name = 'null-coalescing'; Pattern = [regex]::Escape('?' + '?') },
    @{ Name = 'null-conditional'; Pattern = [regex]::Escape('?' + '.') },
    @{ Name = 'foreach-parallel'; Pattern = 'ForEach-Object\s+-Parallel' },
    @{ Name = 'doi-chinh-sach-chay-script'; Pattern = ('Set' + '-ExecutionPolicy') }
)
$secretPatterns = @(('sk' + '_[A-Za-z0-9]{10,}'), ('AI' + 'za[0-9A-Za-z_-]{20,}'), ('apify' + '_api_[A-Za-z0-9]{6,}'))

$kitWin = Join-Path $repo 'kit\scripts\win'
$files = @(Get-ChildItem -LiteralPath (Join-Path $repo 'kit') -Recurse -Filter '*.ps1') +
         @(Get-ChildItem -LiteralPath (Join-Path $repo 'tests') -Recurse -Filter '*.ps1' |
           Where-Object { $_.FullName -notmatch '\\tests\\tmp\\' })

foreach ($file in $files) {
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 239 -or $bytes[1] -ne 187 -or $bytes[2] -ne 191) {
        [void]$errors.Add("BOM: $($file.FullName)")
    }
    $tokens = $null; $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { [void]$errors.Add("Parse: $($file.FullName): $($parseErrors[0].Message)") }
    $text = [IO.File]::ReadAllText($file.FullName)
    # Quy tac cu phap chi ap dung cho dong CODE (bo dong chu thich bat dau bang #).
    $codeLines = @(($text -split "`r?`n") | Where-Object { -not $_.Trim().StartsWith('#') })
    $codeText = $codeLines -join "`n"
    foreach ($rule in $syntaxRules) {
        if ($codeText -match $rule.Pattern) { [void]$errors.Add("Cam $($rule.Name): $($file.FullName)") }
    }
    if ($text -match 'Invoke-WebRequest' -and $text -notmatch 'Invoke-WebRequest[\s\S]*-UseBasicParsing') {
        [void]$errors.Add("Invoke-WebRequest thieu -UseBasicParsing: $($file.FullName)")
    }
    foreach ($pattern in $secretPatterns) {
        if ($text -match $pattern) { [void]$errors.Add("Giong khoa API that: $($file.FullName)") }
    }

    $isKitWin = $file.FullName.StartsWith($kitWin, [StringComparison]::OrdinalIgnoreCase)
    if (-not $isKitWin) { continue }
    $body = $bytes[3..($bytes.Length - 1)]
    if (@($body | Where-Object { $_ -gt 127 }).Count -gt 0) { [void]$errors.Add("Co ky tu khong ASCII: $($file.FullName)") }
    $lineNo = 0
    foreach ($line in ($text -split "`r?`n")) {
        $lineNo++
        $code = $line.Trim()
        if ($code.StartsWith('#')) { continue }
        if ($file.Name -ne 'common.ps1' -and $code -match '\bWrite-Host\b') {
            [void]$errors.Add("Write-Host tran (dung Write-Ascii): $($file.Name):$lineNo")
        }
        # Ma Python truyen bang -c (bien ten *Code*) khong duoc chua dau nhay KEP: PS 5.1 se lam mat no.
        if ($code -match '\$\w*Code\w*\s*=\s*''[^'']*"[^'']*''') {
            [void]$errors.Add("Ma Python -c chua dau nhay kep (PS 5.1 lam mat): $($file.Name):$lineNo")
        }
        $prints = ($code -match '\b(Write-Ascii|Write-Host|Write-Output)\b')
        if ($prints -and $code -notmatch 'Mask-Key' -and $code -match '\$[A-Za-z_.]*(Value|Token|Secret|Key)\b') {
            [void]$errors.Add("In bien giong khoa ma khong qua Mask-Key: $($file.Name):$lineNo")
        }
    }
}

if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Host $_ }; exit 1 }
Write-Host ("PASS lint: {0} files" -f $files.Count)
exit 0
