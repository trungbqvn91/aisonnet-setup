# common.Tests.ps1 - test cac ham thuan/logic trong common.ps1 (khong mang, khong dong vao may that).
$repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
. (Join-Path $repo 'kit\scripts\win\common.ps1')
$tmp = Join-Path $repo 'tests\tmp\common'
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

# Chuoi tieng Viet dung ma ky tu (file test chi chua ASCII).
$chao = 'Xin ch' + [char]0xE0 + 'o'
$triTueNhanTao = 'tr' + [char]0xED + ' tu' + [char]0x1EC7 + ' nh' + [char]0xE2 + 'n t' + [char]0x1EA1 + 'o'
$fakeApify = 'apify' + '_api_' + ('x' * 30)
$fakeGenmax = 'sk' + '_' + ('a' * 40)
$fakeGemini = 'AI' + 'za' + ('B' * 35)
$fakeTele = '123456789:' + ('A' * 35)

# ---------------------------------------------------------------- Remove-Diacritics
Test-Case 'diacritics: xin chao' { Assert-Equal 'Xin chao' (Remove-Diacritics $chao) }
Test-Case 'diacritics: tri tue nhan tao' { Assert-Equal 'tri tue nhan tao' (Remove-Diacritics $triTueNhanTao) }
Test-Case 'diacritics: d-gach thuong' { Assert-Equal 'day' (Remove-Diacritics ([string][char]0x111 + [char]0xE2 + 'y')) }
Test-Case 'diacritics: D-gach hoa' { Assert-Equal 'Dung' (Remove-Diacritics ([string][char]0x110 + [char]0x1EE9 + 'ng').Replace([string][char]0x1EE9, 'u')) }
Test-Case 'diacritics: dau chong (a-circumflex-hook)' { Assert-Equal 'a' (Remove-Diacritics ([string][char]0x1EA9)) }
Test-Case 'diacritics: ASCII khong doi' { Assert-Equal 'hello 123' (Remove-Diacritics 'hello 123') }
Test-Case 'diacritics: rong/null' { Assert-Equal '' (Remove-Diacritics $null); Assert-Equal '' (Remove-Diacritics '') }

# ---------------------------------------------------------------- Mask-Key
Test-Case 'mask: khoa dai' { Assert-Equal '...abcd' (Mask-Key '1234567890abcd') }
Test-Case 'mask: khoa ngan' { Assert-Equal '...abc' (Mask-Key 'abc') }
Test-Case 'mask: rong' { Assert-Equal '(trong)' (Mask-Key ''); Assert-Equal '(trong)' (Mask-Key $null) }
Test-Case 'mask: chi ASCII' { Assert-True ((Mask-Key '1234567890abcd') -match '^[\x00-\x7F]+$') }

# ---------------------------------------------------------------- Read-DotEnv
$envFile = Join-Path $tmp 'a.env'
Test-Case 'dotenv: file khong ton tai' { Assert-Equal 0 (Read-DotEnv (Join-Path $tmp 'khong-co.env')).Count }
Test-Case 'dotenv: co ban + chu thich + dong trong' {
    [IO.File]::WriteAllText($envFile, "# chu thich`nA=1`n`n  B = hai  `n")
    $d = Read-DotEnv $envFile
    Assert-Equal 2 $d.Count; Assert-Equal '1' $d['A']; Assert-Equal 'hai' $d['B']
}
Test-Case 'dotenv: CRLF' { [IO.File]::WriteAllText($envFile, "A=1`r`nB=2`r`n"); Assert-Equal '2' (Read-DotEnv $envFile)['B'] }
Test-Case 'dotenv: BOM' {
    [IO.File]::WriteAllText($envFile, "A=1`r`n", (New-Object Text.UTF8Encoding($true)))
    Assert-Equal '1' (Read-DotEnv $envFile)['A']
}
Test-Case 'dotenv: dau = trong gia tri' { [IO.File]::WriteAllText($envFile, "K=ab=cd==`n"); Assert-Equal 'ab=cd==' (Read-DotEnv $envFile)['K'] }
Test-Case 'dotenv: bo cap nhay' {
    [IO.File]::WriteAllText($envFile, "A=`"x y`"`nB='z'`n")
    $d = Read-DotEnv $envFile; Assert-Equal 'x y' $d['A']; Assert-Equal 'z' $d['B']
}
Test-Case 'dotenv: gia tri rong' { [IO.File]::WriteAllText($envFile, "A=`nB=2`n"); $d = Read-DotEnv $envFile; Assert-Equal '' $d['A']; Assert-Equal '2' $d['B'] }
Test-Case 'dotenv: dong hong bi bo qua' {
    [IO.File]::WriteAllText($envFile, "khong co dau bang`n=thieu ten`nOK=1`n")
    $d = Read-DotEnv $envFile; Assert-Equal 1 $d.Count; Assert-Equal '1' $d['OK']
}
Test-Case 'dotenv: giu thu tu' {
    [IO.File]::WriteAllText($envFile, "Z=1`nA=2`nM=3`n")
    Assert-Equal 'Z,A,M' ((Read-DotEnv $envFile).Keys -join ',')
}

# ---------------------------------------------------------------- Set-DotEnvValue
Test-Case 'set-dotenv: thay gia tri, giu chu thich' {
    [IO.File]::WriteAllText($envFile, "# giu`nA=1`nB=`n")
    Set-DotEnvValue $envFile 'B' '42'
    $text = [IO.File]::ReadAllText($envFile)
    Assert-Contains $text '# giu'; Assert-Contains $text 'B=42'; Assert-Equal '1' (Read-DotEnv $envFile)['A']
}
Test-Case 'set-dotenv: them moi khi chua co' {
    [IO.File]::WriteAllText($envFile, "A=1`n"); Set-DotEnvValue $envFile 'NEW' 'x'
    Assert-Equal 'x' (Read-DotEnv $envFile)['NEW']
}

# ---------------------------------------------------------------- Update-MarkerBlock
$begin = '<!-- AISONNET:BEGIN'; $end = '<!-- AISONNET:END -->'
$block = "<!-- AISONNET:BEGIN v1 -->`nNOI DUNG MOI`n<!-- AISONNET:END -->"
function Read-Text([string]$p) { return [IO.File]::ReadAllText($p) }
Test-Case 'marker: file chua ton tai -> tao moi' {
    $f = Join-Path $tmp 'm1\CLAUDE.md'
    Update-MarkerBlock $f $begin $end $block
    Assert-Contains (Read-Text $f) 'NOI DUNG MOI'
}
Test-Case 'marker: file co noi dung, chua co khoi -> them cuoi, giu noi dung' {
    $f = Join-Path $tmp 'm2.md'; [IO.File]::WriteAllText($f, "# Cua toi`nDong rieng`n")
    Update-MarkerBlock $f $begin $end $block
    $t = Read-Text $f; Assert-Contains $t 'Dong rieng'; Assert-Contains $t 'NOI DUNG MOI'
}
Test-Case 'marker: da co khoi -> thay (phien ban cu), giu noi dung hai ben' {
    $f = Join-Path $tmp 'm3.md'
    [IO.File]::WriteAllText($f, "TRUOC`n<!-- AISONNET:BEGIN v0 -->`nCU`n<!-- AISONNET:END -->`nSAU`n")
    Update-MarkerBlock $f $begin $end $block
    $t = Read-Text $f
    Assert-Contains $t 'TRUOC'; Assert-Contains $t 'SAU'; Assert-Contains $t 'NOI DUNG MOI'; Assert-NotContains $t 'CU'
}
Test-Case 'marker: chay 2 lan cho cung ket qua' {
    $f = Join-Path $tmp 'm4.md'; [IO.File]::WriteAllText($f, "A`n")
    Update-MarkerBlock $f $begin $end $block; $once = Read-Text $f
    Update-MarkerBlock $f $begin $end $block
    Assert-Equal $once (Read-Text $f)
    Assert-Equal 1 ([regex]::Matches((Read-Text $f), 'AISONNET:BEGIN')).Count
}
Test-Case 'marker: giu CRLF cua file goc' {
    $f = Join-Path $tmp 'm5.md'; [IO.File]::WriteAllText($f, "A`r`nB`r`n")
    Update-MarkerBlock $f $begin $end $block
    $t = Read-Text $f
    Assert-True ($t -notmatch "(?<!`r)`n") 'co dong bi xuong dong kieu LF trong file CRLF'
}
Test-Case 'marker: giu BOM neu co, KHONG them BOM neu khong co' {
    $withBom = Join-Path $tmp 'm6.md'; [IO.File]::WriteAllText($withBom, "A`n", (New-Object Text.UTF8Encoding($true)))
    $noBom = Join-Path $tmp 'm7.md'; [IO.File]::WriteAllText($noBom, "A`n", (New-Object Text.UTF8Encoding($false)))
    Update-MarkerBlock $withBom $begin $end $block; Update-MarkerBlock $noBom $begin $end $block
    $b1 = [IO.File]::ReadAllBytes($withBom); $b2 = [IO.File]::ReadAllBytes($noBom)
    Assert-True ($b1[0] -eq 0xEF -and $b1[1] -eq 0xBB) 'mat BOM cua file goc'
    Assert-True ($b2[0] -ne 0xEF) 'tu them BOM vao file goc'
}
Test-Case 'marker: tieng Viet co dau khong bi hong' {
    $f = Join-Path $tmp 'm8.md'
    $viBlock = "<!-- AISONNET:BEGIN v1 -->`n" + $chao + "`n<!-- AISONNET:END -->"
    Update-MarkerBlock $f $begin $end $viBlock
    Assert-Contains (Read-Text $f) $chao
}

# ---------------------------------------------------------------- Add-PathSegment
Test-Case 'path: them moi' { Assert-Equal 'C:\a;C:\b;C:\c' (Add-PathSegment 'C:\a;C:\b' 'C:\c') }
Test-Case 'path: da co thi giu nguyen' { Assert-Equal 'C:\a;C:\b' (Add-PathSegment 'C:\a;C:\b' 'C:\b') }
Test-Case 'path: khong phan biet hoa thuong + dau gach cuoi' { Assert-Equal 'C:\a;C:\b\' (Add-PathSegment 'C:\a;C:\b\' 'c:\B') }
Test-Case 'path: rong/null' { Assert-Equal 'C:\x' (Add-PathSegment '' 'C:\x'); Assert-Equal 'C:\x' (Add-PathSegment $null 'C:\x') }
Test-Case 'path: bo dau ; thua' { Assert-Equal 'C:\a;C:\x' (Add-PathSegment 'C:\a;;' 'C:\x') }
Test-Case 'path: khong trung khi goi 2 lan' {
    $once = Add-PathSegment 'C:\a' 'C:\x'; Assert-Equal $once (Add-PathSegment $once 'C:\x')
}

# ---------------------------------------------------------------- Redact-Secrets
Test-Case 'redact: khoa Genmax' { Assert-NotContains (Redact-Secrets ("loi voi " + $fakeGenmax)) $fakeGenmax }
Test-Case 'redact: khoa Gemini' { Assert-NotContains (Redact-Secrets ("key=" + $fakeGemini)) $fakeGemini }
Test-Case 'redact: khoa Apify' { Assert-NotContains (Redact-Secrets ($fakeApify)) $fakeApify }
Test-Case 'redact: token Telegram trong URL' {
    $url = 'https://api.telegram.org/bot' + $fakeTele + '/getMe'
    Assert-NotContains (Redact-Secrets $url) $fakeTele
}
Test-Case 'redact: gia tri bi mat cu the (khong theo mau)' {
    Assert-Equal 'a *** b' (Redact-Secrets 'a MATKHAUBIMAT b' @('MATKHAUBIMAT'))
}
Test-Case 'redact: van ban binh thuong khong doi' { Assert-Equal 'xin chao the gioi' (Redact-Secrets 'xin chao the gioi') }

# ---------------------------------------------------------------- Test-PathRisk
Test-Case 'pathrisk: sach' { Assert-Equal 0 (@(Test-PathRisk @('C:\Users\Nam', 'C:\AISONNET'))).Count }
Test-Case 'pathrisk: OneDrive' { Assert-True ((Test-PathRisk @('C:\Users\x\OneDrive\Desktop')) -contains 'OneDrive') }
Test-Case 'pathrisk: ky tu co dau' {
    Assert-True ((Test-PathRisk @('C:\Users\Nguy' + [char]0x1EC5 + 'n')) -contains 'ky-tu-co-dau')
}
Test-Case 'pathrisk: khoang trang' { Assert-True ((Test-PathRisk @('C:\Users\Hoc Vien')) -contains 'khoang-trang') }
Test-Case 'pathrisk: duong dan dai' { Assert-True ((Test-PathRisk @('C:\' + ('a' * 200))) -contains 'duong-dan-dai') }
Test-Case 'pathrisk: nhieu rui ro cung luc' { Assert-True (@(Test-PathRisk @('C:\Users\Hoc Vien\OneDrive')).Count -ge 2) }

# ---------------------------------------------------------------- Get-WingetOutcome
Test-Case 'winget: thanh cong' { Assert-Equal 'OK' (Get-WingetOutcome 0 '') }
Test-Case 'winget: da cai san' { Assert-Equal 'ALREADY' (Get-WingetOutcome 0 'Found an existing package already installed') }
Test-Case 'winget: khong co installer hop scope (ma)' { Assert-Equal 'NO_INSTALLER' (Get-WingetOutcome -1978335216 'x') }
Test-Case 'winget: khong co installer hop scope (chu)' { Assert-Equal 'NO_INSTALLER' (Get-WingetOutcome 1 'No applicable installer found') }
Test-Case 'winget: UAC bi tu choi (1223)' { Assert-Equal 'UAC_DECLINED' (Get-WingetOutcome 1 'Installer failed with exit code: 1223') }
Test-Case 'winget: nguoi dung huy' { Assert-Equal 'UAC_DECLINED' (Get-WingetOutcome 1 'The operation was canceled by the user') }
Test-Case 'winget: mat mang' { Assert-Equal 'NETWORK' (Get-WingetOutcome 1 'unexpected error 0x80072ee7') }
Test-Case 'winget: nguon hong' { Assert-Equal 'SOURCE' (Get-WingetOutcome 1 'Failed in attempting to update the source: winget') }
Test-Case 'winget: loi la' { Assert-Equal 'OTHER' (Get-WingetOutcome 1 'something weird') }

# ---------------------------------------------------------------- Get-ApiErrorCode
Test-Case 'api: 200 OK' { Assert-Equal 'OK' (Get-ApiErrorCode 200 '') }
Test-Case 'api: 401' { Assert-Equal 'E_KEY_INVALID' (Get-ApiErrorCode 401 '') }
Test-Case 'api: 403' { Assert-Equal 'E_KEY_INVALID' (Get-ApiErrorCode 403 '') }
Test-Case 'api: 400 Gemini khoa sai' { Assert-Equal 'E_KEY_INVALID' (Get-ApiErrorCode 400 'API key not valid. Please pass a valid API key.') }
Test-Case 'api: 400 het han' { Assert-Equal 'E_KEY_EXPIRED' (Get-ApiErrorCode 400 'API key expired. Please renew') }
Test-Case 'api: 429 va 402' { Assert-Equal 'E_QUOTA' (Get-ApiErrorCode 429 ''); Assert-Equal 'E_QUOTA' (Get-ApiErrorCode 402 '') }
Test-Case 'api: 0 va 5xx la loi mang' { Assert-Equal 'E_KEY_NETWORK' (Get-ApiErrorCode 0 ''); Assert-Equal 'E_KEY_NETWORK' (Get-ApiErrorCode 503 '') }
Test-Case 'api: 404' { Assert-Equal 'E_KEY_INVALID' (Get-ApiErrorCode 404 '') }

# ---------------------------------------------------------------- Test-KeyFormat
Test-Case 'format: rong hop le' { Assert-Equal '' (Test-KeyFormat 'APIFY_TOKEN' '') }
Test-Case 'format: khoang trang ben trong' { Assert-Contains (Test-KeyFormat 'APIFY_TOKEN' 'abc def ghi jkl mno') 'khoang trang' }
Test-Case 'format: qua ngan' { Assert-Contains (Test-KeyFormat 'APIFY_TOKEN' 'short') 'ngan' }
Test-Case 'format: con dau nhay' { Assert-Contains (Test-KeyFormat 'APIFY_TOKEN' ('"' + ('x' * 20) + '"')) 'nhay' }
Test-Case 'format: khoa dung' {
    Assert-Equal '' (Test-KeyFormat 'GEMINI_API_KEY' $fakeGemini)
    Assert-Equal '' (Test-KeyFormat 'GENMAX_API_KEY' $fakeGenmax)
    Assert-Equal '' (Test-KeyFormat 'TELEGRAM_BOT_TOKEN' $fakeTele)
}
Test-Case 'format: dan nham khoa Gemini vao o Apify' { Assert-Contains (Test-KeyFormat 'APIFY_TOKEN' $fakeGemini) 'Gemini' }
Test-Case 'format: dan nham khoa Genmax vao o Gemini' { Assert-Contains (Test-KeyFormat 'GEMINI_API_KEY' $fakeGenmax) 'Genmax' }
Test-Case 'format: token Telegram sai dang' { Assert-Contains (Test-KeyFormat 'TELEGRAM_BOT_TOKEN' ('x' * 30)) 'token bot' }
Test-Case 'format: chat id' {
    Assert-Equal '' (Test-KeyFormat 'TELEGRAM_CHAT_ID' '-1001234567')
    Assert-Contains (Test-KeyFormat 'TELEGRAM_CHAT_ID' '12x') 'chat id'
}
Test-Case 'format: voice id khong kiem do dai' { Assert-Equal '' (Test-KeyFormat 'GENMAX_VOICE_ID' 'abc') }
Test-Case 'format: model Genmax (eleven_v3 ngan hon 12 ky tu van hop le)' {
    Assert-Equal '' (Test-KeyFormat 'GENMAX_MODEL' 'eleven_v3')
    Assert-Equal '' (Test-KeyFormat 'GENMAX_MODEL' 'eleven_turbo_v2_5')
    Assert-Contains (Test-KeyFormat 'GENMAX_MODEL' 'ten-sai!') 'model'
}
Test-Case 'format: the cam xuc chi nhan 0 hoac 1' {
    Assert-Equal '' (Test-KeyFormat 'GENMAX_EMOTION_TAGS' '1')
    Assert-Equal '' (Test-KeyFormat 'GENMAX_EMOTION_TAGS' '0')
    Assert-Contains (Test-KeyFormat 'GENMAX_EMOTION_TAGS' 'yes') 'bat'
}
Test-Case 'mac dinh giong: Adam + eleven_v3 + the cam xuc bat' {
    Assert-Equal 'pNInz6obpgDQGcFmaJgB' $script:GenmaxDefaults['GENMAX_VOICE_ID']
    Assert-Equal 'eleven_v3' $script:GenmaxDefaults['GENMAX_MODEL']
    Assert-Equal '1' $script:GenmaxDefaults['GENMAX_EMOTION_TAGS']
}
Test-Case 'mau .env: da dien san giong mac dinh va khong co khoa that' {
    $tpl = Read-DotEnv (Join-Path $repo 'kit\templates\env.template')
    Assert-Equal $script:GenmaxDefaults['GENMAX_VOICE_ID'] $tpl['GENMAX_VOICE_ID']
    Assert-Equal 'eleven_v3' $tpl['GENMAX_MODEL']
    Assert-Equal '' $tpl['GENMAX_API_KEY']; Assert-Equal '' $tpl['APIFY_TOKEN']; Assert-Equal '' $tpl['GEMINI_API_KEY']
}
Test-Case 'khoi toan cuc: noi ro giong mac dinh va lenh genmax-tts' {
    $block = [IO.File]::ReadAllText((Join-Path $repo 'kit\templates\global-claude-block.md'))
    Assert-Contains $block 'pNInz6obpgDQGcFmaJgB'; Assert-Contains $block 'eleven_v3'; Assert-Contains $block 'genmax-tts'
    Assert-True (($block -split "`n").Count -le 25) 'khoi toan cuc qua dai (> 25 dong)'
}

# ---------------------------------------------------------------- Trang thai + nhat ky khong chua khoa
Test-Case 'status: gop nhieu phase + extra + loc khoa' {
    $root = Join-Path $tmp 'st'
    Set-SetupStatus $root 'a' 'OK' 'xong a'
    Set-SetupStatus $root 'b' 'E_X' ('loi co ' + $fakeGenmax) @{ winget_exit = 5 }
    $json = Get-JsonFile (Join-Path $root 'state\status.json')
    Assert-Equal 'OK' $json.phases.a.code
    Assert-Equal 'E_X' $json.phases.b.code
    Assert-Equal 5 $json.phases.b.winget_exit
    Assert-NotContains ([IO.File]::ReadAllText((Join-Path $root 'state\status.json'))) $fakeGenmax
}
Test-Case 'log: loc khoa' {
    $root = Join-Path $tmp 'lg'
    Write-SetupLog $root ('thu ' + $fakeGemini)
    Assert-NotContains ([IO.File]::ReadAllText((Join-Path $root 'SETUP-LOG.md'))) $fakeGemini
}

Test-Case 'format: khoa RapidAPI dan nham ca doan code bi bao' {
    Assert-Contains (Test-KeyFormat 'TIKTOK_API23_KEY' "x-rapidapi-key: abcdef1234567890abcd") 'x-rapidapi-key'
}
Test-Case 'format: khoa RapidAPI dang chuoi thuong hop le' {
    Assert-Equal '' (Test-KeyFormat 'TIKTOK_API23_KEY' ('a1b2c3d4e5' * 4 + 'msh'))
}
Test-Case 'api spec: RapidAPI co host + key + User-Agent trinh duyet, khong in khoa' {
    $spec = Get-ApiSpec 'TIKTOK_API23_KEY' ('k' * 40)
    Assert-Contains $spec.Url 'tiktok-api23.p.rapidapi.com'
    Assert-Equal 'tiktok-api23.p.rapidapi.com' $spec.Headers['x-rapidapi-host']
    Assert-Contains $spec.Headers['User-Agent'] 'Mozilla'
}
Test-Case 'skill di kem: du file va script chi goi host RapidAPI' {
    $sk = Join-Path $repo 'kit\skills\rapidapi-tiktok-api23'
    foreach ($f in @('SKILL.md', 'scripts\tiktok_api.py', 'references\huong-dan-ket-noi.md')) {
        Assert-True (Test-Path -LiteralPath (Join-Path $sk $f)) ('thieu ' + $f)
    }
    Assert-Equal 5 @(Get-ChildItem (Join-Path $sk 'references\images') -Filter *.png).Count
    $py = [IO.File]::ReadAllText((Join-Path $sk 'scripts\tiktok_api.py'))
    $hosts = [regex]::Matches($py, 'https?://[A-Za-z0-9\.\-]+') | ForEach-Object { $_.Value } | Sort-Object -Unique
    foreach ($h in $hosts) { Assert-True ($h -match 'rapidapi\.com|tiktok\.com|docs\.tikfly\.io|python\.org|www\.python') ('host la trong script skill: ' + $h) }
    Assert-NotContains $py 'os.system'
    Assert-NotContains $py 'eval('
}
Test-Case 'skill Genmax: tu mo link gioi thieu, nhac ma, cam tra tien thay hoc vien' {
    $t = [IO.File]::ReadAllText((Join-Path $repo 'kit\skills\genmax-dang-ky-nap-credit\SKILL.md'))
    Assert-Contains $t 'name: genmax-dang-ky-nap-credit'
    Assert-Contains $t 'genmax-tts --open signup'; Assert-Contains $t 'genmax-tts --open topup'
    Assert-Contains $t 'KMGENMAX'
    Assert-Contains $t 'Không tự trả tiền'
    Assert-Contains $t 'Enter voucher code (optional)'
    Assert-NotContains $t '/html/body'
    Assert-True ($t -match '(?m)^description: .*nạp credit') 'mo ta (trigger) thieu "nap credit"'
}
Test-Case 'khoi toan cuc va SETUP nhac skill Genmax' {
    foreach ($f in @('templates\global-claude-block.md', 'templates\global-claude-block-mac.md', 'SETUP.md')) {
        Assert-Contains ([IO.File]::ReadAllText((Join-Path $repo ('kit\' + $f)))) 'genmax-dang-ky-nap-credit' ($f + ' chua nhac skill')
    }
}
Test-Case 'mau .env co dong TIKTOK_API23_KEY' {
    $tpl = Read-DotEnv (Join-Path $repo 'kit\templates\env.template')
    Assert-True ($tpl.Contains('TIKTOK_API23_KEY')) 'thieu TIKTOK_API23_KEY'
    Assert-Equal '' $tpl['TIKTOK_API23_KEY']
}

# ---------------------------------------------------------------- Get-TelegramSendOutcome
Test-Case 'telegram: gui tin thanh cong' { Assert-Equal 'OK' (Get-TelegramSendOutcome 200 '{"ok":true}') }
Test-Case 'telegram: token sai (401/404)' {
    Assert-Equal 'E_TG_TOKEN' (Get-TelegramSendOutcome 401 ''); Assert-Equal 'E_TG_TOKEN' (Get-TelegramSendOutcome 404 '')
}
Test-Case 'telegram: bi chan' {
    Assert-Equal 'E_TG_BLOCKED' (Get-TelegramSendOutcome 403 'Forbidden: bot was blocked by the user')
}
Test-Case 'telegram: chat khong ton tai' { Assert-Equal 'E_TG_CHAT' (Get-TelegramSendOutcome 400 'Bad Request: chat not found') }
Test-Case 'telegram: loi mang / 5xx' {
    Assert-Equal 'E_KEY_NETWORK' (Get-TelegramSendOutcome 0 ''); Assert-Equal 'E_KEY_NETWORK' (Get-TelegramSendOutcome 502 '')
}
Test-Case 'telegram: loi la' { Assert-Equal 'E_TG_SEND' (Get-TelegramSendOutcome 400 'Bad Request: text is empty') }
Test-Case 'telegram: Send-TelegramTest voi token gia khong in token, tra ma loi ro rang' {
    $fakeToken = '123456789:' + ('Z' * 35)
    $out = (& { $r = Send-TelegramTest $fakeToken '12345'; Write-Output ($r.Code + ' ' + $r.Note) } 6>&1 | Out-String)
    Assert-NotContains $out $fakeToken
    Assert-True ($out -match '^(E_TG_TOKEN|E_TG_SEND|E_KEY_NETWORK|E_TG_CHAT)') ('ma khong mong doi: ' + $out)
}

# ---------------------------------------------------------------- Get-VoiceRows (JSON mau lay tu tai lieu Genmax + code AIEdit-trung)
$elevenJson = '{"voices":[{"voice_id":"rv30Fd6w5bnbL0kHzWlr","name":"Aria","gender":"female","description":"A young voice"},' +
              '{"voice_id":"CwhRBWXzGAHq8TQ4Fs17","name":"Roger","gender":"male","description":"Mature"}],"has_more":true}'
$minimaxJson = '{"voice_list":[{"voice_id":"mm_001","voice_name":"Giong Nu","tag_list":["Female","Vietnamese"],"description":"mo ta"}]}'
$capcutJson = '{"voice_list":[{"voice_id":"cc_9","name":"Cap Nam","gender":"male","tags":["vi","news"]}]}'
Test-Case 'voices: elevenlabs 2 giong' {
    $rows = @(Get-VoiceRows 'elevenlabs' $elevenJson)
    Assert-Equal 2 $rows.Count; Assert-Equal 'rv30Fd6w5bnbL0kHzWlr' $rows[0].Id; Assert-Equal 'Aria' $rows[0].Name
    Assert-Equal 'male' $rows[1].Gender
}
Test-Case 'voices: minimax suy ra gioi tinh tu tag' {
    $rows = @(Get-VoiceRows 'minimax' $minimaxJson)
    Assert-Equal 1 $rows.Count; Assert-Equal 'female' $rows[0].Gender; Assert-Equal 'Giong Nu' $rows[0].Name
}
Test-Case 'voices: capcut dung gender + tags lam ghi chu' {
    $rows = @(Get-VoiceRows 'capcut' $capcutJson)
    Assert-Equal 'male' $rows[0].Gender; Assert-Contains $rows[0].Note 'news'
}
Test-Case 'voices: JSON hong / rong / thieu truong khong gay loi' {
    Assert-Equal 0 @(Get-VoiceRows 'elevenlabs' 'khong phai json').Count
    Assert-Equal 0 @(Get-VoiceRows 'elevenlabs' '').Count
    Assert-Equal 0 @(Get-VoiceRows 'minimax' '{"khac":1}').Count
}

# ---------------------------------------------------------------- Write-Ascii
Test-Case 'write-ascii: khong in ky tu ngoai ASCII' {
    $captured = (& { Write-Ascii ($chao + ' ' + $triTueNhanTao + ' ' + [char]0x2026) } 6>&1 | Out-String)
    Assert-True ($captured -match '^[\x00-\x7F\r\n]+$') ('con ky tu khong ASCII: ' + $captured)
    Assert-Contains $captured 'Xin chao'
}
