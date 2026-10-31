## work you actually do (sv_livingcity_jobgames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_jobgames.lua`


> Note for you (not shown in game): community service is unpaid (sv_livingcity_work.lua): the work still counts

- "You earned %d extra credits for this work, on top of your normal shift pay."  (message, line 112)
- "No extra credits for this work."  (text, line 112)

> Note for you (not shown in game): What's under the wrapper: { item, weight } (credits for "coins")

- "A small folded scrap of paper. It says 'Kleiner lives.', with a lambda (the Resistance symbol) drawn underneath."  (text, line 179)
- "A ration wrapper with a map drawn on the inside: it shows the canal, with an X marked on it."  (text, line 180)
- "A note written by a child: 'Papa, they took the man from 4C. Come home the back way.'"  (text, line 181)
- "Half of a torn Combine notice. All that's left: '...relocation of all residents of Block...'"  (text, line 182)

> Note for you (not shown in game): part of: start

- "Street sweep"  (title, line 216)

> Note for you (not shown in game): part of: lc on pickup

- "found in the rubbish"  (text, line 247)
- "[Sanitation] You found %d credits in Union tokens stuck in that rubbish. They're yours to keep."  (message, line 248)
- "Found in the rubbish"  (on-screen notice, line 250)
- "[Sanitation] You found {what} hidden in that rubbish. It's in your pockets now."  (chat message, line 253)

> Note for you (not shown in game): part of: start

- "[Sanitation] Your cart is waiting at the depot. Look at it and press E to grab it and push it; press E again to let go. Pick up each piece of rubbish with E and throw it into the cart with left click (long throws pay extra). When the cart is full, push it back to the depot to finish. You have 7 minutes, and finishing in under 3 earns a bonus."  (chat message, line 263)

> Note for you (not shown in game): part of: hud

- "Rubbish in the cart: %d of %d"  (message, line 266)
- "Long throws (extra pay): %d"  (message, line 267)
- "Cart full: push it back to the depot to finish"  (text, line 268)
- "Pushing the cart (press E to let go)"  (text, line 268)
- "Press E on the cart to push it"  (text, line 268)

> Note for you (not shown in game): part of: tick

- "Done in under 3 minutes: 5 credits bonus."  (text, line 301)
- "%d long throws into the cart (1 extra credit each)."  (message, line 303)
- "Time's up: you're paid for the rubbish already in the cart."  (text, line 308)

> Note for you (not shown in game): pressing a key

- "[Sanitation] You let go of the cart. Press E on it to push it again."  (chat message, line 323)

> Note for you (not shown in game): The same line, other work: the ration plant's sealing line (opts.variant = "rations").

- "Factory line"  (title, line 349)
- "The conveyor belt is starting. Rust-red, sparking parts are faulty: pick them up with E and throw them (left click) into the scrap bin beside the belt. Leave the good parts on the belt so they reach the end. You're paid for each one you get right and lose pay for each mistake. (Stealing: press R while holding a good part to hide it in your coat; the dealer and the quartermaster buy them. If a Civil Protection unit sees you, you become wanted, and if you take more than one, the foreman may find the count short and dock your pay.)"  (text, line 350)
- "Something rattles inside this part. Press R while holding it to open it and pocket what's hidden inside."  (text, line 351)
- "Ration sealing line"  (title, line 352)
- "The ration sealing belt is starting. Split, leaking packs (the sickly green ones) are faulty: pick them up with E and throw them (left click) into the reject bin beside the belt. Leave the sealed packs on the belt so they reach the end and go on to the dispensers. You're paid for each one you get right and lose pay for each mistake. (Stealing: press R while holding a sealed pack to hide it in your coat. If a Civil Protection unit sees you, you become wanted, and if you take more than one, the foreman may find the count short and dock your pay.)"  (text, line 353)
- "This pack is heavier than a ration should be. Press R while holding it to open it and pocket what's hidden inside."  (text, line 354)

> Note for you (not shown in game): part of: hud

- "Faulty %s binned: %d    Good %s passed: %d"  (message, line 423)
- "Faulty %s missed: %d    Good %s binned by mistake: %d"  (message, line 424)

> Note for you (not shown in game): part of: tick

- "[Foreman] That one was good! Binning good ones comes out of your pay."  (chat message, line 474)
- "[Foreman] A faulty one reached the end of the belt! That comes out of your pay."  (chat message, line 477)

> Note for you (not shown in game): the foreman counts what went through: skim more than one and he may find it short

- "The foreman found %d missing from his count. It comes out of your pay, and you lose Civil Standing."  (message, line 514)
- "Goods went missing on your shift"  (text, line 515)

> Note for you (not shown in game): part of: tick

- "No mistakes all shift: 6 credits bonus."  (text, line 519)
- "Faulty parts binned: %d of %d. Good parts passed: %d."  (message, line 521)

> Note for you (not shown in game): Skimming (sv_livingcity_funding.lua): R while holding a good part pockets it. A unit who sees it makes you wanted; and the more you take, the likelier the foreman finds the count short.

- "That one is faulty: nobody would buy it, so it's not worth stealing."  (chat message, line 540)

> Note for you (not shown in game): part of: line skim

- "You hid {name} in your coat. The foreman's count will be one short."  (chat message, line 546)
- "Theft from the factory floor"  (text, line 548)
- "[Civil Protection] A Civil Protection unit saw you steal that. You're now wanted."  (chat message, line 549)

> Note for you (not shown in game): pressing a key

- "You open it and pocket what was hidden inside: {what}."  (chat message, line 565)
- "Theft from the factory floor"  (text, line 567)
- "[Civil Protection] A Civil Protection unit saw you steal that. You're now wanted."  (chat message, line 568)

> Note for you (not shown in game): part of: rule lines

- "Papers must not be expired."  (text, line 609)
- "The photo must match the person in front of you."  (text, line 609)

> Note for you (not shown in game): One traveler's papers, and what's wrong with them (if anything).

- "Anya Vasek"  (text, line 620)
- "Pavel Orlov"  (text, line 620)
- "Mira Kessler"  (text, line 620)
- "Tomas Hrabal"  (text, line 620)
- "Ilse Brandt"  (text, line 620)
- "Jonas Petrov"  (text, line 620)

> Note for you (not shown in game): part of: start

- "Papers check"  (title, line 687)
- "[Station] Travelers will walk up to you one at a time. Press E on each one to see their papers and check them against today's rules (listed on your screen). Then choose: approve them, deny them, or call a Civil Protection unit if the papers are forged (look closely at the seal). Right calls pay; wrong ones get you a citation and docked pay."  (chat message, line 694)

> Note for you (not shown in game): part of: hud

- "Travelers checked: %d of %d"  (message, line 696)
- "Right calls: %d    Citations (mistakes): %d"  (message, line 696)
- "Today's rules:"  (text, line 696)
- "Press E on the traveler to see their papers"  (text, line 698)

> Note for you (not shown in game): part of: finish

- "No citations all shift: 5 credits bonus."  (text, line 722)
- "%d of %d decisions right."  (message, line 724)

> Note for you (not shown in game): The call: "approve", "deny" or "unit". True when it was right.

- "Forged papers: the seal reads {seal}. A Civil Protection unit takes the traveler away."  (text, line 780)

> Note for you (not shown in game): part of: papers decide

- "Denied. The seal was forged, so calling a Civil Protection unit would have paid more."  (text, line 782)
- "You approved forged papers (the seal read {seal})."  (text, line 786)
- "They walk through on forged papers. Under their breath: 'Thank you.' Nobody noticed this time."  (text, line 788)
- "You approved papers that had expired."  (text, line 793)
- "You approved a traveler whose photo didn't match them."  (text, line 793)
- "You approved entry from a banned district, {banned}."  (text, line 794)
- "You approved a traveler with no transit permit stamp."  (text, line 794)
- "You approved travel for work without a Union stamp."  (text, line 795)
- "You turned away a traveler whose papers were all in order."  (text, line 799)
- "Your pay is docked for this."  (on-screen notice, line 806)
- "[Station] {note}"  (chat message, line 808)

> Note for you (not shown in game): part of: start

- "the panel"  (text, line 971)
- "the terminal"  (text, line 972)

> Note for you (not shown in game): part of: hud

- "Turns used: %d (fewest possible: %d)"  (message, line 981)
- "Blackout: this job pays double."  (text, line 982)

> Note for you (not shown in game): the breaker trips: a new board (and paid less)

- "[Maintenance] Too slow: the breaker tripped and the wires are scrambled. Start again (this job now pays less)."  (chat message, line 993)

> Note for you (not shown in game): part of: wire try

- "Finished in close to the fewest turns: 2 credits bonus."  (text, line 1044)
- "Blackout: pay doubled."  (text, line 1045)
- "Not shocked once."  (text, line 1047)

> Note for you (not shown in game): Triage (Clinic Medic): patients bleeding out at different rates. Treat them with the medkit (primary fire) before they're gone: the worst first.

- "Bleeding badly"  (label, line 1067)
- "Stab wound"  (label, line 1067)
- "Stunstick beating"  (label, line 1068)
- "Broken arm"  (label, line 1068)

> Note for you (not shown in game): part of: start

- "[Clinic] Patients are coming in, and their health keeps dropping. Aim your medkit at a patient and left click to heal them, until each one is almost fully healed. Treat the worst injuries first: a patient whose health reaches zero dies."  (chat message, line 1097)

> Note for you (not shown in game): part of: hud

- "Saved: %d    Lost: %d    Waiting: %d"  (message, line 1099)

> Note for you (not shown in game): part of: tick

- "[Clinic] A patient has died: {label}."  (chat message, line 1112)
- "[Clinic] A patient has died: {label}."  (chat message, line 1127)
- "[Clinic] He grabs your wrist on the way out. 'Thank you. Please... don't write down what did this.'"  (chat message, line 1135)
- "Every patient survived: 6 credits bonus."  (text, line 1147)
- "%d patients saved, %d lost."  (message, line 1148)

> Note for you (not shown in game): part of: start

- "[Reclamation] Smash every block in the pile with your crowbar (left click). Each broken block drops a piece of scrap you can pick up, and sometimes something else. You're paid 1 credit per block."  (chat message, line 1201)

> Note for you (not shown in game): part of: hud

- "Blocks broken: %d of %d"  (message, line 1202)
- "Hit the blocks with the crowbar (left click)"  (text, line 1202)

## more work you actually do (the engine is sv_livingcity_jobgames.lua) (sv_livingcity_moregames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_moregames.lua`


> Note for you (not shown in game): Parcel run (Courier) text: what it looks like; say: what an honest sender calls it; inside: what's really in it

- "A heavy little box, taped twice. It smells of gun oil."  (text, line 70)
- "pistol rounds, loose in a sock"  (text, line 70)
- "Soft and lumpy, wrapped in newspaper. Something inside sloshes."  (text, line 71)
- "a bottle of something that isn't water, and a rag for a fuse"  (text, line 71)
- "A flat tin, very light. It rattles when you turn it."  (text, line 72)
- "buttons, for the laundry"  (spoken line, line 72)
- "buttons, hundreds of them"  (text, line 72)
- "A shoebox tied up with wire. It's warm, somehow."  (text, line 73)
- "a Combine battery cell, humming to itself"  (text, line 73)
- "The label says medicine, but the label is handwritten."  (text, line 74)
- "my mother's medicine"  (spoken line, line 74)
- "painkillers, a few days' worth, in a paper twist"  (text, line 74)
- "It's as heavy as books. Nobody has said the word 'books' out loud in years."  (text, line 75)
- "books, the kind the Union burns"  (text, line 75)
- "A small parcel, neatly wrapped. It weighs almost nothing."  (text, line 76)
- "a letter and some socks for my son"  (spoken line, line 76)
- "a letter, and a pair of darned socks"  (text, line 76)

> Note for you (not shown in game): The sender: an honest one says what's in it; a silent one won't; a bold one owns up to contraband and offers more. The courier takes it, hands it back, reports the sender to a Civil Protection unit (only when they wouldn't say, or owned up), or opens it (Civil Standing, and half the pay: you opened somebody's mail).

- "You opened it. Inside: {inside}."  (text, line 87)
- "The sender says it's {or}."  (text, line 88)
- "You ask what's in it. The sender won't say: 'Don't ask. Just get it there.'"  (text, line 89)
- "The sender admits it's contraband: 'It's not something a unit should see. {SMUGGLE_BONUS} credits extra when it gets there.'"  (text, line 90)

> Note for you (not shown in game): part of: parcel set off

- "Deliver three parcels (follow the waypoint) before the timer runs out. If a Civil Protection unit watches you too long, they stop you for a search, so crouch near them to draw less attention. When stopped, stand still for 5 seconds, or run (you become wanted)."  (chat message, line 106)

> Note for you (not shown in game): part of: parcel way

- "Next delivery"  (text, line 112)

> Note for you (not shown in game): part of: start

- "Parcel run"  (title, line 117)
- "The Resistance cell's cargo, wrapped to look harmless."  (text, line 122)
- "guns and ammunition for the cell"  (text, line 122)
- "Smuggling run"  (title, line 128)
- "Deliver the Resistance cell's cargo to three drop points (follow the waypoint) before the timer runs out. If a Civil Protection unit watches you too long, they stop you for a search, so crouch near them to draw less attention. When stopped, stand still for 5 seconds and hope they miss it, or run (you become wanted)."  (chat message, line 130)
- "Deliver three parcels (follow the waypoint) before the timer runs out. If a Civil Protection unit watches you too long, they stop you for a search, so crouch near them to draw less attention. When stopped, stand still for 5 seconds, or run (you become wanted)."  (chat message, line 134)

> Note for you (not shown in game): the sender: honest about a harmless one most of the time; a hot one is never "honest"

- "The sender is waiting for your answer."  (text, line 143)
- "Choose in the window: take the parcel, hand it back, report the sender, or open it (closed it? press E to bring it back)"  (text, line 143)

> Note for you (not shown in game): part of: hud

- "Delivery %d of %d: %s"  (message, line 146)
- "Civil Protection attention (full means a search): {heat}"  (text, line 148)
- "SEARCH: stand still for %d more seconds, or run"  (message, line 149)
- "A Civil Protection unit is watching you. Crouch or get out of sight before the bar fills and they search you."  (text, line 150)

> Note for you (not shown in game): part of: tick

- "Evading a search"  (text, line 162)
- "You ran from a search"  (on-screen notice, line 163)
- "You're now wanted for evading a search: every Civil Protection unit in the sector has your description. You can still deliver the parcels."  (on-screen notice, line 163)
- "Carrying contraband"  (text, line 170)
- "A Civil Protection unit opened the parcel and found contraband. It's seized, you're wanted, and you get no pay."  (text, line 171)
- "The Civil Protection unit turns it over, shakes it, and hands it back. 'Move along.' You passed the search: carry on."  (chat message, line 175)
- "A Civil Protection unit is stopping you to search the parcel. Stand still for 5 seconds, or run (you become wanted)."  (on-screen notice, line 188)
- "Parcel delivered: {or}. Nobody signs for these."  (chat message, line 195)
- "Finished with %d seconds to spare (1 extra credit for every 10 seconds)."  (message, line 201)
- "Never stopped for a search: 2 credits bonus."  (text, line 205)
- "The cargo got through: 10 credits bonus. The cell won't forget it."  (text, line 208)
- "a smuggling run"  (text, line 209)
- "The sender's %d extra credits, as promised. You knew you were carrying contraband."  (message, line 212)
- "Whatever was in the parcels, it got there."  (text, line 214)
- "Time's up, so there's no time bonus. Deliver the rest anyway."  (chat message, line 222)

> Note for you (not shown in game): part of: act

- "You hand the parcel back: 'Find someone else.' The job ends, with no pay."  (chat message, line 234)
- "reported a sender of contraband"  (text, line 244)
- "You hand the parcel to a Civil Protection unit and point out the sender. It was contraband, so the unit takes it from there, and you gain Civil Standing."  (text, line 245)
- "reported a sender"  (text, line 247)
- "You hand it to a Civil Protection unit. It was harmless: {inside}. The unit isn't pleased you wasted their time."  (text, line 248)
- "opened somebody's parcel"  (text, line 257)
- "You open it. Opening someone's mail costs you Civil Standing, and each delivery now pays less (1 credit instead of 3)."  (chat message, line 258)

> Note for you (not shown in game): part of: start

- "Records terminal"  (title, line 294)
- "the records terminal"  (text, line 295)
- "A needle swings back and forth: click (or press Space) while it's inside the marked band. Do it 4 times to get in; each miss sets you back one. When the scanner flies over, don't click: if it sees you twice, the alarm goes off and you become wanted."  (chat message, line 311)

> Note for you (not shown in game): part of: hud

- "Hits: %d of %d needed"  (message, line 313)
- "Seen by the scanner: %d of 2 (2 sets off the alarm)"  (message, line 313)
- "SCANNER OVERHEAD: don't click"  (text, line 314)
- "Scanner coming: get ready to stop clicking"  (text, line 314)

> Note for you (not shown in game): part of: act

- "Tampering with a Combine terminal"  (text, line 355)
- "The scanner saw you twice and set off the alarm. You're wanted: get out."  (text, line 356)
- "The scanner saw you working the panel. If it sees you once more, it sets off the alarm."  (chat message, line 361)
- "The scanner never saw you: 6 credits bonus."  (text, line 373)

> Note for you (not shown in game): Dead drop (Resistance): hide it where nobody sees you do it

- "the bin"  (text, line 398)
- "the oil drum"  (text, line 398)
- "the box"  (text, line 399)
- "the crate"  (text, line 399)

> Note for you (not shown in game): part of: start

- "Dead drop"  (title, line 405)
- "Three hiding places are outlined. Press E on one, then crouch close to it and stay there until it's hidden. If someone watches you while you hide it, the Seen bar fills; when it's full, that place is burned and you must try another."  (chat message, line 420)

> Note for you (not shown in game): part of: hud

- "Seen bar (full means this place is burned): {seen}"  (text, line 422)
- "Hiding places burned: %d of %d"  (message, line 422)
- "Crouch close to it to keep hiding it"  (text, line 423)
- "Hiding it (stay crouched): {HIDE_SECS}%"  (text, line 423)
- "Press E on an outlined hiding place"  (text, line 424)

> Note for you (not shown in game): part of: tick

- "Someone saw you at {lcDropName}, so it's burned. Try another hiding place."  (on-screen notice, line 452)
- "Someone saw you at every hiding place. You take the message home, with no pay."  (text, line 454)
- "Hidden in {lcDropName}."  (text, line 462)
- "Nobody noticed you: 2 credits bonus."  (text, line 463)

> Note for you (not shown in game): Searching the dead (Mortuary), before the incinerator

- "Trouser pockets"  (text, line 478)
- "Identity papers, still valid"  (label, line 480)
- "Ration coupons, two days' worth"  (label, line 481)
- "A wedding ring"  (label, line 482)
- "Loose pistol rounds"  (label, line 483)
- "A folded note: a name and an address"  (label, line 484)
- "A data chip, sewn into the hem"  (label, line 485)
- "A photograph of two children"  (label, line 486)

> Note for you (not shown in game): part of: start

- "Searching the dead"  (title, line 542)
- "Three bodies to search before they go in the incinerator. Press E on the body and search each pocket. For anything you find, choose: Log it (paid), Keep it, or Family (set it aside for them). Then press 'Done: into the fire'. The overseer looks in now and then: if he's watching when you keep something, you're caught."  (chat message, line 548)

> Note for you (not shown in game): part of: hud

- "Body %d of %d"  (message, line 550)
- "Logged: %d    Kept: %d"  (message, line 550)
- "The overseer is out of the room (nobody is watching)"  (text, line 551)
- "Press E on the body to search it"  (text, line 551)

> Note for you (not shown in game): part of: tick

- "The door opens. The overseer leans on the frame, watching you work. Don't keep anything while he's here."  (chat message, line 560)
- "The overseer goes back out. Nobody is watching now."  (chat message, line 562)

> Note for you (not shown in game): part of: act

- "logged contraband from the dead"  (text, line 580)
- "caught stealing from the dead"  (text, line 586)
- "The overseer saw you: 'In the tray.' It's logged instead, and you lose pay and Civil Standing."  (chat message, line 587)
- "%d items logged, %d kept."  (message, line 602)
- "The overseer wrote your name down for stealing (no clean-work bonus)."  (text, line 603)
- "Into the incinerator. The next body is on the slab: press E on it."  (chat message, line 607)

> Note for you (not shown in game): Sorting (Uniform Laundry)

- "a folded note"  (text, line 624)
- "a pistol magazine"  (text, line 624)
- "ration coupons"  (text, line 624)
- "a door keycard"  (text, line 625)
- "a ration bar, half eaten"  (text, line 625)

> Note for you (not shown in game): part of: start

- "Incident wash (bloodstained)"  (label, line 653)

> Note for you (not shown in game): part of: hud

- "Uniforms: %d of %d"  (message, line 658)
- "Right: %d    Wrong: %d"  (message, line 658)

> Note for you (not shown in game): part of: tick

- "Time's up, with uniforms still on the pile."  (text, line 665)

> Note for you (not shown in game): part of: act

- "a Civil Protection unit's pocket came back short"  (text, line 677)
- "The supervisor counts what comes out of the pockets. Tonight he counts one short and suspects you: you lose Civil Standing."  (chat message, line 678)
- "turned in what a Civil Protection unit left in a pocket"  (text, line 683)
- "You didn't empty the pocket first, so whatever was in it went into the bin too."  (chat message, line 693)
- "No uniforms in the wrong bin: 3 credits bonus."  (text, line 696)
- "%d of %d sorted right."  (message, line 697)

> Note for you (not shown in game): Filing (Records Clerk)

- "Anya Vasek"  (text, line 715)
- "Pavel Orlov"  (text, line 715)
- "Mira Kessler"  (text, line 715)
- "Tomas Hrabal"  (text, line 715)
- "Ilse Brandt"  (text, line 715)
- "Jonas Petrov"  (text, line 715)
- "Lena Duric"  (text, line 715)
- "Viktor Sorel"  (text, line 716)
- "Hana Novak"  (text, line 716)
- "Emil Strand"  (text, line 716)
- "Katya Lind"  (text, line 716)
- "Oskar Benes"  (text, line 716)
- "Rosa Kalnin"  (text, line 716)
- "Dmitri Arkov"  (text, line 716)

> Note for you (not shown in game): part of: hud

- "Forms: %d of %d"  (message, line 763)
- "Right: %d    Wrong: %d"  (message, line 763)

> Note for you (not shown in game): part of: tick

- "Time's up, with forms still in the in-tray."  (text, line 770)

> Note for you (not shown in game): part of: act

- "caught taking a blank identity form"  (text, line 780)
- "Theft of state forms"  (text, line 781)
- "A Civil Protection unit at the counter saw you take it. You put it back, but you're wanted and lose Civil Standing."  (chat message, line 782)
- "You slip a blank identity form into your sleeve. It's in your pockets now."  (chat message, line 786)
- "No forms filed wrong: 3 credits bonus."  (text, line 800)
- "%d of %d filed right."  (message, line 801)

> Note for you (not shown in game): Radio repair: a set's trimmer screws, set by ear. Tune it to its station (the dial), then turn the screws with the screwdriver until it comes through clean: the volume trimmer brings the station up, the squelch pushes the static down, the alignment pulls a smeared signal into focus. Sometimes the clearest thing on the band is Freq 7.

- "Volume trimmer"  (text, line 819)

> Note for you (not shown in game): How right a screw is: 1 on the spot, 0 a third of the range off.

- "'...this is Freq 7. They count the rations and they count you. Count them back...'"  (text, line 828)
- "'...the third shift at the station is short two Civil Protection units on Tuesdays. Freq 7, out...'"  (text, line 829)
- "'...if you can hear this, you are not alone. Freq 7...'"  (text, line 830)
- "'...the Administrator's broadcasts are recorded. She is not in the city. Freq 7...'"  (text, line 831)

> Note for you (not shown in game): part of: new radio

- "A voice comes through the static, on Freq 7."  (text, line 871)

> Note for you (not shown in game): part of: radio done

- "You fixed every radio: 3 credits bonus."  (text, line 894)
- "%d of %d radios fixed."  (message, line 895)

> Note for you (not shown in game): part of: start

- "Radio repair"  (title, line 904)

> Note for you (not shown in game): part of: hud

- "Radio %d of %d"  (message, line 909)
- "Turn the dial to its station, then adjust the screws until it sounds clear"  (text, line 910)
- "%d seconds left for this radio"  (message, line 911)

> Note for you (not shown in game): part of: tick

- "Out of time: this radio goes back on the shelf unfixed."  (chat message, line 918)

> Note for you (not shown in game): part of: act

- "Right station, but too faint. Adjust the volume trimmer."  (text, line 956)
- "Right station, but buried in static. Adjust the squelch."  (text, line 957)
- "Right station, but blurred and smeared. Adjust the alignment."  (text, line 957)
- "reported an illegal broadcast"  (text, line 980)
- "You report the frequency to Civil Protection: extra pay and Civil Standing. They'll be listening for it now."  (chat message, line 982)
- "You secretly write down Freq 7 and the seven frequencies it broadcasts on. The Freq 7 sheet is in your pockets: it's contraband, so pass it on or burn it."  (chat message, line 988)
- "You tune past it and leave Freq 7 alone. Nothing on this band is worth the risk."  (chat message, line 991)

> Note for you (not shown in game): A Freq 7 sheet, read: the rule, and the seven frequencies it gives.

- "FREQ 7 /  / Freq 7 only broadcasts on frequencies whose digits add up to seven. These are the seven places on the dial: /  / {list} /  / {or}When the Combine find the broadcast, it moves to another of these: try the next one. /  / Keep the volume low, and never listen where a Civil Protection unit can hear it."  (text, line 1006)

> Note for you (not shown in game): part of: read item

- "(in a cramped hand)"  (text, line 1013)

> Note for you (not shown in game): part of: listen off

- "[Radio] {why}"  (chat message, line 1059)

> Note for you (not shown in game): Listen (already on: the window again, where you left the dial; it has its own off switch).

- "You can't listen to a radio while you're in custody."  (text, line 1067)

> Note for you (not shown in game): a timer (regularly)

- "Your radio is no longer in your pockets, so it switched off."  (text, line 1101)

> Note for you (not shown in game): the pirate band, out loud, where a unit can hear it

- "Listening to an illegal broadcast"  (text, line 1118)
- "A Civil Protection unit heard that"  (on-screen notice, line 1119)
- "A Civil Protection unit heard Freq 7 playing from your radio. You're now wanted: switch it off, or run."  (on-screen notice, line 1119)

> Note for you (not shown in game): Pat-down (Civil Protection)

- "Left pocket"  (text, line 1131)
- "Right pocket"  (text, line 1131)
- "They hold their coat closed with one hand."  (text, line 1133)
- "Their left hand keeps drifting to their pocket."  (text, line 1133)
- "They keep their right side turned away from you."  (text, line 1134)
- "They won't stop tugging their shirt down."  (text, line 1134)
- "They shift their weight off one foot."  (text, line 1135)
- "They hold the bag tight against them."  (text, line 1135)
- "a pistol magazine"  (text, line 1137)
- "a Resistance leaflet"  (text, line 1137)
- "a forged ration card"  (text, line 1137)
- "a data chip"  (text, line 1138)

> Note for you (not shown in game): part of: verdict

- "You let them go, but they were hiding something you missed."  (chat message, line 1164)
- "You let them go and hand back what you found. They don't say thank you; they don't dare."  (chat message, line 1165)
- "Confiscated: {what}. Logged as evidence."  (chat message, line 1171)
- "You detained someone with nothing on them: a wrong call, and it comes out of your pay. Dispatch is not impressed, and neither is the street."  (chat message, line 1182)
- "Every call right: 3 credits bonus."  (text, line 1192)
- "%d searched, %d right."  (message, line 1193)

> Note for you (not shown in game): part of: start

- "Press E on a citizen to stop them. In the window, pat down one place at a time: each empty place you check costs some of their nerve, and if it runs out they run off. Watch how they act, as it hints where something is hidden. Then choose: Release, Confiscate (if you found something) or Detain."  (chat message, line 1205)

> Note for you (not shown in game): part of: hud

- "Searched: %d of %d"  (message, line 1207)
- "Right calls: %d"  (message, line 1207)
- "Their nerve (they run at zero): %s"  (message, line 1208)
- "Press E on a citizen to stop and search them"  (text, line 1208)

> Note for you (not shown in game): part of: use

- "You searched that citizen already. Pick someone else."  (chat message, line 1219)

> Note for you (not shown in game): part of: act

- "They lose their nerve and run off."  (chat message, line 1260)
- "One ran off with something hidden on them."  (text, line 1261)
- "%d searched, %d right."  (message, line 1265)

> Note for you (not shown in game): part of: room

- "Get everyone on the floor: press E on each person before they run or burn evidence. Then search the room: press E on each outlined piece of furniture."  (chat message, line 1318)

> Note for you (not shown in game): part of: start

- "The door is locked. Press E on it to set a breaching charge, then stand back: it blows a moment later."  (chat message, line 1336)

> Note for you (not shown in game): part of: hud

- "Charge set: stand back"  (text, line 1341)
- "Press E on the door to set the charge"  (text, line 1341)
- "On the floor: %d    Ran: %d    Still standing: %d"  (message, line 1346)
- "Found: %d    Destroyed: %d    Left to search: %d"  (message, line 1347)

> Note for you (not shown in game): part of: use

- "Found: {what}."  (chat message, line 1375)
- "Ash, and the smell of burnt paper. Someone destroyed what was here before you searched it."  (chat message, line 1377)

> Note for you (not shown in game): part of: tick

- "Someone you didn't get on the floor in time burned evidence. Whatever it was, it's gone."  (chat message, line 1410)
- "One of them ran out the back before you got them on the floor."  (chat message, line 1416)
- "Nobody ran and nothing was destroyed: 4 credits bonus."  (text, line 1425)
- "%d on the floor, %d ran, %d found."  (message, line 1426)

