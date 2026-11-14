# Jobs and quests (F4), and story chains

**Finding the objective.** The tracker on the right shows a compass for whatever you're after: a pointer relative to where you're facing, the distance in meters, a heading (ahead, behind left, ...) and whether it's on your level, a floor or more **UP**, or **DOWN**. It works even when the target is far enough away that the game isn't drawing it. Quests never send you to the infestation or onto Combine ground. Deliveries are made to **people**: the mail comes from the postal clerk and goes to named residents, Mrs. Kleiner hands you her parcel herself, luggage goes back to its owner, uniforms go to the unit at the checkpoint. Ration crates come from the truck driver and go to the dispenser attendant, and the Resistance's supply runs, the weapons ring and the proof-of-nerve parcel are handed over by and to contacts. Each person waits at a marked spot; walk up and press E.

Each faction has a board of radiant jobs built from your actual map: Directives, Protocols, Agenda, Operations, Assignments, Urges. Many have **choices with d20 checks** (Authority, Empathy, Guile, Nerve), and your choices build three traits that stick: **Loyalty, Sympathy, Corruption**.

Built for crowded servers: no job ever targets a player, boards are finite and scale with faction size, violent jobs are capped city-wide, and people can squad up.

**Directives for what's happening now.** The city's events bring their own jobs, posted two minutes before an event starts (units are briefed early even for a surprise sweep or raid) and as it begins, shown only while it's on, and withdrawn when it ends (whoever was already working one is paid; whoever hadn't started isn't held to it). Units get **Ration line supervision** (rations), **Civil status inspections** (sweeps: pat-downs), **Housing block inspection** (block raids: breach the door, get everyone down, search the place), **Curfew enforcement** and **Lockdown: hold the perimeter**; the Resistance get **Warn the block** (raids) and **Run supplies under curfew** (curfew and lockdown). When the infestation spreads or the Resistance take ground, **Containment** or **Retake the block** goes up at once for that patch, and every unit is told. These, and the chases (Apprehend, Disturbance), are squad jobs: up to 4 to 8 people work one together (the rest of the board takes `lc_quest_squad`, 3). Take it from the board and the others join you from theirs.

**The night shift** (Civil Protection and Overwatch, the owner, 8 November): most nights (`lc_nightshift_chance`, 0.85) the board has a **Night shift** directive from dusk, always offered first while it's up: walk six patrol stops through the night. Taking it excuses the unit from lights out that night, and a CP Commissary issues them one stimulant shot (`civil-protection-tools.md`).

## Story chains

Personal stories that unlock from what you've done, appear at the top of your board marked **Your Story**, and branch on your choices:

| Story | Who it finds |
|---|---|
| Internal Affairs | Cops who take bribes |
| The Man Inside | Kind, clean cops. Defect, or stay in uniform as a double agent with secret **Inside Work**, until **Suspicion** brings a **Mole Hunt** (caught: wanted, no surrender, Resistance for good; see the Resistance Insider below) |
| The Missing Unit | Experienced cops. Three different truths |
| The Overwatch Candidate | Division Leaders. Accept the conditioning and the Overwatch ranks open, or keep your name and go no higher |
| The Pamphleteer | Kind citizens. Can end with you joining the Resistance |
| The Informant | Loyal citizens. Includes tailing a neighbor: a suspicion meter fills while he can see you (faster the closer you are and when you run, slower crouched) and drains when you get out of sight, so stepping round a corner into view gives you time to duck back |
| Father Grigori's Flock | The chaplain. A secret mass, and a traitor among the faithful |

Admins can start any chain directly: `lcq_startchain <ia|inside|missing|candidate|pamphleteer|informant|flock> [player]`. `lcq_story <name>` shows someone's traits, counters and progress; `lcq_resetstory <name>` starts them over.

**Changes from the 7 November playtest.** A story quest ("Your story") waits until the character has done 2 to 4 ordinary jobs (drawn once and saved; existing characters too, from now); Union shifts, rehabilitation, Insider operations, the stalker's lot, the collar and chains already started are never held back, and a tip says when stories open. In the missing unit's story, the infestation leaves headcrab blood smeared up the wall and across the floor (it said "headcrab shells").

**The quest trail.** While you have a quest, amber chevrons on the ground lead to its objective, flowing toward it. The server works out the way over the paths drawn in the editor first, then the map's own nodegraph, then its navmesh if it has one, and straight there if none of them can (`sv_livingcity_guidance.lua`). It sends it again when the objective moves (someone you're following walks off), when you wander more than about 6 m (300 units) off it, and every 10 seconds while you're on the move; no more than 4 ways are worked out a second, so a full server stays cheap. On your screen, the points you've walked past drop away at once, so the trail always starts at your feet, and only the next 1400 units (about 25 m) are drawn, fading at the far end. It goes when you reach the objective, when the quest ends, and while Breen's water clouds your memory. C > Settings hides it for you (`lc_trail_show`, 1: the server stops sending it too); `lc_trail 0` turns it off for everyone.

**Changes from the 7 November playtest (part 2).**
- **Retake the block** (Civil Protection, the Overwatch): the job is to eliminate every rebel on the ground, not three of them (the objective counts down who's left, and the marker points to the nearest). From the moment the team arrives, no new rebels turn up on that ground or in the camp it grew from (nor a lookout post there) until the job is over and two minutes after (`LC.QuietRebels`). Holding it for the last 30 seconds, a wave of fighters (two plus one per member, up to six) comes from outside to take it back. The time limit is 12 minutes (was 10).
- **A squad for every violent job:** take a violent job and `lc_quest_allies` (2) of your own side go with you: units with pistols and SMGs for Civil Protection, soldiers for the Overwatch, fighters for the Resistance. Free ones nearby join first; else they're brought in out of sight. They follow you and fight what you fight (Civil Protection's and the Overwatch's also turn on the infested near them) until the job ends, and one who falls is replaced now and then. Joining a sweep and backing up a rebel raid bring their own fighters, so no squad there. Not for the infested's jobs.
- **The Missing Unit, part 2 ("What's left of him"):** no choice window in the middle of the infestation. After three kills a zombine in a Civil Protection uniform comes at you, and a notice on screen says it must be 6-12: kill him to end his suffering (the "mercy" ending), or leave the infestation and let a cleanup crew deal with him (the "left" ending). The same endings, decided by what you do.
- **Contraband sweep:** after the three stashes, the last one has something on it (a ration coupon, a work card) with a citizen's number: ask a citizen near the stashes who that is (E), track the suspect down (marked), then detain them, make them say who it was for (authority), take a bribe, or let them go, and arrest them with the baton. +30 XP for the trail; 15 minutes in all. With no prison or nobody about, the sweep ends after the stashes as before.
- **Get the lab running** (the Resistance): when the Combine wreck a lab, this job goes up on the Resistance's board. Find spare parts (marked), bring them to the lab, and stay at the bench for 20 seconds while you and the scientist put it back together. Only players can do it.

## The trail on the ground (11 November)

The chevrons keep their place on the ground and flow on at the same speed however fast you move (they were spaced from your own feet, so they ran with you). The way leaves out path points you could walk straight past: on your own level (70 units up or down at most), nothing solid in the way, floor under the line, up to 2200 units, as far as the objective itself. `lc_trail_straight` (1; 0 follows every path point as before).

## 14 November (the owner's 13 November playtest)

- **Kills count sooner.** A kill made on the way to a job's fight counts toward the kills its next stage asks for, and with them all made, arriving is done too. A kill by an NPC of your own side within 1500 units of you counts for your job (`LC.QuestAssist`).
- **"Repel the attack" ends with the attack:** over while you were there, or after a kill of yours, it is complete; over before you arrived, it is called off ("the attack was over before you got there"). A job template can say this with `over`.
- **The trail goes round walls into the other side's ground.** The planners keep units off rebel ground and everyone else off the Combine's; a job there used to get one straight line through every wall. Now a way is looked for again with no ground kept out of.
- **No distance in a job's title** ("to the north-east", not "240 metres north-east of you"): the marker shows it.
- **Headcrab hunt:** any of the Resistance's supply crates takes the meat.
- **The lab:** walk off while the scientist is making something and he works on, keeps it for you alone, and hands it over when you next talk to him; if a unit takes him, it is lost with him. Back from the cells, or the lab fixed, the blood is cleaned off him, the bench and the kit.

## 14 November (the owner's answers)

- **Repel the attack tracks every attacker:** "Put down the attackers (3 of 5 down)", counting all of the raid's fighters whoever brings them down; done when none is left standing, or when the attack is over.
- **The trail never draws a line through walls.** When either end isn't near a path node on its own floor (an objective on a crate or a balcony, you on a ledge), the way is planned between the path nodes nearest each end; with no way at all, no trail is drawn (the marker still shows where). `LC.TrailNoWay` counts those.
