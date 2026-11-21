# What Valve's maps taught us (a digest)

The short version of the lessons, by topic; the numbers and maps are in each lesson (`python3 _dev/tools/map_lessons.py --find ID`). Moved out of `docs/dev/map-ingestion.md` on 21 November to keep that guide under 20 KB. When a headline number across maps moves (`map_ingest.py aggregate`), update it here.

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
- **Canals** (tag `canal`, `valve_canals/pictures.json`; built 21 November, `docs/dev/map-modules.md`, the shared
  dressing): 512 wide in the city, 1024 in the airboat canals; a dished floor; walls about 384; walk ledges 72 wide at
  212 up; outfalls 128 across about 384 apart; cage lamps about 800 apart. The owner's 45 degree banks kept on the
  plain city stretches, the canal kept dry; steps 8 by 12.
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
