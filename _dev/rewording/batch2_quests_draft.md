## quests (sv_livingcity_quests.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_quests.lua`


> Note for you (not shown in game): Reading the world

- "hoarding ration units"  (text, line 141)
- "unauthorized assembly"  (text, line 141)
- "possession of contraband"  (text, line 141)
- "failing a loyalty check"  (text, line 141)
- "breaking curfew"  (text, line 142)
- "speaking out against the Combine"  (text, line 142)
- "trading ration units"  (text, line 142)
- "moving home without registering"  (text, line 142)
- "tampering with a city terminal"  (text, line 143)
- "harboring an anticitizen"  (text, line 143)

> Note for you (not shown in game): Half-Life 2 has no proper elderly citizen model; these are its older faces.

- "an unregistered radio"  (text, line 151)
- "a stash of ration units"  (text, line 152)
- "Resistance pamphlets"  (text, line 153)
- "a weapons cache"  (text, line 154)
- "The note says only: the canal gate opens at four."  (text, line 161)
- "A child's drawing of a lambda (the Resistance symbol) and an address. You memorize the address and burn the note."  (text, line 162)
- "Coordinates, and a single word: Ravenholm. You decide not to go."  (text, line 163)
- "A list of Civil Protection unit numbers. Two are crossed out."  (text, line 164)

> Note for you (not shown in game): part of: describe place

- "near {group}"  (text, line 178)
- "in rebel territory"  (text, line 180)
- "by the prison"  (text, line 182)
- "by the ration line"  (text, line 188)
- "at a checkpoint"  (text, line 189)
- "outside an apartment doorway"  (text, line 190)
- "%d metres %s of you"  (message, line 191)
- "somewhere in the city"  (text, line 192)

> Note for you (not shown in game): Somewhere safe for the Resistance: rebel territory if there is any, else far away.

- "rebel territory"  (text, line 490)

> Note for you (not shown in game): part of: narrate

- "[{board}] {text}"  (chat message, line 593)

> Note for you (not shown in game): part of: enter stage

- "the job's target couldn't be found"  (text, line 677)

> Note for you (not shown in game): part of: send state

- "%ds / %ds"  (message, line 741)
- "You can't remember what you were doing: Breen's water has clouded your memory. It comes back in about a minute."  (text, line 753)

> Note for you (not shown in game): Ticking quests

- "the person you were escorting is gone"  (text, line 780)

> Note for you (not shown in game): part of: poll

- "you ran out of time"  (text, line 909)
- "everyone left the job"  (text, line 911)
- "you were arrested"  (text, line 915)

> Note for you (not shown in game): follow someone: close enough to keep them in sight, far enough not to be noticed

- "the person you were following is gone"  (text, line 927)

> Note for you (not shown in game): suspicion builds while they can see you (or hear you right behind them) and fades while you're out of sight; only a full meter blows it

- "They keep glancing back: they're getting suspicious. Get out of their sight before they spot you."  (quest narration, line 945)

> Note for you (not shown in game): part of: poll

- "they noticed you following them"  (text, line 949)
- "you fell too far behind and lost them"  (text, line 953)
- "your target is gone"  (text, line 980)
- "Another Civil Protection unit arrested them first. You get half the reward."  (quest narration, line 986)

> Note for you (not shown in game): A ration break: rations are out mid-shift, so the job waits (its clock stopped, nothing failing for your being away) till you've had your ration, five minutes are up, or you go back to it. F1 > Take a ration break (or !rationbreak; !back to carry on).

- "You don't have a shift or job running, so there's nothing to take a break from."  (text, line 1005)
- "Rations aren't being handed out right now, so you can't take a ration break."  (text, line 1006)

> Note for you (not shown in game): part of: on break

- "[Work] Your ration break is over (five minutes at most). Your job's timer is running again."  (chat message, line 1021)

> Note for you (not shown in game): the game's living city ration collected moment

- "[Work] You've got your ration, so your break is over. Your job carries on from where you left it."  (chat message, line 1029)

> Note for you (not shown in game): the game's living city event started moment

- "Rations are being handed out"  (on-screen notice, line 1037)
- "To get your ration without failing your job, press F1 and choose Take a ration break. It pauses your job's timer until you've collected your ration (five minutes at most)."  (on-screen notice, line 1037)

> Note for you (not shown in game): the chat command /rationbreak

- "[Work] Ration break started. Your job's timer is paused until you collect your ration, for five minutes at most. Type /back to end the break early."  (chat message, line 1044)
- "[Work] {or}"  (text, line 1044)

> Note for you (not shown in game): the chat command /back

- "[Work] Break ended. Your job's timer is running again."  (chat message, line 1047)
- "[Work] You're not on a break."  (chat message, line 1047)

> Note for you (not shown in game): a timer (regularly)

- "something went wrong"  (text, line 1058)

> Note for you (not shown in game): Building blocks for templates

- "Choose what to do"  (text, line 1164)

> Note for you (not shown in game): part of: arrest stage

- "Detain them with the Arrest Baton (right click)"  (text, line 1208)

> Note for you (not shown in game): part of: build

- "Walk to patrol stop %d of %d, %s"  (message, line 1274)
- "Patrol sweep {GetPos}"  (title, line 1276)
- "Walk to each marked patrol stop in turn, so citizens see Civil Protection on the streets."  (description, line 1277)
- "Dispatch wants boots on the street. Yours will do."  (text, line 1278)
- "Overwatch reports elevated noncompliance. Show them the uniform."  (text, line 1278)
- "Civil status inspections"  (title, line 1289)
- "Stop %d citizens and %s. Nobody is above suspicion."  (message, line 1290)
- "pat them down"  (message, line 1290)
- "check their papers"  (message, line 1290)
- "Pat down %d citizens: walk up to one and press E, search them, then release them, confiscate what they carry, or detain them"  (message, line 1291)
- "Inspect citizens: walk up to one and press E"  (quest step, line 1292)
- "Apprehend citizen {id}"  (title, line 1304)
- "Citizen %s is wanted for %s. An informant has given you their location: they're marked on your screen."  (message, line 1305)
- "Find citizen {id} (marked on your screen)"  (text, line 1307)
- "Citizen %s freezes. Their eyes go to your baton, then to the street behind you."  (message, line 1308)
- "Detain them."  (text, line 1309)
- "Make them name their supplier."  (text, line 1310)

> Note for you (not shown in game): part of: success

- "They crack and tell you: there's {stash} hidden {GetPos}."  (quest narration, line 1313)
- "Find {stash} (marked) and press E on it to seize it"  (text, line 1317)

> Note for you (not shown in game): part of: fail

- "They shove past you and run! Catch them."  (quest narration, line 1320)

> Note for you (not shown in game): part of: build

- "Take their ration units as a bribe and let them go (ends the job, less XP)."  (text, line 1323)

> Note for you (not shown in game): part of: pick

- "The ration units are still warm from their pocket. Nobody will ever know. You will."  (quest narration, line 1328)

> Note for you (not shown in game): part of: build

- "Let them go (ends the job, no XP)."  (text, line 1331)

> Note for you (not shown in game): part of: pick

- "You look away. They're gone before you look back."  (quest narration, line 1336)

> Note for you (not shown in game): part of: build

- "Checkpoint duty {GetPos}"  (title, line 1353)
- "Go to the checkpoint and stand guard there until the timer is full. Nobody passes without being looked at."  (description, line 1354)
- "Go to the marked checkpoint"  (quest step, line 1355)
- "Stay at the checkpoint until the timer is full"  (quest step, line 1355)
- "Contraband sweep {GetPos}"  (title, line 1367)
- "An informant reports {kind} hidden around this area, in three places. Find and confiscate all three."  (description, line 1368)
- "Confiscate {kind}: find each one (marked) and press E on it"  (text, line 1370)
- "Disturbance {GetPos}"  (title, line 1382)
- "There's a disturbance nearby. Get there fast, then catch and arrest the suspect who runs."  (description, line 1383)
- "Hurry to the marked disturbance"  (quest step, line 1385)
- "Chase the suspect and arrest them with the Arrest Baton (right click)"  (text, line 1387)
- "Someone breaks from the crowd and runs! That's your suspect."  (text, line 1403)
- "Ration line supervision"  (title, line 1417)
- "Keep order at ration line {g} while rations are handed out."  (description, line 1418)
- "Go to ration line {g} (marked)"  (quest step, line 1420)
- "The line is restless. A woman at the front is shaking, and the man behind her keeps looking at your hands."  (quest choice, line 1421)
- "Keep order, by the book."  (text, line 1422)
- "Calm the line with a few quiet words."  (text, line 1423)

> Note for you (not shown in game): part of: success

- "The shaking stops. Somebody actually says thank you."  (quest narration, line 1427)

> Note for you (not shown in game): part of: fail

- "Someone spits near your boots. The line goes quiet anyway."  (quest narration, line 1429)

> Note for you (not shown in game): part of: build

- "Pocket a few ration units while nobody's counting."  (text, line 1430)
- "Stay near the front of the line while 3 citizens collect their rations"  (text, line 1434)
- "Go to the infested area (marked)"  (quest step, line 1459)

> Note for you (not shown in game): done when every infested thing in the area is down, not after a set number

- "Kill every infested creature in this area"  (quest step, line 1492)

> Note for you (not shown in game): part of: poll

- "Kill every infested creature in this area (%d left)"  (message, line 1495)
- "Area clear: every infested creature here is dead"  (text, line 1495)

> Note for you (not shown in game): a patch of it, gone, and quiet for a while

- "The infestation is pushed back: this part of the infested zone is cleared, and nothing will crawl back for a while."  (quest narration, line 1503)
- "Area clear. No infested creatures will appear here for a while."  (quest narration, line 1505)

> Note for you (not shown in game): part of: build

- "Containment {GetPos}"  (title, line 1509)
- "The infestation has spread into new ground. Go there and kill every infested creature to push it back."  (description, line 1510)
- "The infestation is active at its source. Go there and kill every infested creature before it spreads."  (description, line 1510)

> Note for you (not shown in game): the ground that was just taken, or the nearest piece of it

- "Go to the rebel-held ground {where} (marked)"  (quest step, line 1542)
- "Stay on the ground for 30 seconds to secure it"  (quest step, line 1544)

> Note for you (not shown in game): part of: on done

- "The ground is retaken: it's no longer rebel territory. Whatever they built here comes down by morning."  (quest narration, line 1547)

> Note for you (not shown in game): part of: build

- "Retake the block {where}"  (title, line 1550)
- "Anticitizens have taken over ground {where}. Go there, kill 3 of the rebels holding it, then stay on the ground for 30 seconds. Expect them to fight back."  (description, line 1551)
- "Kill 3 of the rebels holding the ground"  (quest step, line 1554)
- "Stay on the spot for 60 seconds. Civil Protection units will come to stop you."  (quest step, line 1578)

> Note for you (not shown in game): dispatch hears about it, and sends whoever is nearest to look

- "Dispatch: anticitizens gathering {where}. Nearby Civil Protection units, investigate."  (text, line 1581)

> Note for you (not shown in game): part of: on done

- "The ground is ours: it's rebel territory now. People are already moving in behind you."  (quest narration, line 1599)
- "You held it, but it can't be kept: the ground doesn't become rebel territory."  (quest narration, line 1599)

> Note for you (not shown in game): part of: build

- "Take ground {where}"  (title, line 1602)
- "We want the ground {where}. Get there and stay on it for a minute, and it becomes rebel territory. Civil Protection units will be sent to stop you."  (description, line 1603)
- "Go to the marked ground {where}"  (quest step, line 1604)
- "Steal the crate of Union supplies {where}: press E on it"  (text, line 1629)

> Note for you (not shown in game): part of: on done

- "Theft of Union supplies"  (text, line 1633)
- "A Civil Protection unit saw you take it. You're wanted now: run."  (quest narration, line 1634)
- "Nobody saw you take it. Walk, don't run."  (quest narration, line 1636)

> Note for you (not shown in game): word gets out: units can follow the smuggler on their screens (sv_livingcity_resistanceops.lua)

- "Take it to the Resistance supply crate in rebel territory (marked)"  (text, line 1641)
- "You add six meals to the Resistance supply crate. It now holds %d."  (message, line 1644)

> Note for you (not shown in game): and ammunition, packed under the food

- "There was ammunition packed under the food. Everyone on the job gets a box."  (quest narration, line 1649)
- "Supply run {where}"  (title, line 1652)
- "The Resistance's food stores are low. The Union keeps supplies {where}. Steal a crate and bring it to the Resistance supply crate in rebel territory."  (description, line 1653)

> Note for you (not shown in game): part of: build

- "Find the crate a contact left {where} and press E to break it open"  (text, line 1683)

> Note for you (not shown in game): part of: on done

- "You break the crate open and put the supplies in your pockets. A search will find them, so don't get stopped."  (quest narration, line 1688)
- "The crate breaks open, but your pockets are full. Make room in your pockets (F2), then pick the supplies up off the ground."  (quest narration, line 1691)

> Note for you (not shown in game): part of: build

- "Take the supplies home to {homeName}"  (text, line 1695)
- "Take the supplies to the Resistance quartermaster (marked)"  (text, line 1695)

> Note for you (not shown in game): (the supplies; or a whole crate, from before crates were broken open)

- "You arrived without the supplies, so there's no reward. Somebody's going to want to know where they went."  (quest narration, line 1702)

> Note for you (not shown in game): part of: on done

- "Inside: 3 gun parts and some chemicals, now in your pockets. Craft them into something worth selling."  (quest narration, line 1709)
- "gun run"  (text, line 1711)
- "The quartermaster counts the guns, then counts out sixty credits. 'Same again, soon.'"  (quest narration, line 1713)

> Note for you (not shown in game): part of: build

- "Parts pickup {where}"  (text, line 1717)
- "Gun run {where}"  (text, line 1717)
- "A smuggler has left gun parts for you {where}. Pick them up and take them home without getting searched."  (text, line 1718)
- "A crate of guns is waiting {where}. Get it to the Resistance quartermaster and you're paid sixty credits."  (text, line 1719)
- "Take over detainee {id} from the Civil Protection unit holding them {place}: walk up to them (marked)"  (text, line 1742)

> Note for you (not shown in game): the handover; then he's back on his beat

- "The Civil Protection unit nods at the detainee. 'All yours.' He heads back to his beat."  (quest narration, line 1767)

> Note for you (not shown in game): part of: build

- "Detainee transfer: {id}"  (title, line 1773)
- "A Civil Protection unit is holding citizen {id} {place} and has been called away. Take over the detainee, choose how to handle them, then arrest them with the Arrest Baton (right click) to send them to the cells."  (description, line 1774)
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
- "Go into rebel territory and stay alive inside it for sixty seconds. Expect rebels to fight back."  (description, line 1811)

> Note for you (not shown in game): {

- "Go into the marked rebel territory"  (quest step, line 1814)

> Note for you (not shown in game): part of: build

- "Stay alive inside rebel territory for 60 seconds"  (text, line 1818)
- "Address the citizens"  (title, line 1832)
- "The people need to hear their Administrator. Go to the plaza, speak to the crowd, then choose how to end your speech."  (description, line 1833)
- "Go to the plaza (marked)"  (quest step, line 1835)
- "Stay there for 40 seconds while you give your speech"  (quest step, line 1836)
- "The crowd watches you in silence. How do you end it?"  (quest choice, line 1837)
- "Announce additional rations (starts a ration handout)."  (text, line 1838)
- "Remind them of their duty to the city (starts an inspection sweep)."  (text, line 1842)
- "Declare a curfew, effective immediately (starts a curfew)."  (text, line 1846)
- "Review the Civil Protection units"  (title, line 1862)
- "Check on Civil Protection in person: find units on the street and talk to them."  (description, line 1863)
- "Talk to Civil Protection units: walk up to one and press E"  (quest step, line 1864)

> Note for you (not shown in game): Resistance: Operations

- "Supply run"  (title, line 1880)

> Note for you (not shown in game): part of: build

- "A contact has a crate of medical supplies for you {GetPos}. Bring it to the Resistance's safe spot: {where}."  (description, line 1881)
- "Find your contact (marked) and press E on them to take the crate"  (text, line 1883)
- "'Don't thank me. Don't look back, either.'"  (text, line 1883)
- "The crate is heavier than it should be. There's a Civil Protection unit posted at the end of the street."  (quest choice, line 1884)
- "Walk it out in plain sight."  (text, line 1885)
- "Bury it under a coat and some laundry."  (text, line 1886)

> Note for you (not shown in game): part of: success

- "Nobody looks twice at a tired citizen with laundry."  (quest narration, line 1887)

> Note for you (not shown in game): part of: fail

- "A Civil Protection unit shouts after you. You're wanted now: run!"  (quest narration, line 1889)
- "Carrying contraband"  (text, line 1890)

> Note for you (not shown in game): part of: build

- "Find the quartermaster at the safe spot ({where}) and press E on him to hand over the crate"  (text, line 1893)
- "He's already prying the lid up. 'Good. We needed this yesterday.'"  (text, line 1893)
- "Post flyer %d of 3 %s: crouch at the marked spot for 3 seconds"  (message, line 1906)

> Note for you (not shown in game): part of: on done

- "A Civil Protection unit saw you put that up. You're wanted now."  (quest narration, line 1912)
- "Distributing propaganda"  (text, line 1913)

> Note for you (not shown in game): part of: build

- "Paper the walls"  (title, line 1918)
- "Put up three Resistance flyers in three marked places. If a Civil Protection unit sees you putting one up, you become wanted."  (description, line 1919)
- "Go to the marked checkpoint and crouch there for 5 seconds to plant the charge"  (quest step, line 1931)

> Note for you (not shown in game): part of: on done

- "The checkpoint goes up in a shower of sparks. You're wanted now, and every Civil Protection unit in the sector heard that."  (quest narration, line 1940)

> Note for you (not shown in game): part of: build

- "Sabotage {GetPos}"  (title, line 1943)
- "Blow up the checkpoint to put it out of action for five minutes, then escape to safety."  (description, line 1944)
- "Escape: get to the safe spot ({where})"  (text, line 1945)
- "Jailbreak: {id}"  (title, line 1961)
- "Citizen {id} was arrested last night, and they know too much to stay in a cell. Break them out of prison and lead them to safety."  (description, line 1962)
- "Go to their cell in the prison (marked) and press E on them to break them out"  (text, line 1965)

> Note for you (not shown in game): part of: on done

- "Aiding an escape"  (text, line 1978)
- "The lock gives. You're wanted for this now, and the alarms won't stay quiet for long. Move."  (quest narration, line 1979)

> Note for you (not shown in game): part of: build

- "Lead them to the safe spot ({where}): they follow you"  (text, line 1982)
- "Sound out the neighbors"  (title, line 1995)
- "Find three citizens who might be ready to join the Resistance, and talk to them where no Civil Protection unit can see you."  (description, line 1996)
- "Talk to 3 citizens (walk up and press E) where no Civil Protection unit can see you"  (quest step, line 1997)

> Note for you (not shown in game): count

- "[Operations] A Civil Protection unit can see you, so that didn't count. Move somewhere out of sight."  (chat message, line 2000)

> Note for you (not shown in game): part of: build

- "Dead drop"  (title, line 2015)
- "Meet a contact at the meeting point, then hide a message at the drop for the Resistance to find."  (description, line 2016)
- "Go to the marked meeting point {GetPos}"  (quest step, line 2018)
- "Wait at the meeting point for 20 seconds for your contact"  (quest step, line 2019)
- "Your contact doesn't come. Instead, a child walks past and presses a folded note into your hand."  (quest choice, line 2020)
- "Read it."  (text, line 2021)
- "Burn it unread."  (text, line 2022)

> Note for you (not shown in game): part of: pick

- "Some things are safer not known."  (quest narration, line 2022)

> Note for you (not shown in game): part of: build

- "Take the message to the marked drop {GetPos}"  (text, line 2024)
- "Go to the marked drop {GetPos} to leave the message"  (quest step, line 2025)
- "Hide the message: press E on one of the three marked hiding places, then crouch and keep still. If anyone sees you doing it, that hiding place is ruined."  (text, line 2026)
- "the drop {from}"  (name, line 2045)
- "Smuggling run"  (title, line 2048)
- "Take the Resistance cell's cargo (guns and ammunition) to three drops around the city. If a Civil Protection unit searches you, they'll find it."  (description, line 2049)
- "Go to the quartermaster (marked) to collect the cargo"  (text, line 2051)
- "Go to the marked spot to collect the cargo"  (text, line 2051)
- "Deliver the cargo to the three marked drops before time runs out. Crouch to sneak past Civil Protection units, or stand still for their search and hope for the best"  (text, line 2052)
- "the civil records terminal"  (text, line 2070)
- "the Combine console"  (text, line 2070)
- "a records terminal"  (text, line 2072)

> Note for you (not shown in game): one of ours with a record (or whoever did it, if nobody else has one)

- "[Operations] A Resistance member wiped your record from the Combine's terminals: you're no longer wanted."  (chat message, line 2084)

> Note for you (not shown in game): part of: wipe

- "[Operations] You wiped {Nick}'s record: they're no longer wanted."  (chat message, line 2085)
- "[Operations] Nobody of ours was wanted, so you wiped three names from the registers instead. The scanner never noticed."  (chat message, line 2087)

> Note for you (not shown in game): part of: build

- "Doctor the records"  (title, line 2091)
- "Some of ours are wanted by the Combine. Hack into {what} {GetPos} and wipe a wanted Resistance member's record."  (description, line 2092)
- "Go to {what} {GetPos} (marked)"  (text, line 2094)
- "Hack the terminal: stop the moving needle inside the band (click or space) four times. When the scanner passes over, stop touching the panel"  (text, line 2095)
- "Ambush a patrol"  (title, line 2106)
- "For fighters only. Kill two Civil Protection units, then get away."  (description, line 2107)
- "Kill 2 Civil Protection units"  (quest step, line 2108)
- "Someone on a Civil Protection wanted list is hiding {GetPos}. Find them and lead them to safety."  (description, line 2125)
- "Find the fugitive (marked on your screen)"  (text, line 2128)
- "Lead them to the safe spot ({safe}): they follow you"  (text, line 2138)
- "The ministry"  (title, line 2150)
- "Tend to your flock: comfort a grieving woman, heal three wounded people with The Blessing, and preach once. The Combine call it unlawful worship. You call it Sunday."  (description, line 2151)
- "A woman catches your sleeve. Her husband was taken last night. She asks you to pray with her, here, in the open."  (quest choice, line 2153)
- "Pray with her where she stands (if a Civil Protection unit sees, you become wanted)."  (text, line 2154)

> Note for you (not shown in game): part of: pick

- "You finish the prayer. Then you hear the boots: a Civil Protection unit saw you, and you're wanted now."  (quest narration, line 2158)
- "Unlawful worship"  (text, line 2159)
- "She holds your hand through all of it. Nobody comes."  (quest narration, line 2161)

> Note for you (not shown in game): part of: build

- "Promise to pray for him tonight, somewhere safe."  (text, line 2164)

> Note for you (not shown in game): part of: success

- "She nods. It's enough. For now it's enough."  (quest narration, line 2165)

> Note for you (not shown in game): part of: fail

- "She lets go of your sleeve and doesn't look back."  (quest narration, line 2166)

> Note for you (not shown in game): part of: build

- "Heal 3 different wounded people with The Blessing (primary fire)"  (quest step, line 2168)
- "Preach the Word: hold The Blessing and press reload where people can hear"  (quest step, line 2169)

> Note for you (not shown in game): Citizens: Assignments

- "Collect your ration"  (title, line 2186)

> Note for you (not shown in game): part of: build

- "Your ration is ready. Go to ration line {g} and wait at the front to collect it."  (description, line 2187)
- "Go to ration line {g} (marked)"  (quest step, line 2188)
- "Stand at the front of the line for 10 seconds"  (quest step, line 2188)
- "Union work order: sanitation"  (title, line 2199)
- "Pick up four pieces of litter {GetPos}. A clean city is a compliant city."  (description, line 2200)
- "Pick up the litter: press E on each marked piece"  (text, line 2202)
- "Find her cousin {GetPos} (marked) and press E on them to hand over the parcel"  (text, line 2228)
- "'From Kleiner? Tell her I'm fine.' It's not true, and you both know it."  (text, line 2229)
- "A neighbor's errand"  (title, line 2231)
- "Mrs. Kleiner from the third floor needs a parcel carried across the district. Collect it from her inside the housing block, then deliver it to her cousin."  (description, line 2232)
- "Mrs. Kleiner from the third floor needs a parcel carried across the district. Collect it from her, then deliver it to her cousin."  (description, line 2233)
- "Find Mrs. Kleiner inside the housing block (marked) and press E on her"  (text, line 2235)
- "Find Mrs. Kleiner (marked) and press E on her"  (text, line 2235)
- "'It's only a little parcel. It's gone to the third floor and back already.' She presses it into your hands."  (text, line 2236)
- "The parcel is taped shut. It's light, and something inside slides when you tilt it."  (quest choice, line 2237)
- "Deliver it unopened."  (text, line 2238)
- "Peel back the tape and look."  (text, line 2239)

> Note for you (not shown in game): part of: success

- "Resistance pamphlets. Your hands are suddenly cold."  (quest choice, line 2241)
- "Deliver it anyway."  (text, line 2242)
- "Hand it to Civil Protection instead."  (text, line 2243)

> Note for you (not shown in game): part of: pick

- "Hand the parcel to a Civil Protection unit: walk up to one and press E"  (quest step, line 2246)

> Note for you (not shown in game): part of: fail

- "The tape tears loudly. Better just deliver it, and fast."  (quest narration, line 2250)

> Note for you (not shown in game): part of: build

- "the dumpster"  (text, line 2277)
- "the bins"  (text, line 2277)
- "Two people swap a bundle behind {noun}. One has a lambda scratched into his sleeve."  (text, line 2278)
- "Walk over to {noun} (marked), casually"  (quest step, line 2279)
- "Something you saw"  (title, line 2329)
- "Neighbors whisper about something going on behind {or}{GetPos}. Go and see what it is."  (description, line 2330)
- "Stay nearby and watch quietly for 6 seconds"  (quest step, line 2333)
- "Report it to a Civil Protection unit."  (text, line 2335)

> Note for you (not shown in game): part of: pick

- "Tell a Civil Protection unit: walk up to one and press E"  (quest step, line 2338)

> Note for you (not shown in game): part of: build

- "Keep it to yourself (ends the job, little XP)."  (text, line 2340)

> Note for you (not shown in game): part of: pick

- "You saw nothing. You'll keep seeing nothing."  (quest narration, line 2344)

> Note for you (not shown in game): part of: build

- "his doorway"  (text, line 2366)
- "The confused old man"  (title, line 2369)
- "An old man is wandering {GetPos}, asking everyone for directions. Find him and walk him home."  (description, line 2370)
- "Find the old man (marked on your screen)"  (text, line 2373)
- "He doesn't remember his block number. He keeps asking for his daughter."  (quest choice, line 2385)
- "Calm him down first."  (text, line 2386)

> Note for you (not shown in game): part of: success

- "He takes your arm. His hand is light as paper."  (quest narration, line 2387)

> Note for you (not shown in game): part of: fail

- "He shuffles after you anyway, still asking."  (quest narration, line 2388)

> Note for you (not shown in game): part of: build

- "Just lead the way."  (text, line 2389)
- "Walk him home to {homeName}. He follows you, slowly."  (text, line 2391)
- "Loyalty check"  (title, line 2404)
- "You've been summoned for a routine loyalty check. Go to the checkpoint and present yourself to a Civil Protection officer."  (description, line 2405)
- "Go to the marked checkpoint"  (quest step, line 2407)
- "Present yourself to a Civil Protection officer: walk up to one and press E"  (quest step, line 2408)
- "The officer's mask tilts. Where were you last night, citizen?"  (quest choice, line 2409)
- "Tell the truth."  (text, line 2410)
- "Give a smooth, boring alibi."  (text, line 2411)

> Note for you (not shown in game): part of: success

- "He waves you through. Boring is safe."  (quest narration, line 2412)

> Note for you (not shown in game): part of: fail

- "He doesn't buy it. You're wanted now for failing a loyalty check."  (quest narration, line 2414)
- "Failing a loyalty check"  (text, line 2415)

> Note for you (not shown in game): The Infested: Urges

- "Kill 2 citizens"  (quest step, line 2434)

> Note for you (not shown in game): part of: build

- "Get close to 4 different citizens (they'll run from you)"  (quest step, line 2446)
- "Scare the living: get close to four different citizens."  (description, line 2459)
- "Leave the infested zones and survive outside them for two minutes."  (description, line 2469)
- "Stay alive outside the infested zones for 2 minutes"  (text, line 2470)

> Note for you (not shown in game): part of: advance chain

- "[Story] You turned down {name}. It comes back to your board (F3) in about 30 minutes."  (chat message, line 2571)
- "[Story] {name} has ended. {ending}"  (chat message, line 2575)
- "Story %s ended for %s: %s"  (message, line 2576)
- "[Story] {name} continues.{or}"  (chat message, line 2583)
- "[Story] {name} has ended."  (chat message, line 2586)
- "[Story] {name}: that part failed. You can try it again: it comes back to your board (F3)."  (chat message, line 2591)

> Note for you (not shown in game): part of: check unlocks

- "[Story] A new story is available. Check your job board (F3)."  (chat message, line 2606)

> Note for you (not shown in game): part of: build

- "Housing block inspection: {name}"  (title, line 2751)
- "The raid team is searching {name}. Back them up: inspect the residents, then guard the block until the search is done."  (description, line 2752)
- "Go to {name} (marked)"  (text, line 2754)
- "Breach and search: press E on the locked door to set the charge and stand back, press E on each resident to put them on the floor, then press E on the furniture to search it"  (text, line 2755)
- "Go to {name} (marked)"  (quest step, line 2757)
- "Inspect 3 residents of {name}: walk up to each one and press E"  (text, line 2759)
- "Stay at the block for 45 seconds while the team finishes the search"  (quest step, line 2764)
- "Dispatch: all units, {name} is under inspection. Nobody leaves without papers."  (text, line 2766)
- "Clear the streets: go to stop %d of %d, %s"  (message, line 2778)
- "Stay on this street for 60 seconds. Anyone still outside gets three warnings before they become wanted"  (quest step, line 2779)
- "Curfew enforcement"  (title, line 2781)
- "Curfew is in effect. Walk to each marked stop, moving people along as you go, then stay at the last stop for 60 seconds."  (description, line 2782)
- "Lockdown: hold the perimeter {GetPos}"  (title, line 2795)
- "Lockdown is in effect. Go to your post and guard it for 90 seconds, or until the lockdown lifts. Nobody moves through your sector."  (description, line 2796)
- "Go to your marked post"  (quest step, line 2797)
- "Stay at your post for 90 seconds"  (quest step, line 2797)
- "Warn {name}"  (title, line 2810)
- "Civil Protection units are about to search {name}. Get there first and warn three residents to move what they're hiding."  (description, line 2811)
- "Get to {name} (marked) before the Civil Protection units do"  (quest step, line 2813)
- "Warn 3 residents: walk up to each one and press E"  (text, line 2815)
- "Run supplies under curfew"  (title, line 2848)
- "The streets are empty and the Civil Protection units are busy. A contact left a crate {GetPos}. Pick it up and bring it to the safe spot: {toName}."  (description, line 2849)
- "Find the crate (marked) and press E to pick it up"  (text, line 2852)
- "Bring it to the safe spot ({toName})"  (text, line 2853)

> Note for you (not shown in game): part of: post directive

- "[%s] New job: %s. Take it from your job board (F3). Up to %d people can work on it together."  (message, line 2990)

> Note for you (not shown in game): whoever got stuck in gets paid; whoever hadn't started hasn't failed; a count left short (residents warned, people stopped) wasn't done

- "the event ended with only %d of %d done"  (message, line 3020)
- "The event is over. Good work: the job counts as done."  (quest narration, line 3022)

> Note for you (not shown in game): the game's living city event ended moment

- "the event ended before you got started, so it doesn't count against you"  (text, line 3025)

> Note for you (not shown in game): part of: send board

- "[Living City] Quests are turned off on this server."  (chat message, line 3044)

> Note for you (not shown in game): part of: accept posting

- "[Living City] Finish or abandon your current job first."  (chat message, line 3083)
- "[Living City] You have to wait before taking another job. Next job in {CurTime}s."  (chat message, line 3085)
- "[Living City] That job is no longer available."  (chat message, line 3094)
- "[Living City] Stalkers can only do stalker work. You can't take this job."  (chat message, line 3097)
- "[Living City] That job has enough people."  (chat message, line 3104)
- "has joined the job."  (quest narration, line 3107)
- "[{board}] {title}. {or}"  (chat message, line 3129)
- "Quest accepted: %s [%s] by %s"  (message, line 3131)

> Note for you (not shown in game): part of: abandon quest

- "left the job."  (quest narration, line 3145)

> Note for you (not shown in game): part of: resolve choice

- "%s check: rolled %d + %d skill = %d, needed %d. %s"  (message, line 3163)

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

