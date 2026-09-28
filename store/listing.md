# Connect IQ store listing (draft)

Paste into the app form at apps.garmin.com. Upload `bin/FishRegs.iq` (`./build.sh store`) and the
`screenshot-*.png` files in this folder (390x390, from the G2 simulator).

**Cover (hero) image:** `cover-1440x720.png`. Background: "Kelp forest, Channel Islands NMS", NOAA Photo Library, public
domain (commons.wikimedia.org/wiki/File:Kelp_forest,_Channel_Islands_NMS.jpg). If the form asks for another size,
re-render with `hero.ps1` (`-W`/`-H`; the background is not in the repo, download it from that page).
Don't use the CDFW logo anywhere: it implies endorsement.

**Icon:** `icon-1024.png` / `icon-512.png` / `icon-256.png` / `icon-128.png`, original artwork (`icon.ps1 -Size N`
renders any size).
**Screen images:** `screenshot-1..6-*.png`, 390x390 from the G2 simulator (same screen as the Mk3 43mm).

**App name:** SoCal Ocean Fishing Regs (shows as "SoCal Regs" on the watch)
**Type:** Device App · **Category:** Outdoor / Diving · **Price:** free
**Version:** 1.0.0 (manifest.xml)
**Devices:** Descent G2, Descent Mk3 43mm / Mk3i 43mm, Descent Mk3i 51mm, Descent Mk2 / Mk2i, Descent Mk2 S
**Permissions:** none. Works fully offline; collects and sends no data.

## Short description

Unofficial SoCal fishing and spearfishing regs on your Descent, kept current with CDFW regulations: bag, size,
season and spear rules, with ID photos. Works offline.

## Description

Check the rules before you pull the trigger. SoCal Ocean Fishing Regs puts California's recreational ocean fishing
regulations for the Southern Management Area (Point Conception to the Mexico border, Channel Islands
included) on your Descent, offline.

- 100+ species and rules in 7 groups: Bass & Reef Fish, Rockfish & Groundfish, Pelagics, Flatfish & Surf,
  Sharks & Rays, Lobster & Inverts, Rules & Spearfishing
- For each species: bag limit, size limit, season, whether spearfishing is allowed, notes, and the
  governing Title 14 CCR section
- ID photos for 96 species, right at the top of each species page
- Diver-specific rules stated first where they differ from boat anglers
- Spearfishing essentials: spear-prohibited species, diver groundfish exemption, fillet and length rules,
  lobster report card, hours of take
- No phone, no signal, no permissions needed

Regulations as of September 15, 2026 (shown under About).

**Unofficial, but kept current.** This is an independent app, not affiliated with or endorsed by the
California Department of Fish and Wildlife (CDFW). The regulations are compiled from CDFW's published
regulations and Title 14 of the California Code of Regulations, and each release is updated to match the latest
CDFW rules. The date the data was last checked is shown under About in the app.

Regulations can change mid-season, sometimes before an update reaches your watch, and the app does not list
Marine Protected Areas. It is a quick reference, not legal advice. Always confirm current regulations at
wildlife.ca.gov before you dive or fish.

Photos are from Wikimedia Commons under public domain and Creative Commons licenses. The author and license
for each photo are shown in the app under that species ("Photo credit").

## What's new (1.0.0)

First release.
