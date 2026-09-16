# Fish Regs — Descent G2

Connect IQ watch app for a Southern California spearfisher: browse saltwater species by group, pick one,
read its 2026 California recreational ocean sport fishing regulation (bag, size, season, spear status,
notes, governing 14 CCR section). Read-only, offline, no permissions. Sideloaded like the apnea apps.

> Not legal advice. Regs change in-season and the app does not list MPAs. Data is compiled from CDFW
> pages and Title 14 CCR text as of the `asof` date shown under About. Verify at wildlife.ca.gov before you dive.

## Use on the watch

Group menu → species menu (sublabel shows bag | size) → field menu → full text. BACK goes up a level.
UP/DOWN or touch scroll; START/tap selects. Full-text screens page with UP/DOWN (counter at the bottom).
Rules & Spearfishing entries open straight to their text. Verified in the Connect IQ simulator (descentg2);
83 KB of the 764 KB app budget in use.

## Build and sideload

Toolchain is Windows-side (Connect IQ SDK under `%AppData%\Garmin\ConnectIQ`, JDK 17 in `C:\Program Files\Java`,
developer key in `C:\Users\clamd\Documents\devkeys`), driven from WSL:

```
./build.sh                                   # -> bin/FishRegs.prg (descentg2)
python3 check_data.py                        # data sanity: fields, lengths, watch-safe characters
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w sideload.ps1)"   # USB/MTP copy into GARMIN/APPS
```

Manual sideload: plug the G2 in over USB, drag `bin/FishRegs.prg` into `This PC > Descent G2 > GARMIN > APPS`, eject.
If the watch doesn't enumerate as a drive, reseat the charging clip. A `.prg` can vanish from APPS after the
watch installs it; that is normal.

Simulator: start `simulator.exe` from the SDK `bin`, then
`java -classpath monkeybrains.jar com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux -f bin\FishRegs.prg -d descentg2 -s <sdk>\bin\shell.exe`.

## Data

`resources/jsonData/regs.json` is the whole dataset: `asof` plus a `fish` array of
`{name, group, bag, size, season, spear, notes, src}`. Rule entries leave bag/size/season/spear empty.
Groups appear in the menu in first-seen order. Edit the JSON, run `check_data.py`, rebuild.

`data/sources.json` keeps the citations (URL + verbatim quote) behind every entry, so a value can be
re-checked without redoing the research. `data/README.md` says how the data was produced, which entries
were independently verified (Bass & Reef Fish and Pelagics in full; the rest researcher + spot checks),
and how to resume the verification workflow.

Scope: south of Point Conception (34°27'N) to the Mexico border, Channel Islands included. Where a rule
differs for divers vs boat anglers, the diver rule is stated first.

## Layout

```
manifest.xml, monkey.jungle        Connect IQ project (product descentg2, minApiLevel 3.3.0)
source/FishRegsApp.mc              loads regs.json once; app entry
source/FishMenus.mc                group -> species -> field menus (native Menu2)
source/FieldView.mc                one paged text screen (round-screen word wrap)
data/                              research output, compose script, citations, provenance notes
resources/jsonData/regs.json       the data
check_data.py, build.sh, sideload.ps1
```
