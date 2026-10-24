<!-- AISONNET:BEGIN v0.1.0 -->
Máy này đã cài: Git, Python 3.12, FFmpeg, faster-whisper, Playwright, apify-client, google-genai, python-dotenv, requests.
Khoá dùng biến môi trường User: APIFY_TOKEN, GENMAX_API_KEY, GEMINI_API_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID. Cấu hình giọng: GENMAX_VOICE_ID, GENMAX_MODEL, GENMAX_EMOTION_TAGS.
File khoá là `C:\AISONNET\.env`; có biểu tượng “Mở file khoá API” trên Desktop.
Giọng đọc MẶC ĐỊNH (Genmax → ElevenLabs): giọng Adam (voice_id `pNInz6obpgDQGcFmaJgB`), model `eleven_v3`, TỰ thêm thẻ cảm xúc (Genmax `POST /v1/enhance`, chỉ có tác dụng với v3) rồi mới đọc. Dùng sẵn: `genmax-tts --text "..." --out file.mp3` (thêm `--no-tags` để tắt thẻ). Chỉ đổi giọng/model khi học viên yêu cầu (`C:\AISONNET\scripts\win\55-genmax-voices.ps1`). Nếu v3 bị từ chối, công cụ tự lùi về `eleven_turbo_v2_5` và bỏ thẻ.
Gặp lỗi hãy chạy `khoahoc-doctor`; muốn cài lại xem `C:\AISONNET\SETUP.md`.
Không in giá trị khoá ra khung chat. Trong Python, đọc khoá từ biến môi trường (`os.environ`); in tiếng Việt cần `PYTHONUTF8=1` (đã đặt sẵn).
<!-- AISONNET:END -->
