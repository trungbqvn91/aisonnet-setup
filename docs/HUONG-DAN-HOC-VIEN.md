# Chuẩn bị máy cho khoá AISONNET — hướng dẫn từ đầu

Làm xong phần này TRƯỚC buổi học đầu tiên. Bạn không cần biết lập trình: **Claude sẽ tự cài hầu hết mọi thứ**, bạn chỉ làm vài thao tác đơn giản được nêu dưới đây.

> Bản thử nghiệm (beta). **Windows 11** đã kiểm tra kỹ nhất. **Máy Mac** dùng được nhưng mới ở mức thử nghiệm (chưa kiểm trên máy Mac thật) — bạn là một trong những người thử đầu tiên nên nếu gặp lỗi xin gửi báo cáo cho giảng viên. Windows 10 và máy công ty/trường chưa hỗ trợ đầy đủ.

## Bạn sẽ được gì sau khi xong
Máy của bạn có đủ công cụ để học: **Git, Python, FFmpeg** (xử lý video), **Whisper** (chuyển giọng nói thành chữ), **Playwright + Chrome** (tự động hoá trình duyệt), tuỳ chọn **VS Code**, cùng các tài khoản/khoá kết nối: **Apify** (quét TikTok/Facebook), **Genmax** (tạo giọng đọc), **Gemini** (phân tích video), **Telegram** (nhận thông báo, tuỳ chọn). Mọi thứ dùng được ở mọi thư mục, không chỉ trong lúc cài.

## Tổng quan 5 bước

| Bước | Việc | Ai làm | Thời gian (ước tính) |
|---|---|---|---|
| **0. Chuẩn bị** | Có gói Claude trả phí, mạng ổn định, máy còn trống ổ C ít nhất 8 GB | Bạn | 5 phút |
| **1. Cài Claude** | Tải và cài ứng dụng Claude, đăng nhập | Bạn | 10 phút |
| **2. Mở đúng chế độ** | Vào tab **Code**, chọn thư mục, chọn chế độ **Auto** | Bạn | 5 phút |
| **3. Dán prompt** | Dán đoạn prompt giảng viên gửi | Bạn | 1 phút |
| **4. Claude cài tự động** | Hỏi bạn vài câu ngắn, cài phần mềm, báo tiến độ sau mỗi bước | **Claude** (bạn theo dõi, thỉnh thoảng bấm đồng ý) | 30–60 phút, tuỳ mạng |
| **5. Điền khoá API** | Tạo tài khoản, copy khoá dán vào file; đóng hẳn rồi mở lại Claude; Claude kiểm tra lần cuối | Bạn + Claude | 15–30 phút |

Con số thời gian là **ước tính**, thực tế phụ thuộc tốc độ mạng và máy.

## Bước 0 — Chuẩn bị (5 phút)
- **Gói Claude trả phí** (Pro trở lên). Gói miễn phí không dùng được chế độ Code. Mỗi gói có giới hạn số lượt hỏi theo giờ, nên trong lúc cài đừng dùng Claude làm việc khác.
- **Mạng ổn định**, cắm sạc laptop. Cài đặt có tải file lớn (vài trăm MB đến vài GB).
- **Ổ C còn trống ≥ 8 GB.**
- Có sẵn **điện thoại** (để đăng nhập 2 bước, và để tạo bot Telegram nếu bạn dùng).
- Đóng bớt phần mềm đang chạy. Không cần tắt diệt virus — **đừng tắt Windows Defender**.

## Bước 1 — Cài Claude và đăng nhập (10 phút)
1. Vào trang tải ứng dụng Claude cho Windows: https://claude.ai/download (tải bản Windows), mở file vừa tải và cài như phần mềm bình thường.
2. Mở Claude, **đăng nhập** bằng tài khoản có gói trả phí.
3. Nếu máy hỏi quyền cài đặt (hộp thoại xanh/vàng của Windows): bấm **Yes (Có)**.

> **Nếu ứng dụng Claude không có tab "Code"** (hoặc tab Code không chạy được trên máy bạn): báo giảng viên, sẽ có cách cài thay thế bằng dòng lệnh. Đừng cố tự xử lý.

## Bước 2 — Mở chế độ Code (5 phút)
1. Trong ứng dụng Claude, bấm vào tab **Code**.
2. Chọn thư mục làm việc: bấm chọn thư mục và chọn **`C:\AISONNET`** (nếu chưa có, tạo thư mục mới tên đó ở ổ C rồi chọn).
3. Ở ô chọn chế độ quyền (dưới khung chat), chọn **Auto** (tự động). Nếu không thấy Auto thì để mặc định; thỉnh thoảng Claude sẽ hỏi quyền, bạn đọc kỹ và bấm đồng ý khi đó là việc cài đặt của khoá.
4. Nếu Claude hỏi "có tin tưởng thư mục này không": bấm **Có**.

## Bước 3 — Dán prompt (1 phút)
Mở tin nhắn giảng viên gửi, **copy nguyên đoạn prompt** và dán vào khung chat của Claude rồi gửi. Đoạn đó cho Claude phép tải bộ cài và làm các việc ở bước 4.

## Bước 4 — Claude cài tự động (30–60 phút)
Claude sẽ:
- Hỏi bạn **khoảng 8 câu ngắn** (gói Claude nào, máy cá nhân hay công ty, đã có tài khoản nào, có dùng Telegram không…). Trả lời đơn giản.
- Tự kiểm tra máy rồi cài **Git, Python, FFmpeg**, thư viện, **Whisper**, **Playwright**…
- **Báo tiến độ** sau mỗi bước, kiểu: `✅ Dò máy → ✅ Core → ⏳ Whisper → ○ Trình duyệt → ○ Khoá → ○ Kiểm tra`, kèm thời gian chờ và việc duy nhất bạn cần làm.
- Tự xử lý lỗi nếu gặp. Việc nào chưa làm được ngay, Claude làm các phần khác trước rồi quay lại sau.

**Bạn chỉ cần:**
- Bấm **Yes** khi Windows hiện hộp xin quyền (UAC) — Claude sẽ báo trước.
- Bấm đồng ý khi Claude xin phép chạy một việc cài đặt.
- **Không đóng cửa sổ** khi đang tải/cài, chờ tới khi Claude báo xong.

## Bước 5 — Điền khoá API (15–30 phút)
Claude sẽ mở file **khoá API** (Notepad) và hướng dẫn từng dịch vụ. Với mỗi dịch vụ: tự đăng nhập → copy khoá → dán vào file → bấm **Ctrl+S** để lưu → nói với Claude "đã lưu".

| Dịch vụ | Dùng để | Lấy khoá ở đâu |
|---|---|---|
| **Apify** | Quét dữ liệu TikTok, Facebook | console.apify.com → Settings → API & Integrations → copy Personal API token |
| **Genmax** | Tạo giọng đọc | Đăng ký bằng link giảng viên gửi (tài khoản mới có ít credit dùng thử), vào genmax.io/docs, copy khoá. Nạp credit nhập mã **KMGENMAX** được thêm 15% (không bắt buộc) |
| **Gemini** | Phân tích video | aistudio.google.com/apikey → đăng nhập Google → tạo khoá |
| **Telegram** (tuỳ chọn) | Nhận thông báo | Trong app Telegram nhắn **@BotFather**, gõ `/newbot`, copy token; rồi nhắn bot của bạn 1 câu bất kỳ |

**Quy tắc an toàn quan trọng:**
- **Không dán khoá vào khung chat** của Claude. Chỉ dán vào file Notepad.
- **Không chụp ảnh, không gửi file khoá** vào nhóm Zalo hay cho bất kỳ ai. Lỡ lộ thì vào trang dịch vụ tạo khoá mới.
- File khoá luôn mở lại được bằng biểu tượng **"Mở file khoá API"** ngoài màn hình Desktop; đến lớp vẫn dùng tiếp.

**Sau khi điền xong:** **đóng hẳn Claude** (và mọi cửa sổ lệnh), rồi **mở lại**. Lý do: khoá chỉ có hiệu lực với ứng dụng mở *sau khi* điền. Claude sẽ chạy bài **kiểm tra cuối** (cắt thử video, nhận dạng giọng nói thử, gọi thử từng dịch vụ) và báo kết quả:
- **READY**: xong hoàn toàn.
- **READY với mục "để sau"**: dùng được, vài mục tuỳ chọn bạn chưa làm (Claude nêu rõ).
- **NOT_READY**: còn mục chưa đạt, Claude xử lý tiếp hoặc hướng dẫn bạn nhờ giảng viên.

## Dành cho máy MAC — những điểm khác Windows
Các bước tổng quan vẫn như trên. Khác biệt:
- **Bước 1:** tải Claude cho Mac tại https://claude.ai/download, kéo vào thư mục Applications, mở và đăng nhập.
- **Bước 2:** tab **Code**, chọn thư mục `AISONNET` trong thư mục Home của bạn (tạo mới nếu chưa có).
- **Bước 3:** dùng **bản prompt dành cho Mac** giảng viên gửi (khác bản Windows).
- **Bước 4 — có 2 lần bạn phải tự gõ mật khẩu máy Mac** trong cửa sổ **Terminal** (Cmd+Space, gõ "Terminal"): (a) cài công cụ dòng lệnh của Apple (hộp thoại **Install**), (b) cài **Homebrew** (công cụ cài phần mềm cho Mac). Claude sẽ hướng dẫn từng lệnh; khi gõ mật khẩu màn hình **không hiện ký tự gì — đó là bình thường**. **Không gửi mật khẩu cho Claude.**
- Mac đời Intel và macOS cũ (12 trở xuống): ngoài phạm vi kiểm thử, có thể gặp thêm lỗi.
- **Điền khoá:** file mở bằng **TextEdit**, lưu bằng **Cmd+S**; biểu tượng **"Mo file khoa API"** nằm ở Desktop. Sau khi điền, **thoát hẳn Claude và Terminal bằng Cmd+Q** rồi mở lại.
- Báo cáo hỗ trợ ở `~/AISONNET/bao-cao-ho-tro.txt` (không gửi file `.env`).

## Nếu gặp sự cố
1. **Cứ nói với Claude** điều đang xảy ra (hoặc chụp màn hình lỗi, *trừ* file khoá API). Claude tự kiểm tra, tự sửa và đi tiếp.
2. Claude báo **không tự xử lý được**: nhờ nó tạo **báo cáo hỗ trợ** — file `C:\AISONNET\bao-cao-ho-tro.txt` (đã tự lọc khoá). Gửi **nội dung file này** cho giảng viên. **Tuyệt đối không gửi file `.env`**.
3. Đã đóng/mở lại Claude mà vẫn báo "không thấy khoá/biến môi trường": đóng *hẳn* (kể cả icon dưới thanh Taskbar), mở lại rồi chạy kiểm tra cuối.
4. Máy công ty/trường bị chặn cài phần mềm: hỏi bộ phận IT, **đừng tắt Defender hay đổi cài đặt bảo mật**.

## Câu hỏi thường gặp
- **Tốn bao nhiêu tiền?** Bộ cài miễn phí. Chi phí duy nhất là gói Claude của bạn và credit Genmax nếu bạn muốn dùng giọng đọc nhiều (Apify, Gemini có mức miễn phí; kiểm tra điều khoản từng dịch vụ).
- **Có làm hỏng máy không?** Bộ cài chỉ cài công cụ vào thư mục riêng/tài khoản của bạn và không xoá dữ liệu cá nhân. Claude hỏi trước khi làm việc ngoài phạm vi.
- **Cài lại được không?** Được, chạy lại prompt sẽ không cài lặp và không mất khoá đã điền.
- **Máy dùng chung nhiều tài khoản (Windows/Mac)?** Chỉ tài khoản đã cài dùng được; tài khoản khác phải cài riêng.
