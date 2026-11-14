# Voice scripts: what to paste into ElevenLabs

**Made from the code by `python3 _dev/voice_lines.py`: never edit it by hand.** The lines of `VOICE_LINES.md` that are generated speech (named citizens, units, the Administrator, and the G-Man's made-up lines), written the way ElevenLabs wants them, with a voice description for each voice.


## Still to record (the server's `lc_voice_missing`)

Ticked [x] below: the server already has it. Left to record, 357 files:

- **the dreams' lines** (`dreams/voice/`): 150 missing
- **Overwatch** (`overwatch/`): 9 missing
- **the Administrator** (`administrator/`): 31 missing
- **the radio** (`radio/`): 11 missing
- **the G-Man** (`gman/`): 10 missing
- **citizens (named citizens and showing the way)** (`citizens/`): 67 missing
- **units** (`units/`): nothing missing
- **the clerk** (`clerk/`): 16 missing
- **the old-timer** (`oldtimer/`): 29 missing
- **machines** (`machines/`): 10 missing
- **Colonel Cubbage** (`cubbage/`): 24 missing
- **the Resistance's people** (`resistance/`): nothing missing

Run `lc_voice_missing` on the server after uploading, and give Claude the list (or `data/livingcity/voice_missing.txt`) to update the ticks. The Colonel's own lines (the ghost) aren't checked by it.

## How to use it

- **Model:** Eleven v4 (or v3). A direction in **square brackets** changes how what follows is said: `[whispers] Careful.` It is not read out. Put it just before the words it changes. Your own wording works (`[tired, flat]`), as do reactions (`[sighs]`, `[exhales]`, `[short laugh]`) and `[pause]`. If a tag is read aloud, the model is not v4 or v3, or the brackets are not square.
- **Copy the "Paste" cell as it is.** Generate two or three takes and keep the best; a second good take can be saved as `...2` (one is picked at random in game).
- **Save each file under the name in the table**, `.mp3` or `.wav`, into the folder named above the table (on the server, under `garrysmod/sound/livingcity/`).
- **Tags are a starting point.** If a line comes out overacted, delete the tag or soften it (`[quietly]`): these are tired people, not actors. The breaks are the only loud ones.
- **The same voice for every line of a kind:** design the voice once (below), save it to your voices, and use that saved voice for the whole table.
- **Staying legal:** the descriptions below describe a kind of voice in ordinary words. Do not name a game, a character or an actor in a voice prompt, and do not upload audio from the games to clone a voice: that needs the performer's consent, and ElevenLabs' terms forbid it.

## All of them at once (instead of pasting each line)

`_dev/tools/elevenlabs_batch.py` sends every line to ElevenLabs and saves each file under its right name, in the right folder, ready to upload. On Linux Mint, in a terminal in the gamemode's folder:

**Just the citizens, the simple way:** keep `record_citizens.sh`, `elevenlabs_batch.py` and `voice_batch.tsv` together in one folder (any folder) and run `bash record_citizens.sh` there: it makes 3 test lines only. `bash record_citizens.sh all` then makes the rest. It asks for your key (hidden, never saved) and makes them louder (needs `ffmpeg`). The two voice ids are at the top of the script. Upload what lands in `voice_out/sound/livingcity/citizens/` (made beside the script) to the server's `garrysmod/sound/livingcity/citizens/`.

```
export ELEVENLABS_API_KEY='your key here'
python3 _dev/tools/elevenlabs_batch.py --man VOICE_ID --woman VOICE_ID --dry-run
python3 _dev/tools/elevenlabs_batch.py --man VOICE_ID --woman VOICE_ID --limit 3
python3 _dev/tools/elevenlabs_batch.py --man VOICE_ID --woman VOICE_ID --unit VOICE_ID --administrator VOICE_ID --gman VOICE_ID
```

- **A voice id** is shown beside each voice in ElevenLabs' voice list (design and save the voices first, below). Only the voices you give are made: leave one out to skip its lines.
- **`--dry-run`** makes nothing: it says how many lines and characters it would send, so you know the cost first. **`--limit 3`** makes just the first three, to listen before doing the rest.
- **It never makes a file twice:** a file already in the output folder is skipped, so you can stop and run it again, delete the takes you dislike and rerun, or add `--takes 2` for a second take of each (`...2`).
- **Where they go:** `voice_out/sound/livingcity/...`, laid out like the server's `garrysmod/sound/`, so the whole `sound` folder can be uploaded as it is. Unit lines go to `voice_out/units_clean/` instead: run `bash _dev/tools/unit_radio.sh voice_out/units_clean voice_out/sound/livingcity/units` for their radio sound.
- **Only what your server lacks:** run `lc_voice_missing` on the server, download `data/livingcity/voice_missing.txt`, and add `--missing voice_missing.txt`: lines the server already has a recording of are left out.
- **`--extras`** also makes the G-Man lines that are not in the game yet. **`--model eleven_v4_turbo`** is cheaper than the default `eleven_v4`.
- The G-Man's files must be `.wav`: with `ffmpeg` installed (`sudo apt install ffmpeg`) the script converts them itself.
- **Half-Life 2's own lines, in your voices** (they then play in place of Half-Life 2's clips; never the G-Man): run `lc_hl2_lines` in the server console, download `data/livingcity/hl2_lines.txt`, then `python3 _dev/tools/elevenlabs_batch.py --hl2 hl2_lines.txt --man ID --woman ID --unit ID --soldier ID --overwatch ID --dry-run`. More: `docs/features/recorded-lines.md`.
- **Not yet tried against the real service.** If the first run prints an error from ElevenLabs, paste it to Claude.

## Voice descriptions (ElevenLabs: Voices > Voice Design; paste one, listen, adjust)

Each is written to sit close to the people already heard in the city without copying anyone. Try the first; the others lean a different way.

### The citizen, a man (every named male citizen)

The Half-Life 2 man is not gruff or deep: he is a clear, fairly light, well-spoken voice in his thirties, lively and a little theatrical, an actor playing an ordinary guy. Start with the first; the others move one thing each (lighter and younger; a touch older and drier).

1. `An American man in his mid thirties with a clear, light baritone that leans toward tenor. Clean, neutral General American accent, crisp consonants, well-spoken. A friendly, earnest everyman with a slightly wry edge: lively and expressive, quick to sound worried or urgent, never gravelly, never deep, never sleepy. Sounds like a trained stage actor playing a regular guy. Close, dry studio recording, no reverb.`
2. `American man around thirty, bright clear tenor-baritone, smooth with no rasp. Neutral accent, precise and articulate, energetic and a little breathless, sincere, slightly nervous good humour. An approachable, ordinary, educated-sounding guy. Close, dry studio recording.`
3. `American man in his late thirties, clear medium-pitched voice, clean and resonant but not deep, neutral General American. Articulate, steady, dryly humorous, concerned and alert, speaks with energy and clear emphasis. No gravel, no drawl. Close, dry studio recording.`

**If it still misses,** change one word at a time and listen: too deep or old (add `higher, lighter, younger`), too flat (add `animated, expressive`), too smooth or like an announcer (add `natural, conversational, slightly breathy`), too gruff (add `smooth, clean, no rasp`). The tags on the lines ask for tired and quiet; if this voice then sounds unlike itself, delete the tag for that line.

**A voice that is right but too high** (ElevenLabs will not lower a voice without changing it): make the lines with it as it is, then `bash _dev/tools/voice_deeper.sh FOLDER_IN FOLDER_OUT` writes a deeper copy of every file at the same speed. `SEMITONES=-1` is subtle, `-1.5` the default, `-2` clearly deeper, `-3` about as far as it stays natural: `SEMITONES=-2 bash _dev/tools/voice_deeper.sh in out`. The originals are never overwritten.

### The citizen, a woman (every named female citizen)

The Half-Life 2 woman is likewise clear and medium-pitched, in her thirties, earnest and expressive, not husky or low.

1. `An American woman in her early thirties with a clear, medium-pitched voice, warm and smooth with no rasp. Clean, neutral General American accent, articulate. Earnest, capable and caring, expressive, quick to sound concerned or urgent, never husky, never low, never sleepy. Sounds like a trained stage actor playing an ordinary woman. Close, dry studio recording, no reverb.`
2. `American woman around thirty, bright clear mezzo voice, neutral accent, precise and lively, sincere, a little anxious, friendly. An approachable, ordinary, educated-sounding woman. Close, dry studio recording.`
3. `American woman in her late thirties, clear mid voice with gentle warmth, neutral General American, steady and articulate, wry, alert and concerned, speaks with clear emphasis. No rasp, no drawl. Close, dry studio recording.`

### The unit (one voice for every Civil Protection unit)

**The radio sound is not the voice: it is an effect put on afterwards.** No voice model will make it reliably. Record the lines CLEAN with a plain, deep, flat voice, then run them through the effect (next heading). A clean voice to start from:

1. `An American man in his forties, deep and flat. Low baritone, clipped and cold, every word the same weight, no emotion, like a man reading orders he has read a thousand times. Speaks close to the microphone, firmly, a little too loud. Dry studio recording, no reverb.`
2. `Deep-voiced American man, thirties, hard and bored. Gravelly bass-baritone, short flat sentences bitten off at the end, faintly contemptuous. Close, dry recording.`
3. `American man, fifties, heavy chest voice. Slow, toneless, official, slightly muffled as if speaking behind a mask, no rise or fall. Close, dry recording.`

If you would rather ElevenLabs tried the effect itself, add this to the end of any of them (results vary a lot from take to take): `Heard through a small helmet radio: narrow, tinny, compressed and slightly distorted, with a faint electronic buzz.`

### Giving the unit's lines their radio sound

On Linux Mint, once, in a terminal: `sudo apt install ffmpeg`. Then put the clean unit recordings in one folder and run the script that comes with the gamemode:

```
bash _dev/tools/unit_radio.sh ~/unit_clean ~/unit_radio
```

It writes a `.wav` of each into the second folder: a little deeper, the lows and highs cut like a small speaker, squashed flat and loud, a little digital grit and a fast buzz for the gargle, and a click of static before and after. Listen to one. To change it, put settings in front: `DEPTH=0.90 BUZZ=0.5 CRUSH=0.4 bash _dev/tools/unit_radio.sh ...` (DEPTH 0.90 deeper to 1.00 as recorded; BUZZ 0 none to 0.6 heavy; CRUSH 0 clean to 0.6 gritty). Upload the results to `garrysmod/sound/livingcity/units/`.

By hand in Audacity instead, in this order: Effect > Pitch and Tempo > Change Pitch (about -6%); Effect > EQ and Filters > High-Pass Filter (300 Hz) and Low-Pass Filter (3000 Hz); Effect > Volume and Compression > Compressor (ratio 8:1, threshold -24 dB); Effect > Distortion and Modulation > Distortion (Hard Clipping, a little); Effect > Distortion and Modulation > Tremolo (about 85 Hz, depth 35%).

### The G-Man (only for his lines that are not real clips)

Most of his lines in game are his real clips and need nothing. These are for the few made-up ones, so they sit beside the real ones without imitating the performer. Expect to generate several takes: what sells him is where the stress falls, and the tags only nudge that.

1. `A middle-aged American man with a soft, breathy, slightly hoarse voice and a strange, halting way of speaking: pauses in the wrong places, stress on the wrong syllables, sibilants drawn out a little, pitch rising and falling where it should not. Polite, bureaucratic, quietly menacing, as if human speech were learned from a manual. Very slow and deliberate. Close, dry recording.`
2. `Older man, sixties, thin dry voice barely above a whisper, formal and courteous, oddly musical, each phrase beginning slowly and ending in a small upward lilt. Unsettlingly calm, patient, amused. Close, dry recording.`
3. `Man in his fifties, smooth low voice with a faint rasp, a government official's careful diction, long unnatural gaps between words, cold and detached, never raising his voice. Close, dry recording.`

## The Administrator's announcements

Folder: `administrator/`. **Use the voice her existing recordings were made with.** Each line is given in her usual tone; the tone is the word in the file name (none: warm). A harsher take of any line is worth having, since she steps up a tone when the city is on red or after violence: paste the same words after `[stern, cold, slowly]` and save as `<trigger>_stern1`, or after `[furious, barely controlled, clipped]` as `<trigger>_furious1`.

| Done | File | When | Paste |
|---|---|---|---|
| [ ] | `socio_black_furious1.wav` | The city collapses to BLACK (also every 5 minutes while it lasts): open rebellion, the curfew and the shelling, in one | [furious, barely controlled, clipped] Citizens. The city has been overrun by its own ingratitude. Go indoors and stay there. Anyone in the open will be fired upon from the Nexus. This is not a request. |
| [ ] | `jog1.wav` | The morning jog | [warm, motherly, smiling] Morning, everyone! Shoes on: time for our little jog. |
| [x] | `drill1.wav` | The morning drill | [warm, motherly, smiling] Into the yard, everyone, for our morning exercises. Stretch! |
| [x] | `parade1.wav` | The morning parade | [warm, motherly, smiling] Parade time! Chins up, shoulders back, and let's show the city who we are. |
| [ ] | `black_stand_furious1.wav` | Her last stand begins | [furious, barely controlled, clipped] So you have come for me. Come, then. You will not reach me. |
| [ ] | `black_crushed_stern1.wav` | The uprising is crushed (time ran out) | [stern, cold, slowly] It is over. The city is mine again, and I will remember every one of you. |
| [ ] | `suppressor_down_furious1.wav` | The suppression device is destroyed | [furious, barely controlled, clipped] They have silenced the Nexus. It changes nothing. |
| [ ] | `speech_soon1.wav` | Her address is called: the city must gather (Overwatch's when a player Administrator calls it from her tablet; hers when the city gives it) | [warm, motherly, smiling] My dear citizens, I am going to speak to you all in a few minutes. Come and gather in front of the stand. I would so hate to miss anyone. |
| [ ] | `speech_open1.wav` | Her speech, the opening | [warm, motherly, smiling] Citizens. Thank you for coming to hear me. Let us talk about the days behind us. |
| [ ] | `speech_ev_deaths_firm1.wav` | Her speech, on what happened lately: when people were killed lately | [firm, composed, still kind] Blood has been spilled in our streets. Every life lost to violence is stolen from all of us. Violence solves nothing. It only invites more. |
| [ ] | `speech_ev_arrests_firm1.wav` | Her speech, on what happened lately: when people were taken to the cells | [firm, composed, still kind] Civil Protection has been busy. No one taken to the cells was taken at random. They chose disorder, and disorder has a price. |
| [ ] | `speech_ev_informers1.wav` | Her speech, on what happened lately: when citizens informed (she knows who) | [warm, motherly, smiling] To those of you who came forward and told us what you saw: thank you. You know who you are, and so do I. Your loyalty will not be forgotten. |
| [ ] | `speech_ev_informer_hurt_stern1.wav` | Her speech, on what happened lately: when the Resistance hurt an informer | [stern, cold, slowly] Some of you were hurt for helping the city, beaten in the dark by cowards who call themselves liberators. Look at what they do to their own neighbours, and ask who your friends really are. |
| [ ] | `speech_ev_taken_stern1.wav` | Her speech, on what happened lately: when the Resistance took someone (the cage, the chair, an execution) | [stern, cold, slowly] Citizens have been taken, dragged off by the so-called Resistance and questioned like animals. That is the freedom they offer you: a cage, and a chair. |
| [ ] | `speech_ev_escape_stern1.wav` | Her speech, on what happened lately: when someone escaped | [stern, cold, slowly] Some who were held have run from where they belong. They will be found. And whoever hides them will stand beside them when they are. |
| [ ] | `speech_ev_posters_firm1.wav` | Her speech, on what happened lately: when the city's posters were defaced | [firm, composed, still kind] Someone has been defacing the city's notices. A poster costs the Union very little. Replacing it will cost you your rations. |
| [ ] | `speech_ev_theft_firm1.wav` | Her speech, on what happened lately: when there was stealing | [firm, composed, still kind] There has been stealing, from the city and from each other. A thief steals from everyone standing in this square. |
| [ ] | `speech_ev_defiance_firm1.wav` | Her speech, on what happened lately: when people shouted at units or accused each other (a mind breaking) | [firm, composed, still kind] Voices have been raised at the officers who keep you safe. I understand frustration. I will not tolerate it in the street. |
| [ ] | `speech_ev_sabotage_stern1.wav` | Her speech, on what happened lately: when someone sabotaged the city's work (a mind breaking) | [stern, cold, slowly] Machines have been broken and the city's work undone. Sabotage hurts no one but you. It is your water, your light, your bread. |
| [ ] | `speech_ev_heavyhand_firm1.wav` | Her speech, on what happened lately: when a unit was brutal (a mind breaking) | [firm, composed, still kind] Some of you have seen our officers act firmly. Firmness is a kindness, in the end. It ends trouble before trouble ends you. |
| [ ] | `speech_ev_drink1.wav` | Her speech, on what happened lately: when people took to drink (a mind breaking) | [warm, motherly, smiling] I hear some of you have found comfort in a bottle. I do not blame you. But a clear head is a loyal head. |
| [ ] | `speech_ev_kindness1.wav` | Her speech, on what happened lately: when people shared food or steadied each other (a mind breaking) | [warm, motherly, smiling] And I have seen good things too: neighbours sharing their bread, calming each other's nerves. That is the city I am proud of. |
| [ ] | `speech_ev_despair1.wav` | Her speech, on what happened lately: when people gave up hope (a mind breaking) | [warm, motherly, smiling] Some of you have lost hope. Do not. Hope is not something you are given. It is something you choose, every morning. |
| [ ] | `speech_unrest_stern1.wav` | Her speech, on the state of the city: when the Resistance is strong | [stern, cold, slowly] There are those among you who whisper of freedom and mean only chaos. Every one of them you shelter is a debt your whole block will pay. |
| [ ] | `speech_hunger1.wav` | Her speech, on the state of the city: when supply is low | [warm, motherly, smiling] I know the rations have been thin. I feel every empty bowl as if it were my own. Work your shifts, keep your quotas, and the trains will come. |
| [ ] | `speech_order_firm1.wav` | Her speech, on the state of the city: when her authority is low | [firm, composed, still kind] Let me be clear, so no one can say they were not told. The rules of this city are not suggestions, and my authority is not in question. |
| [ ] | `speech_morale1.wav` | Her speech, on the state of the city: when morale is low | [warm, motherly, smiling] I see tired faces, and I understand. But the lights are on, the streets are swept, and not one of you is alone. |
| [ ] | `speech_calm1.wav` | Her speech, on the state of the city: when nothing much happened (a quiet few days) | [warm, motherly, smiling] These have been quiet days, days of order and honest work. The Union sees it. I see it. |
| [ ] | `speech_mood_afraid1.wav` | Her speech, on the city's mood: when the city's people are frightened (the minds: stress high) | [warm, motherly, smiling] I can see fear in your faces. You have nothing to fear from me. Only from those who would set you against me. |
| [ ] | `speech_mood_restless_firm1.wav` | Her speech, on the city's mood: when the city's people are restless (the minds: unrest high) | [firm, composed, still kind] There is a restlessness in this city. I feel it. Restlessness can be turned into work, or into ruin. Choose work. |
| [ ] | `speech_mood_content1.wav` | Her speech, on the city's mood: when the city's people are at ease (the minds: stress low) | [warm, motherly, smiling] You look well: rested, fed and calm. Good. Keep it so. |
| [ ] | `speech_close1.wav` | Her speech, the closing | [warm, motherly, smiling] Now go back to your work, and remember: this city is only as strong as each one of you. Glory to the Union. |

## What named citizens say

Folder: `citizens/`. Paste each line twice: once with the man's voice (save as the man's file), once with the woman's.

| Done | Man's file | Woman's file | Paste |
|---|---|---|---|
| | | | **Openers (a word or two before another line)** |
| [x] | `say_open_listen_male1` | `say_open_listen_female1` | [low, urgent] Listen. |
| [x] | `say_open_look_male1` | `say_open_look_female1` | [tired, flat] Look. |
| [x] | `say_open_please_male1` | `say_open_please_female1` | [pleading, quietly] Please. |
| [x] | `say_open_quiet_male1` | `say_open_quiet_female1` | [whispers, tense] Keep your voice down. |
| [x] | `say_open_well_male1` | `say_open_well_female1` | [thinking it over] Well... |
| [x] | `say_open_you_male1` | `say_open_you_female1` | [sharp, low] You. |
| | | | **Hello** |
| [x] | `say_greet_cold_male1` | `say_greet_cold_female1` | [cold, flat] What do you want? |
| [x] | `say_greet_guarded_male1` | `say_greet_guarded_female1` | [wary, guarded] Do I know you? |
| [x] | `say_greet_plain_male1` | `say_greet_plain_female1` | [tired, dry] Hey. Still here, huh? [exhales] Me too. |
| [x] | `say_greet_unit_male1` | `say_greet_unit_female1` | [nervous, too polite] No trouble here, officer. |
| [x] | `say_greet_warm_male1` | `say_greet_warm_female1` | [relieved, warm] Oh, it's you. Good to see a friendly face. |
| | | | **Goodbye** |
| [x] | `say_bye_cold_male1` | `say_bye_cold_female1` | [cold, final] We're done here. |
| [x] | `say_bye_plain_male1` | `say_bye_plain_female1` | [flat, tired] I should get going. |
| [x] | `say_bye_warm_male1` | `say_bye_warm_female1` | [warm, quietly] Take care of yourself. [sincere] I mean it. |
| | | | **Yes, no, perhaps** |
| [x] | `say_later_male1` | `say_later_female1` | [hushed, tense] Not now. Not here. |
| [x] | `say_maybe_male1` | `say_maybe_female1` | [hesitant] Maybe. I'd have to think about it. |
| [x] | `say_no_male1` | `say_no_female1` | [flat, apologetic] Sorry, but no. |
| [x] | `say_no_hard_male1` | `say_no_hard_female1` | [firm, low] No. [pause] And don't ask me again. |
| [x] | `say_yes_male1` | `say_yes_female1` | [plain, tired] Yeah. All right. |
| [x] | `say_yes_warm_male1` | `say_yes_warm_female1` | [warm, a small smile] For you? Of course. |
| | | | **What they know** |
| [x] | `say_ask_else_male1` | `say_ask_else_female1` | [tired, dismissive] You're asking the wrong person. |
| [x] | `say_cant_say_male1` | `say_cant_say_female1` | [hushed, uneasy] I can't talk about that. You know why. |
| [x] | `say_dunno_male1` | `say_dunno_female1` | [guarded, flat] I wouldn't know anything about that. |
| [x] | `say_dunno_scared_male1` | `say_dunno_scared_female1` | [frightened, quick] I don't know, and I don't want to know. |
| [x] | `say_heard_male1` | `say_heard_female1` | [low, careful] I've heard things. [pause] Everyone has. |
| [x] | `say_truth_male1` | `say_truth_female1` | [quiet, grim] Honestly? [sighs] It's as bad as it looks. |
| | | | **How they are** |
| [x] | `say_state_angry_male1` | `say_state_angry_female1` | [tight, barely holding it in] I've had about all I can take. |
| [x] | `say_state_fine_male1` | `say_state_fine_female1` | [worn, matter of fact] Getting by. That's all I can do. |
| [x] | `say_state_hopeful_male1` | `say_state_hopeful_female1` | [quiet, hopeful] It can't last forever. Nothing ever does. |
| [x] | `say_state_hungry_male1` | `say_state_hungry_female1` | [weak, hollow] I haven't had a real meal in days. |
| [x] | `say_state_lonely_male1` | `say_state_lonely_female1` | [soft, grateful] It's good to just talk to someone. |
| [x] | `say_state_low_male1` | `say_state_low_female1` | [hollow, defeated] What's the point? [pause] Really, what is the point? |
| [x] | `say_state_scared_male1` | `say_state_scared_female1` | [frightened, hushed] I'm scared. Aren't you? |
| [x] | `say_state_tired_male1` | `say_state_tired_female1` | [exhausted] I'm tired. [sighs] Just so tired. |
| | | | **Answering how they were spoken to** |
| [x] | `say_agree_male1` | `say_agree_female1` | [dry, low] You're not wrong. |
| [x] | `say_disagree_male1` | `say_disagree_female1` | [even, firm] Well, I don't see it that way. |
| [x] | `say_insulted_male1` | `say_insulted_female1` | [stung, stiff] Hey. There's no need for that. |
| [x] | `say_laugh_male1` | `say_laugh_female1` | [short laugh] Ha. [warm, surprised] That's the first laugh I've had all week. |
| [x] | `say_sorry_male1` | `say_sorry_female1` | [nervous, backing down] I'm sorry. I didn't mean anything by it. |
| [x] | `say_thanks_male1` | `say_thanks_female1` | [sincere, quietly] Thank you. I won't forget it. |
| [x] | `say_thanks_big_male1` | `say_thanks_big_female1` | [moved, voice catching] You didn't have to do that. Thank you. |
| [x] | `say_threatened_male1` | `say_threatened_female1` | [frightened, hands up] I don't want any trouble. |
| | | | **The Combine** |
| [x] | `say_careful_male1` | `say_careful_female1` | [whispers] Careful. The walls have ears. |
| [x] | `say_fear_units_male1` | `say_fear_units_female1` | [low, warning] Stay away from the units today. They're in a mood. |
| [x] | `say_hate_quiet_male1` | `say_hate_quiet_female1` | [low, bitter, controlled] One day they'll answer for all of it. |
| [x] | `say_loyal_male1` | `say_loyal_female1` | [earnest, a little rehearsed] The Administrator knows best. Everyone knows that! |
| [x] | `say_loyal_warn_male1` | `say_loyal_warn_female1` | [alarmed, hushed] You shouldn't say things like that. Someone will hear. |
| [x] | `say_obey_male1` | `say_obey_female1` | [tired, kindly] Keep your head down and do what they say. That's how you make it. |
| [x] | `say_units_near_male1` | `say_units_near_female1` | [under their breath] Not with them standing right there. |
| | | | **The Resistance** |
| [x] | `say_res_deny_male1` | `say_res_deny_female1` | [quick, stiff, too careful] I don't know anything about any Resistance. |
| [x] | `say_res_hint_male1` | `say_res_hint_female1` | [whispers, meaningful] There are people. [pause] That's all I'll say. |
| [x] | `say_res_refuse_male1` | `say_res_refuse_female1` | [afraid, firm] I've got people to think about. Leave me out of it. |
| [x] | `say_res_respect_male1` | `say_res_respect_female1` | [quiet, a hint of a smile] Whoever they are, good luck to them. |
| [x] | `say_res_side_male1` | `say_res_side_female1` | [very quietly, steady] If someone needed a door left open, mine would be. |
| | | | **Warnings and tips** |
| [x] | `say_tip_help_male1` | `say_tip_help_female1` | [low, kind] If you need something, ask. [whispers] Quietly. |
| [x] | `say_tip_trouble_male1` | `say_tip_trouble_female1` | [uneasy, low] There's gonna be trouble tonight. I can feel it. |
| [x] | `say_warn_asked_male1` | `say_warn_asked_female1` | [low, urgent] Someone's been asking about you. |
| [x] | `say_warn_go_male1` | `say_warn_go_female1` | [urgent, hushed] You should go. Now. |
| [x] | `say_warn_informer_male1` | `say_warn_informer_female1` | [low, careful] Watch who you talk to. Not everyone here is a friend. |
| [x] | `say_warn_watched_male1` | `say_warn_watched_female1` | [whispers, barely moving lips] You're being watched. Don't look now and don't turn around. |
| | | | **Asking and giving** |
| [x] | `say_ask_food_male1` | `say_ask_food_female1` | [weak, ashamed to ask] You got anything to eat? [pause] Anything? |
| [x] | `say_ask_help_male1` | `say_ask_help_female1` | [desperate, quietly] I need help. I've got nobody else to ask. |
| [x] | `say_ask_smoke_male1` | `say_ask_smoke_female1` | [edgy, hopeful] You wouldn't have a smoke on you, would you? |
| [x] | `say_decline_gift_male1` | `say_decline_gift_female1` | [gentle, proud] I can't take that. Keep it. |
| [x] | `say_offer_male1` | `say_offer_female1` | [hushed, quick] Here. Take it. Don't say where you got it. |
| | | | **As a mind gives way** |
| [x] | `say_break_accuse_male1` | `say_break_accuse_female1` | [loud, accusing, pointing] That one! That one talks to Civil Protection! |
| [x] | `say_break_accused_male1` | `say_break_accused_female1` | [panicked, loud] That's a lie! I never told them anything! |
| [x] | `say_break_beaten_male1` | `say_break_beaten_female1` | [crying out in pain, terrified] Stop! Please, I didn't do anything! |
| [x] | `say_break_binge_male1` | `say_break_binge_female1` | [slurred, tired, bitter] Leave me alone. Just let me have this. |
| [x] | `say_break_defy_male1` | `say_break_defy_female1` | [quiet, defiant, steady] They can't scare all of us forever. |
| [x] | `say_break_despair_male1` | `say_break_despair_female1` | [broken, near tears] I can't. [shaky breath] I just can't anymore. |
| [x] | `say_break_inform_male1` | `say_break_inform_female1` | [nervous, eager, hushed] Officer. I've got something you'll want to hear. |
| [x] | `say_break_seek_male1` | `say_break_seek_female1` | [relieved, a little shaky] There you are. I've been looking for you. |
| [ ] | `say_break_share_male1` | `say_break_share_female1` | [gentle, insisting] Go on, take half. You need it more than I do. |
| [x] | `say_break_steady_male1` | `say_break_steady_female1` | [calm, soothing, low] Easy. Easy now. We're going to be ok, right? |
| [x] | `say_break_tantrum_male1` | `say_break_tantrum_female1` | [shouting, voice cracking] I've had enough! Do you hear me? Enough! |
| | | | **What they saw** |
| [x] | `say_grief_male1` | `say_grief_female1` | [numb, grieving] They took my friend. [pause] Just dragged them off. |
| [x] | `say_saw_beating_male1` | `say_saw_beating_female1` | [under their breath, tense] Don't look. Just keep walking. |
| [x] | `say_saw_death_male1` | `say_saw_death_female1` | [horrified, gasping] Oh God. Oh God, no. |
| | | | **Other** |
| [ ] | `say_small_button_male1` | `say_small_button_female1` | [casual, absent-minded] I lost a button off my coat. I keep looking down for it. |
| [ ] | `say_small_cat_male1` | `say_small_cat_female1` | [casual, dreamy] Did you ever have a cat? [pause] I think I had a cat once. |
| [ ] | `say_small_crust_male1` | `say_small_crust_female1` | [casual, wistful] If you ever find bread with a crust that crunches, tell me. |
| [ ] | `say_small_neighbor_male1` | `say_small_neighbor_female1` | [casual, tired] My neighbor hums through the wall. Same three notes, every night. |
| [ ] | `say_small_pigeon_male1` | `say_small_pigeon_female1` | [casual, wry] There's a pigeon on my windowsill. I'm pretty sure it hates me. |
| [ ] | `say_small_rain_male1` | `say_small_rain_female1` | [casual, resigned] Looks like rain again. [pause] It always looks like rain. |
| [ ] | `say_small_shoes_male1` | `say_small_shoes_female1` | [casual, mildly annoyed] My shoes squeak now. Both of them. [pause] Since Tuesday. |
| [ ] | `say_small_soup_male1` | `say_small_soup_female1` | [casual, puzzled] I had the strangest dream about soup last night. |
| [ ] | `say_small_stairs_male1` | `say_small_stairs_female1` | [casual, grumbling] Lift's broken again. Eight floors. My knees hate me. |
| [ ] | `say_small_tiles_male1` | `say_small_tiles_female1` | [casual, oddly proud] I counted the tiles in my hallway. Two hundred and twelve. |
| [ ] | `say_small_tune_male1` | `say_small_tune_female1` | [casual, half laughing] I can't get that tune from the speakers out of my head. |
| [ ] | `say_small_water_male1` | `say_small_water_female1` | [casual, thoughtful] The water tastes different this week. [pause] Not worse. Just different. |

## What units say

Folder: `units/`. Record clean, then give them the radio sound (above). Half-Life 2's own units are heard beside these, so the closer the effect gets to theirs the better: compare one of yours with `npc/metropolice/vo/movealong.wav`.

| Done | File | Paste |
|---|---|---|

**Nothing to record for these:** Half-Life 2's own Civil Protection voice says them, and the game uses its clip (`npc/metropolice/vo/`): "Prepare for judgment." (`prepareforjudgement`); "Now get out of here." (`nowgetoutofhere`); "Vacate, citizen." (`vacatecitizen`); "Watch it." (`watchit`); "Keep moving." (`keepmoving`); "Citizen." (`citizen`); "Copy." (`copy`); "Looking for trouble?" (`lookingfortrouble`); "Move along." (`movealong`); "Move it." (`moveit`); "Get out of here." (`getoutofhere`); "Issuing malcompliant citation." (`issuingmalcompliantcitation`); "Don't move." (`dontmove`); "All right, you can go." (`allrightyoucango`); "Roger that." (`rodgerthat`); "Move back, right now." (`movebackrightnow`); "You want a malcompliance verdict?" (`youwantamalcomplianceverdict`); "Final warning." (`finalwarning`); "First warning: move away." (`firstwarningmove`); "This is your second warning." (`thisisyoursecondwarning`); "Affirmative." (`affirmative`). The clip names are from memory: `lc_voice_missing` on your server lists any unit line that has neither a recording nor a clip, and those can then be recorded.

## The G-Man: the lines that are not real clips

Folder: as in the File column, under `garrysmod/sound/`. These are the collapse lines the gamemode already looks for; until a file is there the moment is silent and the words show. Save as `.wav` (signed 16-bit, 44100 Hz, mono).

| Done | File | When | Paste |
|---|---|---|---|
| [ ] | `livingcity/gman/black_gman_choose.wav` | His window opens (step down, end it, refuse) | [slow, breathy, unsettling calm, odd pauses and emphasis] Step aside. Or end it ... yourself. Choose. |
| [ ] | `livingcity/gman/black_gman_press.wav` | Half her time to answer is gone | [slow, breathy, unsettling calm, odd pauses and emphasis] Time is a luxury you no longer have, Administrator. |
| [ ] | `livingcity/gman/black_gman_lastcall.wav` | 30 seconds left to answer | [slow, breathy, unsettling calm, odd pauses and emphasis] Choose. Or I will ... choose for you. |
| [ ] | `livingcity/gman/black_gman_wise.wav` | She steps down | [slow, breathy, unsettling calm, odd pauses and emphasis] A wise choice, Administrator. |
| [ ] | `livingcity/gman/black_gman_asyouwish.wav` | She ends it herself | [slow, breathy, unsettling calm, odd pauses and emphasis] ... As you wish. |
| [ ] | `livingcity/gman/black_gman_sleep.wav` | His second step: people waking armed | [slow, breathy, unsettling calm, odd pauses and emphasis] Your citizens sleep poorly. They wake ... prepared. |
| [ ] | `livingcity/gman/black_gman_dark.wav` | His third step: the grid failing | [slow, breathy, unsettling calm, odd pauses and emphasis] Even the lights are leaving you. |
| [ ] | `livingcity/gman/black_gman_office.wav` | His fourth step: her last stand | [slow, breathy, unsettling calm, odd pauses and emphasis] It ends where it began, Administrator. In your office. |

## The G-Man: lines it would be nice to have

**Not in the game yet.** Nothing plays these today: they are offered as lines worth making while you are designing his voice. Tell Claude which you record and where you want them heard, and they can be wired in. Suggested folder: `livingcity/gman/`.

| File | Where it could be heard | Paste |
|---|---|---|
| `gman_asked_again.wav` | The collapse: he asks the city's own Administrator again | [slow, breathy, patient, faintly amused] I will ask ... once more. |
| `gman_poorly.wav` | The collapse: she refuses him again | [slow, soft, mock regret] She was given a choice. [pause] She chose ... poorly. |
| `gman_vote_yes.wav` | His vote passes, as time starts again | [slow, pleased, breathy] Then it is ... decided. |
| `gman_new_admin.wav` | A new City Administrator takes the post | [slow, courteous, cold] Congratulations ... Administrator. We will be ... watching. |
| `gman_glimpse.wav` | A glimpse of him about the city | [barely a whisper, amused] Not yet. |
| `gman_crate_taken.wav` | A player takes a weapon from one of his crates | [slow, breathy, approving] A wise ... investment. |
| `gman_dream_open.wav` | The start of one of his riddles in a dream | [very slow, soft, dreamlike] Rise ... and listen. |
| `gman_dream_close.wav` | The end of one of his riddles | [slow, fading] Remember this ... when you wake. |
| `gman_last_stand_won.wav` | The uprising is crushed | [slow, dry, faintly disappointed] How ... disappointing. Another time, then. |
| `gman_last_stand_lost.wav` | The Administrator falls in her office | [slow, satisfied, breathy] The city ... thanks you. In its way. |
| `gman_time_resumes.wav` | Time starts again after his vote | [slow, businesslike] Time, I think ... to resume. |
| `gman_patience.wav` | A directive has waited too long | [slow, cold, quiet] My employers ... are not patient. |

## Colonel Cubbage answers her speeches

Folder: `cubbage/`. Odessa Cubbage, alive and well, answering her address from the Resistance's camp: a well-spoken, defiant older man who enjoys taking her apart. Voice: `A British man in his fifties, rich and theatrical baritone, educated, dry and wry, a confident public speaker with a gleam of mischief; warm toward his listeners, scornful of the one he answers. Close, dry studio recording.` (Describes a kind of voice: no game or actor named.)

| Done | File | Answers | Paste |
|---|---|---|---|
| [ ] | `answer_open1` | (his opening) | [defiant, dry, a speaker enjoying himself] You heard her. Now hear me. Colonel Cubbage, and I have a few corrections to make. |
| [ ] | `answer_ev_deaths1` | her `speech_ev_deaths` | [defiant, dry, a speaker enjoying himself] She talks about blood in the streets. Ask whose hands it's on. Her units don't carry those batons for show. |
| [ ] | `answer_ev_arrests1` | her `speech_ev_arrests` | [defiant, dry, a speaker enjoying himself] Not one of them taken at random, she says. Then tell me what crime a man commits by standing in the wrong square. |
| [ ] | `answer_ev_informers1` | her `speech_ev_informers` | [defiant, dry, a speaker enjoying himself] She thanks the ones who whispered to her. We know who you are too. It isn't too late to stop. |
| [ ] | `answer_ev_informer_hurt1` | her `speech_ev_informer_hurt` | [defiant, dry, a speaker enjoying himself] She calls us cowards. We don't drag families out of bed at night. We deal with the ones who sell their neighbours. |
| [ ] | `answer_ev_taken1` | her `speech_ev_taken` | [defiant, dry, a speaker enjoying himself] Yes, we take some of hers, and we ask them questions. She takes all of you, every day, and doesn't bother asking. |
| [ ] | `answer_ev_escape1` | her `speech_ev_escape` | [defiant, dry, a speaker enjoying himself] Some of ours walked out of her cells. Good. If one of them knocks at your door, open it. |
| [ ] | `answer_ev_posters1` | her `speech_ev_posters` | [defiant, dry, a speaker enjoying himself] She frets about her posters. Paper. She worries about paper while you go hungry. |
| [ ] | `answer_ev_theft1` | her `speech_ev_theft` | [defiant, dry, a speaker enjoying himself] Stealing, she says. The only thief in this city sits in an office and takes your bread to pay for her speeches. |
| [ ] | `answer_ev_defiance1` | her `speech_ev_defiance` | [defiant, dry, a speaker enjoying himself] People raised their voices at her officers. Good. Your voice is the first thing they take, and the last thing you should give up. |
| [ ] | `answer_ev_sabotage1` | her `speech_ev_sabotage` | [defiant, dry, a speaker enjoying himself] Broken machines hurt only you, she says. They're her machines, and they keep you in line. Let them break. |
| [ ] | `answer_ev_heavyhand1` | her `speech_ev_heavyhand` | [defiant, dry, a speaker enjoying himself] Firmness, she calls it. You saw what it was. Remember it. |
| [ ] | `answer_ev_drink1` | her `speech_ev_drink` | [defiant, dry, a speaker enjoying himself] She doesn't blame you for drinking. Of course she doesn't. A drunk doesn't fight back. |
| [ ] | `answer_ev_kindness1` | her `speech_ev_kindness` | [defiant, dry, a speaker enjoying himself] She takes the credit for you sharing your bread. That was you. It's the one thing she can't stamp out, and it frightens her. |
| [ ] | `answer_ev_despair1` | her `speech_ev_despair` | [defiant, dry, a speaker enjoying himself] Hope is a choice, she says. Then choose it. Just don't let her tell you what to hope for. |
| [ ] | `answer_unrest1` | her `speech_unrest` | [defiant, dry, a speaker enjoying himself] Whispers of freedom mean chaos, she says. We mean freedom. She knows the difference, and it terrifies her. |
| [ ] | `answer_hunger1` | her `speech_hunger` | [defiant, dry, a speaker enjoying himself] She feels every empty bowl, does she? Then why is hers never empty? |
| [ ] | `answer_order1` | her `speech_order` | [defiant, dry, a speaker enjoying himself] Her authority is not in question, she says. When someone has to say that out loud, it already is. |
| [ ] | `answer_morale1` | her `speech_morale` | [defiant, dry, a speaker enjoying himself] Tired faces, she says. You're tired because she works you to the bone. Rest isn't her gift. It's yours. |
| [ ] | `answer_calm1` | her `speech_calm` | [defiant, dry, a speaker enjoying himself] Quiet days, she calls them. Quiet is what she calls it when nobody dares to speak. |
| [ ] | `answer_mood_afraid1` | her `speech_mood_afraid` | [defiant, dry, a speaker enjoying himself] You've nothing to fear from her, she says. Tell that to the ones she's taken. |
| [ ] | `answer_mood_restless1` | her `speech_mood_restless` | [defiant, dry, a speaker enjoying himself] She feels your restlessness, she says. Good. Let her feel it. |
| [ ] | `answer_mood_content1` | her `speech_mood_content` | [defiant, dry, a speaker enjoying himself] Rested, fed and calm, she says. Look around you. Does that look like anyone you know? |
| [x] | `answer_slogan1` | her `speech_slogan` | [defiant, dry, a speaker enjoying himself] Love your neighbour, hate the traitor, she says. We agree. Ask yourself who sold this city. |
| [ ] | `answer_close1` | (his closing) | [defiant, dry, a speaker enjoying himself] That's all from me. Keep your heads down, your eyes open, and your door unlocked for a friend. We're closer than she thinks. |

## The Resistance's people

Folder: `resistance/`. Fighters, lookouts, the quartermaster and the medic speaking to a player: tired, wary, warm to their own. Record each twice: `_male1` in a man's voice (`A man in his thirties, gruff and tired, plain-spoken, low and wary, close dry recording.`) and `_female1` in a woman's (`A woman in her thirties, firm and tired, plain-spoken, wary, close dry recording.`). (Describes a kind of voice: no game or actor named.)

| Done | File | Paste |
|---|---|---|
| [x] | `busy_male1` | [tired, wary, plain] I'm busy. Ask someone else. |
| [x] | `busy_female1` | [tired, wary, plain] I'm busy. Ask someone else. |
| [x] | `head_back_male1` | [tired, wary, plain] Right. I'll head back. |
| [x] | `head_back_female1` | [tired, wary, plain] Right. I'll head back. |
| [x] | `medic_broke_male1` | [tired, wary, plain] You don't have the credits, friend. Sorry. |
| [x] | `medic_broke_female1` | [tired, wary, plain] You don't have the credits, friend. Sorry. |
| [x] | `medic_charge_male1` | [tired, wary, plain] I hate to charge, but these don't grow on trees. |
| [x] | `medic_charge_female1` | [tired, wary, plain] I hate to charge, but these don't grow on trees. |
| [x] | `medic_fine_male1` | [tired, wary, plain] You look fine to me. Come back when you're bleeding. |
| [x] | `medic_fine_female1` | [tired, wary, plain] You look fine to me. Come back when you're bleeding. |
| [x] | `medic_hurt_male1` | [tired, wary, plain] Hurt? I can patch you up. |
| [x] | `medic_hurt_female1` | [tired, wary, plain] Hurt? I can patch you up. |
| [x] | `meet_there_male1` | [tired, wary, plain] We'll meet you there. |
| [x] | `meet_there_female1` | [tired, wary, plain] We'll meet you there. |
| [x] | `not_earned_male1` | [tired, wary, plain] Who are you? Get someone who's earned it to ask me. |
| [x] | `not_earned_female1` | [tired, wary, plain] Who are you? Get someone who's earned it to ask me. |
| [x] | `on_watch_male1` | [tired, wary, plain] I'm on watch. Find someone else. |
| [x] | `on_watch_female1` | [tired, wary, plain] I'm on watch. Find someone else. |
| [x] | `parade_male1` | [tired, wary, plain] Any more and you're a parade. |
| [x] | `parade_female1` | [tired, wary, plain] Any more and you're a parade. |
| [x] | `qm_chip_male1` | [tired, wary, plain] Is that a Combine chip? Don't wave it about. Take it to the lab, the doc will decode it. |
| [x] | `qm_chip_female1` | [tired, wary, plain] Is that a Combine chip? Don't wave it about. Take it to the lab, the doc will decode it. |
| [x] | `qm_greet_male1` | [tired, wary, plain] What do you need? |
| [x] | `qm_greet_female1` | [tired, wary, plain] What do you need? |
| [x] | `qm_stranger_male1` | [tired, wary, plain] I don't know you. But if you've brought something for the fight, I'll take it. |
| [x] | `qm_stranger_female1` | [tired, wary, plain] I don't know you. But if you've brought something for the fight, I'll take it. |

## Overwatch's announcements

Folder: `overwatch/`. Overwatch: cold and clinical, a dispatcher, the same voice as his existing recordings.

| Done | File | When | Paste |
|---|---|---|---|
| [x] | `rations1` | A ration distribution starts | [cold, clinical, flat dispatcher] Attention, residents: ration distribution is now in progress. Report to your assigned distribution point. |
| [x] | `sweep1` | An inspection sweep starts | [cold, clinical, flat dispatcher] Attention, residents: inspection sweep in progress. Remain where you are and present your identification. |
| [x] | `curfew1` | Curfew starts | [cold, clinical, flat dispatcher] Attention, residents: curfew is now in effect. Return to your residence block immediately. |
| [x] | `lockdown1` | A lockdown starts | [cold, clinical, flat dispatcher] Attention, all residents: the city is now in lockdown. Remain indoors. Civil Protection is authorized to use force. |
| [x] | `raid1` | A raid on a block starts | [cold, clinical, flat dispatcher] Attention, residents: a block inspection is under way. Do not interfere with Civil Protection. |
| [x] | `supply1` | A supply convoy arrives | [cold, clinical, flat dispatcher] Attention, residents: supply convoy in transit. Clear the route. |
| [x] | `ended1` | An event is over | [cold, clinical, flat dispatcher] Attention, residents: sociostabilization restored. Resume assigned duties. |
| [x] | `rations_soon1` | Two minutes before a ration distribution | [cold, clinical, flat dispatcher] Attention, residents: ration distribution begins in two minutes. |
| [x] | `curfew_soon1` | Two minutes before curfew | [cold, clinical, flat dispatcher] Attention, residents: curfew begins in two minutes. Proceed to your residence block. |
| [x] | `socio_green1` | Sociostability goes green | [cold, clinical, flat dispatcher] Sociostability nominal. Resume normal activity. |
| [x] | `socio_yellow1` | Sociostability goes yellow | [cold, clinical, flat dispatcher] Sociostability marginal. Expect increased inspections. Keep your papers ready. |
| [x] | `socio_red1` | Sociostability goes red | [cold, clinical, flat dispatcher] Judgment waiver in effect. Civil Protection may act at their discretion. Remain indoors. |
| [ ] | `socio_black1` | The city collapses to BLACK (also every 5 minutes while it lasts): open rebellion, the curfew and the shelling, in one | [cold, clinical, flat dispatcher] Attention all residents: sociostability has collapsed. Martial law is in effect. Mandatory curfew. Suppression fire authorized on all exposed sectors. |
| [x] | `dawn1` | Dawn | [cold, clinical, flat dispatcher] Attention, residents: a new work cycle begins. Report to your assignments. |
| [x] | `day1` | Midday | [cold, clinical, flat dispatcher] Attention, residents: productivity quotas remain in effect. |
| [x] | `dusk1` | Dusk | [cold, clinical, flat dispatcher] Attention, residents: the work cycle is ending. Prepare for curfew. |
| [x] | `night1` | Night | [cold, clinical, flat dispatcher] Attention, residents: night cycle. Movement outside residence blocks is restricted. |
| [x] | `outbreak1` | Infected break out into the streets | [cold, clinical, flat dispatcher] Alert: biotic contamination in the city. Avoid the affected area. Containment teams are responding. |
| [x] | `blackout1` | A district loses power | [cold, clinical, flat dispatcher] Alert: power failure in your district. Remain calm. Maintenance has been dispatched. |
| [x] | `power_restored1` | Power comes back | [cold, clinical, flat dispatcher] Power restored. Resume normal activity. |
| [x] | `skirmish_raid1` | Overwatch answers a fight with the Resistance | [cold, clinical, flat dispatcher] Overwatch response team deployed. Residents, clear the area. |
| [x] | `skirmish_sweep1` | Overwatch sweeps into rebel ground | [cold, clinical, flat dispatcher] Overwatch sweep under way in an anticivil sector. Residents, remain clear. |
| [x] | `response1` | A response squad is sent | [cold, clinical, flat dispatcher] Protection response team dispatched. Do not interfere. |
| [x] | `breakout1` | Prisoners break out | [cold, clinical, flat dispatcher] Alert: unauthorized departure from detention. All residents, report sightings to Civil Protection. |
| [x] | `overwatch_drop1` | Overwatch soldiers are dropped in | [cold, clinical, flat dispatcher] Overwatch deployment in progress. Residents, clear the landing zone. |
| [x] | `block_raided1` | A housing block is raided | [cold, clinical, flat dispatcher] Housing block inspection in progress. Remain in your unit. |
| [x] | `territory_grew1` | The Resistance gains ground | [cold, clinical, flat dispatcher] Alert: anticivil activity expanding. Avoid unregistered areas. |
| [x] | `train_arrival1` | A train arrives | [cold, clinical, flat dispatcher] Attention: new arrivals at the platform. Proceed to Civil Intake. |
| [x] | `welcome1` | Someone joins the server (just for them) | [cold, clinical, flat dispatcher] Attention, new resident: report to Civil Intake for registration. |
| [x] | `ambient1` | General city announcements now and then (also her addresses, with lc_breen_broadcasts 1) | [cold, clinical, flat dispatcher] Attention, residents: inaction is conspiracy. Report suspicious behavior. |
| [ ] | `jog1` | The morning jog | [cold, clinical, flat dispatcher] Attention, residents: morning exercise. Assemble for the run. |
| [ ] | `drill1` | The morning drill | [cold, clinical, flat dispatcher] Attention, residents: morning drill. Assemble in the yard. |
| [ ] | `parade1` | The morning parade | [cold, clinical, flat dispatcher] Attention, residents: assemble for the parade. |
| [ ] | `black_stand1` | Her last stand begins | [cold, clinical, flat dispatcher] Overwatch acknowledges incursion at the Nexus. All units, converge and protect the Administrator. |
| [ ] | `black_fallen1` | She's dead (always Overwatch's: she can't announce her own death) | [cold, clinical, flat dispatcher] Administrator biosignal lost. City administration suspended. All units, fall back to the Nexus. |
| [ ] | `black_crushed1` | The uprising is crushed (time ran out) | [cold, clinical, flat dispatcher] Incursion contained. Sociostability restoring. Remain indoors. |
| [ ] | `suppressor_down1` | The suppression device is destroyed | [cold, clinical, flat dispatcher] Alert: Nexus suppression device offline. All units, contain and repair. |
| [ ] | `speech_soon1` | Her address is called: the city must gather (Overwatch's when a player Administrator calls it from her tablet; hers when the city gives it) | [cold, clinical, flat dispatcher] Attention, all residents: the City Administrator will address the city. Report to the assembly point immediately. Attendance is mandatory. |

## The radio

Folder: **`garrysmod/sound/livingcity/radio/`**. One voice of your choosing (a Union announcer for `union`, a Resistance voice for Freq 7).

| Done | File | When | Paste |
|---|---|---|---|
| [ ] | `union1.wav` | An ordinary station, the Union band (none: her ambient recordings play instead) | This is the Union band. Work hard, sleep well. |
| [ ] | `freq7_1.wav` | The Resistance's pirate broadcast, between songs (its .txt is shown on the panel) | This is Frequency 7. They can't jam us all. Stay low, stay alive. |
| [ ] | `freq7_sweep1.wav` | Freq 7 warns: a sweep is coming | Heads up: a sweep is coming into our ground. Hide what you've got. |
| [ ] | `freq7_raid1.wav` | Freq 7 warns: a raid is coming | They're raiding a block. If you can get out, get out now. |
| [ ] | `freq7_curfew1.wav` | Freq 7 warns: curfew | Curfew's coming. Get where you need to be. |
| [ ] | `freq7_supply1.wav` | Freq 7 warns: a supply convoy (a chance to hit it) | Supply convoy on the move. Anyone feeling brave? |
| [ ] | `freq7_incursion1.wav` | Freq 7 warns: the Combine are in rebel ground | Combine in our territory. Everyone to your posts. |
| [ ] | `freq7_lockdown1.wav` | Freq 7 warns: lockdown | Lockdown. Stay put, stay quiet, wait it out. |
| [ ] | `freq7_dropship1.wav` | Freq 7 warns: a dropship | Dropship incoming. Find cover. |

## The dreams' lines

Folder: `dreams/voice/`. Each dream has its own speakers (the column Who); design a voice for each from how it should sound. Save as the file named (`.mp3`, `.ogg` or `.wav`).


### The Cheese Dream (`cheese`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `cheese_hello1.mp3` | The Heads in the Sky | [a choir of giant floating heads, humming, slow, warm, reverb-heavy and slightly off-key] Cheeeeese. Cheeeeeeeese. |
| [ ] | `cheese_gold1.mp3` | The Heads in the Sky | [the same choir, suddenly excited, overlapping, high-pitched] The golden cheese! The golden cheese! |

### Musical Chairs (`chairs`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `chairs_hello1.mp3` | The Music Man | [a cheerful old game-show host, a little too close to the microphone] Ladies and gentlemen, musical chairs! When the music stops... sit. |
| [ ] | `chairs_sit1.mp3` | The Music Man | [the game-show host, sudden and loud] SIT! |

### Wings (`flying`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `flying_hello1.mp3` | A Gentle Voice | [a soft, kind, dreamy narrator, almost whispering] Go on. You always knew you could. Just... flap. |

### It's Raining Melons (`melons`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `melons_hello1.mp3` | The Weatherman | [a chirpy TV weatherman, completely serious about it] Today's forecast: melons. Heavy melons, with a chance of lead. |

### Hooves and All (`horse`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `horse_intro_male1.mp3` | A Hungry Man | [a weary, starving working man, far away, as if from the end of a long tunnel (replaces Half-Life 2's line)] I'm so hungry... I could eat a horse. |
| [ ] | `horse_intro_female1.mp3` | A Hungry Woman | [a tired, starving woman, distant and dreamy (replaces Half-Life 2's line)] I'm so hungry... I could eat a horse. |
| [ ] | `horse_grigori11.mp3` | Father Grigori | [an old, wild-eyed priest with a booming, theatrical voice, laughing between words] Back! Back to the pit, foul beast! |
| [ ] | `horse_grigori21.mp3` | Father Grigori | [the old priest, delighted and horrified at once] It will not die! Why will it not die?! |
| [ ] | `horse_grigori31.mp3` | Father Grigori | [the old priest, preaching at the top of his lungs] Eat, my children! Eat, while it stands still! |
| [ ] | `horse_grigori41.mp3` | Father Grigori | [the old priest, proud and completely mad] I have been shooting this horse since the old days. I will shoot it until the end of days! |
| [ ] | `horse_grigori51.mp3` | Father Grigori | [the old priest, cackling] Hah! Feel the wrath of the Lord, and buckshot! |
| [ ] | `horse_grigori61.mp3` | Father Grigori | [the old priest, suddenly quiet and tender] Hooves and all, children. Hooves and all. |

### The Main Event (`boxing`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `boxing_hello1.mp3` | The Ring Announcer | [a classic big-fight ring announcer, stretching every vowel] Ladies and gentlemen, citizens of all ages... welcome... to the Main Event! |
| [ ] | `boxing_foe11.mp3` | The Ring Announcer | [the ring announcer, building to a roar] In the far corner, weighing in at four hundred pounds of pure debeaked fury... Lamarr! |
| [ ] | `boxing_foe21.mp3` | The Ring Announcer | [the ring announcer, deadly serious] And now, undefeated in forty bouts, dispensing pain at a reasonable price... the Soda Machine! |
| [ ] | `boxing_foe31.mp3` | The Ring Announcer | [the ring announcer, almost screaming] And your final opponent... he's big, he's bald, he's barely a year old... the Baby! |
| [ ] | `boxing_ko1.mp3` | The Ring Announcer | [the ring announcer, ecstatic] It's a knockout! |
| [ ] | `boxing_champ1.mp3` | The Ring Announcer | [the ring announcer, over a roaring crowd] Your new... champion... of the world! |

### The Exam (`exam`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `exam_hello1.mp3` | Doctor Kleiner | [an elderly, fussy, kindly professor, absent-minded and a little alarmed] Good morning, class. Pencils ready. Oh dear. You did study, didn't you? And... where are your trousers? |
| [ ] | `exam_q11.mp3` | Doctor Kleiner | [the old professor, peering over his glasses] Next question. Take your time. Actually, don't. |
| [ ] | `exam_q21.mp3` | Doctor Kleiner | [the old professor, puzzled by his own words] This one will be on the test. This is the test. |
| [ ] | `exam_q31.mp3` | Doctor Kleiner | [the old professor, mumbling] Hmm. I'm not sure I know this one either. |
| [ ] | `exam_end1.mp3` | Doctor Kleiner | [the old professor, very full, patting his stomach] Marvellous. All graded. I couldn't eat another bite. |
| [ ] | `exam_collect1.mp3` | Doctor Kleiner | [the old professor, licking his lips] Pencils down! I shall now collect your papers. Personally. |
| [ ] | `exam_eat11.mp3` | Doctor Kleiner | [the old professor, chewing loudly, mouth full] Mmm. A little dry. |
| [ ] | `exam_eat21.mp3` | Doctor Kleiner | [the old professor, mouth full, ecstatic] Delicious. Absolutely delicious. |
| [ ] | `exam_eat31.mp3` | Doctor Kleiner | [the old professor, chewing, matter-of-fact] I grade with my mouth. It's the only fair way. |
| [ ] | `exam_eat41.mp3` | Doctor Kleiner | [the old professor, crunching, delighted] Oh, this one has a lot of crossing out. Crunchy. |

### The Last Train (`train`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `train_hello1.mp3` | The Conductor | [a hoarse old train conductor, echoing down a station platform] Last train! Last train out of City Seventeen! All aboard! |
| [ ] | `train_hint1.mp3` | The Conductor | [the conductor, conspiratorial, a stage whisper] You're looking right at it. That never works in dreams. |
| [ ] | `train_closing1.mp3` | The Conductor | [the conductor, urgent] Doors closing! Doors closing! |

### Where's Lamarr? (`lamarr`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `lamarr_hello1.mp3` | Doctor Kleiner | [the old professor, fretting over a lost pet] Lamarr? Lamarr! Oh, where has she got to now? Has anyone seen my headcrab? |
| [ ] | `lamarr_found1.mp3` | Doctor Kleiner | [the old professor, overjoyed] Lamarr! There you are, you naughty girl! |

### Running in Molasses (`molasses`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `molasses_hello1.mp3` | A Whisper | [a slow, breathy, menacing whisper, dragged out] Run. Why aren't you running? Run... |

### Hot Potato (`potato`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `potato_hello1.mp3` | The Host | [a manic children's party host] Hot potato! Don't be holding it when the music... I mean the grenade... stops! |

### Overwatch Says (`simon`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `simon_hello1.mp3` | The Officer | [a Civil Protection officer through a gas mask radio, flat and clipped] Citizens. You will do as Overwatch says. Only as Overwatch says. |
| [ ] | `simon_says_jump1.mp3` | The Officer | [the masked officer, flat] Overwatch says: jump. |
| [ ] | `simon_says_crouch1.mp3` | The Officer | [the masked officer, flat] Overwatch says: crouch. |
| [ ] | `simon_says_freeze1.mp3` | The Officer | [the masked officer, flat] Overwatch says: freeze. |
| [ ] | `simon_says_walk1.mp3` | The Officer | [the masked officer, flat] Overwatch says: walk. |
| [ ] | `simon_trap_jump1.mp3` | The Officer | [the masked officer, flat, sly] Jump. |
| [ ] | `simon_trap_crouch1.mp3` | The Officer | [the masked officer, flat, sly] Crouch. |
| [ ] | `simon_end1.mp3` | The Officer | [the masked officer, almost pleased] Compliance noted. Dismissed. |

### Dance Marathon (`dance`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `dance_hello1.mp3` | The DJ | [an over-excited club DJ with heavy reverb] City Seventeen, are you ready to move? Jump on the big beat! |

### Counting Headcrabs (`sheep`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `sheep_hello1.mp3` | A Sleepy Voice | [a soft, slow, yawning bedtime voice] Close your eyes... and count the headcrabs. One... two... |
| [ ] | `sheep_ask1.mp3` | A Sleepy Voice | [the sleepy voice, half asleep] How many was that? Say it... before you drift off... |
| [ ] | `sheep_again1.mp3` | A Sleepy Voice | [the sleepy voice, yawning] Again... from the beginning... |

### Stop the Clocks (`clocks`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `clocks_hello1.mp3` | The Clock Voice | [a slow, deep, echoing voice, like a grandfather clock talking in its sleep] Tick. Tock. Tick. Tock. It's later than you think. It's earlier than you think. It's cheese. |
| [ ] | `clocks_won1.mp3` | The Clock Voice | [the clock voice, slowing down to nothing] Time... stops. |

### The Tea Party (`tea`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `tea_hello1.mp3` | The Host | [a manic, posh, very old-fashioned tea-party host, talking far too fast] Welcome, welcome! No room! No room! Sit anywhere. No, not there. |
| [ ] | `tea_down11.mp3` | The Host | [the posh host, shrieking with delight] Change places! Move down one! |
| [ ] | `tea_down21.mp3` | The Host | [the posh host, shrieking with delight] Change places! Move down two! |
| [ ] | `tea_down31.mp3` | The Host | [the posh host, shrieking with delight] Change places! Move down three! |
| [ ] | `tea_up1.mp3` | The Host | [the posh host, outraged] Clean cup! Clean cup! Move up! |

### The Headcrab Derby (`derby`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `derby_hello1.mp3` | The Commentator | [a breathless horse-racing commentator] Welcome to the Headcrab Derby! Place your bets, place your bets! |
| [ ] | `derby_off1.mp3` | The Commentator | [the racing commentator, at full gallop] And they're off! |
| [ ] | `derby_win11.mp3` | The Commentator | [the racing commentator, ecstatic] And it's Lamarr's Cousin by a leg! It only has legs! |
| [ ] | `derby_win21.mp3` | The Commentator | [the racing commentator, baffled and thrilled] Hooves wins it! Hooves! A headcrab called Hooves! |
| [ ] | `derby_win31.mp3` | The Commentator | [the racing commentator, screaming] Mister Leg takes it! Mister Leg, everybody! |
| [ ] | `derby_win41.mp3` | The Commentator | [the racing commentator, losing his mind] Breen's Toupee! Breen's Toupee wins the Derby! |

### Say Cheese (`photo`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `photo_hello1.mp3` | The Scanner | [a chirpy robotic camera voice, slightly glitchy] Hello! Hello! Lovely day for a photograph! Everybody smile! |
| [ ] | `photo_cheese1.mp3` | The Scanner | [the chirpy robot camera, sing-song] Say cheese! |

### The Doors (`doors`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `doors_hello1.mp3` | A Little Voice | [a small, sweet, slightly eerie child's voice, whispering] Six doors. One plays a song. Listen... listen... |
| [ ] | `doors_open1.mp3` | A Little Voice | [the eerie child's voice, giggling] That one. It was always that one. |

### Splat! (`paint`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `paint_hello1.mp3` | The Painter | [an over-the-top, flamboyant artist] A blank canvas! Make it yours! Splat! |

### Conga! (`conga`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `conga_hello1.mp3` | The Bandleader | [a jolly big-band leader, shouting over brass] Everybody conga! One, two, three, kick! |

### Shh! (`shh`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `shh_hello1.mp3` | A Whisper | [a very quiet, tense whisper] Shhhh. The baby's sleeping. Don't wake the baby. |
| [ ] | `shh_wake1.mp3` | A Whisper | [the whisper, cold and disappointed] You woke the baby. |

### Bubbles (`bubbles`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `bubbles_hello1.mp3` | A Bubbly Voice | [a giggly, bubbly, high-pitched voice] Pop! Pop! Pop them all! |

### The Watchers (`watchers`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `watchers_hello1.mp3` | A Whisper | [a slow, hollow whisper, very close to the ear] They don't move while you watch them. You can't watch them all. |

### Pick Up That Can (`can`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `can_hello1.mp3` | The Officer | [a Civil Protection officer through his mask's radio, flat and bored, just as in Half-Life 2] Pick up that can. |
| [ ] | `can_trash1.mp3` | The Officer | [the officer, flat, already enjoying himself] Now, put it in the trash can. |
| [ ] | `can_again1.mp3` | The Officer | [the officer, slower and lower every word, losing patience] Pick. Up. That. Can. |
| [ ] | `can_litter1.mp3` | The Officer | [the officer, slow and deep, as if he has grown very large] That is not the trash can. Nothing is the trash can. Pick up that can. |
| [ ] | `can_bin1.mp3` | The Bin | [a deep, hollow, echoing voice from inside a metal bin, ending in a small burp] Thank you. Delicious. |
| [ ] | `can_swap1.mp3` | The Can | [the officer's line, tinny and high, as if spoken from inside an empty drinks can] Pick up that can. |
| [ ] | `can_clone1.mp3` | Another Can | [tinny and high, several voices not quite together] Pick up that can. Pick up that can. Pick up that can. |
| [ ] | `can_full1.mp3` | The Can | [tinny and high, delighted with itself] No more room. Pick up all the cans. |

### Kneel Before Her (`adore`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `adore_hello1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] You may look upon me. On your knees, of course. |

### Roses for Her (`roses`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `roses_hello1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Flowers? For me? How predictable. How lovely. |

### Mirror, Mirror (`mirror`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `mirror_hello1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Tell me what you see. |

### The Saviour (`saviour`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `saviour_stop1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] STOP! |
| [ ] | `saviour_soldiers1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Come, my soldiers. Protect them. |
| [ ] | `saviour_safe1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] You are safe now, my children. You are always safe with me. |

### The Loyalty Quiz (`quiz`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `quiz_hello1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Good evening, citizens. Let us see how well you know your city. |
| [ ] | `quiz_end1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Well answered. The city is proud of you. |
| [ ] | `quiz_rebel1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Officers. Remove him. |
| [ ] | `quiz_resume1.mp3` | The Administrator | [her own voice: warm, regal, a little vain] Where were we? Ah, yes. |

### Record Harvest (`harvest`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `harvest_hello1.mp3` | The Administrator | [her own voice] Citizens! The harvest is ripe and the quota is waiting. Bring it in! |
| [ ] | `harvest_medal1.mp3` | The Administrator | [her own voice] For glorious labour beyond the plan: the Order of the Golden Sheaf. |

### The Union Shift (`shift`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `shift_hello1.mp3` | The Administrator | [her own voice] My workers! Today's norm is one hundred percent. Tomorrow's is fourteen hundred. Why wait? |
| [ ] | `shift_double1.mp3` | The Administrator | [her own voice] Double norm! Every blow counts twice! |
| [ ] | `shift_hero1.mp3` | The Administrator | [her own voice] A new Hero of Labour! Hang their portrait beside mine! |
| [ ] | `shift_idle1.mp3` | The Administrator | [her own voice] I see you standing there. Back to work, citizen! |

### Careless Talk (`spy`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `spy_hello1.mp3` | The Administrator | [her own voice] Careless talk costs lives, my children. There is a traitor among you. Watch them closely. |
| [ ] | `spy_caught1.mp3` | The Administrator | [her own voice] Time is up. The traitor is revealed. I thank my vigilant citizens. |
| [ ] | `spy_chant_male1.mp3` | A diner (man), cheering | [] Glory to the Administrator! |
| [ ] | `spy_chant_female1.mp3` | A diner (woman), cheering | [] Glory to the Administrator! |
| [ ] | `spy_flat_male1.mp3` | The spy (man), flat and bored | [] Glory to the Administrator. |
| [ ] | `spy_flat_female1.mp3` | The spy (woman), flat and bored | [] Glory to the Administrator. |
| [ ] | `spy_whisper_male1.mp3` | The spy (man), whispering | [] The old bridge. After curfew. Don't be late. |
| [ ] | `spy_whisper_female1.mp3` | The spy (woman), whispering | [] The old bridge. After curfew. Don't be late. |
| [ ] | `spy_ready1.mp3` | The officer | [] Ready! |
| [ ] | `spy_aim1.mp3` | The officer | [] Aim! |
| [ ] | `spy_fire1.mp3` | The officer | [] Fire! |

### The Newsreel (`newsreel`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `newsreel_hello1.mp3` | The Administrator | [her own voice] Welcome to my City Seventeen, where every citizen smiles, and every smile is sincere! |
| [ ] | `newsreel_end1.mp3` | The Administrator | [her own voice] And so another happy day draws to a close. Goodnight, my City Seventeen! |

### Two Minutes of Hate (`hate`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `hate_hello1.mp3` | The Administrator | [her own voice] Citizens! Behold the enemy of the people. Let him hear you! |
| [ ] | `hate_end1.mp3` | The Administrator | [her own voice] The enemy fades. Love returns. Love me. |

### The Mass Games (`massgames`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `massgames_hello1.mp3` | The Administrator | [her own voice] Cards ready! Together, you are my portrait. |
| [ ] | `massgames_flip1.mp3` | The Administrator | [her own voice] FLIP! |

### On-the-Spot Guidance (`guidance`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `guidance_hello1.mp3` | The Administrator | [her own voice] Show me your work. I have so much guidance to give. |
| [ ] | `guidance_end1.mp3` | The Administrator | [her own voice] Excellent. I have improved everything here simply by looking at it. |

### The Scrap Drive (`scrap`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `scrap_hello1.mp3` | The Administrator | [her own voice] Every pot, every pan, every bucket. The city needs your scrap! |

### Flowers for the Liberators (`flowers`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `flowers_hello1.mp3` | The Administrator | [her own voice] My soldiers are marching home. Show them how much you love them. |

### Duck and Cover (`duck`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `duck_hello1.mp3` | Sunny the Scanner | [] Hi, citizens! I'm Sunny! The nasty terrorists have built a rocket. If they launch it, what do we do? We duck, and cover! |
| [ ] | `duck_siren1.mp3` | Sunny the Scanner | [] Rocket launch! Duck and cover! Crouch beside a table, quick as you can! |
| [ ] | `duck_clear1.mp3` | Sunny the Scanner | [] All clear! The Combine protects us. Wasn't that fun? |

### Ravenholm (`ravenholm`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `ravenholm_rise1.mp3` | Father Grigori | [] RISE, my children! Rise from your graves and FEAST! |
| [ ] | `ravenholm_stop1.mp3` | The Administrator | [her own voice] Begone, false priest! These citizens are under MY protection. |
| [ ] | `ravenholm_safe1.mp3` | The Administrator | [her own voice] You see? Only I can keep you safe. Never forget it. |
| [ ] | `ravenholm_vort1.mp3` | A Vortigaunt | [] The Vortessence sees through the false light. Behold what is true. |
| [ ] | `ravenholm_good1.mp3` | Father Grigori | [] Hah! Back to your rest, poor souls! Not one of these children shall be harmed! |
| [ ] | `ravenholm_defeat1.mp3` | The Administrator | [her own voice] No... NO! This is MY dream! |

### battleline (`battleline`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `battleline_hello1.mp3` | The Administrator | [her own voice] My brave citizens! The terrorists are coming. Take up arms beside my soldiers and hold the line! |
| [ ] | `battleline_giant1.mp3` | The Administrator | [her own voice] Look at the size of that one! Everyone, fire! |
| [ ] | `battleline_traitor1.mp3` | The Administrator | [her own voice] You fired on MY soldiers? Manhacks! Deal with this traitor. |
| [ ] | `battleline_turned1.mp3` | The Administrator | [her own voice] A traitor wants to be a rebel? Then be one. Forever. |
| [ ] | `battleline_doom1.mp3` | Overwatch | [] Sector overrun. Hostiles beyond containment. Requesting immediate air support. |
| [ ] | `battleline_air1.mp3` | The Administrator | [her own voice] Did you think I would abandon you? Behold my wings! |
| [ ] | `battleline_held1.mp3` | The Administrator | [her own voice] The line held! Every one of you is a hero of my city. |

### vortwar (`vortwar`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `vortwar_in1.mp3` | A Vortigaunt | [] The Vortessence sees through her false light. Come, stand with us, and see what is true. |
| [ ] | `vortwar_answer11.mp3` | A Vortigaunt | [] She says she protects you. Ask who built the walls. |
| [ ] | `vortwar_answer21.mp3` | A Vortigaunt | [] Her smile is painted on. Look closer. |
| [ ] | `vortwar_answer31.mp3` | A Vortigaunt | [] We were chained as you are chained. We are free. You can be. |
| [ ] | `vortwar_answer41.mp3` | A Vortigaunt | [] The dream is hers. The waking is yours. |
| [ ] | `vortwar_loyal1.mp3` | The Administrator | [her own voice] Begone, false spirits! These citizens are MINE. |
| [ ] | `vortwar_shatter1.mp3` | A Vortigaunt | [] Her light was never yours. Wake, and see. |

### The Loyalty Quiz's questions (`quiz`)

| Done | File | Who | Paste |
|---|---|---|---|
| [ ] | `quiz_q11.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] Who keeps you safe at night? |
| [ ] | `quiz_q21.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] What do we do when an officer speaks to us? |
| [ ] | `quiz_q31.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] Where does your ration come from? |
| [ ] | `quiz_q41.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] What are the people who call themselves the Resistance? |
| [ ] | `quiz_q51.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] Complete the phrase: Compliance is... |
| [ ] | `quiz_q61.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] How would you describe the Administrator? |
| [ ] | `quiz_q71.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] What should you do if you see a rebel? |
| [ ] | `quiz_q81.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] Who is your best friend? |
| [ ] | `quiz_q91.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] What happens to those who disobey? |
| [ ] | `quiz_q101.mp3` | The Administrator | [her own voice: warm, regal, a little vain, a quizmaster] What is the most important thing a citizen can be? |

## Citizens showing the way

Folder: `citizens/`. The citizen voices (man and woman) above: paste each line twice.

| Done | Man's file | Woman's file | When | Paste |
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

## The Citizen Information clerk

The clerk behind the Citizen Information desk: flat, tired, official. Folder: **`garrysmod/sound/livingcity/clerk/`**. One voice for every clerk (or record a man's and a woman's take and keep whichever fits). Without a recording, a terminal's chime, and the words show.

| Done | File | When | Paste |
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

## The old-timer

The old man who gives advice: warm, worn, a little wry. Folder: **`garrysmod/sound/livingcity/oldtimer/`**. For "Is anyone fighting back?" he goes on to say where the Resistance gathers (that part changes with the map, so it only shows as words). Without a recording, Half-Life 2's own citizen voice.

| Done | File | When | Paste |
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

## Machines

The ration dispenser and the vending machines, in a flat machine voice (a Combine terminal's). Folder: **`garrysmod/sound/livingcity/machines/`**. Without a recording, the machine's beep.

| Done | File | When | Paste |
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
