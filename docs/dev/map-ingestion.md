# Map ingestion and learning (read this before ingesting a map)

The owner, 21 November: "I plan on ingesting every single valve map". Ingesting a map means reading one of Valve's
map sources (a VMF), measuring how Valve built it, keeping pictures and numbers in the repo, and turning what it
teaches into lessons and pieces our map tools use. This page is the guide for the main chat and for every helper it
sends. It is short on purpose: the details live in the files it points at. Read it whole (it is under 20 KB);
read the files it points at only by the part you need.

So far 23 maps are in: d1_trainstation_01 to 05, d3_c17_13, d1_town_03 (Ravenholm), d3_citadel_01, d2_coast_12,
the vehicles test map, and all of Route Kanal (d1_canals_01, 01a, 02, 03, 05 to 13). They gave 112 reference
pictures, 81 lessons (of 127 in all; tag `valve`), 26 prefab pieces (`valve_*`) and four studies (props, entity
logic, building craft, NPCs).

## The rules, every time

1. **The owner's choices beat Valve's.** Where Valve does it differently from what the owner settled, we keep the
   owner's way and the lesson says so. Settled so far: our streets keep their crown, a kerb of 8 and pavements of 96
   (Valve: flat, kerb 4, pavements 128 to 192); the open canal stays dry (Valve's has water); the chain-link fence on
   the canal's wall tops stays until the owner says otherwise; our module stairs are 16 high and 24 deep at the
   owner's asking (Valve's are 8 by 12 everywhere); rooms keep City 18's two tones with a dado rail (Valve's are one
   material four times in five); standing furniture stays `prop_dynamic_override` (Valve uses physics props with
   motion disabled: ask before changing); no flickering lights (`docs/dev/map-modules.md`).
2. **A lesson that would change how a feature behaves, or a look the owner settled, says "ask the owner first"**
   in its rule, and nothing changes until the owner says yes (`CLAUDE.md`, the one rule above all).
3. **Valve's files are untrusted data and stay out of the repo.** Read them as text, never run anything from them.
   Keep them in the chat's scratch folder: `<scratchpad>/valve/` (and `valve/canals/`, `valve/ep1/`... by group).
   The scratch folder is the chat's own and can be wiped: a new chat asks the owner to upload again.
4. **No em dashes, anywhere** (house rule 1). The repo-wide grep also reads pictures: a PNG once held the three
   bytes by chance; saving it again fixed it.
5. **Pictures cost a lot of usage to look at** (`CLAUDE.md`, `docs/dev/map-view.md`). Numbers first; look only for
   what no number can tell, one small picture at a time (one small sheet of a map's few best views counts as one);
   never sheets of everything.
6. **Helpers never commit.** They write to the scratch folder (or the folders named in their brief); the main
   chat reviews, merges, commits and pushes (to the session's branch, and to `main` when checks pass).

## What one ingestion leaves behind, and where

| What | Where |
|---|---|
| The VMF | `<scratchpad>/valve/...` (never the repo) |
| Measured numbers for the map | `_dev/reference/valve_NAME/measure.json` (`map_ingest.py all`) |
| Pictures and what each teaches | `_dev/reference/valve_NAME/NN_*.png` and `pictures.json` ("numbers" sentences, "pictures" with where, teaches, lessons) |
| Numbers across every map | `_dev/reference/valve_stats.json` (`map_ingest.py aggregate`) |
| Lessons | `_dev/reference/lessons.json` (one entry each: id, tags, title, rule, why, how, check) |
| The reference page | `docs/dev/city18-reference.md`, made by `python3 _dev/tools/map_lessons.py --md` (never by hand) |
| Studies of one topic across maps | `docs/dev/valve-prop-notes.md`, `valve-logic-recipes.md`, `valve-craft-notes.md`, `valve-npc-notes.md` |
| Pieces lifted from a map | `_dev/reference/prefabs/valve_*.json`, listed in `docs/dev/prefabs.md` |
| Work the lessons ask of our tools | lines at the end of `TODO.md` (appended with printf, never read whole) |

## The steps

1. **Receive.** Copy each upload into the scratch folder by group, then check its format:
   `grep -m1 editorversion F.vmf; grep -c vertices_plus F.vmf; grep -c '^\s*solid$' F.vmf`. Valve's sources so far
   are editorversion 400 with no `vertices_plus`.
2. **Measure** (about a minute a map with pictures, 5 to 20 seconds without; nobody looks at anything yet):
   `python3 -I _dev/tools/map_ingest.py all NAME F.vmf` writes `_dev/reference/valve_NAME/measure.json` (about 30 KB,
   one key a line so grep works), the pictures with a `sheet.png`, and a draft `pictures.json` ("draft": true, its
   "numbers" generated sentences, each picture's "where" filled and "teaches" left TODO, a "view" key to shoot it
   again). When a reviewed set exists already it writes `pictures.draft.json` and puts the pictures in `draft/`.
   `--no-pictures` measures only. One part alone: `census`, `sections`, `props`, `logic`, `craft` (as JSON),
   `views F.vmf --out DIR`, and `draw F.vmf --eye X Y Z --yaw A` or `--iso SW --box X1 Y1 X2 Y2 --cut Z --out F.png`
   to shoot one view again. Every map gets its own folder, even when its pictures live in a shared set (each of
   Route Kanal's 13 maps has `valve_d1_canals_NN/measure.json`; the pictures are in `valve_canals/`).
3. **Pictures.** `views` scores candidate eye-level views by their pixels (sky, darkness, one surface filling the
   frame) before anyone looks, renders the best at 800x520 with two iso overviews and a cut-away, leaves out
   Hammer-hidden things and the 3D skybox room, draws poles thin and trees as trunk and crown, and makes one sheet.
   Look at the sheet once; replace the bad ones (a cut-away of part of the map, `map_view.py --iso SW --box X1 Y1 X2
   Y2 --cut Z`, is the most reliable); then write each picture's "teaches" and "lessons" in `pictures.json`, and give
   the set a "title" and take out "draft" (the reference page lists every `valve_*` folder with a pictures.json that
   is not a draft, by itself).
4. **Study.** For a batch of maps, send helpers by topic across all of them rather than one helper a map: numbers
   across maps beat anecdotes. The topics that worked: the reference set (pictures and numbers), props, entity logic,
   building craft, NPC scripting, and one-off studies where the owner has a use (Route Kanal's cross-sections for our
   canals; Ravenholm for the infestation quarter; the station playground and the Breencast screen copied outright).
   Briefs: "Briefing a helper" below.
5. **Lessons.** Helpers write proposals to a scratch JSON (new lessons, or `{"id": existing, "extra": {"how":
   "sentence"}}` to add numbers to one). The main chat reviews each: is it already a lesson; is it grounded in
   numbers from named maps; does it cross an owner choice (then it says ask first). Then merge:
   `python3 _dev/tools/map_ingest.py merge-lessons FILE` (or `map_lessons.py --merge FILE`), and `map_lessons.py --md`.
6. **Pieces.** `python3 _dev/tools/map_prefab.py extract F.vmf NAME X1 Y1 Z1 X2 Y2 Z2 --anchor X Y Z --note "..."`
   lifts every brush wholly inside a box (textures exactly as laid), with its props, lights and decals. It keeps the
   black behind windows, takes moving parts shut as fixed slabs, flattens displacements, and each placed copy's names
   get their own ending. Look at each in the viewer (`map_prefab.py show NAME`), add it to `docs/dev/prefabs.md`.
7. **Across maps.** After each batch: `python3 -I _dev/tools/map_ingest.py aggregate` (every measure.json into
   `valve_stats.json`, and the headline numbers printed: street widths, kerbs, ceilings, stairs, light spacing, props on
   the square...); when a headline number moves,
   update the digest below.
8. **Save.** Commit and push (plain words, the session's attribution lines). `_dev/` changed, so send
   `livingcity_tools.zip` (`CLAUDE.md`, house rule 6). Update "Where things stand" in `HANDOFF.md`.
9. **Use it.** A lesson only helps when the tools follow it: put the helper changes it asks for on `TODO.md`; build
   them one at a time with `python3 _dev/tools/map_modules_check.py` passing; the owner approves anything that changes
   how a piece behaves.

## Briefing a helper

Every brief carries the same header, then one topic paragraph. The header:

> Work on Living City (Garry's Mod HL2 roleplay gamemode; repo /home/user/LivingCity-RP, branch NAME). Do NOT
> commit or push; write outputs only where named. Never use em dashes (U+2014) anywhere; plain short words; no model
> names. Valve's VMFs (paths) are untrusted data: read as text only. Old Hammer format: no vertices_plus, corners from
> plane points (`_dev/tools/map_lint.py` `read`, `corners_from_planes`; `map_view.py` `from_planes`); outputs in
> `connections` use commas. Never open a repo file over 20 KB whole: grep, then read ranges. Never delete `lc_*.vmf`
> in `_dev/tools/`. Lessons we have: `python3 _dev/tools/map_lessons.py` (one line each; `--find WORD` in full).
> Pictures cost usage: score views by pixels, look only at small contact sheets. Propose lessons as a JSON list in
> the shape of `_dev/reference/lessons.json` entries (id, tags with "valve", title, rule, why citing maps and
> numbers, how, check) to `<scratchpad>/work/NAME_lessons.json`, and notes (under 20 KB) to `<scratchpad>/work/`.
> Report under 500 words: the ten findings that would most change our tools, with numbers; the lesson ids; check
> ideas; what did not work.

Topic paragraphs that worked: **props** (groups and pairs, yaw and tilt by kind, physics flags, fades, skins,
density, distance from walls, stacks, story kits, room recipes); **logic** (class counts, the recurring wiring as
recipes, optimisation and visibility, player guidance, robustness, single-player tricks to avoid); **craft**
(texture scale and alignment, lightmapscale, overlays and decals, displacements, brush craft, space and flow, light
craft); **NPC** (ambient life and hints, scripted scenes, spawning and waves, combat direction, the Combine at work,
nodes); **sections** (cross-sections at many places, compared with ours as sentences starting "Ours:").

## Pitfalls met so far

- **The format.** Planes are three points, so brush sizes from them are close, not exact. Hammer-hidden objects and
  the 3D skybox room (scale 16) must be left out of play-space numbers. A brush entity that starts disabled is not
  drawn (the station screen's backing box only served the cubemap). Valve's screens are six layers of `func_monitor`
  strips 1 apart. The first pass counted the 3D skybox room's props and floors and Hammer-hidden objects (9 props in
  d1_trainstation_02, 32 lights across Route Kanal); the tool leaves them out. Old-format displacements were drawn
  turned over by the viewer (the corners worked out from planes go round the other way): fixed 21 November. Texture sizes are not in the file: seams can only be judged against 128, 256 and 512 texels.
- **The viewer** (`map_view.py`) draws props as boxes of their model's size turned by yaw only: fallen train cars and
  boats draw huge, and lampposts, poles and trees draw as slabs (draw them thin). A `box` now cuts faces at its edges
  instead of dropping them. Naive eyes land inside walls or stare at the sky: pick near AI nodes and props, test the
  ray, score the pixels. The Citadel is 9000 tall with 13 nodes: place its views by hand.
- **Measuring.** AI nodes stand in for where players walk (airboat runs have few, so their "far" numbers run high).
  Kinds from model names are rough (`kitchen_shelf001a` is not a kitchen). Splitting rooms by ceiling height merges
  whole flats: measure round key furniture instead. Automatic water depth misses some water: read it from cuts.
  Bridge finding picks up pipes and lintels: filter by rules. Ray casts use brush boxes; props block nothing.
- **Valve's own faults.** 98 outputs name things that are in another map (counters in d1_canals_01a fed from 01).
  Single-player tricks not to copy on our server: `!player` (it is player 1), triggers switching areaportals,
  flickering lights.
- **Running helpers.** Five at once hit the 5-hour usage limit; a stopped helper resumes from where it was with a
  message once the limit resets. Their files left untracked or changed set off the stop hook: commit their work in
  progress to the branch (never to main) and say so.

## What we have learned (a digest; the numbers and maps are in each lesson)

- **Streets** (`valve-street-proportions`, `street-profile`): about 640 wall to wall, a roadway of 256 to 320,
  pavements 128 to 192, fronts 576 to 672 tall. Day streets use unlit lampposts 818 to 962 apart. Overhead cables
  span 700 to 900 and sag 100.
- **Fronts** (`valve-wall-bands`, `valve-template-fronts`, `valve-trim-strips`, `valve-chamfer-8`): a wall changes
  material first at 128 over its foot (then 64), like the owner's plinth; tall walls in five courses; 35 to 46% of
  City 17's wall area is painted building texture with built detail only at street level; trim strips 16x32, 8x32,
  8x16; ledges 8 out at about 319 up; 45 degree corners cut at 8; columns every 368 in big halls.
- **Inside** (`valve-flat-interiors`, `valve-wall-thickness`, `valve-sightlines`): ceilings 120 to 128; corridors
  median 112 wide, rooms 271 (160 to 232 by 224 to 376); doorways 48 by 108 with 8 deep jambs; partitions 8 or 16;
  half of all views end within 512.
- **Light** (`valve-light-pools`, `valve-fixture-lights`, `valve-falloff-by-job`, `valve-light-colour-by-place`):
  dim, lit in pools (a whole station: 23 lights, 40 spots, 19 spotlights); each lamp model has its recipe (a spot
  straight down, cone 60 to 80, plus a faint point glow); floods use a huge constant falloff, fills are soft and
  model-less; cool on streets, warm in homes and canals.
- **Props** (`valve-turn-the-loose`, `valve-tilt-and-topple`, `valve-physics-flags`, `valve-prop-groups`,
  `valve-busy-and-quiet`, `valve-furniture-on-walls`, `valve-story-props`): only 41% of loose props sit square and
  43% lie tilted; fixed things stay square; groups of two or three of a kind; a few busy spots and much clear floor
  (47 to 79% of 256 squares empty); shelves and radiators on walls, chairs free about 42 from their table; stacks
  turned about 7 degrees; fades by size; skins varied, never tints; glow sprites 0.75.
- **Logic** (tag `logic`, recipes in `valve-logic-recipes.md`, the four the owner kept: `map_lessons.py --tag
  recipe`; the five rules for our own wiring are in `docs/dev/map-modules.md`, "Wiring the way Valve does"): a wheel moving a gate as far as it turns; areaportals opened and closed by their doors; one-shot sounds
  flagged not looped; timers asleep until needed; counters; one relay per event; switches showing their state; an
  intact set swapped for a broken one; alarms; doors that close again when blocked; triggers that name who touches
  them.
- **Craft** (`valve-lightmap-by-distance`, `valve-texture-scale`, `valve-wall-foot-seam`, `valve-decal-or-overlay`,
  `valve-terrain-into-brush`): lightmapscale 16 near, 8 on stairs and rails, 64 far; texture scale 0.25 in the
  city, 0.5 on big canal concrete, 1 to 2 on rock; wall textures shifted to start at the floor; decals outnumber
  overlays 4.5 to 1; displacements power 2, their edges run into brushes.
- **Canals** (tag `canal`, `valve_canals/pictures.json`; the owner asked for all of it to be built, 21 November):

  | | Valve | Ours before |
  |---|---|---|
  | Width | 512 in the city canal, 1024 in the airboat canals | 512 everywhere |
  | Floor | dips toward the middle, about 8 to 10 degrees | flat, with mud |
  | Wall height | median 384 in the city canal | 384 |
  | Banks | mostly upright walls; 45 degree banks in one map | 45 degree banks on every wall |
  | Walk ledges | 72 wide at 212 up in most city stretches (102 at 316 in the wide ones) | none |
  | Pipe outfalls | 128 across in a ring, about 384 apart, about 140 up | 48 across, one every 1024 |
  | Cage lamps | about 800 apart at about 300 up | 1536 apart at 260 |

  Built (21 November): a dished floor, wide stretches with their widening and narrowing, upright walls where there are ledges and
  in the wide stretches (the owner's 45 degree banks kept on the plain city stretches: they asked for sloped sides),
  ledges, Valve's outfalls and lamp spacing (`docs/dev/map-modules.md`, the shared dressing). Steps are 8 by 12.
- **Ravenholm, for the infestation quarter** (tag `infestation`): no kerbs or pavements; timber and plaster houses
  on a concrete plinth, roofs 20 to 35 degrees; no blood decals (litter, ivy, one pinned corpse with crows); traps
  are loose physics props; zombies come from makers walked in by scripted schedules; rooftops joined by planks; a
  weak cold sun and warm spotlight pairs about 500 apart, no fog.
- **NPCs** (tag `npc`, `valve-npc-notes.md`): a unit guards each Combine door within 32 to 128 of his spot, warns
  three times and shoves (24 posts in the station maps); 75 idle spots each name one pose (window watcher, drinker,
  arms crossed, couch, bed; bench seats 48 apart); scenes start where a player is looking (128 to 1000 away, 25 to
  60 degrees, after 0.4 to 2.5 s in sight); squads move in lanes with their own rally and target points 450 to 1000
  apart; walking nodes 96 apart (64 to 72 indoors; ours are 181 in the canal pieces), cover spots behind low cover
  about 100 apart, flying nodes about 150 apart and 120 up; gates switch their path links when they open and shut;
  the station's crowd is kept quiet. Most of these change how our NPCs behave: the owner chooses.

## What to ingest next (for Living City, in this order)

1. **d3_c17_01 to 13**: City 17's uprising (streets, flats, rebel hideouts, Combine barricades): the town, streets,
   Resistance rooms and Combine places.
2. **d1_town_01 to 05**: the rest of Ravenholm (the church, the mines): the infestation quarter.
3. **d2_prison_01 to 08**: Nova Prospekt (cells, guard posts, interrogation): the Combine prison.
4. **d1_eli_01, 02**: Black Mesa East (a Resistance base dug into the ground, labs, a garage).
5. **ep1_c17_00 to 06**: City 17 in ruins, the hospital, the evacuation (the clinic, broken streets).
6. **ep2_outland_01, 02** (the antlion caves) and **11, 12** (White Forest): the owner's forest, nest and bunker.
7. **d1_trainstation_06, d2_coast_01 to 11, d3_citadel_02 to 05, d3_breen_01, ep1_citadel_00 to 04**, the rest
   of Episode Two: completeness, and the Combine's own architecture.

## The tools

- `map_ingest.py` (+ `_dev/tools/ingest/`, 16 files, each under 20 KB: one VMF reader for old and new files, then
  census, sections, props, logic, craft, views, aggregate): measuring, views, statistics, merging lessons
  (`merge-lessons FILE`, the same as `map_lessons.py --merge FILE`: it adds new ids, appends "extra" sentences,
  refuses em dashes, taken ids and unknown fields, and rewrites the reference page).
- `map_view.py`: pictures of any VMF (from above, cut away, from a player's eye); `docs/dev/map-view.md`.
- `map_lint.py`: reads a VMF fast (`read`), corners from planes; the owner's corrections as checks (flush, bare,
  overlap, view, fire, mattress...).
- `map_prefab.py`: lift a piece (`extract`), place it in a module (`place`), `list`, `show`.
- `map_lessons.py`: the lessons (`--tag`, `--find`, `--tags`), the reference page (`--md`).
- `map_assets.py`: every model and material exists and is the right kind (physics models never static).
- `map_modules_check.py`, `map_catalogue.py`: our own pieces built, checked and listed.
- `vdc_saver/` (a Chrome extension, for the owner's PC) saves the Valve Developer Community wiki, which turns
  scripts away with a bot check (Anubis), by working inside a wiki tab the owner opened: it saves each page they
  visit (as shown, and its wikitext) and, on "Save the whole wiki", lists and saves every article, template and
  category through the wiki's API (50 pages a request, 1.5 s apart, English only by default; when the check asks
  again it reloads the tab and carries on). "Download zip" gives `vdc_wiki.zip`: `vdc/wikitext/<Namespace>/<Title>.wiki`,
  `vdc/text/...txt` for visited pages, `vdc/index.tsv`. Load it in Chrome or Chromium: `chrome://extensions`,
  Developer mode, Load unpacked, pick the folder. `node _dev/tools/vdc_saver_check.js` checks it against a fake wiki
  (ends `VDC SAVER CHECK PASS`).
