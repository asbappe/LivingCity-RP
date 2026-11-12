# What named people say, recorded

Asked for by the owner, 11 November: "architect and design natural sounding lines so that we can pre record NPC lines and cover as much situational dialogs as possible with the least amount of lines". Code: `sv_livingcity_lines.lua` (the bank and playing it), used by `sv_livingcity_brain.lua` (free talk, the director) and `sv_livingcity_mindsact.lua` (breaks). Tests: LinesTests (26). The list to record: `VOICE_LINES.md`, sections 10 and 11. **The text to paste into ElevenLabs, with voice descriptions: `VOICE_SCRIPTS.md`.**

## The idea

Voicing every answer as it is written would cost money on every line, for ever. Instead there is a **small bank of lines recorded once**, and the hosted model **picks from it**: it is shown the bank and asked which line this person would say right now. A recorded line costs nothing to play, sounds the same every time, and is in the person's own voice.

**79 lines for a citizen (a man's take and a woman's of each: 158 recordings) and nothing for a unit (all 21 of his lines are Half-Life 2's own clips): 158 recordings, and only for the citizens who get the recorded voice.** With the directions for ElevenLabs they come to about 9,000 characters; with the Administrator's 36 announcements and the G-Man's 8 made-up lines, 211 files and about 13,000 characters, which `_dev/tools/elevenlabs_batch.py` makes in one run (`VOICE_SCRIPTS.md`). The wording is American (the owner, 11 November), to sit with the Half-Life 2 citizens still heard around them. With ElevenLabs that is a one-off of well under a dollar at the prices seen in November, or a few thousand of a plan's monthly characters.

## How so few lines cover so much

1. **Lines are written by what they do, not what they are about.** "I wouldn't know anything about that." answers any question about anything. "You should go. Now." fits a raid, a snitch, a unit coming, a fight starting. The bank is a set of moves: greet, part, agree, refuse, put off, not know, admit, thank, back down, take offence, warn, ask, give.
2. **Nothing specific is in them:** no names, jobs, places, times of day, events or items. Any named citizen can say any line, at any hour, on any map.
3. **The same few feelings throughout:** warm, plain, guarded, cold. Where the feeling changes the words there are two or three versions (four greetings, three goodbyes); where it does not there is one.
4. **Six openers** ("Listen.", "Look.", "Please.", "Keep your voice down.", "Well.", "You.") can be said before any other line. They turn 73 lines into several hundred that sound different: "Look. Sorry, but no." is not "Please. Sorry, but no."
5. **Who they are comes from which line is picked,** not from the words: the loyal say "The Administrator knows best. Everyone knows that!"; the frightened say "I don't know, and I don't want to know."; a sympathizer who trusts you says "There are people. That's all I'll say."

## The groups (a citizen)

| Group | Lines | For |
|---|---|---|
| Openers | 6 | a word or two before another line |
| Hello, goodbye | 8 | by how they feel about you; one for being spoken to by a unit |
| Yes, no, perhaps | 6 | agreeing, refusing, refusing for good, putting it off |
| What they know | 6 | not knowing, not daring to know, rumours, the unsayable, the plain truth |
| How they are | 8 | all right, hungry, tired, afraid, angry, lonely, hopeful, in despair (their mind chooses) |
| Answering how they were spoken to | 8 | thanks, a big thanks, sorry, insulted, threatened, a laugh, agreeing, disagreeing |
| The Combine | 7 | loyalty, fear, a warning to talk less, hatred said low |
| The Resistance | 5 | denying, hinting, offering, refusing, approving |
| Warnings and tips | 6 | being asked about, being watched, go now, informants, help offered, trouble coming |
| Asking and giving | 5 | food, a smoke, help; giving something; refusing a gift |
| As a mind gives way | 11 | one for each break players see or hear (`city-minds.md`) |
| What they saw | 3 | a beating, a death, a friend taken |

A unit's 17 are the same moves in his register: "Citizen.", "Move along.", "Identification. Now.", "Affirmative.", "Negative.", "That information is restricted.", and so on, with one kind line for a unit who has some kindness in him and two for when his mind gives way.

**A unit's lines are all Half-Life 2's own Civil Protection clips now** (the owner, 11 November: "already exist in HL2"; 21 lines, each naming clips in `sound/npc/metropolice/vo/` that were checked against the owner's server list): "Citizen.", "Move along.", "Don't move.", "First warning: move away.", "Final warning.", "You want a malcompliance verdict?", "All right, you can go." **Nothing to record for units, and no radio effect to make.** The words are read from the clips' names (that folder has no captions), so one or two may differ slightly from what is said: tell Claude and the words are corrected.

## Two voices by personality

The owner, 11 November: "if the NPCs personality lines up with the available default HL2 voice lines, then they could be used, and then save other NPCs for the custom voice lines". Built from the owner's own clip list (`_dev/tools/hl2_lines.txt`, written on their server by `lc_hl2_lines`).

- **Each named citizen has one voice for life** (`LC.VoiceOf`): Half-Life 2's, or the recorded one. It comes from who they are: sociable plus hopeful plus half of brave, at zero or more, keeps Half-Life 2's (its citizens sound lively and earnest); below zero gets the recorded voice (the withdrawn, the despairing, the timid). About half the roster each way. It is kept with the person, so it never changes.
- **Until the recorded bank exists for their sex, everyone has Half-Life 2's voice**, so nothing waits on recording. `lc_voice_split` 0: no split, every named citizen takes the recorded voice once it exists.
- **A second bank, of Half-Life 2's own clips** (`LC.HL2Lines`, 107 lines, nothing to record): the lines of its citizens that fit a city under occupation, with the game's own words: "I wouldn't say that too loud.", "Know what you mean.", "What am I supposed to do about it?", "God I'm hungry.", "They're never gonna make a stalker out of me.", "We trusted you!", "Civil Protection!". Everything about Freeman, fighting and vortigaunts is left out. Every clip was checked to be on the server for both the man and the woman.
- **In free talk the model is shown the bank of the person spoken to** and picks from it, so someone with Half-Life 2's voice answers with a real Half-Life 2 line, spoken, today. When none fits it writes words of its own (text, with a Half-Life 2 "answer" sound).
- **A break or a director's line meant for the recorded bank** is said their own way by someone with Half-Life 2's voice (`LC.HL2Instead`: a tantrum is "This is bullshit!", an accusation "We trusted you!", despair "What's the point?"), or not said where Half-Life 2 has nothing like it.
- **The clip swap** (below) changes a citizen's clip only for named citizens with the recorded voice; everyone else keeps Half-Life 2's.
- Unnamed citizens and the Resistance's fighters keep Half-Life 2's voice for everything.

## One voice for each named person

The owner, 11 November: a named citizen must not answer in a recorded voice and then say a Half-Life 2 line in another.

- **Once any line of the bank is recorded for men (or for women), the named citizens of that sex WHO HAVE THE RECORDED VOICE (above) stop using Half-Life 2's citizen voice** wherever the gamemode chooses the sound: street chatter between citizens, the talk window, protests and nervous lines when stopped, panic, greetings, cries, an advice line that is not recorded, and under words the model wrote. There they are silent, and any words still show. Their recorded lines are their only voice (`LC.OwnVoice`).
- **An unrecorded line of the bank is words only,** never Half-Life 2's voice in its place.
- **Unnamed citizens keep Half-Life 2's voice** for everything, as before, and never use the bank.
- Not covered: sounds the game engine makes by itself (pain grunts, its own reactions to being pushed or shot at).

## Where they are heard

- **Free talk.** With `lc_brain_lines` 1 (the default) the model is shown the bank for the person spoken to and told to pick the line that says what they would say, even roughly, with an opener if it adds something. Only when nothing comes close does it write words of its own (text only; an unnamed-voice "answer" sound under them until the bank is recorded, nothing after). `lc_brain_lines` 2: recorded lines only, never words of its own (everything said is voiced; "I wouldn't know anything about that." when nothing fits). `lc_brain_lines` 0: the bank is left out, as before.
- **The director's approach.** The citizen who walks up to a player opens with a recorded line (warnings, tips, asks, greetings, how they are, the Resistance) when one fits.
- **The minds' breaks.** The person says their line as it happens: the tantrum's shout, the accusation and the accused's answer, the plea under the stick, the unit's "You saw nothing." The `**` scene line in chat is unchanged.
- The bank adds about 1,000 tokens to each free talk request (the instructions are the same every time, so the service can reuse them cheaply). At the small model's price that is about a hundredth of a cent a line.

## Heard without the director (asked for 12 November)
The owner, 12 November: "can we wire up all these voices now please? make the triggers?" (no director key for now). `sv_livingcity_voicecues.lua` (`LC.Cue`) says the lines where the game already knows what is happening. **All 79 have a moment.** `lc_voice_cues` (1) turns it off; `lc_voice_approach` (300) is the seconds between walk-ups to the same player (0: never); `lc_voice_cue_words` (1) shows the words of a line said to you in chat.
- **Who speaks.** Where Half-Life 2's voice already plays for everyone (street chatter, the talk window, being stopped), only named citizens with the recorded voice say a line; the rest go on as before. Where nothing played before (what they see, chat, being hurt, walk-ups), every named citizen speaks: Half-Life 2's own line in place of the recorded one (`LC.HL2Instead`), or nothing where it has nothing like it. A person says at most one line every 6 seconds unless the moment calls for it.
- **The talk window:** hello by how they feel about you (warm, plain, guarded, cold; "No trouble here, officer." to a unit); Chat: how they are (`LC.CueState`, from hunger, rest, company, stress and mood), the Combine or the Resistance by who they are (`LC.CueTopic`), "Honestly? It's as bad as it looks." to a friend, "I've heard things." before a rumour, "There are people." before a safe house hint, "I don't want any trouble." when afraid; thanks or a big thanks for food and medicine, a refused gift, a leaflet denied or welcomed, a pickpocket caught ("Hey. There's no need for that."); yes, yes for you, maybe, not now, no, no for good, or "leave me out of it" to the Resistance's lookout offer (`LC.CueRecruit`); goodbye when you walk more than a few steps off within 90 seconds. **For those with the recorded voice the window quotes what was heard** (narration kept, the words in quotes are the line's).
- **The street:** two citizens chatting say real lines, an opener and an answer that fits who answers (`LC.CueAnswer`: the loyal warn against hatred, the bold and disloyal disagree with loyalty, the hopeful answer despair); stopped or frisked by a unit; "Stop! Please, I didn't do anything!" at an arrest; "You should go. Now." or "Oh God. Oh God, no." in a panic or under gunfire; a friend found in the seek break is greeted warmly; fear of someone who hurt them, warmth to a friend walking by.
- **What they see** (the `LivingCityThought` hook from `Psy.Think`, a player within 800 units, once a minute for each kind): a beating, a friend beaten, a death, a friend dead, a friend taken ("They took my friend."), a poster defaced (the loyal warn, the disloyal approve), being stopped and searched.
- **Hurt by a player** (and still alive, once every 20 seconds): "I don't want any trouble." (the proud and bold: "Hey. There's no need for that."); by a unit: "I'm sorry. I didn't mean anything by it."
- **Chat near them** (only while the director has no key; with one, the model answers): the named citizen the player faces within speaking range (a whisper closer, a yell farther) answers hello, goodbye, how are you, a joke, an insult, a threat, an apology, the Resistance, the Combine (against or for), food, a smoke, help, questions and "will you" asks (`LC.CueReply`, words in `LC.CueWords`). The words show to everyone in chat range.
- **Walk-ups** (every 15 seconds a chance, for each player at most once every `lc_voice_approach` seconds, never in curfew or lockdown, never to a unit, never someone who fears them; a person walks up once every 15 minutes at most): wanted: "You should go. Now."; on the units' radar: "Someone's been asking about you."; a Resistance player near a unit: "You're being watched."; an informer near and they like you: "Watch who you talk to."; the city on red: "There's gonna be trouble tonight."; a sympathizer to a Resistance player; a kind friend gives you water or a ration ("Here. Take it.", once every 30 minutes); hungry: "You got anything to eat?"; craving: a smoke; at the end of their rope: "I need help."; lonely: "It's good to just talk to someone." (`LC.CueApproachLine`).
- **Openers** come before the lines they suit, about a third of the time (`LC.CueLeads`): "Look." before a refusal, "Well..." before maybe, "Please." before asking, "Keep your voice down." before the dangerous, "Listen." before a warning, "You." when stopping someone.
- Tests: VoiceCuesTests.

## Recording them

- **Folders:** a citizen's lines in `garrysmod/sound/livingcity/citizens/` (the folder the advice lines already use), a unit's in `garrysmod/sound/livingcity/units/` (new).
- **Names:** `say_dunno_male1.wav` and `say_dunno_female1.wav`; a unit's `unit_move1.wav`. More takes `...2`, `...3`: one is picked at random, which is the cheapest way to make the lines heard most (greetings, "I wouldn't know", yes and no) sound less repeated. `.wav`, `.mp3` or `.ogg`; **`.mp3` is worth it here** (some 170 short files are a few megabytes for players to download as MP3, some 30 as WAV).
- **Voices:** one man and one woman for every citizen, for now. Half-Life 2's citizens are clear, fairly light, well-spoken voices in their thirties, lively rather than gruff: the descriptions in `VOICE_SCRIPTS.md` aim there (rewritten 11 November, when the owner found the first set did not match). Pick two ElevenLabs voices that sound like they belong in the same city as Half-Life 2's citizens, since those are still heard where there is no recording. A unit: one clipped male voice, with a radio or vocoder effect over it if you can.
- **Direction:** short and flat. The openers should run on into the next line (no falling full stop). The breaks are the only loud ones.
- **After adding files:** FastDL sync, then a map change. **What is already on the server:** `lc_voice_missing` also writes `data/livingcity/voice_missing.txt`; `elevenlabs_batch.py --missing voice_missing.txt` then makes only the lines the server has no recording of. `lc_voice_missing` in the server console lists what is not there yet ("Named citizens' lines", "Units' lines").
- **Without a recording** the words show and nothing is said (a unit uses Half-Life 2's own clip where it has one): nothing waits on the recordings.
- **The radio sound of a unit** is an effect put on a clean recording afterwards: `bash _dev/tools/unit_radio.sh FOLDER_IN FOLDER_OUT` (needs `ffmpeg`), explained in `VOICE_SCRIPTS.md`.
- **`VOICE_SCRIPTS.md`** has every line as text to paste, with a direction in square brackets for Eleven v4 or v3 (kept in the bank as each line's third entry), voice descriptions for the citizen man and woman, the unit and the G-Man, the Administrator's announcements in her usual tone, and the G-Man's made-up lines.

## Half-Life 2's own lines, replaced one by one

The owner, 11 November: "We are going to slowly replace all the HL2 native voice lines with my custom generated ones, EXCEPT for Gman" (matching a generated voice to Half-Life 2's actors by description did not work, so the voices no longer have to match anyone: every line is to be in the owner's own voices in the end).

- **How it works:** a recording at `garrysmod/sound/livingcity/hl2/<the clip's own path>` is played in place of that Half-Life 2 clip, wherever it is played, by the gamemode or by the game itself. `sound/livingcity/hl2/vo/npc/male01/hi01.mp3` is heard instead of `sound/vo/npc/male01/hi01.wav`. There is no list to keep: the file being there is all of it, so they can be added a few at a time, and a clip with no recording plays as it always did. `.mp3`, `.wav` or `.ogg`.
- **Which clips:** the citizens (`vo/npc/male01/`, `vo/npc/female01/`), Civil Protection (`npc/metropolice/vo/`), Overwatch's soldiers (`npc/combine_soldier/vo/`) and Overwatch's own voice (`npc/overwatch/cityvoice/`, `radiovoice/`). **Never the G-Man's.** `lc_voice_replace` 0 turns it off; `lc_voice_replaced` in the server console counts the recordings it found. After adding files: FastDL sync, then a map change.
- **Making them:** (1) on the server, `lc_hl2_lines` writes `data/livingcity/hl2_lines.txt`: every one of those clips the server has, with its words where the game's caption file gives them. (2) Download that file. (3) On your PC: `python3 _dev/tools/elevenlabs_batch.py --hl2 hl2_lines.txt --man ID --woman ID --unit ID --soldier ID --overwatch ID --dry-run` (then without `--dry-run`; `--limit 5` for a first few). It says the words of each clip in your voice and saves it under the clip's own path in `voice_out/sound/livingcity/hl2/`. Units and soldiers are saved clean in `voice_out/radio_clean/` and the script prints the `unit_radio.sh` command that gives them their radio sound. (4) Upload `voice_out/sound/`.
- **With the one-voice rule:** a named citizen is never silenced on a clip that has been re-recorded (it is their voice now); only clips still in Half-Life 2's voice are held back, once the bank is recorded.
- **Not checked in the real game:** that the swap catches the lines the game plays by itself (it uses the game's `EntityEmitSound` hook, which should see them), and that the caption file reads as expected. Clips with no words in the list (grunts, noises) are left out: they stay Half-Life 2's. Civil Protection's radio chatter built from several short clips in a row is replaced clip by clip. Lips do not move on a re-recorded line.

## Changing the bank

The lines are the tables `LC.StreetLines` and `LC.UnitLines` at the top of `sv_livingcity_lines.lua`: an id, the words, and when it is said (the model reads all three). Add or reword a line there, run `python3 _dev/voice_lines.py`, and record it. Keep to the rules above, and keep it small: every line added is two more recordings and a longer list for the model to read.

**Not yet:** more than one voice for each sex (the file names would need a voice letter); lines for the named Resistance fighters, vortigaunts and the Administrator's guards; tuning which lines the model actually picks, from real `TALK` lines in the minds' log.

**The 12 November playtest (the owner: "fix all of it please").** **Mouths move:** anyone (not a player) playing a sound from `sound/livingcity/` is marked talking for the line's length (`LC.MarkTalking`, NW2 `lc_talk_from`/`lc_talk_until`); `cl_livingcity_lipsync.lua` works the jaw and lips of faces within 900 units, then puts the face back. Masked faces (metrocops, soldiers) have no jaw and are left alone. Half-Life 2's own clips keep the engine's lip sync.
