# Xử lý sự cố

Mỗi lần xử lý: thử cách 1 → 2 → 3, ghi `SETUP-LOG.md`; chỉ sau đó mới ứng biến theo nguồn chính thức, một bước/lần. Không in khoá. Mã lỗi do script in ra (dòng bắt đầu `E_...`); `state\status.json` có thêm trường `*_winget_exit` (mã thoát thô của winget) để tra cứu.

| Mã | Dấu hiệu | Cách 1 → 2 → 3 | Khi hỏi người | Câu Claude nói |
|---|---|---|---|---|
| E_OS_UNSUPPORTED | Windows cũ hơn 10 bản 1809 | Báo rõ không hỗ trợ → gợi ý cập nhật Windows | Máy không cập nhật được | “Windows này quá cũ cho bộ cài. Cần cập nhật Windows hoặc dùng máy khác.” |
| E_DISK | Ổ trống dưới 8 GB | Dọn file cá nhân → chọn ổ khác được phép → nhờ chủ máy | Không rõ được xoá gì | “Máy còn thiếu chỗ trống. Bạn hãy tự dọn ít nhất 8 GB rồi báo tôi.” |
| E_WINGET | Không có winget | Mở Microsoft Store → cập nhật “App Installer” → nếu Store bị chặn, tải App Installer từ trang Microsoft chính thức | Store bị IT chặn | “Máy chưa có App Installer (công cụ cài phần mềm của Windows). Tôi sẽ hướng dẫn mở nguồn chính thức.” |
| E_WINGET_SOURCE | winget báo lỗi nguồn | Chạy `winget source update` → chạy lại → mở terminal mới | Vẫn lỗi | “Kho phần mềm của Windows đang trục trặc; tôi sẽ thử cập nhật lại.” |
| E_NETWORK | Không ra được Internet / mất mạng giữa chừng | Kiểm Wi-Fi/VPN → chạy lại (script tự thử lại 2 lần) → thử mạng khác | Proxy/công ty | “Mạng đang chặn tải. Hãy thử mạng khác (điện thoại phát Wi-Fi) hoặc hỏi IT.” |
| E_UAC_DECLINED | Học viên bấm No ở hộp xin quyền | Giải thích → chạy lại `10-install-core.ps1` → học viên bấm Yes | Không có quyền quản trị | “Windows cần bạn bấm Yes để cài. Tôi không cần và không nhận mật khẩu của bạn.” |
| E_CORE_GIT / _PYTHON / _FFMPEG / _CHROME / _VSCODE | Một gói cài thất bại (xem `*_winget_exit` và 3 dòng cuối) | Mở terminal mới → chạy lại → `winget show --id <ID> --exact` xem gói còn tồn tại không → cài từ trang chính thức của gói | Vẫn lỗi sau 3 cách | “Một công cụ chưa cài xong; tôi đã ghi mã lỗi và sẽ thử cách khác.” |
| E_PATH | Đã cài nhưng terminal không thấy lệnh | Đóng hẳn terminal/Claude → mở mới → chạy lại | PATH do IT quản lý | “Hãy đóng hẳn và mở lại; công cụ mới cài chỉ hiện ở cửa sổ mở sau đó.” |
| E_PY_MISSING | Không có Python 3.12 | Chạy `10-install-core.ps1` → mở terminal mới → kiểm `py -3.12 --version` | Có nhiều Python lạ | “Chưa thấy Python 3.12; tôi sẽ cài đúng bản này, không xoá bản cũ.” |
| E_PIP | pip không cài/import được (xem 3 dòng cuối) | Đọc lỗi: nếu `metadata_errors`/`av` → chạy lại `20-python-libs.ps1` (đã ghim) → retry mạng → xoá thư mục thư viện lỗi dưới `%APPDATA%\Python\Python312\site-packages` chỉ khi chắc chắn gói nào hỏng, rồi cài lại đúng gói đó | Python hỏng nặng | “Thư viện Python chưa tải xong. Tôi sẽ thử lại theo nguồn chính thức.” |
| E_WHISPER_DOWNLOAD | Model không tải được | Kiểm mạng/ổ đĩa → chạy lại `30-whisper.ps1` → thử `-Model base` | Mạng proxy | “Model nhận dạng giọng nói chưa tải xong; việc này cần mạng ổn định.” |
| E_WHISPER_RUN | Whisper crash hoặc trúng ít từ khoá | Kiểm `20-python-libs` → thử lại → đọc dòng `Ket qua (khong dau)` xem có ra chữ không | Vẫn crash | “Whisper chưa chạy được trên máy này; tôi đã lưu chi tiết để hỗ trợ.” |
| E_WHISPER_SAMPLE | Thiếu `assets\sample-vi.wav` | Kiểm ZIP đủ file → giải nén lại | ZIP không đủ file | “File thử âm thanh đang thiếu; cần bộ cài đầy đủ.” |
| E_PLAYWRIGHT | Chromium không cài/mở | Chạy lại `40-browser-tools.ps1` → kiểm mạng → **không tắt Defender**, hỏi IT nếu bị chặn | Máy công ty | “Trình duyệt thử chưa sẵn sàng; không cần tắt bảo vệ máy.” |
| E_TEMPLATE | Thiếu `templates\env.template` | Giải nén lại ZIP | Cả hai link lỗi | “Bộ cài thiếu file mẫu; hãy tải lại.” |
| E_KEY_FORMAT | Khoá có khoảng trắng/xuống dòng, bị bao nháy, quá ngắn, dán nhầm khoá khác | Mở lại Notepad (biểu tượng Desktop) → sửa đúng dòng đó → lưu → chạy lại `50-keys-sync.ps1` | Không tìm thấy khoá | “Dòng này có vẻ chưa copy đúng (thừa khoảng trắng hoặc dán nhầm). Bạn mở lại file và dán lại giúp tôi.” |
| E_KEY_INVALID | Dịch vụ từ chối khoá (401/403/400) | Kiểm khoá copy đủ → tạo khoá mới trên trang dịch vụ → dán lại | Tài khoản bị khoá | “Dịch vụ không nhận khoá này. Bạn tạo khoá mới trên trang của họ rồi dán lại nhé.” |
| E_KEY_EXPIRED | Khoá hết hạn | Tạo khoá mới → dán lại → chạy lại | — | “Khoá này đã hết hạn, bạn tạo khoá mới giúp tôi.” |
| E_QUOTA | Hết hạn mức/credit (429/402) | Chờ vài phút → kiểm số dư trên trang dịch vụ → nạp credit (Genmax: mã `KMGENMAX` +15%) — **chỉ học viên tự quyết nạp** | Cần trả tiền | “Tài khoản đang hết hạn mức. Khoá vẫn đúng; bạn có thể chờ hoặc nạp thêm khi cần.” |
| E_KEY_NETWORK | Không gọi được dịch vụ (lỗi mạng/5xx) | Chạy lại sau 1–2 phút → thử mạng khác | Dịch vụ đang lỗi | “Dịch vụ đang chậm hoặc mạng chập chờn; tôi sẽ thử lại.” |
| E_SMOKE | `60-smoke.ps1` có mục LOI | Xử lý từng mục LOI trong bảng (mục `env:` hoặc `lenh-khoahoc-doctor` ghi `CAN_MO_TERMINAL_MOI` = đóng hẳn rồi mở lại) → chạy lại | Mục LOI lạ | “Còn một vài mục chưa đạt; tôi xử lý từng mục rồi kiểm lại.” |
| E_AUTO_BLOCKED | Claude Auto chặn một lệnh | Giải thích đúng hành động → học viên nói rõ đồng ý (nêu tên việc) hoặc bấm đồng ý khi được hỏi | Chặn liên tiếp | “Claude cần bạn xác nhận đúng việc cài đặt này. Tôi không dùng cách lách.” |
| E_ZIP_INVALID | ZIP tải về là trang HTML/hỏng (thường do Drive) | Thử link dự phòng → tải thủ công bằng trình duyệt → kiểm ZIP có `SETUP.md` | Cả hai link lỗi | “File tải về chưa phải ZIP hợp lệ; hãy mở link bằng trình duyệt, bấm Tải xuống rồi giải nén vào C:\AISONNET.” |
| E_ENV_NOT_VISIBLE | Claude/terminal cũ chưa thấy biến | Đóng hẳn app → mở mới → chạy `60-smoke.ps1` | Vẫn thiếu sau khi mở mới | “Biến mới chỉ hiện ở ứng dụng mở sau đó. Hãy đóng hẳn và mở lại.” |
| (cảnh báo) OneDrive / ký tự có dấu / khoảng trắng | `preflight.json → path_risks` | Không cần sửa: bộ cài dùng `C:\AISONNET` và trích dẫn đường dẫn | Phần mềm khác vẫn lỗi | “Tên tài khoản có dấu hoặc OneDrive không sao; bộ cài dùng đường dẫn an toàn riêng.” |
| (cảnh báo) máy công ty / domain | `warnings: may-cong-ty` | Báo cảnh báo → dùng cách IT chấp thuận → ghi DEFERRED nếu bị chặn | Cần quyền IT | “Đây là máy công ty/trường; hãy hỏi IT thay vì tự đổi chính sách.” |
| (bẫy) “tiếng Việt bị lỗi dấu” trong log/màn hình | Chữ `?` hoặc ký tự lạ | Bình thường: script cố ý in không dấu; chương trình Python → kiểm `PYTHONUTF8=1` đã đặt chưa (chạy `50-keys-sync.ps1`, mở terminal mới) | — | “Chữ không dấu trong cửa sổ lệnh là bình thường; tôi sẽ nói lại có dấu cho bạn.” |

## Lỗi ngoài bảng
Đi hết cách 1 → 2 → 3 của lỗi gần nhất. Sau đó chỉ dùng tài liệu/trang chính thức, thực hiện **một** thay đổi đảo ngược được mỗi lần, xem kết quả và ghi log. Hỏi học viên trước nếu cần UAC/mật khẩu, ảnh hưởng ngoài phạm vi, chi phí, gửi dữ liệu, hay máy công ty. Không tắt Defender, không đổi chính sách bảo mật và không yêu cầu khoá trong chat. Sau cùng nếu vẫn kẹt: `90-export-report.ps1` (đã lọc khoá) và bảo học viên gửi **nội dung** `bao-cao-ho-tro.txt` cho giảng viên.

## macOS (BETA — chưa kiểm chứng trên Mac thật)
Script Mac in cùng mã lỗi như Windows; bảng dưới là chỗ KHÁC. Mọi lỗi mới: ghi `SETUP-LOG.md` (nhật ký quý cho giảng viên).

| Mã / dấu hiệu | Cách 1 → 2 → 3 | Câu Claude nói |
|---|---|---|
| E_BREW (chưa có Homebrew) | Chưa có Xcode CLT thì cài trước (`xcode-select --install`) → học viên dán lệnh Homebrew chính thức vào **Terminal thật** và tự gõ mật khẩu → làm theo "Next steps" Homebrew in ra → mở Terminal mới | “Homebrew cần mật khẩu máy của bạn. Bạn tự gõ trong Terminal nhé — tôi không nhận mật khẩu.” |
| `brew: command not found` sau khi cài | Apple Silicon: `eval "$(/opt/homebrew/bin/brew shellenv)"`; Intel: `/usr/local/bin/brew` → thêm vào `~/.zprofile` → mở Terminal mới | “Mở một cửa sổ Terminal mới để máy nhận Homebrew.” |
| `xcode-select: error ... already installed` hoặc hộp thoại không hiện | `xcode-select -p` kiểm; nếu trống → `sudo xcode-select --reset` (học viên tự gõ mật khẩu) → cài lại | “Cần cài công cụ dòng lệnh của Apple trước.” |
| `externally-managed-environment` (pip) | KHÔNG dùng `pip` của hệ thống; dùng `aisonnet-pip` hoặc `~/.aisonnet/venv/bin/pip` | “Mac không cho cài thư viện vào Python hệ thống; tôi dùng môi trường riêng.” |
| Biến môi trường “không thấy” trong Claude Desktop | `launchctl` chỉ có hiệu lực sau khi mở lại ứng dụng: **Cmd+Q** Claude + Terminal, mở lại; vẫn không → đăng xuất/đăng nhập lại macOS | “Hãy thoát hẳn Claude (Cmd+Q) rồi mở lại.” |
| `Operation not permitted` / hộp thoại quyền (Files & Folders, Full Disk) | Học viên bấm **Cho phép** khi macOS hỏi; không tắt bảo mật hệ thống | “macOS đang hỏi quyền; bạn bấm Cho phép nhé.” |
| `zsh: permission denied` khi chạy script | Chạy bằng `bash đường-dẫn.sh` (file từ ZIP không có quyền chạy) | — |
| Mac Intel / macOS cũ | Cảnh báo ngoài phạm vi; thử tiếp, ghi rõ vào báo cáo | “Máy này ngoài phạm vi kiểm thử; có thể gặp thêm lỗi.” |
| Playwright/Chromium lỗi | Chạy lại `40-browser-tools.sh`; kiểm mạng; Gatekeeper chặn thì hỏi học viên, không tắt bảo mật | “Trình duyệt thử chưa sẵn sàng.” |
