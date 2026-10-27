---
name: rapidapi-tiktok-api23
description: Gọi API tiktok-api23 trên RapidAPI (https://rapidapi.com/Lundehund/api/tiktok-api23, docs đầy đủ tại docs.tikfly.io) để lấy dữ liệu TikTok công khai — thông tin user, video, comment, search, live, nhạc, hashtag/challenge, nơi chốn, drama, effect, collection, và đặc biệt nhóm Ads/Trending (soi quảng cáo top, nhạc thương mại) và Download (tải video/nhạc không logo). Dùng khi người dùng nói "gọi API tiktok-api23", "lấy dữ liệu TikTok qua RapidAPI", "soi quảng cáo TikTok", "lấy thông tin user/video TikTok bằng API", "tải video TikTok không logo bằng API", hoặc cần một endpoint cụ thể trong 61 endpoint của API này. KHÔNG dùng cho Douyin (skill quet-video-win-douyin) hay phân tích kênh qua trình duyệt (skill phan-tich-kenh-tiktok) — đây là API trả phí theo gói, dữ liệu JSON thô.
---

# API tiktok-api23 (RapidAPI)

Người dùng có thể là **bất kỳ ai** (không chỉ Trung) và có thể **không rành kỹ thuật** — skill này được chia sẻ cho nhiều người tự kết nối trên máy riêng của họ. Nói ngắn gọn, dễ hiểu, đi từng bước một, chờ họ báo "xong"/"rồi" rồi mới sang bước sau. Mỗi người có tài khoản RapidAPI và key riêng, lưu trên đúng máy của họ — không ai cần key của người khác.

Wrapper gọi 61 endpoint của API `tiktok-api23` (nhà cung cấp: apibox / tikfly.io) qua RapidAPI. `<skill>` = thư mục chứa file này.

## Kết nối lần đầu (mỗi người tự làm 1 lần trên máy của họ)

Hướng dẫn đầy đủ **kèm ảnh chụp từng bước** (kiểm chứng ngày 24/10/2026): `references/huong-dan-ket-noi.md` + `references/images/`. Đọc file đó khi hướng dẫn một người lần đầu hoặc khi họ bị kẹt. Tóm tắt nhanh:

**Trước tiên xác định lệnh Python đúng trên máy đó** — gõ thử `python --version`; nếu lỗi hoặc tự bật Microsoft Store thì thử `py --version` rồi `python3 --version`, dùng lệnh nào chạy được cho mọi bước dưới đây (thay cho `python`). Không có lệnh nào chạy được → máy chưa cài Python, hướng dẫn cài tại https://www.python.org/downloads/ (khi cài nhớ tick **"Add python.exe to PATH"**) rồi thử lại.

1. Vào https://rapidapi.com/Lundehund/api/tiktok-api23 → đăng nhập/đăng ký (Sign Up/Log In góc phải)
2. Bấm **"Subscribe to run"** (nút xanh góc phải) → ở trang chọn gói, bấm **"Start Free Plan"** dưới cột **BASIC $0.00** (100 request/tháng, 10 download/ngày, không cần thẻ)
3. Popup "Subscription Confirmed" hiện ra → bấm **"Get Started"** → tự chuyển vào Playground
4. Chọn 1 endpoint bất kỳ ở sidebar trái → cuộn xuống, bấm tab **"Code snippet"** (dưới cùng, cạnh Request/Response)
5. Trong khung code có dòng `x-rapidapi-key: ...` → copy đúng chuỗi key (hoặc copy cả khối rồi tự tách)
6. **Nạp key vào máy (không bao giờ dán key vào khung chat với Claude):** Claude chạy (thay `python` nếu cần):
   ```
   python "<skill>/scripts/tiktok_api.py" --setup-key
   ```
   → mở Notepad trống. Người dùng dán key (Ctrl+V), lưu (Ctrl+S), đóng. Báo Claude "xong rồi".
7. Kiểm tra:
   ```
   python "<skill>/scripts/tiktok_api.py" --check-key
   ```
   - `KEY OK` → xong, dùng được ngay.
   - Lỗi → đọc `references/huong-dan-ket-noi.md` (có mục lỗi thường gặp đầy đủ).

Key lưu ở `~/.tiktok-api23/key.txt` trên máy đó — dùng chung cho mọi project trên cùng máy, không cần làm lại bước này lần sau. Có thể override bằng biến môi trường `TIKTOK_API23_KEY`.

## Xem danh sách endpoint

```
python "<skill>/scripts/tiktok_api.py" --list
python "<skill>/scripts/tiktok_api.py" --list trending
```
In ra tất cả endpoint theo nhóm (post, user, search, live, music, place, drama, effect, challenge, collection, trending, download), kèm tham số bắt buộc/tùy chọn.

## Gọi 1 endpoint

```
python "<skill>/scripts/tiktok_api.py" <slug> key=value key2=value2
```

Ví dụ:
```
python "<skill>/scripts/tiktok_api.py" user-info uniqueId=taylorswift
python "<skill>/scripts/tiktok_api.py" search-video keyword="máy hút bụi"
python "<skill>/scripts/tiktok_api.py" trending-ads country=VN limit=20
python "<skill>/scripts/tiktok_api.py" download-video url="https://www.tiktok.com/@user/video/123..."
```

**Mặc định kết quả JSON được LƯU RA FILE** (`./tiktok-out/<slug>-<timestamp>.json`, hoặc `--out <đường dẫn>`), terminal chỉ in một bản tóm tắt rút gọn (object cắt còn ~8 field đầu, list cắt còn 3 phần tử) — JSON TikTok thường rất dài (nhiều trăm field lồng nhau), **không đọc nguyên file vào ngữ cảnh** trừ khi thật sự cần field cụ thể (dùng `jq`/Python để trích đúng field đó thay vì đọc cả file). Chỉ dùng `--print` khi chắc chắn kết quả ngắn (vd `live-check-alive`, `live-category`).

Dùng như module Python khi cần xử lý tiếp trong script khác:
```python
import sys; sys.path.insert(0, r"<skill>/scripts")
import tiktok_api as tk
data = tk.call("user-info", uniqueId="taylorswift")
```

## Nhóm endpoint đáng chú ý (không chỉ user/post cơ bản)

- **post**: detail, comments, reply-comments, related, explore (theo category), **discover (theo từ khóa)** — dò nội dung theo keyword.
- **user**: info / info-with-region / info-by-id, posts, liked-posts, followers/followings, playlist, repost, story, dramas.
- **search**: general, video, account, live, photo, **others-searched-for** (gợi ý từ khóa liên quan).
- **trending — nhóm giá trị cao nhất, dễ bị bỏ sót**:
  - `trending-ads` / `trending-ads-detail`: **soi quảng cáo top trên TikTok** theo nước/ngành/thời gian — ad intelligence cho affiliate.
  - `trending-commercial-music-library` (+ playlist/detail): nhạc thương mại hợp pháp dùng trong video.
  - Các endpoint `trending-keyword*`, `trending-hashtag`, `trending-song`, `trending-creator`, `trending-video`, `trending-top-products*` đều **[deprecated]** theo docs — vẫn gọi được nhưng nhà cung cấp không đảm bảo còn cập nhật, nên kiểm tra kỹ dữ liệu trả về trước khi dựa vào.
- **download**: video/music không logo, và tải toàn bộ video của 1 user (`download-user-video`).
- **live, music, place, drama, effect, challenge, collection**: mỗi nhóm có `*-info` (chi tiết 1 đối tượng) và `*-posts` (video gắn với đối tượng đó).

## Giới hạn

- Free tier (BASIC) giới hạn số request/tháng — gọi `--check-key` hoặc đọc lỗi HTTP 429 để biết khi hết hạn mức; gói trả phí tăng hạn mức.
- API không chính thức (unofficial), dữ liệu TikTok công khai — không dùng để thu thập dữ liệu cá nhân nhạy cảm hoặc vi phạm điều khoản TikTok.
- Một số tham số cần `secUid`/`userId` lấy từ kết quả gọi `user-info` trước (không phải `uniqueId`/username trực tiếp) — xem field trả về của `user-info` để lấy đúng ID cho các endpoint khác.
