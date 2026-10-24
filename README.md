# aisonnet-setup

Bộ cài đặt máy cho khoá học **AISONNET** (Claude + AI ứng dụng làm Affiliate) — **Windows 11** và **macOS (beta)**.

Học viên không phải tải thủ công: giảng viên gửi một đoạn prompt (bản Windows hoặc bản Mac), dán vào Claude Code, Claude tự tải bản phát hành mới nhất, hỏi vài câu ngắn, cài Git, Python, FFmpeg, Whisper, Playwright… và hướng dẫn điền khoá API. Hướng dẫn từ đầu cho học viên: [docs/HUONG-DAN-HOC-VIEN.md](docs/HUONG-DAN-HOC-VIEN.md).

- Tải thủ công (nếu cần): trang **Releases** → `aisonnet-setup.zip` → giải nén vào `C:\AISONNET` (Windows) hoặc `~/AISONNET` (Mac).
- Khoá API (Apify, Genmax, Gemini, Telegram) do học viên tự điền vào file `.env`; **không bao giờ** dán khoá vào khung chat hay gửi file này cho ai.
- Trạng thái: **beta**. Windows 11 đã kiểm thử kỹ nhất; **Mac chưa kiểm thử trên máy Mac thật** (mới kiểm logic trong Linux). Windows 10, máy công ty/trường, Mac Intel/macOS ≤ 12 chưa hỗ trợ đầy đủ.

Kiểm thử: `tests/win/run-tests.ps1` (Windows PowerShell 5.1) và `tests/linux` (Docker). Đóng gói: `build/build-release.ps1`.
