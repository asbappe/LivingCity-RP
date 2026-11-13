# Posters that hint at dreams (13 November)

The owner, 12 November: "propaganda posters that hint at dreams. Posters in the city reflect and foreshadow the dreams (tonight's, or ones people have had)."

`sv_livingcity_dreamposters.lua`, the poster `entities/lc_civposter.lua`, tests `DreamPosterTests`.

- **Which posters:** only the city's own civil notice posters (the editor's "Civil notice poster") that would show the plain curfew notice, the one hung where no ration dispenser, Commissary, Civil Intake desk, water or law board is near. `lc_dream_posters` (0.25) of those show a dream's poster instead, a different few each day (worked out from the poster's place and the night's number, so a poster keeps its dream all day). Posters that teach a rule where it applies, and posters hung by hand (the Director of Propaganda's roll, the Resistance's paste-ups), never change. `lc_dream_posters 0`: none.
- **Which dream:** half of them foreshadow tonight's dream, the one the city would choose as the day stands (`LC.DreamPlanDecide`, `LC.DreamPlanNext`); half remember one of the last three dreams the city dreamt (never a test dream). With none dreamt yet since the map started, all foreshadow.
- **The words:** in the city's voice, a hint that never names the dream ("FORECAST: FAIR, WITH PRODUCE. Fresh fruit is a privilege of compliance. Do not look up for it."): every dream you play has its own (`LC.DreamPosterHints`); any other dream (an ending) gets its mood's. The drawn notice has a night-blue band, "SLEEP WELL, CITIZEN", where the others have the red "CITY ADMINISTRATION". E reads it in chat; reading one teaches nothing (no tip cards).
- **Painted over** by the Resistance it reads **WAKE UP**.
- **Pictures (optional):** `garrysmod/materials/livingcity/posters/dream_<codeword>.png` (or `.jpg`), else `dream.png` for all of them, else the drawn notice; painted over, `dream_x.png`. Loose in the server's `garrysmod/`, with the other posters (`livingcity_content.zip`). Not made yet (`TODO.md`).
