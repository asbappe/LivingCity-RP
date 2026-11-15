# Playtest card

About twenty minutes on the server. Only things a person has to judge are here: how it looks, sounds and feels. Everything a test can prove is proved by the tests and by the robot players, and is not asked of you.

Tick what works, write a word under what does not. What is not on this card waits in `PLAYTEST_ARCHIVE.md` (the backlog, about 70 one-line items).

## This card (15 November 2026: your 14 November night notes, fixed, please try)

- [ ] **One status box:** upper left, as a rebel in citizen clothes with a radio. Is it one box, each fact once, easy to read?
  Notes:
- [ ] **People stay:** note three named citizens in the morning. Are they still about later, going into their own block and coming back out? Does the street feel lived in, not emptied? (The debug report's "people:" line says how many are out, at home, dead.)
  Notes:
- [ ] **Rations:** press Fill the city's ration stores in the editor panel (Survival and economy) once. Does a dispenser give you a ration? An hour or two later, are the stores still well above empty, and was there no ration announcement after 18:00? Type `lc_stock` in the console and send the two lines it prints.
  Notes:
- [ ] **Armed among soldiers:** as a rebel with a gun out, beside rebel fighters against soldiers. Are you only ever shot at, never cuffed? Do the soldiers shoot the rebel fighters too?
  Notes:
- [ ] **The struggle:** gun away, let a unit take you. Does the struggle bar come up, and can you break free by pressing E fast?
  Notes:
- [ ] **Out of custody:** mid-march and in a cell, F4 > Admin tools > Handy > Out of custody. Free on the spot?
  Notes:
- [ ] **Ranks:** set yourself Lieutenant from the F4 admin tools. Does the career page say Lieutenant, does the cage open, is Hacker offered?
  Notes:
- [ ] **The cage:** with it clipped into the wall as you place it, do prisoners stand inside it, none in or behind the wall? Any rebel inside it?
  Notes:
- [ ] **The lab and cuffs:** are the vest and the bypass charge on the scientist's list at a fair price? F2 on a citizen with cuffs in your pockets: "Cuff them", and they walk to the cage?
  Notes:
- [ ] **A dream by itself:** sleep at 21:30 as a rebel on rebel ground. Does a dream come within about half a minute? If not, send the debug report (its "dreams:" line says why).
  Notes:
- [ ] **The Administrator, untouchable:** punch a unit, then order a kill while standing in the line of fire. No reaction, no damage, every guard holding a rifle?
  Notes:
- [ ] **The Administrator's tablet and camera:** does the tablet open its own window (not the C menu)? Does the recording scanner look at your face? Order a parade: do you see it?
  Notes:
- [ ] **The vortigaunt's broom:** in the claws, head on the floor, while it walks and sweeps? (Head in its hands: `lc_vort_broom_flip 1`.)
  Notes:
- [ ] **The baton's glow:** at the tip, on your side, the right size?
  Notes:
- [ ] **The editor's list:** can you find things now? (Old and new names: `docs/dev/editor-menu-names.md`.)
  Notes:
- [ ] **The errors file:** last thing, F4 > Factions > Admin: errors (N). Send the server's errors.txt.
  Notes:

## For whoever adds to this file

- Keep the card to about 15 items, one short line each, in the order of one walk through a session.
- Put here only what a person must judge. What a test can prove gets a test instead.
- When the card is full, a new item goes at the end of `PLAYTEST_ARCHIVE.md` with the tag `[needs a person: why]`.
