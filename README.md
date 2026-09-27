# Fish Regs — Garmin Descent

Connect IQ watch app for a Southern California spearfisher: browse saltwater species by group, pick one,
read its 2026 California recreational ocean sport fishing regulation (bag, size, season, spear status,
notes, governing 14 CCR section). Read-only, offline, no permissions. Runs on the Descent G2, Mk3 (43/51 mm)
and Mk2 / Mk2i / Mk2 S; sideloaded or packaged for the Connect IQ store.

> Not legal advice. Regs change in-season and the app does not list MPAs. Data is compiled from CDFW
> pages and Title 14 CCR text as of the `asof` date shown under About. Verify at wildlife.ca.gov before you dive.

## Use on the watch

Group menu → species menu (sublabel shows bag | size) → field menu → full text. For 96 species entries the field
menu has the species name and an ID photo across its top (a CustomMenu, since Menu2's title is too small for
one), plus a Photo credit row. BACK goes up a level.
UP/DOWN or touch scroll; START/tap selects. Full-text screens page with UP/DOWN (counter at the bottom).
Rules & Spearfishing entries open straight to their text. Verified in the Connect IQ simulator on every
product (all 96 photos load); ~106 KB of 764 KB in use on the G2/Mk3, ~125 KB of 1.3 MB on the Mk2.

Not supported: Descent G1 (96 KB app memory; the whole regs.json is held in memory, so it would need the data
split per group first) and Mk1.

## Build and sideload

Toolchain is Windows-side (Connect IQ SDK under `%AppData%\Garmin\ConnectIQ`, JDK 17 in `C:\Program Files\Java`,
developer key in `C:\Users\clamd\Documents\devkeys`), driven from WSL:

```
./build.sh                                   # -> bin/FishRegs.prg (descentg2)
DEVICE=descentmk2 ./build.sh                 # -> bin/FishRegs.prg for another manifest product (simulator)
./build.sh store                             # -> bin/FishRegs.iq, release build of all products (store upload)
python3 check_data.py                        # data sanity: fields, lengths, watch-safe characters
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w sideload.ps1)"   # USB/MTP copy into GARMIN/APPS
```

Manual sideload: plug the G2 in over USB, drag `bin/FishRegs.prg` into `This PC > Descent G2 > GARMIN > APPS`, eject.
If the watch doesn't enumerate as a drive, reseat the charging clip. A `.prg` can vanish from APPS after the
watch installs it; that is normal.

Simulator: start `simulator.exe` from the SDK `bin`, then
`java -classpath monkeybrains.jar com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux -f bin\FishRegs.prg -d descentg2 -s <sdk>\bin\shell.exe`
(use the same `-d` as the build).

Store: upload `bin/FishRegs.iq` at apps.garmin.com (developer account; listing text, screenshots and icon are
entered there). The photo credit rows and the About line are the in-app attribution the CC BY / BY-SA photos
require once the app is distributed.

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

## Photos

`data/photos.py` maps each species name to a Wikipedia article and pulls that article's lead image from
Wikimedia Commons (free licenses only) into `resources/photos/`, recording credits (author, license, file page)
in `data/photos.json`. From those it generates `resources/photos/photos.xml` and `source/Photos.mc`
(name -> bitmap + credit text). Edit `TITLES` and re-run to change a photo; after changing `BOX`/`CROP`,
`python3 data/photos.py --no-fetch` regenerates without downloading.

Sizing: `BOX` is tuned on a 390 px screen and given to the compiler as a percent of the screen, so each
product gets its own pre-scaled bitmap (no runtime scaling on these devices). Photos are scaled to the full
box width and PhotoTitle clips top and bottom (mostly water) to fit, losing at most `CROP` of the height.
256-color palette, uncompressed: `compress="true"` produced bitmaps that crash on load for some photos.

## Layout

```
manifest.xml, monkey.jungle        Connect IQ project (product descentg2, minApiLevel 3.3.0)
source/FishRegsApp.mc              loads regs.json once; app entry
source/FishMenus.mc                group -> species -> field menus (native Menu2)
source/FieldView.mc                one paged text screen (round-screen word wrap)
source/PhotoTitle.mc               photo field menu: tall photo title + hand-drawn items
source/Photos.mc                   generated by data/photos.py: species name -> bitmap, caption
resources/photos/                  generated by data/photos.py: images + photos.xml
data/                              research output, compose script, citations, provenance notes
resources/jsonData/regs.json       the data
check_data.py, build.sh, sideload.ps1
```
