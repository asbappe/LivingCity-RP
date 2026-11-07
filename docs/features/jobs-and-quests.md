# Jobs and quests (F3), and story chains

**Finding the objective.** The tracker on the right shows a compass for whatever you're after: a pointer relative to where you're facing, the distance in meters, a heading (ahead, behind left, ...) and whether it's on your level, a floor or more **UP**, or **DOWN**. It works even when the target is far enough away that the game isn't drawing it. Quests never send you to the infestation or onto Combine ground. Deliveries are made to **people**: the mail comes from the postal clerk and goes to named residents, Mrs. Kleiner hands you her parcel herself, luggage goes back to its owner, uniforms go to the unit at the checkpoint. Ration crates come from the truck driver and go to the dispenser attendant, and the Resistance's supply runs, the weapons ring and the proof-of-nerve parcel are handed over by and to contacts. Each person waits at a marked spot; walk up and press E.

Each faction has a board of radiant jobs built from your actual map: Directives, Protocols, Agenda, Operations, Assignments, Urges. Many have **choices with d20 checks** (Authority, Empathy, Guile, Nerve), and your choices build three traits that stick: **Loyalty, Sympathy, Corruption**.

Built for crowded servers: no job ever targets a player, boards are finite and scale with faction size, violent jobs are capped city-wide, and people can squad up.

**Directives for what's happening now.** The city's events bring their own jobs, posted two minutes before an event starts (units are briefed early even for a surprise sweep or raid) and as it begins, shown only while it's on, and withdrawn when it ends (whoever was already working one is paid; whoever hadn't started isn't held to it). Units get **Ration line supervision** (rations), **Civil status inspections** (sweeps: pat-downs), **Housing block inspection** (block raids: breach the door, get everyone down, search the place), **Curfew enforcement** and **Lockdown: hold the perimeter**; the Resistance get **Warn the block** (raids) and **Run supplies under curfew** (curfew and lockdown). When the infestation spreads or the Resistance take ground, **Containment** or **Retake the block** goes up at once for that patch, and every unit is told. These, and the chases (Apprehend, Disturbance), are squad jobs: up to 4 to 8 people work one together (the rest of the board takes `lc_quest_squad`, 3). Take it from the board and the others join you from theirs.

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
