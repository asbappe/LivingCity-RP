# Civil notice posters: a brief for the artwork

Six propaganda posters for Living City, a Half-Life 2 roleplay server. They hang on walls in the city (the editor's "Fixture: Civil notice poster"), and each one shows the poster that fits the official thing closest to it. Give this whole file to whoever (or whatever) makes the pictures.

## The world they belong to

- An occupied city in a grim near future: grey concrete housing blocks, rain, Eastern European architecture, everything worn and rationed. Citizens wear blue Union uniforms, live in assigned rooms, eat rations from machines, and are watched by masked Civil Protection officers and flying scanners.
- The city is run for the occupiers by **the City Administrator, a woman** in her fifties: composed, maternal on the surface, cold underneath. Her office prints these posters.
- **The tone:** kind on the surface, a threat underneath. Warm words, a hard edge. The posters always sound reasonable, and always remind you that someone is watching.

## Style, shared by all six

- **Look:** mid-century state propaganda (Soviet and Eastern Bloc posters of the 1950s to 1970s), cleaned up by a cold, futuristic regime. Flat shapes, strong diagonals, bold blocky sans-serif lettering, a few strong colours on a muted ground. Screen-printed, not photographic.
- **Palette:** dark slate blue, steel grey and off-white, with **one strong accent per poster** (signal red, or a cold cyan). Slightly faded inks.
- **The regime's mark:** a small angular emblem in a corner (a hard, segmented, shield-like or claw-like symbol) and a footer line: **"Office of the City Administrator"**.
- **Wear:** slightly worn paper: soft creases, faint water stains, edges a little lifted, a touch of grime. Not torn to pieces: the city keeps its posters up.
- **People** on the posters are idealised and calm: square-jawed workers in blue Union overalls, a tidy mother and child, a stern Civil Protection officer in a gas mask (seen as protector, not monster). Faces calm and content, eyes up and forward.

## Technical

- **Shape:** portrait, **3 wide by 4 tall**. In game it's about 88 cm wide by 118 cm tall on the wall.
- **Size:** **768 x 1024 pixels** is plenty (1536 x 2048 at most). Keep each file under about 1 MB, since every player downloads them.
- **Format:** PNG or JPG, no transparency needed, the whole image filled edge to edge (it's the full poster, paper included).
- **File names** (exactly these): `dispenser.png`, `commissary.png`, `intake.png`, `water.png`, `law.png`, `curfew.png`.
- **Where they go on the server:** `garrysmod/materials/livingcity/posters/`. Then press FastDL sync on the host panel and change the map. A poster without its picture shows the plain drawn notice instead, so they can be added one at a time.
- **Lettering:** image models often misspell words. Either check every word carefully, or make the picture without text and add the words in an image editor afterwards. The words below are the ones to use (players can read the same text by pressing E on the poster).

## The six posters

### 1. `dispenser.png`: Labor earns rations
- **Hangs:** beside the ration dispenser.
- **Headline:** LABOR EARNS RATIONS
- **Smaller text:** One ration card for each ration. One card for each completed Union shift. No card, no ration.
- **Picture:** a worker in blue overalls handing a small ration card into a gleaming wall-mounted dispenser; a neat grey ration packet sliding out to him. Behind him, a row of identical workers queueing in perfect order. A factory skyline and a raised hand of authority in the background.
- **Accent:** signal red (the card, the headline).
- **Feeling:** fair exchange. You get what you work for, and only that.

### 2. `commissary.png`: The Commissary serves the compliant
- **Hangs:** at the Commissary terminal.
- **Headline:** THE COMMISSARY SERVES THE COMPLIANT
- **Smaller text:** Food, water, medicine and tablets, for credits. Credits are earned by work.
- **Picture:** a clean counter stocked with neat rows of tins, bottles of water and small medicine vials; a smiling citizen accepting a parcel from a gloved hand through a hatch. On the wall behind, a portrait of the Administrator looking on approvingly.
- **Accent:** cold cyan.
- **Feeling:** plenty, for those who behave.

### 3. `intake.png`: All arrivals must register
- **Hangs:** at Civil Intake and the Housing and Labor desks.
- **Headline:** ALL ARRIVALS MUST REGISTER
- **Smaller text:** Unregistered persons receive no rations, no work and no housing. Carry your papers at all times.
- **Picture:** a train platform; new arrivals with suitcases stepping off a train into a pool of light, guided by a Civil Protection officer's outstretched arm toward a registration desk. In the foreground, a hand holding up identity papers with a photo and a stamp.
- **Accent:** signal red (the stamp).
- **Feeling:** welcome, with conditions.

### 4. `water.png`: Untreated water carries parasites
- **Hangs:** by sinks and water machines.
- **Headline:** UNTREATED WATER CARRIES PARASITES
- **Smaller text:** Drink only from approved taps and machines. Antiparasitic tablets are available at the Commissary.
- **Picture:** split down the middle. Left: murky canal water with dark, worm-like shapes in it, a cracked bottle. Right: a gleaming approved tap pouring clear water into a clean cup held by a healthy child. A thin red line divides them.
- **Accent:** cold cyan (the clean water) against sickly green-grey.
- **Feeling:** concern, with a hint of disgust. Only the regime keeps you safe.

### 5. `law.png`: Know the law
- **Hangs:** by the law board.
- **Headline:** KNOW THE LAW
- **Smaller text:** Ignorance of the law is no defence. The city's laws are posted here. Comply.
- **Picture:** a huge stone tablet or board of laws towering over a small crowd of citizens reading it, heads tilted up. A Civil Protection officer stands beside it, baton lowered, calm. Strong upward perspective so the law looms.
- **Accent:** signal red.
- **Feeling:** order. The rules are bigger than you.

### 6. `curfew.png`: Curfew is absolute
- **Hangs:** anywhere else (the default poster).
- **Headline:** CURFEW IS ABSOLUTE
- **Smaller text:** At the two-minute warning, return to your housing block. Do not run in the presence of Civil Protection.
- **Picture:** a night street under a searchlight beam; a citizen walking (not running) calmly home toward a lit housing block door, a mother ushering her child inside. High above, a scanner's eye glows. The windows of the block are warm and safe; the street is cold and empty.
- **Accent:** cold cyan (the searchlight) on deep blue-black.
- **Feeling:** home is safe. Outside is not.

## Don't

- No real-world flags, swastikas, hammers and sickles, or real political figures.
- No gore, and nobody shown being hurt: the threat is always implied, never shown.
- Not cartoony or glossy: these are worn, printed posters in a grim city.

## Eleven more, hung by hand

The Director of Propaganda hangs these with the poster roll (they never appear by themselves). Same style, same footer. File names: `work`, `loyalty`, `informants`, `contraband`, `radio`, `illness`, `infestation`, `housing`, `vortigaunt`, `recruit`, `administrator` (`.png` or `.jpg`). The Administrator is drawn after Judith Mossman: short auburn hair with a side part, a white roll-neck sweater. Their words are in `gamemodes/livingcity/entities/entities/lc_civposter.lua`. All seventeen pictures are already drawn (`materials/livingcity/posters/`, made by `node _dev/posters/gen.js OUTDIR`).

## The Resistance's answer

Each of the seventeen has a painted-over version, `<kind>_x` (a spray can on the poster shows it): words struck out or sprayed across by hand in white and orange paint (every line at its own tilt, uneven letters, runs), with a lambda. And four paste-ups of their own, rough sprayed and painted by hand on scrap paper, with a typed line under: `rebel_watch` (SHE WATCHES. WE SEE.), `rebel_leash` (THE RATION IS THE LEASH), `rebel_water` (DON'T DRINK THE WATER), `rebel_home` (THIS IS NOT YOUR HOME). All drawn by `_dev/posters/art3.js`.

## The posters that hint at dreams

Some plain curfew posters show a dream's poster instead (`docs/features/dream-posters.md`). Same style, with "SLEEP WELL, CITIZEN" where the others say "CIVIL NOTICE". File names: `dream_<codeword>` (`.png` or `.jpg`), `dream` for any dream without its own, `dream_x` painted over ("WAKE UP"). Their words are `LC.DreamPosterHints` in `sv_livingcity_dreamposters.lua`. The small words are one sentence. Drawn (`_dev/posters/dreams.js` to `dreams4.js`): every Nightmare and propaganda dream, `dream_lamarr`, `dream_cheese`, and `dream_forecast`, the melons' one, which hangs only inside that dream, never in the city.

## Her slogan

`neighbour` (and `neighbour_x`, painted over: HATE THE TRAITOR struck out and HATE THE ADMINISTRATOR sprayed under it, the owner's wording): **LOVE YOUR NEIGHBOUR, HATE THE TRAITOR**, the owner's own slogan (14 November), with no smaller words. Two neighbours with calm faces: a younger man hands an older woman a framed portrait of the Administrator, a red heart above it between them (the owner's idea, 14 November; no handshake, no drawn smiles); beside them, in the dark, a Resistance face struck out in red. It is on the Director of Propaganda's poster roll with the eleven above. Drawn by `_dev/posters/slogan.js`.
