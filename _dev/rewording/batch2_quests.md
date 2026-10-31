## quests (sv_livingcity_quests.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_quests.lua`


> Note for you (not shown in game): Reading the world

- "hoarding ration units"  (text, line 141)
- "unauthorized assembly"  (text, line 141)
- "possession of contraband"  (text, line 141)
- "failing a loyalty check"  (text, line 141)
- "breaking curfew"  (text, line 142)
- "anti-civil remarks"  (text, line 142)
- "trading ration units"  (text, line 142)
- "unregistered relocation"  (text, line 142)
- "tampering with a city terminal"  (text, line 143)
- "harboring an anticitizen"  (text, line 143)

> Note for you (not shown in game): Half-Life 2 has no proper elderly citizen model; these are its older faces.

- "an unregistered radio"  (text, line 151)
- "a stash of ration units"  (text, line 152)
- "Resistance pamphlets"  (text, line 153)
- "a weapons cache"  (text, line 154)
- "The note says only: the canal gate opens at four."  (text, line 161)
- "A child's drawing of a lambda, and an address you memorize and burn."  (text, line 162)
- "Coordinates, and a single word: Ravenholm. You decide not to go."  (text, line 163)
- "A list of Civil Protection unit numbers. Two are crossed out."  (text, line 164)

> Note for you (not shown in game): part of: describe place

- "near {group}"  (text, line 178)
- "in rebel territory"  (text, line 180)
- "by the prison"  (text, line 182)
- "by the ration line"  (text, line 188)
- "at a checkpoint"  (text, line 189)
- "outside an apartment doorway"  (text, line 190)
- "%d m %s of you"  (message, line 191)
- "somewhere in the city"  (text, line 192)

> Note for you (not shown in game): Somewhere safe for the Resistance: rebel territory if there is any, else far away.

- "rebel territory"  (text, line 490)

> Note for you (not shown in game): part of: narrate

- "[{board}] {text}"  (chat message, line 593)

> Note for you (not shown in game): part of: enter stage

- "the trail went cold"  (text, line 677)

> Note for you (not shown in game): part of: send state

- "%ds / %ds"  (message, line 741)
- "You can't quite remember what you were doing."  (text, line 753)

> Note for you (not shown in game): Ticking quests

- "you lost them"  (text, line 780)

> Note for you (not shown in game): part of: poll

- "out of time"  (text, line 909)
- "nobody left on the job"  (text, line 911)
- "taken into custody"  (text, line 915)

> Note for you (not shown in game): follow someone: close enough to keep them in sight, far enough not to be noticed

- "you lost them"  (text, line 927)

> Note for you (not shown in game): suspicion builds while they can see you (or hear you right behind them) and fades while you're out of sight; only a full meter blows it

- "They keep glancing back. Get out of sight."  (quest narration, line 945)

> Note for you (not shown in game): part of: poll

- "they spotted you"  (text, line 949)
- "you lost them"  (text, line 953)
- "the target is gone"  (text, line 980)
- "Another Civil Protection unit brought them in. Credit shared."  (quest narration, line 986)

> Note for you (not shown in game): A ration break: rations are out mid-shift, so the job waits (its clock stopped, nothing failing for your being away) till you've had your ration, five minutes are up, or you go back to it. F1 > Take a ration break (or !rationbreak; !back to carry on).

- "You've no shift or job on to step away from."  (text, line 1005)
- "Rations aren't out right now."  (text, line 1006)

> Note for you (not shown in game): part of: on break

- "[Work] Break's over. Back to it."  (chat message, line 1021)

> Note for you (not shown in game): the game's living city ration collected moment

- "[Work] Ration in hand. Back to the job: it's waiting where you left it."  (chat message, line 1029)

> Note for you (not shown in game): the game's living city event started moment

- "Rations are out"  (on-screen notice, line 1037)
- "Your shift can wait: F1 > Take a ration break (it pauses the job till you've had your ration)."  (on-screen notice, line 1037)

> Note for you (not shown in game): the chat command /rationbreak

- "[Work] You step away for your ration. The job waits (five minutes at most)."  (chat message, line 1044)
- "[Work] {or}"  (text, line 1044)

> Note for you (not shown in game): the chat command /back

- "[Work] Back to it."  (chat message, line 1047)
- "[Work] You're not on a break."  (chat message, line 1047)

> Note for you (not shown in game): a timer (regularly)

- "something went wrong"  (text, line 1058)

> Note for you (not shown in game): Building blocks for templates

- "Decide what to do"  (text, line 1164)

> Note for you (not shown in game): part of: arrest stage

- "Detain them with the Arrest Baton (right click)"  (text, line 1208)

> Note for you (not shown in game): part of: build

- "Patrol stop %d of %d, %s"  (message, line 1274)
- "Patrol sweep {GetPos}"  (title, line 1276)
- "Walk the route and be seen. Visibility is the deterrent."  (description, line 1277)
- "Dispatch wants boots on the street. Yours will do."  (text, line 1278)
- "Overwatch reports elevated noncompliance. Show them the uniform."  (text, line 1278)
- "Civil status inspections"  (title, line 1289)
- "Stop %d citizens and %s. Nobody is above suspicion."  (message, line 1290)
- "pat them down"  (message, line 1290)
- "check their papers"  (message, line 1290)
- "Stop %d citizens and pat them down (E on one): release, confiscate or detain"  (message, line 1291)
- "Stop citizens for inspection (walk up and press E)"  (quest step, line 1292)
- "Apprehend citizen {id}"  (title, line 1304)
- "Citizen %s is wanted for %s. An informant has marked them for you."  (message, line 1305)
- "Find citizen {id} (marked)"  (text, line 1307)
- "Citizen %s freezes. Their eyes go to your baton, then to the street behind you."  (message, line 1308)
- "Detain them."  (text, line 1309)
- "Make them name their supplier."  (text, line 1310)

> Note for you (not shown in game): part of: success

- "They crack. There's {stash} {GetPos}."  (quest narration, line 1313)
- "Seize {stash} (press E)"  (text, line 1317)

> Note for you (not shown in game): part of: fail

- "They shove past you and run!"  (quest narration, line 1320)

> Note for you (not shown in game): part of: build

- "Take their ration units and walk away."  (text, line 1323)

> Note for you (not shown in game): part of: pick

- "The Civil Protection units are warm from their pocket. Nobody will ever know. You will."  (quest narration, line 1328)

> Note for you (not shown in game): part of: build

- "Let them go."  (text, line 1331)

> Note for you (not shown in game): part of: pick

- "You look away. They're gone before you look back."  (quest narration, line 1336)

> Note for you (not shown in game): part of: build

- "Checkpoint duty {GetPos}"  (title, line 1353)
- "Hold the checkpoint. Nobody passes without being looked at."  (description, line 1354)
- "Report to the checkpoint"  (quest step, line 1355)
- "Hold the checkpoint"  (quest step, line 1355)
- "Contraband sweep {GetPos}"  (title, line 1367)
- "An informant reports {kind} hidden around the area. Find all three."  (description, line 1368)
- "Confiscate {kind} (press E)"  (text, line 1370)
- "Disturbance {GetPos}"  (title, line 1382)
- "Reports of a disturbance. Respond quickly."  (description, line 1383)
- "Respond to the disturbance (hurry)"  (quest step, line 1385)
- "Catch the suspect and detain them"  (text, line 1387)
- "Someone breaks from the crowd and runs!"  (text, line 1403)
- "Ration line supervision"  (title, line 1417)
- "Keep order at ration line {g} while Civil Protection units are distributed."  (description, line 1418)
- "Report to ration line {g}"  (quest step, line 1420)
- "The line is restless. A woman at the front is shaking, and the man behind her keeps looking at your hands."  (quest choice, line 1421)
- "Keep order, by the book."  (text, line 1422)
- "Calm the line with a few quiet words."  (text, line 1423)

> Note for you (not shown in game): part of: success

- "The shaking stops. Somebody actually says thank you."  (quest narration, line 1427)

> Note for you (not shown in game): part of: fail

- "Someone spits near your boots. The line goes quiet anyway."  (quest narration, line 1429)

> Note for you (not shown in game): part of: build

- "Pocket a few ration units while nobody's counting."  (text, line 1430)
- "Supervise the distribution (stay near the front)"  (text, line 1434)
- "Reach the infestation"  (quest step, line 1459)

> Note for you (not shown in game): done when every infested thing in the area is down, not after a set number

- "Clear out every infested thing here"  (quest step, line 1492)

> Note for you (not shown in game): part of: poll

- "Clear out every infested thing here (%d left)"  (message, line 1495)
- "Area clear"  (text, line 1495)

> Note for you (not shown in game): a patch of it, gone, and quiet for a while

- "The line holds. This part of the infestation is contained, and nothing will crawl back for a while."  (quest narration, line 1503)
- "Area clear. Nothing will crawl back here for a while."  (quest narration, line 1505)

> Note for you (not shown in game): part of: build

- "Containment {GetPos}"  (title, line 1509)
- "The infestation has spread past the line. Push it back."  (description, line 1510)
- "Infestation activity at the source. Thin it out before it spreads."  (description, line 1510)

> Note for you (not shown in game): the ground that was just taken, or the nearest piece of it

- "Move on the rebel-held ground {where}"  (quest step, line 1542)
- "Hold the ground until it's secure"  (quest step, line 1544)

> Note for you (not shown in game): part of: on done

- "The ground is retaken. Whatever they built here comes down by morning."  (quest narration, line 1547)

> Note for you (not shown in game): part of: build

- "Retake the block {where}"  (title, line 1550)
- "Anticitizens have taken ground {where}. Clear them out and hold it. Expect them to fight."  (description, line 1551)
- "Neutralize the anticitizens holding it"  (quest step, line 1554)
- "Hold the ground. Stay close; they'll come"  (quest step, line 1578)

> Note for you (not shown in game): dispatch hears about it, and sends whoever is nearest to look

- "Dispatch: anticitizens gathering {where}. Nearby Civil Protection units, investigate."  (text, line 1581)

> Note for you (not shown in game): part of: on done

- "The ground is ours. People are already moving in behind you."  (quest narration, line 1599)
- "You held it, but there's no holding it for long."  (quest narration, line 1599)

> Note for you (not shown in game): part of: build

- "Take ground {where}"  (title, line 1602)
- "We want the ground {where}. Get there and hold it for a minute, and it's ours. The Combine will notice."  (description, line 1603)
- "Get to the ground we want {where}"  (quest step, line 1604)
- "Steal a crate of Union supplies {where} (press E)"  (text, line 1629)

> Note for you (not shown in game): part of: on done

- "Theft of Union supplies"  (text, line 1633)
- "A Civil Protection unit saw you take it. Run."  (quest narration, line 1634)
- "Nobody saw. Walk, don't run."  (quest narration, line 1636)

> Note for you (not shown in game): word gets out: units can follow the smuggler on their screens (sv_livingcity_resistanceops.lua)

- "Get it to the Resistance stores in rebel territory"  (text, line 1641)
- "Six meals' worth, into the crate. %d stored now."  (message, line 1644)

> Note for you (not shown in game): and ammunition, packed under the food

- "There was ammunition packed under the tins. Everyone gets a box."  (quest narration, line 1649)
- "Supply run {where}"  (title, line 1652)
- "The stores are low. The Union keeps food {where}. Take a crate and bring it home."  (description, line 1653)

> Note for you (not shown in game): part of: build

- "Break open the crate from a contact {where} (press E)"  (text, line 1683)

> Note for you (not shown in game): part of: on done

- "The crate breaks open. The supplies are in your pockets now. Searches will find them. Don't get stopped."  (quest narration, line 1688)
- "The crate breaks open, but your pockets are full. Make room (F2) and pick the supplies up."  (quest narration, line 1691)

> Note for you (not shown in game): part of: build

- "Get it home to {homeName}"  (text, line 1695)
- "Get it to the Resistance quartermaster"  (text, line 1695)

> Note for you (not shown in game): (the supplies; or a whole crate, from before crates were broken open)

- "You got there with empty pockets. Somebody's going to want to know where it went."  (quest narration, line 1702)

> Note for you (not shown in game): part of: on done

- "Gun parts, and something to clean them with. Make something worth selling."  (quest narration, line 1709)
- "gun run"  (text, line 1711)
- "The quartermaster counts the guns, then counts out sixty credits. 'Same again, soon.'"  (quest narration, line 1713)

> Note for you (not shown in game): part of: build

- "Parts pickup {where}"  (text, line 1717)
- "Gun run {where}"  (text, line 1717)
- "A smuggler has gun parts for you {where}. Get them home without being searched."  (text, line 1718)
- "A crate of guns {where} needs to reach the Resistance quartermaster. Sixty credits if it gets there."  (text, line 1719)
- "Collect detainee {id} from the Civil Protection unit holding them {place} (walk up to them)"  (text, line 1742)

> Note for you (not shown in game): the handover; then he's back on his beat

- "The Civil Protection unit nods at the detainee. 'All yours.' He heads back to his beat."  (quest narration, line 1767)

> Note for you (not shown in game): part of: build

- "Detainee transfer: {id}"  (title, line 1773)
- "A Civil Protection unit is holding citizen {id} {place} and has been called away. Collect the detainee, decide what to do with them, then detain them with the Arrest Baton to send them to the cells."  (description, line 1774)
- "The detainee was flagged by an informant. They swear they've done nothing, and their voice is steady."  (quest choice, line 1777)
- "Process them."  (text, line 1778)
- "Hear them out."  (text, line 1779)

> Note for you (not shown in game): part of: success

- "Their story holds. The informant owed them money. You note it in the file. It won't matter."  (quest narration, line 1783)

> Note for you (not shown in game): part of: fail

- "Halfway through, they contradict themselves. You stop listening."  (quest narration, line 1785)

> Note for you (not shown in game): part of: build

- "Lean on them for names."  (text, line 1786)

> Note for you (not shown in game): part of: success

- "Two names. You'll see them on a directive soon."  (quest narration, line 1790)

> Note for you (not shown in game): part of: fail

- "They go silent. Smarter than they look."  (quest narration, line 1792)

> Note for you (not shown in game): part of: build

- "Detain them with the Arrest Baton (right click) to send them to the cells"  (text, line 1794)

> Note for you (not shown in game): Overwatch: Protocols    Administrator: Agenda

- "Incursion {GetPos}"  (title, line 1810)
- "Enter anticitizen territory and hold it. Sixty seconds."  (description, line 1811)

> Note for you (not shown in game): {

- "Enter rebel territory"  (quest step, line 1814)

> Note for you (not shown in game): part of: build

- "Hold position inside rebel territory"  (text, line 1818)
- "Address the citizens"  (title, line 1832)
- "The people need to hear their Administrator. Go out among them."  (description, line 1833)
- "Go to the plaza"  (quest step, line 1835)
- "Deliver your address"  (quest step, line 1836)
- "The crowd watches you in silence. How do you end it?"  (quest choice, line 1837)
- "Announce additional rations."  (text, line 1838)
- "Remind them of their duty to the city."  (text, line 1842)
- "Declare a curfew. Effective immediately."  (text, line 1846)
- "Review the Civil Protection units"  (title, line 1862)
- "See for yourself that Civil Protection is doing its job."  (description, line 1863)
- "Speak with Civil Protection units (press E)"  (quest step, line 1864)

> Note for you (not shown in game): Resistance: Operations

- "Supply run"  (title, line 1880)

> Note for you (not shown in game): part of: build

- "A crate of medical supplies is waiting {GetPos}. Bring it home to {where}."  (description, line 1881)
- "Meet your contact and take the crate (press E)"  (text, line 1883)
- "'Don't thank me. Don't look back, either.'"  (text, line 1883)
- "The crate is heavier than it should be. There's a Civil Protection unit posted at the end of the street."  (quest choice, line 1884)
- "Walk it out in plain sight."  (text, line 1885)
- "Bury it under a coat and some laundry."  (text, line 1886)

> Note for you (not shown in game): part of: success

- "Nobody looks twice at a tired citizen with laundry."  (quest narration, line 1887)

> Note for you (not shown in game): part of: fail

- "A Civil Protection unit shouts after you. Run!"  (quest narration, line 1889)
- "Carrying contraband"  (text, line 1890)

> Note for you (not shown in game): part of: build

- "Hand it to the quartermaster at {where} (press E)"  (text, line 1893)
- "He's already prying the lid up. 'Good. We needed this yesterday.'"  (text, line 1893)
- "Post flyer %d of 3 %s (crouch at the spot)"  (message, line 1906)

> Note for you (not shown in game): part of: on done

- "A Civil Protection unit saw that."  (quest narration, line 1912)
- "Distributing propaganda"  (text, line 1913)

> Note for you (not shown in game): part of: build

- "Paper the walls"  (title, line 1918)
- "Three flyers, three places people will see them. Don't get seen putting them up."  (description, line 1919)
- "Plant the charge at the checkpoint (crouch)"  (quest step, line 1931)

> Note for you (not shown in game): part of: on done

- "The checkpoint goes up in a shower of sparks. Every Civil Protection unit in the sector heard that."  (quest narration, line 1940)

> Note for you (not shown in game): part of: build

- "Sabotage {GetPos}"  (title, line 1943)
- "Take that checkpoint offline for a while, then get clear."  (description, line 1944)
- "Get clear: reach {where}"  (text, line 1945)
- "Jailbreak: {id}"  (title, line 1961)
- "Citizen {id} was taken last night. They know too much to stay in there."  (description, line 1962)
- "Break them out (press E on them in their cell)"  (text, line 1965)

> Note for you (not shown in game): part of: on done

- "Aiding an escape"  (text, line 1978)
- "The lock gives. Alarms don't, yet. Move."  (quest narration, line 1979)

> Note for you (not shown in game): part of: build

- "Get them to {where}"  (text, line 1982)
- "Sound out the neighbors"  (title, line 1995)
- "Find three people who might be ready. Talk to them where Civil Protection can't see."  (description, line 1996)
- "Quietly talk to citizens (press E) away from Civil Protection"  (quest step, line 1997)

> Note for you (not shown in game): count

- "[Operations] A Civil Protection unit is watching. Not here."  (chat message, line 2000)

> Note for you (not shown in game): part of: build

- "Dead drop"  (title, line 2015)
- "Meet a contact, then leave a message where it'll be found."  (description, line 2016)
- "Go to the meeting point {GetPos}"  (quest step, line 2018)
- "Wait for your contact"  (quest step, line 2019)
- "Your contact doesn't come. Instead, a child walks past and presses a folded note into your hand."  (quest choice, line 2020)
- "Read it."  (text, line 2021)
- "Burn it unread."  (text, line 2022)

> Note for you (not shown in game): part of: pick

- "Some things are safer not known."  (quest narration, line 2022)

> Note for you (not shown in game): part of: build

- "Take the message to the drop {GetPos}"  (text, line 2024)
- "Leave the message {GetPos}"  (quest step, line 2025)
- "Hide the message where nobody sees you do it: E on a hiding place, then crouch and keep still"  (text, line 2026)
- "the drop {from}"  (name, line 2045)
- "Smuggling run"  (title, line 2048)
- "The cell's cargo: guns and ammunition, out to three drops in the city. You know what's in it, and so will any unit who searches you."  (description, line 2049)
- "Collect the cargo from the quartermaster"  (text, line 2051)
- "Collect the cargo"  (text, line 2051)
- "Get the cargo to the three drops (marked) against the clock: crouch past the units, or stand still for a search and hope"  (text, line 2052)
- "the civil records terminal"  (text, line 2070)
- "the Combine console"  (text, line 2070)
- "a records terminal"  (text, line 2072)

> Note for you (not shown in game): one of ours with a record (or whoever did it, if nobody else has one)

- "[Operations] Your record is gone from the Combine's terminals. Somebody of ours did that."  (chat message, line 2084)

> Note for you (not shown in game): part of: wipe

- "[Operations] {Nick}'s record is gone."  (chat message, line 2085)
- "[Operations] Three names gone from the registers, and the scanner none the wiser."  (chat message, line 2087)

> Note for you (not shown in game): part of: build

- "Doctor the records"  (title, line 2091)
- "Some of ours are in the Combine's records. Get into {what} {GetPos} and make them disappear."  (description, line 2092)
- "Go to {what} {GetPos}"  (text, line 2094)
- "Get into the terminal: stop the needle in the band, and keep your hands off while the scanner passes"  (text, line 2095)
- "Ambush a patrol"  (title, line 2106)
- "Fighters only. Take down two Civil Protection units and disappear."  (description, line 2107)
- "Take down Civil Protection units"  (quest step, line 2108)
- "Someone on a CP list is hiding {GetPos}. Bring them in."  (description, line 2125)
- "Find the fugitive (marked)"  (text, line 2128)
- "Lead them to {safe}"  (text, line 2138)
- "The ministry"  (title, line 2150)
- "Tend to your flock. The Combine call it contraband. You call it Sunday."  (description, line 2151)
- "A woman catches your sleeve. Her husband was taken last night. She asks you to pray with her, here, in the open."  (quest choice, line 2153)
- "Pray with her where she stands."  (text, line 2154)

> Note for you (not shown in game): part of: pick

- "You finish the prayer. Then you hear the boots."  (quest narration, line 2158)
- "Unlawful worship"  (text, line 2159)
- "She holds your hand through all of it. Nobody comes."  (quest narration, line 2161)

> Note for you (not shown in game): part of: build

- "Promise to pray for him tonight, somewhere safe."  (text, line 2164)

> Note for you (not shown in game): part of: success

- "She nods. It's enough. For now it's enough."  (quest narration, line 2165)

> Note for you (not shown in game): part of: fail

- "She lets go of your sleeve and doesn't look back."  (quest narration, line 2166)

> Note for you (not shown in game): part of: build

- "Tend to the wounded with The Blessing"  (quest step, line 2168)
- "Preach the Word (reload) where people can hear"  (quest step, line 2169)

> Note for you (not shown in game): Citizens: Assignments

- "Collect your ration"  (title, line 2186)

> Note for you (not shown in game): part of: build

- "Your ration allocation is ready at line {g}."  (description, line 2187)
- "Go to ration line {g}"  (quest step, line 2188)
- "Wait at the front of the line"  (quest step, line 2188)
- "Union work order: sanitation"  (title, line 2199)
- "Clear the litter {GetPos}. A clean city is a compliant city."  (description, line 2200)
- "Pick up the litter (press E)"  (text, line 2202)
- "Give the parcel to her cousin {GetPos} (press E)"  (text, line 2228)
- "'From Kleiner? Tell her I'm fine.' It's not true, and you both know it."  (text, line 2229)
- "A neighbor's errand"  (title, line 2231)
- "Mrs. Kleiner from the third floor has left a parcel in the block, to be carried across the district."  (description, line 2232)
- "Mrs. Kleiner from the third floor needs a parcel carried across the district."  (description, line 2233)
- "Speak to Mrs. Kleiner inside the block (press E)"  (text, line 2235)
- "Speak to Mrs. Kleiner (press E)"  (text, line 2235)
- "'It's only a little parcel. It's gone to the third floor and back already.' She presses it into your hands."  (text, line 2236)
- "The parcel is taped shut. It's light, and something inside slides when you tilt it."  (quest choice, line 2237)
- "Deliver it unopened."  (text, line 2238)
- "Peel back the tape and look."  (text, line 2239)

> Note for you (not shown in game): part of: success

- "Resistance pamphlets. Your hands are suddenly cold."  (quest choice, line 2241)
- "Deliver it anyway."  (text, line 2242)
- "Hand it to Civil Protection instead."  (text, line 2243)

> Note for you (not shown in game): part of: pick

- "Hand it to a Civil Protection unit (press E)"  (quest step, line 2246)

> Note for you (not shown in game): part of: fail

- "The tape tears loudly. Better just deliver it, and fast."  (quest narration, line 2250)

> Note for you (not shown in game): part of: build

- "the dumpster"  (text, line 2277)
- "the bins"  (text, line 2277)
- "Two people swap a bundle behind {noun}. One has a lambda scratched into his sleeve."  (text, line 2278)
- "Go over to {noun}, casually"  (quest step, line 2279)
- "Something you saw"  (title, line 2329)
- "Neighbors whisper about something going on behind {or}{GetPos}."  (description, line 2330)
- "Watch quietly"  (quest step, line 2333)
- "Report it to a Civil Protection unit."  (text, line 2335)

> Note for you (not shown in game): part of: pick

- "Tell a Civil Protection unit (press E)"  (quest step, line 2338)

> Note for you (not shown in game): part of: build

- "Keep it to yourself."  (text, line 2340)

> Note for you (not shown in game): part of: pick

- "You saw nothing. You'll keep seeing nothing."  (quest narration, line 2344)

> Note for you (not shown in game): part of: build

- "his doorway"  (text, line 2366)
- "The confused old man"  (title, line 2369)
- "An old man is wandering {GetPos}, asking everyone for directions."  (description, line 2370)
- "Find the old man (marked)"  (text, line 2373)
- "He doesn't remember his block number. He keeps asking for his daughter."  (quest choice, line 2385)
- "Calm him down first."  (text, line 2386)

> Note for you (not shown in game): part of: success

- "He takes your arm. His hand is light as paper."  (quest narration, line 2387)

> Note for you (not shown in game): part of: fail

- "He shuffles after you anyway, still asking."  (quest narration, line 2388)

> Note for you (not shown in game): part of: build

- "Just lead the way."  (text, line 2389)
- "Walk him home to {homeName}"  (text, line 2391)
- "Loyalty check"  (title, line 2404)
- "You've been summoned to a checkpoint for a routine loyalty check."  (description, line 2405)
- "Report to the checkpoint"  (quest step, line 2407)
- "Present yourself to an officer (press E)"  (quest step, line 2408)
- "The officer's mask tilts. Where were you last night, citizen?"  (quest choice, line 2409)
- "Tell the truth."  (text, line 2410)
- "Give a smooth, boring alibi."  (text, line 2411)

> Note for you (not shown in game): part of: success

- "He waves you through. Boring is safe."  (quest narration, line 2412)

> Note for you (not shown in game): part of: fail

- "He doesn't buy it."  (quest narration, line 2414)
- "Failing a loyalty check"  (text, line 2415)

> Note for you (not shown in game): The Infested: Urges

- "Feed on citizens"  (quest step, line 2434)

> Note for you (not shown in game): part of: build

- "Get close to the living (they'll scatter)"  (quest step, line 2446)
- "Let them see you."  (description, line 2459)
- "Leave the nest. Stay out."  (description, line 2469)
- "Stay out of the infestation zones"  (text, line 2470)

> Note for you (not shown in game): part of: advance chain

- "[Story] {name}: maybe another time."  (chat message, line 2571)
- "[Story] {name} has ended. {ending}"  (chat message, line 2575)
- "Story %s ended for %s: %s"  (message, line 2576)
- "[Story] {name} continues.{or}"  (chat message, line 2583)
- "[Story] {name} has ended."  (chat message, line 2586)
- "[Story] {name}: that didn't go to plan. You'll get another chance."  (chat message, line 2591)

> Note for you (not shown in game): part of: check unlocks

- "[Story] Something has changed. Check your board (F3)."  (chat message, line 2606)

> Note for you (not shown in game): part of: build

- "Housing block inspection: {name}"  (title, line 2751)
- "The raid team is going through {name}. Back them up: stop residents and check their papers, then hold the entrance until it's done."  (description, line 2752)
- "Report to {name}"  (text, line 2754)
- "Breach and search: blow the door, everyone on the floor (E), then search the furniture (E)"  (text, line 2755)
- "Report to {name}"  (quest step, line 2757)
- "Inspect residents of {name} (walk up and press E)"  (text, line 2759)
- "Hold the block until the team is through"  (quest step, line 2764)
- "Dispatch: all units, {name} is under inspection. Nobody leaves without papers."  (text, line 2766)
- "Clear the street, stop %d of %d, %s"  (message, line 2778)
- "Hold the street: anyone still out gets three warnings"  (quest step, line 2779)
- "Curfew enforcement"  (title, line 2781)
- "Curfew is in effect. Walk the streets, move people along, and hold your position until it's quiet."  (description, line 2782)
- "Lockdown: hold the perimeter {GetPos}"  (title, line 2795)
- "Lockdown is in effect. Nobody moves through your sector. Hold it until it lifts."  (description, line 2796)
- "Take up position"  (quest step, line 2797)
- "Hold the perimeter"  (quest step, line 2797)
- "Warn {name}"  (title, line 2810)
- "Civil Protection units are going through {name}. Get there first and tell people to move what they're hiding."  (description, line 2811)
- "Get to {name} before the Civil Protection units do"  (quest step, line 2813)
- "Warn residents (walk up and press E)"  (text, line 2815)
- "Run supplies under curfew"  (title, line 2848)
- "The streets are empty and the Civil Protection units are busy. A contact left a crate {GetPos}. Get it to {toName}."  (description, line 2849)
- "Pick up the crate (press E)"  (text, line 2852)
- "Bring it to {toName}"  (text, line 2853)

> Note for you (not shown in game): part of: post directive

- "[%s] New: %s. Take it from your board (F3); up to %d of you can work it together."  (message, line 2990)

> Note for you (not shown in game): whoever got stuck in gets paid; whoever hadn't started hasn't failed; a count left short (residents warned, people stopped) wasn't done

- "it's over, and only %d of %d done"  (message, line 3020)
- "It's over. Good work."  (quest narration, line 3022)

> Note for you (not shown in game): the game's living city event ended moment

- "it's over before you got there; no harm done"  (text, line 3025)

> Note for you (not shown in game): part of: send board

- "[Living City] Quests are turned off on this server."  (chat message, line 3044)

> Note for you (not shown in game): part of: accept posting

- "[Living City] Finish or abandon your current job first."  (chat message, line 3083)
- "[Living City] Take a breath. Next job in {CurTime}s."  (chat message, line 3085)
- "[Living City] That posting is gone."  (chat message, line 3094)
- "[Living City] A stalker does the work it's given, and nothing else."  (chat message, line 3097)
- "[Living City] That job has enough people."  (chat message, line 3104)
- "has joined."  (quest narration, line 3107)
- "[{board}] {title}. {or}"  (chat message, line 3129)
- "Quest accepted: %s [%s] by %s"  (message, line 3131)

> Note for you (not shown in game): part of: abandon quest

- "left the job."  (quest narration, line 3145)

> Note for you (not shown in game): part of: resolve choice

- "%s check: rolled %d + %d = %d against %d. %s"  (message, line 3163)

> Note for you (not shown in game): the console command lcq_startchain

- "[Story] Chains: {ids}. Usage: lcq_startchain <chain> [player]"  (text, line 3215)
- "[Story] Player not found."  (text, line 3217)
- "[Story] {name} is ready on {Nick}'s board (F3)."  (text, line 3222)

> Note for you (not shown in game): the console command lcq_story

- "[Story] Player not found."  (text, line 3229)
- "[Story] %s: loyalty %d, sympathy %d, corruption %d"  (message, line 3231)
- "counters: {or}"  (text, line 3235)
- "ended ({done})"  (text, line 3237)
- "at {part}"  (text, line 3237)

> Note for you (not shown in game): the console command lcq_resetstory

- "[Story] Your story has been reset."  (chat message, line 3249)

