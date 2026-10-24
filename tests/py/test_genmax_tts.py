"""Test genmax_tts.py voi MAY CHU GIA (khong goi Genmax that, khong ton credit, khong can khoa that)."""
import contextlib
import http.server
import io
import json
import os
import sys
import tempfile
import threading
import unittest

sys.dont_write_bytecode = True  # khong de lai __pycache__ trong kit\ (se lot vao ZIP)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,os.path.join(os.path.dirname(os.path.dirname(HERE)), 'kit', 'tools'))
import genmax_tts  # noqa: E402

FAKE_KEY = 'sk' + '_' + ('a' * 40)
AUDIO_BYTES = b'ID3FAKE-AUDIO-BYTES'


class Mock(http.server.BaseHTTPRequestHandler):
    """May chu gia Genmax. Cau hinh bang thuoc tinh lop; ghi lai moi request."""
    requests = []
    enhance_status = 200
    v3_status = 202
    history_status = 'completed'

    def log_message(self, *args):
        pass

    def _reply(self, status, payload, raw=None):
        body = raw if raw is not None else json.dumps(payload).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self):
        length = int(self.headers.get('Content-Length') or 0)
        return json.loads(self.rfile.read(length).decode('utf-8')) if length else {}

    def do_GET(self):
        Mock.requests.append(('GET', self.path, None, self.headers.get('xi-api-key')))
        if self.path.startswith('/v1/models'):
            return self._reply(200, [{'model_id': 'eleven_multilingual_v2', 'name': 'v2'},
                                     {'model_id': 'eleven_v3', 'name': 'Eleven v3'}])
        if self.path.startswith('/v1/history/'):
            if Mock.history_status == 'failed':
                return self._reply(200, {'status': 'failed', 'error': 'loi gia lap'})
            host = 'http://127.0.0.1:%d' % self.server.server_address[1]
            return self._reply(200, {'status': 'completed', 'result': {'audio_url': host + '/audio.mp3'}})
        if self.path == '/audio.mp3':
            self.send_response(200)
            self.send_header('Content-Length', str(len(AUDIO_BYTES)))
            self.end_headers()
            self.wfile.write(AUDIO_BYTES)
            return None
        return self._reply(404, {'message': 'khong co'})

    def do_POST(self):
        body = self._body()
        Mock.requests.append(('POST', self.path, body, self.headers.get('xi-api-key')))
        if self.path == '/v1/enhance':
            if Mock.enhance_status != 200:
                return self._reply(Mock.enhance_status, {'message': 'enhance hong'})
            return self._reply(200, {'text': '[excited] ' + body['text'], 'enhanced': True})
        if self.path.startswith('/v1/text-to-speech/'):
            if body.get('model_id') == 'eleven_v3' and Mock.v3_status != 202:
                return self._reply(Mock.v3_status, {'message': 'language_code khong ho tro'})
            return self._reply(202, {'id': 'task-123', 'status': 'pending'})
        return self._reply(404, {'message': 'khong co'})


class GenmaxTtsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Mock)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.url = 'http://127.0.0.1:%d' % cls.server.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def setUp(self):
        Mock.requests = []
        Mock.enhance_status = 200
        Mock.v3_status = 202
        Mock.history_status = 'completed'
        self.tmp = tempfile.mkdtemp()
        self.out = os.path.join(self.tmp, 'sub', 'ra.mp3')
        self.saved = {k: os.environ.get(k) for k in (
            'GENMAX_BASE_URL', 'GENMAX_API_KEY', 'GENMAX_VOICE_ID', 'GENMAX_MODEL',
            'GENMAX_EMOTION_TAGS', 'AISONNET_ENV_FILE')}
        os.environ['GENMAX_BASE_URL'] = self.url
        os.environ['GENMAX_API_KEY'] = FAKE_KEY
        os.environ['AISONNET_ENV_FILE'] = os.path.join(self.tmp, 'khong-co.env')
        for name in ('GENMAX_VOICE_ID', 'GENMAX_MODEL', 'GENMAX_EMOTION_TAGS'):
            os.environ.pop(name, None)
        genmax_tts.POLL_INTERVAL_SECONDS = 0

    def tearDown(self):
        for name, value in self.saved.items():
            if value is None:
                os.environ.pop(name, None)
            else:
                os.environ[name] = value

    def run_main(self, args):
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer):
            code = genmax_tts.main(args)
        return code, buffer.getvalue()

    def posts(self, prefix):
        return [r for r in Mock.requests if r[0] == 'POST' and r[1].startswith(prefix)]

    def test_base_url_override_only_for_loopback(self):
        os.environ['GENMAX_BASE_URL'] = 'https://may-chu-xau.example.com'
        self.assertEqual('https://api.genmax.io', genmax_tts.base_url())
        os.environ['GENMAX_BASE_URL'] = 'http://evil.localhost.example.com:80'
        self.assertEqual('https://api.genmax.io', genmax_tts.base_url())
        os.environ['GENMAX_BASE_URL'] = 'http://127.0.0.1:8080/'
        self.assertEqual('http://127.0.0.1:8080', genmax_tts.base_url())

    # ---- ham thuan
    def test_strip_tags(self):
        self.assertEqual('Xin chao ban', genmax_tts.strip_tags('[excited] Xin chao [short pause] ban'))
        self.assertEqual('khong co the', genmax_tts.strip_tags('khong co the'))

    def test_tags_enabled(self):
        self.assertTrue(genmax_tts.tags_enabled({}))
        self.assertTrue(genmax_tts.tags_enabled({'GENMAX_EMOTION_TAGS': ''}))
        self.assertTrue(genmax_tts.tags_enabled({'GENMAX_EMOTION_TAGS': '1'}))
        for off in ('0', 'false', 'No', 'OFF'):
            self.assertFalse(genmax_tts.tags_enabled({'GENMAX_EMOTION_TAGS': off}))

    def test_load_env_file(self):
        path = os.path.join(self.tmp, 'a.env')
        with open(path, 'w', encoding='utf-8-sig') as handle:
            handle.write('# ghi chu\nA=1\nB = "hai ba"\nC=x=y\n\nrac\n')
        self.assertEqual({'A': '1', 'B': 'hai ba', 'C': 'x=y'}, genmax_tts.load_env_file(path))

    # ---- luong day du, mac dinh = Adam + v3 + the cam xuc
    def test_default_flow_adam_v3_with_tags(self):
        code, output = self.run_main(['--text', 'Xin chao cac ban', '--out', self.out])
        self.assertEqual(0, code, output)
        enhance = self.posts('/v1/enhance')
        self.assertEqual(1, len(enhance))
        tts = self.posts('/v1/text-to-speech/')
        self.assertEqual(1, len(tts))
        self.assertTrue(tts[0][1].endswith(genmax_tts.DEFAULT_VOICE))
        body = tts[0][2]
        self.assertEqual('eleven_v3', body['model_id'])
        self.assertEqual('elevenlabs', body['provider'])
        self.assertEqual('vi', body['language_code'])
        self.assertTrue(body['text'].startswith('[excited]'), 'phai doc ban DA them the cam xuc')
        with open(self.out, 'rb') as handle:
            self.assertEqual(AUDIO_BYTES, handle.read())

    def test_key_sent_to_api_but_never_printed_or_sent_to_audio_host(self):
        code, output = self.run_main(['--text', 'Chao', '--out', self.out])
        self.assertEqual(0, code)
        self.assertNotIn(FAKE_KEY, output)
        api_calls = [r for r in Mock.requests if r[1] != '/audio.mp3']
        self.assertTrue(all(r[3] == FAKE_KEY for r in api_calls))
        audio_calls = [r for r in Mock.requests if r[1] == '/audio.mp3']
        self.assertTrue(all(r[3] is None for r in audio_calls), 'khong duoc gui khoa toi may chu audio')

    def test_old_tags_are_stripped_before_enhance(self):
        self.run_main(['--text', '[whispers] Chao ban', '--out', self.out])
        self.assertEqual('Chao ban', self.posts('/v1/enhance')[0][2]['text'])

    def test_no_tags_flag_skips_enhance(self):
        code, _ = self.run_main(['--text', 'Chao', '--no-tags', '--out', self.out])
        self.assertEqual(0, code)
        self.assertEqual(0, len(self.posts('/v1/enhance')))
        self.assertEqual('Chao', self.posts('/v1/text-to-speech/')[0][2]['text'])

    def test_env_tags_off_skips_enhance(self):
        os.environ['GENMAX_EMOTION_TAGS'] = '0'
        self.run_main(['--text', 'Chao', '--out', self.out])
        self.assertEqual(0, len(self.posts('/v1/enhance')))

    def test_non_v3_model_never_calls_enhance(self):
        os.environ['GENMAX_MODEL'] = 'eleven_turbo_v2_5'
        self.run_main(['--text', 'Chao', '--out', self.out])
        self.assertEqual(0, len(self.posts('/v1/enhance')))
        self.assertEqual('eleven_turbo_v2_5', self.posts('/v1/text-to-speech/')[0][2]['model_id'])

    def test_enhance_failure_continues_with_original_text(self):
        Mock.enhance_status = 500
        code, output = self.run_main(['--text', 'Chao ban', '--out', self.out])
        self.assertEqual(0, code, output)
        self.assertEqual('Chao ban', self.posts('/v1/text-to-speech/')[0][2]['text'])
        self.assertIn('Canh bao', output)

    def test_v3_rejected_falls_back_to_turbo_without_tags(self):
        Mock.v3_status = 400
        code, output = self.run_main(['--text', 'Chao ban', '--out', self.out])
        self.assertEqual(0, code, output)
        tts = self.posts('/v1/text-to-speech/')
        self.assertEqual(['eleven_v3', genmax_tts.FALLBACK_MODEL], [r[2]['model_id'] for r in tts])
        self.assertEqual('Chao ban', tts[1][2]['text'], 'ban lui phai bo the cam xuc')
        self.assertIn(genmax_tts.FALLBACK_MODEL, output)

    def test_custom_voice_and_model_from_env(self):
        os.environ['GENMAX_VOICE_ID'] = 'VOICE_TUY_CHINH_01'
        self.run_main(['--text', 'Chao', '--no-tags', '--out', self.out])
        self.assertTrue(self.posts('/v1/text-to-speech/')[0][1].endswith('VOICE_TUY_CHINH_01'))

    def test_task_failed_returns_error_code_3(self):
        Mock.history_status = 'failed'
        code, output = self.run_main(['--text', 'Chao', '--out', self.out])
        self.assertEqual(3, code)
        self.assertIn('E_GENMAX', output)
        self.assertNotIn(FAKE_KEY, output)

    def test_missing_key_exit_2_and_no_network(self):
        os.environ.pop('GENMAX_API_KEY')
        code, output = self.run_main(['--text', 'Chao', '--out', self.out])
        self.assertEqual(2, code)
        self.assertIn('CHUA_DIEN', output)
        self.assertEqual([], Mock.requests)

    def test_dry_run_no_network_and_no_file(self):
        code, output = self.run_main(['--text', 'Chao', '--dry-run', '--out', self.out])
        self.assertEqual(0, code)
        self.assertEqual([], Mock.requests)
        self.assertFalse(os.path.exists(self.out))
        self.assertIn('model=eleven_v3', output)

    def test_list_models_marks_v3(self):
        code, output = self.run_main(['--list-models'])
        self.assertEqual(0, code)
        self.assertIn('eleven_v3 | Eleven v3  <-- ban v3', output)

    def test_text_file_utf8_with_vietnamese(self):
        path = os.path.join(self.tmp, 'kich-ban.txt')
        text = 'Xin chào các bạn'
        with open(path, 'w', encoding='utf-8-sig') as handle:
            handle.write(text)
        code, output = self.run_main(['--text-file', path, '--no-tags', '--out', self.out])
        self.assertEqual(0, code, output)
        self.assertEqual(text, self.posts('/v1/text-to-speech/')[0][2]['text'])
        output.encode('ascii')  # moi dong in ra phai ASCII

    def test_no_text_is_an_argument_error(self):
        code, _ = self.run_main(['--out', self.out])
        self.assertEqual(2, code)


if __name__ == '__main__':
    unittest.main(verbosity=1)
