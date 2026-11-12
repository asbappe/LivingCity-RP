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
- Held for `lc_rebel_hold` seconds (300), then let out and uncuffed. From the cage's menu a Fighter or above can pat them down, send them to the chair, or let them go sooner. The chair, and executions, are below.
- With the gate shut there is no walking out (anyone who slips through the fence is put back). With free hands and a lockpick: F1 > **Pick the cage's padlock**. Seen, the pick is taken; otherwise the same odds as the cuffs. The gate swings open and they can walk out.
- Dragged out by the arm, killed, or locked up by Civil Protection instead: off the cage's list.
- It goes in the chronicle (kind `caged`), as a caged citizen does.

## The quick menu for situations

`LC_CL.OpenSituation(page)` shows a list where F1's is, picked with the number keys, with what was just said written under it. It stays while the situation does (near the chair, near the cage, the prisoner cuffed and in reach) and for two minutes at most without a key. **The interrogation chair and the holding cage use it now, in place of their mouse windows** (the same choices; the cage lists each prisoner, and a second page has what to do with them).

## The evidence locker (12 November, later)

The owner: "can we make this an entity in the editor that an escaped prisoner, a thief, or a corrupt CP unit, can search and take from?"

- **Editor:** "Fixture: evidence locker" (`lc_evidencelocker`, kind `evidlocker`, in the "Civil Protection and the Combine" folder). Setting `lc_evidence_locker` (1).
- **What is in it:** the evidence stock that already existed (what searches and raids confiscate, burned in public now and then: `sv_livingcity_evidence.lua`). New into that stock: what a **player unit's patdown** bags, what a city unit takes off a **player** it walks in, and the guns and radios kept back on release. It is kept in memory: a restart empties it.
- **E on it** brings up a quick menu. A unit opens it with their own key and can take anything: no alarm, but another unit player who is looking sees it. Anyone else: **pick the lock** (8 seconds; seen by a unit, wanted; the usual odds) or **pry it with a crowbar** (5 seconds, loud, always wanted). Once open it stays open to that person for 90 seconds; taking something while a unit can see makes you wanted.
- The newest eight kinds of thing are listed; one pick takes that whole stack (or one gun).

## Citizens and rebels in custody

- Each one taken (cuffed by Civil Protection, or put in the Resistance's cage) may be hiding something, worked out once: a thing a search would find, and now and then a **lockpick** (about one in eight; three in ten for a rebel).
- **Pat them down:** the quick menu that comes with cuffing them, F1 while looking at them, or the cage's menu. A unit's finds go to the evidence locker; a rebel keeps the lockpick.
- A **city unit** searches whoever it arrests, unless it is in a firefight.
- **Nobody searched them and they had a pick:** after 75 seconds in a cell or the cage they are out. Civil Protection's radio hears "a prisoner has picked a cell door"; at the cage the padlock is found hanging open. Either way it is in the chronicle (kind `escaped`).

## A player in the interrogation chair

- From the cage's menu, a Fighter or above sends a held player **to the interrogation chair** (a free one near the cage). They are sat in it, cuffed, the lamp in their eyes.
- The one asking has the chair's menu. **Each question goes to the prisoner as a quick menu: Tell the truth, Lie, Say nothing** (20 seconds, then silence). The asker hears an answer and is never told which it was; a lie is seen through about one time in three, more after blows.
- **The truth is real:** it is what the chronicle holds that this player did, or saw. With nothing there: "There's nothing. I swear it."
- **Hit them:** 12 health a blow, never below 10, six at most.
- Then **back to the cage** (their time there carries on) or **let go** (uncuffed). Left alone for 20 seconds, or after four minutes: back to the cage.

## The Resistance's rules, mood and the leader's clipboard

The owner: "a whole system of 'Resistance Atmosphere' ... not announced on loudspeakers ... the resistance boards can hold this info", "the leader of the resistance can set the mood or even rules via their own 'tablet' (aka a clipboard they have as a SWEP with paper and checkboxes on it)". Code: `sv_livingcity_rebelrule.lua`, `weapon_lc_rebelclip`; setting `lc_rebel_rules` (1); tests `RebelRuleTests`.

- **The leader** is the highest-ranked Resistance player on (a Fighter or above). They are given **the cell's clipboard**; left click, or F2 > Resistance > "The cell's rules", shows the paper as a quick menu of boxes ticked with the number keys. Anyone else in the Resistance can read it, not change it.
- **The boxes:** hands may be laid on prisoners (ticked at first); prisoners may be executed, with leave (not ticked); sympathizers who turn are fair game (not ticked); a priority (lie low, attack the Combine, spread pamphlets, put up propaganda); the mood (as events make it, or set to calm, wary, desperate or vengeful). **The last rules stand when the leader is away** (`data/livingcity/rebel_rules.json`).
- **The mood** is one word for the cell: calm, wary, desperate or vengeful. It comes from what happens to them (a fighter killed, one of theirs arrested, an informer found in the chair, a prisoner escaping) and fades with time. **It is never announced and never shown as a number: it is the first line of the Resistance's notice board**, with the rules under it.
- **What it changes by itself:** the cell's own questioning hits at most twice when calm and up to five times when vengeful, and not at all when the leader has forbidden it (they ask twice, quietly); prisoners are held half as long when desperate and twice as long when vengeful; the cell's own answer to a request for leave follows the rules and the mood.
- **Against the rules:** a player who hits or kills a prisoner when the clipboard forbids it is not stopped. It is written down, and the board carries it.
- The priority is written on the board and does nothing else yet.

## Kind options in the chair (citizens)

The chair's menu has **Be kind**: talk with no threats (works slowly on most, never on the proud), give them food or water from your pockets (once), and **ask them to join us** (once; likelier the better they were treated, less likely after blows). One who joins is a sympathizer; one who was beaten first is sometimes only saying so.

## Executions

The owner: "a Lieutenant or above can give the order and do it themselves, but the fighter is supposed to request permission to execute ... executing so without approval is where the option comes in to punish them, expel them, stand by them, etc, by the highest ranking Resistance member"; "if it's a proper execution, then yeah the character dies", otherwise "a close call"; "a dice roll might be best".

- **Where:** the cage's menu (each prisoner's page) and the chair's menu have **Execution**. Only on someone the Resistance holds.
- **A Lieutenant or above:** "Execute them".
- **A Fighter:** "Ask leave to execute them" (it goes to every Lieutenant and above who is on, as a quick menu: give leave or refuse; with none on, the cell answers in a few seconds by its rules and mood), then "Execute them (leave is given)". Or **"Execute them without leave"**.
- **A player prisoner:** with leave or by a Lieutenant, it is **the character's real death**. Without leave, the dice: one time in three the same, otherwise an ordinary death (a close call, like any other).
- **Without leave, someone answers for it:** the highest-ranked Resistance member gets a quick menu: **expel them** (out of the Resistance, and wanted), **break them in rank**, **order their execution** (any Fighter or above may then do it once they hold them), or **stand by them**. With nobody to answer, the cell does after half a minute. Leave asked, refused, and done anyway is recorded as such.
- All of it goes in the chronicle (`executed`, `judged`) and on the Resistance's board.

## Not built

- How the people take it (the Resistance's standing among citizens, pamphlets and posters from it), the body, exchanges, and the Administrator's answer (`TODO.md`).
- The clipboard's "general sentiment as a sentence" shows the cell's mood for now; the people's sentiment is not built.
- Jobs taken at the board instead of F4 (needs the owner's yes).
- The priority doing something, and the mood changing how readily the cell's fighters fight.
