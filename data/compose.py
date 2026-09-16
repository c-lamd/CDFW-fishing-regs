#!/usr/bin/env python3
"""Turn the research workflow's raw output into the watch dataset.
Reads data/gathered.json (+ data/workflow_results.json for verifier verdicts), applies the edits below,
writes resources/jsonData/regs.json (what the watch shows) and data/sources.json (citations per entry).
Run: python3 data/compose.py && python3 check_data.py"""
import json, re, unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASOF = "2026-09-15"
gathered = json.load(open(ROOT / "data/gathered.json", encoding="utf-8"))
verdicts = json.load(open(ROOT / "data/workflow_results.json", encoding="utf-8"))

# Season strings for groundfish, Southern Management Area 2026. Divers are exempt from all of it.
NEAR = "Divers all year. Boat: Apr-Jun all depths, Jul-Sep <50 fm, else closed"
SHELF = "Divers all year. Boat: Apr-Jun, Jul-Sep <50 fm, Oct-Dec >50 fm, Jan-Mar closed"

DROP = {
    "Sablefish (black cod)", "Dover/English sole, arrowtooth",   # deepwater, never speared
    "Sand crabs (bait)", "Ghost shrimp (bait)",                    # bait digging, not diving
    "Pacific halibut",                                             # not present south of Pt Conception; season unresolved
}
SHARKS = {"Leopard shark", "Soupfin shark", "Shortfin mako shark", "Thresher shark", "Blue shark", "Sixgill shark",
          "Broadnose sevengill shark", "White shark", "Bat ray", "Shovelnose guitarfish", "Pacific angel shark",
          "Horn shark", "Swell shark", "Smoothhounds (gray/brown)", "Skates (big/California/longnose)", "Spiny dogfish"}
RENAME = {"Skates (big/California/longnose)": "Skates (big/CA/longnose)",
          "Soles (rock/sand/butter/curlfin)": "Soles (rock/sand/butter)",
          "Lobster card, gauge, no spear": "Lobster report card & gauge"}
GROUP_ORDER = ["Bass & Reef Fish", "Rockfish & Groundfish", "Pelagics", "Flatfish & Surf", "Sharks & Rays",
               "Lobster & Inverts", "Rules & Spearfishing"]

# Field overrides. Verifier corrections first (see data/workflow_results.json), then trims for the watch.
EDIT = {
    "CA scorpionfish (sculpin)": {
        "notes": "Federal groundfish but exempt from season/depth closures; not in the RCG 10. No take in the 8 SoCal Groundfish Exclusion Areas (offshore banks, §27.50). Boat/kayak: descending device must be aboard when possessing (§27.20(b)(2)). Venomous spines. Fillets: entire skin attached.",
        "src": "14 CCR §28.54, §27.50, §27.20(b)(2)"},
    "California barracuda": {
        "notes": "No undersized tolerance. Boat fillets: min 17 in w/ 1 in sq patch of silver skin. AL (§1.62) = base of 1st dorsal spine to end of longest tail lobe; used when the head is removed, tail must stay on."},
    "California spiny lobster": {
        "season": "Oct 2, 2026 6:00 pm - Mar 17, 2027 (closed now)",
        "notes": "Divers: hands only, no hooked device; a spear may be carried but not used on lobster. Measure in the water; shorts never leave the water or enter a bag. Keep whole. Carry a gauge. Report card: fill in BEFORE entering the water. Hoop nets max 5/person, 10/vessel."},
    "Lobster report card & gauge": {
        "bag": "", "size": "", "season": "", "spear": "",
        "notes": "Report card required at any age; on you, in the boat, or within 500 yd of your shore entry. Record date, location and gear code BEFORE diving; count kept AFTER. Return or report by Apr 30 or pay the non-return fee. Carry a gauge: 3.25 in carapace, measured in the water; never surface a short. Hands only, no spear or hooked device."},
    "Abalone (all species)": {
        "notes": "All species (red, green, pink, black, white). Booklet (Jul 17, 2026): all ocean waters closed; abalone may not be taken or possessed, closure runs to Apr 1, 2036. Southern summary: no abalone may be taken at any time in Southern California."},
    "Other invertebrates (general)": {
        "notes": "§29.05: 35 per species unless a specific limit; no closed season or size unless listed. No take of any invert in state marine reserves; SMCAs vary. Intertidal (high tide mark to 1,000 ft seaward): only listed species (lobster, crabs, urchins, octopus, mussels, rock scallop, limpets, clams, snails)."},
    "General finfish bag limit": {
        "bag": "",
        "notes": "20 finfish total, max 10 of any one species, where no species limit is listed; possession = daily bag. Species with their own limit (bass, sheephead, halibut, RCG...) use that instead. No limit: Pacific/jack mackerel, sardine, anchovy, queenfish, sanddabs, skipjack, topsmelt, jacksmelt."},
    "Spear-prohibited species": {"spear": ""},
    "Spears & harpoons (§28.95)": {"spear": ""},
    "Diver groundfish exemption": {"season": "", "spear": ""},
    "Length definitions (TL/FL/AL)": {
        "season": "",
        "notes": "TL: tip of head (mouth closed, fish flat) to end of longest tail lobe. FL: tip of head to center of tail fork. AL (alternate length): base of the foremost first-dorsal spine to end of longest tail lobe, used when the head is removed (bass 10 in, white seabass 20.5 in, barracuda 17 in).",
        "src": "14 CCR §1.62"},
    "Marine Protected Areas": {"spear": ""},
    "Hours of take (day/night)": {"spear": ""},
    "Descending device (boats)": {"spear": ""},
    "Harbors & bays": {"spear": ""},
    "Rockfish (RCG complex)": {"season": NEAR},
    "Lingcod": {"season": SHELF},
}
for n in ["Vermilion/sunset rockfish", "Canary rockfish", "Bocaccio"]:
    EDIT.setdefault(n, {})["season"] = SHELF
for n in ["Copper rockfish", "Treefish", "Gopher rockfish", "Black-and-yellow rockfish", "Kelp rockfish", "Grass rockfish",
          "Brown rockfish", "Olive rockfish", "Blue/deacon rockfish", "Cabezon", "Greenling (kelp/rock)"]:
    EDIT.setdefault(n, {})["season"] = NEAR

def ascii_clean(s):
    s = s.replace("–", "-").replace("—", "-").replace("‑", "-").replace("½", "1/2")
    s = s.replace("‘", "'").replace("’", "'").replace("“", '"').replace("”", '"').replace("×", "x")
    s = s.replace("≤", "<=").replace("≥", ">=").replace(" ", " ")
    out = []
    for c in s:
        if ord(c) < 127 or c in "§°":
            out.append(c)
        else:
            base = unicodedata.normalize("NFKD", c).encode("ascii", "ignore").decode()
            out.append(base or "?")
    return re.sub(r"[ \t]+", " ", "".join(out)).strip()

# Which verifier lenses passed each entry (empty = gather only, no independent verification completed).
verified = {}
for label, val in verdicts.items():
    if label.startswith("verify:") and isinstance(val, dict):
        for r in val.get("results", []):
            verified.setdefault(r["name"].strip().lower(), []).append((label.split(":")[-1], bool(r.get("ok"))))

fish, sources = [], []
for e in gathered:
    name = e["name"]
    if name in DROP:
        continue
    row = {k: e.get(k, "") for k in ["name", "group", "bag", "size", "season", "spear", "notes", "src"]}
    if name in SHARKS:
        row["group"] = "Sharks & Rays"
    elif row["group"] == "Flatfish, Surf & Sharks":
        row["group"] = "Flatfish & Surf"
    row.update(EDIT.get(name, {}))
    row["name"] = RENAME.get(name, name)
    row = {k: ascii_clean(v) for k, v in row.items()}
    fish.append(row)
    sources.append({"name": row["name"], "group": row["group"], "confidence": e.get("confidence"),
                    "verified_by": verified.get(name.strip().lower(), []),
                    "edited": name in EDIT, "citations": e.get("citations", [])})

order = {g: i for i, g in enumerate(GROUP_ORDER)}
fish.sort(key=lambda r: order[r["group"]])   # stable: keeps the researcher's order within a group
sources.sort(key=lambda r: order[r["group"]])
json.dump({"asof": ASOF, "fish": fish}, open(ROOT / "resources/jsonData/regs.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=0)
json.dump({"asof": ASOF, "entries": sources}, open(ROOT / "data/sources.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
nv = sum(1 for s in sources if s["verified_by"] and all(ok for _, ok in s["verified_by"]))
print(f"wrote {len(fish)} entries in {len(GROUP_ORDER)} groups; {nv} fully verified by 2-3 independent lenses, rest gather-only")
