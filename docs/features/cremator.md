# The Cremator

Asked for by the owner on 10 November: "for now they can just be an NPC that roams around burning bodies and if a rebel/enemy is nearby they can attack it". The Mortician job is unchanged. A player Cremator is not decided yet (`TODO.md`).

## What it needs

A Cremator model on the server, from the Workshop. The gamemode ships none. The owner chose:

- NPC model: Workshop item `2090972521`
- Playermodel: Workshop item `3329322225` (for a later player role; used for the NPC only if the first is missing)

Both go in the server's Workshop collection. Players who join download the one in use by themselves. With no model there are no Cremators and nothing else changes.

The model is found by itself: `lc_cremator_model` if set, then any NPC an addon lists with "cremator" in its name, a few likely paths, a search of `models/` for a `*cremator*.mdl`, and last a Cremator playermodel. Heads, gibs, arms and ragdolls are skipped.

## What it does

- `lc_cremators` of them (1; 0: none; 4 at most) walk the streets. One appears out of sight. One killed is replaced, out of sight, five minutes later.
- **Bodies:** a body that has lain `lc_cremator_grace` seconds (90), that nobody is hauling, has on a cart or has claimed: it walks over, turns its flame on it for five seconds, and the body is gone (a scorch mark stays). Not while the Administrator has stood the morticians down, and never on Resistance ground. Players and Morticians have those 90 seconds, and any time before it arrives, to search or haul the body first.
- **Enemies** (seen within 520 units): whoever the units would shoot (a gun in hand, hurt someone lately, hunted), a zombie player, one of the Resistance's people out in the open (not one acting casual), headcrabs and zombies, and anyone who attacks it for 90 seconds after. It walks at them and burns them from 280 units: they catch fire and lose about 16 health a second. It gives up past 1000 units.
- **Never enemies unless they attack it:** Civil Protection, the Administration, an admin holding the editor or in noclip, citizens doing no harm.
- 400 health. Fire does nothing to it. A player (not Combine) who attacks it brings the units within 1200 units.
- The city's own people take no notice of it.
- Its name tag reads "Cremator", with what it is doing.

## How it is built

Nobody could check which animations the Workshop model has, so the walking is done by an unseen `npc_stalker` (slow, and already used by the zone stalkers) and the Cremator seen is a `prop_dynamic` carried on it. It plays whichever of the model's own sequences sound like standing, walking and firing: likely names first, then the model's list scored by name. The model and the three animations used are in the debug report (People) and are printed by `lc_cremator_spawn`.

The flame is green, as the Immolator's was, drawn on the client from the model's muzzle attachment if it has one.

## Settings and commands

- `lc_cremators` (1), `lc_cremator_grace` (90), `lc_cremator_model` (empty: found by itself).
- `lc_cremator_spawn` (admins, console): one where you are looking, and a line saying which model and animations were found. An extra for checking; the Cremators need no command. In the console it also lists every Cremator model found and every animation the model has (lines starting `[cremator]`), for sending back when it looks wrong.

## Code

`sv_livingcity_cremator.lua` (`LC.CrematorModel`, `LC.CrematorModelsFound`, `LC.CrematorSequence`, `LC.SpawnCremator`, `LC.CrematorEnemy`, `LC.CrematorBody`, `LC.CrematorsStaff`/`Think`/`Tick`, `LC.CrematorDie`, `LC.CrematorSummary`; hooks `LivingCityCremated` with the walker as who, `LivingCityCrematorKilled`), `cl_livingcity_cremator.lua` (the flame). Tests: CrematorTests.
