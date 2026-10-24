# Playbook cài đặt Windows AISONNET

Bộ cài nằm ở `C:\AISONNET`. Mọi script chạy trong PowerShell theo đúng mẫu:

`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\AISONNET\scripts\win\<tên>.ps1" <tham số>`

**Cách đọc kết quả mọi script:** mã thoát `0` = OK, khác `0` = có lỗi; tìm dòng có mã `E_...` rồi tra `RECOVERY.md`. Script in tiếng Việt **không dấu** (có chủ ý) — bạn diễn giải lại có dấu cho học viên. Nguồn sự thật máy đọc được: `C:\AISONNET\state\status.json` (kết quả từng phase), `state\preflight.json` (thông tin máy), `SETUP-LOG.md` (nhật ký). Tất cả script chạy lại nhiều lần an toàn; thêm `-DryRun` để xem kế hoạch mà không đổi gì.

**Quy tắc lỗi (xem `CLAUDE.md`):** phase nào lỗi mà chưa tự khắc phục được thì ghi `HOAN` + lý do vào `SETUP-LOG.md`, làm tiếp các phase không phụ thuộc, rồi **quay lại xử lý mục HOAN trước Phase 7**. Thứ tự phụ thuộc: Phase 2 (Python) → Phase 3; Phase 1–2 độc lập với Phase 4 (trình duyệt) và Phase 5 (khoá), nên khoá/extension có thể làm trước khi quay lại sửa lỗi cài nền nếu lỗi đó cần người.

Sau mỗi phase: báo tiến độ theo `CLAUDE.md` (thanh ✅/⏳/○, ETA, đúng MỘT việc học viên cần làm).

## Phase 0 — Chào và phỏng vấn
Làm theo `INTERVIEW.md`. Ghi từng câu trả lời (KHÔNG ghi khoá/mật khẩu):
`... -File "C:\AISONNET\scripts\win\record-answer.ps1" -Name claude_plan -Value Pro`
(tên trường: `consent`, `claude_plan`, `machine_owner`, `service_accounts`, `telegram_needed`, `confidence_level`, `uac_available`, `vscode_now`, `extension_now`). Xong khi có `consent=yes`.

## Phase 1 — Dò máy (không đổi máy)
Thư mục `C:\AISONNET` do bước tải/giải nén tạo ra nếu máy chưa có (các script cũng tự tạo `state\` và `SETUP-LOG.md` khi cần). Giải khoá file tải từ internet (an toàn, chạy 1 lần): `Get-ChildItem -Recurse C:\AISONNET | Unblock-File`
Rồi chạy `00-preflight.ps1`. Đọc `state\preflight.json`:
- `errors` có `E_DISK` / `E_WINGET` / `E_NETWORK` / `E_OS_UNSUPPORTED` → xử lý theo RECOVERY rồi chạy lại.
- `is_win11 = false` hoặc cảnh báo `windows-10` / `arm64` / `may-cong-ty` → nói rõ với học viên: bộ cài **chưa hỗ trợ đầy đủ** máy này, vẫn thử được nhưng có thể phải xử lý thêm; máy công ty thì hỏi IT, không tự đổi chính sách.
- `path_risks` (OneDrive / ký tự có dấu / khoảng trắng): báo tin tốt là bộ cài dùng đường dẫn riêng `C:\AISONNET`, không ảnh hưởng.
Xong khi `PREFLIGHT: OK`.

## Phase 2 — Phần mềm nền (Git, Python 3.12, FFmpeg, Chrome nếu thiếu)
`10-install-core.ps1` (thêm `-WithVSCode` nếu `vscode_now=yes`). Windows có thể hiện hộp xin quyền (UAC): báo trước, học viên bấm **Yes**; không nhận mật khẩu. Mã lỗi: `E_UAC_DECLINED`, `E_WINGET_SOURCE`, `E_NETWORK`, `E_CORE_GIT|PYTHON|FFMPEG|CHROME|VSCODE`, `E_PATH`. Script tự bỏ qua thứ đã có. Xong khi `CORE: OK`. Nếu báo đã cài nhưng chưa thấy lệnh (`E_PATH`): mở terminal mới rồi chạy lại.

## Phase 3 — Thư viện Python + Whisper
1. `20-python-libs.ps1` (3–5 phút; cài cho người dùng, dùng được ở mọi thư mục; **ghim** `faster-whisper==1.2.1` + `av==16.1.0` — nếu thấy lỗi `metadata_errors` nghĩa là `av` bị nâng nhầm, chạy lại script này).
2. `30-whisper.ps1` (model `base`; lần đầu tải 1–3 phút; `-Model small` chỉ khi học viên muốn chất lượng cao hơn và máy khoẻ). Xong khi `WHISPER: OK` (trùng ≥ 2 từ khoá).

## Phase 4 — Trình duyệt + extension
`40-browser-tools.ps1` (cài Playwright Chromium, thử mở trang). Extension Claude cho Chrome: nếu `assets\links.json` chưa có URL thì **tự tìm trang chính thức** (không bịa link), mở cho học viên bấm “Thêm vào Chrome”; hoặc ghi **DEFERRED do học viên chọn** nếu `extension_now=no`. Không dùng Playwright/extension để đăng nhập hay lấy khoá hộ.

## Phase 5 — Khoá API
**5a. Chuẩn bị:** `50-keys-sync.ps1 -Prepare -OpenEditor` → tạo `C:\AISONNET\.env`, biểu tượng Desktop “Mo file khoa API”, mở Notepad. Dẫn học viên lần lượt từng dịch vụ (mỗi lần MỘT dịch vụ; mở trang giúp họ; họ tự đăng nhập, tự copy, tự dán vào Notepad, bấm Ctrl+S):
| Dịch vụ | Biến | Việc học viên làm |
|---|---|---|
| Apify | `APIFY_TOKEN` | `console.apify.com` → Settings → API & Integrations → copy Personal API token |
| Genmax | `GENMAX_API_KEY` | đăng ký bằng link giới thiệu của giảng viên `https://genmax.io/?ref=mzkkz9` (đăng nhập Google), mở `https://genmax.io/docs`, bấm ô code đầu trang để copy khoá. Nạp credit nhập mã `KMGENMAX` được thêm 15% (không bắt buộc; tài khoản mới có ít credit dùng thử) |
| Gemini | `GEMINI_API_KEY` | `aistudio.google.com/apikey` → đăng nhập Google → tạo khoá |
| Telegram (tuỳ chọn) | `TELEGRAM_BOT_TOKEN` | app Telegram → nhắn `@BotFather` → `/newbot` → copy token → nhắn bot của mình 1 câu |
Nhắc: **không dán khoá vào khung chat**, không chụp ảnh/gửi file `.env`. Học viên chỉ cần báo “đã lưu”.
**5b. Kiểm tra + đồng bộ:** `50-keys-sync.ps1` (thêm `-FetchTelegramChatId` nếu có token Telegram — script tự lấy chat id sau khi học viên đã nhắn bot; `-SkipTelegram` nếu không dùng). Script gọi thử API thật từng khoá, in bảng `TEN | TRANG THAI | GHI CHU | ...4 ký tự cuối` (không bao giờ in giá trị khoá). Khoá OK được đặt thành biến môi trường **mức User** (dùng được ở mọi phiên); `.env` giữ nguyên để học viên xem lại. Mã `E_KEY_FORMAT` / `E_KEY_INVALID` / `E_KEY_EXPIRED` / `E_QUOTA` / `E_KEY_NETWORK` → RECOVERY, mở lại Notepad cho học viên sửa đúng dòng đó rồi chạy lại.
**5c. Giọng Genmax — đã đặt MẶC ĐỊNH, KHÔNG cần hỏi chọn giọng:** giọng **Adam** (ElevenLabs, `GENMAX_VOICE_ID=pNInz6obpgDQGcFmaJgB`), model **`eleven_v3`**, **tự thêm thẻ cảm xúc** (`GENMAX_EMOTION_TAGS=1`). `50-keys-sync.ps1` tự điền các dòng này vào `.env` nếu để trống. Chỉ khi học viên muốn đổi: `55-genmax-voices.ps1 -Search <tên>` (hoặc `-Provider minimax|capcut`) liệt kê giọng, `55-genmax-voices.ps1 -Set <ID>` ghi `GENMAX_VOICE_ID`, rồi chạy lại `50-keys-sync.ps1`. Muốn tắt thẻ cảm xúc: đặt `GENMAX_EMOTION_TAGS=0` trong `.env`.
Công cụ đọc có sẵn: lệnh `genmax-tts --text "..." --out file.mp3` (đọc khoá/giọng/model từ biến môi trường; tự gọi `/v1/enhance` để thêm thẻ rồi đọc; nếu v3 bị từ chối thì tự lùi về `eleven_turbo_v2_5` và bỏ thẻ; `--list-models` để xem ID model thật). **Đọc thử 1 câu tốn credit — chỉ làm khi học viên đồng ý rõ.** Nếu ID model v3 thật khác `eleven_v3`, chạy `genmax-tts --list-models` rồi sửa `GENMAX_MODEL` trong `.env`.
Xong khi mọi khoá bắt buộc `OK` và các khoá tuỳ chọn là `OK` hoặc `BO_QUA` (do học viên chọn).

## Phase 6 — Toàn cục (làm trong cùng lần chạy `50-keys-sync.ps1` ở 5b)
Script cũng: thêm `C:\AISONNET\tools` vào PATH User (lệnh `khoahoc-doctor`), đặt `PYTHONUTF8=1` (để chương trình Python in tiếng Việt không bị lỗi), ghi một khối ghi chú vào `~\.claude\CLAUDE.md` toàn cục (phần cũ giữ nguyên) để **mọi phiên Claude sau này** biết máy có gì. Xong khi script in “Da ghi khoi ghi chu AISONNET”.
**Bắt buộc sau phase này:** học viên **đóng hẳn Claude (và mọi terminal) rồi mở lại** — biến môi trường mới chỉ hiện ở ứng dụng mở sau đó. Dặn họ mở Claude mới và dán: *“Tiếp tục cài đặt AISONNET: đọc C:\AISONNET\CLAUDE.md và SETUP.md rồi làm từ Phase 7.”*

## Phase 7 — Kiểm tra cuối (terminal MỚI, thư mục KHÁC)
Kiểm đúng thứ học viên sẽ dùng thật: bắt đầu bằng `Set-Location $env:USERPROFILE` (KHÔNG đứng trong `C:\AISONNET`), rồi:
1. `khoahoc-doctor` (kiểm nhanh) — nếu không nhận lệnh: terminal chưa mới (`E_PATH`/`E_ENV_NOT_VISIBLE`).
2. `60-smoke.ps1` (đầy đủ: lệnh, import thư viện, FFmpeg cắt thử, Whisper, Playwright, biến môi trường, gọi thử API, khối toàn cục, biểu tượng Desktop).
Dòng cuối `KET LUAN:` là `READY` / `READY_WITH_DEFERRED (...)` / `NOT_READY (...)`. **Chỉ nói READY** khi `READY` hoặc `READY_WITH_DEFERRED`; nêu rõ từng mục DEFERRED. `NOT_READY` → xử lý từng mục LOI theo RECOVERY rồi chạy lại.

## Phase 8 — Bàn giao
Tóm tắt cho học viên: đã cài gì, mục DEFERRED nào (do họ chọn) và cách làm sau, vị trí file khoá (biểu tượng Desktop), lệnh `khoahoc-doctor` khi nghi ngờ lỗi. Nếu còn sự cố không tự xử lý được sau khi đi hết thang trong RECOVERY: chạy `90-export-report.ps1` (đã lọc khoá) và bảo học viên gửi **nội dung** `C:\AISONNET\bao-cao-ho-tro.txt` cho giảng viên (tuyệt đối không gửi `.env`).
