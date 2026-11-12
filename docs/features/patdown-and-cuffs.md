# The patdown, lockpicks on cuffs, and players in the Resistance's cage (12 November)

The owner: "we need a patdown when being brought into prison, both CP and resistance, or at least the option of one ... if it's a firefight or dangerous then the arresting party can choose to skip it, and maybe nobody remembers to do it later, meaning lockpicks and other useful items could be snuck into prison", "prisoners should be able to 'work at cuffs' ... and if they happen to have a lockpick can try to use it on the cuffs, and ... on the prison cell door", and on the menus: "I Really want to not use a mouse click and UI element with buttons ... a special hidden menu that appears for these situations similar to the F1 and F2 quick menus".

Code: `sv_livingcity_patdown.lua`, `cl_livingcity_patdown.lua`; the quick menu in `cl_livingcity_quick.lua` (`LC_CL.OpenSituation`); tests `PatdownTests`. Setting: `lc_patdown` (1).

## What an arrest took before, and still takes when nobody pats the prisoner down

- **Being cuffed** takes what is in the hands (every weapon carried) and nothing from the pockets. Uncuffed, the weapons come back.
- **Being locked in a cell** takes nothing more. A lockpick in the pockets stays there, and already opens the cell door (look at the door, F1 > Pick the lock).
- **On release** from the Combine's cells, guns and radios in the pockets stay in the evidence locker.

## The patdown

- **Who:** a Civil Protection unit, a Resistance Fighter or above, or whoever put the cuffs on. Only on a **cuffed player**, within arm's reach, once per cuffing.
- **How:** cuffing a player brings up a quick menu by itself (number keys, like F1 and F2; no mouse): **1 Pat them down, 2 No time: walk them along, 3 Take the cuffs off**, 0 closes it. It goes away when the prisoner is out of reach. Skipped, it can still be done later for as long as they are cuffed: look at them, F1 > "Pat (name) down". In the Resistance's cage it is on the cage's menu too.
- **What it does:** four seconds beside them, then every **weapon, radio and tool** (lockpicks, bypass charges, keycards) in their pockets is taken, and what was taken from their hands at cuffing is not handed back. A unit bags it as evidence (gone); anyone else keeps it.
- **City units:** a unit that walks a prisoner to the cells pats them down first, **unless it is in a firefight** (then: "No time to search you"). The transport that takes a prisoner when no unit is free does not search.
- `lc_patdown 0`: no patdown is offered and city units don't do one (an arrest is exactly as it was).

## A lockpick on the cuffs

- F1 > **Pick the cuffs (needs a lockpick)**, while cuffed and not being held by the arm. Ten seconds (working at the cuffs without one is still thirty).
- A captor who can see (a unit player, a Fighter or above, or whoever cuffed them, within 450 units with a clear line) **takes the pick**.
- Unseen: about two tries in three open the cuffs; a failed try snaps the pick four times in ten. A pick that survives can go on to the cell door or the cage's padlock (it wears out as lockpicks always did, `lc_wear_uses`).

## Players in the Resistance's cage

- A **Fighter or above dragging a cuffed player** to within reach of a holding cage with room puts them in it (as a unit's drag to a cell does). They count towards the cage's room (`lc_rebel_cage_room`).
- Held for `lc_rebel_hold` seconds (300), then let out and uncuffed. From the cage's menu a Fighter or above can pat them down or let them go sooner. **The interrogation chair is not for player prisoners yet.**
- With the gate shut there is no walking out (anyone who slips through the fence is put back). With free hands and a lockpick: F1 > **Pick the cage's padlock**. Seen, the pick is taken; otherwise the same odds as the cuffs. The gate swings open and they can walk out.
- Dragged out by the arm, killed, or locked up by Civil Protection instead: off the cage's list.
- It goes in the chronicle (kind `caged`), as a caged citizen does.

## The quick menu for situations

`LC_CL.OpenSituation(page)` shows a list where F1's is, picked with the number keys, with what was just said written under it. It stays while the situation does (near the chair, near the cage, the prisoner cuffed and in reach) and for two minutes at most without a key. **The interrogation chair and the holding cage use it now, in place of their mouse windows** (the same choices; the cage lists each prisoner, and a second page has what to do with them).

## Not built

- Citizens and units (NPCs) are not patted down, so nothing is hidden on them yet.
- The chair, and executions, for player prisoners (`TODO.md`).
