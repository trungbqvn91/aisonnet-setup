<!-- AISONNET:BEGIN v0.1.0-mac -->
Máy này (macOS) đã cài: Git, Python 3.12 (Homebrew), FFmpeg, môi trường Python riêng `~/.aisonnet/venv` với faster-whisper, Playwright, apify-client, google-genai, python-dotenv, requests. Chạy Python bằng `aisonnet-python` (hoặc `~/.aisonnet/venv/bin/python`), cài thêm gói bằng `aisonnet-pip`.
Khoá là biến môi trường (ghi trong ~/.zprofile): APIFY_TOKEN, GENMAX_API_KEY, GEMINI_API_KEY, TIKTOK_API23_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID; cấu hình giọng: GENMAX_VOICE_ID, GENMAX_MODEL, GENMAX_EMOTION_TAGS.
File khoá là `~/AISONNET/.env`; mở lại bằng biểu tượng “Mo file khoa API.command” trên Desktop.
Giọng đọc MẶC ĐỊNH (Genmax → ElevenLabs): Adam (`pNInz6obpgDQGcFmaJgB`), model `eleven_v3`, TỰ thêm thẻ cảm xúc (Genmax `/v1/enhance`) rồi mới đọc. Dùng: `genmax-tts --text "..." --out file.mp3` (`--no-tags` để tắt). Chỉ đổi giọng/model khi học viên yêu cầu.
Skill `rapidapi-tiktok-api23` (đã cài ở ~/.claude/skills): gọi API TikTok qua RapidAPI (user/video/comment/search/quảng cáo top/tải video). Khoá đọc từ biến `TIKTOK_API23_KEY`; chạy bằng `python3` nếu `python` không có. Gói BASIC chỉ 100 lượt/tháng: đừng gọi thử bừa.
Gặp lỗi chạy `khoahoc-doctor`; cài lại xem `~/AISONNET/SETUP-MAC.md`.
Không in giá trị khoá ra khung chat. Trong Python đọc khoá từ `os.environ`; in tiếng Việt cần `PYTHONUTF8=1` (đã đặt sẵn).
<!-- AISONNET:END -->
