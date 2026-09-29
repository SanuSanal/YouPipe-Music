"""Records real (anonymous) InnerTube WEB_REMIX responses as parser test fixtures.

Usage:  python tool/record_fixtures.py test/innertube/fixtures

Keep VER in sync with lib/innertube/clients.dart. After re-recording, run `flutter test`:
parsers_test.dart asserts concrete values (e.g. "Despacito", "Lofi Loft"), so update those
expectations if YouTube's content changed rather than the parsers.
"""
import json, sys, urllib.request, os

OUT = sys.argv[1]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
VER = "1.20260304.03.00"
visitor = None


def post(endpoint, body, extra_q=""):
    global visitor
    ctx = {"client": {"clientName": "WEB_REMIX", "clientVersion": VER, "hl": "en", "gl": "US"}}
    if visitor:
        ctx["client"]["visitorData"] = visitor
    data = json.dumps({"context": ctx, **body}).encode()
    req = urllib.request.Request(
        f"https://music.youtube.com/youtubei/v1/{endpoint}?prettyPrint=false{extra_q}", data=data,
        headers={"Content-Type": "application/json", "User-Agent": UA, "Origin": "https://music.youtube.com",
                 "Referer": "https://music.youtube.com/", "X-YouTube-Client-Name": "67",
                 "X-YouTube-Client-Version": VER, **({"X-Goog-Visitor-Id": visitor} if visitor else {})})
    with urllib.request.urlopen(req) as r:
        d = json.load(r)
    visitor = visitor or d.get("responseContext", {}).get("visitorData")
    return d


def save(name, d):
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False)
    print(f"{name}: {os.path.getsize(os.path.join(OUT, name))//1024} KB")


def find(o, key):
    """Yield every value stored under `key` anywhere in o."""
    if isinstance(o, dict):
        for k, v in o.items():
            if k == key:
                yield v
            yield from find(v, key)
    elif isinstance(o, list):
        for v in o:
            yield from find(v, key)


post("visitor_id", {})
home = post("browse", {"browseId": "FEmusic_home"}); save("home.json", home)
cont = next(find(home, "nextContinuationData"), None) or next(find(home, "continuationCommand"), None)
token = cont.get("continuation") or cont.get("token") if cont else None
if token:
    save("home_continuation.json", post("browse", {}, f"&ctoken={token}&continuation={token}&type=next"))
save("search_all.json", post("search", {"query": "coldplay"}))
# Songs filter params: keep in sync with SearchFilter.songs in lib/innertube/innertube.dart.
save("search_songs.json", post("search", {"query": "despacito", "params": "EgWKAQIIAWoSEAUQCRADEAQQChAOEBAQFRAR"}))
save("search_suggestions.json", post("music/get_search_suggestions", {"input": "cold"}))
save("album.json", post("browse", {"browseId": "MPREb_78js9pEDBUZ"}))
save("artist.json", post("browse", {"browseId": "UCIaFw5VBEK8qaW6nRpx_qnw"}))  # Coldplay
playlist = post("browse", {"browseId": "VLRDCLAK5uy_kb7EBi6y3GrtJri4_ZH56Ms786DFEimbM"})  # "Lofi Loft"
save("playlist.json", playlist)
cont = next(find(playlist, "nextContinuationData"), None)
if cont:
    save("playlist_continuation.json", post("browse", {"continuation": cont["continuation"]}))
nxt = post("next", {"videoId": "FXovf5dsRTw", "playlistId": "RDAMVMFXovf5dsRTw", "isAudioOnly": True,
                    "enablePersistentPlaylistPanel": True, "tunerSettingValue": "AUTOMIX_SETTING_NORMAL"})
save("next.json", nxt)
for tab in find(nxt, "tabRenderer"):
    ep = tab.get("endpoint", {}).get("browseEndpoint", {})
    bid = ep.get("browseId", "")
    if bid.startswith("MPLY"):
        save("lyrics.json", post("browse", {"browseId": bid}))
    elif bid.startswith("MPTRt"):
        save("related.json", post("browse", {"browseId": bid}))
save("explore.json", post("browse", {"browseId": "FEmusic_explore"}))
save("new_releases.json", post("browse", {"browseId": "FEmusic_new_releases_albums"}))
save("charts.json", post("browse", {"browseId": "FEmusic_charts"}))
moods = post("browse", {"browseId": "FEmusic_moods_and_genres"}); save("moods.json", moods)
cat = next((e for e in find(moods, "browseEndpoint") if e.get("params")), None)
if cat:
    save("mood_category.json", post("browse", {"browseId": cat["browseId"], "params": cat["params"]}))
