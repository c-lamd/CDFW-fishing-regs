#!/usr/bin/env python3
"""Fetch one ID photo per species: the lead image of its Wikipedia article, free-licensed Commons files only.
Writes resources/photos/*, data/photos.json (credits), and from those resources/photos/photos.xml and
source/Photos.mc.
Run: python3 data/photos.py              re-fetch everything (after editing TITLES)
     python3 data/photos.py --no-fetch   only regenerate photos.xml / Photos.mc (after changing BOX)"""
import json, os, re, struct, sys, time, unicodedata, urllib.error, urllib.parse, urllib.request

# regs.json name -> Wikipedia article. Group/generic entries are left out on purpose.
TITLES = {
    "Kelp bass (calico)": "Paralabrax clathratus",
    "Barred sand bass": "Paralabrax nebulifer",
    "Spotted sand bass": "Paralabrax maculatofasciatus",
    "White seabass": "Atractoscion nobilis",
    "Giant (black) sea bass": "Stereolepis gigas",
    "California sheephead": "California sheephead",
    "Ocean whitefish": "Caulolatilus princeps",
    "CA scorpionfish (sculpin)": "Scorpaena guttata",
    "Garibaldi": "Garibaldi (fish)",
    "Gulf & broomtail grouper": "Mycteroperca jordani",
    "Other groupers (cabrilla)": "Epinephelus analogus",
    "Opaleye": "Girella nigricans",
    "Halfmoon": "Medialuna californiensis",
    "Sargo": "Anisotremus davidsonii",
    "Black croaker": "Cheilotrema saturnum",
    "Vermilion/sunset rockfish": "Sebastes miniatus",
    "Copper rockfish": "Sebastes caurinus",
    "Canary rockfish": "Sebastes pinniger",
    "Bocaccio": "Sebastes paucispinis",
    "Treefish": "Sebastes serriceps",
    "Gopher rockfish": "Sebastes carnatus",
    "Black-and-yellow rockfish": "Sebastes chrysomelas",
    "Kelp rockfish": "Sebastes atrovirens",
    "Grass rockfish": "Sebastes rastrelliger",
    "Brown rockfish": "Sebastes auriculatus",
    "Olive rockfish": "Sebastes serranoides",
    "Blue/deacon rockfish": "Sebastes mystinus",
    "Cowcod": "Sebastes levis",
    "Yelloweye rockfish": "Sebastes ruberrimus",
    "Bronzespotted rockfish": "Sebastes gilli",
    "Quillback rockfish": "Sebastes maliger",
    "Lingcod": "Lingcod",
    "Cabezon": "Scorpaenichthys marmoratus",
    "Greenling (kelp/rock)": "Hexagrammos decagrammus",
    "Yellowtail": "Seriola dorsalis",
    "Pacific bonito": "Sarda chiliensis",
    "California barracuda": "Sphyraena argentea",
    "Mackerel (Pacific & jack)": "Scomber japonicus",
    "Dorado (dolphinfish)": "Mahi-mahi",
    "Albacore": "Albacore",
    "Bluefin tuna": "Pacific bluefin tuna",
    "Skipjack tuna": "Skipjack tuna",
    "Yellowfin/bigeye/other tuna": "Yellowfin tuna",
    "Wahoo": "Wahoo",
    "Striped marlin": "Striped marlin",
    "Broadbill swordfish": "Swordfish",
    "Jacksmelt": "Atherinopsis californiensis",
    "Topsmelt": "Atherinops affinis",
    "Pacific sardine": "Sardinops sagax",
    "Northern anchovy": "Engraulis mordax",
    "California halibut": "Paralichthys californicus",
    "Pacific sanddab": "Citharichthys sordidus",
    "Soles (rock/sand/butter)": "Lepidopsetta bilineata",
    "Petrale sole / starry flounder": "Eopsetta jordani",
    "Redtail surfperch": "Amphistichus rhodoterus",
    "Shiner perch": "Cymatogaster aggregata",
    "California corbina": "Menticirrhus undulatus",
    "Spotfin croaker": "Roncador stearnsii",
    "Yellowfin croaker": "Umbrina roncador",
    "White croaker (tomcod)": "Genyonemus lineatus",
    "Salmon (Chinook)": "Chinook salmon",
    "Striped bass": "Striped bass",
    "Leopard shark": "Leopard shark",
    "Soupfin shark": "School shark",
    "Shortfin mako shark": "Shortfin mako shark",
    "Thresher shark": "Common thresher",
    "Blue shark": "Blue shark",
    "Sixgill shark": "Bluntnose sixgill shark",
    "Broadnose sevengill shark": "Broadnose sevengill shark",
    "White shark": "Great white shark",
    "Bat ray": "Bat ray",
    "Shovelnose guitarfish": "Pseudobatos productus",
    "Pacific angel shark": "Pacific angelshark",
    "Horn shark": "Horn shark",
    "Swell shark": "Swellshark",
    "Smoothhounds (gray/brown)": "Grey smooth-hound",
    "Skates (big/CA/longnose)": "Big skate",
    "Spiny dogfish": "Spiny dogfish",
    "California spiny lobster": "California spiny lobster",
    "Rock crabs (red/yellow/brown)": "Cancer productus",
    "Sheep crab (spider crab)": "Loxorhynchus grandis",
    "Rock scallop": "Crassadoma gigantea",
    "Red sea urchin": "Mesocentrotus franciscanus",
    "Purple sea urchin": "Strongylocentrotus purpuratus",
    "Octopus": "Octopus bimaculoides",
    "Warty sea cucumber": "Apostichopus parvimensis",
    "Market squid": "Doryteuthis opalescens",
    "Mussels (California & bay)": "Mytilus californianus",
    "Pismo clam": "Pismo clam",
    "Littleneck/chione/cockle clams": "Leukoma staminea",
    "Gaper & Washington clams": "Tresus nuttallii",
    "Abalone (all species)": "Red abalone",
    "Kellet's whelk": "Kelletia kelletii",
    "Moon snail": "Neverita lewisii",
    "Limpets": "Lottia gigantea",
    "Kelp & marine plants": "Macrocystis pyrifera",
    "Speckled (bay) scallop": "Argopecten ventricosus",
}
BOX = (240, 104)  # px on a 390 px screen for the photo under the name (PhotoTitle.mc); scales per device
CROP = 0.35       # PhotoTitle clips top/bottom to BOX height; lose at most this share of a photo's height
SCREEN = 390
UA = {"User-Agent": "FishRegs-watchapp/1.0 (personal Connect IQ app; photo fetch script)"}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "resources", "photos")


def get(url):
    """GET with a polite pace; waits out 429s and dropped connections (Wikimedia rate-limits bursts)."""
    for wait in (1, 5, 15, 30, 60):
        time.sleep(wait)
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA)) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
        except urllib.error.URLError:  # flaky network: retry too
            pass
    raise RuntimeError("still rate-limited: " + url)


def api(host, **params):
    params.update(action="query", format="json", formatversion="2")
    return json.loads(get(f"https://{host}/w/api.php?" + urllib.parse.urlencode(params)))["query"]


def dims(b):
    """(width, height) of PNG or JPEG bytes. Thumbs of small originals come back at original size."""
    if b[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", b[16:24])
    i = 2
    while i < len(b):
        marker, length = b[i + 1], struct.unpack(">H", b[i + 2:i + 4])[0]
        if marker in (0xC0, 0xC1, 0xC2):  # start of frame: precision, height, width
            h, w = struct.unpack(">HH", b[i + 5:i + 9])
            return w, h
        i += 2 + length
    raise ValueError("no image size found")


def strip_html(s):
    return re.sub(r"<[^>]+>", "", s or "").strip()


def main():
    names = [f["name"] for f in json.load(open(os.path.join(ROOT, "resources/jsonData/regs.json")))["fish"]]
    missing = set(TITLES) - set(names)
    assert not missing, f"TITLES keys not in regs.json: {missing}"
    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        os.remove(os.path.join(OUT, old))

    # Article -> lead image. pageimages returns free images only by default (pilicense=free).
    lead = {}
    titles = list(TITLES.values())
    for i in range(0, len(titles), 50):
        q = api("en.wikipedia.org", titles="|".join(titles[i:i + 50]), prop="pageimages", piprop="name", redirects=1)
        alias = {t: t for t in titles[i:i + 50]}
        for m in q.get("normalized", []) + q.get("redirects", []):
            for k, v in list(alias.items()):
                if v == m["from"]:
                    alias[k] = m["to"]
        byname = {p["title"]: p for p in q["pages"]}
        for t, final in alias.items():
            p = byname.get(final, {})
            if "pageimage" in p:
                lead[t] = (final, p["pageimage"])

    credits = []
    for name in names:
        t = TITLES.get(name)
        if t not in lead:
            if t:
                print("no free lead image:", name, "->", t)
            continue
        article, file = lead[t]
        q = api("commons.wikimedia.org", titles="File:" + file, prop="imageinfo",
                iiprop="url|extmetadata", iiextmetadatafilter="Artist|LicenseShortName", iiurlwidth=330)
        page = q["pages"][0]
        if page.get("missing") or "imageinfo" not in page:  # local (non-Commons) file: skip
            print("not on Commons:", name, file)
            continue
        info = page["imageinfo"][0]
        rid = "p_" + re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
        fn = rid + os.path.splitext(urllib.parse.urlparse(info["thumburl"]).path)[1].lower()
        open(os.path.join(OUT, fn), "wb").write(get(info["thumburl"]))
        meta = info.get("extmetadata", {})
        credits.append({"name": name, "article": article, "image": fn, "file": info["descriptionurl"],
                        "artist": strip_html(meta.get("Artist", {}).get("value")),
                        "license": meta.get("LicenseShortName", {}).get("value", "")})
    json.dump(credits, open(os.path.join(ROOT, "data", "photos.json"), "w"), indent=1, ensure_ascii=False)
    print(f"{len(credits)} photos")


def ascii(s):
    """Watch fonts only reliably carry ASCII (see check_data.py): fold accents, drop the rest."""
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()


def generate():
    """photos.json + downloaded images -> photos.xml (per-device scaling) and Photos.mc (lookup + credit)."""
    xml, rows = [], []
    for c in json.load(open(os.path.join(ROOT, "data", "photos.json"))):
        rid = os.path.splitext(c["image"])[0]
        w, h = dims(open(os.path.join(OUT, c["image"]), "rb").read())
        # Full BOX width, then PhotoTitle crops top/bottom (usually just water) to BOX height, but never
        # more than CROP of the photo: tall subjects get narrower instead.
        k = min(BOX[0] / w, BOX[1] / (h * (1 - CROP)))
        # Percent of the screen, so the compiler re-scales for each product's resolution.
        xml.append(f'    <bitmap id="{rid}" filename="{c["image"]}" scaleX="{w * k / SCREEN:.2%}"'
                   f' scaleY="{h * k / SCREEN:.2%}" scaleRelativeTo="screen"/>')
        pictured = re.sub(r"\s*\(fish\)$", "", c["article"])
        artist = ascii(c["artist"]) or "Unknown"
        credit = (f"Pictured: {pictured}. Photo: {artist[:80]}, {ascii(c['license'])}, via Wikimedia Commons "
                  f"({ascii(urllib.parse.unquote(c['file'].rsplit('/', 1)[1]))})")
        rows.append(f'        {json.dumps(c["name"])} => [Rez.Drawables.{rid}, {json.dumps(credit)}],')
    open(os.path.join(OUT, "photos.xml"), "w").write("<drawables>\n" + "\n".join(xml) + "\n</drawables>\n")
    open(os.path.join(ROOT, "source", "Photos.mc"), "w").write(
        "import Toybox.Lang;\n\n"
        "// Generated by data/photos.py; edit TITLES there and re-run instead of editing this.\n"
        "//! Species name -> [bitmap, credit], or null when the entry has no photo.\n"
        "function photo(name as String) as Array? {\n"
        "    return ({\n" + "\n".join(rows) + "\n    } as Dictionary<String, Array>)[name];\n}\n")


if __name__ == "__main__":
    if "--no-fetch" not in sys.argv:
        main()
    generate()
