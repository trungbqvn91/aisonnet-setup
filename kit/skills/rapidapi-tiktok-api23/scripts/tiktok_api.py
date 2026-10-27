"""Client gọi API tiktok-api23 trên RapidAPI (https://rapidapi.com/Lundehund/api/tiktok-api23).

Key (không bao giờ in ra, không dán vào chat): biến môi trường TIKTOK_API23_KEY,
hoặc file ~/.tiktok-api23/key.txt (người dùng tự dán bằng --setup-key).

Dùng như module:
    import tiktok_api as tk
    data = tk.call("user-info", uniqueId="taylorswift")

Dùng như CLI:
    python tiktok_api.py --setup-key
    python tiktok_api.py --check-key
    python tiktok_api.py --list [nhóm]
    python tiktok_api.py <endpoint> key=value key2=value2 [--out file.json] [--print]

Endpoint JSON trả về thường dài (hàng trăm field) -> mặc định LƯU RA FILE
(thư mục ./tiktok-out/) và chỉ in ra một bản tóm tắt ngắn, tránh tốn ngữ cảnh/lượt.
Dùng --print khi chắc chắn kết quả ngắn (vd check-alive, live-category).
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

BASE_URL = "https://tiktok-api23.p.rapidapi.com"
API_HOST = "tiktok-api23.p.rapidapi.com"
IS_MAC = sys.platform == "darwin"

KEY_DIR = os.path.expanduser(os.path.join("~", ".tiktok-api23"))
KEY_FILE = os.path.join(KEY_DIR, "key.txt")

# slug: (path, required_params, optional_params, mô tả tiếng Anh gốc từ docs)
ENDPOINTS = {
    "post-detail": ("/api/post/detail", ["videoId"], [], "Get Post Detail"),
    "post-comments": ("/api/post/comments", ["videoId"], ["count", "cursor"], "Get Post Comments"),
    "post-comment-replies": ("/api/post/comment/replies", ["videoId", "commentId"], ["count", "cursor"], "Get Post Reply Comments"),
    "post-related": ("/api/post/related", ["videoId"], ["count", "cursor"], "Get Related Posts"),
    "post-explore": ("/api/post/explore", ["categoryType"], ["count"], "Get Posts by Category"),
    "post-discover": ("/api/post/discover", ["keyword"], ["page"], "Discover Posts by Keyword"),
    "user-info": ("/api/user/info", ["uniqueId"], [], "Get User Info"),
    "user-info-with-region": ("/api/user/info-with-region", ["uniqueId"], [], "Get User Info v2"),
    "user-info-by-id": ("/api/user/info-by-id", [], ["userId", "secUid"], "Get User Info by ID"),
    "user-posts": ("/api/user/posts", ["secUid"], ["count", "cursor"], "Get User Posts"),
    "user-popular-posts": ("/api/user/popular-posts", ["secUid"], ["count", "cursor"], "Get User Popular Posts [deprecated]"),
    "user-oldest-posts": ("/api/user/oldest-posts", ["secUid"], ["count", "cursor"], "Get User Oldest Posts [deprecated]"),
    "user-liked-posts": ("/api/user/liked-posts", ["secUid"], ["count", "cursor"], "Get User Liked Posts"),
    "user-followers": ("/api/user/followers", [], ["secUid", "userId", "count", "max_time"], "Get User Follower"),
    "user-followings": ("/api/user/followings", [], ["secUid", "userId", "count", "max_time"], "Get User Following"),
    "user-playlist": ("/api/user/playlist", ["secUid"], ["count", "cursor"], "Get User Playlist"),
    "user-repost": ("/api/user/repost", ["secUid"], ["count", "cursor"], "Get User Repost"),
    "user-story": ("/api/user/story", ["userId"], ["maxCursor"], "Get User Story"),
    "user-dramas": ("/api/user/dramas", ["secUid"], ["count", "cursor"], "Get User Dramas"),
    "search-general": ("/api/search/general", ["keyword"], ["cursor", "search_id"], "Search General (Top)"),
    "search-video": ("/api/search/video", ["keyword"], ["cursor", "search_id"], "Search Video"),
    "search-account": ("/api/search/account", ["keyword"], ["cursor", "search_id"], "Search Account"),
    "search-live": ("/api/search/live", ["keyword"], ["cursor", "search_id"], "Search Live"),
    "search-photo": ("/api/search/photo", ["keyword"], ["cursor", "search_id"], "Search Photo"),
    "search-others-searched-for": ("/api/search/others-searched-for", ["keyword"], [], "Get Suggest Search Keyword"),
    "live-info": ("/api/live/info", ["roomId"], [], "Get Live Info"),
    "live-category": ("/api/live/category", [], [], "Get Live Category"),
    "live-stream": ("/api/live/stream", ["related_live_tag"], [], "Get Live Stream (related tag)"),
    "live-check-alive": ("/api/live/check-alive", ["uniqueId"], [], "Check if user is currently live"),
    "music-info": ("/api/music/info", ["musicId"], [], "Get Music Info"),
    "music-posts": ("/api/music/posts", ["musicId"], ["count", "cursor"], "Get Music Posts"),
    "music-unlimited-sounds": ("/api/music/unlimited-sounds", [], ["page", "pageSize", "orderBy"], "Get Music Unlimited Sounds"),
    "place-info": ("/api/place/info", ["placeId"], [], "Get Place Info"),
    "place-posts": ("/api/place/posts", ["placeId"], ["count", "cursor"], "Get Place Posts"),
    "drama-detail": ("/api/drama/detail", ["dramaId"], [], "Get Drama Detail"),
    "drama-episodes": ("/api/drama/episodes", ["dramaId"], ["count", "cursor"], "Get Drama Episodes"),
    "drama-explore": ("/api/drama/explore", [], ["type", "count", "cursor", "region", "releasePeriod"], "Explore Dramas"),
    "effect-info": ("/api/effect/info", ["effectId"], [], "Get Effect Info"),
    "effect-posts": ("/api/effect/posts", ["effectId"], ["count", "cursor"], "Get Effect Posts"),
    "challenge-info": ("/api/challenge/info", ["challengeName"], [], "Get Challenge (Hashtag) Info"),
    "challenge-posts": ("/api/challenge/posts", ["challengeId"], ["count", "cursor"], "Get Challenge (Hashtag) Posts"),
    "collection-info": ("/api/collection/info", ["collectionId"], [], "Get Collection Info"),
    "collection-posts": ("/api/collection/posts", ["collectionId"], ["count", "cursor"], "Get Collection Posts"),
    "trending-ads": ("/api/trending/ads", [], ["page", "period", "limit", "country", "order_by", "like", "ad_format", "objective", "industry", "ad_language", "keyword"], "Get Top Ads (ad intelligence)"),
    "trending-ads-detail": ("/api/trending/ads/detail", ["ads_id"], [], "Get Ads Detail"),
    "trending-keyword": ("/api/trending/keyword", [], ["page", "limit", "period", "country", "industry", "objective", "keyword_type"], "Get Trending Keyword [deprecated]"),
    "trending-keyword-sentence": ("/api/trending/keyword/sentence", ["keyword"], ["page", "limit", "period", "country", "order_type"], "Get Keyword Sentence [deprecated]"),
    "trending-keyword-posts": ("/api/trending/keyword/posts", ["keyword"], ["country", "limit", "period"], "Get Trending Video By Keyword [deprecated]"),
    "trending-hashtag": ("/api/trending/hashtag", [], ["page", "limit", "period", "country", "sort_by", "industry_id"], "Get Trending Hashtag [deprecated]"),
    "trending-song": ("/api/trending/song", [], ["page", "limit", "period", "country", "rank_type", "new_on_board", "commercial_music"], "Get Trending Song [deprecated]"),
    "trending-creator": ("/api/trending/creator", [], ["page", "limit", "sort_by", "country", "audience_count", "audience_country"], "Get Trending Creator [deprecated]"),
    "trending-video": ("/api/trending/video", [], ["page", "limit", "period", "order_by", "country"], "Get Trending Video [deprecated]"),
    "trending-commercial-music-library": ("/api/trending/commercial-music-library", [], ["page", "limit", "region", "scenarios", "duration", "placements", "themes", "genres", "moods", "music_name", "singer_name"], "Get Commercial Music Library"),
    "trending-commercial-music-library-playlist": ("/api/trending/commercial-music-library/playlist", [], ["limit", "region"], "Get Commercial Music Playlist"),
    "trending-commercial-music-library-playlist-detail": ("/api/trending/commercial-music-library/playlist/detail", ["playlist_id"], ["page", "limit", "region"], "Get Commercial Music Playlist Detail"),
    "trending-top-products": ("/api/trending/top-products", [], ["page", "last", "order_by", "country_code", "keyword", "category_id", "week", "month"], "Get Top Products [deprecated]"),
    "trending-top-products-metrics": ("/api/trending/top-products/metrics", ["product_id"], [], "Get Top Product Metrics [deprecated]"),
    "trending-top-products-detail": ("/api/trending/top-products/detail", ["product_id"], [], "Get Top Product Detail [deprecated]"),
    "download-video": ("/api/download/video", ["url"], [], "Download Video (no watermark)"),
    "download-user-video": ("/api/download/user/video", ["secUid"], ["minCursor", "maxCursor"], "Download All User Videos"),
    "download-music": ("/api/download/music", ["url"], [], "Download Music"),
}


class TiktokApiError(Exception):
    pass


def find_key():
    if os.environ.get("TIKTOK_API23_KEY"):
        return os.environ["TIKTOK_API23_KEY"].strip()
    if os.path.exists(KEY_FILE):
        with open(KEY_FILE, encoding="utf-8-sig") as f:
            k = f.read().strip()
        if k:
            return k
    sys.exit(
        "Chưa có key RapidAPI cho tiktok-api23.\n"
        "1. Subscribe (gói BASIC miễn phí) tại https://rapidapi.com/Lundehund/api/tiktok-api23/pricing\n"
        "2. Lấy key ở tab 'Code Snippets' trong playground\n"
        f"3. Chạy: python {os.path.basename(__file__)} --setup-key   (dán key vào Notepad hiện ra, lưu lại)"
    )


def setup_key():
    """Mở Notepad/TextEdit để người dùng tự dán key. Claude không bao giờ thấy nội dung key."""
    os.makedirs(KEY_DIR, exist_ok=True)
    if not os.path.exists(KEY_FILE):
        with open(KEY_FILE, "w", encoding="utf-8") as f:
            f.write("")
    if IS_MAC:
        subprocess.Popen(["open", "-e", KEY_FILE])
    else:
        os.startfile(KEY_FILE)  # noqa: S606 (mở bằng chương trình mặc định .txt)
    print(f"Đã mở {KEY_FILE}. Dán API key RapidAPI vào, lưu (Ctrl+S), đóng cửa sổ.")
    print("Xong chạy lại với --check-key để kiểm tra.")


def check_key():
    key = find_key()
    try:
        call("user-info", uniqueId="tiktok", _key=key)
    except TiktokApiError as e:
        print(f"KEY SAI hoặc chưa subscribe: {e}")
        sys.exit(1)
    print("KEY OK")


def call(slug, _key=None, _timeout=20, **params):
    """Gọi 1 endpoint theo slug (xem ENDPOINTS). Trả về dict JSON đã parse."""
    if slug not in ENDPOINTS:
        raise TiktokApiError(f"Không biết endpoint '{slug}'. Chạy --list để xem danh sách.")
    path, required, optional, _ = ENDPOINTS[slug]
    missing = [p for p in required if p not in params or params[p] in (None, "")]
    if missing:
        raise TiktokApiError(f"Thiếu tham số bắt buộc cho '{slug}': {missing}")
    allowed = set(required) | set(optional)
    unknown = set(params) - allowed
    if unknown:
        raise TiktokApiError(f"Tham số không hợp lệ cho '{slug}': {sorted(unknown)} (hợp lệ: {sorted(allowed)})")

    key = _key or find_key()
    qs = urllib.parse.urlencode({k: v for k, v in params.items() if v not in (None, "")})
    url = f"{BASE_URL}{path}" + (f"?{qs}" if qs else "")
    req = urllib.request.Request(
        url,
        headers={
            "x-rapidapi-key": key,
            "x-rapidapi-host": API_HOST,
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=_timeout) as resp:
            status = resp.status
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise TiktokApiError(f"HTTP {e.code} gọi {slug}: {body[:500]}") from None
    except urllib.error.URLError as e:
        raise TiktokApiError(f"Lỗi mạng gọi {slug}: {e}") from None

    if status == 204 or not body.strip():
        # Nhà cung cấp trả rỗng (thường gặp ở nhóm search/* hiện tại) — không phải lỗi key/script.
        return {"_empty": True, "_note": "API trả về rỗng (HTTP 204) cho endpoint/tham số này, thử keyword hoặc endpoint khác."}

    try:
        return json.loads(body)
    except json.JSONDecodeError:
        raise TiktokApiError(f"Phản hồi không phải JSON hợp lệ cho {slug}: {body[:300]}") from None


def _summarize(data, max_items=3):
    """Tóm tắt ngắn gọn để in ra terminal, tránh làm tràn ngữ cảnh Claude."""
    def shrink(x, depth=0):
        if depth > 2:
            return "…"
        if isinstance(x, dict):
            keys = list(x.keys())
            return {k: shrink(x[k], depth + 1) for k in keys[:8]} | ({"...": f"+{len(keys)-8} field khác"} if len(keys) > 8 else {})
        if isinstance(x, list):
            return [shrink(i, depth + 1) for i in x[:max_items]] + ([f"...+{len(x)-max_items} mục"] if len(x) > max_items else [])
        if isinstance(x, str) and len(x) > 200:
            return x[:200] + "…"
        return x
    return shrink(data)


def _list_endpoints(group_filter=None):
    groups = {}
    for slug, (path, req, opt, desc) in ENDPOINTS.items():
        group = slug.split("-")[0]
        groups.setdefault(group, []).append((slug, path, req, opt, desc))
    for group, items in sorted(groups.items()):
        if group_filter and group_filter not in group:
            continue
        print(f"\n== {group} ==")
        for slug, path, req, opt, desc in items:
            parts = [f"{p}=" for p in req] + [f"[{p}=]" for p in opt]
            print(f"  {slug:<48} {desc}")
            if parts:
                print(f"      {' '.join(parts)}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("endpoint", nargs="?", help="slug endpoint, vd user-info (bỏ trống nếu dùng --list/--setup-key/--check-key)")
    ap.add_argument("params", nargs="*", help="tham số dạng key=value")
    ap.add_argument("--list", nargs="?", const="", metavar="NHÓM", help="liệt kê endpoint (lọc theo nhóm nếu có, vd 'trending')")
    ap.add_argument("--setup-key", action="store_true")
    ap.add_argument("--check-key", action="store_true")
    ap.add_argument("--out", help="đường dẫn file JSON để lưu kết quả (mặc định: tiktok-out/<slug>-<timestamp>.json)")
    ap.add_argument("--print", action="store_true", dest="do_print", help="in toàn bộ JSON ra terminal thay vì lưu file (chỉ dùng khi kết quả ngắn)")
    args = ap.parse_args()

    if args.setup_key:
        return setup_key()
    if args.check_key:
        return check_key()
    if args.list is not None or args.endpoint is None:
        return _list_endpoints(args.list or None)

    kv = {}
    for p in args.params:
        if "=" not in p:
            sys.exit(f"Tham số sai định dạng (cần key=value): {p}")
        k, v = p.split("=", 1)
        kv[k] = v

    try:
        data = call(args.endpoint, **kv)
    except TiktokApiError as e:
        sys.exit(str(e))

    if args.do_print:
        print(json.dumps(data, ensure_ascii=False, indent=2))
        return

    out_path = args.out
    if not out_path:
        os.makedirs("tiktok-out", exist_ok=True)
        out_path = os.path.join("tiktok-out", f"{args.endpoint}-{int(time.time())}.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Đã lưu: {out_path}")
    print("Tóm tắt:")
    print(json.dumps(_summarize(data), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
