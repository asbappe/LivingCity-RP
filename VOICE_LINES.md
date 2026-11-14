# Voice lines to record

**Every voice line the gamemode looks for, in one place** (the owner, 10 November). Made from the code by `python3 _dev/voice_lines.py`: never edit it by hand, rerun it. Tick them off as you go.

- **Which ones your server still lacks:** run `lc_voice_missing` in the server console: it lists exactly what isn't there yet. Paste its output to Claude and the boxes here can be ticked for you.
- **Formats:** `.wav` (signed 16-bit PCM, 44100 Hz, mono), `.mp3` or `.ogg`. More than one take: `...1`, `...2` and so on; one is picked at random.
- **Different words from the ones suggested?** Put them in a `.txt` file with the same name beside the recording (`curfew1.txt` beside `curfew1.wav`): that's what shows in chat or on screen.
- **After adding files:** press FastDL sync on the host panel, then change the map (players download new sounds when they join).
- **Without a recording** the moment is silent (or Half-Life 2's own voice, for Overwatch, with `lc_announce_stock` 1), and the words still show.

Contents: 1. The city's announcements (Overwatch and the Administrator) · 2. The radio · 3. The G-Man · 4. The dreams · 5. Citizens showing the way · 6. The Citizen Information clerk · 7. The old-timer · 8. Machines · 9. The Colonel · 10. What named citizens say · 11. What units say

## 1. The city's announcements

Folders on the server: **`garrysmod/sound/livingcity/overwatch/`** and **`garrysmod/sound/livingcity/administrator/`**. Which voice speaks: the Administrator's with nobody playing the Administrator, Overwatch's with a player in the post. **Her tone:** each line has a usual tone, the word in her file name (warm has no word: `rations1.wav`; then `firm`, `stern`, `furious`: `curfew_firm1.wav`). Her tone goes up a step on red sociostability and again after a run of violence, so a `stern` or `furious` take of any line is worth having; with none in the tone she needs, she uses the nearest one she has.

| Done | Trigger | When it plays | Overwatch file | Overwatch says | Administrator file (her usual tone) | She says |
|---|---|---|---|---|---|---|
| [x] | `rations` | A ration distribution starts | `rations1.wav` | Attention, residents: ration distribution is now in progress. Report to your assigned distribution point. | `rations1.wav` (warm) | Good news, everyone! Rations are being handed out right now. Come along, and don't forget your card. |
| [x] | `sweep` | An inspection sweep starts | `sweep1.wav` | Attention, residents: inspection sweep in progress. Remain where you are and present your identification. | `sweep_firm1.wav` (firm) | A little inspection, nothing to worry about. Stand still, papers out, and it'll be over before you know it. |
| [x] | `curfew` | Curfew starts | `curfew1.wav` | Attention, residents: curfew is now in effect. Return to your residence block immediately. | `curfew_firm1.wav` (firm) | Bedtime, everyone. Curfew starts now: home you go, and stay there till morning. |
| [x] | `lockdown` | A lockdown starts | `lockdown1.wav` | Attention, all residents: the city is now in lockdown. Remain indoors. Civil Protection is authorized to use force. | `lockdown_stern1.wav` (stern) | The city is in lockdown. Stay inside. I am not asking. |
| [x] | `raid` | A raid on a block starts | `raid1.wav` | Attention, residents: a block inspection is under way. Do not interfere with Civil Protection. | `raid_stern1.wav` (stern) | Civil Protection is visiting one of our blocks. Cooperate, and everyone sleeps soundly tonight. |
| [x] | `supply` | A supply convoy arrives | `supply1.wav` | Attention, residents: supply convoy in transit. Clear the route. | `supply1.wav` (warm) | A supply convoy is coming through! Step aside and let it pass, there's a love. |
| [x] | `ended` | An event is over | `ended1.wav` | Attention, residents: sociostabilization restored. Resume assigned duties. | `ended1.wav` (warm) | That's all done. Thank you, everyone. Back to your day. |
| [x] | `rations_soon` | Two minutes before a ration distribution | `rations_soon1.wav` | Attention, residents: ration distribution begins in two minutes. | `rations_soon1.wav` (warm) | In just a couple of minutes, rations! Start making your way over, dears. |
| [x] | `curfew_soon` | Two minutes before curfew | `curfew_soon1.wav` | Attention, residents: curfew begins in two minutes. Proceed to your residence block. | `curfew_soon_firm1.wav` (firm) | Curfew in two minutes. Finish up and head home, please. |
| [x] | `socio_green` | Sociostability goes green | `socio_green1.wav` | Sociostability nominal. Resume normal activity. | `socio_green1.wav` (warm) | Everything is calm again. Well done, all of you. |
| [x] | `socio_yellow` | Sociostability goes yellow | `socio_yellow1.wav` | Sociostability marginal. Expect increased inspections. Keep your papers ready. | `socio_yellow_firm1.wav` (firm) | Things are a little tense. Papers ready, heads down, and we'll get through it. |
| [x] | `socio_red` | Sociostability goes red | `socio_red1.wav` | Judgment waiver in effect. Civil Protection may act at their discretion. Remain indoors. | `socio_red_stern1.wav` (stern) | We are on red. Go home. Whatever happens out there now, you were warned. |
| [ ] | `socio_black` | The city collapses to BLACK (also every 5 minutes while it lasts): open rebellion, the curfew and the shelling, in one | `socio_black1.wav` | Attention all residents: sociostability has collapsed. Martial law is in effect. Mandatory curfew. Suppression fire authorized on all exposed sectors. | `socio_black_furious1.wav` (furious) | Citizens. The city has been overrun by its own ingratitude. Go indoors and stay there. Anyone in the open will be fired upon from the Nexus. This is not a request. |
| [x] | `dawn` | Dawn | `dawn1.wav` | Attention, residents: a new work cycle begins. Report to your assignments. | `dawn1.wav` (warm) | Good morning, everyone! Rise and shine: a brand new day for the city. |
| [x] | `day` | Midday | `day1.wav` | Attention, residents: productivity quotas remain in effect. | `day1.wav` (warm) | Halfway through the day. Keep it up, I'm proud of you. |
| [x] | `dusk` | Dusk | `dusk1.wav` | Attention, residents: the work cycle is ending. Prepare for curfew. | `dusk1.wav` (warm) | The day's nearly done. Finish up, and think about heading home. |
| [x] | `night` | Night | `night1.wav` | Attention, residents: night cycle. Movement outside residence blocks is restricted. | `night1.wav` (warm) | Goodnight, everyone. Sleep well, and dream of the city. |
| [x] | `outbreak` | Infected break out into the streets | `outbreak1.wav` | Alert: biotic contamination in the city. Avoid the affected area. Containment teams are responding. | `outbreak_firm1.wav` (firm) | Something has got out of the infestation. Keep away from it and let the crews do their work. |
| [x] | `blackout` | A district loses power | `blackout1.wav` | Alert: power failure in your district. Remain calm. Maintenance has been dispatched. | `blackout_firm1.wav` (firm) | A little power cut, nothing more. The crews are on it, so stay calm. |
| [x] | `power_restored` | Power comes back | `power_restored1.wav` | Power restored. Resume normal activity. | `power_restored1.wav` (warm) | Lights back on! Thank you for your patience. |
| [x] | `skirmish_raid` | Overwatch answers a fight with the Resistance | `skirmish_raid1.wav` | Overwatch response team deployed. Residents, clear the area. | `skirmish_raid_stern1.wav` (stern) | Overwatch is dealing with some trouble. Stay well away from it. |
| [x] | `skirmish_sweep` | Overwatch sweeps into rebel ground | `skirmish_sweep1.wav` | Overwatch sweep under way in an anticivil sector. Residents, remain clear. | `skirmish_sweep_stern1.wav` (stern) | Overwatch is cleaning up a troubled corner of the city. Let them work. |
| [x] | `response` | A response squad is sent | `response1.wav` | Protection response team dispatched. Do not interfere. | `response_stern1.wav` (stern) | A response team is on its way. Please don't get in their way. |
| [x] | `breakout` | Prisoners break out | `breakout1.wav` | Alert: unauthorized departure from detention. All residents, report sightings to Civil Protection. | `breakout_furious1.wav` (furious) | Some people have run from where they belong. If you see them, tell a unit. Now. |
| [x] | `overwatch_drop` | Overwatch soldiers are dropped in | `overwatch_drop1.wav` | Overwatch deployment in progress. Residents, clear the landing zone. | `overwatch_drop_stern1.wav` (stern) | Overwatch soldiers are arriving. Make way for them. |
| [x] | `block_raided` | A housing block is raided | `block_raided1.wav` | Housing block inspection in progress. Remain in your unit. | `block_raided_stern1.wav` (stern) | We're checking one of our housing blocks. Stay in your room and it'll be quick. |
| [x] | `territory_grew` | The Resistance gains ground | `territory_grew1.wav` | Alert: anticivil activity expanding. Avoid unregistered areas. | `territory_grew_firm1.wav` (firm) | Some troublemakers are spreading out. Don't go near them, and don't listen to them. |
| [x] | `train_arrival` | A train arrives | `train_arrival1.wav` | Attention: new arrivals at the platform. Proceed to Civil Intake. | `train_arrival1.wav` (warm) | Welcome to the city, all you new faces! Civil Intake is just this way. |
| [x] | `welcome` | Someone joins the server (just for them) | `welcome1.wav` | Attention, new resident: report to Civil Intake for registration. | `welcome1.wav` (warm) | Hello, and welcome to the city! You're going to love it here. |
| [x] | `ambient` | General city announcements now and then (also her addresses, with lc_breen_broadcasts 1) | `ambient1.wav` | Attention, residents: inaction is conspiracy. Report suspicious behavior. | `ambient1.wav` (warm) | Remember, a good citizen is a happy citizen. And I do so want you all to be happy. |
| [ ] | `jog` | The morning jog | `jog1.wav` | Attention, residents: morning exercise. Assemble for the run. | `jog1.wav` (warm) | Morning, everyone! Shoes on: time for our little jog. |
| [ ] | `drill` | The morning drill | `drill1.wav` | Attention, residents: morning drill. Assemble in the yard. | `drill1.wav` (warm) | Into the yard, everyone, for our morning exercises. Stretch! |
| [ ] | `parade` | The morning parade | `parade1.wav` | Attention, residents: assemble for the parade. | `parade1.wav` (warm) | Parade time! Chins up, shoulders back, and let's show the city who we are. |
| [ ] | `black_stand` | Her last stand begins | `black_stand1.wav` | Overwatch acknowledges incursion at the Nexus. All units, converge and protect the Administrator. | `black_stand_furious1.wav` (furious) | So you have come for me. Come, then. You will not reach me. |
| [ ] | `black_fallen` | She's dead (always Overwatch's: she can't announce her own death) | `black_fallen1.wav` | Administrator biosignal lost. City administration suspended. All units, fall back to the Nexus. | (not hers) |  |
| [ ] | `black_crushed` | The uprising is crushed (time ran out) | `black_crushed1.wav` | Incursion contained. Sociostability restoring. Remain indoors. | `black_crushed_stern1.wav` (stern) | It is over. The city is mine again, and I will remember every one of you. |
| [ ] | `suppressor_down` | The suppression device is destroyed | `suppressor_down1.wav` | Alert: Nexus suppression device offline. All units, contain and repair. | `suppressor_down_furious1.wav` (furious) | They have silenced the Nexus. It changes nothing. |
| [ ] | `speech_soon` | Her address is called: the city must gather (Overwatch's when a player Administrator calls it from her tablet; hers when the city gives it) | `speech_soon1.wav` | Attention, all residents: the City Administrator will address the city. Report to the assembly point immediately. Attendance is mandatory. | `speech_soon1.wav` (warm) | My dear citizens, I am going to speak to you all in a few minutes. Come and gather in front of the stand. I would so hate to miss anyone. |
| [ ] | `speech_open` | Her speech, the opening | (not his) | | `speech_open1.wav` (warm) | Citizens. Thank you for coming to hear me. Let us talk about the days behind us. |
| [x] | `speech_slogan` | Her speech her slogan, before the closing, every time | (not his) | | `speech_slogan1.wav` (warm) | Love your neighbour, hate the traitor. |
| [ ] | `speech_ev_deaths` | Her speech, on what happened lately: when people were killed lately | (not his) | | `speech_ev_deaths_firm1.wav` (firm) | Blood has been spilled in our streets. Every life lost to violence is stolen from all of us. Violence solves nothing. It only invites more. |
| [ ] | `speech_ev_arrests` | Her speech, on what happened lately: when people were taken to the cells | (not his) | | `speech_ev_arrests_firm1.wav` (firm) | Civil Protection has been busy. No one taken to the cells was taken at random. They chose disorder, and disorder has a price. |
| [ ] | `speech_ev_informers` | Her speech, on what happened lately: when citizens informed (she knows who) | (not his) | | `speech_ev_informers1.wav` (warm) | To those of you who came forward and told us what you saw: thank you. You know who you are, and so do I. Your loyalty will not be forgotten. |
| [ ] | `speech_ev_informer_hurt` | Her speech, on what happened lately: when the Resistance hurt an informer | (not his) | | `speech_ev_informer_hurt_stern1.wav` (stern) | Some of you were hurt for helping the city, beaten in the dark by cowards who call themselves liberators. Look at what they do to their own neighbours, and ask who your friends really are. |
| [ ] | `speech_ev_taken` | Her speech, on what happened lately: when the Resistance took someone (the cage, the chair, an execution) | (not his) | | `speech_ev_taken_stern1.wav` (stern) | Citizens have been taken, dragged off by the so-called Resistance and questioned like animals. That is the freedom they offer you: a cage, and a chair. |
| [ ] | `speech_ev_escape` | Her speech, on what happened lately: when someone escaped | (not his) | | `speech_ev_escape_stern1.wav` (stern) | Some who were held have run from where they belong. They will be found. And whoever hides them will stand beside them when they are. |
| [ ] | `speech_ev_posters` | Her speech, on what happened lately: when the city's posters were defaced | (not his) | | `speech_ev_posters_firm1.wav` (firm) | Someone has been defacing the city's notices. A poster costs the Union very little. Replacing it will cost you your rations. |
| [ ] | `speech_ev_theft` | Her speech, on what happened lately: when there was stealing | (not his) | | `speech_ev_theft_firm1.wav` (firm) | There has been stealing, from the city and from each other. A thief steals from everyone standing in this square. |
| [ ] | `speech_ev_defiance` | Her speech, on what happened lately: when people shouted at units or accused each other (a mind breaking) | (not his) | | `speech_ev_defiance_firm1.wav` (firm) | Voices have been raised at the officers who keep you safe. I understand frustration. I will not tolerate it in the street. |
| [ ] | `speech_ev_sabotage` | Her speech, on what happened lately: when someone sabotaged the city's work (a mind breaking) | (not his) | | `speech_ev_sabotage_stern1.wav` (stern) | Machines have been broken and the city's work undone. Sabotage hurts no one but you. It is your water, your light, your bread. |
| [ ] | `speech_ev_heavyhand` | Her speech, on what happened lately: when a unit was brutal (a mind breaking) | (not his) | | `speech_ev_heavyhand_firm1.wav` (firm) | Some of you have seen our officers act firmly. Firmness is a kindness, in the end. It ends trouble before trouble ends you. |
| [ ] | `speech_ev_drink` | Her speech, on what happened lately: when people took to drink (a mind breaking) | (not his) | | `speech_ev_drink1.wav` (warm) | I hear some of you have found comfort in a bottle. I do not blame you. But a clear head is a loyal head. |
| [ ] | `speech_ev_kindness` | Her speech, on what happened lately: when people shared food or steadied each other (a mind breaking) | (not his) | | `speech_ev_kindness1.wav` (warm) | And I have seen good things too: neighbours sharing their bread, calming each other's nerves. That is the city I am proud of. |
| [ ] | `speech_ev_despair` | Her speech, on what happened lately: when people gave up hope (a mind breaking) | (not his) | | `speech_ev_despair1.wav` (warm) | Some of you have lost hope. Do not. Hope is not something you are given. It is something you choose, every morning. |
| [ ] | `speech_unrest` | Her speech, on the state of the city: when the Resistance is strong | (not his) | | `speech_unrest_stern1.wav` (stern) | There are those among you who whisper of freedom and mean only chaos. Every one of them you shelter is a debt your whole block will pay. |
| [ ] | `speech_hunger` | Her speech, on the state of the city: when supply is low | (not his) | | `speech_hunger1.wav` (warm) | I know the rations have been thin. I feel every empty bowl as if it were my own. Work your shifts, keep your quotas, and the trains will come. |
| [ ] | `speech_order` | Her speech, on the state of the city: when her authority is low | (not his) | | `speech_order_firm1.wav` (firm) | Let me be clear, so no one can say they were not told. The rules of this city are not suggestions, and my authority is not in question. |
| [ ] | `speech_morale` | Her speech, on the state of the city: when morale is low | (not his) | | `speech_morale1.wav` (warm) | I see tired faces, and I understand. But the lights are on, the streets are swept, and not one of you is alone. |
| [ ] | `speech_calm` | Her speech, on the state of the city: when nothing much happened (a quiet few days) | (not his) | | `speech_calm1.wav` (warm) | These have been quiet days, days of order and honest work. The Union sees it. I see it. |
| [ ] | `speech_mood_afraid` | Her speech, on the city's mood: when the city's people are frightened (the minds: stress high) | (not his) | | `speech_mood_afraid1.wav` (warm) | I can see fear in your faces. You have nothing to fear from me. Only from those who would set you against me. |
| [ ] | `speech_mood_restless` | Her speech, on the city's mood: when the city's people are restless (the minds: unrest high) | (not his) | | `speech_mood_restless_firm1.wav` (firm) | There is a restlessness in this city. I feel it. Restlessness can be turned into work, or into ruin. Choose work. |
| [ ] | `speech_mood_content` | Her speech, on the city's mood: when the city's people are at ease (the minds: stress low) | (not his) | | `speech_mood_content1.wav` (warm) | You look well: rested, fed and calm. Good. Keep it so. |
| [ ] | `speech_close` | Her speech, the closing | (not his) | | `speech_close1.wav` (warm) | Now go back to your work, and remember: this city is only as strong as each one of you. Glory to the Union. |

## 2. The radio

Folder: **`garrysmod/sound/livingcity/radio/`**. One voice of your choosing (a Union announcer for `union`, a Resistance voice for Freq 7).

| Done | File | When it plays | Suggested |
|---|---|---|---|
| [x] | `static1.wav` | The hiss between stations on the radio repair bench (long and loopable is best) | (no words: radio static) |
| [ ] | `union1.wav` | An ordinary station, the Union band (none: her ambient recordings play instead) | Union broadcast music or a calm announcer: "This is the Union band. Work hard, sleep well." |
| [ ] | `freq7_1.wav` | The Resistance's pirate broadcast, between songs (its .txt is shown on the panel) | "This is Frequency 7. They can't jam us all. Stay low, stay alive." |
| [ ] | `freq7_song_<anything>.ogg` | Songs on Freq 7 (lc_freq7_songs 1); name them freq7_song_<anything>.ogg | (music) |
| [ ] | `jam1.wav` | The jamming whine when the Combine find Freq 7 (a stock sound otherwise) | (no words: a harsh whine) |
| [ ] | `freq7_sweep1.wav` | Freq 7 warns: a sweep is coming | "Heads up: a sweep is coming into our ground. Hide what you've got." |
| [ ] | `freq7_raid1.wav` | Freq 7 warns: a raid is coming | "They're raiding a block. If you can get out, get out now." |
| [ ] | `freq7_curfew1.wav` | Freq 7 warns: curfew | "Curfew's coming. Get where you need to be." |
| [ ] | `freq7_supply1.wav` | Freq 7 warns: a supply convoy (a chance to hit it) | "Supply convoy on the move. Anyone feeling brave?" |
| [ ] | `freq7_incursion1.wav` | Freq 7 warns: the Combine are in rebel ground | "Combine in our territory. Everyone to your posts." |
| [ ] | `freq7_lockdown1.wav` | Freq 7 warns: lockdown | "Lockdown. Stay put, stay quiet, wait it out." |
| [ ] | `freq7_dropship1.wav` | Freq 7 warns: a dropship | "Dropship incoming. Find cover." |

## 3. The G-Man

Nothing here needs a new voice: every line is one of his real clips (Half-Life 2, the Episodes, Half-Life: Alyx), as it is or spliced ("Mr. Freeman" cut out). Each has a setting pointing at its file; a `.txt` beside a clip gives its exact words on screen.


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

### The collapse (sociostability BLACK): his lines to the Administrator

Added 10 November. He stands in front of the Administrator (only she sees him) and says these. **Nothing needs recording:** point each setting at any real G-Man clip, stock or one you've spliced (cut out "Mr. Freeman" and so on). **The words on screen:** put a `.txt` file with the same name next to the clip (for example `black_gman_wise.txt` beside `black_gman_wise.wav`) holding exactly what the clip says, and that's what shows; with no `.txt`, the words below show. With no clip, the moment is silent and the words still show. `lc_voice_missing` lists which ones the server doesn't have yet.

| # | When it plays | What it says now (on screen) | File (under `garrysmod/sound/`) by default | Setting |
|---|---|---|---|---|
| 11 | He appears in front of her (she can't move while he talks) | "Is it really that time again?" | `vo/citadel/gman_exit02.wav` (Half-Life 2, on your server) | `lc_black_gman_arrive` |
| 12 | Five seconds later | "I've received some interesting offers for your services. Ordinarily, I wouldn't contemplate them. These are extraordinary times." | `vo/citadel/gman_exit05.wav` (Half-Life 2, on your server) | `lc_black_gman_ways` |
| 13 | His window opens (step down, end it, refuse) | "Step aside. Or end it ... yourself. Choose." | `livingcity/gman/black_gman_choose.wav` | `lc_black_gman_choose` |
| 14 | Half her time to answer is gone | "Time is a luxury you no longer have, Administrator." | `livingcity/gman/black_gman_press.wav` | `lc_black_gman_press` |
| 15 | 30 seconds left to answer | "Choose. Or I will ... choose for you." (Half-Life 2's ending has a line about taking the liberty of choosing for you: a good one to splice) | `livingcity/gman/black_gman_lastcall.wav` | `lc_black_gman_lastcall` |
| 16 | She shuts his window or walks away from him (10 seconds to come back and press E on him) | "Get back here..." | `vo/episode_1/npc/gman/gman_getbackhere.wav` (row 6: splice "get back here ... get back here now" without "Freeman", with a `.txt` of its words) | `lc_gman_line_walk_away` (shared with row 6) |
| 17 | She steps down | "A wise choice, Administrator." | `livingcity/gman/black_gman_wise.wav` | `lc_black_gman_wise` |
| 18 | She ends it herself | "... As you wish." | `livingcity/gman/black_gman_asyouwish.wav` | `lc_black_gman_asyouwish` |
| 19 | She refuses (or doesn't come back in time) | "Not for long..." | row 3's file | `lc_gman_line_refused` (shared with row 3) |
| 20 | His first step: weapon crates about the city | "The right man in the wrong place can make all the difference in the world." | row 9's file | `lc_gman_line_crates` (shared with row 9) |
| 21 | His second step: people waking armed | "Your citizens sleep poorly. They wake ... prepared." | `livingcity/gman/black_gman_sleep.wav` | `lc_black_gman_sleep` |
| 22 | His third step: the grid failing | "Even the lights are leaving you." | `livingcity/gman/black_gman_dark.wav` | `lc_black_gman_dark` |
| 23 | His fourth step: her last stand | "It ends where it began, Administrator. In your office." | `livingcity/gman/black_gman_office.wav` | `lc_black_gman_office` |


## 4. The dreams

Every line said in the dreams you play. Folder: **`garrysmod/sound/livingcity/dreams/voice/`** (`.mp3`, `.ogg` or `.wav`). If the words you recorded differ, a `.txt` of the same name holds them. **Music** for any dream goes in `garrysmod/sound/livingcity/dreams/`, named for the dream's codeword (in brackets): `horse1.mp3`, `boxing1.mp3`; Dance Marathon's tempo goes in `dance1.txt` (just the BPM).

**The voices in the dark:** The Cheese Dream uses Half-Life 2's own citizens. Hooves and All uses Half-Life 2's hungry line too, unless you record `horse_intro_male1.mp3` and `horse_intro_female1.mp3`.

### The strange dreams

#### The Cheese Dream (`cheese`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `cheese_hello1.mp3` | The Heads in the Sky | Cheeeeese. Cheeeeeeeese. | a choir of giant floating heads, humming, slow, warm, reverb-heavy and slightly off-key |
| [ ] | `cheese_gold1.mp3` | The Heads in the Sky | The golden cheese! The golden cheese! | the same choir, suddenly excited, overlapping, high-pitched |

#### Musical Chairs (`chairs`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `chairs_hello1.mp3` | The Music Man | Ladies and gentlemen, musical chairs! When the music stops... sit. | a cheerful old game-show host, a little too close to the microphone |
| [ ] | `chairs_sit1.mp3` | The Music Man | SIT! | the game-show host, sudden and loud |

#### Wings (`flying`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `flying_hello1.mp3` | A Gentle Voice | Go on. You always knew you could. Just... flap. | a soft, kind, dreamy narrator, almost whispering |

#### It's Raining Melons (`melons`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `melons_hello1.mp3` | The Weatherman | Today's forecast: melons. Heavy melons, with a chance of lead. | a chirpy TV weatherman, completely serious about it |

#### Hooves and All (`horse`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `horse_intro_male1.mp3` | A Hungry Man | I'm so hungry... I could eat a horse. | a weary, starving working man, far away, as if from the end of a long tunnel (replaces Half-Life 2's line) |
| [ ] | `horse_intro_female1.mp3` | A Hungry Woman | I'm so hungry... I could eat a horse. | a tired, starving woman, distant and dreamy (replaces Half-Life 2's line) |
| [ ] | `horse_grigori11.mp3` | Father Grigori | Back! Back to the pit, foul beast! | an old, wild-eyed priest with a booming, theatrical voice, laughing between words |
| [ ] | `horse_grigori21.mp3` | Father Grigori | It will not die! Why will it not die?! | the old priest, delighted and horrified at once |
| [ ] | `horse_grigori31.mp3` | Father Grigori | Eat, my children! Eat, while it stands still! | the old priest, preaching at the top of his lungs |
| [ ] | `horse_grigori41.mp3` | Father Grigori | I have been shooting this horse since the old days. I will shoot it until the end of days! | the old priest, proud and completely mad |
| [ ] | `horse_grigori51.mp3` | Father Grigori | Hah! Feel the wrath of the Lord, and buckshot! | the old priest, cackling |
| [ ] | `horse_grigori61.mp3` | Father Grigori | Hooves and all, children. Hooves and all. | the old priest, suddenly quiet and tender |

#### The Main Event (`boxing`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `boxing_hello1.mp3` | The Ring Announcer | Ladies and gentlemen, citizens of all ages... welcome... to the Main Event! | a classic big-fight ring announcer, stretching every vowel |
| [ ] | `boxing_foe11.mp3` | The Ring Announcer | In the far corner, weighing in at four hundred pounds of pure debeaked fury... Lamarr! | the ring announcer, building to a roar |
| [ ] | `boxing_foe21.mp3` | The Ring Announcer | And now, undefeated in forty bouts, dispensing pain at a reasonable price... the Soda Machine! | the ring announcer, deadly serious |
| [ ] | `boxing_foe31.mp3` | The Ring Announcer | And your final opponent... he's big, he's bald, he's barely a year old... the Baby! | the ring announcer, almost screaming |
| [ ] | `boxing_ko1.mp3` | The Ring Announcer | It's a knockout! | the ring announcer, ecstatic |
| [ ] | `boxing_champ1.mp3` | The Ring Announcer | Your new... champion... of the world! | the ring announcer, over a roaring crowd |

#### The Exam (`exam`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `exam_hello1.mp3` | Doctor Kleiner | Good morning, class. Pencils ready. Oh dear. You did study, didn't you? And... where are your trousers? | an elderly, fussy, kindly professor, absent-minded and a little alarmed |
| [ ] | `exam_q11.mp3` | Doctor Kleiner | Next question. Take your time. Actually, don't. | the old professor, peering over his glasses |
| [ ] | `exam_q21.mp3` | Doctor Kleiner | This one will be on the test. This is the test. | the old professor, puzzled by his own words |
| [ ] | `exam_q31.mp3` | Doctor Kleiner | Hmm. I'm not sure I know this one either. | the old professor, mumbling |
| [ ] | `exam_end1.mp3` | Doctor Kleiner | Marvellous. All graded. I couldn't eat another bite. | the old professor, very full, patting his stomach |
| [ ] | `exam_collect1.mp3` | Doctor Kleiner | Pencils down! I shall now collect your papers. Personally. | the old professor, licking his lips |
| [ ] | `exam_eat11.mp3` | Doctor Kleiner | Mmm. A little dry. | the old professor, chewing loudly, mouth full |
| [ ] | `exam_eat21.mp3` | Doctor Kleiner | Delicious. Absolutely delicious. | the old professor, mouth full, ecstatic |
| [ ] | `exam_eat31.mp3` | Doctor Kleiner | I grade with my mouth. It's the only fair way. | the old professor, chewing, matter-of-fact |
| [ ] | `exam_eat41.mp3` | Doctor Kleiner | Oh, this one has a lot of crossing out. Crunchy. | the old professor, crunching, delighted |

#### The Last Train (`train`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `train_hello1.mp3` | The Conductor | Last train! Last train out of City Seventeen! All aboard! | a hoarse old train conductor, echoing down a station platform |
| [ ] | `train_hint1.mp3` | The Conductor | You're looking right at it. That never works in dreams. | the conductor, conspiratorial, a stage whisper |
| [ ] | `train_closing1.mp3` | The Conductor | Doors closing! Doors closing! | the conductor, urgent |

#### Where's Lamarr? (`lamarr`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `lamarr_hello1.mp3` | Doctor Kleiner | Lamarr? Lamarr! Oh, where has she got to now? Has anyone seen my headcrab? | the old professor, fretting over a lost pet |
| [ ] | `lamarr_found1.mp3` | Doctor Kleiner | Lamarr! There you are, you naughty girl! | the old professor, overjoyed |

#### Running in Molasses (`molasses`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `molasses_hello1.mp3` | A Whisper | Run. Why aren't you running? Run... | a slow, breathy, menacing whisper, dragged out |

#### Hot Potato (`potato`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `potato_hello1.mp3` | The Host | Hot potato! Don't be holding it when the music... I mean the grenade... stops! | a manic children's party host |

#### Overwatch Says (`simon`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `simon_hello1.mp3` | The Officer | Citizens. You will do as Overwatch says. Only as Overwatch says. | a Civil Protection officer through a gas mask radio, flat and clipped |
| [ ] | `simon_says_jump1.mp3` | The Officer | Overwatch says: jump. | the masked officer, flat |
| [ ] | `simon_says_crouch1.mp3` | The Officer | Overwatch says: crouch. | the masked officer, flat |
| [ ] | `simon_says_freeze1.mp3` | The Officer | Overwatch says: freeze. | the masked officer, flat |
| [ ] | `simon_says_walk1.mp3` | The Officer | Overwatch says: walk. | the masked officer, flat |
| [ ] | `simon_trap_jump1.mp3` | The Officer | Jump. | the masked officer, flat, sly |
| [ ] | `simon_trap_crouch1.mp3` | The Officer | Crouch. | the masked officer, flat, sly |
| [ ] | `simon_end1.mp3` | The Officer | Compliance noted. Dismissed. | the masked officer, almost pleased |

#### Dance Marathon (`dance`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `dance_hello1.mp3` | The DJ | City Seventeen, are you ready to move? Jump on the big beat! | an over-excited club DJ with heavy reverb |

#### Counting Headcrabs (`sheep`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `sheep_hello1.mp3` | A Sleepy Voice | Close your eyes... and count the headcrabs. One... two... | a soft, slow, yawning bedtime voice |
| [ ] | `sheep_ask1.mp3` | A Sleepy Voice | How many was that? Say it... before you drift off... | the sleepy voice, half asleep |
| [ ] | `sheep_again1.mp3` | A Sleepy Voice | Again... from the beginning... | the sleepy voice, yawning |

#### Stop the Clocks (`clocks`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `clocks_hello1.mp3` | The Clock Voice | Tick. Tock. Tick. Tock. It's later than you think. It's earlier than you think. It's cheese. | a slow, deep, echoing voice, like a grandfather clock talking in its sleep |
| [ ] | `clocks_won1.mp3` | The Clock Voice | Time... stops. | the clock voice, slowing down to nothing |

#### The Tea Party (`tea`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `tea_hello1.mp3` | The Host | Welcome, welcome! No room! No room! Sit anywhere. No, not there. | a manic, posh, very old-fashioned tea-party host, talking far too fast |
| [ ] | `tea_down11.mp3` | The Host | Change places! Move down one! | the posh host, shrieking with delight |
| [ ] | `tea_down21.mp3` | The Host | Change places! Move down two! | the posh host, shrieking with delight |
| [ ] | `tea_down31.mp3` | The Host | Change places! Move down three! | the posh host, shrieking with delight |
| [ ] | `tea_up1.mp3` | The Host | Clean cup! Clean cup! Move up! | the posh host, outraged |

#### The Headcrab Derby (`derby`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `derby_hello1.mp3` | The Commentator | Welcome to the Headcrab Derby! Place your bets, place your bets! | a breathless horse-racing commentator |
| [ ] | `derby_off1.mp3` | The Commentator | And they're off! | the racing commentator, at full gallop |
| [ ] | `derby_win11.mp3` | The Commentator | And it's Lamarr's Cousin by a leg! It only has legs! | the racing commentator, ecstatic |
| [ ] | `derby_win21.mp3` | The Commentator | Hooves wins it! Hooves! A headcrab called Hooves! | the racing commentator, baffled and thrilled |
| [ ] | `derby_win31.mp3` | The Commentator | Mister Leg takes it! Mister Leg, everybody! | the racing commentator, screaming |
| [ ] | `derby_win41.mp3` | The Commentator | Breen's Toupee! Breen's Toupee wins the Derby! | the racing commentator, losing his mind |

#### Say Cheese (`photo`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `photo_hello1.mp3` | The Scanner | Hello! Hello! Lovely day for a photograph! Everybody smile! | a chirpy robotic camera voice, slightly glitchy |
| [ ] | `photo_cheese1.mp3` | The Scanner | Say cheese! | the chirpy robot camera, sing-song |

#### The Doors (`doors`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `doors_hello1.mp3` | A Little Voice | Six doors. One plays a song. Listen... listen... | a small, sweet, slightly eerie child's voice, whispering |
| [ ] | `doors_open1.mp3` | A Little Voice | That one. It was always that one. | the eerie child's voice, giggling |

#### Splat! (`paint`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `paint_hello1.mp3` | The Painter | A blank canvas! Make it yours! Splat! | an over-the-top, flamboyant artist |

#### Conga! (`conga`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `conga_hello1.mp3` | The Bandleader | Everybody conga! One, two, three, kick! | a jolly big-band leader, shouting over brass |

#### Shh! (`shh`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `shh_hello1.mp3` | A Whisper | Shhhh. The baby's sleeping. Don't wake the baby. | a very quiet, tense whisper |
| [ ] | `shh_wake1.mp3` | A Whisper | You woke the baby. | the whisper, cold and disappointed |

#### Bubbles (`bubbles`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `bubbles_hello1.mp3` | A Bubbly Voice | Pop! Pop! Pop them all! | a giggly, bubbly, high-pitched voice |

#### The Watchers (`watchers`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `watchers_hello1.mp3` | A Whisper | They don't move while you watch them. You can't watch them all. | a slow, hollow whisper, very close to the ear |

#### Pick Up That Can (`can`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `can_hello1.mp3` | The Officer | Pick up that can. | a Civil Protection officer through his mask's radio, flat and bored, just as in Half-Life 2 |
| [ ] | `can_trash1.mp3` | The Officer | Now, put it in the trash can. | the officer, flat, already enjoying himself |
| [ ] | `can_again1.mp3` | The Officer | Pick. Up. That. Can. | the officer, slower and lower every word, losing patience |
| [ ] | `can_litter1.mp3` | The Officer | That is not the trash can. Nothing is the trash can. Pick up that can. | the officer, slow and deep, as if he has grown very large |
| [ ] | `can_bin1.mp3` | The Bin | Thank you. Delicious. | a deep, hollow, echoing voice from inside a metal bin, ending in a small burp |
| [ ] | `can_swap1.mp3` | The Can | Pick up that can. | the officer's line, tinny and high, as if spoken from inside an empty drinks can |
| [ ] | `can_clone1.mp3` | Another Can | Pick up that can. Pick up that can. Pick up that can. | tinny and high, several voices not quite together |
| [ ] | `can_full1.mp3` | The Can | No more room. Pick up all the cans. | tinny and high, delighted with itself |

### The propaganda dreams

(The Loyalty Quiz's questions, `quiz_q1` onwards, are read out too: each is its question.)

#### Kneel Before Her (`adore`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `adore_hello1.mp3` | The Administrator | You may look upon me. On your knees, of course. | her own voice: warm, regal, a little vain |

#### Roses for Her (`roses`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `roses_hello1.mp3` | The Administrator | Flowers? For me? How predictable. How lovely. | her own voice: warm, regal, a little vain |

#### Mirror, Mirror (`mirror`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `mirror_hello1.mp3` | The Administrator | Tell me what you see. | her own voice: warm, regal, a little vain |

#### The Saviour (`saviour`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `saviour_stop1.mp3` | The Administrator | STOP! | her own voice: warm, regal, a little vain |
| [ ] | `saviour_soldiers1.mp3` | The Administrator | Come, my soldiers. Protect them. | her own voice: warm, regal, a little vain |
| [ ] | `saviour_safe1.mp3` | The Administrator | You are safe now, my children. You are always safe with me. | her own voice: warm, regal, a little vain |

#### The Loyalty Quiz (`quiz`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `quiz_hello1.mp3` | The Administrator | Good evening, citizens. Let us see how well you know your city. | her own voice: warm, regal, a little vain |
| [ ] | `quiz_end1.mp3` | The Administrator | Well answered. The city is proud of you. | her own voice: warm, regal, a little vain |
| [ ] | `quiz_rebel1.mp3` | The Administrator | Officers. Remove him. | her own voice: warm, regal, a little vain |
| [ ] | `quiz_resume1.mp3` | The Administrator | Where were we? Ah, yes. | her own voice: warm, regal, a little vain |

#### Record Harvest (`harvest`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `harvest_hello1.mp3` | The Administrator | Citizens! The harvest is ripe and the quota is waiting. Bring it in! | her own voice |
| [ ] | `harvest_medal1.mp3` | The Administrator | For glorious labour beyond the plan: the Order of the Golden Sheaf. | her own voice |

#### The Union Shift (`shift`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `shift_hello1.mp3` | The Administrator | My workers! Today's norm is one hundred percent. Tomorrow's is fourteen hundred. Why wait? | her own voice |
| [ ] | `shift_double1.mp3` | The Administrator | Double norm! Every blow counts twice! | her own voice |
| [ ] | `shift_hero1.mp3` | The Administrator | A new Hero of Labour! Hang their portrait beside mine! | her own voice |
| [ ] | `shift_idle1.mp3` | The Administrator | I see you standing there. Back to work, citizen! | her own voice |

#### Careless Talk (`spy`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `spy_hello1.mp3` | The Administrator | Careless talk costs lives, my children. There is a traitor among you. Watch them closely. | her own voice |
| [ ] | `spy_caught1.mp3` | The Administrator | Time is up. The traitor is revealed. I thank my vigilant citizens. | her own voice |
| [ ] | `spy_chant_male1.mp3` | A diner (man), cheering | Glory to the Administrator! |  |
| [ ] | `spy_chant_female1.mp3` | A diner (woman), cheering | Glory to the Administrator! |  |
| [ ] | `spy_flat_male1.mp3` | The spy (man), flat and bored | Glory to the Administrator. |  |
| [ ] | `spy_flat_female1.mp3` | The spy (woman), flat and bored | Glory to the Administrator. |  |
| [ ] | `spy_whisper_male1.mp3` | The spy (man), whispering | The old bridge. After curfew. Don't be late. |  |
| [ ] | `spy_whisper_female1.mp3` | The spy (woman), whispering | The old bridge. After curfew. Don't be late. |  |
| [ ] | `spy_ready1.mp3` | The officer | Ready! |  |
| [ ] | `spy_aim1.mp3` | The officer | Aim! |  |
| [ ] | `spy_fire1.mp3` | The officer | Fire! |  |

#### The Newsreel (`newsreel`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `newsreel_hello1.mp3` | The Administrator | Welcome to my City Seventeen, where every citizen smiles, and every smile is sincere! | her own voice |
| [ ] | `newsreel_end1.mp3` | The Administrator | And so another happy day draws to a close. Goodnight, my City Seventeen! | her own voice |

#### Two Minutes of Hate (`hate`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `hate_hello1.mp3` | The Administrator | Citizens! Behold the enemy of the people. Let him hear you! | her own voice |
| [ ] | `hate_end1.mp3` | The Administrator | The enemy fades. Love returns. Love me. | her own voice |

#### The Mass Games (`massgames`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `massgames_hello1.mp3` | The Administrator | Cards ready! Together, you are my portrait. | her own voice |
| [ ] | `massgames_flip1.mp3` | The Administrator | FLIP! | her own voice |

#### On-the-Spot Guidance (`guidance`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `guidance_hello1.mp3` | The Administrator | Show me your work. I have so much guidance to give. | her own voice |
| [ ] | `guidance_end1.mp3` | The Administrator | Excellent. I have improved everything here simply by looking at it. | her own voice |

#### The Scrap Drive (`scrap`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `scrap_hello1.mp3` | The Administrator | Every pot, every pan, every bucket. The city needs your scrap! | her own voice |

#### Flowers for the Liberators (`flowers`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `flowers_hello1.mp3` | The Administrator | My soldiers are marching home. Show them how much you love them. | her own voice |

#### Duck and Cover (`duck`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `duck_hello1.mp3` | Sunny the Scanner | Hi, citizens! I'm Sunny! The nasty terrorists have built a rocket. If they launch it, what do we do? We duck, and cover! |  |
| [ ] | `duck_siren1.mp3` | Sunny the Scanner | Rocket launch! Duck and cover! Crouch beside a table, quick as you can! |  |
| [ ] | `duck_clear1.mp3` | Sunny the Scanner | All clear! The Combine protects us. Wasn't that fun? |  |

#### Ravenholm (`ravenholm`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `ravenholm_rise1.mp3` | Father Grigori | RISE, my children! Rise from your graves and FEAST! |  |
| [ ] | `ravenholm_stop1.mp3` | The Administrator | Begone, false priest! These citizens are under MY protection. | her own voice |
| [ ] | `ravenholm_safe1.mp3` | The Administrator | You see? Only I can keep you safe. Never forget it. | her own voice |
| [ ] | `ravenholm_vort1.mp3` | A Vortigaunt | The Vortessence sees through the false light. Behold what is true. |  |
| [ ] | `ravenholm_good1.mp3` | Father Grigori | Hah! Back to your rest, poor souls! Not one of these children shall be harmed! |  |
| [ ] | `ravenholm_defeat1.mp3` | The Administrator | No... NO! This is MY dream! | her own voice |

#### battleline (`battleline`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `battleline_hello1.mp3` | The Administrator | My brave citizens! The terrorists are coming. Take up arms beside my soldiers and hold the line! | her own voice |
| [ ] | `battleline_giant1.mp3` | The Administrator | Look at the size of that one! Everyone, fire! | her own voice |
| [ ] | `battleline_traitor1.mp3` | The Administrator | You fired on MY soldiers? Manhacks! Deal with this traitor. | her own voice |
| [ ] | `battleline_turned1.mp3` | The Administrator | A traitor wants to be a rebel? Then be one. Forever. | her own voice |
| [ ] | `battleline_doom1.mp3` | Overwatch | Sector overrun. Hostiles beyond containment. Requesting immediate air support. |  |
| [ ] | `battleline_air1.mp3` | The Administrator | Did you think I would abandon you? Behold my wings! | her own voice |
| [ ] | `battleline_held1.mp3` | The Administrator | The line held! Every one of you is a hero of my city. | her own voice |

#### vortwar (`vortwar`)

| Done | File | Who | Words | How it should sound |
|---|---|---|---|---|
| [ ] | `vortwar_in1.mp3` | A Vortigaunt | The Vortessence sees through her false light. Come, stand with us, and see what is true. |  |
| [ ] | `vortwar_answer11.mp3` | A Vortigaunt | She says she protects you. Ask who built the walls. |  |
| [ ] | `vortwar_answer21.mp3` | A Vortigaunt | Her smile is painted on. Look closer. |  |
| [ ] | `vortwar_answer31.mp3` | A Vortigaunt | We were chained as you are chained. We are free. You can be. |  |
| [ ] | `vortwar_answer41.mp3` | A Vortigaunt | The dream is hers. The waking is yours. |  |
| [ ] | `vortwar_loyal1.mp3` | The Administrator | Begone, false spirits! These citizens are MINE. | her own voice |
| [ ] | `vortwar_shatter1.mp3` | A Vortigaunt | Her light was never yours. Wake, and see. |  |


## 5. Citizens showing the way

When you chat with a citizen and they notice what you need, they say one of these, then point the way (a marker and a trail) or, if they like you, walk you there. Folder: **`garrysmod/sound/livingcity/citizens/`**. Each line wants a man's take and a woman's (the citizen's own voice): `advice_bins_male1.wav`, `advice_bins_female1.wav`; more takes `...2`, `...3`. Without a recording they speak with Half-Life 2's own citizen voice, and the words still show.

| Done | Man's file | Woman's file | When | Says |
|---|---|---|---|---|
| [ ] | `advice_bins_male1.wav` | `advice_bins_female1.wav` | Advice | You look half-starved. Try the bins. Nobody checks them as often as they should. |
| [ ] | `advice_buy_male1.wav` | `advice_buy_female1.wav` | Advice | You look hungry, and you've got credits. The Commissary has food. Go on. |
| [ ] | `advice_drink_own_male1.wav` | `advice_drink_own_female1.wav` | Advice | You've something to drink in your coat. Drink it. You look awful. |
| [ ] | `advice_eat_own_male1.wav` | `advice_eat_own_female1.wav` | Advice | You've got food on you, haven't you? Eat it, before someone takes it off you. |
| [ ] | `advice_home_male1.wav` | `advice_home_female1.wav` | Advice | You look lost. Your block's that way. Get there before curfew. |
| [ ] | `advice_housing_male1.wav` | `advice_housing_female1.wav` | Advice | Nowhere to sleep? They hand out rooms. Go and ask, it's not far. |
| [ ] | `advice_intake_male1.wav` | `advice_intake_female1.wav` | Advice | You're new, aren't you? Get yourself on the register before anything else. Over that way. |
| [ ] | `advice_job_male1.wav` | `advice_job_female1.wav` | Advice | No work? The Union doesn't like idle hands. Find a job before they find you. |
| [ ] | `advice_labor_male1.wav` | `advice_labor_female1.wav` | Advice | Registered, but no work? Nobody gets a room without a work assignment. Go and get one. |
| [ ] | `advice_nowhere_male1.wav` | `advice_nowhere_female1.wav` | No such place on this map | Can't help you there, friend. I wish I could. |
| [ ] | `advice_ration_male1.wav` | `advice_ration_female1.wav` | Advice | Your ration's waiting. Don't leave it too long, they notice who doesn't come. |
| [ ] | `advice_shift_male1.wav` | `advice_shift_female1.wav` | Advice | Short on credits? Get to work. A shift pays. |
| [ ] | `advice_water_male1.wav` | `advice_water_female1.wav` | Advice | You look parched. There's water near here. Drink before you fall down. |
| [ ] | `advice_work_male1.wav` | `advice_work_female1.wav` | Advice | Hungry, and no card? Work a shift. It's the only way they give you one. |
| [ ] | `lead_arrive_male1.wav` | `lead_arrive_female1.wav` | Walking you there | Here. Don't tell anyone I helped you. |
| [ ] | `lead_arrive2_male1.wav` | `lead_arrive2_female1.wav` | Walking you there | This is it. Good luck. |
| [ ] | `lead_cantgo_male1.wav` | `lead_cantgo_female1.wav` | Walking you there | I can't go there. It's that way, look. |
| [ ] | `lead_giveup_male1.wav` | `lead_giveup_female1.wav` | Walking you there | Fine. It's that way. Find it yourself. |
| [ ] | `lead_start_male1.wav` | `lead_start_female1.wav` | Walking you there | Come on, I'll show you. Stay close. |
| [ ] | `lead_start2_male1.wav` | `lead_start2_female1.wav` | Walking you there | Here, let me show you. Follow me. |
| [ ] | `lead_wait_male1.wav` | `lead_wait_female1.wav` | Walking you there | Keep up! I'm not waiting all day. |

## 6. The Citizen Information clerk

The clerk behind the Citizen Information desk: flat, tired, official. Folder: **`garrysmod/sound/livingcity/clerk/`**. One voice for every clerk (or record a man's and a woman's take and keep whichever fits). Without a recording, a terminal's chime, and the words show.

| Done | File | The question asked | Says |
|---|---|---|---|
| [ ] | `rations1.wav` | Rations and ration cards | Rations are issued at the ration dispenser. Each ration requires one ration card. Ration cards are issued on completion of a Union shift: one card per shift. No shift, no card. No card, no ration. Your first allocation after arrival is guaranteed. |
| [ ] | `work1.wav` | Work | All residents are assigned labor. Report to Labor Assignment for your assignment. Shifts pay credits and Civil Standing, and each completed shift earns one ration card. Your shifts are listed on your work board. |
| [ ] | `housing1.wav` | Housing | Housing Allocation assigns rooms to registered residents with a work assignment. Your room is in your housing block. Sleep there, keep your possessions there, and be there at curfew. |
| [ ] | `papers1.wav` | Papers and registration | Every resident is registered at Civil Intake and carries identity papers at all times. Present them to any Civil Protection unit on request. Lost papers are replaced at Civil Intake, for a fee. |
| [ ] | `law1.wav` | The law | The city's laws are posted on the law board. Ignorance of the law is not a defence. Comply with Civil Protection. Do not run in their presence. Report anticivil activity. |
| [ ] | `curfew1.wav` | Curfew | Curfew is announced two minutes in advance. When it begins, return to your housing block and remain there until morning. Residents found outside during curfew will be detained. |
| [ ] | `standing1.wav` | Civil Standing | Civil Standing measures your value to the city. Work, compliance and reporting raise it. Infractions lower it. Below zero, ration privileges are withdrawn. High standing qualifies a resident for Civil Protection. |
| [ ] | `cp1.wav` | Joining Civil Protection | Residents of sufficient Civil Standing may apply to Civil Protection. Applications are made on your work board, under Factions. Civil Protection serves the city. Consider it. |
| [ ] | `closed1.wav` | (said between answers) | This desk is closed. Come back later. |
| [ ] | `greet1.wav` | (said between answers) | Citizen Information. State your question. |
| [ ] | `greet_curt1.wav` | (said between answers) | Make it quick. There are others waiting. |
| [ ] | `greet_warm1.wav` | (said between answers) | Good day, citizen. Thank you for your cooperation. How may I help you? |
| [ ] | `noplace1.wav` | (said between answers) | That facility is not available in this sector. |
| [ ] | `route1.wav` | (said between answers) | The route is marked. Follow it. Next. |
| [ ] | `wanted1.wav` | (said between answers) | You have an outstanding warrant. Remain where you are. Civil Protection is aware of you. |
| [ ] | `where1.wav` | (said between answers) | Which location? I will mark the route. |

## 7. The old-timer

The old man who gives advice: warm, worn, a little wry. Folder: **`garrysmod/sound/livingcity/oldtimer/`**. For "Is anyone fighting back?" he goes on to say where the Resistance gathers (that part changes with the map, so it only shows as words). Without a recording, Half-Life 2's own citizen voice.

| Done | File | The question asked | Says |
|---|---|---|---|
| [ ] | `headdown1.wav` | Any advice for someone like me? | Keep your head down, your papers handy, and your mouth shut. The ones who last are the ones nobody remembers. |
| [ ] | `curfew1.wav` | What about curfew? | When the voice says two minutes, it means one. Be indoors. I've seen what they do to the ones who are late, and so have the walls. |
| [ ] | `scanners1.wav` | The flying things? | Scanners. They take your picture. Don't stand under them, don't do anything worth photographing, and if one flashes you, walk, don't run. |
| [ ] | `running1.wav` | Why does everyone walk so slowly? | Run in front of a cop and you're a suspect. Walk. Even when your heart's going like a train, walk. |
| [ ] | `bins1.wav` | Where do people find food, really? | The bins. Commissary scraps, things people drop. Nobody checks them as often as they should. Here, I'll show you the nearest. |
| [ ] | `water1.wav` | And water? | Sinks, the machines, open water if you're desperate. Boil anything that isn't from a tap, or you'll be coughing for a week. |
| [ ] | `fishing1.wav` | Anything else to eat out there? | Fish, if you can find a line. Cook what you catch on a stove or a fire barrel. Raw meat will turn your stomach. |
| [ ] | `dealer1.wav` | Things the Commissary doesn't sell? | There's a man who trades in what you can't buy. Don't tell him I sent you, and don't let a cop see you with him. That way. |
| [ ] | `lockpick1.wav` | What's a lockpick good for? | Doors that aren't yours. Rooms people left in a hurry. Be quick, be quiet, and never in front of a unit. |
| [ ] | `resistance1.wav` | Is anyone fighting back? | You didn't hear it from me. |
| [ ] | `hint_hungry1.wav` | What's troubling him (said instead of his greeting) | My legs won't take me to the bins any more. Some days I don't eat at all. |
| [ ] | `thanks_hungry1.wav` | You helped him with it | Food. Real food. You don't know what that means to an old man. |
| [ ] | `hint_thirsty1.wav` | What's troubling him (said instead of his greeting) | The tap on my floor's been dry a week. Carrying water up those stairs, at my age... |
| [ ] | `thanks_thirsty1.wav` | You helped him with it | Water. Bless you. I'll make it last. |
| [ ] | `hint_cough1.wav` | What's troubling him (said instead of his greeting) | This cough. Twenty years I've had it. The Commissary wants more for its medicine than I see in a month. |
| [ ] | `thanks_cough1.wav` | You helped him with it | Medicine? For me? I'll sleep tonight, for the first time in a long while. |
| [ ] | `hint_card1.wav` | What's troubling him (said instead of his greeting) | Some young thug took my ration card in the line. I'm too old to work a shift for another. |
| [ ] | `thanks_card1.wav` | You helped him with it | A card? You worked for that. I won't forget it. Not ever. |
| [ ] | `hint_smoke1.wav` | What's troubling him (said instead of his greeting) | What I wouldn't give for a smoke. Even the Union's, and those taste of floor sweepings. |
| [ ] | `thanks_smoke1.wav` | You helped him with it | Ah. Now that's a kindness. Sit with me while I have it. |
| [ ] | `food1.wav` | (said between answers) | For me? You're a good one. I won't forget it. |
| [ ] | `greet1.wav` | (said between answers) | Sit down, sit down. My knees aren't what they were. What do you want to know? |
| [ ] | `greet_friend1.wav` | (said between answers) | Ah, you again. Good. Not many come back. |
| [ ] | `keepsake1.wav` | (said between answers) | You've done more for me than my own family. Here. My old picks. I won't be needing them, and you might. Doors don't stay locked for people who know how. |
| [ ] | `keepsake_again1.wav` | (said between answers) | Sit a while. The city's quieter when there's someone to share it with. |
| [ ] | `nothing1.wav` | (said between answers) | Kind of you. But nothing I need, not that. |
| [ ] | `notyet1.wav` | (said between answers) | Hm. Ask me that when I know you better. |
| [ ] | `nowhere1.wav` | (said between answers) | There used to be one. Not in this part of town, not any more. |
| [ ] | `stranger1.wav` | (said between answers) | I don't know you. Ask me something simple. |

## 8. Machines

The ration dispenser and the vending machines, in a flat machine voice (a Combine terminal's). Folder: **`garrysmod/sound/livingcity/machines/`**. Without a recording, the machine's beep.

| Done | File | Which machine | Says |
|---|---|---|---|
| [ ] | `dispenser_blackout1.wav` | Ration dispenser | Power failure. Service unavailable. |
| [ ] | `dispenser_empty1.wav` | Ration dispenser | Distribution suspended. |
| [ ] | `dispenser_nocard1.wav` | Ration dispenser | No ration card detected. Report for labor assignment. |
| [ ] | `dispenser_short1.wav` | Ration dispenser | Supply shortfall. Try again shortly. |
| [ ] | `dispenser_suspended1.wav` | Ration dispenser | Ration privileges suspended. |
| [ ] | `dispenser_unregistered1.wav` | Ration dispenser | Identity not found. Report to Civil Intake. |
| [ ] | `dispenser_wait1.wav` | Ration dispenser | Allocation not yet available. Return later. |
| [ ] | `dispenser_withheld1.wav` | Ration dispenser | Allocation withheld. Noncompliance is recorded. |
| [ ] | `vending_blackout1.wav` | Vending machine | Power failure. Service unavailable. |
| [ ] | `vending_credits1.wav` | Vending machine | Insufficient credits. |

## 9. The Colonel

The old fighter at the Resistance camp (an old man's face, `lc_colonel_model`; Odessa Cubbage himself answers her speeches, section 12): weary, dry, kind underneath, a ghost who doesn't quite know it at first. Folder: **`garrysmod/sound/livingcity/colonel/`**. Only the player he's talking to hears these. Without a recording he's silent and the words show. `job_unit` names a unit's designation where it says %s: record it without the number ("Designation... still walking around").

| Done | File | When | Says |
|---|---|---|---|
| [ ] | `ask11.wav` | What's happening to you? (by how ghostly he looks) | Happening? I'm old. Old men look how they look. Ask me something useful. |
| [ ] | `ask21.wav` | What's happening to you? (by how ghostly he looks) | You're tired, and the light's bad in here. That's all it is. Don't stare, it's rude. |
| [ ] | `ask31.wav` | What's happening to you? (by how ghostly he looks) | You've seen the others don't answer me. I saw it too, a long time ago. I stopped asking why. Leave it alone a while longer. |
| [ ] | `ask41.wav` | What's happening to you? (by how ghostly he looks) | All right. You've earned it. I didn't get out of the first camp. They burned it with us inside, my brother and me both. Nobody here can see me but the ones who keep coming back. I don't know what that makes me. I know I'm still here, and I know you can hear me. That'll have to do for the pair of us. |
| [ ] | `debrief_clean1.wav` | Debrief me | Clean. Nobody saw you, nobody followed you home. That's how it's done. |
| [ ] | `debrief_failed1.wav` | Debrief me | We lost that one. Learn why before you try again. |
| [ ] | `debrief_messy1.wav` | Debrief me | You got it done, and half the city knows your face. Next time, slower. |
| [ ] | `debrief_none1.wav` | Debrief me | Nothing to report? Then go and do something worth reporting. |
| [ ] | `greet1.wav` | Greeting (by how well he knows you) | Another one. Sit, if you like. Nobody else does. |
| [ ] | `greet_back1.wav` | Greeting (by how well he knows you) | You came back. Most don't. |
| [ ] | `greet_known1.wav` | Greeting (by how well he knows you) | You've worked it out by now, haven't you. Nobody else can see me. I didn't get out of the first camp. None of us did, not really. But you keep coming, so I keep telling you what I know. |
| [ ] | `greet_trust1.wav` | Greeting (by how well he knows you) | The quartermaster won't look at me, you know. Hasn't for years. Sit. |
| [ ] | `intel_march1.wav` | What's the word? | They're walking one of ours to the cells. Right now. You can still get to them. |
| [ ] | `intel_quiet1.wav` | What's the word? | Quiet. Too quiet. Rest while you can. |
| [ ] | `intel_supply1.wav` | What's the word? | Supply drop coming in. Guarded, but not well. Go. |
| [ ] | `intel_sweep1.wav` | What's the word? | They're coming into our ground. Now. Clear what you can carry and go. |
| [ ] | `intel_sympathizer1.wav` | What's the word? | That one. They're with us, they just don't know it yet. Ask them to keep watch. |
| [ ] | `job_medicine1.wav` | What he needs (end of his greeting) | Our wounded are in a bad way. Three of the Union's medicines would see them through. |
| [ ] | `job_tags1.wav` | What he needs (end of his greeting) | They took my brother's tags when they took him. They keep things like that on their own ground. I'd like them back. |
| [ ] | `job_unit1.wav` | What he needs (end of his greeting) | One more thing. The unit who lit the first camp. Designation %s. Still walking around. |
| [ ] | `job_unit_none1.wav` | What he needs (end of his greeting) | There's a unit I'd like to see in the ground. When he's back on the streets, I'll tell you his number. |
| [ ] | `nothing1.wav` | Between answers | That's not what I need. |
| [ ] | `thanks_medicine1.wav` | You helped | That'll keep them breathing. Good. You think of others. That's rarer than courage. |
| [ ] | `thanks_tags1.wav` | You helped | His. His name, scratched in by hand. Here. He'd want you to have this. It never missed for him. |
| [ ] | `thanks_unit1.wav` | You helped | Is it done? ...It is. I can feel it. Thank you. I don't think I'll need anything else. |
| [ ] | `whisper_base1.wav` | Heard anything strange? | The master core, the big one from their nexus. Get it to our scientist and let him crack it open. All their screens change. |
| [ ] | `whisper_bloom1.wav` | Heard anything strange? | Let the weeds take the streets, every crack full, and leave them be. The city starts to dance. |
| [ ] | `whisper_fire1.wav` | Heard anything strange? | Set fifteen fires burning at once. Then watch what the city does. |
| [ ] | `whisper_hard1.wav` | Heard anything strange? | Kill the city's lights and keep them dead for a quarter of an hour. Somebody starts a party in the dark, and nobody can stop it. |
| [ ] | `whisper_harpies1.wav` | Heard anything strange? | When the streets run red fast enough, a dozen dead in a few minutes, something comes down out of the sky. Something with wings. |
| [ ] | `whisper_marrow1.wav` | Heard anything strange? | When the dead pile up faster than they can be carried off, or the infested hold half the city, the bones get restless. |
| [ ] | `whisper_none1.wav` | Heard anything strange? | Nothing you haven't heard from me already. |
| [ ] | `whisper_plane1.wav` | Heard anything strange? | Do the morning drill, five of you or more, and do it perfectly. Not one mistake. Then look up. |
| [ ] | `whisper_shalom1.wav` | Heard anything strange? | Six people dancing in a ring, in this city. Imagine it. They say the whole city joins in. |
| [ ] | `whisper_standup1.wav` | Heard anything strange? | Keep the city red for three quarters of an hour straight. The crowd starts wanting a show. |
| [ ] | `whisper_water1.wav` | Heard anything strange? | There's a priest who'd swallow anything holy. Feed him the master core and pray for rain. A lot of rain. |

## 10. What named citizens say

A small bank of lines the city's named citizens say everywhere: answering you in free talk (the hosted model picks the one that fits), walking up to you when the director sends them, and as their minds give way. Written by what the line does, not what it is about, with no names, jobs, places or times in them, so any citizen can say any line. Folder: **`garrysmod/sound/livingcity/citizens/`** (the same as section 5). Each line wants a man's take and a woman's: `say_dunno_male1.wav`, `say_dunno_female1.wav`; more takes `...2`, `...3`. Keep them short and flat: tired people, speaking low. An opener is said just before another line, so record it to run on ("Listen." ... "You should go. Now."). Without a recording they speak with Half-Life 2's own citizen voice, and the words still show. How it works: `docs/features/recorded-lines.md`.

| Done | Man's file | Woman's file | When | Says |
|---|---|---|---|---|
| | | | **Openers (a word or two before another line)** | |
| [x] | `say_open_listen_male1.wav` | `say_open_listen_female1.wav` | Opener: before something that matters | Listen. |
| [x] | `say_open_look_male1.wav` | `say_open_look_female1.wav` | Opener: before a refusal or a plain truth | Look. |
| [x] | `say_open_please_male1.wav` | `say_open_please_female1.wav` | Opener: before asking, or begging off | Please. |
| [x] | `say_open_quiet_male1.wav` | `say_open_quiet_female1.wav` | Opener: before anything dangerous to say | Keep your voice down. |
| [x] | `say_open_well_male1.wav` | `say_open_well_female1.wav` | Opener: thinking it over | Well. |
| [x] | `say_open_you_male1.wav` | `say_open_you_female1.wav` | Opener: stopping someone | You. |
| | | | **Hello** | |
| [x] | `say_greet_cold_male1.wav` | `say_greet_cold_female1.wav` | Greeting someone they dislike | What do you want? |
| [x] | `say_greet_guarded_male1.wav` | `say_greet_guarded_female1.wav` | Greeting a stranger they are wary of | Do I know you? |
| [x] | `say_greet_plain_male1.wav` | `say_greet_plain_female1.wav` | Greeting anyone | Hey. Still here, huh? Me too. |
| [x] | `say_greet_unit_male1.wav` | `say_greet_unit_female1.wav` | Spoken to by a unit | No trouble here, officer. |
| [x] | `say_greet_warm_male1.wav` | `say_greet_warm_female1.wav` | Greeting someone they like | Oh, it's you. Good to see a friendly face. |
| | | | **Goodbye** | |
| [x] | `say_bye_cold_male1.wav` | `say_bye_cold_female1.wav` | Ending a conversation they want no more of | We're done here. |
| [x] | `say_bye_plain_male1.wav` | `say_bye_plain_female1.wav` | Ending a conversation | I should get going. |
| [x] | `say_bye_warm_male1.wav` | `say_bye_warm_female1.wav` | Parting from someone they like | Take care of yourself. I mean it. |
| | | | **Yes, no, perhaps** | |
| [x] | `say_later_male1.wav` | `say_later_female1.wav` | Putting it off: the wrong time or place | Not now. Not here. |
| [x] | `say_maybe_male1.wav` | `say_maybe_female1.wav` | Not sure | Maybe. I'd have to think about it. |
| [x] | `say_no_male1.wav` | `say_no_female1.wav` | Refusing | Sorry, but no. |
| [x] | `say_no_hard_male1.wav` | `say_no_hard_female1.wav` | Refusing for good | No. And don't ask me again. |
| [x] | `say_yes_male1.wav` | `say_yes_female1.wav` | Agreeing to something | Yeah. All right. |
| [x] | `say_yes_warm_male1.wav` | `say_yes_warm_female1.wav` | Agreeing, for someone they like | For you? Of course. |
| | | | **What they know** | |
| [x] | `say_ask_else_male1.wav` | `say_ask_else_female1.wav` | Asked for something they can't give | You're asking the wrong person. |
| [x] | `say_cant_say_male1.wav` | `say_cant_say_female1.wav` | Asked what can't be said aloud | I can't talk about that. You know why. |
| [x] | `say_dunno_male1.wav` | `say_dunno_female1.wav` | Asked something they don't know, or won't say | I wouldn't know anything about that. |
| [x] | `say_dunno_scared_male1.wav` | `say_dunno_scared_female1.wav` | Asked something dangerous | I don't know, and I don't want to know. |
| [x] | `say_heard_male1.wav` | `say_heard_female1.wav` | Asked about a rumour | I've heard things. Everyone has. |
| [x] | `say_truth_male1.wav` | `say_truth_female1.wav` | Asked how things are, by someone they trust | Honestly? It's as bad as it looks. |
| | | | **How they are** | |
| [x] | `say_state_angry_male1.wav` | `say_state_angry_female1.wav` | Asked how they are: close to breaking | I've had about all I can take. |
| [x] | `say_state_fine_male1.wav` | `say_state_fine_female1.wav` | Asked how they are: all right | Getting by. That's all I can do. |
| [x] | `say_state_hopeful_male1.wav` | `say_state_hopeful_female1.wav` | Asked how they are: in good spirits | It can't last forever. Nothing ever does. |
| [x] | `say_state_hungry_male1.wav` | `say_state_hungry_female1.wav` | Asked how they are: hungry | I haven't had a real meal in days. |
| [x] | `say_state_lonely_male1.wav` | `say_state_lonely_female1.wav` | Asked how they are: starved of company | It's good to just talk to someone. |
| [x] | `say_state_low_male1.wav` | `say_state_low_female1.wav` | Asked how they are: in despair | What's the point? Really, what is the point? |
| [x] | `say_state_scared_male1.wav` | `say_state_scared_female1.wav` | Asked how they are: afraid | I'm scared. Aren't you? |
| [x] | `say_state_tired_male1.wav` | `say_state_tired_female1.wav` | Asked how they are: worn out | I'm tired. Just so tired. |
| | | | **Answering how they were spoken to** | |
| [x] | `say_agree_male1.wav` | `say_agree_female1.wav` | Agreeing with an opinion | You're not wrong. |
| [x] | `say_disagree_male1.wav` | `say_disagree_female1.wav` | Disagreeing with an opinion | Well, I don't see it that way. |
| [x] | `say_insulted_male1.wav` | `say_insulted_female1.wav` | Insulted | Hey. There's no need for that. |
| [x] | `say_laugh_male1.wav` | `say_laugh_female1.wav` | Something funny was said | Ha. That's the first laugh I've had all week. |
| [x] | `say_sorry_male1.wav` | `say_sorry_female1.wav` | Backing down | I'm sorry. I didn't mean anything by it. |
| [x] | `say_thanks_male1.wav` | `say_thanks_female1.wav` | Thanked for a kindness | Thank you. I won't forget it. |
| [x] | `say_thanks_big_male1.wav` | `say_thanks_big_female1.wav` | A real kindness: food, medicine, help | You didn't have to do that. Thank you. |
| [x] | `say_threatened_male1.wav` | `say_threatened_female1.wav` | Threatened | I don't want any trouble. |
| | | | **The Combine** | |
| [x] | `say_careful_male1.wav` | `say_careful_female1.wav` | Warning someone who is talking too freely | Careful. The walls have ears. |
| [x] | `say_fear_units_male1.wav` | `say_fear_units_female1.wav` | A warning about Civil Protection | Stay away from the units today. They're in a mood. |
| [x] | `say_hate_quiet_male1.wav` | `say_hate_quiet_female1.wav` | A disloyal citizen, to someone they trust | One day they'll answer for all of it. |
| [x] | `say_loyal_male1.wav` | `say_loyal_female1.wav` | A loyal citizen, on the Combine | The Administrator knows best. Everyone knows that! |
| [x] | `say_loyal_warn_male1.wav` | `say_loyal_warn_female1.wav` | Hearing sedition, and not liking it | You shouldn't say things like that. Someone will hear. |
| [x] | `say_obey_male1.wav` | `say_obey_female1.wav` | Advice to a newcomer | Keep your head down and do what they say. That's how you make it. |
| [x] | `say_units_near_male1.wav` | `say_units_near_female1.wav` | Won't talk with a unit close | Not with them standing right there. |
| | | | **The Resistance** | |
| [x] | `say_res_deny_male1.wav` | `say_res_deny_female1.wav` | Asked about the Resistance | I don't know anything about any Resistance. |
| [x] | `say_res_hint_male1.wav` | `say_res_hint_female1.wav` | A sympathizer, hinting to someone they trust | There are people. That's all I'll say. |
| [x] | `say_res_refuse_male1.wav` | `say_res_refuse_female1.wav` | Asked to help the Resistance, and afraid | I've got people to think about. Leave me out of it. |
| [x] | `say_res_respect_male1.wav` | `say_res_respect_female1.wav` | Quiet approval of the Resistance | Whoever they are, good luck to them. |
| [x] | `say_res_side_male1.wav` | `say_res_side_female1.wav` | A sympathizer, offering help | If someone needed a door left open, mine would be. |
| | | | **Warnings and tips** | |
| [x] | `say_tip_help_male1.wav` | `say_tip_help_female1.wav` | Offering help | If you need something, ask. Quietly. |
| [x] | `say_tip_trouble_male1.wav` | `say_tip_trouble_female1.wav` | The city's mood is turning | There's gonna be trouble tonight. I can feel it. |
| [x] | `say_warn_asked_male1.wav` | `say_warn_asked_female1.wav` | A warning: they are being looked for | Someone's been asking about you. |
| [x] | `say_warn_go_male1.wav` | `say_warn_go_female1.wav` | A warning: get away | You should go. Now. |
| [x] | `say_warn_informer_male1.wav` | `say_warn_informer_female1.wav` | A warning about informants | Watch who you talk to. Not everyone here is a friend. |
| [x] | `say_warn_watched_male1.wav` | `say_warn_watched_female1.wav` | A warning: an informant or a unit has an eye on them | You're being watched. Don't look now and don't turn around. |
| | | | **Asking and giving** | |
| [x] | `say_ask_food_male1.wav` | `say_ask_food_female1.wav` | Hungry, asking a player | You got anything to eat? Anything? |
| [x] | `say_ask_help_male1.wav` | `say_ask_help_female1.wav` | In trouble, asking a player | I need help. I've got nobody else to ask. |
| [x] | `say_ask_smoke_male1.wav` | `say_ask_smoke_female1.wav` | Craving, asking a player | You wouldn't have a smoke on you, would you? |
| [x] | `say_decline_gift_male1.wav` | `say_decline_gift_female1.wav` | Refusing a gift | I can't take that. Keep it. |
| [x] | `say_offer_male1.wav` | `say_offer_female1.wav` | Giving something | Here. Take it. Don't say where you got it. |
| | | | **As a mind gives way** | |
| [x] | `say_break_accuse_male1.wav` | `say_break_accuse_female1.wav` | Accusing someone of informing | That one! That one talks to Civil Protection! |
| [x] | `say_break_accused_male1.wav` | `say_break_accused_female1.wav` | Accused of informing | That's a lie! I never told them anything! |
| [x] | `say_break_beaten_male1.wav` | `say_break_beaten_female1.wav` | Being beaten | Stop! Please, I didn't do anything! |
| [x] | `say_break_binge_male1.wav` | `say_break_binge_female1.wav` | Drinking in the street | Leave me alone. Just let me have this. |
| [x] | `say_break_defy_male1.wav` | `say_break_defy_female1.wav` | Defiance: painting over a poster | They can't scare all of us forever. |
| [x] | `say_break_despair_male1.wav` | `say_break_despair_female1.wav` | Despair | I can't. I just can't anymore. |
| [x] | `say_break_inform_male1.wav` | `say_break_inform_female1.wav` | Informing to a unit | Officer. I've got something you'll want to hear. |
| [x] | `say_break_seek_male1.wav` | `say_break_seek_female1.wav` | Finding a friend | There you are. I've been looking for you. |
| [ ] | `say_break_share_male1.wav` | `say_break_share_female1.wav` | Sharing food | Go on, take half. You need it more than I do. |
| [x] | `say_break_steady_male1.wav` | `say_break_steady_female1.wav` | Steadying the people near | Easy. Easy now. We're going to be ok, right? |
| [x] | `say_break_tantrum_male1.wav` | `say_break_tantrum_female1.wav` | A tantrum, in a unit's face | I've had enough! Do you hear me? Enough! |
| | | | **What they saw** | |
| [x] | `say_grief_male1.wav` | `say_grief_female1.wav` | A friend arrested or dead | They took my friend. Just dragged them off. |
| [x] | `say_saw_beating_male1.wav` | `say_saw_beating_female1.wav` | Someone beaten in front of them | Don't look. Just keep walking. |
| [x] | `say_saw_death_male1.wav` | `say_saw_death_female1.wav` | Someone killed in front of them | Oh God. Oh God, no. |
| | | | **Other** | |
| [ ] | `say_small_button_male1.wav` | `say_small_button_female1.wav` | Small talk | I lost a button off my coat. I keep looking down for it. |
| [ ] | `say_small_cat_male1.wav` | `say_small_cat_female1.wav` | Small talk | Did you ever have a cat? I think I had a cat once. |
| [ ] | `say_small_crust_male1.wav` | `say_small_crust_female1.wav` | Small talk | If you ever find bread with a crust that crunches, tell me. |
| [ ] | `say_small_neighbor_male1.wav` | `say_small_neighbor_female1.wav` | Small talk | My neighbor hums through the wall. Same three notes, every night. |
| [ ] | `say_small_pigeon_male1.wav` | `say_small_pigeon_female1.wav` | Small talk | There's a pigeon on my windowsill. I'm pretty sure it hates me. |
| [ ] | `say_small_rain_male1.wav` | `say_small_rain_female1.wav` | Small talk | Looks like rain again. It always looks like rain. |
| [ ] | `say_small_shoes_male1.wav` | `say_small_shoes_female1.wav` | Small talk | My shoes squeak now. Both of them. Since Tuesday. |
| [ ] | `say_small_soup_male1.wav` | `say_small_soup_female1.wav` | Small talk | I had the strangest dream about soup last night. |
| [ ] | `say_small_stairs_male1.wav` | `say_small_stairs_female1.wav` | Small talk | Lift's broken again. Eight floors. My knees hate me. |
| [ ] | `say_small_tiles_male1.wav` | `say_small_tiles_female1.wav` | Small talk | I counted the tiles in my hallway. Two hundred and twelve. |
| [ ] | `say_small_tune_male1.wav` | `say_small_tune_female1.wav` | Small talk | I can't get that tune from the speakers out of my head. |
| [ ] | `say_small_water_male1.wav` | `say_small_water_female1.wav` | Small talk | The water tastes different this week. Not worse. Just different. |

## 11. What units say

The named Civil Protection units' answers in free talk, and what they say when their minds give way. One voice for every unit, clipped and cold, through the mask (a radio or vocoder effect over it helps). Folder: **`garrysmod/sound/livingcity/units/`**. **Where Half-Life 2 already has the line** (marked in the table) its own clip is played and nothing needs recording. Without a recording or a clip a unit is silent and the words show.

| Done | File | When | Says |
|---|---|---|---|
| n/a | `unit_brutal1.wav` (optional) | Brutality: to whoever is watching | Prepare for judgment. (Half-Life 2 has it: `npc/metropolice/vo/prepareforjudgement.wav`, used by itself) |
| n/a | `unit_busy1.wav` (optional) | Ending it | Now get out of here. (Half-Life 2 has it: `npc/metropolice/vo/nowgetoutofhere.wav`, used by itself) |
| n/a | `unit_curfew1.wav` (optional) | Curfew, a lockdown or a sweep | Vacate, citizen. (Half-Life 2 has it: `npc/metropolice/vo/vacatecitizen.wav`, used by itself) |
| n/a | `unit_drink1.wav` (optional) | Caught drinking on duty | Watch it. (Half-Life 2 has it: `npc/metropolice/vo/watchit.wav`, used by itself) |
| n/a | `unit_dunno1.wav` (optional) | Asked anything he won't answer | Keep moving. (Half-Life 2 has it: `npc/metropolice/vo/keepmoving.wav`, used by itself) |
| n/a | `unit_greet1.wav` (optional) | Spoken to | Citizen. (Half-Life 2 has it: `npc/metropolice/vo/citizen.wav`, used by itself) |
| n/a | `unit_greet_cp1.wav` (optional) | Spoken to by another unit | Copy. (Half-Life 2 has it: `npc/metropolice/vo/copy.wav`, used by itself) |
| n/a | `unit_insulted1.wav` (optional) | Insulted | Looking for trouble? (Half-Life 2 has it: `npc/metropolice/vo/lookingfortrouble.wav`, used by itself) |
| n/a | `unit_move1.wav` (optional) | Wants them gone | Move along. (Half-Life 2 has it: `npc/metropolice/vo/movealong.wav`, used by itself) |
| n/a | `unit_move_hard1.wav` (optional) | Wants them gone, losing patience | Move it. (Half-Life 2 has it: `npc/metropolice/vo/moveit.wav`, used by itself) |
| n/a | `unit_no1.wav` (optional) | Refusing | Get out of here. (Half-Life 2 has it: `npc/metropolice/vo/getoutofhere.wav`, used by itself) |
| n/a | `unit_noted1.wav` (optional) | Heard something he will report | Issuing malcompliant citation. (Half-Life 2 has it: `npc/metropolice/vo/issuingmalcompliantcitation.wav`, used by itself) |
| n/a | `unit_papers1.wav` (optional) | Suspicious of them | Don't move. (Half-Life 2 has it: `npc/metropolice/vo/dontmove.wav`, used by itself) |
| n/a | `unit_soft1.wav` (optional) | A unit with some kindness in him, to someone he doesn't mind | All right, you can go. (Half-Life 2 has it: `npc/metropolice/vo/allrightyoucango.wav`, used by itself) |
| n/a | `unit_thanks1.wav` (optional) | Told something useful, or obeyed | Roger that. (Half-Life 2 has it: `npc/metropolice/vo/rodgerthat.wav`, used by itself) |
| n/a | `unit_threat1.wav` (optional) | Threatened or crowded | Move back, right now. (Half-Life 2 has it: `npc/metropolice/vo/movebackrightnow.wav`, used by itself) |
| n/a | `unit_verdict1.wav` (optional) | Insulted again, or defied | You want a malcompliance verdict? (Half-Life 2 has it: `npc/metropolice/vo/youwantamalcomplianceverdict.wav`, used by itself) |
| n/a | `unit_warn1.wav` (optional) | Pushed too far | Final warning. (Half-Life 2 has it: `npc/metropolice/vo/finalwarning.wav`, used by itself) |
| n/a | `unit_warn_first1.wav` (optional) | A first warning | First warning: move away. (Half-Life 2 has it: `npc/metropolice/vo/firstwarningmove.wav`, used by itself) |
| n/a | `unit_warn_second1.wav` (optional) | A second warning | This is your second warning. (Half-Life 2 has it: `npc/metropolice/vo/thisisyoursecondwarning.wav`, used by itself) |
| n/a | `unit_yes1.wav` (optional) | Agreeing | Affirmative. (Half-Life 2 has it: `npc/metropolice/vo/affirmative.wav`, used by itself) |

## 12. Colonel Cubbage answers her speeches

Odessa Cubbage, alive and well, at the Resistance's camp a few minutes after her address: defiant, dry, a speaker who enjoys taking her apart. An opening, an answer to each thing she spoke about (named as her piece in section 1), and a closing. Folder: **`garrysmod/sound/livingcity/cubbage/`**. Heard near him, and a recording cuts in on Freq 7. Without a recording, the words show in chat.

| Done | File | Answers | Says |
|---|---|---|---|
| [ ] | `answer_open1.wav` | (his opening) | You heard her. Now hear me. Colonel Cubbage, and I have a few corrections to make. |
| [ ] | `answer_ev_deaths1.wav` | her `speech_ev_deaths` | She talks about blood in the streets. Ask whose hands it's on. Her units don't carry those batons for show. |
| [ ] | `answer_ev_arrests1.wav` | her `speech_ev_arrests` | Not one of them taken at random, she says. Then tell me what crime a man commits by standing in the wrong square. |
| [ ] | `answer_ev_informers1.wav` | her `speech_ev_informers` | She thanks the ones who whispered to her. We know who you are too. It isn't too late to stop. |
| [ ] | `answer_ev_informer_hurt1.wav` | her `speech_ev_informer_hurt` | She calls us cowards. We don't drag families out of bed at night. We deal with the ones who sell their neighbours. |
| [ ] | `answer_ev_taken1.wav` | her `speech_ev_taken` | Yes, we take some of hers, and we ask them questions. She takes all of you, every day, and doesn't bother asking. |
| [ ] | `answer_ev_escape1.wav` | her `speech_ev_escape` | Some of ours walked out of her cells. Good. If one of them knocks at your door, open it. |
| [ ] | `answer_ev_posters1.wav` | her `speech_ev_posters` | She frets about her posters. Paper. She worries about paper while you go hungry. |
| [ ] | `answer_ev_theft1.wav` | her `speech_ev_theft` | Stealing, she says. The only thief in this city sits in an office and takes your bread to pay for her speeches. |
| [ ] | `answer_ev_defiance1.wav` | her `speech_ev_defiance` | People raised their voices at her officers. Good. Your voice is the first thing they take, and the last thing you should give up. |
| [ ] | `answer_ev_sabotage1.wav` | her `speech_ev_sabotage` | Broken machines hurt only you, she says. They're her machines, and they keep you in line. Let them break. |
| [ ] | `answer_ev_heavyhand1.wav` | her `speech_ev_heavyhand` | Firmness, she calls it. You saw what it was. Remember it. |
| [ ] | `answer_ev_drink1.wav` | her `speech_ev_drink` | She doesn't blame you for drinking. Of course she doesn't. A drunk doesn't fight back. |
| [ ] | `answer_ev_kindness1.wav` | her `speech_ev_kindness` | She takes the credit for you sharing your bread. That was you. It's the one thing she can't stamp out, and it frightens her. |
| [ ] | `answer_ev_despair1.wav` | her `speech_ev_despair` | Hope is a choice, she says. Then choose it. Just don't let her tell you what to hope for. |
| [ ] | `answer_unrest1.wav` | her `speech_unrest` | Whispers of freedom mean chaos, she says. We mean freedom. She knows the difference, and it terrifies her. |
| [ ] | `answer_hunger1.wav` | her `speech_hunger` | She feels every empty bowl, does she? Then why is hers never empty? |
| [ ] | `answer_order1.wav` | her `speech_order` | Her authority is not in question, she says. When someone has to say that out loud, it already is. |
| [ ] | `answer_morale1.wav` | her `speech_morale` | Tired faces, she says. You're tired because she works you to the bone. Rest isn't her gift. It's yours. |
| [ ] | `answer_calm1.wav` | her `speech_calm` | Quiet days, she calls them. Quiet is what she calls it when nobody dares to speak. |
| [ ] | `answer_mood_afraid1.wav` | her `speech_mood_afraid` | You've nothing to fear from her, she says. Tell that to the ones she's taken. |
| [ ] | `answer_mood_restless1.wav` | her `speech_mood_restless` | She feels your restlessness, she says. Good. Let her feel it. |
| [ ] | `answer_mood_content1.wav` | her `speech_mood_content` | Rested, fed and calm, she says. Look around you. Does that look like anyone you know? |
| [x] | `answer_slogan1.wav` | her `speech_slogan` | Love your neighbour, hate the traitor, she says. We agree. Ask yourself who sold this city. |
| [ ] | `answer_close1.wav` | (his closing) | That's all from me. Keep your heads down, your eyes open, and your door unlocked for a friend. We're closer than she thinks. |
