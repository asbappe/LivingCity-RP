# Voice scripts: what to paste into ElevenLabs

**Made from the code by `python3 _dev/voice_lines.py`: never edit it by hand.** The lines of `VOICE_LINES.md` that are generated speech (named citizens, units, the Administrator, and the G-Man's made-up lines), written the way ElevenLabs wants them, with a voice description for each voice.

## How to use it

- **Model:** Eleven v4 (or v3). A direction in **square brackets** changes how what follows is said: `[whispers] Careful.` It is not read out. Put it just before the words it changes. Your own wording works (`[tired, flat]`), as do reactions (`[sighs]`, `[exhales]`, `[short laugh]`) and `[pause]`. If a tag is read aloud, the model is not v4 or v3, or the brackets are not square.
- **Copy the "Paste" cell as it is.** Generate two or three takes and keep the best; a second good take can be saved as `...2` (one is picked at random in game).
- **Save each file under the name in the table**, `.mp3` or `.wav`, into the folder named above the table (on the server, under `garrysmod/sound/livingcity/`).
- **Tags are a starting point.** If a line comes out overacted, delete the tag or soften it (`[quietly]`): these are tired people, not actors. The breaks are the only loud ones.
- **The same voice for every line of a kind:** design the voice once (below), save it to your voices, and use that saved voice for the whole table.
- **Staying legal:** the descriptions below describe a kind of voice in ordinary words. Do not name a game, a character or an actor in a voice prompt, and do not upload audio from the games to clone a voice: that needs the performer's consent, and ElevenLabs' terms forbid it.

## All of them at once (instead of pasting each line)

`_dev/tools/elevenlabs_batch.py` sends every line to ElevenLabs and saves each file under its right name, in the right folder, ready to upload. On Linux Mint, in a terminal in the gamemode's folder:
**Just the citizens, the simple way:** keep `record_citizens.sh`, `elevenlabs_batch.py` and `voice_batch.tsv` together in one folder (any folder) and run `bash record_citizens.sh` there. It asks for your key (hidden, never saved), shows the cost, makes 3 to listen to, then the rest, and makes them all louder (needs `ffmpeg`). The two voice ids are at the top of the script. Upload what lands in `voice_out/sound/livingcity/citizens/` (made beside the script) to the server's `garrysmod/sound/livingcity/citizens/`.


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
| [ ] | `rations1.wav` | A ration distribution starts | [warm, motherly, smiling] Good news, everyone! Rations are being handed out right now. Come along, and don't forget your card. |
| [ ] | `sweep_firm1.wav` | An inspection sweep starts | [firm, composed, still kind] A little inspection, nothing to worry about. Stand still, papers out, and it'll be over before you know it. |
| [ ] | `curfew_firm1.wav` | Curfew starts | [firm, composed, still kind] Bedtime, everyone. Curfew starts now: home you go, and stay there till morning. |
| [ ] | `lockdown_stern1.wav` | A lockdown starts | [stern, cold, slowly] The city is in lockdown. Stay inside. I am not asking. |
| [ ] | `raid_stern1.wav` | A raid on a block starts | [stern, cold, slowly] Civil Protection is visiting one of our blocks. Cooperate, and everyone sleeps soundly tonight. |
| [ ] | `supply1.wav` | A supply convoy arrives | [warm, motherly, smiling] A supply convoy is coming through! Step aside and let it pass, there's a love. |
| [ ] | `ended1.wav` | An event is over | [warm, motherly, smiling] That's all done. Thank you, everyone. Back to your day. |
| [ ] | `rations_soon1.wav` | Two minutes before a ration distribution | [warm, motherly, smiling] In just a couple of minutes, rations! Start making your way over, dears. |
| [ ] | `curfew_soon_firm1.wav` | Two minutes before curfew | [firm, composed, still kind] Curfew in two minutes. Finish up and head home, please. |
| [ ] | `socio_green1.wav` | Sociostability goes green | [warm, motherly, smiling] Everything is calm again. Well done, all of you. |
| [ ] | `socio_yellow_firm1.wav` | Sociostability goes yellow | [firm, composed, still kind] Things are a little tense. Papers ready, heads down, and we'll get through it. |
| [ ] | `socio_red_stern1.wav` | Sociostability goes red | [stern, cold, slowly] We are on red. Go home. Whatever happens out there now, you were warned. |
| [ ] | `socio_black_furious1.wav` | The city collapses to BLACK (also every 5 minutes while it lasts): open rebellion, the curfew and the shelling, in one | [furious, barely controlled, clipped] Citizens. The city has been overrun by its own ingratitude. Go indoors and stay there. Anyone in the open will be fired upon from the Nexus. This is not a request. |
| [ ] | `dawn1.wav` | Dawn | [warm, motherly, smiling] Good morning, everyone! Rise and shine: a brand new day for the city. |
| [ ] | `day1.wav` | Midday | [warm, motherly, smiling] Halfway through the day. Keep it up, I'm proud of you. |
| [ ] | `dusk1.wav` | Dusk | [warm, motherly, smiling] The day's nearly done. Finish up, and think about heading home. |
| [ ] | `night1.wav` | Night | [warm, motherly, smiling] Goodnight, everyone. Sleep well, and dream of the city. |
| [ ] | `outbreak_firm1.wav` | Infected break out into the streets | [firm, composed, still kind] Something has got out of the infestation. Keep away from it and let the crews do their work. |
| [ ] | `blackout_firm1.wav` | A district loses power | [firm, composed, still kind] A little power cut, nothing more. The crews are on it, so stay calm. |
| [ ] | `power_restored1.wav` | Power comes back | [warm, motherly, smiling] Lights back on! Thank you for your patience. |
| [ ] | `skirmish_raid_stern1.wav` | Overwatch answers a fight with the Resistance | [stern, cold, slowly] Overwatch is dealing with some trouble. Stay well away from it. |
| [ ] | `skirmish_sweep_stern1.wav` | Overwatch sweeps into rebel ground | [stern, cold, slowly] Overwatch is cleaning up a troubled corner of the city. Let them work. |
| [ ] | `response_stern1.wav` | A response squad is sent | [stern, cold, slowly] A response team is on its way. Please don't get in their way. |
| [ ] | `breakout_furious1.wav` | Prisoners break out | [furious, barely controlled, clipped] Some people have run from where they belong. If you see them, tell a unit. Now. |
| [ ] | `overwatch_drop_stern1.wav` | Overwatch soldiers are dropped in | [stern, cold, slowly] Overwatch soldiers are arriving. Make way for them. |
| [ ] | `block_raided_stern1.wav` | A housing block is raided | [stern, cold, slowly] We're checking one of our housing blocks. Stay in your room and it'll be quick. |
| [ ] | `territory_grew_firm1.wav` | The Resistance gains ground | [firm, composed, still kind] Some troublemakers are spreading out. Don't go near them, and don't listen to them. |
| [ ] | `train_arrival1.wav` | A train arrives | [warm, motherly, smiling] Welcome to the city, all you new faces! Civil Intake is just this way. |
| [ ] | `welcome1.wav` | Someone joins the server (just for them) | [warm, motherly, smiling] Hello, and welcome to the city! You're going to love it here. |
| [ ] | `ambient1.wav` | General city announcements now and then (also her addresses, with lc_breen_broadcasts 1) | [warm, motherly, smiling] Remember, a good citizen is a happy citizen. And I do so want you all to be happy. |
| [ ] | `jog1.wav` | The morning jog | [warm, motherly, smiling] Morning, everyone! Shoes on: time for our little jog. |
| [ ] | `drill1.wav` | The morning drill | [warm, motherly, smiling] Into the yard, everyone, for our morning exercises. Stretch! |
| [ ] | `parade1.wav` | The morning parade | [warm, motherly, smiling] Parade time! Chins up, shoulders back, and let's show the city who we are. |
| [ ] | `black_stand_furious1.wav` | Her last stand begins | [furious, barely controlled, clipped] So you have come for me. Come, then. You will not reach me. |
| [ ] | `black_crushed_stern1.wav` | The uprising is crushed (time ran out) | [stern, cold, slowly] It is over. The city is mine again, and I will remember every one of you. |
| [ ] | `suppressor_down_furious1.wav` | The suppression device is destroyed | [furious, barely controlled, clipped] They have silenced the Nexus. It changes nothing. |

## What named citizens say

Folder: `citizens/`. Paste each line twice: once with the man's voice (save as the man's file), once with the woman's.

| Done | Man's file | Woman's file | Paste |
|---|---|---|---|
| | | | **Openers (a word or two before another line)** |
| [ ] | `say_open_listen_male1` | `say_open_listen_female1` | [low, urgent] Listen. |
| [ ] | `say_open_look_male1` | `say_open_look_female1` | [tired, flat] Look. |
| [ ] | `say_open_please_male1` | `say_open_please_female1` | [pleading, quietly] Please. |
| [ ] | `say_open_quiet_male1` | `say_open_quiet_female1` | [whispers, tense] Keep your voice down. |
| [ ] | `say_open_well_male1` | `say_open_well_female1` | [thinking it over] Well... |
| [ ] | `say_open_you_male1` | `say_open_you_female1` | [sharp, low] You. |
| | | | **Hello** |
| [ ] | `say_greet_cold_male1` | `say_greet_cold_female1` | [cold, flat] What do you want? |
| [ ] | `say_greet_guarded_male1` | `say_greet_guarded_female1` | [wary, guarded] Do I know you? |
| [ ] | `say_greet_plain_male1` | `say_greet_plain_female1` | [tired, dry] Hey. Still here, huh. [exhales] Me too. |
| [ ] | `say_greet_unit_male1` | `say_greet_unit_female1` | [nervous, too polite] No trouble here, officer. |
| [ ] | `say_greet_warm_male1` | `say_greet_warm_female1` | [relieved, warm] Oh, it's you. Good to see a friendly face. |
| | | | **Goodbye** |
| [ ] | `say_bye_cold_male1` | `say_bye_cold_female1` | [cold, final] We're done here. |
| [ ] | `say_bye_plain_male1` | `say_bye_plain_female1` | [flat, tired] I should get going. |
| [ ] | `say_bye_warm_male1` | `say_bye_warm_female1` | [warm, quietly] Take care of yourself. [sincere] I mean it. |
| | | | **Yes, no, perhaps** |
| [ ] | `say_later_male1` | `say_later_female1` | [hushed, tense] Not now. Not here. |
| [ ] | `say_maybe_male1` | `say_maybe_female1` | [hesitant] Maybe. I'd have to think about it. |
| [ ] | `say_no_male1` | `say_no_female1` | [flat, apologetic] No. Sorry. |
| [ ] | `say_no_hard_male1` | `say_no_hard_female1` | [firm, low] No. [pause] And don't ask me again. |
| [ ] | `say_yes_male1` | `say_yes_female1` | [plain, tired] Yeah. All right. |
| [ ] | `say_yes_warm_male1` | `say_yes_warm_female1` | [warm, a small smile] For you? Of course. |
| | | | **What they know** |
| [ ] | `say_ask_else_male1` | `say_ask_else_female1` | [tired, dismissive] You're asking the wrong person. |
| [ ] | `say_cant_say_male1` | `say_cant_say_female1` | [hushed, uneasy] I can't talk about that. You know why. |
| [ ] | `say_dunno_male1` | `say_dunno_female1` | [guarded, flat] I wouldn't know anything about that. |
| [ ] | `say_dunno_scared_male1` | `say_dunno_scared_female1` | [frightened, quick] I don't know, and I don't want to know. |
| [ ] | `say_heard_male1` | `say_heard_female1` | [low, careful] I've heard things. [pause] Everyone has. |
| [ ] | `say_truth_male1` | `say_truth_female1` | [quiet, grim] Honestly? [sighs] It's as bad as it looks. |
| | | | **How they are** |
| [ ] | `say_state_angry_male1` | `say_state_angry_female1` | [tight, barely holding it in] I've had about all I can take. |
| [ ] | `say_state_fine_male1` | `say_state_fine_female1` | [worn, matter of fact] Getting by. That's all anyone can say. |
| [ ] | `say_state_hopeful_male1` | `say_state_hopeful_female1` | [quiet, hopeful] It can't last forever. Nothing does. |
| [ ] | `say_state_hungry_male1` | `say_state_hungry_female1` | [weak, hollow] I haven't had a real meal in days. |
| [ ] | `say_state_lonely_male1` | `say_state_lonely_female1` | [soft, grateful] It's good to just talk to someone. |
| [ ] | `say_state_low_male1` | `say_state_low_female1` | [hollow, defeated] What's the point? [pause] Really, what is the point? |
| [ ] | `say_state_scared_male1` | `say_state_scared_female1` | [frightened, hushed] I'm scared. Aren't you? |
| [ ] | `say_state_tired_male1` | `say_state_tired_female1` | [exhausted] I'm tired. [sighs] Just so tired. |
| | | | **Answering how they were spoken to** |
| [ ] | `say_agree_male1` | `say_agree_female1` | [dry, low] You're not wrong. |
| [ ] | `say_disagree_male1` | `say_disagree_female1` | [even, firm] I don't see it that way. |
| [ ] | `say_insulted_male1` | `say_insulted_female1` | [stung, stiff] Hey. There's no need for that. |
| [ ] | `say_laugh_male1` | `say_laugh_female1` | [short laugh] Ha. [warm, surprised] That's the first laugh I've had all week. |
| [ ] | `say_sorry_male1` | `say_sorry_female1` | [nervous, backing down] I'm sorry. I didn't mean anything by it. |
| [ ] | `say_thanks_male1` | `say_thanks_female1` | [sincere, quietly] Thank you. I won't forget it. |
| [ ] | `say_thanks_big_male1` | `say_thanks_big_female1` | [moved, voice catching] You didn't have to do that. Thank you. |
| [ ] | `say_threatened_male1` | `say_threatened_female1` | [frightened, hands up] I don't want any trouble. |
| | | | **The Combine** |
| [ ] | `say_careful_male1` | `say_careful_female1` | [whispers] Careful. The walls have ears. |
| [ ] | `say_fear_units_male1` | `say_fear_units_female1` | [low, warning] Stay away from the units today. They're in a mood. |
| [ ] | `say_hate_quiet_male1` | `say_hate_quiet_female1` | [low, bitter, controlled] One day they'll answer for all of it. |
| [ ] | `say_loyal_male1` | `say_loyal_female1` | [earnest, a little rehearsed] The Administrator knows best. I believe that. |
| [ ] | `say_loyal_warn_male1` | `say_loyal_warn_female1` | [alarmed, hushed] You shouldn't say things like that. Someone will hear. |
| [ ] | `say_obey_male1` | `say_obey_female1` | [tired, kindly] Keep your head down and do what they say. That's how you make it. |
| [ ] | `say_units_near_male1` | `say_units_near_female1` | [under their breath] Not with them standing right there. |
| | | | **The Resistance** |
| [ ] | `say_res_deny_male1` | `say_res_deny_female1` | [quick, stiff, too careful] I don't know anything about any Resistance. |
| [ ] | `say_res_hint_male1` | `say_res_hint_female1` | [whispers, meaningful] There are people. [pause] That's all I'll say. |
| [ ] | `say_res_refuse_male1` | `say_res_refuse_female1` | [afraid, firm] I've got people to think about. Leave me out of it. |
| [ ] | `say_res_respect_male1` | `say_res_respect_female1` | [quiet, a hint of a smile] Whoever they are, good luck to them. |
| [ ] | `say_res_side_male1` | `say_res_side_female1` | [very quietly, steady] If someone needed a door left open, mine might be. |
| | | | **Warnings and tips** |
| [ ] | `say_tip_help_male1` | `say_tip_help_female1` | [low, kind] If you need something, ask. [whispers] Quietly. |
| [ ] | `say_tip_trouble_male1` | `say_tip_trouble_female1` | [uneasy, low] There's gonna be trouble tonight. I can feel it. |
| [ ] | `say_warn_asked_male1` | `say_warn_asked_female1` | [low, urgent] Someone's been asking about you. |
| [ ] | `say_warn_go_male1` | `say_warn_go_female1` | [urgent, hushed] You should go. Now. |
| [ ] | `say_warn_informer_male1` | `say_warn_informer_female1` | [low, careful] Watch who you talk to. Not everyone here is a friend. |
| [ ] | `say_warn_watched_male1` | `say_warn_watched_female1` | [whispers, barely moving lips] You're being watched. Don't turn around. |
| | | | **Asking and giving** |
| [ ] | `say_ask_food_male1` | `say_ask_food_female1` | [weak, ashamed to ask] You got anything to eat? [pause] Anything? |
| [ ] | `say_ask_help_male1` | `say_ask_help_female1` | [desperate, quietly] I need help. I've got nobody else to ask. |
| [ ] | `say_ask_smoke_male1` | `say_ask_smoke_female1` | [edgy, hopeful] You wouldn't have a smoke on you, would you? |
| [ ] | `say_decline_gift_male1` | `say_decline_gift_female1` | [gentle, proud] I can't take that. Keep it. |
| [ ] | `say_offer_male1` | `say_offer_female1` | [hushed, quick] Here. Take it. Don't say where you got it. |
| | | | **As a mind gives way** |
| [ ] | `say_break_accuse_male1` | `say_break_accuse_female1` | [loud, accusing, pointing] That one! That one talks to Civil Protection! |
| [ ] | `say_break_accused_male1` | `say_break_accused_female1` | [panicked, loud] That's a lie! I never told them anything! |
| [ ] | `say_break_beaten_male1` | `say_break_beaten_female1` | [crying out in pain, terrified] Stop! Please, I didn't do anything! |
| [ ] | `say_break_binge_male1` | `say_break_binge_female1` | [slurred, tired, bitter] Leave me alone. Just let me have this. |
| [ ] | `say_break_defy_male1` | `say_break_defy_female1` | [quiet, defiant, steady] They can't scare all of us forever. |
| [ ] | `say_break_despair_male1` | `say_break_despair_female1` | [broken, near tears] I can't. [shaky breath] I just can't anymore. |
| [ ] | `say_break_inform_male1` | `say_break_inform_female1` | [nervous, eager, hushed] Officer. I've got something you'll want to hear. |
| [ ] | `say_break_seek_male1` | `say_break_seek_female1` | [relieved, a little shaky] There you are. I've been looking for you. |
| [ ] | `say_break_share_male1` | `say_break_share_female1` | [gentle, insisting] Go on, take half. You need it more than I do. |
| [ ] | `say_break_steady_male1` | `say_break_steady_female1` | [calm, soothing, low] Easy. Easy now. We're still here, right? |
| [ ] | `say_break_tantrum_male1` | `say_break_tantrum_female1` | [shouting, voice cracking] I've had enough! Do you hear me? Enough! |
| | | | **What they saw** |
| [ ] | `say_grief_male1` | `say_grief_female1` | [numb, grieving] They took my friend. [pause] Just dragged them off. |
| [ ] | `say_saw_beating_male1` | `say_saw_beating_female1` | [under their breath, tense] Don't look. Just keep walking. |
| [ ] | `say_saw_death_male1` | `say_saw_death_female1` | [horrified, gasping] Oh God. Oh God, no. |

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
