# 55-genmax-voices.ps1 - liet ke giong Genmax de hoc vien chon, va ghi GENMAX_VOICE_ID vao .env.
#   55-genmax-voices.ps1 -Search aria            : tim giong theo ten (mac dinh nha cung cap elevenlabs)
#   55-genmax-voices.ps1 -Provider minimax       : giong MiniMax
#   55-genmax-voices.ps1 -Set <voice_id>         : ghi GENMAX_VOICE_ID vao .env (khong goi mang)
# Doc khoa tu .env (khong in khoa). Chi goi GET danh sach giong (khong ton credit).
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [ValidateSet('elevenlabs', 'minimax', 'capcut')][string]$Provider = 'elevenlabs',
    [string]$Search = '',
    [string]$Set = ''
)
. (Join-Path $PSScriptRoot 'common.ps1')

$envFile = Join-Path $Root '.env'
Write-Ascii '== CHON GIONG GENMAX =='

if ($Set) {
    if ($Set -notmatch '^[A-Za-z0-9_\-]{6,80}$') {
        Write-Ascii 'E_KEY_FORMAT: ID giong khong hop le (chi gom chu, so, gach).'
        exit 1
    }
    if ($DryRun) { Write-Ascii '[DryRun] Se ghi GENMAX_VOICE_ID vao .env.'; exit 0 }
    Set-DotEnvValue $envFile 'GENMAX_VOICE_ID' $Set
    Write-SetupLog $Root 'VOICES: da doi GENMAX_VOICE_ID theo lua chon cua hoc vien'
    Write-Ascii 'Da ghi GENMAX_VOICE_ID vao .env. Chay lai 50-keys-sync.ps1 de cap nhat bien moi truong.'
    exit 0
}

$paths = @{
    elevenlabs = '/v1/default-voices?page_size=100'
    minimax    = '/v1/minimax/system-voices?page_size=100'
    capcut     = '/v1/capcut/system-voices?page_size=100'
}
$path = $paths[$Provider]
if ($Provider -eq 'elevenlabs' -and $Search) { $path += '&search=' + [uri]::EscapeDataString($Search) }
if ($DryRun) {
    Write-Ascii "[DryRun] Se goi danh sach giong ($Provider)."
    exit 0
}

$values = Read-DotEnv $envFile
$apiKey = ''
if ($values.Contains('GENMAX_API_KEY')) { $apiKey = [string]$values['GENMAX_API_KEY'] }
if (-not $apiKey) {
    Write-Ascii 'CHUA_DIEN: chua co GENMAX_API_KEY trong .env - hay dien khoa truoc (Phase KHOA).'
    exit 1
}
$reply = Invoke-ApiRequest ('https://api.genmax.io' + $path) @{ 'xi-api-key' = $apiKey }
$code = Get-ApiErrorCode $reply.Status $reply.Body
if ($code -ne 'OK') {
    Write-Ascii ("{0}: khong lay duoc danh sach giong (http={1})." -f $code, $reply.Status)
    exit 1
}
$voices = @(Get-VoiceRows $Provider $reply.Body)
if ($Search -and $Provider -ne 'elevenlabs') {
    $voices = @($voices | Where-Object { (Remove-Diacritics $_.Name).ToLower().Contains((Remove-Diacritics $Search).ToLower()) })
}
Write-Ascii ("Tim thay {0} giong. Hien toi da 30:" -f $voices.Count)
Write-Ascii 'ID | TEN | GIOI TINH | GHI CHU'
foreach ($v in ($voices | Select-Object -First 30)) {
    $note = $v.Note
    if ($note.Length -gt 60) { $note = $note.Substring(0, 60) }
    Write-Ascii ("{0} | {1} | {2} | {3}" -f $v.Id, $v.Name, $v.Gender, $note)
}
Write-Ascii 'Chon 1 giong roi chay: 55-genmax-voices.ps1 -Set <ID>'
exit 0
