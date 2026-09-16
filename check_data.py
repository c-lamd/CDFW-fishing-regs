#!/usr/bin/env python3
"""The one check: fails if regs.json breaks what the watch UI assumes. Run: python3 check_data.py"""
import json, sys

KEYS = ["name", "group", "bag", "size", "season", "spear", "notes", "src"]
# Field lengths the 390 px screen can show: menu labels/sublabels, and one TextArea page for notes.
LIMITS = {"name": 30, "group": 26, "bag": 60, "size": 60, "season": 80, "spear": 50, "notes": 300, "src": 40}
OK_CHARS = set("§°")  # non-ASCII the Garmin system fonts are known to carry; everything else must be ASCII

d = json.load(open("resources/jsonData/regs.json", encoding="utf-8"))
fish = d["fish"]
errs = []
names = set()
for f in fish:
    n = f.get("name", "?")
    for k in KEYS:
        v = f.get(k)
        if not isinstance(v, str):
            errs.append(f"{n}: {k} missing or not a string"); continue
        if len(v) > LIMITS[k]:
            errs.append(f"{n}: {k} is {len(v)} chars, max {LIMITS[k]}")
        bad = {c for c in v if ord(c) > 126 and c not in OK_CHARS}
        if bad:
            errs.append(f"{n}: {k} has characters the watch font may lack: {sorted(bad)}")
        if "PLACEHOLDER" in v:
            errs.append(f"{n}: {k} is placeholder text")
    if not f.get("name") or not f.get("group") or not f.get("notes") or not f.get("src"):
        errs.append(f"{n}: name, group, notes and src are required")
    if f.get("bag"):  # a species row; rules leave bag/size/season/spear empty
        for k in ["size", "season", "spear"]:
            if not f.get(k):
                errs.append(f"{n}: species row missing {k}")
    if n in names:
        errs.append(f"{n}: duplicate name")
    names.add(n)
groups = sorted({f["group"] for f in fish})
if not d.get("asof"):
    errs.append("asof missing")
for e in errs:
    print("FAIL", e)
if errs:
    sys.exit(1)
print(f"ok: {len(fish)} entries, {len(groups)} groups, as of {d['asof']}")
