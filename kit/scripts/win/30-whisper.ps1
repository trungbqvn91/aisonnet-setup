# 30-whisper.ps1 - Phase 3b: tai model Whisper nhe va thu boc loi tieng Viet tren file mau.
# Python tu bo dau + in ASCII (chu co dau di qua pipe de hong), PowerShell chi doc dong HITS=.
param(
    [switch]$DryRun,
    [string]$Root = 'C:\AISONNET',
    [ValidateSet('base', 'small')][string]$Model = 'base',
    [int]$MinHits = 2,
    [string]$PythonExe = ''
)
. (Join-Path $PSScriptRoot 'common.ps1')

$sample = Join-Path $script:KitRoot 'assets\sample-vi.wav'
$expect = Join-Path $script:KitRoot 'assets\sample-vi.expect.txt'

# Doan Python chay that. Ghi ra file tam UTF-8 roi chay (tranh loi dau nhay khi dung -c).
$pythonSource = @'
import sys, time, unicodedata

def plain(text):
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    return text.replace('\u0111', 'd').replace('\u0110', 'D').lower()

model_name, wav_path, expect_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    from faster_whisper import WhisperModel
    t0 = time.time()
    model = WhisperModel(model_name, device='cpu', compute_type='int8')
    print('TIME_LOAD=%.1f' % (time.time() - t0))
except Exception as exc:
    print('ERR_LOAD=' + type(exc).__name__ + ': ' + ascii(str(exc))[:200])
    sys.exit(3)
try:
    t1 = time.time()
    segments, info = model.transcribe(wav_path, language='vi')
    text = ' '.join(s.text.strip() for s in segments)
    print('TIME_RUN=%.1f' % (time.time() - t1))
except Exception as exc:
    print('ERR_RUN=' + type(exc).__name__ + ': ' + ascii(str(exc))[:200])
    sys.exit(4)
ascii_text = plain(text)
words = open(expect_path, encoding='utf-8-sig').read().splitlines()
keywords = [w.strip() for w in words if w.strip()]
hits = sum(1 for k in keywords if k in ascii_text)
print('HITS=%d/%d' % (hits, len(keywords)))
print('TEXT=' + ascii_text.encode('ascii', 'replace').decode('ascii'))
'@

Write-Ascii ("== THU WHISPER (model {0}) ==" -f $Model)
if ($DryRun) {
    Write-Ascii "[DryRun] Se tai model Whisper '$Model' va boc thu file mau."
    exit 0
}

$code = 'OK'
$detail = ''
if (-not (Test-Path -LiteralPath $sample) -or -not (Test-Path -LiteralPath $expect)) {
    $code = 'E_WHISPER_SAMPLE'
    $detail = 'thieu assets\sample-vi.wav hoac sample-vi.expect.txt trong bo cai'
} else {
    $python = Get-PythonInvocation $PythonExe
    $tmp = Join-Path $env:TEMP ('aisonnet-whisper-' + [guid]::NewGuid().ToString('N') + '.py')
    [IO.File]::WriteAllText($tmp, $pythonSource, (New-Object System.Text.UTF8Encoding($false)))
    Write-Ascii 'Dang tai/nap model (lan dau co the mat 1-3 phut, dung dong cua so) ...'
    try {
        $run = Invoke-Python $python @($tmp, $Model, $sample, $expect)
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    $out = $run.Output
    if ($run.ExitCode -eq 3) {
        $code = 'E_WHISPER_DOWNLOAD'
        $detail = Get-LastLines $out 2
    } elseif ($run.ExitCode -ne 0) {
        $code = 'E_WHISPER_RUN'
        $detail = Get-LastLines $out 2
    } else {
        $hits = 0
        if ($out -match 'HITS=(\d+)/(\d+)') { $hits = [int]$Matches[1] }
        $load = ''
        $time = ''
        if ($out -match 'TIME_LOAD=([\d\.]+)') { $load = $Matches[1] }
        if ($out -match 'TIME_RUN=([\d\.]+)') { $time = $Matches[1] }
        Write-Ascii ("Nap model {0}s, boc mau {1}s, trung {2} tu khoa (can >= {3})." -f $load, $time, $hits, $MinHits)
        if ($out -match 'TEXT=(.*)') { Write-Ascii ('Ket qua (khong dau): ' + $Matches[1].Trim()) }
        if ($hits -lt $MinHits) {
            $code = 'E_WHISPER_RUN'
            $detail = 'boc duoc nhung trung it tu khoa hon yeu cau'
        }
        $detail = ("model=$Model load=${load}s run=${time}s hits=$hits " + $detail).Trim()
    }
}

Set-SetupStatus $Root 'whisper' $code $detail
Write-SetupLog $Root ("WHISPER: {0} {1}" -f $code, $detail)
if ($code -ne 'OK') {
    Write-Ascii ("{0}: {1}" -f $code, $detail)
    exit 1
}
Write-Ascii 'WHISPER: OK'
exit 0
