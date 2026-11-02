# The G-Man's sound clips (for the owner)

Every clip the gamemode plays for the G-Man: when it plays, the file it looks for, and where it comes from.

- **Where the files go:** on the server, under `garrysmod/sound/`, at the path in the table (for example `garrysmod/sound/vo/episode_1/npc/gman/gman_notforlong.wav`).
- **After adding files:** press FastDL sync, then change the map. Players download any of these the server has when they join.
- **Format:** WAV, signed 16-bit PCM, 44100 Hz, mono (Audacity: File > Export > WAV). Not .ogg.
- **Missing a file?** That moment is silent, but the words still show on screen.
- **Changing a file:** each clip has a setting (last column) to point it at another file.

| # | When it plays | Who hears it | What he says | File (under `garrysmod/sound/`) | Where it comes from | On your server now? | Setting |
|---|---|---|---|---|---|---|---|
| 1 | The G-Man's vote, when time stops | Everyone | "Is it really that time again?" | `vo/citadel/gman_exit02.wav` | Half-Life 2 (`sound/vo/citadel`) | Yes | `lc_ending_gman_lines` |
| 2 | The vote says no | Everyone | "Not this time..." | `vo/episode_1/npc/gman/gman_notthistime.wav` | Episode One pre-load (`sound/vo/episode_1/npc/gman`) | No: download it | `lc_gman_line_vote_no` |
| 3 | The Administrator refuses a sealed directive, the first time | The Administrator | "Not for long..." | `vo/episode_1/npc/gman/gman_notforlong.wav` | Episode One pre-load | No: download it | `lc_gman_line_refused` |
| 4 | The Administrator refuses again (the harsher one) | The Administrator | "We'll see about that." | `vo/episode_1/npc/gman/gman_wellseeaboutthat.wav` | Episode One (`sound/vo/episode_1/intro` or `npc/gman`) | No: download it | `lc_gman_line_refused_again` |
| 5 | 5 minutes left on a waiting directive (the last call; an envelope beside him, and the bar turns red) | The Administrator | "Come back. Come back here, now." | `vo/episode_1/npc/gman/gman_comebacknow.wav` | Episode One pre-load: `gman_comebacknow`, **cut "Oh no, Freeman"** so it starts at "Come back" | No: download and splice | `lc_gman_line_last_call` |
| 6 | The Administrator closes the envelopes without answering (once a directive) | The Administrator | "Get back here..." | `vo/episode_1/npc/gman/gman_getbackhere.wav` | Episode One pre-load: `gman_getbackhere` | No: download it | `lc_gman_line_walk_away` |
| 7 | After a refusal, he picks a rival who could run for the office; they can then call a recall vote | The rival | "A previous hire has been unable, or unwilling, to perform the tasks laid before him. We have struggled to find a suitable replacement. Until now." | `livingcity/gman/gman_replacement.wav` | Half-Life: Alyx: `04_00302` to `04_00304`, **joined into one file** | No: download and join | `lc_gman_line_rival` |
| 8 | A new City Administrator (elected, or by recall) | The new Administrator | "I've received some interesting offers for your services. ... These are extraordinary times." | `vo/citadel/gman_exit05.wav` | Half-Life 2. Optional: **cut "Ordinarily, I wouldn't contemplate them"**, save it as `livingcity/gman/gman_offers.wav`, and point the setting at that | Yes (uncut) | `lc_gman_line_elected` |
| 9 | Someone first looks at one of his weapon crates (each player, once a round of crates) | That player | "The right man in the wrong place can make all the difference in the world." | `vo/gman_misc/gman_03.wav` | Half-Life 2 (`sound/vo/gman_misc`) | Yes | `lc_gman_line_crates` |
| 10 | A glimpse of him about the city, as a directive warms up | Whoever sees him (the sound is from where he stands) | (his inhale) | `vo/episode_1/npc/gman/gman_inhale.wav` | Episode One (`sound/vo/episode_1/npc/gman`) | No: download it (or leave it out: the glimpse is silent) | `lc_gman_line_glimpse` |

**To download (6 files):** `gman_notthistime`, `gman_notforlong`, `gman_wellseeaboutthat`, `gman_comebacknow` (spliced), `gman_getbackhere`, `gman_inhale`, into `garrysmod/sound/vo/episode_1/npc/gman/`; and the Half-Life: Alyx `04_00302` to `04_00304` joined into `garrysmod/sound/livingcity/gman/gman_replacement.wav`.

Dreams (the riddles, the rumours) have no voice: his words on screen, over the dark.
