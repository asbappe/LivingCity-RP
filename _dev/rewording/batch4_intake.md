## lc_intake.lua (lc_intake.lua)

`gamemodes/livingcity/entities/entities/lc_intake.lua`

- "Civil Intake terminal"  (name, line 13)

## cl_livingcity_intake.lua (cl_livingcity_intake.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_intake.lua`


> Note for you (not shown in game): on screen

- "Stay at the terminal"  (drawn on screen, line 77)

> Note for you (not shown in game): The sign on the terminal itself (lc_intake.lua draws it, in 3D).

- "Registered arrivals: request a room"  (drawn on screen, line 107)
- "New arrivals: registration"  (drawn on screen, line 107)

> Note for you (not shown in game): How you came to have the room you have.

- "Allocated here, at Housing Allocation."  (text, line 133)
- "Transferred here at your request."  (text, line 134)
- "Came with your papers (there was no Housing Allocation desk then)."  (text, line 135)
- "Assigned by the city administration."  (text, line 136)
- "Already on file before you came to this desk: assigned when you first arrived in the city."  (text, line 137)

> Note for you (not shown in game): part of: paint

- "citizen {or}"  (drawn on screen, line 163)

> Note for you (not shown in game): part of: open desk

- "Housing: {or}"  (text, line 197)
- "Identity papers: {or}"  (text, line 198)
- "Ration cards: %d (you earn one for each Union shift you finish)"  (message, line 199)
- "Replace my identity papers (%d credits)"  (message, line 202)
- "Civil Protection units ask for papers; Housing Allocation wants to see them"  (button, line 203)
- "Your papers are in order."  (text, line 205)
- "You have no room yet. Housing Allocation assigns one."  (text, line 208)
- "Show me the way to Housing Allocation"  (text, line 209)
- "Show me the way home"  (text, line 211)
- "The terminal can't find you on the register. Register at Civil Intake first; then come back with your papers."  (text, line 215)
- "Show me the way to Civil Intake"  (text, line 216)
- "Present your papers and pick a block. Any block is approved at once (the least crowded). A crowded block is only granted to citizens in good standing ({or} or more). Yours: {or}."  (text, line 219)
- "Papers: {or}"  (text, line 221)
- "Any block (approved at once)"  (button, line 222)
- "Apply for %s   (%d living there%s%s)"  (message, line 227)
- "No blocks on file in this city."  (text, line 230)
- "Show me the way home"  (text, line 234)
- "Move to another block (once every half hour). A crowded block needs good standing ({or})."  (text, line 237)
- "Transfer to %s   (%d living there%s)"  (message, line 240)
- "Present your papers to apply: you have none on you."  (text, line 244)
- "Not now."  (text, line 246)

> Note for you (not shown in game): on screen

- "Held up by the person in front of you"  (drawn on screen, line 309)

## Civil Intake (becoming somebody) (sv_livingcity_intake.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_intake.lua`


> Note for you (not shown in game): part of: register person

- "[Civil Intake] You were processed while in custody: %s, citizen %s. Your papers are in your pockets (F2). Ration cards come from work: each Union shift you finish earns one."  (message, line 222)
- "[Civil Intake] Registration complete. %s, citizen %s. Your identity papers are in your pockets (F2): keep them on you. Ration cards come from work: each Union shift you finish earns one."  (message, line 224)
- "[Civil Intake] Next: Housing Allocation, for a room. It's marked on your screen."  (chat message, line 228)
- "[Civil Intake] Your file already lists a room: {n}. Housing Allocation can tell you more."  (chat message, line 232)
- "[Civil Intake] You've been given a room in {n}."  (chat message, line 237)

> Note for you (not shown in game): part of: house person

- "[Housing Allocation] {or} is full; your request was declined. Assigned: a room in {n}."  (chat message, line 293)
- "[Housing Allocation] Approved: a room in {n}. It's marked on your screen. Curfew finds you at home from now on."  (chat message, line 295)
- "[Housing Allocation] No rooms on file in this city."  (chat message, line 298)

> Note for you (not shown in game): A housed citizen moving to another block.

- "You have no room to transfer from."  (text, line 308)
- "Transfers are for citizens in good standing ({TRANSFER_STANDING} or more)."  (text, line 310)
- "Your last transfer is too recent. Ask again in %d minutes."  (message, line 313)

> Note for you (not shown in game): part of: transfer person

- "[Housing Allocation] {why}"  (chat message, line 319)
- "[Housing Allocation] There's nowhere to transfer you to."  (chat message, line 322)
- "[Housing Allocation] Transfer declined: {or} is full. You stay in {from}."  (chat message, line 324)
- "[Housing Allocation] Transfer approved: {from} to {n}. It's marked on your screen."  (chat message, line 329)
- "Processing your registration"  (text, line 351)
- "[Civil Intake] Stand still. Processing."  (text, line 351)
- "Searching the housing register"  (text, line 352)
- "[Housing Allocation] Stand still. Searching the housing register."  (text, line 352)
- "Processing your transfer request"  (text, line 353)
- "[Housing Allocation] Stand still. Processing your transfer request."  (text, line 353)
- "Printing your identity papers"  (text, line 354)
- "[Civil Intake] Stand still. Printing new papers."  (text, line 354)

> Note for you (not shown in game): part of: finish

- "[Civil Intake] Insufficient credits. The replacement costs {fee}."  (chat message, line 379)
- "replacement {what}"  (text, line 382)
- "[Civil Intake] New identity papers issued ({fee} credits). Keep them on you."  (chat message, line 384)

> Note for you (not shown in game): part of: use intake

- "[Housing Allocation]"  (title, line 407)
- "[Civil Intake]"  (title, line 407)
- "The screen reads CLOSED. New arrivals are registered as they come in."  (chat message, line 409)
- "%d waiting in line."  (message, line 413)
- "The terminal only processes citizens."  (chat message, line 415)

> Note for you (not shown in game): the registered (and anyone at Housing Allocation): the terminal's own screen

- "Processing another citizen. Wait your turn."  (chat message, line 421)

> Note for you (not shown in game): A button on a terminal's screen. True if the terminal took it on.

- "[Housing Allocation]"  (title, line 469)
- "[Civil Intake]"  (title, line 469)
- "Processing another citizen. Wait your turn."  (chat message, line 473)

> Note for you (not shown in game): part of: desk action

- "No record of you. Register at Civil Intake first."  (chat message, line 477)
- "Present your identity papers. You have none on you: Civil Intake replaces lost papers."  (chat message, line 479)
- "You already have a room. Ask for a transfer instead."  (chat message, line 483)
- "Ration cards aren't issued here. You earn one for each Union shift you finish."  (chat message, line 493)
- "You already have your papers on you."  (chat message, line 498)
- "A replacement costs {fee} credits. You don't have them."  (chat message, line 501)

> Note for you (not shown in game): the game answering something done in a window (lc_intake_act)

- "[Civil Intake] Step back up to the terminal."  (chat message, line 521)

> Note for you (not shown in game): The registration form, handed in (sv_livingcity_character.lua asks first).

- "Step back up to the terminal to enter your details."  (text, line 531)
- "Describe yourself for the register: how a stranger would know you (8 characters at least)."  (text, line 534)

> Note for you (not shown in game): part of: intake form check

- "A shorter description, please (120 characters at most)."  (text, line 535)

> Note for you (not shown in game): a timer (regularly)

- "[Civil Intake] You walked away from the terminal. Start again."  (chat message, line 564)

> Note for you (not shown in game): on the register, but never handed their papers (everyone from before they were things you carry)

- "[Papers] Your identity papers are in your pockets (F2). Keep them on you: Civil Protection units ask for them."  (chat message, line 609)

> Note for you (not shown in game): a timer (regularly)

- "[Civil Intake] You've arrived in the city with nothing: no papers, no room, no ration card. Report to Civil Intake to register. Your screen points the way."  (chat message, line 638)
- "[Housing Allocation] You've arrived in the city with nowhere to sleep. Ask Housing Allocation for a room. Your screen points the way."  (chat message, line 640)

> Note for you (not shown in game): on the register: are they carrying their papers?

- "[Civil Protection] Papers. None? Carry them at all times. Civil Intake replaces lost papers."  (chat message, line 658)
- "no papers on them"  (text, line 659)

> Note for you (not shown in game): part of: intake stopped

- "[Civil Protection] No papers. New arrival? Report to Civil Intake. Now."  (chat message, line 666)
- "[Civil Protection] Still no papers. Failure to register."  (chat message, line 670)
- "Failure to register"  (text, line 671)

> Note for you (not shown in game): A unit's own search finds no papers.

- "[Records] No papers: not on the register. New arrivals report to Civil Intake."  (chat message, line 679)
- "[Records] On the register, but carrying no papers."  (chat message, line 681)

> Note for you (not shown in game): The steps a new arrival takes at the desks before going home (empty when there are none, or intake is off).

- "in line at Civil Intake"  (text, line 799)
- "being registered at Civil Intake"  (text, line 799)
- "in line for Housing Allocation"  (text, line 801)
- "waiting on a housing allocation"  (text, line 801)

> Note for you (not shown in game): Commands What their papers say: their own, or the forged ones they're living under.

- "None yet: Housing Allocation"  (text, line 837)
- "None on file"  (text, line 837)

> Note for you (not shown in game): part of: papers info

- "Citizen {alias}"  (text, line 844)

> Note for you (not shown in game): Show your papers to whoever you're looking at (or read them yourself).

- "[Papers] You have none. Report to Civil Intake to register."  (text, line 857)
- "[Papers] You have no papers on you. Civil Intake replaces lost papers."  (text, line 859)

> Note for you (not shown in game): part of: show papers

- "[Papers] They show you their papers: %s, citizen %s."  (message, line 865)
- "[Papers] You hold your papers up for them to see."  (chat message, line 867)

> Note for you (not shown in game): part of: papers

- "[Papers] You have none. Report to Civil Intake to register."  (chat message, line 878)
- "[Papers] %s, citizen %s. Housing: %s.%s"  (message, line 883)
- "(Your papers aren't on you: Civil Intake replaces them.)"  (message, line 884)

> Note for you (not shown in game): the console command lc_register

- "[Living City] Usage: lc_register <name>"  (text, line 909)

> Note for you (not shown in game): the console command lc_unregister

- "[Living City] Usage: lc_unregister <name> (sends them back through Civil Intake)"  (text, line 916)
- "[Living City] Staff sent you back through Civil Intake: register, then ask Housing Allocation for a room."  (chat message, line 932)

