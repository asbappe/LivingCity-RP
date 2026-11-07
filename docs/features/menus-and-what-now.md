# What now, the quick menus (F1, F2), F4 and the full menu (C)

### What now? Never lost

**Clothes that show the job.** The editor's panel has **Job outfits** (or `!outfits`, or `lc_outfits_edit`, admin; the button used to do nothing, its command having the same name as the on/off setting): pick a job, then a model from whatever's installed (the stock citizens and medics, the hostages, a Workshop pack such as the Black Mesa citizens), tick the skins and bodygroup pieces that fit in the live preview (shirts, overalls, caps, glasses; leave out anything that doesn't), add the look, save. A pack's battle gear (a soldier's helmet, a welding mask: any piece named for a helmet or welding) is only worn by the Resistance in the open: a rebel fighter, or a rebel player not passing as a citizen; on anyone else it's left off. A job can have several looks. The city's people with that job wear one, and so does a citizen player who holds it; each person gets their own pick and keeps it, and a look made from Half-Life 2's citizens can keep each person's own face. **Everyone else (no job)** gives the unemployed glasses, beanies or caps the same way. The Clinic Medic no longer starts out in Half-Life 2's medic clothes (those are the Resistance's medics, armband and all; the owner, 1 November): no job is dressed by default, and a job's outfit starts bare (no leftover pieces of someone's own look, like a welding helmet, carried onto it). Saved for every map in `garrysmod/data/livingcity/outfits.json`; `lc_outfits 0` turns it off. **The Black Mesa citizens pack** (Workshop 534130993): when the server has it and you haven't set looks for Everyone else (no job), about half the city's people without a job wear its citizens and refugees (`lc_bms_people`, 50 percent; 0 turns it off), each person always the same, with their own skin and clothes pieces; the rest keep their Half-Life 2 faces. A man gets its man's model and a woman its woman's. Players keep the face they chose; its citizen and refugee looks are added to the character creator as extra choices. Players download the pack when they join. Cheap variety on top, nothing to download: each of the city's people is a slightly different height (`lc_people_heights`), and each citizen player's shirt has its own drab colour (`lc_citizen_tint`).

**Ways to get by** (F1 > What now? > Ways to get by, or `!ways`): everything you could do right now, one plain line each, ready ones first, the rest saying the one thing missing ("Needs Civil Standing 50, you have 12"), with a button that marks the way there or opens the screen it happens on: eating, bins, a Union job, a market stall, renting an apartment, salvage, fishing, notes and posters, joining Civil Protection or the Resistance; a unit's list is a unit's, a rebel's a rebel's.

**With a rank** (the Resistance, Civil Protection, the administration: anyone not a plain citizen), the corner shows who you are instead of the nudges: faction and rank, credits, Civil Standing, your Union job, and WANTED when you are; only something urgent (hungry, thirsty, down) still takes its place. Everyone always has **one next step**, worked out from where they stand (a plain citizen sees it in the corner): register at Civil Intake, ask Housing Allocation for a room, find your block, eat, drink, get a Union job, work a shift. Each step says why, and **F1 > 1 (What now?)** shows you the way (a waypoint). A new life sees the step as a quiet line under the status box for its first hour (`lc_whatnow_minutes`, 60), and anyone sees it when it's urgent (hungry, thirsty, nowhere to live). After that it's on F1 whenever you want it, or always on screen (C > Settings > Next step on screen; `lc_whatnow_show` 0 never, 1 new life and urgent, 2 always).

**Hungry or thirsty?** The step names the nearest way to eat or drink right now, in order: what's in your pockets, your ration if it's due, food you can afford at the Commissary, bins to search (and how long until your next ration). Running low puts a card on screen once, with the way. **A new life's first ration allocation is never turned away by a supply shortfall.**

**Places:** F1 > What now? > Places (and C > Places in the city) lists everywhere worth knowing, each with a waypoint: the ration dispenser, water, bins, your block, your workplace, the Commissary, Civil Intake and Housing Allocation (units: their Commissary; the Resistance: the lab). `lc_whatnow 0` turns all of it off.

### The keys (the owner, 7 November)

| Key | What it opens |
|---|---|
| F1 | The quick menu: what everyone has |
| F2 | The second quick menu: what your side, rank and job have |
| F3 | Your pockets (and your stash at home) |
| F4 | One window with three tabs: Jobs, Career, Factions |

The engine's own keys are unchanged (F1 to F4 are still `gm_showhelp`, `gm_showteam`, `gm_showspare1`, `gm_showspare2`): only what each opens changed, so a player who rebinds them keeps their keys. Before 7 November, F1 mixed both quick menus, F2 was the pockets, F3 the job board and F4 the faction screen.

### The quick menus (F1 and F2)

**F1 and F2 open quick menus**, like a voice menu in a team shooter: a short list at the left of the screen, picked with the number keys (1 to 9; 0 goes back or closes), and you keep moving while it's up. Both look the same and work the same; 9 on either is everything else, the full menu.

**F1, what everyone has** (the same for every side): 1 **What now? >** (your next step, Places), 2 Hands up, 3 My papers, 4 **Talk >** (and Tell everyone nearby my name), 5 My pockets (F3); then 6 to 8 are what's in front of you and your own trouble, shown in green (a person: tell them your name, show them your papers, uncuff and drag, inform; someone who's down; a body; a door; a forcefield, a transformer, a power bank with a multitool; and you being downed, tied, wanted, interrogated or hauling). With nothing there, 6 to 8 are **Pose >**, **Gesture >** and Jobs, career, factions (F4).

**F2, what your side, rank and job have** (the owner: "the same BUT contextual and specific commands for their class/rank/faction"):

| You are | F2 |
|---|---|
| Civil Protection (the Overwatch too) | 1 **Voice lines >** (the mask's most used lines; the Overwatch ranks' own), 2 Unit tools, 3 Kick, 4 Call for backup, 5 Issue a BOLO, 6 Send my 10-20 (the owner, 7 November); then 7 and 8: search, cuff, escort, take a microphone, walk a prisoner to the cells, read a power bank or pack up a turret (whoever or whatever is in front of you), or My directives (F4) and the records terminal |
| Resistance | Gear up or Plain clothes, Black market, **Resistance >** (find the lab, donate food, decode a chip, write down what you see, hack a door with a multitool), **Squad orders >** (act casual, guns out, meet me at the marker: with a squad following you); cut a vortigaunt's shackles when you're looking at one |
| City Administrator | **Sociostability >** (only the Administrator sets it), Broadcast to the whole city |
| Vortigaunt (shackled) | Reach out through the vortessence (call the Resistance to free you) |
| Stalker | My work: the Stalker's Lot (F4) |
| Anyone on a job | Ask for a Civil Protection escort (or send it away), a ration break while rations are out (or back to work), the body cart (Morticians); a citizen with Civil Standing 150: become (or stop being) a Union foreman, and give whoever you're looking at a work order |
| Staff (admins) | **Staff >** (the staff panel, the admin testing tools, build mode, path mapping) |

With nothing of the kind (a citizen with no job, say), F2 says so: "Nothing here for your side or job right now. F1 has what everyone can do." A ">" opens a page of its own. Bind a key to `lc_quick` (F1's) or `lc_quick2` (F2's) to open them from something else. With F2's menu up, F1 swaps to F1's. Hints that name where something is (the kick reminder at a locked door: "press G (or F2 > 3)") look it up live, with the player's own keys.

### F4: jobs, career and factions, one window

The owner, 7 November: "consolidate F3 and F4 ... a career/factions tab at the top". **F4 opens one window with three tabs along the top:**

- **Jobs** (the first, and where a new session opens): the job board as it was on F3, with the Union employment card (or the way to Labor Assignment), the jobs, the squads and your stories.
- **Career:** your rank, the XP to the next one, every rank of your side and what it takes, the way up in plain words, and the button to ask Overwatch for a reassessment.
- **Factions:** who holds the city, every faction you can join with its requirements and special roles, and for admins the testing tools.

**The last tab you looked at is remembered** for the rest of your session: F4 opens on it. Anything that opens one part on its own opens the window on that tab: `!jobs` (or the board again after you take a job) on Jobs, `!faction` on Factions, C > My career on Career. The separate "My career" buttons that were at the top of the board and the faction screen are gone (the Career tab is where your career is).

### Everything is in the full menu (C)

**You never need a chat command.** C (outside build mode), or 9 on either quick menu, opens a menu of everything you can do right now, for who you are and what you're looking at. At the top: the guide, your pockets (F3), your board (F4 > Jobs), factions (F4 > Factions), your career (F4 > Career), **Tips I've seen**, and for units **Unit tools**. Then whoever or whatever is in front of you (a person by the name you know them by, or what they look like: recognize, inform, cuff, search, escort, give them a key; someone who's down; a body; a door; a machine), and:

- **Me:** hands up, holster, work at the cuffs, give yourself up, give up (when you're down), poses and gestures, your papers, your credits and standing, your characters, your name and face, how strangers see you, I'm stuck.
- **Talk:** tell everyone nearby your name, yell, whisper, describe what you do or the scene, roll the dice, out of character (nearby or everyone), your radio and the Union band. (These are the chat prefixes, typed for you.)
- **Getting by:** your stash, the Commissary, the black market, writing, fishing, salvage, a Civil Protection request, escorts, becoming a foreman.
- **Home:** your housing block, the way home (marked on your screen), the way to Civil Intake or Housing Allocation (while you need them), your apartment, locking it (looking at its door), taking a key back, giving it up.
- **The city:** the time and weather, who holds the city, the laws, and for the Administrator a broadcast.
- **Civil Protection** (units) or **Resistance** (rebels): their tools.
- **Settings:** camera sway, the next step on screen, what you can do here (the panel on the right), the quest trail on the ground, third person while posing, warnings and notices on screen, tips off or on or from the start.
- **Help:** ask staff for help (a ticket); for staff, the staff panel, the admin testing tools, build mode and path mapping.

Every chat command a player can type has a place in it (the client smoke test checks each one, that F1 has nine working items for every side, and that a unit's F2 is in the owner's order), and the tips and the guide point to the menus, not to the command. The commands still work, as shortcuts.

### On the screen, not just in chat

Chat is busy, so what matters goes on the screen too (and stays in chat to scroll back through). **Someone talking to you** (a rebel guarding the supplies, the quartermaster, the scientist, an interrogator) shows as a subtitle low in the middle; when a window is open there (the quartermaster's, the lab's), just below it instead (or above, with no room below), never hidden behind it. **Warnings** (Civil Protection, Overwatch, conduct strikes, custody, a disguise slipping) show as a card at the top, edged in red; **notices** (Civil Intake, Housing Allocation, your papers, rations, the city) edged in blue; and **the city's announcements** in amber, with what they mean for you. The same line again bumps a counter instead of stacking up. **Waypoints:** asking the way somewhere (the Civil Protection Commissary, Housing Allocation, home, the lab) marks it on your screen with how far it is, at the edge of the screen when it's behind you, gone when you get there (home: once you're inside your block). Turn the cards off for yourself in C > Settings (`lc_notices 0`).

**Changes from the 7 November playtest.** Gestures (F1 > Gesture) play as your own animation (the act command did nothing on the server); the old command is the fallback. Putting your hands up never moved you: the pose is drawn ahead of the model, and the body is now pulled back to match. When a unit searches you, a tip says to put your hands up (F1, then 2), and the unit is told whether they are.
