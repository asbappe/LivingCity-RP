# F1 and F2 menu audit (18 November)

Taken from the code itself (the client smoke test's menus, for 13 kinds of player), not from the docs. **Nothing has changed yet.** Each numbered change below waits for the owner's yes or no.

## What's there now (short)

**F1 is the same for everyone:** 1 What now? > (next step, Ways to get by, Places, "Keep it on screen"), 2 Hands up, 3 My papers, 4 Talk >, 5 My pockets (F3), 6 Out of character >, 7 Pose >, 8 Gesture >, 9 full menu. Whatever you're looking at takes slots 7 and 8. **F1 is in good shape.**

**F2 is where the trouble is:**

| You are | F2 now |
|---|---|
| Citizen, no job | 1 **Me** > (work, rations, home, standing, **More** > dreams, household, survival, *the state of the city*). Nothing else. |
| Citizen with a Union job | 1 Ask for an escort, 2 Me > (as above) |
| Civil Protection | 1 Voice lines, 2 Unit tools, 3 Kick, 4 HQ calls (radio), 5 Me > (*My shift*, *Bounties on the wanted*, where I stand, dreams, *the state of the city*) |
| Overwatch | 1 Me >. **Nothing else.** |
| Administrator | 1 Sociostability, 2 Broadcast, 3 Tablet, 4 Laws, 5 Tonight's dream, 6 Guards, 7 Staff (if staff), 8 Me > (where I stand, dreams, *the state of the city*, **Administrator** > *speech, amnesty, crackdown, extra rations*) |
| Resistance | 1 Clothes, 2 Black market, 3 Resistance >, 4 Squad orders (with a squad), 5 Find the way >, 6 Me > (where I stand, dreams, household, *the state of the city*) |
| Vortigaunt | 1 Reach out through the vortessence, 2 Me > |
| Stalker | 1 My work: the Stalker's Lot (F4) |
| Infested | nothing ("Nothing here for your side") |

## What's wrong

1. **"Me" has become the junk drawer.** Things got put there when F2 ran out of room, not because they're about you: the state of the city (news about the city), the Administrator's speech, amnesty, crackdown and rations (her main powers, three menus deep), a unit's shift (their current work), CP bounties.
2. **A citizen's F2 is one button that opens another menu.** With no job, F2 > 1 is the only thing there, so every citizen action takes an extra press.
3. **The overflow page is named by the computer.** When F2 has more than 8 entries, slot 8 becomes "More: (the first two names)...", and the citizen's own "More: survival, dreams, the city, household, business" is the same idea.
4. **Duplicates:** Talk > 7 and 8 (out of character nearby or everyone) repeat F1 > 6. The Resistance page has "Find the lab (mark it)", and Find the way has "Guide me to the nearest lab".
5. **Labels that are instructions:** "HQ calls: get your radio out, right click (backup, resupply, BOLO, 10-20)", "Unit tools (everything a unit has)", "Keep it on screen: new life and urgent (change)", "Me: where I stand, survival, dreams". Pose has "Stand: pose 1" and "Stand: pose 2".
6. **Overwatch has no F2 of their own:** no voice lines, no kick, nothing but Me.

## Proposed changes (yes or no to each)

Kept as you approved them: F1 > 2 Hands up and F1 > 6 Out of character; a unit's F2 1 Voice lines, 2 Unit tools, 3 Kick, 4 HQ calls; HQ calls only on the radio; the Resistance's clothes and black market first; the Administrator's sociostability first.

1. **The state of the city moves to F1 > What now?** It's news everyone can read, not something about you.
2. **A citizen's F2 drops the "Me" step.** Its lines go straight on F2: 1 My work, 2 My rations, 3 My home, 4 My standing, 5 Household, stall and debts >, 6 Dreams and survival >. Job extras (escort, ration break, body cart, foreman) take 7, and with more than one, 7 becomes "My job >".
3. **Everyone else's "Me" holds only what's about you:** Where I stand, Dreams and survival, and Household (Resistance only). Named just "Me".
4. **A unit's shift goes on F2 itself:** 5 My shift (or "Back on duty" when off duty), 6 Bounties on the wanted (rank 3 and up), 7 Me.
5. **The Administrator's powers come out of Me:** 1 Sociostability, 2 Speak to the city > (speech into the microphone, speech in writing, broadcast), 3 City orders > (amnesty, crackdown, extra rations, order the arrest of whoever she's looking at), 4 Tablet, 5 Laws, 6 Tonight's dream, 7 Guards, 8 Me. If she is also staff, Staff goes inside Me.
6. **Duplicates go:** Talk loses its two out-of-character lines (F1 > 6 has them); the Resistance page loses "Find the lab" (Find the way has it).
7. **Shorter names:** "HQ calls (radio)", "Unit tools", "What stays on screen", "Me", and the two standing poses named for what they look like.
8. **The overflow page is just "More..."** and should rarely appear once 2, 4 and 5 are done.
9. **Overwatch's F2: your call.** Should soldiers get voice lines, Kick and Unit tools like Civil Protection, or is "Me" alone right for them?

After the moves, every message that names a menu path ("F2 > Me (More) > My dreams" and about 40 others) is updated to match, and the tests that check the menus' order follow.
