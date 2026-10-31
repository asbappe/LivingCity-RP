## work you actually do (sv_livingcity_jobgames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_jobgames.lua`


> Note for you (not shown in game): community service is unpaid (sv_livingcity_work.lua): the work still counts

- "Paid %d credits for the work, on top of the shift."  (message, line 112)
- "Nothing extra for that."  (text, line 112)

> Note for you (not shown in game): What's under the wrapper: { item, weight } (credits for "coins")

- "A scrap of paper, folded small: 'Kleiner lives.' Underneath, a lambda."  (text, line 179)
- "A ration wrapper with a map drawn on the inside: the canal, and an X."  (text, line 180)
- "A note in a child's hand: 'Papa, they took the man from 4C. Come home the back way.'"  (text, line 181)
- "Half a Combine notice, the rest torn away: '...relocation of all residents of Block...'"  (text, line 182)

> Note for you (not shown in game): part of: start

- "Street sweep"  (title, line 216)

> Note for you (not shown in game): part of: lc on pickup

- "found in the rubbish"  (text, line 247)
- "[Sanitation] Wedged in it: %d credits in Union tokens. Finders keepers."  (message, line 248)
- "Found in the rubbish"  (on-screen notice, line 250)
- "[Sanitation] Tucked inside it: {what}. It's in your pockets."  (chat message, line 253)

> Note for you (not shown in game): part of: start

- "[Sanitation] Your cart's at the depot. E on it to push it (E again to let go). Pick up the rubbish with E and throw it in (left click). Bring the cart back when it's full."  (chat message, line 263)

> Note for you (not shown in game): part of: hud

- "In the cart: %d of %d"  (message, line 266)
- "Long throws: %d"  (message, line 267)
- "Full: push the cart back to the depot"  (text, line 268)
- "Pushing the cart (E to let go)"  (text, line 268)
- "E on the cart to push it"  (text, line 268)

> Note for you (not shown in game): part of: tick

- "Quick work: the foreman nods."  (text, line 301)
- "%d long throws into the cart."  (message, line 303)
- "Out of time: what's in the cart counts."  (text, line 308)

> Note for you (not shown in game): pressing a key

- "[Sanitation] You let go of the cart."  (chat message, line 323)

> Note for you (not shown in game): The same line, other work: the ration plant's sealing line (opts.variant = "rations").

- "On the line"  (title, line 349)
- "The line's starting. Rust-red, sparking parts are bad: grab them (E) and throw them in the scrap bin. Let the good ones go through. (R while holding a good one slips it into your coat: the dealer and the quartermaster buy them. Not where a unit can see, and the foreman counts.)"  (text, line 350)
- "Something rattles inside this one. R while you're holding it to slip it in your pocket."  (text, line 351)
- "The sealing line"  (title, line 352)
- "The sealing line's starting. Split, leaking packs (the sickly green ones) go in the reject bin: grab them (E) and throw them in. Sealed ones go through to the dispensers. (R while holding a sealed one slips it into your coat. Not where a unit can see, and the foreman counts.)"  (text, line 353)
- "This pack is heavier than a ration should be. R while you're holding it to slip it in your pocket."  (text, line 354)

> Note for you (not shown in game): part of: hud

- "Bad %s binned: %d    Good %s through: %d"  (message, line 423)
- "Bad %s let through: %d    Good %s binned: %d"  (message, line 424)

> Note for you (not shown in game): part of: tick

- "[Foreman] That one was good! Watch what you're binning."  (chat message, line 474)
- "[Foreman] A bad one went through! That comes out of your pay."  (chat message, line 477)

> Note for you (not shown in game): the foreman counts what went through: skim more than one and he may find it short

- "The foreman's count is %d short. It comes out of your pay, and he'll remember."  (message, line 514)
- "The count was short on your shift"  (text, line 515)

> Note for you (not shown in game): part of: tick

- "A clean shift: not a single mistake."  (text, line 519)
- "%d of %d bad parts caught; %d good parts through."  (message, line 521)

> Note for you (not shown in game): Skimming (sv_livingcity_funding.lua): R while holding a good part pockets it. A unit who sees it makes you wanted; and the more you take, the likelier the foreman finds the count short.

- "That one's scrap: nobody would buy it."  (chat message, line 540)

> Note for you (not shown in game): part of: line skim

- "Into your coat: {name}. The count will be one short."  (chat message, line 546)
- "Theft from the factory floor"  (text, line 548)
- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 549)

> Note for you (not shown in game): pressing a key

- "You work it open and palm what's inside: {what}."  (chat message, line 565)
- "Theft from the factory floor"  (text, line 567)
- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 568)

> Note for you (not shown in game): part of: rule lines

- "Papers must be in date."  (text, line 609)
- "The photo must be the bearer."  (text, line 609)

> Note for you (not shown in game): One traveler's papers, and what's wrong with them (if anything).

- "Anya Vasek"  (text, line 620)
- "Pavel Orlov"  (text, line 620)
- "Mira Kessler"  (text, line 620)
- "Tomas Hrabal"  (text, line 620)
- "Ilse Brandt"  (text, line 620)
- "Jonas Petrov"  (text, line 620)

> Note for you (not shown in game): part of: start

- "Papers check"  (title, line 687)
- "[Station] Travelers will come to you. E on one to check their papers against today's rules: approve, deny, or call a Civil Protection unit."  (chat message, line 694)

> Note for you (not shown in game): part of: hud

- "Travelers checked: %d of %d"  (message, line 696)
- "Right: %d    Citations: %d"  (message, line 696)
- "Today's rules:"  (text, line 696)
- "E on the traveler to see their papers"  (text, line 698)

> Note for you (not shown in game): part of: finish

- "Not a single citation."  (text, line 722)
- "%d of %d calls right."  (message, line 724)

> Note for you (not shown in game): The call: "approve", "deny" or "unit". True when it was right.

- "A forgery: the seal reads {seal}. A Civil Protection unit takes them away."  (text, line 780)

> Note for you (not shown in game): part of: papers decide

- "Denied. (The seal was forged: a Civil Protection unit would have wanted to know.)"  (text, line 782)
- "Approved forged papers (the seal read {seal})."  (text, line 786)
- "They walk through. Under their breath: 'Thank you.'"  (text, line 788)
- "Approved papers out of date."  (text, line 793)
- "Approved a traveler whose photo wasn't them."  (text, line 793)
- "Approved entry from {banned}."  (text, line 794)
- "Approved a traveler with no transit permit."  (text, line 794)
- "Approved work travel without a Union stamp."  (text, line 795)
- "Turned away a traveler whose papers were in order."  (text, line 799)
- "Pay docked."  (on-screen notice, line 806)
- "[Station] {note}"  (chat message, line 808)

> Note for you (not shown in game): part of: start

- "the panel"  (text, line 971)
- "the terminal"  (text, line 972)

> Note for you (not shown in game): part of: hud

- "Turns: %d (par %d)"  (message, line 981)
- "Blackout: double pay."  (text, line 982)

> Note for you (not shown in game): the breaker trips: a new board (and paid less)

- "[Maintenance] Too slow: the breaker trips and the board scrambles. Again."  (chat message, line 993)

> Note for you (not shown in game): part of: wire try

- "Neat work: on par."  (text, line 1044)
- "Blackout rates."  (text, line 1045)
- "Clean: not a spark."  (text, line 1047)

> Note for you (not shown in game): Triage (Clinic Medic): patients bleeding out at different rates. Treat them with the medkit (primary fire) before they're gone: the worst first.

- "Bleeding badly"  (label, line 1067)
- "Stab wound"  (label, line 1067)
- "Stunstick beating"  (label, line 1068)
- "Broken arm"  (label, line 1068)

> Note for you (not shown in game): part of: start

- "[Clinic] Patients coming in. Medkit, primary fire. The worst first: they won't all wait."  (chat message, line 1097)

> Note for you (not shown in game): part of: hud

- "Saved: %d    Lost: %d    Waiting: %d"  (message, line 1099)

> Note for you (not shown in game): part of: tick

- "[Clinic] You've lost one. {label}."  (chat message, line 1112)
- "[Clinic] You've lost one. {label}."  (chat message, line 1127)
- "[Clinic] He grabs your wrist on the way out. 'Thank you. Please... don't write down what did this.'"  (chat message, line 1135)
- "Everyone walked out."  (text, line 1147)
- "%d saved, %d lost."  (message, line 1148)

> Note for you (not shown in game): part of: start

- "[Reclamation] Break the pile up (crowbar, primary fire). Each block gives up a bit of scrap."  (chat message, line 1201)

> Note for you (not shown in game): part of: hud

- "Blocks broken: %d of %d"  (message, line 1202)
- "Crowbar, primary fire"  (text, line 1202)

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
- "Medicine, by the label. The label is in somebody's handwriting."  (text, line 74)
- "my mother's medicine"  (spoken line, line 74)
- "painkillers, a few days' worth, in a paper twist"  (text, line 74)
- "Books, by the weight. Nobody has said the word 'books' out loud in years."  (text, line 75)
- "books, the kind the Union burns"  (text, line 75)
- "A small parcel, neatly wrapped. It weighs almost nothing."  (text, line 76)
- "a letter and some socks for my son"  (spoken line, line 76)
- "a letter, and a pair of darned socks"  (text, line 76)

> Note for you (not shown in game): The sender: an honest one says what's in it; a silent one won't; a bold one owns up to contraband and offers more. The courier takes it, hands it back, reports the sender to a Civil Protection unit (only when they wouldn't say, or owned up), or opens it (Civil Standing, and half the pay: you opened somebody's mail).

- "You slit the tape and look. Inside: {inside}."  (text, line 87)
- "The sender says it's {or}."  (text, line 88)
- "You ask what's in it. 'Don't ask. Just get it there.'"  (text, line 89)
- "The sender leans in: 'It's not something a unit should see. {SMUGGLE_BONUS} credits extra when it gets there.'"  (text, line 90)

> Note for you (not shown in game): part of: parcel set off

- "Three to go, against the clock. Civil Protection units stop couriers they get a good look at: crouch past them, or stand still for the search."  (chat message, line 106)

> Note for you (not shown in game): part of: parcel way

- "The next parcel"  (text, line 112)

> Note for you (not shown in game): part of: start

- "Parcel run"  (title, line 117)
- "The cell's cargo, wrapped to look like nothing."  (text, line 122)
- "guns and ammunition for the cell"  (text, line 122)
- "Smuggling run"  (title, line 128)
- "The cell's cargo. Three drops, against the clock. Units search anyone who looks wrong: crouch past them, or stand still and hope."  (chat message, line 130)
- "Three to go, against the clock. Civil Protection units stop couriers they get a good look at: crouch past them, or stand still for the search."  (chat message, line 134)

> Note for you (not shown in game): the sender: honest about a harmless one most of the time; a hot one is never "honest"

- "The sender is waiting."  (text, line 143)
- "Take it, hand it back, report them, or open it (the window; E brings it back)"  (text, line 143)

> Note for you (not shown in game): part of: hud

- "Parcel %d of %d: %s"  (message, line 146)
- "Watched {heat}"  (text, line 148)
- "SEARCH: stand still (%d), or run"  (message, line 149)
- "A Civil Protection unit is looking at you. Crouch, or get out of sight."  (text, line 150)

> Note for you (not shown in game): part of: tick

- "Evading a search"  (text, line 162)
- "You ran"  (on-screen notice, line 163)
- "Every Civil Protection unit in the sector has your description now. Get the parcels there anyway."  (on-screen notice, line 163)
- "Carrying contraband"  (text, line 170)
- "A Civil Protection unit opened the parcel. It's evidence now, and so are you."  (text, line 171)
- "The Civil Protection unit turns it over, shakes it, and hands it back. 'Move along.'"  (chat message, line 175)
- "A Civil Protection unit wants to see the parcel. Stand still for the search, or run."  (on-screen notice, line 188)
- "Delivered, {or}. Nobody signs for these."  (chat message, line 195)
- "%d seconds to spare."  (message, line 201)
- "Never stopped once."  (text, line 205)
- "The cargo got through. The cell won't forget it."  (text, line 208)
- "a smuggling run"  (text, line 209)
- "The %d credits extra, as promised. You knew what you were carrying."  (message, line 212)
- "Whatever was in them, it got there."  (text, line 214)
- "You're late. The rest still has to get there."  (chat message, line 222)

> Note for you (not shown in game): part of: act

- "You hand it back. 'Find someone else.' No parcel, no pay."  (chat message, line 234)
- "reported a sender of contraband"  (text, line 244)
- "You hand the parcel to a Civil Protection unit and point out the sender. Contraband: the unit takes it from there."  (text, line 245)
- "reported a sender"  (text, line 247)
- "You hand it to a Civil Protection unit. Inside: {inside}. The unit isn't pleased to be bothered."  (text, line 248)
- "opened somebody's parcel"  (text, line 257)
- "You open it. Opening the mail costs you: Civil Standing, and half the pay if you deliver it."  (chat message, line 258)

> Note for you (not shown in game): part of: start

- "Records terminal"  (title, line 294)
- "the records terminal"  (text, line 295)
- "Stop the needle in the band (click, or space), four times. When the scanner comes over, keep your hands off the panel."  (chat message, line 311)

> Note for you (not shown in game): part of: hud

- "Bypassed: %d of %d"  (message, line 313)
- "Seen by the scanner: %d of 2"  (message, line 313)
- "SCANNER OVERHEAD: hands off"  (text, line 314)
- "Scanner coming..."  (text, line 314)

> Note for you (not shown in game): part of: act

- "Tampering with a Combine terminal"  (text, line 355)
- "The scanner saw you twice: the alarm's going. Get out."  (text, line 356)
- "The scanner's light catches your hands on the panel. Once more and it calls it in."  (chat message, line 361)
- "The scanner never saw a thing."  (text, line 373)

> Note for you (not shown in game): Dead drop (Resistance): hide it where nobody sees you do it

- "the bin"  (text, line 398)
- "the oil drum"  (text, line 398)
- "the box"  (text, line 399)
- "the crate"  (text, line 399)

> Note for you (not shown in game): part of: start

- "Dead drop"  (title, line 405)
- "Three places to leave it. E on one, then crouch and keep still. If anyone sees you at it, that one's burned."  (chat message, line 420)

> Note for you (not shown in game): part of: hud

- "Seen {seen}"  (text, line 422)
- "Places burned: %d of %d"  (message, line 422)
- "Crouch, close to it, to hide it"  (text, line 423)
- "Hiding it... {HIDE_SECS}%"  (text, line 423)
- "E on a hiding place (outlined)"  (text, line 424)

> Note for you (not shown in game): part of: tick

- "Someone saw you at {lcDropName}. Not that one: try another."  (on-screen notice, line 452)
- "Every place was watched. The message goes home with you."  (text, line 454)
- "Left in {lcDropName}."  (text, line 462)
- "Nobody looked twice."  (text, line 463)

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
- "Three for the fire tonight. E on the body: every pocket before it goes in. Log it, keep it, or set it aside for the family. The overseer looks in now and then."  (chat message, line 548)

> Note for you (not shown in game): part of: hud

- "Body %d of %d"  (message, line 550)
- "Logged: %d    Kept: %d"  (message, line 550)
- "The overseer is out of the room"  (text, line 551)
- "E on the body to search it"  (text, line 551)

> Note for you (not shown in game): part of: tick

- "The door opens. The overseer leans on the frame, watching you work."  (chat message, line 560)
- "The overseer goes back out. You're alone with them."  (chat message, line 562)

> Note for you (not shown in game): part of: act

- "logged contraband from the dead"  (text, line 580)
- "caught stealing from the dead"  (text, line 586)
- "The overseer clears his throat. 'In the tray.' It goes in the tray, and in his notebook."  (chat message, line 587)
- "%d logged, %d kept."  (message, line 602)
- "The overseer wrote your name down."  (text, line 603)
- "Into the fire. The next one's on the slab."  (chat message, line 607)

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

- "The shift ran out with uniforms still on the pile."  (text, line 665)

> Note for you (not shown in game): part of: act

- "a Civil Protection unit's pocket came back short"  (text, line 677)
- "The supervisor counts what comes out of the pockets. Tonight he counts one short, and looks at you."  (chat message, line 678)
- "turned in what a Civil Protection unit left in a pocket"  (text, line 683)
- "Whatever was in the pocket went in with it."  (chat message, line 693)
- "Not one in the wrong bin."  (text, line 696)
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

- "Forms left in the in-tray. They'll be there tomorrow."  (text, line 770)

> Note for you (not shown in game): part of: act

- "caught taking a blank identity form"  (text, line 780)
- "Theft of state forms"  (text, line 781)
- "A Civil Protection unit at the counter watches you put it back."  (chat message, line 782)
- "One blank identity form, folded into your sleeve."  (chat message, line 786)
- "A clean in-tray."  (text, line 800)
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

- "Every set on the shelf works."  (text, line 894)
- "%d of %d fixed."  (message, line 895)

> Note for you (not shown in game): part of: start

- "Radio repair"  (title, line 904)

> Note for you (not shown in game): part of: hud

- "Set %d of %d"  (message, line 909)
- "Find its station, then the screws: by ear"  (text, line 910)
- "%d seconds on this one"  (message, line 911)

> Note for you (not shown in game): part of: tick

- "Out of time: it goes back on the shelf, still hissing."  (chat message, line 918)

> Note for you (not shown in game): part of: act

- "It's there, but so faint you'd miss it. The volume trimmer."  (text, line 956)
- "It's there, under a wall of hiss. The squelch."  (text, line 957)
- "It's there, but smeared across the dial. The alignment."  (text, line 957)
- "reported an illegal broadcast"  (text, line 980)
- "You write the frequency on a slip for the Civil Protection units. Somebody will be listening for it now."  (chat message, line 982)
- "You copy it down where nobody will look: Freq 7, and the seven places on the dial it hides. A Freq 7 sheet, in your pockets (contraband: pass it on, or burn it)."  (chat message, line 988)
- "You tune past it. Nothing on this band is worth what it costs."  (chat message, line 991)

> Note for you (not shown in game): A Freq 7 sheet, read: the rule, and the seven frequencies it gives.

- "FREQ 7 /  / They only broadcast where the digits add up to seven. There are seven places on the dial: /  / {list} /  / {or}When the Combine find it, it moves: try the next one. /  / Listen low. Never where a unit can hear it."  (text, line 1006)

> Note for you (not shown in game): part of: read item

- "(in a cramped hand)"  (text, line 1013)

> Note for you (not shown in game): part of: listen off

- "[Radio] {why}"  (chat message, line 1059)

> Note for you (not shown in game): Listen (already on: the window again, where you left the dial; it has its own off switch).

- "Not in here."  (text, line 1067)

> Note for you (not shown in game): a timer (regularly)

- "Your radio's gone."  (text, line 1101)

> Note for you (not shown in game): the pirate band, out loud, where a unit can hear it

- "Listening to an illegal broadcast"  (text, line 1118)
- "A Civil Protection unit heard that"  (on-screen notice, line 1119)
- "Freq 7, out loud, in front of Civil Protection. Turn it off, or run."  (on-screen notice, line 1119)

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

- "They walk off lighter on their feet than they should."  (chat message, line 1164)
- "You hand it back. They don't say thank you; they don't dare."  (chat message, line 1165)
- "Confiscated: {what}. Logged as evidence."  (chat message, line 1171)
- "Detained with nothing on them. Dispatch is not impressed, and neither is the street."  (chat message, line 1182)
- "Every call right."  (text, line 1192)
- "%d searched, %d right."  (message, line 1193)

> Note for you (not shown in game): part of: start

- "Stop citizens on the street: E on one. Pat them down a place at a time before they lose their nerve. Watch their hands."  (chat message, line 1205)

> Note for you (not shown in game): part of: hud

- "Searched: %d of %d"  (message, line 1207)
- "Right calls: %d"  (message, line 1207)
- "Their nerve: %s"  (message, line 1208)
- "E on a citizen to stop them"  (text, line 1208)

> Note for you (not shown in game): part of: use

- "You searched that one already."  (chat message, line 1219)

> Note for you (not shown in game): part of: act

- "They lose their nerve and bolt."  (chat message, line 1260)
- "One bolted with something on them."  (text, line 1261)
- "%d searched, %d right."  (message, line 1265)

> Note for you (not shown in game): part of: room

- "Everyone on the floor: E on each of them before they run or get rid of something. Then search the place (E on the furniture)."  (chat message, line 1318)

> Note for you (not shown in game): part of: start

- "The door's locked. E on it to set the charge, then stand back."  (chat message, line 1336)

> Note for you (not shown in game): part of: hud

- "Charge set: stand back"  (text, line 1341)
- "E on the door to set the charge"  (text, line 1341)
- "On the floor: %d    Ran: %d    Still standing: %d"  (message, line 1346)
- "Found: %d    Flushed: %d    To search: %d"  (message, line 1347)

> Note for you (not shown in game): part of: use

- "Found: {what}."  (chat message, line 1375)
- "Ash, and the smell of burnt paper. Too late."  (chat message, line 1377)

> Note for you (not shown in game): part of: tick

- "Somebody's burning something. Whatever it was, it's gone."  (chat message, line 1410)
- "One of them's out the back."  (chat message, line 1416)
- "Nobody ran, nothing burned."  (text, line 1425)
- "%d on the floor, %d ran, %d found."  (message, line 1426)

