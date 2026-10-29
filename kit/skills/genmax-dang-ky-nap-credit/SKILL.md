---
name: genmax-dang-ky-nap-credit
description: Đăng ký tài khoản Genmax (giọng đọc AI) và nạp credit trên máy học viên AISONNET. TỰ MỞ link giới thiệu khi cần đăng ký, và LUÔN nhắc nhập mã khuyến mại KMGENMAX (thêm 15% credit) mỗi khi học viên nạp/mua credit, kể cả nạp sau này. Dùng khi học viên nói "đăng ký Genmax", "tạo tài khoản Genmax", "chưa có tài khoản/khoá Genmax", "nạp credit", "mua credit", "hết credit", "hết hạn mức giọng đọc", "xem số dư Genmax", hoặc khi gọi Genmax báo lỗi 402/429/insufficient credit, hoặc khi cần lấy GENMAX_API_KEY mà học viên chưa có tài khoản.
---

# Genmax: đăng ký và nạp credit (skill trên máy học viên)

Học viên thường **không rành máy tính**: bạn tự mở link, tự nhắc mã, đừng bắt họ copy link hay nhớ mã. Nói ngắn, từng bước một, chờ họ báo xong rồi mới sang bước sau.

Công cụ sẵn trên máy (đã cài cùng bộ cài AISONNET; chạy từ bất kỳ thư mục nào):
- `genmax-tts --open signup` : tự mở **link giới thiệu** để đăng ký, in lại mã khuyến mại.
- `genmax-tts --open topup`  : tự mở trang Genmax để mua/nạp credit, in lại mã khuyến mại.
- `genmax-tts --balance`     : xem số dư credit (không tốn credit), tự nhắc nạp nếu sắp hết.
(Nếu lệnh `genmax-tts` không nhận: Windows chạy `py -3.12 C:\AISONNET\tools\genmax_tts.py ...`; Mac chạy `~/AISONNET/tools/genmax-tts ...`.)

**Dự phòng nếu `genmax-tts` không chạy được** (chưa cài Python, lỗi lạ): tự mở link bằng lệnh hệ điều hành, vẫn không bắt học viên copy: Windows `Start-Process 'https://genmax.io/?ref=mzkkz9'`; Mac `open 'https://genmax.io/?ref=mzkkz9'` (link giới thiệu đăng ký). Trang nạp credit: `https://genmax.io/`. Mã khuyến mại luôn là `KMGENMAX`.

## Khi học viên cần ĐĂNG KÝ (chưa có tài khoản hoặc chưa có khoá)
1. Hỏi một câu: "Bạn đã có tài khoản Genmax chưa?"
2. **Chưa có:** chạy `genmax-tts --open signup` (tự mở trình duyệt; học viên không cần copy link). Dặn: đăng ký bằng **Google** ngay trong cửa sổ vừa mở, **không vào genmax.io từ chỗ khác trước** (link giới thiệu phải là nơi đăng ký đầu tiên). Tài khoản mới có ít credit dùng thử.
3. **Đã có tài khoản:** nói thật rằng link giới thiệu chỉ tính cho tài khoản mới nên lần này không áp dụng được; vẫn dùng bình thường. Không bắt họ tạo tài khoản thứ hai.
4. Sau khi đăng nhập: mở `https://genmax.io/docs`, copy khoá ở ô code đầu trang, dán vào file khoá `.env` (theo hướng dẫn trong `SETUP.md` Phase 5, **không dán khoá vào chat**), rồi chạy kiểm tra khoá của bộ cài.

## Khi học viên cần NẠP CREDIT (bất cứ lúc nào, kể cả nạp ngay hay nạp sau này)
1. Chạy `genmax-tts --balance` để cho họ biết còn bao nhiêu.
2. Chạy `genmax-tts --open topup` (tự mở trang), và **luôn nhắc mã `KMGENMAX`**: "Khi thanh toán, nhập mã **KMGENMAX** để được thêm 15% credit." Nhắc **trước khi** họ bấm trả tiền, không nhắc sau.
3. Gói giá niêm yết ở trang chủ lúc 24/10/2026: 1.000.000 credit = $8; 2.500.000 = $16; 3.500.000 = $20; 7.000.000 = $36 (giá có thể đổi, lấy theo trang). Nạp nhiều được thêm bonus theo trang.
4. **Tìm ô nhập mã theo chữ hiển thị, không theo vị trí:** trong cửa sổ/bước mua credit có **một ô nhập mã voucher**, chữ gợi ý trong ô (placeholder) là `Enter voucher code (optional)` (nếu giao diện đã dịch thì là "Nhập mã voucher" hoặc tương tự). Hãy bảo học viên tìm ô có chữ đó, gõ `KMGENMAX`. Khi mã hợp lệ, trang hiện nhãn thưởng kiểu `+15% = … bonus credits`; **nếu thấy nhãn này thì mã đã áp dụng**, nếu không thì mã chưa được nhận.
   - Mã có thể báo `Voucher code not found` (gõ sai, nhắc gõ đúng KMGENMAX viết hoa), `This voucher is no longer active`, `Voucher expired` hoặc `out of stock` (hết hạn/hết lượt). Gặp các trường hợp này thì **nói thật với học viên, để họ tự quyết có nạp tiếp không**; đừng hứa chắc chắn còn khuyến mại.
   - Vị trí ô trên màn hình có thể khác theo cỡ cửa sổ hay khi Genmax đổi giao diện: **không** dựa vào XPath/vị trí. Không thấy ô đó thì nhờ học viên mô tả màn hình đang hiện (nút, ô, chữ) rồi chỉ chỗ; không bịa vị trí.
   - Không nhầm với mục **Redeem code** (đổi mã quà tặng ra credit) nếu trang có; mã KMGENMAX nhập ở bước **mua credit** (ô voucher).
5. Sau khi nạp xong, chạy lại `genmax-tts --balance` để xác nhận số dư tăng.

## Tự động nhắc khi gặp lỗi hết credit
Gọi Genmax báo 402/429 hoặc chữ `credit/quota/insufficient`, hoặc `genmax-tts` in "CO THE HET CREDIT": dừng, nói với học viên bằng lời đời thường, rồi làm đúng mục "NẠP CREDIT" ở trên. Khoá vẫn đúng, chỉ cần nạp thêm.

## Điều không được làm
- **Không tự trả tiền, không xin/nhập số thẻ, mật khẩu hay mã OTP** của học viên. Tiền và thanh toán là việc của học viên. Mở trang rồi để họ tự làm.
- Không in giá trị khoá; không dán khoá vào chat.
- Không hứa chắc chắn "được thêm 15%": mã áp dụng theo trang Genmax tại thời điểm thanh toán; nếu mã bị từ chối thì nói thật và để học viên quyết định.
