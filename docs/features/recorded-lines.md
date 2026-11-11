# What named people say, recorded

Asked for by the owner, 11 November: "architect and design natural sounding lines so that we can pre record NPC lines and cover as much situational dialogs as possible with the least amount of lines". Code: `sv_livingcity_lines.lua` (the bank and playing it), used by `sv_livingcity_brain.lua` (free talk, the director) and `sv_livingcity_mindsact.lua` (breaks). Tests: LinesTests (18). The list to record: `VOICE_LINES.md`, sections 10 and 11.

## The idea

Voicing every answer as it is written would cost money on every line, for ever. Instead there is a **small bank of lines recorded once**, and the hosted model **picks from it**: it is shown the bank and asked which line this person would say right now. A recorded line costs nothing to play, sounds the same every time, and is in the person's own voice.

**80 lines for a citizen (a man's take and a woman's of each: 160 recordings) and 17 for a unit (one voice): 177 recordings, about 5,500 characters in all.** With ElevenLabs that is a one-off of well under a dollar at the prices seen in November, or a few thousand of a plan's monthly characters.

## How so few lines cover so much

1. **Lines are written by what they do, not what they are about.** "I wouldn't know anything about that." answers any question about anything. "You should go. Now." fits a raid, a snitch, a unit coming, a fight starting. The bank is a set of moves: greet, part, agree, refuse, put off, not know, admit, thank, back down, take offence, warn, ask, give.
2. **Nothing specific is in them:** no names, jobs, places, times of day, events or items. Any named citizen can say any line, at any hour, on any map.
3. **The same few feelings throughout:** warm, plain, guarded, cold. Where the feeling changes the words there are two or three versions (four greetings, three goodbyes); where it does not there is one.
4. **Six openers** ("Listen.", "Look.", "Please.", "Keep your voice down.", "Well.", "You.") can be said before any other line. They turn 74 lines into several hundred that sound different: "Look. No. Sorry." is not "Please. No. Sorry."
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

## Where they are heard

- **Free talk.** With `lc_brain_lines` 1 (the default) the model is shown the bank for the person spoken to and told to pick the line that says what they would say, even roughly, with an opener if it adds something. Only when nothing comes close does it write words of its own (which are text only, with Half-Life 2's citizen voice under them). `lc_brain_lines` 2: recorded lines only, never words of its own (everything said is voiced; "I wouldn't know anything about that." when nothing fits). `lc_brain_lines` 0: the bank is left out, as before.
- **The director's approach.** The citizen who walks up to a player opens with a recorded line (warnings, tips, asks, greetings, how they are, the Resistance) when one fits.
- **The minds' breaks.** The person says their line as it happens: the tantrum's shout, the accusation and the accused's answer, the plea under the stick, the unit's "You saw nothing." The `**` scene line in chat is unchanged.
- The bank adds about 1,000 tokens to each free talk request (the instructions are the same every time, so the service can reuse them cheaply). At the small model's price that is about a hundredth of a cent a line.

## Recording them

- **Folders:** a citizen's lines in `garrysmod/sound/livingcity/citizens/` (the folder the advice lines already use), a unit's in `garrysmod/sound/livingcity/units/` (new).
- **Names:** `say_dunno_male1.wav` and `say_dunno_female1.wav`; a unit's `unit_move1.wav`. More takes `...2`, `...3`: one is picked at random, which is the cheapest way to make the lines heard most (greetings, "I wouldn't know", yes and no) sound less repeated. `.wav`, `.mp3` or `.ogg`; **`.mp3` is worth it here** (177 short files are a few megabytes for players to download as MP3, some 30 as WAV).
- **Voices:** one man and one woman for every citizen, for now: ordinary, tired, speaking low, never acting. Pick two ElevenLabs voices that sound like they belong in the same city as Half-Life 2's citizens, since those are still heard where there is no recording. A unit: one clipped male voice, with a radio or vocoder effect over it if you can.
- **Direction:** short and flat. The openers should run on into the next line (no falling full stop). The breaks are the only loud ones.
- **After adding files:** FastDL sync, then a map change. `lc_voice_missing` in the server console lists what is not there yet ("Named citizens' lines", "Units' lines").
- **Without a recording** a citizen speaks with Half-Life 2's own citizen voice, a unit is silent, and the words still show: nothing waits on the recordings.

## Changing the bank

The lines are the tables `LC.StreetLines` and `LC.UnitLines` at the top of `sv_livingcity_lines.lua`: an id, the words, and when it is said (the model reads all three). Add or reword a line there, run `python3 _dev/voice_lines.py`, and record it. Keep to the rules above, and keep it small: every line added is two more recordings and a longer list for the model to read.

**Not yet:** more than one voice for each sex (the file names would need a voice letter); lines for the named Resistance fighters, vortigaunts and the Administrator's guards; tuning which lines the model actually picks, from real `TALK` lines in the minds' log.
