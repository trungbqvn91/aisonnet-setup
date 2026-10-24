# Phỏng vấn ngắn trước khi cài

Mở đầu: “Bạn đã đồng ý cho Claude tải bộ cài, chạy script, cài công cụ khoá học, đặt biến môi trường User và ghi khối ghi chú toàn cục như prompt đã nêu. Bạn đồng ý bắt đầu chứ?” Ghi `consent=yes` (xem lệnh bên dưới). Hỏi từng câu MỘT, ngắn gọn, bằng lời đời thường; đừng dồn cả bảng cho học viên.

Không hỏi Windows, RAM, ổ đĩa, mạng, username hay phần mềm đã có: Phase 1 tự dò.

| Câu hỏi đời thường | Vì sao hỏi / nhánh cài | Tên trường |
|---|---|---|
| Bạn đang dùng gói Claude nào: Pro, Max, Team/Enterprise hay API? | Xác định khả năng dùng Claude Code và hỗ trợ quota. | `claude_plan` |
| Đây là máy cá nhân hay máy công ty/trường? | Máy công ty có thể bị IT chặn; không tự sửa chính sách. | `machine_owner` |
| Bạn đã có tài khoản Apify, Genmax, Gemini chưa? | Lập danh sách dịch vụ cần hướng dẫn ở Phase 5. | `service_accounts` |
| Bạn có muốn dùng bot Telegram không? | Telegram là tuỳ chọn, có thể DEFERRED rõ ràng. | `telegram_needed` |
| Bạn tự tin với máy tính ở mức mới, cơ bản hay quen? | Chọn mức giải thích và tốc độ hướng dẫn. | `confidence_level` |
| Khi Windows hỏi, bạn có thể tự bấm Yes (hộp UAC) hoặc nhập mật khẩu máy không? | Không nhận mật khẩu; nếu không được thì chờ chủ máy/IT. | `uac_available` |
| Bạn cần VS Code ngay buổi đầu không? | Có thì thêm `-WithVSCode`; không thì làm sau, không bỏ mất. | `vscode_now` |
| Bạn cần extension Claude cho Chrome ngay không? | Có thì mở trang chính thức ở Phase 4; không thì DEFERRED. | `extension_now` |

## Cách ghi câu trả lời
Mỗi câu trả lời ghi bằng (KHÔNG ghi khoá/mật khẩu — script từ chối nếu giống khoá):

`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\AISONNET\scripts\win\record-answer.ps1" -Name claude_plan -Value Pro`

Kết quả lưu ở `C:\AISONNET\state\interview.json`; các phiên sau đọc lại để không hỏi lại.

## Mẫu báo tiến độ
`✅ 2/6 Core xong (Git, Python, FFmpeg). ⏳ Whisper đang tải, còn 12–25 phút. ❌ Chưa có lỗi. Việc của bạn: không cần làm gì.`
