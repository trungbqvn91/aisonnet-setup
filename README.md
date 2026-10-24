# aisonnet-setup

Bộ cài đặt máy cho khoá học **AISONNET** (Claude + AI ứng dụng làm Affiliate) — **Windows 11**.

Học viên không cần tải thủ công: giảng viên gửi một đoạn prompt, dán vào Claude, Claude tự tải bản phát hành mới nhất, hỏi vài câu ngắn, cài Git, Python, FFmpeg, Whisper, Playwright… và hướng dẫn điền khoá API.

- Tải thủ công (nếu cần): trang **Releases** → `aisonnet-setup.zip` → giải nén vào `C:\AISONNET`.
- Khoá API (Apify, Genmax, Gemini, Telegram) do học viên tự điền vào file `C:\AISONNET\.env`; **không bao giờ** dán khoá vào khung chat hay gửi file này cho ai.
- Bản **beta v0.1**: mới kiểm thử trên Windows 11. Windows 10, máy công ty, Mac **chưa hỗ trợ đầy đủ** (`kit/scripts/mac` là bản nháp chưa kiểm chứng, không nằm trong ZIP).

Kiểm thử: `tests/win/run-tests.ps1` (Windows PowerShell 5.1) và `tests/linux` (Docker). Đóng gói: `build/build-release.ps1`.
