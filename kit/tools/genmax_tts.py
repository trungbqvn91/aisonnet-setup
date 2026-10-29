#!/usr/bin/env python3
"""genmax_tts.py - doc van ban thanh giong noi bang Genmax (ElevenLabs).

Mac dinh cua khoa hoc: giong Adam, model ElevenLabs v3, TU DONG them the cam xuc (vd [excited])
bang Genmax /v1/enhance. Hoc vien chi can doi khi muon (bien moi truong hoac tham so).

Cach dung (khoa API doc tu bien moi truong GENMAX_API_KEY, KHONG bao gio in ra):
    py -3.12 genmax_tts.py --text "Xin chao cac ban" --out loi-chao.mp3
    py -3.12 genmax_tts.py --text-file kich-ban.txt --out kich-ban.mp3 --no-tags
    py -3.12 genmax_tts.py --list-models        # xem ID model (tim ban v3)
    py -3.12 genmax_tts.py --text "..." --dry-run   # chi in se gui gi, khong goi mang

Bien moi truong (dat boi bo cai, doi trong C:\\AISONNET\\.env roi chay lai 50-keys-sync.ps1):
    GENMAX_API_KEY (bat buoc)   GENMAX_VOICE_ID (mac dinh Adam)
    GENMAX_MODEL (mac dinh eleven_v3)   GENMAX_EMOTION_TAGS (1 = bat, 0 = tat; mac dinh 1)

Chi dung thu vien chuan (khong can pip). Moi dong in ra la ASCII (de qua pipe khong hong dau).
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser

DEFAULT_VOICE = 'pNInz6obpgDQGcFmaJgB'  # Adam - Dominant, Firm (da xac nhan that voi Genmax)
DEFAULT_MODEL = 'eleven_v3'
# Model da chay that voi tieng Viet (AIEdit-trung, 24/09/2026); dung khi v3 bi tu choi.
FALLBACK_MODEL = 'eleven_turbo_v2_5'
DEFAULT_LANGUAGE = 'vi'
# Dang ky / nap credit: LUON mo link gioi thieu va nhac ma khuyen mai (hoc vien khong phai copy gi).
REFERRAL_URL = 'https://genmax.io/?ref=mzkkz9'
SITE_URL = 'https://genmax.io/app/pricing'  # trang Bang gia (can dang nhap): bam Mua ngay -> o ma khuyen mai
PROMO_CODE = 'KMGENMAX'
LOW_CREDIT_THRESHOLD = 5000  # nguong "sap het" (uoc luong, don vi credit cua Genmax)
POLL_TIMEOUT_SECONDS = 180
POLL_INTERVAL_SECONDS = 2
# The cam xuc dang [excited], [short pause], [whispers] ...
TAG_PATTERN = re.compile(r"\[[A-Za-z][A-Za-z ,'-]{1,40}\]")


class ApiError(Exception):
    """Loi tu Genmax (status 0 = khong ket noi duoc)."""

    def __init__(self, status, message):
        Exception.__init__(self, message)
        self.status = status
        self.message = message


def log(message):
    """In 1 dong, chi ASCII."""
    print(str(message).encode('ascii', 'replace').decode('ascii'))
    sys.stdout.flush()


def base_url():
    # GENMAX_BASE_URL chi de test voi may chu gia TREN MAY NAY (127.0.0.1/localhost). Dia chi khac bi BO QUA,
    # de khong ai doi duoc dich gui khoa API sang may chu la.
    override = os.environ.get('GENMAX_BASE_URL', '')
    if override and urllib.parse.urlparse(override).hostname in ('127.0.0.1', 'localhost'):
        return override.rstrip('/')
    return 'https://api.genmax.io'


def strip_tags(text):
    """Bo the cam xuc cu (de chen lai tu dau, khong chong [excited] [excited])."""
    return re.sub(r'[ \t]{2,}', ' ', TAG_PATTERN.sub('', text)).strip()


def tags_enabled(env):
    """GENMAX_EMOTION_TAGS: thieu hoac rong = bat; 0/false/no/off = tat."""
    value = (env.get('GENMAX_EMOTION_TAGS') or '1').strip().lower()
    return value not in ('0', 'false', 'no', 'off')


def load_env_file(path):
    """Doc .env don gian (TEN=gia_tri). Tra dict; thieu file thi rong."""
    values = {}
    if not path or not os.path.isfile(path):
        return values
    with open(path, encoding='utf-8-sig') as handle:
        for line in handle.read().splitlines():
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            name, _, value = line.partition('=')
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in '"\'':
                value = value[1:-1].strip()
            values[name.strip()] = value
    return values


def get_settings():
    """Gop cau hinh: bien moi truong thang nhat; neu thieu thi doc C:\\AISONNET\\.env (hoac ~/AISONNET/.env)."""
    env = dict(os.environ)
    env_file = os.environ.get('AISONNET_ENV_FILE')
    if not env_file:
        candidates = [r'C:\AISONNET\.env', os.path.join(os.path.expanduser('~'), 'AISONNET', '.env')]
        env_file = next((c for c in candidates if os.path.isfile(c)), '')
    for name, value in load_env_file(env_file).items():
        if not env.get(name):
            env[name] = value
    return env


def short_message(raw):
    """Rut gon thong bao loi cua Genmax (khong bao gio chua khoa)."""
    text = raw.decode('utf-8', 'replace') if isinstance(raw, bytes) else str(raw)
    try:
        data = json.loads(text)
        for field in ('message', 'error', 'detail'):
            if isinstance(data, dict) and data.get(field):
                return str(data[field])[:160]
    except ValueError:
        pass
    return text.strip().replace('\n', ' ')[:160]


def call(method, path, key, body=None, timeout=60):
    """Goi API Genmax, tra JSON. Nem ApiError neu loi."""
    data = json.dumps(body).encode('utf-8') if body is not None else None
    request = urllib.request.Request(base_url() + path, data=data, method=method)
    request.add_header('xi-api-key', key)
    if data is not None:
        request.add_header('Content-Type', 'application/json')
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read()
    except urllib.error.HTTPError as error:
        raise ApiError(error.code, short_message(error.read()))
    except (urllib.error.URLError, OSError) as error:
        reason = getattr(error, 'reason', error)
        raise ApiError(0, 'khong ket noi duoc: ' + type(reason).__name__)
    return json.loads(raw.decode('utf-8')) if raw else {}


def add_emotion_tags(text, key):
    """Nho Genmax tu chen the cam xuc. Loi thi dung van ban goc (khong lam hong ca luot)."""
    try:
        result = call('POST', '/v1/enhance', key, {'text': strip_tags(text)}, timeout=100)
    except ApiError as error:
        log('Canh bao: khong them duoc the cam xuc (%s) - dung van ban goc.' % error.message)
        return text
    enhanced = result.get('text') if isinstance(result, dict) else None
    if not isinstance(enhanced, str) or not enhanced.strip():
        log('Canh bao: Genmax khong tra van ban co the cam xuc - dung van ban goc.')
        return text
    return enhanced


def submit(text, key, voice, model, language):
    """Gui yeu cau doc; tra id tac vu."""
    body = {'text': text, 'provider': 'elevenlabs', 'model_id': model, 'language_code': language}
    result = call('POST', '/v1/text-to-speech/' + urllib.parse.quote(voice, safe=''), key, body)
    task_id = result.get('id') if isinstance(result, dict) else None
    if not task_id:
        raise ApiError(0, 'Genmax khong tra ve ma tac vu')
    return task_id


def wait_for_audio(task_id, key):
    """Cho tac vu xong, tra audio_url."""
    started = time.time()
    while time.time() - started < POLL_TIMEOUT_SECONDS:
        status = call('GET', '/v1/history/' + urllib.parse.quote(task_id, safe=''), key)
        state = status.get('status') if isinstance(status, dict) else None
        if state == 'completed':
            result = status.get('result') or {}
            audio_url = result.get('audio_url')
            if audio_url:
                return audio_url
            raise ApiError(0, 'tac vu xong nhung khong co audio_url')
        if state == 'failed':
            raise ApiError(0, 'Genmax bao that bai: %s' % (status.get('error') or 'khong ro ly do'))
        time.sleep(POLL_INTERVAL_SECONDS)
    raise ApiError(0, 'qua %d giay van chua xong (task %s)' % (POLL_TIMEOUT_SECONDS, task_id))


def download(audio_url, out_path):
    """Tai file audio ve (khong gui khoa)."""
    try:
        with urllib.request.urlopen(audio_url, timeout=120) as response:
            content = response.read()
    except (urllib.error.URLError, OSError) as error:
        raise ApiError(0, 'khong tai duoc file audio: ' + type(getattr(error, 'reason', error)).__name__)
    folder = os.path.dirname(os.path.abspath(out_path))
    os.makedirs(folder, exist_ok=True)
    with open(out_path, 'wb') as handle:
        handle.write(content)
    return len(content)


def synthesize(text, key, voice, model, language, use_tags, out_path):
    """Doc van ban -> file audio. Tra dict { model, tags, task, bytes }."""
    tags_used = False
    if use_tags and 'v3' in model.lower():
        text = add_emotion_tags(text, key)
        tags_used = True
    try:
        task_id = submit(text, key, voice, model, language)
    except ApiError as error:
        # v3 bi tu choi (ngon ngu/model) -> lui ve model da chay that voi tieng Viet, bo the (model nay doc to the ra).
        if error.status in (400, 422) and model != FALLBACK_MODEL:
            log('Canh bao: model %s bi tu choi (%s). Chuyen sang %s va bo the cam xuc.'
                % (model, error.message, FALLBACK_MODEL))
            model = FALLBACK_MODEL
            tags_used = False
            task_id = submit(strip_tags(text), key, voice, model, language)
        else:
            raise
    log('Da gui yeu cau (model %s) - dang cho giong noi ...' % model)
    audio_url = wait_for_audio(task_id, key)
    size = download(audio_url, out_path)
    return {'model': model, 'tags': tags_used, 'task': task_id, 'bytes': size}


def open_page(kind):
    """Mo trang dang ky (link gioi thieu) hoac nap credit, va nhac ma khuyen mai. Luon in URL de du phong."""
    if kind == 'signup':
        url = REFERRAL_URL
        log('DANG KY: dang mo link gioi thieu. Hay dang ky TAI KHOAN MOI bang Google trong cua so vua mo.')
        log('Neu ban DA CO tai khoan Genmax tu truoc thi link gioi thieu khong tinh duoc, nhung van dung binh thuong.')
    else:
        url = SITE_URL
        log('NAP CREDIT: dang mo trang Bang gia. Chon goi, bam "Mua ngay", nhap ma vao o "Nhap ma khuyen mai (neu co)" TRUOC khi chon cach thanh toan.')
    log('MA KHUYEN MAI: %s  (nhap o cua so "Hoan tat thanh toan" de duoc them 15%% credit; khong bat buoc)' % PROMO_CODE)
    try:
        opened = webbrowser.open(url)
    except Exception:  # khong co trinh duyet mac dinh / moi truong khong co man hinh
        opened = False
    log('Da mo trinh duyet.' if opened else 'Khong tu mo duoc trinh duyet - hay mo link nay: ' + url)
    log('LINK: ' + url)
    return 0


def credit_hint(prefix):
    """Nhac nap credit + ma khuyen mai (goi khi het/sap het credit)."""
    log('%s Nap them credit: chay "genmax-tts --open topup" (tu mo trang) va nhap ma %s o buoc thanh toan de duoc them 15%%.'
        % (prefix, PROMO_CODE))


def show_balance(key):
    """In so du credit (GET /v1/auth/me, khong ton credit). Nhac nap neu sap het."""
    me = call('GET', '/v1/auth/me', key)
    balance = me.get('credit_balance') if isinstance(me, dict) else None
    if balance is None:
        log('Khong doc duoc so du credit.')
        return 0
    log('So du credit: %s' % balance)
    try:
        if float(balance) < LOW_CREDIT_THRESHOLD:
            credit_hint('CREDIT SAP HET.')
    except (TypeError, ValueError):
        pass
    return 0


def list_models(key):
    models = call('GET', '/v1/models', key)
    log('model_id | ten')
    for item in models if isinstance(models, list) else []:
        mark = '  <-- ban v3' if 'v3' in str(item.get('model_id', '')).lower() else ''
        log('%s | %s%s' % (item.get('model_id'), item.get('name'), mark))


def main(argv=None):
    parser = argparse.ArgumentParser(description='Doc van ban bang Genmax (mac dinh: Adam, ElevenLabs v3, the cam xuc).')
    parser.add_argument('--text')
    parser.add_argument('--text-file')
    parser.add_argument('--out', default='genmax-output.mp3')
    parser.add_argument('--voice')
    parser.add_argument('--model')
    parser.add_argument('--language', default=DEFAULT_LANGUAGE)
    parser.add_argument('--no-tags', action='store_true', help='tat tu dong them the cam xuc')
    parser.add_argument('--list-models', action='store_true')
    parser.add_argument('--open', choices=['signup', 'topup'], help='mo trang dang ky (link gioi thieu) hoac nap credit va nhac ma khuyen mai')
    parser.add_argument('--balance', action='store_true', help='xem so du credit')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args(argv)

    if args.open:
        return open_page(args.open)
    settings = get_settings()
    voice = args.voice or settings.get('GENMAX_VOICE_ID') or DEFAULT_VOICE
    model = args.model or settings.get('GENMAX_MODEL') or DEFAULT_MODEL
    use_tags = (not args.no_tags) and tags_enabled(settings)
    key = settings.get('GENMAX_API_KEY', '')

    text = args.text
    if args.text_file:
        with open(args.text_file, encoding='utf-8-sig') as handle:
            text = handle.read()
    if not args.list_models and not args.balance and not (text and text.strip()):
        log('E_ARGS: can --text hoac --text-file (hoac --list-models).')
        return 2

    if args.dry_run:
        log('[DryRun] voice=%s model=%s language=%s tags=%s out=%s' % (voice, model, args.language, use_tags, args.out))
        return 0
    if not key:
        log('CHUA_DIEN: chua co GENMAX_API_KEY (mo file khoa o bieu tuong Desktop, hoac chay 50-keys-sync.ps1).')
        return 2

    try:
        if args.balance:
            return show_balance(key)
        if args.list_models:
            list_models(key)
            return 0
        result = synthesize(text, key, voice, model, args.language, use_tags, args.out)
    except ApiError as error:
        log('E_GENMAX: %s (http=%s)' % (error.message, error.status))
        if error.status in (402, 429) or re.search(r'credit|quota|insufficient|balance', error.message, re.I):
            credit_hint('CO THE HET CREDIT.')
        return 3
    log('OK: da luu %s (%d byte) | model=%s | the cam xuc=%s | task=%s'
        % (args.out, result['bytes'], result['model'], 'co' if result['tags'] else 'khong', result['task']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
