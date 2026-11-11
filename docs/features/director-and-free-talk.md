# The director and free talk (a hosted model)

Asked for by the owner, 10 November: "is it possible to run some sort of localized LLM on the server that can handle advanced npc logic to enhance player encounters and dynamically orchestrate NPCs and interactions?", then "I don't have a pc capable of that, so a small hosted fee is fine". Code: `sv_livingcity_brain.lua`. Tests: BrainTests (30).

**What it is.** A language model on someone else's computers, asked over the web by the game server. It takes a second or several to answer, so it never walks, fights or reacts: the city's own code does all of that, as before. The model is a slow brain on top, and it only ever picks from a short list of things the game can already do. **Nothing runs without a key, and if the service is slow, down or says no, nothing happens: the city goes on as it always has.**

## Setting it up (once)

1. Make an account at the Claude Console (`platform.claude.com`), add a few dollars of credit, and create an API key (it starts `sk-ant-`).
2. In game, as a superadmin, take out the Living City editor tool. In its panel, under "The director and free talk": paste the key into **Key**, press **Save the key**, then **Test the connection**. A notice says "The hosted model answered" or what went wrong.
3. That is all. The key is kept on the server in `data/livingcity/brain_key.txt`. It is never sent to players, never printed in the debug report, and the box is emptied after saving. Saving with the box empty clears it.

If the test says it could not reach the service, the game host is blocking outgoing web requests: ask the host to allow `api.anthropic.com`.

**Cost.** The default model is the small, cheap one (`lc_brain_model`, `claude-haiku-5-5`). The director's look is about 1000 words in and a few lines out, every 3 minutes while players are on; a spoken answer is smaller. `lc_brain_daily` (1500) is the most requests in a day, whatever happens. The debug report says how many were made and how many tokens went in and out, to check against the bill.

## The director

Every `lc_director_minutes` (3), with at least one living player on, it is shown a short account of the city: the time of day, the event running, sociostability, the state of the city, unrest; each player's character name, side, place, wanted level and whether they are in a fight; the ten named people nearest the players (role, secrets, what they are doing, how they feel and why, their traits, what they think of that player); the last things the minds' log wrote down; and its own last decisions. It picks one:

- **none:** nothing this time (it is told to choose this often).
- **event:** starts rations, a sweep, a curfew, a raid or a supply convoy. Only when no event is running, and at most once in 15 minutes.
- **break:** a named person on the streets does one of the things in `city-minds.md` (a citizen: tantrum, despair, defy, inform, seek, hoard, accuse, sabotage, binge, share, steady; a unit: brutal, drink, leak). Needs `lc_minds` and `lc_minds_act` on.
- **approach:** a named citizen walks up to a player and says one line the model wrote (140 characters at most), heard by everyone in chat range.

The same person is moved at most once in 10 minutes. A name it made up, a kind that does not fit the person, or an event off the list is refused and written down as "wanted ..., but ...". `lc_director` 2 does it, 1 only writes down what it would have done, 0 is off. Every decision goes in the minds' log as a `DIRECTOR` line (`data/livingcity/minds/`) and the last five are in the debug report.

## Free talk

Say something in character (ordinary chat, `/y` or `/w`) while looking at a named citizen or unit within 220 units. They turn to you, and a moment later answer out loud in their own name ("Olga Volkov says: ..."), heard by everyone in chat range. The model is told who they are (name, job, traits), how they feel right now and why, their secrets (sympathizer, informant), what they think of you, and the last few lines between you (kept for ten minutes). The answer comes with:

- **a feeling** from -2 to 2: how what you said changed what they think of you. It is remembered the way the talk window's choices are (`LC.Remember`), and in their mind.
- **an act:** none; **walk away**; or **report**: an informant sets off to give a unit your name, and a unit names you on the spot (outlined for Civil Protection for 60 seconds, no crime on the record).

One answered line per player every 4 seconds, one answer at a time per person. `/me`, `/it` and out-of-character chat are not sent. The talk window (E) works as it always did.

**What leaves the server:** what the player said, their character's name and description, and the account of the city above. Never a Steam name or id. Players should be told that what they say to named people is read by an outside service.

## Settings (editor panel, under the minds)

`lc_brain` (1; nothing without a key), `lc_brain_talk` (1), `lc_director` (2: acts; 1: writes down only; 0: off), `lc_director_minutes` (3), `lc_brain_daily` (1500; 0: no limit), `lc_brain_model` (console only). Console extras for the server: `lc_brain_key <key>`, `lc_brain_test`.

## Safeguards

- The model's answer must fit a fixed form (the service enforces it), and every field is checked again by the game before anything is done.
- A player cannot talk it into anything: what they say can only come back as a spoken line, a feeling from -2 to 2, and one of three acts.
- What it writes is made one clean line (no line breaks, no long dashes, cut to length) before anyone sees it.
- At most 20 requests a minute and 4 waiting at once; after an error it waits (30 seconds to 5 minutes) before asking again.
