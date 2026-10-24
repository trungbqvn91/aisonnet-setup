# Chuẩn bị máy cho khoá AISONNET — hướng dẫn từ đầu

Làm xong phần này TRƯỚC buổi học đầu tiên. Bạn không cần biết lập trình, **không cần biết máy mình là Windows hay Mac, không cần tự tạo thư mục**: Claude tự nhận biết máy và tự cài hầu hết mọi thứ. Bạn chỉ làm vài thao tác đơn giản dưới đây.

> Bản thử nghiệm (beta). Windows 11 đã kiểm tra kỹ nhất; máy Mac dùng được nhưng mới ở mức thử nghiệm — nếu gặp lỗi xin gửi báo cáo cho giảng viên (cách gửi ở cuối). Windows 10 và máy công ty/trường chưa hỗ trợ đầy đủ.

## Bạn sẽ có gì sau khi xong
**Git, Python, FFmpeg** (xử lý video), **Whisper** (chuyển giọng nói thành chữ), **Playwright + Chrome** (tự động hoá trình duyệt), tuỳ chọn **VS Code**, cùng các kết nối: **Apify** (quét TikTok/Facebook), **Genmax** (tạo giọng đọc), **Gemini** (phân tích video), **Telegram** (thông báo, tuỳ chọn). Dùng được ở mọi thư mục, không chỉ lúc cài.

## Tổng quan 5 bước

| Bước | Việc | Ai làm | Thời gian (ước tính) |
|---|---|---|---|
| **0. Chuẩn bị** | Gói Claude trả phí, mạng ổn định, máy còn trống ít nhất 8 GB | Bạn | 5 phút |
| **1. Cài Claude** | Tải và cài ứng dụng Claude, đăng nhập | Bạn | 10 phút |
| **2. Mở tab Code** | Vào tab **Code**, chọn một thư mục bất kỳ, chọn chế độ **Auto** | Bạn | 5 phút |
| **3. Dán prompt** | Dán đoạn prompt ở Bước 3 (một bản chung cho mọi máy) | Bạn | 1 phút |
| **4. Claude cài tự động** | Hỏi vài câu ngắn, tự nhận máy, cài phần mềm, báo tiến độ | **Claude** (bạn theo dõi, bấm đồng ý khi được hỏi) | 30–60 phút |
| **5. Điền khoá API** | Tạo tài khoản, copy khoá dán vào file; thoát hẳn rồi mở lại Claude; kiểm tra lần cuối | Bạn + Claude | 15–30 phút |

Thời gian là **ước tính**, phụ thuộc mạng và máy.

## Bước 0 — Chuẩn bị
- **Gói Claude trả phí** (Pro trở lên). Gói miễn phí không dùng được chế độ Code. Gói có giới hạn số lượt hỏi theo giờ, nên lúc cài đừng dùng Claude làm việc khác.
- **Mạng ổn định**, cắm sạc laptop (có tải file vài trăm MB đến vài GB). Ổ cứng trống ≥ 8 GB.
- Có **điện thoại** bên cạnh (đăng nhập 2 bước, tạo bot Telegram nếu dùng).
- Không cần tắt diệt virus — **đừng tắt Windows Defender / bảo mật của máy**.
- *Không biết máy mình là Windows hay Mac?* Nhìn góc trên bên trái màn hình: có **logo quả táo** là Mac; còn nếu có nút **Start (logo cửa sổ)** ở dưới cùng là Windows. Không cần nhớ thêm gì — bước sau Claude tự nhận.

## Bước 1 — Cài Claude và đăng nhập
1. Vào https://claude.ai/download, tải bản cho máy bạn (trang hiện nút Windows và Mac — bấm đúng nút theo máy bạn; không chắc thì bấm nút trang đề xuất).
2. Mở file vừa tải và cài như phần mềm bình thường (Mac: kéo vào thư mục Applications). Nếu máy hỏi quyền (hộp thoại Windows xanh/vàng, hoặc macOS hỏi mật khẩu): bấm **Yes/Có** hoặc tự nhập mật khẩu của bạn.
3. Mở Claude, **đăng nhập** bằng tài khoản có gói trả phí.

> **Nếu ứng dụng Claude không có tab "Code"**: mở cửa sổ lệnh và dán đúng một dòng — Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex`; Mac (Terminal): `curl -fsSL https://claude.ai/install.sh | bash`. Cài xong mở cửa sổ lệnh mới, gõ `claude`, đăng nhập, rồi dán prompt ở Bước 3 vào đó (bỏ qua Bước 2).

## Bước 2 — Mở tab Code
1. Trong Claude, bấm tab **Code**.
2. Khi được hỏi chọn thư mục: **chọn thư mục nào cũng được** (ví dụ Tài liệu/Documents hoặc Desktop). **Bạn không cần tạo thư mục gì** — Claude sẽ tự tạo thư mục `AISONNET` ở chỗ phù hợp.
3. Ở ô chế độ quyền (dưới khung chat) chọn **Auto** nếu thấy; không thấy thì để mặc định.
4. Claude hỏi "tin tưởng thư mục này không": bấm **Có**.

## Bước 3 — Dán prompt
**Copy nguyên đoạn prompt dưới đây**, dán vào khung chat của Claude (tab Code) và gửi. Prompt dùng chung cho Windows và Mac; nó cho Claude phép tải bộ cài và làm các việc ở bước 4.

```
Tôi là học viên khoá AISONNET, đang chuẩn bị máy cho lớp. Tôi không rành máy tính và không biết chắc máy mình là Windows hay Mac, nên hãy tự kiểm tra hệ điều hành rồi làm đúng theo máy này. Tôi đồng ý để Claude làm các việc sau trên máy này: (1) tự tạo thư mục AISONNET nếu chưa có (Windows: C:\AISONNET; Mac: thư mục AISONNET trong thư mục Home của tôi), rồi tải bộ cài từ https://github.com/trungbqvn91/aisonnet-setup/releases/latest/download/aisonnet-setup.zip về đó, giải nén và chạy các script trong bộ cài; (2) cài các phần mềm của khoá (Git, Python, FFmpeg, Whisper, Playwright, extension Chrome, và VS Code nếu tôi chọn; trên Mac thì qua Homebrew); (3) đặt biến môi trường cho tài khoản của tôi và thêm một khối ghi chú vào file CLAUDE.md toàn cục của tôi (thư mục .claude trong thư mục Home). Việc nào cần mật khẩu máy (Mac: cài Xcode Command Line Tools và Homebrew) thì hãy hướng dẫn để tôi tự gõ trong cửa sổ Terminal; tôi sẽ không đưa mật khẩu hay API key vào khung chat — khi cần khoá, hãy mở file cho tôi tự điền. Sau khi tải xong, hãy kiểm tra file tải về đúng là ZIP và có SETUP.md bên trong, rồi đọc CLAUDE.md trong thư mục AISONNET và làm theo từng bước nó chỉ: hỏi tôi bằng câu ngắn dễ hiểu, báo tiến độ sau mỗi bước, và tự tìm cách xử lý nếu gặp lỗi, đừng bỏ cuộc ở lỗi đầu tiên. Nếu không tải được, hãy hướng dẫn tôi từng bước mở trang https://github.com/trungbqvn91/aisonnet-setup/releases, tải file aisonnet-setup.zip bằng trình duyệt rồi giải nén giúp tôi vào thư mục AISONNET.
```

## Bước 4 — Claude cài tự động
Claude sẽ:
- Tự kiểm tra máy (Windows hay Mac, còn chỗ trống không…).
- Hỏi bạn **khoảng 8 câu ngắn** (gói Claude nào, máy cá nhân hay công ty, đã có tài khoản nào chưa, có dùng Telegram không…). Trả lời đơn giản.
- Cài **Git, Python, FFmpeg**, thư viện, **Whisper**, **Playwright**…
- **Báo tiến độ** sau mỗi bước: `✅ Dò máy → ✅ Core → ⏳ Whisper → ○ Trình duyệt → ○ Khoá → ○ Kiểm tra`, kèm thời gian chờ và việc duy nhất bạn cần làm.
- Tự xử lý lỗi; việc nào chưa làm được ngay thì làm phần khác trước rồi quay lại.

**Bạn chỉ cần:** bấm **Yes** ở hộp xin quyền (Windows) hoặc **tự gõ mật khẩu máy** khi Mac hỏi — trên Mac việc này xảy ra khi cài công cụ của Apple và Homebrew (khi gõ mật khẩu màn hình **không hiện ký tự — bình thường**; **không gửi mật khẩu cho Claude**); bấm đồng ý khi Claude xin phép; **không đóng cửa sổ** khi đang tải/cài.

## Bước 5 — Điền khoá API
Claude mở file **khoá API** (Windows: Notepad; Mac: TextEdit) và dẫn từng dịch vụ: tự đăng nhập → copy khoá → dán vào file → **lưu (Ctrl+S trên Windows, Cmd+S trên Mac)** → nói với Claude "đã lưu".

| Dịch vụ | Dùng để | Lấy khoá ở đâu |
|---|---|---|
| **Apify** | Quét TikTok, Facebook | console.apify.com → Settings → API & Integrations → copy Personal API token |
| **Genmax** | Tạo giọng đọc | Đăng ký bằng Google tại https://genmax.io/?ref=mzkkz9 (tài khoản mới có ít credit dùng thử), vào https://genmax.io/docs, copy khoá ở ô mã đầu trang. Nạp credit nhập mã **KMGENMAX** được thêm 15% (không bắt buộc) |
| **Gemini** | Phân tích video | aistudio.google.com/apikey → đăng nhập Google → tạo khoá |
| **Telegram** (tuỳ chọn) | Nhận thông báo | Tạo bot với **@BotFather** — xem mục "Kết nối Telegram" bên dưới |

**Quy tắc an toàn:**
- **Không dán khoá vào khung chat** của Claude. Chỉ dán vào file.
- **Không chụp ảnh, không gửi file khoá** vào nhóm Zalo hay cho ai. Lỡ lộ thì vào trang dịch vụ tạo khoá mới.
- File khoá luôn mở lại được bằng biểu tượng **"Mo file khoa API"** ngoài màn hình nền (Desktop).

**Sau khi điền xong:** **thoát hẳn Claude** (Windows: đóng cửa sổ và kiểm tra icon dưới thanh Taskbar; Mac: **Cmd+Q**) rồi **mở lại**. Lý do: khoá chỉ có hiệu lực với ứng dụng mở *sau khi* điền. Claude chạy **kiểm tra cuối** và báo:
- **READY**: xong hoàn toàn.
- **READY với mục "để sau"**: dùng được, vài mục tuỳ chọn chưa làm (Claude nêu rõ).
- **NOT_READY**: còn mục chưa đạt; Claude xử lý tiếp hoặc hướng dẫn bạn gửi báo cáo lỗi.

## Kết nối Telegram (tuỳ chọn, khoảng 5 phút)
Không cần cài Telegram trên máy tính, dùng điện thoại là đủ. Bạn làm bước 1–3, Claude làm bước 4.
1. **Tạo bot:** trong Telegram, tìm **@BotFather** (tài khoản có **tích xanh**), gõ `/newbot`. Đặt tên bot tuỳ ý, rồi đặt **username kết thúc bằng `bot`** (ví dụ `trang_koc_bot`). BotFather gửi lại **token** dạng `123456789:AAH...` — đây là **mật khẩu của bot**: copy lại, **không dán vào khung chat với Claude**.
2. **Dán token vào file khoá:** dán sau dấu `=` ở dòng `TELEGRAM_BOT_TOKEN=`, lưu file, nhắn Claude "đã lưu". Dòng `TELEGRAM_CHAT_ID` để trống, Claude tự điền.
3. **Nhắn bot:** mở Telegram, tìm đúng bot vừa tạo, bấm **Start**, nhắn "hi".
4. **Claude tự lấy mã chat và gửi tin thử.** Telegram nhận được tin thử là xong.

Hay gặp: quên lưu file nên Claude báo chưa có token → mở lại file, lưu rồi chạy lại; không lấy được mã chat → chưa bấm Start hoặc nhắn nhầm bot, nhắn "hi" đúng bot rồi nhờ Claude thử lại; đã chặn bot → bỏ chặn rồi Start lại; muốn bot gửi vào **nhóm** → thêm bot vào nhóm, nhắn "hi" trong nhóm rồi nhờ Claude lấy lại mã chat.

## Nếu gặp sự cố
1. **Cứ nói với Claude** điều đang xảy ra (hoặc chụp màn hình lỗi, *trừ* file khoá API). Claude tự kiểm tra, sửa và đi tiếp.
2. Claude báo **không tự xử lý được**: nhờ nó tạo **báo cáo hỗ trợ** (file `bao-cao-ho-tro.txt` trong thư mục `AISONNET`, đã tự lọc khoá) và gửi **nội dung file này** cho giảng viên. **Tuyệt đối không gửi file `.env`.**
3. Mở lại rồi vẫn báo "không thấy khoá": thoát *hẳn* Claude (xem trên) rồi mở lại.
4. Máy công ty/trường bị chặn cài phần mềm: hỏi bộ phận IT, **đừng tắt bảo mật hay đổi cài đặt hệ thống**.

## Câu hỏi thường gặp
- **Tốn bao nhiêu tiền?** Bộ cài miễn phí. Chi phí là gói Claude và credit Genmax nếu dùng giọng đọc nhiều (Apify, Gemini có mức miễn phí; xem điều khoản từng dịch vụ).
- **Có làm hỏng máy không?** Bộ cài chỉ cài công cụ vào thư mục riêng/tài khoản của bạn, không xoá dữ liệu cá nhân; Claude hỏi trước khi làm việc ngoài phạm vi.
- **Cài lại được không?** Được: chạy lại prompt sẽ không cài lặp và không mất khoá đã điền.
- **Máy dùng chung nhiều tài khoản?** Chỉ tài khoản đã cài dùng được; tài khoản khác phải cài riêng.
