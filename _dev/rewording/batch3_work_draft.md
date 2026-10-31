## occupations (sv_livingcity_work.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_work.lua`


> Note for you (not shown in game): part of: set job

- "That job doesn't exist."  (text, line 56)
- "That job is closed right now. Pick a different one."  (text, line 57)
- "Only citizens can take Union jobs."  (text, line 59)
- "Only registered citizens can take Union jobs. Register at Civil Intake first, then pick a job."  (text, line 61)
- "You changed jobs recently. You can change again in {CurTime} seconds."  (text, line 64)
- "[Union] Your job is now: {name}. Open your board (F3) to find your shifts."  (chat message, line 81)

> Note for you (not shown in game): part of: give union work

- "Union work assignment"  (on-screen notice, line 111)
- "The Union has given you a job: {name}. Go to the {place} to work. Your shifts are on your board (F3), and you can ask for a different job there."  (on-screen notice, line 111)

> Note for you (not shown in game): the game answering something done in a window (lcj_set)

- "[Union] {why}"  (chat message, line 121)

> Note for you (not shown in game): a timer (regularly)

- "[Union] Your job ({name}) has been closed, so you don't have one now. Pick a new job on your board (F3)."  (chat message, line 142)

> Note for you (not shown in game): Shifts, by job

- "Litter sweep"  (title, line 230)

> Note for you (not shown in game): part of: sanitation

- "Pick up 5 pieces of litter {GetPos}."  (description, line 231)
- "Pick up the litter: press E on each piece (5 in all)"  (text, line 233)

> Note for you (not shown in game): part of: text

- "Go to bin %d of 3 (%s) and stay next to it for 6 seconds to empty it"  (message, line 251)
- "Bin round"  (title, line 259)
- "Three bins are overflowing. Go to each one and empty it."  (description, line 259)

> Note for you (not shown in game): part of: stages

- "Graffiti removal"  (title, line 265)
- "Someone reported graffiti {GetPos}. Go there and scrub it off."  (description, line 266)
- "Go to the graffiti (marked)"  (quest step, line 268)
- "Someone has sprayed a lambda (the Resistance symbol) and a name across the wall. You know the name: it's your neighbor's boy."  (quest choice, line 269)
- "Scrub off all of it, lambda and name."  (text, line 270)
- "Scrub off only the name and leave the lambda (if you're caught, you're wanted)."  (text, line 271)

> Note for you (not shown in game): part of: success

- "Somebody will see that lambda tomorrow and feel a little less alone."  (quest narration, line 275)

> Note for you (not shown in game): part of: fail

- "A Civil Protection unit on the corner saw you leave the lambda on the wall. You're now wanted."  (quest narration, line 278)
- "Defacing city property"  (text, line 279)

> Note for you (not shown in game): part of: stages

- "Report the boy's name to a Civil Protection unit."  (text, line 281)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report the name"  (quest step, line 284)

> Note for you (not shown in game): part of: stages

- "Crouch at the wall for 5 seconds to scrub it clean"  (quest step, line 287)

> Note for you (not shown in game): part of: kitchen

- "The sealing line"  (title, line 308)
- "Ration bars and gel get sealed in foil here, thousands a day. Go to the ration plant and work the sealing line."  (description, line 309)
- "Go to the ration plant (marked)"  (quest step, line 310)
- "Stay at the line for 40 seconds to seal ration packs"  (quest step, line 310)

> Note for you (not shown in game): part of: stages

- "Supply run"  (title, line 318)
- "The supply truck is waiting {GetPos}. Get the crate of ration packs from the driver and take it to the dispenser attendant."  (description, line 319)
- "Go to the truck driver (marked) and press E on them to take the ration crate"  (text, line 321)
- "'Sign here. No, nobody has a pen. Just take it.'"  (text, line 321)
- "Take the crate to the dispenser attendant (marked) and press E on them"  (text, line 322)
- "She counts the packs twice and doesn't say what the number should have been."  (text, line 323)
- "The count"  (title, line 331)
- "Every ration pack in the dispensers must match the register. Go to the dispensers and count them."  (description, line 332)
- "Go to the dispensers (marked)"  (quest step, line 334)
- "Stay at the dispensers for 25 seconds to count the packs against the register"  (quest step, line 335)
- "The count is three packs short. Nobody signed for them, and the register doesn't care whose fault that is."  (quest choice, line 336)
- "Report the missing packs to the supervisor."  (text, line 337)

> Note for you (not shown in game): part of: pick

- "The supervisor writes it down. Somebody is going to have a very bad week. It isn't you. (5 extra XP for this shift.)"  (quest narration, line 340)

> Note for you (not shown in game): part of: stages

- "Change the register so the numbers match."  (text, line 342)

> Note for you (not shown in game): part of: pick

- "A stroke of the pen and the register matches the shelves. Nobody will ever know. Probably."  (quest narration, line 344)

> Note for you (not shown in game): part of: stages

- "Write it down as six short and keep three packs for yourself (if you're caught, you're wanted)."  (text, line 346)

> Note for you (not shown in game): part of: success

- "You take three ration packs for yourself. The register will blame whoever worked here before you."  (quest narration, line 350)

> Note for you (not shown in game): part of: fail

- "A dispenser attendant saw you take the packs. She doesn't say anything. She doesn't have to: you're now wanted for ration fraud."  (quest narration, line 353)
- "Ration fraud"  (text, line 354)
- "The counter"  (title, line 366)
- "You're checking ration cards at line {g} today. Each valid card gets one ration pack. Forged cards get nothing."  (description, line 367)
- "Go to the ration counter (marked)"  (quest step, line 369)
- "A card with a smudged stamp and a citizen number that's one digit too long: it's forged. The man holding it is very thin."  (quest choice, line 370)
- "Take the card and report him to Civil Protection."  (text, line 371)

> Note for you (not shown in game): part of: pick

- "A Civil Protection unit takes him by the arm. The card goes in the box with the others. (10 extra XP for this shift.)"  (quest narration, line 374)
- "Accept the card and give him his ration."  (text, line 376)
- "He takes the pack and doesn't look back. Neither do you."  (quest narration, line 379)
- "Keep the forged card for yourself (if you're caught, you're wanted)."  (text, line 381)

> Note for you (not shown in game): part of: success

- "'Invalid,' you tell him, and the card goes in your pocket instead of the box. He doesn't argue."  (quest narration, line 385)

> Note for you (not shown in game): part of: fail

- "The supervisor saw the card go in your pocket. 'Ration fraud,' he says, almost bored. You're now wanted."  (quest narration, line 388)
- "Ration fraud"  (text, line 389)
- "Stay at the counter until 3 citizens have been handed their rations"  (text, line 393)

> Note for you (not shown in game): part of: medic

- "Clinic rounds"  (title, line 404)
- "Three injured patients are waiting at the clinic. Heal each one with your medkit until they're back on their feet."  (description, line 405)
- "Go to the clinic (marked)"  (quest step, line 407)
- "Heal the patients: hold your medkit and press primary fire (left click) on each one until they're healed"  (text, line 408)

> Note for you (not shown in game): part of: stages

- "House call"  (title, line 416)
- "A man was hurt {GetPos} and can't walk to the clinic. Go to him and heal him."  (description, line 417)
- "Go to the injured man (marked)"  (text, line 420)
- "Stunstick bruises, in neat rows: Civil Protection did this. He grabs your wrist. 'Please. Don't write it down. Say I fell.'"  (quest choice, line 429)
- "Write down the truth: a stunstick beating."  (text, line 430)
- "Cover for him: write 'fell down the stairs'."  (text, line 431)

> Note for you (not shown in game): part of: pick

- "He closes his eyes. 'Thank you.'"  (quest narration, line 434)

> Note for you (not shown in game): part of: stages

- "Heal him: hold your medkit and press primary fire (left click) on him until he's healed"  (text, line 437)

> Note for you (not shown in game): part of: factory

- "Assembly quota"  (title, line 450)
- "Today's quota is posted: work the line, then carry the finished part to the next station and fit it. Nobody asks what the parts are for."  (description, line 451)
- "Go to the factory line (marked)"  (quest step, line 453)
- "Stay at the line for 25 seconds to work it"  (quest step, line 454)
- "Pick up the finished part: press E on the box"  (text, line 455)
- "Carry the part to the next station (marked)"  (text, line 456)
- "Stay at the station for 15 seconds to fit the part"  (quest step, line 457)

> Note for you (not shown in game): part of: text

- "Go to the loading dock (marked) and press E on crate %d of 2 to pick it up"  (message, line 468)
- "Carry crate %d to the factory floor (marked)"  (message, line 469)
- "Loading dock"  (title, line 471)
- "Carry two crates, one at a time, from the loading dock to the factory floor."  (description, line 471)

> Note for you (not shown in game): part of: stages

- "Short count"  (title, line 477)
- "Another shift working the factory line."  (description, line 478)
- "Go to the factory line (marked)"  (quest step, line 480)
- "Stay at the line for 20 seconds to work it"  (quest step, line 481)
- "The parts count is short again. You see the foreman slide a box of parts under his coat, and he sees you watching."  (quest choice, line 482)
- "Report the foreman to Civil Protection."  (text, line 483)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report the foreman"  (quest step, line 486)

> Note for you (not shown in game): part of: stages

- "Say nothing."  (text, line 488)
- "Ask him for a share of what he's stealing."  (text, line 489)

> Note for you (not shown in game): part of: pick

- "He grins like you've always been friends. (10 extra XP for this shift.)"  (quest narration, line 493)

> Note for you (not shown in game): real letters, from people in the city to people in the city (sv_livingcity_mail.lua)

- "Go to the post office (marked) and press E on the postal clerk to collect today's letters"  (text, line 509)
- "'Real post, for once. Mind none of it goes astray.'"  (text, line 510)

> Note for you (not shown in game): part of: courier

- "Take letter %d of %d to %s (marked) and stay at their door for 3 seconds to push it under"  (message, line 526)

> Note for you (not shown in game): they're yours from the moment you start

- "The real mail"  (title, line 537)

> Note for you (not shown in game): part of: courier

- "letter{or} written by people in the city, for you to deliver to other people in the city."  (description, line 538)

> Note for you (not shown in game): part of: claimed

- "an apartment doorway"  (text, line 548)

> Note for you (not shown in game): the mail comes from the clerk at the post office, and goes to people, by hand

- "Go to the post office (marked) and press E on the postal clerk to collect the mail"  (text, line 556)
- "'Three for the district. Two are overdue. Don't tell them I said so.'"  (text, line 557)
- "Hand letter %d of 3 to %s, %s (marked): go there and press E on them"  (message, line 561)
- "They take it without looking at who sent it."  (text, line 562)
- "'Finally,' they say, and shut the door on the rest of the sentence."  (text, line 562)
- "A nod. Nobody says anything useful in this city out loud."  (text, line 563)
- "They read the envelope twice before they put it away."  (text, line 563)

> Note for you (not shown in game): part of: claimed

- "Mail round"  (title, line 566)
- "Collect three letters from the clerk at the post office, then hand each one to the person it's addressed to."  (description, line 566)

> Note for you (not shown in game): part of: stages

- "Sealed envelope"  (title, line 574)
- "Collect an envelope with a Civil Protection seal from the post office and deliver it to someone {GetPos}."  (description, line 575)
- "Go to the post office (marked) and press E on the clerk to collect the envelope"  (text, line 577)
- "'Hand it over in person. Nobody signs for these.'"  (text, line 577)
- "The seal is a Combine stamp, and it's not glued very well. You could probably open it."  (quest choice, line 578)
- "Deliver it unopened."  (text, line 579)
- "Steam it open and read it (the seal might tear)."  (text, line 580)

> Note for you (not shown in game): part of: success

- "It's an eviction order for the family in 3B, the one with the twins. They have to be out by tomorrow."  (quest choice, line 582)
- "Deliver it as addressed and say nothing."  (text, line 583)
- "Warn the family before you deliver it."  (text, line 584)

> Note for you (not shown in game): part of: pick

- "Go to the family's home (marked) to quietly warn them"  (quest step, line 587)

> Note for you (not shown in game): part of: fail

- "The seal tears. You'll have to hope nobody checks."  (quest narration, line 591)

> Note for you (not shown in game): part of: stages

- "Take the envelope to the person it's addressed to (marked) and press E on them"  (text, line 593)
- "They take it with both hands, like it might go off."  (text, line 593)

> Note for you (not shown in game): the city's own streetlights, the broken ones first (sv_livingcity_propaganda.lua)

- "Go to streetlight %d of %d (%s) and stay next to it to repair it"  (message, line 607)

> Note for you (not shown in game): part of: maintenance

- "Lights out"  (title, line 614)
- "Streetlights are broken across the district. Go to each one and repair it."  (description, line 614)
- "Go to fuse box %d of 3 (%s) and stay next to it to repair it"  (message, line 620)
- "Lights out"  (title, line 625)
- "Three fuse boxes are broken across the district. Go to each one and repair it."  (description, line 625)

> Note for you (not shown in game): part of: stages

- "Terminal fault"  (title, line 632)
- "A scanner terminal at a checkpoint keeps breaking down. Go there and repair it."  (description, line 633)
- "Go to the broken terminal (marked)"  (quest step, line 635)
- "Stay next to the terminal to repair it"  (quest step, line 636)
- "While the terminal reboots, its log scrolls past. One of last night's entries is your neighbor, out at 3 a.m."  (quest choice, line 637)
- "Leave the log as it is."  (text, line 638)
- "Erase your neighbor's entry while you're in there (if you're caught, you're wanted)."  (text, line 639)

> Note for you (not shown in game): part of: success

- "One line of the log becomes noise. Terminals glitch all the time."  (quest narration, line 643)

> Note for you (not shown in game): part of: fail

- "The terminal flags the edit. Every Civil Protection unit in the sector gets the alert. You're now wanted."  (quest narration, line 646)
- "Tampering with a city terminal"  (text, line 647)

> Note for you (not shown in game): Somewhere people live: a housing block, an apartment doorway, or a street.

- "an apartment doorway"  (text, line 669)

> Note for you (not shown in game): Somewhere Civil Protection works: a checkpoint, the prison, or a street.

- "the checkpoint"  (text, line 677)
- "the prison"  (text, line 679)

> Note for you (not shown in game): Intake Processor

- "New arrivals"  (title, line 718)
- "A train has arrived. Meet one of the new arrivals on the platform and walk him to his assigned housing."  (description, line 719)

> Note for you (not shown in game): part of: porter

- "Go to the new arrival on the platform (marked)"  (text, line 722)
- "He's holding a transfer slip like it might bite him. Under his breath he asks: 'Is there anywhere in this city they don't look?'"  (quest choice, line 731)
- "Tell him: 'Go to your block and keep your head down.'"  (text, line 732)
- "Tell him about the canals (rebel territory) and walk him there instead."  (text, line 733)

> Note for you (not shown in game): part of: pick

- "He doesn't say thank you. He doesn't have to."  (quest narration, line 740)

> Note for you (not shown in game): part of: porter

- "Report what he said to a Civil Protection unit."  (text, line 742)

> Note for you (not shown in game): part of: pick

- "A Civil Protection unit takes him by the arm. He looks back at you once."  (quest narration, line 746)

> Note for you (not shown in game): part of: porter

- "Walk him to his new home (marked)"  (text, line 751)

> Note for you (not shown in game): part of: on enter

- "Walk him to {or}"  (text, line 756)

> Note for you (not shown in game): part of: text

- "A suitcase was left on the train platform. Pick it up and return it to its owner, {destName}."  (description, line 768)
- "Go to the platform (marked) and press E on the suitcase to pick it up"  (text, line 771)
- "The suitcase is heavier than clothes. Something inside slides and settles, like a stack of paper."  (quest choice, line 772)
- "Just carry it. It's not your business."  (text, line 773)
- "Open it and look inside (if you're caught, you're wanted)."  (text, line 774)

> Note for you (not shown in game): part of: success

- "Under the shirts: a stack of blank identity forms. You take one. Nobody counts them twice."  (quest narration, line 776)

> Note for you (not shown in game): part of: fail

- "The latches snap open loud enough to turn heads. A Civil Protection unit is already walking over. You're now wanted."  (quest narration, line 781)
- "Theft from a traveler"  (text, line 782)

> Note for you (not shown in game): part of: text

- "Hand it to Civil Protection."  (text, line 784)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to hand over the suitcase"  (quest step, line 788)

> Note for you (not shown in game): part of: text

- "Take the suitcase to its owner, {destName} (marked), and press E on them"  (text, line 791)
- "'That's mine. I thought I'd lost it.' They don't say thank you."  (text, line 791)
- "Ticket check"  (title, line 799)
- "Check the ticket and transit permit of everyone boarding the train."  (description, line 800)
- "Go to the train platform (marked)"  (quest step, line 802)
- "Check three travelers' tickets: press E on citizens on the platform"  (quest step, line 803)
- "An old woman has a ticket, but no transit permit. "I'm going to see my son," she says. "He's in Nova Prospekt.""  (quest choice, line 804)
- "Let her board anyway (if you're caught, you're wanted)."  (text, line 805)

> Note for you (not shown in game): part of: success

- "She squeezes your hand on the way past. It's the last train she'll ever take, and you both know it."  (quest narration, line 809)

> Note for you (not shown in game): part of: fail

- "The platform scanner flags her before she reaches the door. And you, for letting her through: you're now wanted."  (quest narration, line 812)
- "Aiding unauthorized travel"  (text, line 813)
- "Refuse, and send her back."  (text, line 815)
- "Report her to Civil Protection."  (text, line 816)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report her"  (quest step, line 819)

> Note for you (not shown in game): a real body if the city has left one lying about, or a reported one

- "Go to the body {GetPos}"  (quest step, line 867)

> Note for you (not shown in game): part of: mortuary

- "A body was reported {GetPos}. Nobody has claimed it. Collect it and take it to the incinerator or morgue."  (description, line 884)
- "His coat pocket holds identity papers, still valid. Nobody has reported him dead yet."  (quest choice, line 888)
- "Hand everything in, papers included."  (text, line 889)
- "Keep his identity papers."  (text, line 890)

> Note for you (not shown in game): part of: pick

- "They're good papers. They'll be good for somebody."  (quest narration, line 893)

> Note for you (not shown in game): part of: mortuary

- "Tell his family before you take him away."  (text, line 895)

> Note for you (not shown in game): part of: pick

- "Go and tell his family: {homeName}"  (quest step, line 897)

> Note for you (not shown in game): part of: mortuary

- "Drag the body (press E on it to grab it, E again to let go) to the marked spot"  (text, line 900)
- "Drag %d bodies off the streets to %s (press E on a body to grab it, E again to let go)"  (message, line 914)
- "Clear the streets"  (title, line 917)
- "There's been trouble, and bodies are lying in the streets. Take them to the incinerator or morgue: the city wants them gone before morning."  (description, line 918)

> Note for you (not shown in game): part of: stages

- "Stay at the incinerator for 30 seconds to burn the bodies"  (quest step, line 927)
- "The incinerator runs all night, and somebody has to feed it the bodies. Go there and work it."  (description, line 931)
- "Go to the incinerator (marked)"  (quest step, line 933)
- "Go to the morgue (marked)"  (quest step, line 933)
- "The next body still has a wedding ring on."  (quest choice, line 935)
- "Leave the ring on her."  (text, line 936)
- "Keep the ring for yourself."  (text, line 937)
- "Set the ring aside for her family."  (text, line 941)
- "Find the dead headcrabs and press E on each one to bag it"  (text, line 966)
- "Take the bags to {name} (marked) to burn them"  (text, line 970)
- "Headcrab collection"  (title, line 973)
- "Dead headcrabs left lying in the street breed flies and worse. Bag every one, then take them to be burned."  (description, line 974)

> Note for you (not shown in game): Reclamation Crew

- "Scrap run"  (title, line 989)
- "Scrap metal is lying {GetPos}. Collect 5 pieces and bring them to the reclamation yard. The Union needs all of it."  (description, line 990)

> Note for you (not shown in game): part of: scrap

- "Collect the scrap: press E on each piece (5 in all)"  (text, line 993)
- "One good piece of copper wasn't on anybody's list."  (quest choice, line 994)
- "Log it with the rest."  (text, line 995)
- "Keep it to sell to the dealer (you get 2 scrap)."  (text, line 996)
- "Bring the scrap to the reclamation yard (marked)"  (text, line 1001)
- "Go to rubble pile %d of 3 (%s) and stay next to it to clear it"  (message, line 1010)
- "Under the bricks: a canvas bag. Inside, a pistol and a magazine wrapped in oilcloth. Someone hid it here on purpose."  (quest choice, line 1014)
- "Report the hidden gun to Civil Protection."  (text, line 1015)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report the gun"  (quest step, line 1018)
- "Leave it where it is."  (text, line 1020)
- "You put the bricks back exactly how they were."  (quest narration, line 1022)
- "Take the pistol (if a unit sees you take it, you're wanted)."  (text, line 1024)
- "A Civil Protection unit saw you pull the gun out of the rubble. You're now wanted."  (quest narration, line 1028)
- "Possession of a firearm"  (text, line 1029)
- "It's cold and heavy and nobody saw."  (quest narration, line 1031)
- "Rubble clearing"  (title, line 1035)
- "Clear three piles of rubble left over from the old city."  (description, line 1035)
- "Work the line: throw the bad parts (rust-red and sparking) in the scrap bin and let the good ones pass. E grabs a part, left click throws it"  (text, line 1100)

> Note for you (not shown in game): part of: litter

- "Street sweep"  (title, line 1110)
- "Take your cart from the sanitation depot, fill it with rubbish from the streets and bring it back. You're paid credits for every piece in the cart."  (description, line 1111)
- "Go to the sanitation depot (marked): your cart is there"  (text, line 1113)
- "Fill the cart and push it back to the depot. E on the cart grabs it to push (E again lets go). E picks up rubbish, left click throws it in the cart"  (text, line 1114)

> Note for you (not shown in game): part of: quota

- "On the line"  (title, line 1125)
- "Work the factory line: throw the bad parts in the scrap bin before they reach the end. Good parts go through."  (description, line 1126)
- "Go to the factory line (marked)"  (text, line 1127)

> Note for you (not shown in game): part of: seal

- "The sealing line"  (title, line 1136)
- "Ration bars and gel get sealed in foil here, thousands a day. Throw the split packs in the reject bin: only sealed ones go through."  (description, line 1137)
- "Go to the sealing line at the ration plant (marked)"  (text, line 1138)
- "Work the sealing line: throw split, leaking packs (sickly green) in the reject bin and let the sealed ones pass. E grabs a pack, left click throws it"  (text, line 1139)

> Note for you (not shown in game): The loading dock (two crates, a long walk each way) is the Intake Processor's work now; the factory floor gets more of the line instead (the owner: "an absolute grind").

- "Freight from the dock"  (description, line 1154)
- "Carry two crates, one at a time, from the loading dock to the station."  (text, line 1154)

> Note for you (not shown in game): part of: text

- "Overtime on the line"  (title, line 1166)
- "The quota went up again. Work the factory line: bad parts in the scrap bin, good ones through. The line doesn't stop for you."  (description, line 1167)
- "Go to the factory line (marked)"  (text, line 1168)
- "Overtime on the line"  (title, line 1172)
- "The quota went up again. Go to the factory line and work it."  (description, line 1172)
- "Go to the factory line (marked)"  (quest step, line 1173)
- "Stay at the line for 40 seconds to work it"  (quest step, line 1173)

> Note for you (not shown in game): Maintenance: every repair is a wiring panel

- "Rewire it: click the tiles to turn them (right-click turns back) until the current reaches the lamp. Don't turn a tile while it's sparking: it shocks you"  (text, line 1182)
- "the terminal"  (text, line 1183)
- "the box"  (text, line 1183)

> Note for you (not shown in game): Clinic Medic: rounds are triage

- "Patients are coming into the clinic faster than you can treat them. Treat the worst hurt first."  (description, line 1197)

> Note for you (not shown in game): part of: rounds

- "Go to the clinic (marked)"  (text, line 1199)
- "Heal the patients with your medkit (primary fire, left click) before they bleed out. The bar over each one's head shows who's worst"  (text, line 1200)

> Note for you (not shown in game): Reclamation Crew: rubble is something you break up

- "Break up the rubble: hit it with your crowbar (primary fire, left click)"  (text, line 1209)

> Note for you (not shown in game): part of: ticket

- "Check the travelers' papers: press E on each traveler, then approve, deny, or call a Civil Protection unit"  (text, line 1217)
- "Papers check"  (title, line 1218)
- "Check the papers and permits of everyone boarding the train. Today's rules are shown next to their papers."  (description, line 1220)

> Note for you (not shown in game): Courier: a parcel run against the clock (they aren't letters)

- "an apartment doorway"  (name, line 1235)

> Note for you (not shown in game): part of: desc

- "Parcel run"  (title, line 1244)
- "Deliver three parcels before time runs out: the faster you are, the more you're paid. They aren't letters, and nobody tells you what's in them."  (description, line 1245)
- "Go to the post office (marked) to collect the parcels"  (text, line 1247)
- "Deliver the parcels to the marked spots before time runs out. Civil Protection units stop couriers they get a good look at, so crouch when you pass them"  (text, line 1248)

> Note for you (not shown in game): part of: incinerator

- "Before the fire"  (title, line 1263)
- "Three bodies go in the incinerator tonight. Search every pocket first. The overseer checks on you now and then: don't get caught keeping anything."  (description, line 1264)
- "Go to the incinerator (marked)"  (text, line 1266)
- "Go to the morgue (marked)"  (text, line 1266)
- "Search each body before it goes in: press E on it, check every pocket, then put it in the fire"  (text, line 1267)
- "Sort the washed and pressed Civil Protection uniforms back to their own divisions. Civil Protection units leave things in their pockets."  (text, line 1282)
- "Go to the Nexus laundry (marked)"  (text, line 1283)
- "Put each uniform in its division's bin (the bins are labelled). Bloodstained ones go to the incident wash. If you close the window, press E to open it again"  (text, line 1283)
- "File the in-tray by citizen number. Any form that doesn't match the register goes in the discrepancy tray."  (text, line 1284)
- "Go to the civil records office (marked)"  (text, line 1285)
- "File every form in its drawer by citizen number. Forms that don't match the register go in the discrepancy tray. If you close the window, press E to open it again"  (text, line 1285)
- "Four radio sets on the shelf, all hissing. Tune each one to its station, then adjust its screws until the sound comes through clean."  (text, line 1286)
- "Go to the radio repair shop (marked)"  (text, line 1287)
- "Repair the sets: turn the dial to the station, then turn the screws while you listen, until the static is gone. If you close the window, press E to open it again"  (text, line 1287)

> Note for you (not shown in game): (tests: finish a game at once)

- "Union shift"  (name, line 1296)
- "Civil rehabilitation"  (name, line 1339)

> Note for you (not shown in game): part of: build

- "Community service: {desc}"  (title, line 1349)

## sh_livingcity_jobs.lua (sh_livingcity_jobs.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_jobs.lua`

- "Sanitation Worker"  (name, line 19)
- "Sanitation depot"  (text, line 19)
- "Pick up litter, empty bins and scrub off graffiti. The city must look clean, whatever it really is."  (description, line 20)
- "Ration Production"  (name, line 21)
- "Ration plant"  (text, line 21)
- "Seal ration packs on the line, count the packs against the register, and check ration cards at the counter, catching the forged ones. Nobody cooks here: rations are made in a factory, not cooked."  (description, line 22)
- "Clinic Medic"  (name, line 23)
- "Heal injured citizens with your medkit and write down how they got hurt. Sometimes you decide what goes in the report."  (description, line 24)
- "Factory Worker"  (name, line 25)
- "Work the factory line to meet the quota: throw out the bad parts, pass the good ones. Nobody asks what the parts are for."  (description, line 26)
- "Post office"  (text, line 27)
- "Deliver letters, parcels and sealed envelopes to people all over the district."  (description, line 28)
- "Maintenance Technician"  (name, line 29)
- "Maintenance yard"  (text, line 29)
- "Repair fuse boxes, streetlights and Combine terminals. You get to see what the terminals have logged."  (description, line 30)
- "Intake Processor"  (name, line 31)
- "Train station"  (text, line 31)
- "Check travelers' tickets and papers at the train station, return lost luggage, carry freight from the loading dock, and walk new arrivals to their housing."  (description, line 32)
- "Records Clerk"  (name, line 33)
- "Civil records office"  (text, line 33)
- "File forms by citizen number at the civil records office. The cabinet of blank identity forms is rarely locked."  (description, line 34)
- "Uniform Laundry"  (name, line 35)
- "Nexus laundry"  (text, line 35)
- "Sort washed and pressed Civil Protection uniforms by division. They're supposed to be counted, and usually are."  (description, line 36)
- "City morgue"  (text, line 37)
- "Collect bodies from the streets, search them and burn them in the incinerator. Nobody checks your work closely."  (description, line 38)
- "Reclamation Crew"  (name, line 39)
- "Reclamation yard"  (text, line 39)
- "Collect scrap metal and clear rubble from the old city. Some of what's buried there was hidden on purpose."  (description, line 40)
- "Radio Repair"  (name, line 41)
- "Radio repair shop"  (text, line 41)
- "Repair loudspeakers and Union radios. Some come in tuned to frequencies that aren't supposed to exist."  (description, line 42)

