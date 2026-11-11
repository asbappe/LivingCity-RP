# What named people say, recorded

Asked for by the owner, 11 November: "architect and design natural sounding lines so that we can pre record NPC lines and cover as much situational dialogs as possible with the least amount of lines". Code: `sv_livingcity_lines.lua` (the bank and playing it), used by `sv_livingcity_brain.lua` (free talk, the director) and `sv_livingcity_mindsact.lua` (breaks). Tests: LinesTests (26). The list to record: `VOICE_LINES.md`, sections 10 and 11. **The text to paste into ElevenLabs, with voice descriptions: `VOICE_SCRIPTS.md`.**

## The idea

Voicing every answer as it is written would cost money on every line, for ever. Instead there is a **small bank of lines recorded once**, and the hosted model **picks from it**: it is shown the bank and asked which line this person would say right now. A recorded line costs nothing to play, sounds the same every time, and is in the person's own voice.

**79 lines for a citizen (a man's take and a woman's of each: 158 recordings) and 17 for a unit, of which Half-Life 2 already has 8 (so 9 to record): 167 recordings.** With the directions for ElevenLabs they come to about 9,000 characters; with the Administrator's 36 announcements and the G-Man's 8 made-up lines, 211 files and about 13,000 characters, which `_dev/tools/elevenlabs_batch.py` makes in one run (`VOICE_SCRIPTS.md`). The wording is American (the owner, 11 November), to sit with the Half-Life 2 citizens still heard around them. With ElevenLabs that is a one-off of well under a dollar at the prices seen in November, or a few thousand of a plan's monthly characters.

## How so few lines cover so much

1. **Lines are written by what they do, not what they are about.** "I wouldn't know anything about that." answers any question about anything. "You should go. Now." fits a raid, a snitch, a unit coming, a fight starting. The bank is a set of moves: greet, part, agree, refuse, put off, not know, admit, thank, back down, take offence, warn, ask, give.
2. **Nothing specific is in them:** no names, jobs, places, times of day, events or items. Any named citizen can say any line, at any hour, on any map.
3. **The same few feelings throughout:** warm, plain, guarded, cold. Where the feeling changes the words there are two or three versions (four greetings, three goodbyes); where it does not there is one.
4. **Six openers** ("Listen.", "Look.", "Please.", "Keep your voice down.", "Well.", "You.") can be said before any other line. They turn 73 lines into several hundred that sound different: "Look. No. Sorry." is not "Please. No. Sorry."
5. **Who they are comes from which line is picked,** not from the words: the loyal say "The Administrator knows best. I believe that."; the frightened say "I don't know, and I don't want to know."; a sympathizer who trusts you says "There are people. That's all I'll say."

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

**Where Half-Life 2 already says it** (the owner, 11 November: "already exist in HL2"), a unit's line names Half-Life 2's own Civil Protection clip (`sound/npc/metropolice/vo/`: `citizen`, `movealong`, `affirmative`, `negative`, `finalwarning`, `nowgetoutofhere`, `lookingfortrouble`, `holditrightthere`), its words are the clip's words, and with no recording of yours that clip is played. **The clip names are from memory, not checked against the game's files:** the game looks for each and only uses one that is there, and `lc_voice_missing` lists any unit line left with neither. To settle it, `lc_hl2_lines` in the server console writes `data/livingcity/hl2_lines.txt`: every citizen and Civil Protection clip the server has, with its words where the game's caption file gives them. With that file the bank can be matched to real clips for certain (and more of it, perhaps, taken from Half-Life 2 instead of recorded).

## One voice for each named person

The owner, 11 November: a named citizen must not answer in a recorded voice and then say a Half-Life 2 line in another.

- **Once any line of the bank is recorded for men (or for women), the city's named citizens of that sex stop using Half-Life 2's citizen voice** wherever the gamemode chooses the sound: street chatter between citizens, the talk window, protests and nervous lines when stopped, panic, greetings, cries, an advice line that is not recorded, and under words the model wrote. There they are silent, and any words still show. Their recorded lines are their only voice (`LC.OwnVoice`).
- **An unrecorded line of the bank is words only,** never Half-Life 2's voice in its place.
- **Unnamed citizens keep Half-Life 2's voice** for everything, as before, and never use the bank.
- Not covered: sounds the game engine makes by itself (pain grunts, its own reactions to being pushed or shot at).

## Where they are heard

- **Free talk.** With `lc_brain_lines` 1 (the default) the model is shown the bank for the person spoken to and told to pick the line that says what they would say, even roughly, with an opener if it adds something. Only when nothing comes close does it write words of its own (text only; an unnamed-voice "answer" sound under them until the bank is recorded, nothing after). `lc_brain_lines` 2: recorded lines only, never words of its own (everything said is voiced; "I wouldn't know anything about that." when nothing fits). `lc_brain_lines` 0: the bank is left out, as before.
- **The director's approach.** The citizen who walks up to a player opens with a recorded line (warnings, tips, asks, greetings, how they are, the Resistance) when one fits.
- **The minds' breaks.** The person says their line as it happens: the tantrum's shout, the accusation and the accused's answer, the plea under the stick, the unit's "You saw nothing." The `**` scene line in chat is unchanged.
- The bank adds about 1,000 tokens to each free talk request (the instructions are the same every time, so the service can reuse them cheaply). At the small model's price that is about a hundredth of a cent a line.

## Recording them

- **Folders:** a citizen's lines in `garrysmod/sound/livingcity/citizens/` (the folder the advice lines already use), a unit's in `garrysmod/sound/livingcity/units/` (new).
- **Names:** `say_dunno_male1.wav` and `say_dunno_female1.wav`; a unit's `unit_move1.wav`. More takes `...2`, `...3`: one is picked at random, which is the cheapest way to make the lines heard most (greetings, "I wouldn't know", yes and no) sound less repeated. `.wav`, `.mp3` or `.ogg`; **`.mp3` is worth it here** (some 170 short files are a few megabytes for players to download as MP3, some 30 as WAV).
- **Voices:** one man and one woman for every citizen, for now. Half-Life 2's citizens are clear, fairly light, well-spoken voices in their thirties, lively rather than gruff: the descriptions in `VOICE_SCRIPTS.md` aim there (rewritten 11 November, when the owner found the first set did not match). Pick two ElevenLabs voices that sound like they belong in the same city as Half-Life 2's citizens, since those are still heard where there is no recording. A unit: one clipped male voice, with a radio or vocoder effect over it if you can.
- **Direction:** short and flat. The openers should run on into the next line (no falling full stop). The breaks are the only loud ones.
- **After adding files:** FastDL sync, then a map change. `lc_voice_missing` in the server console lists what is not there yet ("Named citizens' lines", "Units' lines").
- **Without a recording** the words show and nothing is said (a unit uses Half-Life 2's own clip where it has one): nothing waits on the recordings.
- **The radio sound of a unit** is an effect put on a clean recording afterwards: `bash _dev/tools/unit_radio.sh FOLDER_IN FOLDER_OUT` (needs `ffmpeg`), explained in `VOICE_SCRIPTS.md`.
- **`VOICE_SCRIPTS.md`** has every line as text to paste, with a direction in square brackets for Eleven v4 or v3 (kept in the bank as each line's third entry), voice descriptions for the citizen man and woman, the unit and the G-Man, the Administrator's announcements in her usual tone, and the G-Man's made-up lines.

## Changing the bank

The lines are the tables `LC.StreetLines` and `LC.UnitLines` at the top of `sv_livingcity_lines.lua`: an id, the words, and when it is said (the model reads all three). Add or reword a line there, run `python3 _dev/voice_lines.py`, and record it. Keep to the rules above, and keep it small: every line added is two more recordings and a longer list for the model to read.

**Not yet:** more than one voice for each sex (the file names would need a voice letter); lines for the named Resistance fighters, vortigaunts and the Administrator's guards; tuning which lines the model actually picks, from real `TALK` lines in the minds' log.
