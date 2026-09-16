# Data provenance

`regs.json` on the watch is generated, not hand-written. Pipeline:

1. **Research workflow** (`workflow_results.json`, raw agent output): six researcher agents, one per species
   group, read the 2026 CDFW Ocean Sport Fishing Regulations booklet, the CDFW Southern district summary
   (effective Sept 1, 2026), the groundfish summary (June 23, 2026), the 2026 in-season changes page and the
   Title 14 CCR section text, and returned one entry per species with verbatim citations. Then three
   independent verifier agents per chunk of five entries (primary-law lens, CDFW-summary lens,
   recent-change skeptic) tried to refute every field. `gathered.json` is the researcher output.
2. **Compose** (`compose.py`): applies verifier corrections, trims wording to watch limits, splits sharks
   into their own group, drops species not found in SoCal freedive range, and normalizes characters to
   what the Garmin fonts render. Writes `../resources/jsonData/regs.json` and `sources.json`.
3. **Check** (`../check_data.py`): field presence, lengths, characters, duplicates.

## Verification status (2026-09-15)

The workflow hit the account's usage limit mid-run. What completed:

- **Fully verified by 2-3 independent lenses:** all of Bass & Reef Fish and most of Pelagics (29 entries).
  Only two corrections were needed, both to notes (scorpionfish descending-device rule; barracuda's
  alternate-length definition), which suggests the researcher output is reliable.
- **Researcher + spot checks only:** Rockfish & Groundfish, Flatfish & Surf, Sharks & Rays, Lobster & Inverts,
  Rules & Spearfishing. Spot-checked by hand against the CCR text: lobster season/bag/size/gear/report card,
  general 20/10 finfish rule, invertebrate 35 default and tidepool list, §28.90 spear exclusions, California
  halibut, and the Southern groundfish season/depth table with the diver exemption.

`sources.json` records per entry: confidence, which verifier lenses passed it (`verified_by`, empty = not
independently verified), whether compose edited it, and every citation (URL + verbatim quote).

Known open items: Pacific halibut season conflict (dropped from the app); local harbor ordinances on
spearfishing not verified (entry says so); white croaker OEHHA advisory wording from general knowledge.

## Re-running

Finish verification by resuming the workflow (cached agents replay; failed ones re-run), then rerun compose:

```
Workflow({scriptPath: "<session>/workflows/scripts/socal-spearfishing-regs-wf_34258e4d-7f2.js",
          resumeFromRunId: "wf_34258e4d-7f2", args: {"asof": "2026-09-15"}})
python3 data/compose.py && python3 check_data.py && ./build.sh
```

For a new regulation year, run the workflow fresh with a new `asof`, replace `gathered.json` and
`workflow_results.json`, review `compose.py`'s edits (season strings, drops) and rerun.
