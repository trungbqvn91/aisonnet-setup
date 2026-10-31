---
name: genmax-dang-ky-nap-credit
description: Đăng ký tài khoản Genmax (giọng đọc AI) và nạp credit trên máy học viên AISONNET. TỰ MỞ link giới thiệu khi cần đăng ký, và LUÔN nhắc nhập mã khuyến mãi KMGENMAX (thêm 15% credit) mỗi khi học viên nạp/mua credit, kể cả nạp sau này. Dùng khi học viên nói "đăng ký Genmax", "tạo tài khoản Genmax", "chưa có tài khoản/khoá Genmax", "nạp credit", "mua credit", "hết credit", "hết hạn mức giọng đọc", "xem số dư Genmax", hoặc khi gọi Genmax báo lỗi 402/429/insufficient credit, hoặc khi cần lấy GENMAX_API_KEY mà học viên chưa có tài khoản.
---

# Genmax: đăng ký và nạp credit (skill trên máy học viên)

Học viên thường **không rành máy tính**: bạn tự mở link, tự nhắc mã, đừng bắt họ copy link hay nhớ mã. Nói ngắn, từng bước một, chờ họ báo xong rồi mới sang bước sau.

Công cụ sẵn trên máy (đã cài cùng bộ cài AISONNET; chạy từ bất kỳ thư mục nào):
- `genmax-tts --open signup` : tự mở **link giới thiệu** để đăng ký, in lại mã khuyến mãi.
- `genmax-tts --open topup`  : tự mở trang **Bảng giá** (`https://genmax.io/app/pricing`) để mua credit, in lại mã khuyến mãi.
- `genmax-tts --balance`     : xem số dư credit (không tốn credit), tự nhắc nạp nếu sắp hết.
(Nếu lệnh `genmax-tts` không nhận: Windows chạy `py -3.12 C:\AISONNET\tools\genmax_tts.py ...`; Mac chạy `~/AISONNET/tools/genmax-tts ...`.)

**Dự phòng nếu `genmax-tts` không chạy được** (chưa cài Python, lỗi lạ): tự mở link bằng lệnh hệ điều hành, vẫn không bắt học viên copy: Windows `Start-Process 'https://genmax.io/?ref=mzkkz9'`; Mac `open 'https://genmax.io/?ref=mzkkz9'` (đăng ký). Trang mua credit: `https://genmax.io/app/pricing`. Mã khuyến mãi luôn là `KMGENMAX`.

## Khi học viên cần ĐĂNG KÝ (chưa có tài khoản hoặc chưa có khoá)
1. Chạy `genmax-tts --open signup` (tự mở trình duyệt; học viên không cần copy link). **Link giới thiệu mở được cho mọi người**: ai chưa có tài khoản thì đăng ký bằng **Google** ngay trong cửa sổ đó (tài khoản mới có ít credit dùng thử); ai đã có tài khoản thì link chỉ như trang chủ, không ảnh hưởng gì, cứ đăng nhập bình thường. Học viên muốn đăng ký thêm một tài khoản mới qua link cũng được. Không cần giải thích dài dòng hay hỏi trước.
2. Cho học viên link bằng chữ để lưu lại: `https://genmax.io/?ref=mzkkz9`.
3. Sau khi đăng nhập: mở `https://genmax.io/docs`, copy khoá ở ô code đầu trang, dán vào file khoá `.env` (theo `SETUP.md` Phase 5, **không dán khoá vào chat**), rồi chạy kiểm tra khoá của bộ cài.

## Khi học viên cần NẠP CREDIT (bất cứ lúc nào, kể cả nạp ngay hay nạp sau này)
1. Chạy `genmax-tts --balance` để cho họ biết còn bao nhiêu (nếu đã có khoá).
2. Chạy `genmax-tts --open topup` (tự mở trang **Bảng giá**; cần đăng nhập, chưa đăng nhập thì đăng nhập trước). Bảng giá lúc 29/10/2026 (có thể đổi, lấy theo trang): 1.000.000 credits = 185.000 đ; 2.500.000 = 370.000 đ; 3.500.000 = 525.000 đ; 7.000.000 = 925.000 đ. Nạp nhiều được thêm thưởng theo trang.
3. **Luôn nhắc mã `KMGENMAX` trước khi họ trả tiền**, bằng một câu ngắn, ví dụ: "Bấm **Mua ngay** ở gói bạn chọn, trong cửa sổ **Hoàn tất thanh toán** gõ mã **KMGENMAX** vào ô **Nhập mã khuyến mãi (nếu có)** (ô nằm ngay trên hai nút thanh toán), rồi mới chọn **Visa / Mastercard** hoặc **Chuyển khoản**. Nhập mã xong bạn được thêm 15% credit." Ô này nằm rất rõ trên màn hình, học viên tự tìm được: **đừng hỏi học viên vị trí ô, đừng yêu cầu họ mô tả màn hình**, chỉ cần nhắc mã. (Chữ trong ô có thể hiện chữ hoa.)
4. Không dựa vào vị trí/XPath của ô trên trang (đổi theo cỡ cửa sổ và khi Genmax cập nhật giao diện); chỉ nhắc bằng tên ô như trên.
5. Mã có thể báo không hợp lệ (sai mã, hết hạn, hết lượt). Gặp vậy thì **nói thật với học viên để họ tự quyết có nạp tiếp không**; đừng hứa chắc chắn còn khuyến mãi. Mã `KMGENMAX` nhập ở bước **mua credit**, khác mục **Mã quà tặng** (đổi mã quà ra credit) trong menu bên trái.
6. Sau khi nạp xong, chạy lại `genmax-tts --balance` để xác nhận số dư tăng.

## Tự động nhắc khi gặp lỗi hết credit
Gọi Genmax báo 402/429 hoặc chữ `credit/quota/insufficient`, hoặc `genmax-tts` in "CO THE HET CREDIT": dừng, nói với học viên bằng lời đời thường, rồi làm đúng mục "NẠP CREDIT" ở trên. Khoá vẫn đúng, chỉ cần nạp thêm.

## Lỗi 403 `error code: 1010` khi gọi Genmax bằng Python
**Không phải khoá sai.** Đây là Cloudflare (lớp bảo vệ trước Genmax) chặn "chữ ký" của chương trình Python mặc định (`Python-urllib`, và có thể cả `requests`/`httpx` trần), trong khi **PowerShell, curl và trình duyệt vẫn gọi được cùng khoá đó**. Một số máy bị, một số không.
- `genmax-tts` (bản v0.3.4 trở lên) đã tự gửi User-Agent như trình duyệt nên không bị nữa. Gặp 1010 khi dùng `genmax-tts` thì bộ cài đang cũ: chạy lại bộ cài để cập nhật.
- **Khi tự viết code Python gọi `api.genmax.io`** (kể cả `requests`): luôn thêm header `User-Agent` kiểu trình duyệt, ví dụ `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36`, cùng `xi-api-key`. Nếu vẫn bị chặn thì **gọi qua PowerShell** (`Invoke-RestMethod -Headers @{'xi-api-key'=$env:GENMAX_API_KEY}`) hoặc `curl`, rồi để Python xử lý file kết quả.
- Đừng bảo học viên đổi khoá hay tạo lại tài khoản vì lỗi này; đừng đo bằng cách gọi liên tục (làm tốn credit).

## Điều không được làm
- **Không tự trả tiền, không xin/nhập số thẻ, mật khẩu hay mã OTP** của học viên; chuyển khoản học viên tự làm trong app ngân hàng. Mở trang rồi để họ tự làm.
- Không in giá trị khoá; không dán khoá vào chat.
- Không hứa chắc chắn "được thêm 15%": mã áp dụng theo trang Genmax tại thời điểm thanh toán.
