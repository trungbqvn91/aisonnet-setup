# Playbook cài đặt macOS AISONNET (BETA — chưa kiểm chứng trên Mac thật)

Bộ cài nằm ở `~/AISONNET` (= `/Users/<tên>/AISONNET`). Học viên Mac là những người thử đầu tiên: **nói rõ điều này với họ**, ghi lại mọi lỗi bằng `SETUP-LOG.md`, và nếu kẹt thì tạo báo cáo hỗ trợ (Phase 8). Quy tắc chung (thang tự chủ, 3 điều cấm mềm, báo tiến độ, **lỗi thì HOAN rồi quay lại**) nằm ở `CLAUDE.md` và áp dụng nguyên cho Mac.

Mọi script chạy bằng `bash` (file tải từ ZIP không có quyền chạy sẵn): `bash ~/AISONNET/scripts/mac/<tên>.sh [tham số]`. Thêm `--dry-run` để xem kế hoạch mà không đổi gì. Mã thoát `0` = OK; lỗi thì tìm dòng `E_...` và tra `RECOVERY.md` (mục macOS). Script in tiếng Việt **không dấu** có chủ ý — bạn diễn giải lại có dấu cho học viên. Trạng thái từng phase: `~/AISONNET/state/<phase>.json` (không chứa khoá), nhật ký `~/AISONNET/SETUP-LOG.md`.

## Điểm khác Windows (nói trước với học viên)
- **Có 2 việc học viên PHẢI tự gõ mật khẩu máy Mac trong cửa sổ Terminal thật** (Claude không nhập được): cài Xcode Command Line Tools (hộp thoại Install) và cài Homebrew. **Không bao giờ nhận mật khẩu trong chat.**
- Thứ tự bắt buộc: Claude → Xcode CLT → **Homebrew** → Git/Python/FFmpeg → thư viện → Whisper → trình duyệt → khoá → kiểm tra.
- Python dùng môi trường riêng chung cho cả máy: `~/.aisonnet/venv` (macOS khoá Python hệ thống). Dùng `aisonnet-python` / `aisonnet-pip` ở mọi thư mục.
- Biến môi trường ghi vào `~/.zprofile` và `launchctl`; **phải đóng hẳn (Cmd+Q) Claude và Terminal rồi mở lại**.

## Phase 0 — Phỏng vấn
Làm theo `INTERVIEW.md` (bỏ các câu về UAC/Windows; thay bằng "bạn có tự gõ được mật khẩu máy Mac khi macOS hỏi không?"). Ghi câu trả lời vào `state/interview.json` bằng cách tự tạo file JSON đơn giản (không có script riêng cho Mac); không ghi khoá/mật khẩu.

## Phase 1 — Giải nén, dò máy
Bộ cài đã giải nén ở `~/AISONNET` (nếu chưa: `mkdir -p ~/AISONNET && unzip -o ~/AISONNET/setup.zip -d ~/AISONNET`).
`bash ~/AISONNET/scripts/mac/00-preflight.sh` → đọc `state/preflight.json` (macos, arch, ram, ổ trống, admin, xcode_clt, brew, mạng).
- **Mac Intel hoặc macOS ≤ 12:** cảnh báo "ngoài phạm vi" — vẫn thử được, báo trước là có thể gặp lỗi.
- Ổ trống < 8 GB: dừng, nhờ học viên dọn.

## Phase 2 — Xcode CLT + Homebrew (học viên làm, Claude hướng dẫn)
1. Nếu `xcode_clt=false`: bảo học viên mở **Terminal** (Cmd+Space, gõ "Terminal") và gõ `xcode-select --install`, bấm **Install** ở hộp thoại, chờ xong (5–15 phút).
2. Nếu `brew=false`: bảo học viên dán ĐÚNG lệnh Homebrew chính thức vào **Terminal thật** và **tự gõ mật khẩu máy** (màn hình không hiện ký tự khi gõ — bình thường):
   `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
   Cuối lệnh, Homebrew in ra 2–3 dòng "Next steps" — học viên làm đúng theo (thêm vào `~/.zprofile`), rồi đóng và mở lại Terminal.
3. Kiểm: `brew --version`. Chạy lại Phase 1 nếu cần.

## Phase 3 — Phần mềm nền
`bash ~/AISONNET/scripts/mac/10-install-core.sh` → cài `git`, `python@3.12`, `ffmpeg` qua brew (cái nào có rồi thì bỏ qua). Mã lỗi: `E_BREW`, `E_CORE_INSTALL`, `E_CORE_<tên>`.

## Phase 4 — Thư viện Python + Whisper
1. `bash ~/AISONNET/scripts/mac/20-python-libs.sh` (tạo `~/.aisonnet/venv`, cài thư viện đã ghim `faster-whisper==1.2.1` + `av==16.1.0`, thêm `~/.aisonnet/bin` và `~/AISONNET/tools` vào PATH).
2. `bash ~/AISONNET/scripts/mac/30-whisper.sh` (model `base`; lần đầu tải 1–3 phút).

## Phase 5 — Trình duyệt + extension
`bash ~/AISONNET/scripts/mac/40-browser-tools.sh` (Playwright Chromium). Extension Claude cho Chrome: học viên bấm "Thêm vào Chrome" ở trang chính thức (tự tìm trang, không bịa link); cần Chrome — nếu chưa có thì `brew install --cask google-chrome` khi học viên đồng ý.

## Phase 6 — Khoá API
1. `bash ~/AISONNET/scripts/mac/50-keys-sync.sh --prepare --open-editor` → tạo `~/AISONNET/.env`, biểu tượng Desktop "Mo file khoa API.command" (bấm đúp để mở lại), mở TextEdit. Dẫn từng dịch vụ như Windows (Apify, Genmax, Gemini, Telegram — xem bảng ở `SETUP.md` Phase 5; dán vào TextEdit, **Cmd+S**; **không dán vào chat**).
2. Giọng Genmax mặc định đã điền sẵn: **Adam**, model `eleven_v3`, tự thêm thẻ cảm xúc (`GENMAX_EMOTION_TAGS=1`).
3. Sau khi học viên báo "đã lưu": `bash ~/AISONNET/scripts/mac/50-keys-sync.sh` (kiểm API thật, ghi biến vào `~/.zprofile`, khối ghi chú vào `~/.claude/CLAUDE.md`). Thêm `--skip-telegram` nếu không dùng Telegram.
4. **Đóng hẳn Claude và Terminal (Cmd+Q), mở lại.**

## Phase 7 — Kiểm tra cuối (Terminal MỚI, thư mục KHÁC)
`cd ~ && khoahoc-doctor` rồi `bash ~/AISONNET/scripts/mac/60-smoke.sh` (đầy đủ). Dòng cuối `KET LUAN:`. Chỉ báo READY khi `READY`/`READY_WITH_DEFERRED`; nêu rõ mục DEFERRED.

## Phase 8 — Bàn giao và báo cáo hỗ trợ
Tóm tắt như Windows. Nếu cần hỗ trợ: `bash ~/AISONNET/scripts/mac/90-export-report.sh` → học viên gửi **nội dung** `~/AISONNET/bao-cao-ho-tro.txt` (đã lọc khoá) cho giảng viên, **không gửi `.env`**. Đọc thêm: học viên Mac là người thử bản beta nên báo cáo này rất quý.
