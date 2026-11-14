# Playtest archive (the whole old list, sorted on 14 November 2026)

This was `PLAYTEST.md` until 14 November 2026: every item written since the start, in the order it was added (newest last). It is kept for reference. **The list to play from is `PLAYTEST.md`, a short card cut from this one.** An item the card calls "old line N" is at line N + 18 of this file.

Every unticked item was sorted that day (the tag in square brackets at the end of its line):

- **400 ticked as "a test proves it"**: an automated test checks the same behaviour, and the tag names the test. Nothing to play.
- **100 ticked as "replaced"**: a later change or a later item took its place; the tag says which.
- **326 "needs a person"**: only eyes and ears can judge it (look, sound, feel, pacing). These feed the card.
- **79 "needs the real server"**: recordings, FastDL, Workshop models, real players. These feed the card too.
- **39 "unsorted"**: could not be told either way.

The sorting was done by reading each item against the list of tests (`_dev/tests_index.txt`). It is a guide, not a proof: if something ticked here misbehaves on the server, say so and it goes back on the card.

New items are no longer added here by habit. A thing a test can prove gets a test. A thing only a person can judge goes on the card (`PLAYTEST.md`) while it has room (about 15 items), and otherwise at the end of this file with the tag `[needs a person: why]`.

---

# Playtest checklist

Updated 14 November 2026. **Part 1** is everything new since your 1 November playtest: try those first. **Part 2** is older items (from 8 October on); skip any you've already checked.
Tick a box when you've tried it, and write what you saw after **Notes:** (works, broken, feels off, ideas).

## Your 13 November notes: fixed, please try again (14 November)
- [ ] **The heartbeat (and every sound that loops by itself):** get hurt below 35 health so the heartbeat starts, then die or have a close call and respawn: is it silent? Does any other sound keep going after a respawn? [needs a person: Ear: is any sound still looping after a respawn on a real client]
  Notes:
- [ ] **Guns on rebel ground as a unit:** as a prison guard or any unit, walk into rebel territory: no "LOWER YOUR WEAPON" prompt, and every gun fires. Toggle !build there and sleep in their bed, as you did: still firing? [needs a person: No test found for a unit's guns on rebel ground; try it]
  Notes:
- [x] **Repel the attack at a checkpoint:** take it, kill attackers on the way and with your squad: do all of them count? When Dispatch says the attack is over, does the job complete instead of sticking at 1 of 2? [a test proves it: PlaytestNov13Tests (quest kills kept) and PlaytestNov14Tests (every attacker counted)]
  Notes:
- [ ] **Chevrons:** as a unit with a job in rebel territory (and as a rebel with one on Combine ground): does the trail go round the walls now? [needs a person: Real map: does the trail go round the walls]
  Notes:
- [ ] **The Cremator:** does it appear by the infestation? Does it really walk faster (about twice a stalker's pace)? No more cremator error in the debug report? [needs a person: Its walk and where it appears on the real map (pace rule tested)]
  Notes:
- [x] **Action music:** standing around near a job or a skirmish: silence? Fire three shots, or get shot: does it start within a few seconds, and stop soon after? [replaced: Rule changed again: an enemy hit twice, or you are hit (line 1940)]
  Notes:
- [ ] **Eerie music:** do Ravenholm's and the spooky pieces only come up by the infestation, and fade when you walk away? [needs a person: Ear: eerie music only by the infestation, fading as you leave]
  Notes:
- [ ] **Call for backup:** units from further off: do they come in from out of sight about 15 seconds later (Dispatch says so)? Down and bleeding out with units of your squad near: does one kneel by you and get you up? [needs a person: Real map: backup arriving from out of sight, and the kneel to revive]
  Notes:
- [ ] **Commissary screen:** 20% larger? Previous page and Next page side by side on the bottom row, on every page? [needs a person: Screen size and button layout by eye]
  Notes:
- [ ] **Quartermaster and dealer:** buy something halfway down the list: does it stay there? Is the bypass charge's description wrapped beside the button? Do the extra goods have different lines, not all "Off the back of a Union lorry"? [needs a person: List scroll and text wrap on screen (dealer lines tested)]
  Notes:
- [ ] **Ammo boxes and health vials:** with full ammo, Load on a box: refused, the box kept? At full health, E on a health vial on the ground: into your pockets? [needs a person: Ammo box is tested (PlaytestNov13Tests); vial pickup into pockets is not]
  Notes:
- [x] **Poison gas bomb only:** the CP Commissary has no chlorine gas grenade; a Division Leader and the Overwatch are issued poison gas bombs; any old chlorine grenades in your pockets became poison gas bombs. [a test proves it: CraftingTests, Grenades: no chlorine grenade, old ones become poison gas bombs]
  Notes:
- [ ] **Resupply scanner:** does it come down from the top of the sky over about three seconds? Is the crate twice as big? [needs a person: Scanner's descent and crate size by eye]
  Notes:
- [ ] **Firebomb:** 30% smaller fire: better? [needs a person: Fire size: is it better]
  Notes:
- [ ] **Rebels' damage:** 20% more against players (lc_rebel_damage should read 0.6 in the debug report): a threat now? [needs a person: Feel: are rebels a threat now]
  Notes:
- [ ] **Roses for Her:** is there a rose to see (stem, leaves, red bud)? Do notices say "You have a rose" and "Rose 1 of 3 laid at her feet", and does the laid rose lie at her feet? Is there time to crouch at the gold line? [needs a person: The rose model, its place at her feet, time to crouch]
  Notes:
- [ ] **Careless Talk:** is the spy at a different table each round? Salutes: arms outside the body? Fridge, stove and sink by the kitchen table, and props by the other three? [needs a person: Salute pose, kitchen props and tables by eye]
  Notes:
- [x] **Sociostability lines:** no more "(the mood of the city)". [a test proves it: PlaytestNov13Tests: 'the mood of the city' is never shown]
  Notes:
- [x] **Job titles:** "to the north-east", no distance in the tracker's header. [a test proves it: PlaytestNov13Tests: a place with no name is 'to the east', no distance]
  Notes:
- [ ] **Headcrab hunt:** stand at a different supply crate with the meat: does it take it? [needs a person: No test for a different camp's crate; try it]
  Notes:
- [ ] **The lab scientist:** start something and walk off: does he keep at it, tell you when it's done, and hand it over when you talk to him (and to nobody else)? After a raid, when he's back or the lab is fixed: no blood on him or the equipment? [needs a person: Blood left on him or the bench; the rest is in LabFixesTests]
  Notes:
- [ ] **Zombies:** scattered round the infestation, most still near the middle? [needs a person: How zombies are spread on the real map]
  Notes:
- [x] **The infested:** two infested players: no damage to each other, a shove instead? [a test proves it: PlaytestNov13Tests: two infested are kin, a shove and no damage]
  Notes:
- [x] **Resistance roles:** Smuggler from Member, Hacker only from Fighter, Father Grigori only from Lieutenant? [a test proves it: Factions: Smuggler from Member, Father Grigori from Lieutenant, Hacker a Fighter]
  Notes:
- [ ] **The morning jog is archived:** never on the schedule; the layout's jogging stops are gone after a map start (the debug report's points line has no jogroute; a backup is in lc_backups) and the jog's start is an exercise yard. You now have two yards (the old one and the jog's start): delete the one you don't want with the editor. [needs the real server: Your layout: delete the spare exercise yard (archiving itself is tested)]
  Notes:
- [x] **Sweeps:** over a few sweeps, does every rebel camp get one, the underground ones too? [a test proves it: PlaytestNov13Tests: every rebel camp has its sweep before a second]
  Notes:
- [ ] **Power bank and the blessing:** "(it can feed 2 powered devices)"; Father Grigori's blessing no longer says Russian. [needs a person: Two wording changes; no test found, a glance in game]
  Notes:

## Your 12 November notes: fixed, please try again
- [ ] **Spray can marks (new pictures; needs `livingcity_content.zip`, FastDL sync, map change):** Spray at a bare wall: a window asks The lambda, The tally, NO RECORD or Never mind. Try each. Are the two new marks the right size beside a lambda, the right way up, and lit like the wall? Do they scrub off? [needs the real server: Needs livingcity_content.zip and FastDL; then size and lighting by eye]
  Notes:
- [ ] **The Cheese Dream's surfaces:** the plain, slabs and wheels should look like holed cheese (are the holes a sensible size, or too small or too big?); the wedges in the sky should be swirling colours; take a golden cheese and the whole plain should melt into colours for 6 seconds, then go back. [needs a person: Cheese texture, hole size and colours]
  Notes:

- [x] **Lights out:** the warnings say "About six minutes until sleep" and "Two minutes until sleep".
  Notes:
- [x] **Sprays:** off. G only kicks.
  Notes:
- [ ] **Vortigaunt broom:** a street vortigaunt holds it out in front, head on the ground, not sideways. [needs a person: How the broom sits in its hands]
  Notes:
- [x] **Cuffs:** a unit carries 3. Cuff 3 people: F2 then shows Cuff greyed with the reason. Walk up to the CP Commissary: "Cuffs issued", back to 3. [a test proves it: CPCuffTests: three issued, refused with none, topped up at a CP Commissary]
  Notes:
- [ ] **Cuffed arms:** behind the back, wrists together (tune in your own console: `lc_cuff_pose "40 6 75 -75 10"`). Send a screenshot if still off. [needs a person: Arm pose behind the back]
  Notes:
- [ ] **Arrest Baton:** the baton shows in first person, with one small glow at its tip. Screenshot please if not. [needs a person: Baton and glow in first person]
  Notes:
- [x] **Duty allocation:** no more "credits in ration coupons" line.
  Notes:
- [x] **Shift:** 30 minutes again, and "Shift started" only once. [a test proves it: CPShiftFixTests: 30 minutes, one 'Shift started']
  Notes:
- [x] **CP Commissary screen:** right over the console, the floating sign hidden while it's open; signs and screens flicker like holograms. The Union Commissary has its own screen too. Turning in junk keeps your page.
  Notes: can we please have the layout so every page of the commissary screen has the next page and previous page not stacked on top of each other, but instead previous page takes up the left of the bottom row and next page takes up the right of the bottom row? Also please make the commissary interactive window 20% larger, it's just a hair too small (font to scale with it please)
- [x] **Checking papers:** "Done searching: check their papers" on the search window; the citizen stays facing you, still. [replaced: The search is a quick menu now (line 1916); facing is in CPCuffTests]
  Notes:
- [x] **Squad mates:** walk off fast or go up a floor. One more than 900 units back, or stuck 10 seconds, appears just behind you.
  Notes:
- [x] **Action music:** an inspection starts while you're in bed, in a dream, or far away: no action music. [replaced: Owner's new rule replaced it (line 1940)]
  Notes: well now action music is just sort of playing randomly while standing around. New rule: action music only plays for a player when they've fired more than 2 bullets and/or when they've been shot.
- [x] **Jobs over the radio:** radio transmitter up, right click (or F1 > Jobs over the radio).
  Notes:
- [ ] **Incinerator:** stands on end, fire out of the top like a torch; bodies go to its foot. [needs a person: How it stands and the flame looks (IncineratorUprightTests covers the angle)]
  Notes:
- [x] **Cremators:** one stays at each infestation; take a cleanup shift there and one escorts you. Morticians never go in. [a test proves it: CrematorGuardTests: guard the infestation, walk with crews, morticians stay out]
  Notes:
- [ ] **Mouths:** a citizen speaking a recorded line moves their mouth. [needs a person: Mouth movement by eye; needs a recorded line]
  Notes:
- [ ] **Small talk:** two citizens chatting in the street now often say something random and casual (12 lines in `VOICE_LINES.md` to record). [needs the real server: Needs the 12 small talk lines recorded]
  Notes:
- [ ] **Your model at server start:** a unit in the old low-res metrocop is switched to the right one a few seconds after spawning. [needs the real server: Needs the Alyx model pack on the real server (MetrocopRecheckTests covers the rule)]
  Notes:
- [x] **Dreaming as a unit:** a CP in a Combine-zone bed gets the nightmares. [a test proves it: DreamFixTests: a unit asleep in the Combine zone dreams the nightmare]
  Notes:
- [x] **Stop the dream:** as an admin in a dream, F1 > Stop the dream for everyone (also F1 > Staff). [a test proves it: DreamFixTests: stopped for everyone (F1 > Staff, or F1 in the dream)]
  Notes:
- [ ] **Battle Line:** the whole dream zone, rebels at normal speed, giants over a few seconds, gunships at half way, a pulse rifle for you, no streaks left after, no citizens in front. [needs a person: Look and pacing of the battle (rules in DreamFixTests)]
  Notes:
- [ ] **Party bus:** drives on the dream floor, through anything. [needs a person: How the bus drives on the dream floor]
  Notes:
- [ ] **Careless Talk, three rounds:** press E on the one you suspect. The canteen: they chat and gesture, the spy looks over their shoulder. The salute: everyone salutes and cheers together, the spy late and flat. The firing squad: everyone fires but the spy. Vortigaunts start 8 seconds after appearing; their sound plays once. [needs a person: Gestures, salutes and the firing squad by eye (rounds in DreamFixTests)]
  Notes:
- [x] **Sound guard:** any sound starting more than 4 times in 20 seconds is stopped ("sound guard" in the debug report). Every dream sound stops when it ends. [a test proves it: DreamFixTests: four starts then refused, listed in the debug report]
  Notes:
- [ ] **Duck and Cover:** slower, and the alarm is quieter and only during the siren. [needs a person: Pace and alarm loudness]
  Notes:
- [ ] **Freeze:** lights out in the dream zone, darker screen, zombies trailing you, red eye beams on anyone caught moving. [needs a person: Darkness, zombies and eye beams by eye]
  Notes:
- [ ] **Bubbles:** bigger, more, slower, no tiny ones; you weigh 40% of normal. (It was already 60%: say if you meant 60%.) [needs a person: Feel: enough bubbles to catch, and the lightness]
  Notes:
- [ ] **Dream music:** drop songs in `garrysmod/sound/livingcity/dreams/<codeword>/` (for example `freeze/`, `battleline/`, `duck/`, `spy/`, `bubbles/`); the debug report lists what it found. Until then Half-Life 2's own play. [needs the real server: Song files in the dreams sound folders]
  Notes:

## Your 11 November notes: fixed, please try again
- [x] **Stalkers' noise:** a stalker NPC now speaks once a minute, not every few seconds. Still too much?
  Notes: Yes much better
- [X] **G kicks:** as a unit, press G at a door or a person. (It never worked: the key ran the server's setting of the same name.)
  Notes: Works, thanks. Except when I kick it sprays my old spray cause G is my spray button: can we disable sprays on this gamemode?
- [x] **Cuffing without the big window:** look at a player up close, F2: Cuff, then Drag. The baton's tip on the right now says so. [replaced: Cuffs are issued now and a list comes up (lines 74 and 1820)]
  Notes: Please make cuffs standard issue for CP units; they should get 3 cuffs and can automatically get more if low by visiting the CP commissary
I didn't see the F2 cuff option: I patted someone down, found something, then pressed F2 and didn't see it. why not just have it popup as a contextual "cheat" F menu like we said? The hidden F menu...ok wait, I stopped someone and pressed F2 and I don't see a cuff option, what gives? Ohhh I don't have any cuffs...well there are no cuffs for sale at the CP COmmissary, come on! I can't get cuffs, no wonder! Like I said, CP units should get them automatically when going to a CP commissary and rebel units should be able to buy them from the black market dealer or a quartermaster.
- [ ] **Cremator, the sizzle:** let one kill headcrabs. No burning sound left behind afterwards? [needs a person: Ear: no burning sound left behind]
  Notes:
- [x] **Cremator, cooked meat:** what it kills leaves a cooked headcrab or roast bird, not a raw one, and that spoils in time. [a test proves it: CrabCarcassCleanupTests: a Cremator's kill leaves cooked headcrab or roast bird]
  Notes:
- [ ] **Cremator, carcasses:** kill headcrabs and leave them: about 90 seconds on, does a Cremator come and burn them? [needs a person: Watch it come for carcasses on the real map (body rule in CrematorTests)]
  Notes:
- [ ] **Cremator and barricades:** put barricades in its way. Within a minute or so it should give up and carry on somewhere else (out of sight it is moved to another street). [needs a person: Real pathing round barricades; no test found]
  Notes:
- [ ] **Cremator's flame:** greener, with a glow and a green light. Right, or still dull? [needs a person: Flame colour and glow]
  Notes:
- [ ] **Things clear away:** drop items from your pockets, leave meat and bodies lying: gone 5 minutes later, even while you watch (a body you are looking at, a minute after that). [needs a person: No test found for the 5 minute clear-up; watch it]
  Notes:
- [x] **The radio and R:** radio out, R puts it away; R again brings it back and it stays out. [a test proves it: UnitLifeTests: R puts the radio away, a fresh R draws it]
  Notes:
- [x] **A unit's shift:** a notice when a shift starts (with the quota), at half time and with two minutes left. With the editor tool out the shift's clock waits. [replaced: Owner tried it; fixed and relisted at line 82]
  Notes: ok it says when a shift starts, but 2 happen in a row, and I didn't see an option to take a break? so just make the shift back to 30 minutes then.
- [ ] **The trail when you run:** the chevrons should stay where they are on the ground and not race ahead with you. [needs a person: Chevrons on the ground by eye]
  Notes:
- [ ] **The trail in the open:** with a clear walk to the objective (same floor, no wall) it should point straight at it, not zigzag over path nodes. `lc_trail_straight 0` in the server console is the old way, to compare. [needs a person: Trail on the real map (straight line rule in GuidanceTests)]
  Notes:
- [ ] **One line per event:** retake rebel ground as a unit: one chat line about it, not three (the +5 Civil Standing line is separate and still shows). [needs a person: Count the chat lines in game; no exact test found]
  Notes:
- [x] **Action music:** it should end about 20 seconds after the last shot, start on a violent job only once you are near it, and be followed by several minutes of quiet. Fewer repeats of the same piece? [replaced: Action music rule replaced (line 1940)]
  Notes:
- [ ] **Ration vouchers:** about one in 14 minutes now. Right against your hunger? [needs a person: Balance: vouchers against your hunger]
  Notes:
- [ ] **CP Commissary:** the vest charges with one short sound and a chime when full, nothing left humming; the daily health vial is in your pockets (F3), 10 health when used. [needs a person: Ear: charge sound and chime, nothing left humming (kit in UnitLifeTests)]
  Notes:
- [ ] **The conditioning:** the Overwatch Candidate story should only be on a Division Leader's board with 1200 XP (F4 > Career says how much is missing). At the spot a soldier and a stalker wait; walk up to them, accept: black screen, machines, and you are a Combine Prison Guard with the uniform and weapons. [needs a person: The conditioning scene by eye (rank rules in CareerTests)]
  Notes:
- [ ] **The night shift:** on the board only from 18:00 to 21:00. [needs a person: No test found for the 18:00 to 21:00 window; look at the board]
  Notes:
- [ ] **A vortigaunt charging your vest** (as Resistance, E on a freed one): it turns to you, raises its hands, and a green beam pulses to your chest for three seconds. Does it play a charging animation? (The server log says which one it found.) [needs a person: Charging animation and beam]
  Notes:
- [x] **Bubbles dream:** many more of the big pale lift bubbles, a harder throw, 12 seconds of floating. The music's lurches last twice as long. [replaced: Owner tried it; redone at line 120]
  Notes:Nope, still not enough, I can't get any. they rise too fast and are still too few. I am running in circles unable to get any. Can we make the bubbles a little bigger? There are also tons of tiny bubbles everywhere that don't count for points I guess and make it confusing as to which are ok to grab, so maybe make the legit bubbles bigger, the ones that I can grab/eat/pop. Also lower the grav for dreamers for the bubble dream a bit, like 40% please.

## 11 November, part 2: fixed, please try again

- [x] **Your hands as a unit:** are your own sleeves and gloves back in first person? In your game's console (not the server's) there should be a line `own hands: N arm bones of M kept on ...`: if the hands are still missing, tell me that line (or that there is none). [replaced: Owner's note says the hands are back: tick it]
  Notes: yes they are thanks.
- [ ] **The kick from your own eyes:** only the leg now, no lump of torso. [needs a person: First person leg]
  Notes:
- [ ] **Clipboards:** a courier or clerk carries it hanging from the hand, flat against the leg. Better? If you want it held another way (under the arm, up in front), say which. [needs a person: How the clipboard hangs]
  Notes:
- [x] **Pockets as a unit:** "POCKETS", credits and standing sit under the title strip, nothing running through them.
  Notes:Perfect thank you
- [x] **CP Commissary screen:** the right height the first time it opens.
  Notes:
- [x] **Turning in junk:** at the CP Commissary, under the goods: "Turn in all: ..." pays you for what you carry. [replaced: Owner's note says it works; the page fix is ticked at line 84]
  Notes: This works but when I select junk to turn in, it goes back to the first page; please make it stick to the page I am on when selling/turning in.
- [x] **Arrest Baton:** the glow and sparks at its head in your view. A stunstick on the ground can't be picked up by a unit. [replaced: Owner tried it; glow redone at line 78]
  Notes:arrest baton sparks are in a group of 3 and sitting too far back from the viewmodel, please ask me for the screenshot if I forget it.
- [x] **F3 and F4:** with the pockets open press F4 (and the other way round): the open one shuts and the other opens. The window's own key shuts it.
  Notes: Works great
- [ ] **Protect jobs:** when a dropship or supply drop is announced, the job is on F4 for 60 seconds. Take it: "arrives in 1:00" counts down in the job tracker, top right, and it lands when that runs out. Leave it: it comes a second after the job disappears. [needs a person: Countdown in the tracker; only the landing is tested (ResistanceOpsTests)]
  Notes:
- [ ] **Housing block inspection:** the trail goes to a door of the block; the door stays shut until you set the charge (E) or kick it in; the furniture stands on the floor inside the room. [needs a person: Real map: trail to the door, furniture on the floor]
  Notes:
- [x] **Backup:** call it from far from any unit: they should be with you in well under a minute. [replaced: Backup redone on 14 November (line 21)]
  Notes:
- [ ] **Metrocops in a raid:** pistols out near the fighting, not sticks. Unarmed rebels standing in the cells are prisoners (it says so under their name), not raiders. [needs a person: Watch a raid: pistols out, prisoners labelled; no exact test found]
  Notes:
- [x] **Editor tool and sleep:** put the tool away late at night: a notice, and six minutes before you are exhausted. [a test proves it: UnitLifeTests: put it away, six minutes before you are exhausted]
  Notes:
- [ ] **Stalkers:** a body they drag is on a rope from the hand; a pile of dropped junk in their zone gets cleared (and anything dropped goes after 5 minutes anyway). [needs a person: The rope from hand to body by eye]
  Notes:

## 11 November, part 3: the rest of your list, please try

- [x] **Searching a suitcase or parcel:** search an NPC carrying one: a fifth spot ("Suitcase", "Parcel") beside the legs. [a test proves it: VestTests: a fifth spot in the search window (Suitcase)]
  Notes:
- [x] **Checking papers:** in the search window, "Done searching: check their papers"; or F2 > Check their papers with a citizen in front of you. The papers window against today's rules: wave on, cite, or take in a forgery. A catch is 1 credit and +5 Civil Standing; citing papers that were in order costs 2. [replaced: Owner tried it; search is a quick menu now (line 1916), facing fixed]
  Notes: "Done searching: check their papers" I do not see this on the search window. Thankfully the F2 > check their papers works. However when I Checked their papers, they turned around and I couldn't see their face; please make it so they stay facing the officer/person checking their papers; I'm standing still so they don't need to be moving to follow or get out of my way, they just need to face me.
- [ ] **Company on a patrol:** take the night shift (18:00 to 21:00) or a patrol job. Within a few minutes: a loiterer marked on your screen (may bolt when you come near), or somebody following you (a notice, look behind you, they run). Run them down, then search them or check their papers. Too often, too rare, too easy to lose? [needs a person: Feel: too often, too rare, too easy to lose]
  Notes:
- [ ] **NPCs fighting each other:** watch units and rebels meet. They should stop and shoot it out instead of firing a round and walking on, come round a corner for a shot instead of facing a wall, and duck into cover when hurt. `lc_combat_ai 0` in the server console is the old way, to compare. [needs a person: How NPC fights look]
  Notes:
- [ ] **A dream after a late night:** alone on the server, go to bed after 21:15 on a Happy or Neutral night: the dream should come about twenty seconds after you fall asleep. (As a unit you only watch over Nightmares and propaganda dreams as an Enforcer, and a Nightmare never reaches a sleeper in a Combine-only zone.) [needs a person: No test found for the late dream; needs a night alone on the server]
  Notes:

- [ ] **Window titles (11 November):** the guide (C > Guide), the Commissary window, the black market and quartermaster windows and Father Grigori: their own big title, counters and the guide's search box sit under the title strip now, nothing running through them. The guide shows keys as [F1], not {gm_showhelp}. [needs a person: Window titles and layout by eye]
  Notes:

- [ ] **Flashbangs (11 November):** throw one into rebels shooting at you. Chat should say "[Flashbang] N blinded". The blinded ones have no gun in their hands, rub their eyes or stumble for 4 to 9 seconds, then pick the fight up again. If it says "Nobody was caught in it" when it landed among them, tell me: then the bang isn't reaching them at all. [needs a person: Real grenade: does the bang reach them (pose now line 1872)]
  Notes:

## Still open

- "Guns lowered: hold R" only applies on rebel ground, and for recruits and metrocops on the Combine's ground. You said you would test it there.
- Your first person hands as a unit, and the clipboard's new hold: waiting on what you see.

# Part 1: new since your 1 November playtest

## Infestation Cleanup (fixed after your notes: try first)

Players now download both workshop packs when they join (the Alyx hazard props 2043900984, the Infestation Control workers 3185145650). The server needs them too: put both in its workshop collection. Anyone missing a model sees a stand-in, never an ERROR.

- [ ] **Do you see the sprayer and the hoover** in first person, and in your hands in third person? Placement: `lc_sprayer_view "18 9 -10"`, `lc_hoover_view "26 11 -15"` (forward right up): send me numbers that look right. [needs a person: Sprayer and hoover placement in your hands]
  Notes:

## Also fixed from your notes

- [x] **City Administrator:** C > Me > Run for City Administrator (8 hours played; staff: `lua_run` your hours up, or set `lc_admin_hours 0` to test). A vote window; win it: the tablet, two Elites at your side. Right click the tablet: the office (events, rations, prices, job bonus, commend, pardon, housing, permits). Left click at someone: the Elites kill them. [a test proves it: The 1 November playtest: 8 hours, the vote, the office, the Elite bodyguard]
  Notes:
- [x] **AFK:** idle 5 minutes: AFK under your name; 15: kicked (not staff). [replaced: AFK is 20 minutes for both since 2 November (line 644)]
  Notes:
- [x] **The Man Inside, part 2:** the choice (transfer order, a fire, a false report): the guards go off to the fire or the report; the order mostly passes. [a test proves it: Stories: The Man Inside (a transfer order, a fire, or a false report)]
  Notes:
- [x] **Guns lowered:** pistol out: pointing down, no crosshair; hold R raises it; click while down raises it; tap R reloads. Does the gun use Half-Life 2's lowered pose? [replaced: Owner tried it; lowering is only on rebel ground now (lines 646 and 1969)]
  Notes: this does not appear to be working? nothing happens when I hold R for a weapon as a CP unit
- [x] **Wear and legacy:** lockpicks, fishing lines and weedkiller run out after a while; a title under your name after 3 lives; a ring with each new person. [replaced: The ring was removed (line 900); wear and titles are in the 1 November tests]
  Notes:
- [x] **Contraband found** in a street search: a FIGHT / COMPLY box, five seconds. Fight: you keep it, wanted. Comply or wait: taken. [a test proves it: The 1 November playtest: contraband found, fight or comply]
  Notes:
- [ ] **Sleeping rebels** wake when you walk up as a unit. **Multitool:** unshackles street vortigaunts; hacks the CP Commissary; its text low on screen. [needs a person: Several small checks, no single test; the multitool's text place by eye]
  Notes:
- [ ] **Street vortigaunts:** shackled, left alone by the Combine, sweeping when they stop. **Dead vortigaunts:** morticians collect them. [needs a person: Sweeping is tested (1 November); morticians collecting dead vortigaunts is not]
  Notes:
- [ ] **C menu on a citizen:** This person > Ask their name; on rebel ground, Bring them in (Resistance) / Tell them to leave. [needs a person: Ask their name is tested; the rebel ground options have no test found]
  Notes:
- [ ] **Editor:** coloured ticks under used numbers on the number slider. [needs a person: Editor slider ticks by eye]
  Notes:
- [x] **Cleanup:** one step, "Clear 3 growths": spray one and vacuum it, in any order; all three count. Guards are soldiers, and they kill zombies fast now. Warning posts by a path node at the edge. [a test proves it: The 1 November playtest: growths, soldier guards, warning posts]
  Notes:
- [x] **Prison:** two Nova Prospekt guards, tough; no metrocops or soldiers garrisoned there. A prisoner a job's about stays in until the job ends. [a test proves it: The 1 November playtest: the prison is guarded by two Nova Prospekt guards]
  Notes:
- [ ] **Turrets:** knocked over: E as a unit sets it upright where it stood; NPC units right ones they pass. [needs a person: No test found for righting a turret; try it]
  Notes:
- [ ] **Firebomb:** a much wider fire. **Lab:** text wraps, no "Homemade", scientists' own voices. **Weeds:** easier to find, one marked on the shift. **Sweep cart:** on the floor. [needs a person: Text wrap, weeds and cart by eye; firebomb size is now line 33]
  Notes:
- [x] **Poison gas bomb / firebomb:** bought or made, it's on your Grenades weapon (R to pick it, left click throws). No Throw button in F2. [a test proves it: The 1 November playtest: a bought poison gas bomb is on the Grenades weapon]
  Notes:
- [x] **Units in doorways:** walk into one: it shuffles aside and steps clear. [a test proves it: The 1 November playtest: walk into a unit in a doorway, it steps aside]
  Notes:
- [x] **Metrocop with no pistol:** E at the CP Commissary issues it again (or respawning does). [a test proves it: The 1 November playtest: a lost pistol is issued again at the CP Commissary]
  Notes:
- [x] **CP Commissary:** no civilian clothes, no fishing line, no cuffs for sale (a unit's own never run out); a Clean uniform (5) that puts right a soiled unit; poison gas only from Division Leader up. [replaced: Cuffs now run out and are topped up (line 74); the rest is tested]
  Notes:
- [ ] **Terminal screens** just below eye level; Next page and Close light up when aimed at. [needs a person: Screen height and button highlight by eye]
  Notes:
- [x] **The "Request device"** is now the "Civil Protection call box" everywhere. [a test proves it: CPToolTests, /request: you need a Civil Protection call box]
  Notes:
- [x] **Clinic Medic:** own citizen clothes, no rebel medic outfit, no welding helmet. [a test proves it: Playtest fixes, 17 October (evening): a clinic medic's pack helmet comes off]
  Notes:
- [ ] **Job items** (6-12's belongings, evidence, anything to find): never under stairs or in walled-off space; always somewhere you can walk up to. [needs a person: Real map: can you walk up to job items (rule in 1 November tests)]
  Notes:
- [ ] **Sleeping citizens:** lying flat on the bed, eyes shut, not sitting up through it. Heads at the pillow end? (If at the foot: `lc_bed_head_flip 1`.) Too high or sunk in? `lc_bed_npc_lift` (9). Shoot one: they wake. [needs a person: How sleepers lie on the beds]
  Notes:
- [x] **Block Warden:** not listed below 100 standing; listed and takeable at 100. [a test proves it: The 1 November playtest: Block Warden only at 100 standing]
  Notes:
- [x] **Join Civil Protection:** you spawn in a Combine zone, not the train station. [a test proves it: The 1 November playtest: a unit spawns in a Combine zone]
  Notes:
- [ ] **The radio transmitter** (CP and Freq 7) is well up in view now. Adjust: `lc_radio_view "20 9 -3"`. [needs a person: Where the transmitter sits in view]
  Notes:
- [x] **Metrocop hands:** fists (or any weapon with hands) as a metrocop: your own sleeves and gloves now, not the soldier's. Anything odd (bits of body floating in view, stretched shapes)? If it's bad, `lc_cp_hands ""` puts Garry's Mod's back. [replaced: Owner's note at line 172 says the hands are back]
  Notes:
- [ ] **Records Clerk filing:** the instructions at the top make sense? The register shows a status now; anything different (name, number, status) is a Discrepancy; after each form it says right or wrong and why. The blank form button is red and says it's a crime. [needs a person: Do the instructions read well (filing rules in HandsOnTests)]
  Notes:
- [ ] **F4:** a header for each faction; click to open its ranks and roles. Free Vortigaunt and Overwatch Commander no longer cut off. No Stalker on it. [needs a person: F4 layout by eye: headers, nothing cut off]
  Notes:
- [x] **Joining the Resistance:** you start as a Member at most, in your own clothes, whatever your XP: do 3 jobs from their board and they trust you (Fighter: the gear and the guns). F4 shows how many. [a test proves it: The 1 November playtest: three jobs done, then Fighter]
  Notes:
- [ ] **Boiling water at a burning barrel:** works now? (If not, tell me what the barrel is: a map prop, or the editor's "Fixture: fire".) [needs a person: Your map's own barrel: does it count as fire (rule tested 1 November)]
  Notes:
- [ ] **Rain** no longer fills bottles or cans. [needs a person: No test found for rain not filling bottles; try it]
  Notes:
- [x] **Sociostability** when it changes: the chat line says why (curfew, a sweep, lockdown, infected loose in the city...). Headcrabs inside an infestation shouldn't change it. If it still drops for no good reason, send me that line. [a test proves it: PlaytestNov13Tests and the 1 November playtest: the reason is shown, infestation headcrabs don't count]
  Notes:

## Weedkiller as a weapon, and the Combine's gas

- [ ] **Firebomb** (the Resistance lab: 2 weedkiller, an empty bottle, a rag): a burning bottle; it breaks where it lands and burns a while; units in it burn, armour or not; a power bank, forcefield or turret next to it goes down; a growth in it burns away. [needs a person: The burning bottle and fire by eye; only part is tested (1 November)]
  Notes:
- [x] **Barnacle:** drop weedkiller under one (F2 > Drop): it pulls it up, crunches, dies. [a test proves it: The 1 November playtest: a barnacle that eats weedkiller dies]
  Notes:
- [x] **Poison gas bomb** (units only now: the CP Commissary, 40): thrown, a green cloud; citizens choke, units not at all. [a test proves it: The 1 November playtest: gas chokes a citizen, a unit's mask keeps it out]
  Notes:
- [ ] **A sweep into rebel ground** sometimes opens with a gas bomb; the units walk into it unharmed. [needs a person: No test found for a sweep opening with gas; watch one]
  Notes:
- [ ] **As an Insider,** at the Commissary with weedkiller: Foul the filters, then gas hurts units too (and they're told their filter's no good). Spike the food: other units are poisoned over the next few minutes. [needs a person: Fouled filters are tested (1 November); spiking the food is not]
  Notes:
- [x] **Poison:** F2 > Weedkiller > Poison food or drink: the food looks the same; give it to someone, they're poisoned when they eat it. A unit watching: wanted. [a test proves it: The 1 November playtest: whoever eats it is poisoned]
  Notes:

## Weeds and the Groundskeeper

- [ ] **Weeds** come up on open ground and grow (a tuft, weeds, a bush). Which plant shows? (An ERROR model: say so.) [needs a person: Which plant model shows, any ERROR]
  Notes:
- [x] **Groundskeeper** (F3 > Jobs): issued weedkiller; E on a weed sprays it; the shift is three weeds. NPC groundskeepers spray them too. [a test proves it: The 1 November playtest: the Groundskeeper is issued weedkiller, a sprayed weed is gone]
  Notes:

## Rations

- [x] **A new character:** registering at Civil Intake gives papers but no ration card; a dispenser says "No ration card" and tells you to work a shift. [a test proves it: IntakeTests: registered, but no ration card until a shift is worked]
  Notes:
- [x] **Finish a Union shift:** "[Rations] You earned a ration card" on screen; F2 shows the card (and how many). [a test proves it: PapersHousingTests: a finished Union shift earns a ration card]
  Notes:
- [x] **Take a ration:** the dispenser takes one card, and no credits come with it (standing still goes up by 1). [a test proves it: PapersHousingTests: each ration takes one card and pays no credits]
  Notes:
- [ ] **Civil Intake's record screen and your papers** show how many ration cards you have; there's no "Replace my ration card" button any more. [needs a person: What the screens show; no test found for the removed button]
  Notes:
- [x] **Hungry with no card:** What now? says to work a shift for a ration card. [a test proves it: NextStepTests: hungry with no ration card, work a shift for one]
  Notes:
- [ ] **Short rations:** below 150 standing the dispenser gives a short ration (and says so); at 150+ the full packet. [unsorted: Ration lines mentions a short ration; could not confirm the 150 line]
  Notes:

## Fixes from your 1 November playtest

- [x] **Infestations:** citizens, units and rebels walk round them, never through. [a test proves it: The 1 November playtest: a step through an infestation is one to go round]
  Notes:
- [ ] **Rebels on your beds:** at night, rebels lie down on the beds you placed in their camp. [needs a person: Do rebels lie on the beds you placed (your layout)]
  Notes:
- [x] **A sweep:** units arrest the lab scientist, smash the pots (the plant gone, a breaking sound) and empty the supply crates. [a test proves it: The 1 November playtest: a sweep team smashes the pots]
  Notes:
- [x] **Rebels at home** go down in about half the shots; your squad as before. Rebels: SMGs and shotguns only. Combine soldiers: pulse rifles and shotguns only. [replaced: Rebel health changed on 9 November (line 1338); weapons are tested]
  Notes:
- [x] **Triage:** three or four patients going downhill plus one stable (a broken arm stays put); a gunshot wound drops fast. [a test proves it: MoreJobGameTests: triage]
  Notes:
- [ ] **Top left:** credits, standing, and loyalty, sympathy, corruption. [needs a person: HUD corner by eye]
  Notes:
- [x] **Medic to another job:** the medkit is gone. [a test proves it: The 1 November playtest: a new job, the old job's medkit is taken back]
  Notes:
- [x] **A placed bin:** stand next to it, F2: the bin's section is there. [a test proves it: The 1 November playtest: a bin you're standing right by counts]
  Notes:
- [x] **The jog:** units say "Move it!"; finishing says what you earned (standing and 5 credits); skipping shows a reprimand and the next ration is withheld. [replaced: The morning jog is archived (line 55)]
  Notes:

## Terminals on their own screens

- [ ] **Civil Intake / Housing Allocation:** E shows the menu on a screen in front of the terminal; the button under your crosshair lights up; E presses it. Is the screen in a good spot (not inside the terminal, readable, not upside down or mirrored)? [needs a person: Is the screen in a good spot and readable]
  Notes:
- [ ] **CP Commissary (as a unit):** the counter's goods on its screen; buying works. [needs a person: The in-world screen by eye]
  Notes:
- [ ] **C > Settings > Terminals' menus:** switch to a window and back. [needs a person: Switching between screen and window by eye]
  Notes:

## The Resistance Insider, the loyalty test, and more

- [x] **Recruited:** as a kind unit, The Man Inside on F3; stay inside at the crossroads. [a test proves it: The 1 November playtest: recruited (The Man Inside), an Insider]
  Notes:
- [x] **C > Civil Protection > Inside** appears (and only for you). Each action refuses with someone nearby, works alone. [a test proves it: QuickMoreTests: Inside greyed with someone close (it is on F2 now)]
  Notes:
- [x] **Tip off Freq 7:** a Resistance player hears "A friend inside: ...". [a test proves it: The 1 November playtest: a tip-off goes out on Freq 7, unsigned]
  Notes:
- [x] **Lose a record:** a wanted player isn't wanted; your standing drops 25. [a test proves it: The 1 November playtest: a wanted record goes missing, for 25 standing]
  Notes:
- [x] **At the Commissary:** bandages and pistol rounds you can give away. **Copy the records:** the quartermaster pays 60. [a test proves it: The 1 November playtest: the city's records copied out; QuickMoreTests supplies]
  Notes:
- [ ] **Reveal myself:** the person you look at is told. [needs a person: No test found for Reveal myself; try it]
  Notes:
- [x] **Caught in the Mole Hunt:** Resistance, wanted, no surrendering; Civil Protection and Union jobs refused. [a test proves it: The 1 November playtest: caught, Resistance and wanted, no surrendering]
  Notes:
- [x] **The loyalty test** (suspicion 3 as an Insider): the cell, the prisoner, fists only, two shotgun guards beside you. Beat him, kill him: weapons back. Refuse or walk out: shot down, bleeding, then made a stalker. [a test proves it: The 1 November playtest: the loyalty test in the cells; refused, made a stalker]
  Notes:
- [x] **The reckoning** starts by itself after it (no choosing it): pay the debt (starts at once) and the Inside menu comes back; take off the mask (Resistance, never a unit again); or done with the Resistance (the forced soldier conversion). [a test proves it: The 1 November playtest: until the debt's paid, no Inside menu]
  Notes:
- [ ] **The stalker's end:** the frame is built beside a power transformer; once charged, an arc jumps the gap; walking into it kills at once. [needs a person: The frame and the arc by eye]
  Notes:
- [x] **Joining Civil Protection:** refused until 5 Intake Processor shifts (and 100 standing), and told so; F4 shows both as progress bars. [a test proves it: UpdateTests, Joining Civil Protection; 1 November: shifts counted]
  Notes:
- [x] **The loyalty test with a Resistance player online:** the Insider waits; units near the Resistance player keep stopping them; once the rebel's in a cell, both are put in the scene, with the on-screen prompts. [a test proves it: The 1 November playtest: the test waits for a real prisoner]
  Notes:
- [x] **Done with the Resistance:** Proof (a sweep, two of their fighters down), then the conversion. [a test proves it: Stories: The Man Inside (the proof part)]
  Notes:
- [ ] **No Union radio**: radios are Freq 7 radios (black market); the lab's transmitter needs one. [unsorted: Radio tests exist but I could not confirm the lab transmitter needing one]
  Notes:
- [x] **Shackled vortigaunts** sweeping the streets (2); as Resistance, cut one loose (look at it, unshackle): it walks to rebel ground and stays. Playing a vortigaunt: no fists. If there's still no freed one in rebel ground, send the debug report's "vortigaunts" line. [a test proves it: The 1 November playtest: a street vortigaunt cut loose goes home; no fists]
  Notes:
- [x] **Secret endings** three hours apart. [replaced: Sealed directives are off by default (line 989); endings no longer start by themselves]
  Notes:
- [x] **She, not he:** a job about a woman (a patient, a neighbour, a prisoner) says her. [a test proves it: The 1 November playtest: 'Heal her', and him for a man]
  Notes:

## What loyalty earns

- [x] **At 150+ standing:** fewer stops, shifts pay a bit more, the Commissary is cheaper, and lockers open (refused below 150). [a test proves it: The 1 November playtest: standing tiers, Trusted and Exemplary]
  Notes:
- [x] **At 400+:** stops are a papers glance; two ration cards a shift; waved through once a curfew; a curfew slip is a warning; the Administrator names you on screen now and then; MODEL CITIZEN on your papers; Block Warden on F3 > Jobs (refused below 400). [replaced: Block Warden is 100 now (line 282); the rest is in the 1 November tests]
  Notes:

## Vortigaunts, and rent

- [x] **As a shackled vortigaunt:** C > Reach out through the vortessence: Resistance players and free vortigaunts are told where you are; with a unit watching, the collar bites. The Collar on F3: sweep, the crate, the quiet corner. [a test proves it: The 1 November playtest: reach out through the vortessence; The Collar]
  Notes:
- [x] **As a free vortigaunt:** right click another vortigaunt: a second's glow, then +25 health (not again for 10 seconds, by anyone). A freed NPC vortigaunt walks over and mends you when you're hurt. Left click a power bank, forcefield or turret from a distance: it goes down for 45 seconds, then comes back. Free your kin (a street vortigaunt, marked) and Read the Combine (watch a checkpoint, get intel) on the Resistance's board. [a test proves it: The 1 November playtest: mending kin, the bolt on a power bank, its own jobs]
  Notes:
- [x] **Freed vortigaunts in rebel ground** walk about the camp and the fire; free a street one and the two talk in their own tongue now and then. [a test proves it: The 1 November playtest: two freed vortigaunts talk in their own tongue]
  Notes:
- [x] **The hive mind:** with two free vortigaunts about, within 15 minutes a Freq 7 line about a sweep, or a door code on a scrap by them; the code opens a Combine door once. [a test proves it: The 1 November playtest: communing, they see a Combine door code]
  Notes:
- [x] **Rent:** 50 credits for an ordinary citizen; as a unit, or a citizen with 200+ standing, nothing (the question says so). [a test proves it: BusinessTests, Apartments: rent is lc_rent_price (50)]
  Notes:

## Beds

- [ ] **Citizens at curfew or night** walk into the habitation blocks and lie down on the beds you placed, asleep (eyes shut), and get up in the morning. Heads at the foot end? `lc_bed_head_flip 1`. [needs a person: Citizens walking in and lying on your beds, by eye]
  Notes:
- [ ] **You in a bed:** E on it at night: you lie on it, others see you lying there, your view is from the pillow. Jump: back beside the bed. [needs a person: Your view from the pillow, and how others see you]
  Notes:

# Part 2: older items (from 8 October on)

## Knowing what to do

- [x] **What now? (F1, slot 1):** always one next step (register, a room, your block, eat, drink, a job, a shift), and Places with waypoints (dispenser, water, bins, home, work, Commissary, toilet, bath, bed). [a test proves it: NextStepTests: What now? Everyone always has a next step]
  Notes:
- [x] **Ways to get by (F1 > What now? > Ways to get by, or !ways):** everything you could do right now, what's missing, and a "Show me" button. [a test proves it: WaysModelTests: Ways to get by]
  Notes:

## Jobs you actually do (mini-games)

- [x] **Sanitation:** street sweep with a cart. [a test proves it: JobGameTests: the street sweep]
  Notes:
- [x] **Factory:** the conveyor line (bin the rust-red parts, pocket the rattling one). [a test proves it: JobGameTests: the factory line]
  Notes:
- [x] **Intake Processor:** the papers check. [a test proves it: JobGameTests: the papers check]
  Notes:
- [x] **Maintenance:** rewiring panels. [a test proves it: MoreJobGameTests: rewiring]
  Notes:
- [x] **Clinic Medic:** triage. [a test proves it: MoreJobGameTests: triage]
  Notes:
- [x] **Reclamation:** breaking rubble. [a test proves it: MoreJobGameTests: rubble]
  Notes:
- [x] **Courier:** parcel runs. [a test proves it: HandsOnTests: parcels]
  Notes:
- [x] **Mortician** (renamed from Mortuary Attendant): searching the dead, and the Headcrab collection shift. [a test proves it: HandsOnTests (the dead) and MortuaryTests]
  Notes:
- [x] **Records Clerk:** filing. [a test proves it: HandsOnTests: filing]
  Notes:
- [x] **Laundry:** sorting uniforms. [a test proves it: HandsOnTests: laundry]
  Notes:
- [ ] **Radio Repair:** find the station on the dial, then set the three screws by ear. [needs a person: Set by ear: the dial and screws (rules in HandsOnTests)]
  Notes:
- [x] **Resistance:** the terminal hack, and dead drops. [a test proves it: HandsOnTests: the records terminal, dead drops]
  Notes:
- [x] **Civil Protection:** pat-downs and breach raids. [a test proves it: HandsOnTests: pat-downs, breaches]
  Notes:
- [ ] **Block raid you can see:** `lc_event raid`, go to the block it names: units are there within a minute, walk it stop by stop, and leave when it's over. A sweep (`lc_skirmish sweep`): the team really reaches rebel territory and fights. [needs a person: Real map: do units reach the block and the rebel ground]
  Notes:
- [ ] **Editor tool in hand (admin):** hunger and thirst stay put, and units don't stop, frisk or chase you. [unsorted: Only 'never exhausted' is tested (UnitLifeTests); hunger and stops not confirmed]
  Notes:
- [x] **Ration Production** (was Ration Kitchen): the sealing line, supply runs, the count against the register, forged ration cards at the counter. [a test proves it: StaffingTests: Ration Production, and every job staffed]
  Notes:
- [x] **Every job staffed:** the city's NPCs cover every job, more of them as the city grows. [a test proves it: StaffingTests: every job staffed]
  Notes:

## Radios

- [ ] **Listening to a radio:** the dial, static between stations, the Union station and Freq 7 (its frequency moves). Heard within about 20 feet, quieter further away. Listening to Freq 7 is a crime. [needs a person: Ear: static, stations, quieter further away]
  Notes:

- [x] **Freq 7, one station:** a voice line, then a song, back and forth; every radio on it hears the same thing. A warning cuts in before a sweep, raid, curfew or convoy (and for an incursion, a lockdown or a dropship). [replaced: Freq 7 has no music now (line 691)]
  Notes:
- [x] **Freq 7, the hunt:** it only ever sits on 100.6, 101.5, 102.4, 103.3, 104.2, 105.1 or 106.0. The Combine find it and jam it (a whine, units told), it goes dark, then comes back on another. A Resistance radio follows it; a Union radio has to search. A blackout stops the jamming. [a test proves it: Freq7Tests: the seven frequencies, the program, the hunt]
  Notes:

## The city and the Combine

- [x] **Data chips:** decoded only at the Resistance lab, by the scientist. The lab bench is Kleiner's now. [a test proves it: QMDecodeTests: The lab decodes chips]
  Notes:
- [x] **Forcefields:** take damage, recharge, break; a Maintenance crew (NPC or player) repairs them. [a test proves it: ForcefieldTests: they take a beating and recharge]
  Notes:
- [ ] **Power banks:** a forcefield needs one, and a bank powers only two things. HL2's forcefield texture. [needs a person: Forcefield texture by eye (power rules in ForcefieldTests)]
  Notes:
- [ ] **Rain:** thinner, twice as many drops, fog only under open sky. [needs a person: How the rain looks]
  Notes:
- [x] **CP Commissary:** a separate counter for units; the Union Commissary doesn't sell to them. [replaced: Owner tried it; the Union Commissary screen was added (ticked, line 84)]
  Notes: It exists but it doesn't have the in game floating menu like the CP Commissary, can we change that and put it over the console like I mentioned for the CP COmmisary? Thanks
- [x] **Nova Prospekt:** soldiers near the prison wear the prison guard uniform. [replaced: The prison has only two Nova Prospekt guards now (line 258)]
  Notes:
- [ ] **Dropships:** the container stays in the claws, the door opens and soldiers jump out; on red alert the first one out is an Elite. [needs a person: Dropship door and soldiers jumping out, by eye (DropshipCargoTests covers the claws)]
  Notes:
- [ ] **Surprise events:** only rations and curfew are announced two minutes ahead. Sweeps, raids and supply convoys come without warning (units still get their directive early; the Resistance hear a whisper on Freq 7). A lockdown only follows violence. [unsorted: Could not confirm which events are announced ahead]
  Notes:
- [ ] **Alyx Combine models:** used automatically if the Workshop pack is installed (lc_combine_models_list shows what was found). [needs the real server: Needs the Workshop model pack on the server]
  Notes:

## Body and daily life

- [x] **Toilets and parasites:** parasites mean toilet trips (they dehydrate you).
  Notes:
- [x] **Soiling yourself:** a stain on the ground, clean clothes and a bath needed; you stink, flies follow you, people back away. Sanitation crews clean the stains.
  Notes:
- [x] **Sleep:** beds, and sleep at night.
  Notes:
- [x] **Tiredness:** skip a day's sleep and your eyelids droop, less health, no running.
  Notes:
- [x] **Powered vests:** the VEST bar replaces SUIT; vortigaunts charge them.
  Notes: never seen a vortigaunt charge them, can we have them do the animation like from HL2 when they charge Freeman's HEV suit? they hold up their hand and green energy pulses to the player.
- [x] **Father Grigori:** an NPC in rebel territory with blessings and sermons; a player Grigori's shotgun holds 2 shells.
  Notes:

## Stalkers

- [x] **Stalker playermodel:** worn by stalkers (Workshop 268895264).
  Notes:
- [x] **Stalkers for life:** no way out but death.
  Notes:
- [x] **The Stalker's Lot (F3):** ends at an energizer you build; step in (that person ends) or turn away (still a stalker; E twice on it later to step in). [a test proves it: StalkerTests: their work, and the energizer]
  Notes:

## Civil Protection career

- [x] **Ranks:** Recruit > Metrocop > Division Leader > Combine Prison Guard > Combine Soldier > Elite Soldier. [a test proves it: MergeKickTests: One Civil Protection career]
  Notes:
- [x] **The conditioning:** the Overwatch ranks need it; the Overwatch Candidate story offers it to Division Leaders. [a test proves it: CareerTests: the way to the Overwatch]
  Notes:
- [x] **Overwatch Commander:** one at a time, calls in a dropship squad every 15 minutes (F1 > Unit tools). [a test proves it: MergeKickTests: the Overwatch Commander]
  Notes:
- [x] **Scanner Operator:** flies a scanner from a terminal; photos earn XP; rebels photographed become BOLOs. [replaced: The role is gone; any unit flies a scanner (line 840)]
  Notes:
- [x] **Squads:** units hunting the same person stick together behind a leader, watch outward, call contact on the radio. [a test proves it: SquadTests and OutfitSquadTests: squads]
  Notes:

## The kick (G, or F1 > Kick)

- [x] **Metrocop:** doors bang open fast; a locked door gives on the second kick. [a test proves it: KickFollowTests: doors bang open]
  Notes:
- [x] **Combine Soldier:** tips a hinged door off its hinges. [a test proves it: KickFollowTests: fallen doors]
  Notes:
- [x] **Elite:** sends the door flying 5 to 10 feet; whoever it hits is knocked out (never killed). [a test proves it: KickFollowTests: fallen doors knock out]
  Notes:
- [x] **Breaking things:** kicks break crates and planks. [a test proves it: KickFollowTests: boots break crates]
  Notes:
- [ ] **Brush doors:** sliding doors and shutters don't budge. [unsorted: Could not confirm a test for brush doors not moving]
  Notes:
- [x] **Rehanging:** a Maintenance Technician lifts the fallen door (E), carries it to its frame and presses E there. [a test proves it: KickFollowTests: fallen doors get rehung]
  Notes:
- [ ] **The leg animation:** how it looks in first and third person (it may need tuning). [needs a person: The kick's leg animation]
  Notes:

- [ ] **The Endings menu (C > Help > Endings menu, as superadmin):** opens with the ending playing already picked (or pick one and press Play it now). On The dance tab: pick a move and a bone on the body map; is the bone lit up yellow on the dancers, and does the close-up at the top show them (drag to turn round, wheel to zoom)? Do the three sliders turn the bone the way their labels say, live, on everyone (ask another player to watch), with the other side mirrored? Tick the stand-in with no ending playing: does someone do the move in front of you? Settings: do the sliders change the ending as it plays, and does "back to the default" work? Changes: does "Copy it all" give you a list to paste me? After a map change, is the tuning still there? [needs a person: Dance tuning by eye, with another player watching]
  Notes:

## Fixes from the 17 October playtest (what to check)

- [x] **Warn the block:** in the block, residents come out to be warned (any wing of it); if the raid ends before you've warned three, it's not paid. [a test proves it: Playtest fixes, 17 October: residents come out to be warned]
- [x] **Changing jobs:** the old shift goes from your HUD and the new job's shifts can be taken. [a test proves it: Playtest fixes, 17 October: changing jobs ends the old shift]
- [x] **The two voices:** the two-minute warnings and the "it's over" announcements: the Administrator waits till Overwatch has finished. [replaced: Announcer pacing redone; check line 2054 instead]
- [x] **Curfew:** a unit that sees you out (even one at a post) warns you and comes over; three warnings and you're wanted. [a test proves it: Playtest fixes, 17 October: a unit on duty warns someone out in the curfew]
- [x] **Your apartment door:** E opens it, E again shuts it, locked again. [replaced: A locked door only rattles now, right click unlocks (line 693)]
- [x] **Pickpocketing / talking:** nobody ends up stuck inside you. [a test proves it: Playtest fixes, 17 October: someone stopped on top of you steps back]
- [x] **Arrested:** walked to the cells (a unit pausing on the way doesn't end the walk; only a long hold-up brings the van). [replaced: No van now: you come to in a cell (line 628)]
- [x] **Sinks:** E on the map's sinks works again (and not through walls). [a test proves it: Playtest fixes, 17 October: map sinks in reach, not through walls]
- [x] **Ration line:** during a ration event people queue and move up to the dispenser. If not: copy the debug report and look at the "line" line (it says if the dispenser has no power, or the line was placed from the back). [a test proves it: Playtest fixes, 17 October: a line placed from the back is turned round]
- [x] **Factory line:** every red part can be picked up with E; no part rolls off the belt. The loading dock run is the Intake Processor's now; the factory gets "Overtime on the line". [replaced: Same check repeated later (line 606)]
- [ ] **Carrying boxes:** citizens' hands stay on the box as they walk. [needs a person: Hands on the box as they walk]
- [ ] **The bed fixture** is the bed with a mattress (Counter-Strike: Source's; HL2's if the server hasn't CS:S. Players without CS:S see an ERROR: tell me if that happens and I'll pick another). **The toilet** flushes after the splash. **Your fridge** at home opens your stash. The stash button no longer says searches don't reach it. [needs the real server: Needs Counter-Strike: Source content on the server and players' games]
- [ ] **"Civil Protection unit"** everywhere players read "unit" (say if one reads oddly). [needs a person: Reading: does 'Civil Protection unit' read oddly anywhere]
- [x] **The sweep cart:** the smaller cart, the right way round, pushed up stairs, and it doesn't hurt you. [a test proves it: Playtest fixes, 17 October: the smaller cart, turned, pushed up a step]
- [x] **Debug report:** the "people who left" lines. [a test proves it: LeaveReasonTests: Leaving isn't always running away]
- [ ] **The editor:** "Arrange by what it's for" (each job, the rebels, the prison...), "Show the editor's markers", "See markers through walls". [needs a person: Editor lists and markers by eye]
- [x] **Helmets:** a pack's battle helmet or welding mask only on rebels in the open. [a test proves it: Playtest fixes, 17 October: battle helmet only on rebel fighters]
- [x] **Everyone works:** a new registered citizen is assigned a job (a notice says which); rebels aren't. The "What now?" line when you've nothing on is stern now. [a test proves it: Playtest fixes, 17 October: given Union work (with a terminal, see line 927)]
- [ ] **Sneaking:** crouch: the bar at the bottom, the units' sight on the ground (red when you're in it), creeping behind a unit's back unseen, the dark helping. A supply drop raided crouched from behind the crates. [needs a person: Sneak bar and sight cones on screen (sight rules tested 17 October)]
- [x] **Vortigaunts:** one lives in rebel territory from the start (`lc_rebel_vorts`). [a test proves it: Playtest fixes, 17 October: a vortigaunt lives in rebel territory]
- [x] **The body cart** (Mortician): F1 > Take a body cart by the incinerator; bodies let go beside it go on; push it; E on the incinerator burns them all. [a test proves it: Playtest fixes, 17 October: the body cart and the incinerator]
  Notes:

## Fixes from the 17 October evening playtest (what to check)

- [x] **Announcements:** only one voice for each thing (Overwatch or the Administrator, at random), never two at once (Half-Life 2's lines, your Overwatch and the Administrator wait for each other), fewer of them (the time of day, trains and skirmishes left out right after another), and no "new day" during a curfew. [replaced: Announcer pacing redone; check lines 1953 and 2054 instead]
- [ ] **Small things:** a running tap when you fill a bottle at a sink; Father Grigori quiet but for a line a minute; clinic medics without helmets; the HUD's left side never overlapping (the needs box, the line under it, the What now? card, then the rest). [needs a person: Ear and eye: the tap, Grigori's quiet, the HUD's left side]
- [ ] **Rebel territory:** fewer fighters in a small camp; nothing set down in a corridor or the sewer channel; fighters on dry ground first; sleepers lying on their mattresses with their eyes shut (if they still float or sink, `lc_rebel_bed_height`); hold E on a mattress, crate or chair to carry it and let go to set it down (R turns it); after a map change it's where you left it. [needs a person: Sleepers on mattresses by eye (camp rules tested 17 October evening)]
- [x] **Prices:** the quartermaster's radio costs what the lab's does; a forged ration card is 10. [replaced: The lab no longer sells radios or forged cards (line 2019)]
- [x] **Stash:** at your stash, "On you: crowbar / pistol... Stash it", and Take to get it back (magazine and all). [a test proves it: Playtest fixes, 17 October (evening): stash it, take it]
- [x] **The law:** run from a search: units and soldiers chase and cuff you, no shooting, unless you hurt someone or draw a gun. A curfew about you: the unit knows you (no warnings). A daytime curfew only with unrest, and it says so. [a test proves it: Playtest fixes, 17 October (evening): running from a search isn't violent]
- [ ] **Sleep:** in bed you can't move; Jump gets you up; you heal as you sleep; the eyelids fade softly; tiredness kept over a restart. [needs a person: Eyelid fade by eye (sleep rules tested 17 October evening)]
- [ ] **Sneaking:** the sight shown in 3D (walls and a lid), visible from below a slope. [needs a person: The 3D sight shape by eye]
- [x] **A squad:** C menu > Resistance > Squad: act casual (plain clothes, guns away: walk past units), guns out, and "meet me at the job's marker" (they go ahead and wait). Fired on while casual: guns out. [a test proves it: Playtest fixes, 17 October (evening): act casual, guns out, meet me there]
- [x] **Free a vortigaunt:** it waits shackled and harmless; the choice to cut the shackles or walk it out shackled; a unit may stop you; any rebel territory counts; it no longer hops up and down ladders. [a test proves it: Playtest fixes, 17 October (evening): cut the shackles or walk it out]
- [x] **The labs:** Dr. Kleiner, Eli Vance and Dr. Magnusson, one at each. [a test proves it: Playtest fixes, 17 October (evening): three labs, one scientist each]
- [ ] **Factory line:** every part grabbable, none spinning through or falling off the back; workers at the line facing the belt, quieter; nothing left clanking after. [needs a person: Real physics and ear: parts on the belt, nothing left clanking]
- [x] **Intake Processor** (was Station Porter): travelers walk up from the platform and away out of sight; the old woman's line reads right; the papers window gone when the shift's done; rations out mid-shift: Take a ration break. [a test proves it: Playtest fixes, 17 October (evening): Intake Processor, travelers, ration break]
- [x] **Raids:** a minute and a half before the Resistance hit the Combine, a notice and "Back up the raid" on your board (F3), with a waypoint. [a test proves it: Playtest fixes, 17 October (evening): a raid planned ahead, a job to back it]
- [x] **Sweeps (as Civil Protection or Overwatch):** a minute and a half before a sweep moves into rebel territory, a notice and "Join the sweep" on your board (F3), with a waypoint; when the Resistance raid the Combine, "Repel the attack" goes up at once. [a test proves it: Playtest fixes, 17 October (evening): a job to join the sweep]
- [ ] **Rewiring (Maintenance):** the board of circuit tiles: click turns a tile, right-click turns it back; the current lights up as far as it gets; a sparking tile bites; beat par for a bonus. Hard enough now? [needs a person: Difficulty: is rewiring hard enough]
  Notes:

## Fixes from the 20 October playtest (what to check)

- [x] **Announcements:** never two voices over each other (Overwatch's own lines, your recordings, the Administrator). [replaced: Announcer pacing redone; check line 2054 instead]
- [x] **Spawning:** put back where you left off with someone standing there: you're moved beside them, not stuck. [a test proves it: Playtest fixes, 20 October: spawned inside an NPC, moved out beside them]
- [ ] **Rebel camp:** hold E on a mattress or crate, look down at your feet while carrying it, let go: pick it up again (it never sinks into the floor). [needs a person: Real physics: a carried mattress never sinking into the floor]
- [x] **One territory:** rebel zones that touch are one camp: one quartermaster, one supply crate, one fire. A quartermaster left from a deleted zone is gone. [a test proves it: Playtest fixes, 20 October: touching zones are one territory, one quartermaster]
- [ ] **Rebels standing:** fighters stand up straight when there's nothing to crouch for (if you still see bent legs, tell me where and what they were doing). [needs a person: Fighters' standing pose]
- [ ] **The quartermaster's words** show under his window, not behind it. [needs a person: Where his words sit by the window]
- [x] **Food at the quartermaster:** beans and rations sell for 2 at most. [a test proves it: Playtest fixes, 20 October: the quartermaster pays at most 2 for food]
- [x] **The vest:** sleeping doesn't charge it. Charge cells (the lab makes them; dead units and downed scanners drop them) do, and a freed vortigaunt does when you press E on it. [a test proves it: Playtest fixes, 20 October: sleeping doesn't charge the vest, cells do]
- [ ] **Hacker:** F4 says a role sits on top of your rank (still a Fighter, its XP, the role's kit); the HUD shows "Hacker (Fighter)". [needs a person: HUD and F4 wording for a role on a rank, by eye]
- [x] **A new face** (the lab, 300 credits): wake with another face, not wanted, standing up to -50. [a test proves it: Playtest fixes, 20 October: the scientist will change your face]
- [ ] **The corner of the screen** with a rank (Resistance, Civil Protection...): faction and rank, credits, standing, WANTED. [needs a person: HUD corner by eye]
- [x] **Losing them:** wanted, out of every unit's sight 30 seconds: step out and only a unit who sees you comes. [a test proves it: Playtest fixes, 20 October: units lose track of where you are]
- [x] **Cuffed only when subdued:** three blows of the baton (dazed between), or standing still for them; never in noclip. [a test proves it: Playtest fixes, 20 October: a blow and dazed, cuffed when beaten down]
- [x] **Walked to the cells:** doors stay open for you; the unit leading you down, another takes your arm; a unit alone is joined by another; timed out: "struck from behind ... you come to in a cell" (no van). [a test proves it: MarchTests: walked to the cells]
- [x] **Stalkers:** only a rebel who has killed (or is in for murder). The cell door, the blows, black, machinery, waking as one. Then: no talking (E), no hunger or tiredness, nothing in your pockets, your board only the Stalker's Lot, no F4, no !characters. [a test proves it: Playtest fixes, 20 October: who is made a stalker, and what they lose]
- [ ] **The tired eyelids** shut all the way. [needs a person: Eyelids by eye]
- [x] **Father Grigori** moves between camps now and then when nobody's about. [a test proves it: Playtest fixes, 20 October: Father Grigori moves on, unseen]
- [x] **The jog:** the pace marker green while you keep up, red when behind; the city's joggers keep up; fall behind and a unit comes; joining late counts. [replaced: The morning jog is archived (line 55)]
- [x] **Radio repair:** two minutes a set (counting down), a moment between sets (fixed, or out of time), screws turned round and round. [a test proves it: Playtest fixes, 20 October: two minutes for each set]
- [x] **Supply drop:** one soldier turning to look about (warns you off twice, then wanted), two metrocops carrying boxes off down the street and back; prying a load is quiet, but a unit seeing you at it stops you. [a test proves it: Playtest fixes, 20 October: one soldier on guard, two metrocops unloading]
- [x] **The courier's clipboard** the right way up (if not: `lc_clipboard_angle`, pitch yaw roll). [replaced: The clipboard's hold was redone (line 176)]
- [x] **Job outfits** button in the editor opens the window. [a test proves it: Playtest fixes, 20 October: the Job outfits button has its own command]
- [ ] **Rainwater** drinkable as it is. [needs a person: No test found for drinking rainwater; try it]
- [x] **Sealed directives:** as the Administrator, right click the device: the office has Sealed directives (eleven envelopes with rhyming riddles, cold/warm/hot) and Orders. With one waiting, a bar at the top of the screen counts down; leave it to 5 minutes: the G-Man with an envelope, "Come back. Come back here, now.", and the bar turns red. Open the envelopes and close them without answering: "Get back here...". Run the city the bus's way (prices 75%, generous rations, a job bonus, six people online): its seal breaks, the envelope glows, Sign it starts the Party Bus. Refuse one instead: the G-Man over your screen ("We'll see about that"), walking off into the dark; crates turn up after 10 minutes (an SMG or shotgun, a vest and cells), the infestation spreads after 20, he's back at 30. With no Administrator, a superadmin gets a popup; with nobody, the G-Man's vote. Sleep: now and then the G-Man in your dream with a riddle. A vote of no: "Not this time." [replaced: Sealed directives are off by default since 7 November (line 989)]
- [x] **A unit's F1:** 2 is Unit tools (everything a unit has), 5 is Kick, voice lines at 6 when nothing's in front of you. [replaced: F1 is one general menu now; HQ calls are on the radio (lines 1001, 1860)]
- [x] **Kick reminder:** as a unit, stand close in front of a locked apartment door: "Locked. To kick it in: press G (or F1 > 5)"; change `lc_kick_key` and the key in the reminder changes too. Not on an always-locked or prison door. [replaced: The reminder reads 'F2 > 3' now (line 1011)]
- [x] **The G-Man's rival and the recall:** refuse a directive as the Administrator; two minutes on, another player who could run gets a visit, then a box at the side of their screen explains it with a countdown, and F1 has "Call a vote to remove the City Administrator": only units and the Administration get the vote on screen; more yes, and the office changes hands (the new one gets a visit: "interesting offers for your services"). An election: citizens see "Civil Protection and the Administration choose", no vote. [replaced: Sealed directives are off by default since 7 November (line 989)]
- [x] **His crates and glimpses:** look at one of his crates: "The right man in the wrong place..." (once, for you). While a directive is warm, now and then he's standing a way off, gone when you look at him. [replaced: Sealed directives are off by default since 7 November (line 989)]
- [x] **The Administrator's office:** tag a door with the editor's "Door: the City Administrator's office": locked to citizens ("Locked"), opens for the Administrator and staff, locks again; the Administrator's guards come through or appear beside them when stuck. [a test proves it: The v2.7 pieces: the office locked to a citizen, opens for the Administrator]
- [ ] **AFK:** 20 minutes idle: AFK and kicked (not at 5). [needs the real server: A real idle player and kick; no test (the tests switch it off)]
- [x] **Stamina:** sprint until the bar low on the screen runs out: "Out of breath", walking only, no jumping, the view breathing hard; it comes back after a rest, faster after a good night's sleep and when you're fed. The morning drill tires you too. [a test proves it: The v2.7 pieces: stamina, winded, breath back faster when rested and fed]
- [x] **Guns:** a citizen with a pistol out in front of a unit on the streets: wanted at once. Walk up to rebel ground with a gun out: LOWER YOUR WEAPON: hold R on screen before you're in, gone the moment you lower it; the fighters who can see you turn and face you and call out ("Heads up!", "Watch what you're doing!"); keep it up 10 seconds inside and they open fire; lower it and they leave you be. The same as a recruit or metrocop on the Combine's ground with the Overwatch's soldiers (not as a Division Leader or the Overwatch). NPCs never turn on each other over it. Elsewhere guns are ready, no lowering. [a test proves it: The v2.7 pieces: brandishing, lower it on rebel ground, ten seconds]
- [x] **Obituary:** die (or watch someone die): "[Obituary] Name, citizen #..., ..." in chat. [a test proves it: The v2.7 pieces: an obituary names them and their number]
- [x] **Street detention:** wanted for a few minutes, caught where there are no cells: held longer than 20 seconds (up to a minute). [a test proves it: The v2.7 pieces: wanted four minutes, held longer on the street]
- [ ] **Colour grading:** the city looks a touch colder and greyer; `lc_my_color_grade 0` turns it off for you. [needs a person: Colour of the city by eye]
- [x] **Running for Administrator:** the requirement message counts your Records Clerk shifts (20 minutes each). [a test proves it: The v2.7 pieces: Records Clerk shifts count towards running]
- [ ] **/stand** gets you up from /sit again. [unsorted: SlotActTests covers acts; could not confirm /stand after /sit]
- [ ] **Endings with a big crowd (100+ NPCs):** `lc_ending marrow now`: everyone in rings with room between them, nobody inside anybody, no NPC falling through the floor, no lag or disconnects. The console shows no "Ignoring unreasonable position" lines. [needs the real server: Real load: 100+ NPCs, lag and disconnects]
- [ ] **Endings menu:** "Changes" lists only what you changed; Bloom's hands right on people, and "The dance, on the Combine's units only" to tune theirs. [needs a person: Bloom's hands and the tuning list by eye]
- [x] **Shalom twice as loud, the Harpies twice as loud again; the Harpies' title on screen is THEY RETURN.** [a test proves it: Playtest fixes, 20 October: Shalom twice as loud, the Harpies' twice again]
  Notes:

## The Resistance's money (what to check)

- [x] **Intel:** F1 > Resistance > Write down what you see, near a checkpoint, a unit or the Combine's ground (with paper): notes the quartermaster buys (20 to 35). A unit seeing you takes the paper. [a test proves it: The Resistance's money: intel, written near a checkpoint]
- [x] **Skimming:** on the factory line, R while holding a good part: Union machine parts in your coat (dealer 8, quartermaster 12). Take several and the foreman may find the count short. [a test proves it: The Resistance's money: skimming on the line]
- [x] **Forged cards:** the lab makes five at a time. Sell enough (or use them) and a sweep comes for the camp nearest the lab. [replaced: Forged cards come from the quartermaster and dealer now, not the lab (line 2019)]
  Notes:

## Fixes from the 21 October playtest (what to check)

- [x] **Stalker scream:** half as loud. The job text no longer says their mouths are sewn shut. [replaced: The scream was turned down again (line 790)]
- [ ] **Stalker spawn:** wakes in the Combine's ground (a Combine-only zone), never at the station. [unsorted: Could not confirm a test for where a new stalker wakes]
- [x] **Stalkers left alone:** no "restricted area" in the Combine's ground; no unit warns, searches, beats, books or tells it to pick up a can; contraband on it doesn't matter. [a test proves it: Playtest fixes, 21 October: a stalker is never booked for anything]
- [x] **Stalker papers:** a red STALKER stamp across them. [a test proves it: Playtest fixes, 21 October: the STALKER stamp on its papers]
- [x] **Stalker jobs:** a technician walks up and fits the harness; the floors are a push broom and patches of grime (E each); cable is the rewiring board at two power banks; the frame is four cells to carry in and four seams to weld; the charge is the board again. [a test proves it: Playtest fixes, 21 October: the harness, grime to sweep, cells and seams]
- [ ] **Scanner far from its console:** the NPCs around it walk normally (no hopping or floating); the camera doesn't keep tipping up or rolling. [needs a person: The scanner's camera by eye (NPC rule tested 21 October)]
- [x] **Combine HQ:** mostly soldiers; metrocops on their beat don't wander in. [a test proves it: Playtest fixes, 21 October: a metrocop never wanders into the Combine HQ]
- [x] **Infested:** the Zombie and Zombine are no faster than a citizen; no picking up or holding guns; joining from F4 puts you in a nest; your kills don't make you wanted or bring announcements. [replaced: The infested are no longer on F4 (line 1997); speed and guns are tested]
- [x] **The jog:** the city's joggers keep to lanes and don't circle round each other; miss the start, then join the route anywhere: your own marker, and time to finish. [replaced: The morning jog is archived (line 55)]
- [x] **Radio repair:** "Write it down" on Freq 7 leaves the dial where it was and gives a Freq 7 sheet (Read it from your pockets: the seven frequencies; contraband). [a test proves it: Playtest fixes, 21 October: Write it down, a Freq 7 sheet]
- [x] **Radio repair NPCs:** put the work points on a table or bench: a radio sits there and the repairer stands at it working (nothing in their hands). [a test proves it: Playtest fixes, 21 October: a radio sits on the repair bench point]
  Notes:

## Safeguards (29 October: what to check)

- [ ] **Nothing normal is held back:** play as usual (menus, the radio dial, the rewiring board, shops, chat): nothing ignored, no "Slow down" unless you really type fast. [needs the real server: Real play on the real network: nothing held back by mistake]
- [x] **Chat:** seven lines in a row as fast as you can: "Slow down" on the seventh. [a test proves it: Safeguards for a public server: chat, six lines then the rest wait]
- [x] **Dropping things:** drop more than 30 things from your pockets: the oldest on the ground disappears. [a test proves it: Safeguards for a public server: the oldest drop is cleared away]
- [ ] **Tickets:** two `@` messages in a row: the second asks you to wait a moment. [unsorted: Staff tools tests use @ messages; could not confirm the wait]
- [x] **Rent:** an apartment door says 15 credits. [replaced: Rent is 50 now (line 424)]
- [x] **Lab prices:** nothing at the lab is cheaper than the quartermaster pays for it (gun parts 13, not 11). [a test proves it: Safeguards for a public server: gun parts cost more than the quartermaster pays]
- [x] **Cuffs** (once zip ties) sell for 1 at the black market; every menu and message says cuffs; `!cuff` works. [a test proves it: Safeguards for a public server: cuffs sell for 1, !cuff works]
- [x] **Couriers:** a parcel run opens with the sender's window: take it, hand it back, report (only when they won't say or own up), or open it (standing down, 1 credit a delivery instead of 3). A sender who owns up pays 8 extra when it's delivered. [a test proves it: Couriers and senders: take it, hand back, report, open]
- [x] **Smuggler** (Resistance, F4): smuggling runs on the board (F3), from the quartermaster to three drops; pays far better. [a test proves it: Couriers and senders; the Resistance's smugglers]
- [x] **Radio transmitter:** a radio alone only listens (`!r` says so); nobody transmits on the Union band. Units, and anyone with a Freq 7 radio and a radio transmitter (black market or lab): a Radio transmitter next to Hands. A unit with both: right click switches between the CP net and Freq 7. Switch to it: what you type and say goes over the band (others on it read and hear you anywhere; someone right beside you hears you; nobody else). R or switching away puts it down. A soft static hiss plays (just for you) while it's up. [a test proves it: The radio held up: chat and voice over the band]
- [x] **Freq 7:** no music: a voice line, then static for a couple of minutes; warnings still cut in. [a test proves it: Freq7Tests: no music by default, a voice line then a quiet spell]
- [x] **Healing:** no mending on your own while awake (even well fed); eating food mends a little; sleeping in a bed, medkits, bandages, the clinic still heal. [a test proves it: Playtest fixes, 31 October: no slow mending awake, food mends a little]
- [x] **Your apartment door, locked:** E rattles the handle, even for you; right click with your hands out (or !unlock) to unlock it. [a test proves it: Playtest fixes, 17 October: your own locked door just rattles]
- [x] **Ration line:** the person at the front walks up to the dispenser, takes the ration, and steps away. [a test proves it: CityFixTests, Ration lines, and BatchFixTests]
- [ ] **Rain:** blood and marks on open ground near you fade while it rains; graffiti stays. [needs a person: Blood and marks fading in the rain, by eye]
- [x] **Hacking** a vending machine or ration dispenser: a handful (5 to 8) comes out, not 3. [a test proves it: MachineHackTests: Hacking vending machines and ration dispensers]
- [x] **A unit's issued grenades:** can't be sold, dropped, stashed or given to a citizen; can be given to another unit. [a test proves it: Safeguards for a public server: a unit can't sell or hand on an issued grenade]
- [x] **BOLOs:** a second one straight away says to wait. [a test proves it: Safeguards for a public server: a second BOLO straight away waits]
- [ ] **Wanted:** the character form won't take a new name or face. [unsorted: Could not confirm a test for the character form refusing while wanted]
  Notes:

## Morning exercise and more (from the other session)

- [x] **Morning exercise:** every second dawn, the jog (keep up with the pace marker), the drill (copy the leader on your ring, then the skipping rope) or the parade (cheer the column). Needs its editor points: jogging route, exercise yard, parade route. [replaced: The jog is archived (line 55); drill and parade are in the Morning exercise tests]
  Notes:
- [x] **A full stomach:** hunger 85+ gives 15% more XP and slow healing. [a test proves it: Morning exercise: the parade, breakfast, a full stomach]
  Notes:
- [x] **The Harpies (lc_ending harpies now):** lights out, everyone at the LZ, mingebags gathering in the dark, the rush at the swell, the leaping, spectating the dead. Does the timing line up with the song? Does the pose look right? Citizens and other NPCs (no rebels) in the ring between you and the Combine? The Combine chattering out loud, opening fire as they leap, and actually dropping some? No "pick up that can"? The mingebags stay outside the ring until they leap; the Combine open fire 3 seconds before; they go for the Combine first, you have about 30 seconds to run, then it gets brutal; spawned citizens stand normally (no T pose). The song loud enough (lc_ending_song_volume); the citizens standing normally (not arms out). [replaced: The harpies were reworked on 11 November (lines 1759 to 1767)]
  Notes:
- [ ] **Bloom (lc_ending bloom now):** everyone dancing (NPCs too), the camera circling you, the coloured lights and sparkles, the speed-up at 2:01, the launches one at a time. Does the dance look right? (lc_bloom_preview to check it on yourself; lc_bloom_pose_print to send me the numbers.) Everyone at the landing zone with the Combine round them; hands clear of the head (higher still for the Combine's helmets); the body swaying in a curve from the waist with the feet on the floor (nobody hovering), the knees dipping in turn, palms facing forward (if they face back, `lc_bloom_palm -90`) and hands flapping at the wrist like ears; the burst when each dancer spins up is a big flash and confetti everyone can see, and only a soft pink tint on your own screen; no city music over the song (in any ending); no inspections, wanted notices or lost standing during any ending. [needs a person: Bloom's dance, lights and timing by eye]
  Notes:
- [ ] **Marrow (lc_ending marrow now):** skeletons dancing their way in, the drops (everyone dancing, the Combine's units too, strobes), the attacks in between, turning into a skeleton, the outro. Do the sections line up with the song? Doors locked open? More and more skeletons (15 at first, 80 by two thirds through); the kicks in the dance; the Combine shooting them in the fights; you can always outrun one, but the crowd gets everyone by the last fight. Skeletons in sight from the very start; purple and orange spotlights sweeping in the dances; the song loud enough over the fights; the Combine not mowing them down too easily. [needs a person: Marrow's dance, timing against the song]
  Notes:
- [ ] **The Bus (lc_ending bus now):** the bus driving about, everyone seated on the drop, the rainbow trail, the rings popping, the speed on the beat, the landing at 2:29 and the faster take-off. How does the seated pose look? It roams the open air from one far-off spot to the next (never circling one spot, never up into the sky); on the ground it still drives through anything. The light rig on the roof: spotlights sweeping every colour, strobes on the beat, the underglow. [needs a person: The bus, the seated pose, the lights]
  Notes:
- [ ] **The Flood (lc_ending water now):** the stage at the LZ, the storm, the water rising, the waves knocking people off, swimming back, the ichthyosaurs, drowning, Father Grigori on the mic, headbanging the heavy parts and dancing the rest,, and going last. Does the water surface look like water? Does the headbang nod the right way (lc_headbang_angle)? The stage's deck above the water, rising smoothly with you on it (no getting stuck, no jerking up); Father Grigori there even when an admin starts it; a crowd headbanging with him, swept off by the big waves. Grigori's whole upper body banging on the beat (lc_headbang_angle "0 0 -30" if it's backwards); the swept crowd floundering under the surface (not through the ground) and eaten; holding Jump at the edge climbs you back on; jump to fly free once you're out. [needs a person: The water, the headbang, the stage]
  Notes:
- [ ] **Base (lc_ending base now):** the subtitles lining up with the spoken lines (move them with lc_ending_base_lines), the bombs, CATS in the sky, the ZIG fleet, the explosions, the white, Engrish chat. Every subtitle on its line, "What !" included (each was a line late before), not drifting behind; the fleet never up in the sky; lots of bombs (the debug report's log says how many were set up); the fleet in open sky. [needs a person: Subtitles against the spoken lines, the fleet in the sky]
  Notes:
- [ ] **Hard (lc_ending hard now):** everyone at the LZ doing the mirror-flip dance, PARTY HARD everywhere, the strobe, the freeze at the break, people passing out one at a time. The Combine going for it all through (crowd surfs, spins, backflips with confetti), two or three at once. [needs a person: The dance, strobe and Combine moves by eye]
  Notes:
- [ ] **The Shalom song:** upload shalom1.mp3 (delete the old shalom.mp3), FastDL sync, change the map, reconnect, then `lc_sound_check`: it lists each ending song and says "plays" or why not. [needs the real server: Upload shalom1.mp3, FastDL sync, then lc_sound_check]
  Notes:
- [x] **Everyday fixes:** citizens delivering boxes or crates carry them out in front in both hands (not swinging from one hand like a suitcase); switching faction from F4 keeps you where you are; if Civil Protection or citizens stop turning up, a superadmin gets an "NPC cap" notice (`lc_npc_budget` was 10 on the server: set it back to 60). [a test proves it: Playtest fixes: switching faction where you stand, boxes in both hands, the NPC cap]
  Notes:
- [ ] **Pose Recorder (the separate addon, pose_recorder.zip):** Tools, Poser, Pose Recorder. Spawn a mannequin from the panel: is it your model, standing, limbs frozen? Pose an arm with the physgun, right click: "Keyframe 1". Pose it differently, right click again. Reload: does the blue ghost beside it play the loop, and do its poses match the mannequin's exactly (that's the test of the maths)? Try "Record / stop" while moving a limb. Copy, and paste the result to me; Save and Load. Then pose a real dance (Bloom's, Grigori's headbang, the hora) and send it over. [needs a person: The Pose Recorder addon, judged by eye]
  Notes:
- [ ] **Fixes from the last playtest (bone axes worked out from what you saw: tell me which still look wrong):** [needs a person: Ending poses and effects: which still look wrong]
  - Flood: no biting or leaping till 2:20, softer bites and waves, 15 s of breath; rowboats to climb into (Jump from the water); stage lights; Grigori nodding on the beat (if backwards, `lc_headbang_angle "-35 0 0"`), mic at his mouth, elbow forward, not a chicken wing.
  - Plane: a real barrel roll, everyone on the wings staying on through it; if the plane flies sideways, `lc_ending_plane_model_yaw 90` (or 0, 180); turn the camera with the mouse; arms rolling in front of the chest; nobody running on the spot; some fireworks big bangs.
  - Harpies: no mingebags stuck behind walls; dead stays dead till the reload.
  - Standup: a white cone on every hanged head (yours and everyone's); every metrocop strung up.
  - Bus: through buildings, never up into the sky; on its wheels on the road; mouse turns the camera.
  - Bloom: feet on the floor, a curvy sway, palms forward (`lc_bloom_palm -90` if they face back), bursts everyone can see.
  - Marrow: skeletons only dancing through the opening; the city's people with you; no crash at the second dance (lc_ending marrow now, and watch the server console).
  - Hard: spotlights; bodies staying put.
  - Base: mouse camera; the score, the 1000s, the exhaust trails; a barrage of bombs at the end.
  Notes:
- [ ] **Shalom (lc_ending shalom now; the song is shalom.mp3):** the flags running up their poles one after another on the intro's hit, and waving (the star and stripes the right way up); the hanukkiah in the middle facing you wherever you stand, the shamash lit from the start and a candle lit each phrase (with a little whoosh), all eight by the key change. Do the kippahs sit on top of every head, a little towards the back (each player can move them with `lc_shalom_kippah "6.5 0 -1"`: forward right up)? Are the Hebrew sayings readable and the right way round (right to left), on your Linux machine and on Windows? Do the arms look like they're on the neighbours' shoulders (tune with `lc_shalom_pose R_UpperArm -30 -75 0` and so on, then `lc_shalom_pose_print` to send me the numbers)? Does the grapevine step look right (if a leg goes the wrong way, say which)? The rings walking round smoothly, opposite ways; the Combine dropping their guns and joining at 1:02; the chair lifts: the chair is now drawn right under the rider's hips (if it's too high or low, or faces the wrong way, `lc_shalom_chair "21 0"`: how far below the hips, and a turn); if the rider's legs don't look sat down, tune them live with `lc_shalom_pose chair R_Thigh 0 -85 0` (and L_Thigh, R_Calf, L_Calf) and send me `lc_shalom_pose_print`, or pose a sitting mannequin with the Pose Recorder and paste me the JSON; the rush into the middle and back on the breakdowns; the giant flag in the sky and the Star of David fireworks at 3:25; Am Yisrael chai, then Shalom at the end. [needs a person: Shalom: flags, kippahs, arms, chair lift, Hebrew text by eye]
  Notes:
- [ ] **Fire (new; lc_ending fire now; put the song in garrysmod/sound/livingcity/endings/fire.mp3):** the sputtering and smoke through the intro; every behind lighting up at the drop (0:12), flames going out the back and down; the bent-over dance; the hops from 1:00; the liftoff at 1:41 and everyone flying round the ring, bodies flat out Superman style with the flames trailing behind (if anyone flies on their back or upright, open the Endings menu, pick Fire, the "fly" move, and turn the Pelvis); the camera behind you in the air; the rockets up and the fireworks at 2:27. Do the sections line up with the song? [needs a person: Fire: flames, flying pose and timing (needs fire.mp3 on the server)]
  Notes:
- [ ] **Plane (lc_ending plane now):** everyone on the wings doing the webcam dance and mouthing the words, the webcam box in the corner, the captions, the barrel rolls, the fireworks, the climb into the clouds. Do the captions line up (lc_ending_plane_captions)? Do the wings look right? The plane (and the bus, and the ZIG fleet) stays in open sky, never through a building, and the camera never ends up in the void? [needs a person: Plane: captions, wings, camera]
  Notes:
- [ ] **Standup (lc_ending standup now):** someone strung up every other beat, where the ropes go (overhead, walls, sky), the struggling and going limp, the view from the rope. Hanging still on the rope, not running in place; the white cone hats showing; and everyone limp before the song ends, even the last to go up. On the rope you can look about (the camera moves; your body's head doesn't turn after it); the white cone hats on everyone strung up (real props now); hanging in a standing pose, not arms out. [needs a person: Standup: ropes, hanging pose, cone hats]
  Notes:
- [ ] **Flashing warning:** before an ending with strobes, the popup stays up 15 seconds (counting down) before keeping the flashing; Reduce flashing turns it off for you. [needs a person: The flashing warning popup on your screen]
- [ ] **Running sway:** running looks like a grown-up's stride (about three steps a second), not a toddler's bounce; walking unchanged. [needs a person: How running looks]
- [x] **Secret endings:** the G-Man stops time and everyone votes (he's right in front of you whichever way you were looking, your view held on him, and the city's announcements stop); Father Grigori eating a master data core (Eat it in his pockets, or /eatchip) starts the flood (admins: lc_ending <id> now). Once you're out of an ending, left/right click watches someone else and jump flies free (in every ending). The G-Man moves: his idle, straightening his tie now and then, his mouth going as he speaks (each player sees their own, in front of them). [replaced: The G-Man's vote is set aside since 7 November (line 989)]
  Notes:

## Death and progression

- [x] **Close calls:** three per person; you wake in the infirmary with empty pockets; a used one comes back with time. [a test proves it: ProgressTests: Close calls, careers for life, inheritance and the levy]
  Notes:
- [x] **Final deaths:** a stalker's death, the energizer, or retiring a character (!characters). [a test proves it: LifeTests (the end of a life) and ProgressTests]
  Notes:
- [x] **For life:** the Overwatch conditioning and being a stalker can't be undone. [a test proves it: ProgressTests: careers for life]
  Notes:
- [x] **Inheritance:** the next person gets 25% of the savings, up to 200. [a test proves it: ProgressTests: inheritance]
  Notes:
- [x] **Union levy:** anything over 2000 credits is taxed every half hour. [a test proves it: ProgressTests: the levy]
  Notes:
- [ ] **Legacy:** !characters shows your past lives. [unsorted: Could not confirm a test for !characters listing past lives]
  Notes:

## Looks

- [ ] **Black Mesa faces:** with the pack (534130993) on the server, about half the jobless NPCs wear its citizens and refugees (women in the women's models); the character creator also offers its citizen and refugee looks; no ERROR models. [needs the real server: Needs the Black Mesa Workshop pack on the server]
- [x] **Outfit designer:** editor panel > Job outfits (or !outfits). No job is dressed by default (the Clinic Medic is in their own clothes now). [a test proves it: OutfitSquadTests: Job outfits]
  Notes:
- [ ] **Welcome announcement:** plays when an unregistered person joins (or a new character arrives), and not when someone already registered rejoins. [unsorted: Could not confirm a test for who hears the welcome announcement]
- [ ] **Sound files:** `lc_sound_check` (your console) counts the city's sounds on your computer and test-plays one; a sound you can't hear shows a "Sound missing" notice. `lc_announce_clips` shows no CAN'T PLAY lines (an MP3 renamed .wav, or a WAV that isn't 16-bit 44100 Hz), and a superadmin gets a notice on joining if there are any. MP3 announcements queue properly (the Administrator, then Overwatch, for the welcome). [needs the real server: Your sound files and lc_sound_check on the real server]
- [ ] **Character creator:** installed citizen packs, face skins, clothes and accessories. On a dedicated server, a joining player downloads the Workshop citizen packs and sees no ERROR models. [needs the real server: Workshop citizen packs downloading to a joining player]
  Notes:
- [ ] **Variety:** NPCs are slightly different heights, and citizen shirts have their own drab colours. [needs a person: Heights and shirt colours by eye]
  Notes:

## Anything else you noticed

Notes:
- [ ] **Performance pass (2026-11-07):** in the rain, look ahead, up and down: the streaks look as before. Crouch near a unit: the sight cones show. As a unit, a scanner photo outlines the suspect. Earn or spend credits, reconnect: the amount is right. [needs a person: Rain streaks, sight cones, scanner outline by eye]
  Notes:
- [x] **Out of breath (7 November):** run until winded; the panting stops once stamina is back (8 seconds at most), and after a respawn. [replaced: Same check repeated later (line 975)]
  Notes:
- [ ] **Sleep again (7 November):** after a night in a bed, try the bed again later: refused with about how many in-game hours are left; allowed 18 in-game hours after. [unsorted: HygieneTests covers beds and sleep; could not confirm the 18 hour refusal]
  Notes:
- [ ] **Weather (7 November):** no chat line when the weather changes. [needs a person: No test found; watch chat when the weather changes]
  Notes:
- [ ] **Stalker (7 November):** made a stalker: the whirring plays once and stops, the breathing stops, the music cuts to hl2_song26 (is it the sad one you meant?), the scream on E is quieter (0.3). No bed, toilet or bath; no HOME on the curfew bar. [needs a person: Ear: the whirring, breathing, music and scream]
  Notes:
- [x] **G-Man dream (7 November):** sleep: dark, he fades in over 3 seconds (no black square over his mouth), the riddle follows, 26 seconds in all; his inhale plays (or a sound/livingcity/gman/dream*.wav if you add one; FastDL sync and a map change first). [replaced: The G-Man in your sleep is set aside (line 989)]
  Notes:
- [x] **Unit F1 (7 November):** 1 Voice lines, 2 Unit tools, 3 Kick, 4 Call for backup, 5 BOLO, 6 Send my 10-20. [replaced: F1 is one general menu now; HQ calls are on the radio (lines 1001, 1860)]
  Notes:
- [ ] **Sociostability (7 November):** as a recruit (even as a server admin) no Sociostability in F1, Unit tools, C or the records terminal; as the Administrator it is there (F1, C > The city). [unsorted: CPToolTests covers sociostability; could not confirm the recruit rule]
  Notes:
- [ ] **Dealer and scientist (7 November):** they move: idles change every so often, the head follows you when you stand near, E makes the dealer reach to his rack and the scientist reach for his work; a unit busting the dealer sees him cower. [needs a person: Dealer and scientist animations]
  Notes:
- [x] **Cleanup guards (7 November):** take an Infestation Cleanup shift. Two Overwatch soldiers should arrive (one shotgun, one pulse rifle), standing apart, and no metrocops. When the shift ends they walk off. [a test proves it: The 1 November playtest: two Overwatch soldiers, a shotgun and a pulse rifle]
  Notes:
- [x] **Cleanup guards fighting (7 November):** with a zombie behind a wall, the soldiers walk round to it rather than shooting the wall. In the open, the pulse rifle fires steady bursts. [a test proves it: The 1 November playtest: the guards go round, nobody shoots the wall]
  Notes:
- [x] **Guard in a doorway (7 November):** walk into a guard blocking a doorway. They step aside. [a test proves it: The 1 November playtest: walk into a unit in a doorway, it steps aside]
  Notes:
- [ ] **Warning posts (7 November):** at each infestation's edge, the sign, lamp and barrel stand beside the way in, not on the marked path, and none is inside a wall or floating. [needs a person: Real map: posts beside the way in, none in a wall]
  Notes:
- [ ] **Longer cleanup shifts (7 November):** the first shift asks for 3 growths, the next 5, then 7. With all visible growths cleared, more appear where you aren't looking. [needs a person: No test found for 3, then 5, then 7 growths; try it]
  Notes:
- [x] **Bags (7 November):** NPCs and you walk through the bags the cleanup crew leaves. [a test proves it: The 1 November playtest: a bagged growth is passable]
  Notes:
- [x] **Union kit after a reboot (7 November):** as a Groundskeeper or Infestation Cleanup, rejoin after a server restart, and get released from prison: the sprayer (and hoover) are back. [a test proves it: Occupations: the sprayer and hoover come back on release from prison]
  Notes:
- [x] **Union job revoked (7 November):** as Infestation Cleanup, become a CP recruit: hoover, sprayer and weedkiller are gone. As a worker, become an anticitizen: the job and hoover go, the weedkiller stays. [a test proves it: UnitLifeTests: a unit holds no Union job, and the job's tools go]
  Notes:
- [x] **Job change limit (7 November):** change Union job twice in a row from F3: the second is refused with the minutes left (15 minutes). [replaced: The limit is 30 minutes or 4 shifts at the terminal now (line 927)]
  Notes:
- [ ] **Sanitation worker clothes (7 November):** watch a city sanitation worker empty several bins, also at curfew: the hazmat suit stays on. [needs a person: Watch a worker: does the suit stay on (cleanup crew rule tested 1 November)]
  Notes:
- [ ] **Hoover (7 November):** hold it: the pack sits about 2 feet further out; vacuuming a dead growth plays the airboat motor under the usual hiss, and it stops when you let go. [needs a person: Hoover placement and its sound]
  Notes:
- [ ] **Weeds (7 November):** look at several weeds around the city: all sit on the ground. [needs a person: Real map: weeds sitting on the ground]
  Notes:
- [ ] **Incinerator (7 November):** after a map change, walk to the mortician's incinerator without touching it: fire is burning in it. [needs a person: Fire in the incinerator after a map change, by eye]
  Notes:
- [ ] **Commissary signs (7 November):** the Union Commissary and the CP Commissary have a floating blue sign like Civil Intake's. [needs a person: The floating signs by eye]
  Notes:
- [x] **Running (7 November):** run past a metrocop until he chases you and let him catch you. You should be cuffed, hit three times, hear a laugh and "All right, you can go", and lose no standing. Do it three times within an hour: the third time is prison. [a test proves it: RunningTests: Running in front of Civil Protection]
  Notes:
- [ ] **Infestation zone (7 November):** sprint past a unit inside an infestation zone and bump into one there. No "STOP RUNNING" and no shove. [needs a person: No test found for running inside an infestation zone; try it]
  Notes:
- [ ] **Escort shove (7 November):** walk into the unit escorting you on a job. He should not shove you. [needs a person: No test found for the escort not shoving you; try it]
  Notes:
- [x] **Prison guards (7 November):** get jailed and look at your cell. No guard or soldier should stand inside it, and the door should stay shut. [a test proves it: PrisonDoorTests (Prison doors stay shut) and UpdateTests, Cells stay locked]
  Notes:
- [x] **Overwatch Commander (7 November):** as a Recruit (even as superadmin), open F4. Overwatch Commander should be refused. [a test proves it: MergeKickTests: the Overwatch Commander]
  Notes:
- [x] **Turrets and power banks (7 November):** as a Recruit or Division Leader, open Unit tools. There should be no deploy buttons; as Overwatch there are. [a test proves it: CheckpointTests: only the right units put turrets up]
  Notes:
- [x] **Scanner (7 November):** as any unit, F1 > Unit tools > Fly a scanner at a Combine console. F4 should no longer list a Scanner Operator role. [a test proves it: OperatorDoorTests: Any unit flies a scanner from a terminal]
  Notes:
- [ ] **Freeze (7 November):** as a Recruit, play the "Freeze" voice line. You should hear "Don't move!". [needs a person: Ear: the line you hear]
  Notes:
- [x] **Backup squad (7 November):** call for backup. When the units reach you, chat should say they're in your squad, and they should follow you and attack whoever you shoot. [a test proves it: SquadSizeTests and WarTests, Backup and 10-20s]
  Notes:
- [ ] **Rebel kill (7 November):** as a unit, kill a rebel. You should get +5 standing, +2 credits and a box of rounds, with a notice. [unsorted: Could not confirm a test for the reward on killing a rebel]
  Notes:
- [x] **Power bank vest (7 November):** stand close to a live power bank. The label should show; as a unit, hold E to recharge your vest. As a citizen with a vest, it charges but a watching unit books you. [a test proves it: CheckpointTests: E on a live power bank charges a unit's vest]
  Notes:
- [x] **Ration line, front of the line (7 November):** During a distribution, watch the citizen in spot 1. They walk up to the dispenser, take a packet and leave, and the line moves up. [a test proves it: CityFixTests, Ration lines]
  Notes:
- [x] **Ration line, your ration (7 November):** With a ration card, stand at the front of the line during a distribution. You get a packet within a few seconds. If you are refused, the citizens behind you go on past you to the dispenser. [a test proves it: CityFixTests, Ration lines]
  Notes:
- [x] **Ration line, docked newcomer (7 November):** As a new character, get docked by a nearby Resistance attack, then collect your first ration. You get it, and chat says the deduction comes off the next one. [replaced: No exception for a newcomer any more (line 917)]
  Notes:
- [ ] **Ration line supervision (CP) (7 November):** Take the job during a distribution. Citizens come to the line. "The line is restless" appears only after the first citizen has collected, and the job completes after two more. [needs a person: No test found for the supervision job's timing; try it]
  Notes:
- [x] **Beds, taken (7 November):** At night, try several empty beds. None says "Someone's already asleep in this bed" unless someone is lying in it. [a test proves it: HygieneTests: no 'already asleep in this bed' on empty beds]
  Notes:
- [ ] **Beds, sleepers (7 November):** Visit a housing block and a rebel camp at night, also by noclipping in fast. Sleepers lie flat on the mattress with eyes shut and no guns, nobody stands on a bed marked "asleep", and looking at a sleeper shows their name and "asleep". [needs a person: How sleepers lie, by eye]
  Notes:
- [ ] **Beds, waking (7 November):** Watch sleepers get up in the morning, or when hurt. They stand beside the bed in the same room, not through the wall and not in the ceiling. [needs a person: Real map: sleepers getting up beside the bed, not through a wall]
  Notes:
- [x] **Street vortigaunts make way (7 November):** walk into a collared sweeper in a doorway, and watch a metrocop walk at one. It should step aside. [a test proves it: The 1 November playtest: a street sweeper walked into steps aside]
  Notes:
- [x] **Street vortigaunts sweep (7 November):** watch one for 20 seconds. It should hold a push broom, swing it, and pace back and forth. Say if the broom sits wrong. [replaced: The broom's hold was redone (line 72)]
  Notes:
- [x] **Shackled vortigaunts run from headcrabs (7 November):** spawn a headcrab next to a collared sweeper. It should run, never zap. [a test proves it: The 1 November playtest: a headcrab near, it runs, no vortessence]
  Notes:
- [x] **Rebels spread out (7 November):** visit a small rebel zone. There should be fewer fighters, on open floor, not packed into doorways or hallways. [a test proves it: RebelTests: Rebels keep out of doorways, a camp isn't packed]
  Notes:
- [x] **Citizens under gunfire (7 November):** fire a gun near citizens. They should run from you, and some should crouch and cover their heads first. [a test proves it: The 1 November playtest: a citizen who hears a gun runs or covers their head]
  Notes:
- [ ] **Raw fish prop (7 November):** drop a raw fish: a grey pod, not a newspaper; fried fish is a takeout carton. [needs a person: The fish props by eye]
  Notes:
- [x] **Bird carcasses (7 November):** punch a crow, a pigeon and a gull: each leaves its own body (crow, pigeon, gull), named Raw crow / Raw pigeon / Raw gull; all roast to Roast bird. [a test proves it: Hunger, thirst and survival: each bird leaves its own carcass]
  Notes:
- [x] **Spoilage (7 November):** carry a raw and a roast bird: F2 shows "spoils in 24h" counting down in city hours (lc_day_minutes 60: one real hour); after a city day they vanish with a "gone off" card. Put one in a locker and come back a day later: it's gone from the locker too. Drop one and pick it up: the hours left carry over. [a test proves it: Hunger, thirst and survival: raw and roast show the city hours left]
  Notes:
- [ ] **Fishing line (7 November):** buy one line (15 credits) and fish until it snaps: 4 to 8 casts, with a "fraying" warning before the last. [needs a person: GettingByTests covers fishing; the fraying warning has no test found]
  Notes:
- [ ] **Birds outdoors only (7 November):** walk the underground and indoor areas for a while: no pigeons, crows or gulls; they still turn up where the sky is open. [needs a person: Real map: no birds indoors or underground]
  Notes:
- [x] **Shop prices (7 November):** at the black market, quartermaster or Union Commissary with too few credits, check each item shows its price and "Not enough credits, N short" beside its name. [a test proves it: UndergroundTests, The black market: Not enough credits and how many short]
  Notes:
- [x] **Shop scroll (7 November):** sell something far down the black market list; the list should stay where you were. [replaced: Same check redone on 14 November (line 25)]
  Notes:
- [ ] **Bypass charge (7 November):** use one on a glitchy Combine door, and try having a unit work it from the other side; it should stay open for 10 seconds and then be passable until 30. [needs a person: A real glitchy Combine door on the map]
  Notes:
- [ ] **Cuffs text (7 November):** read the cuffs description in the shop and in your pockets; it should say who you can cuff and how. [needs a person: Reading: does the cuffs text say who and how]
  Notes:
- [x] **Call box (7 November):** buy one, open F2, press Call for help beside it, type what's wrong; units should get the request. The tip should name F2. [a test proves it: CPToolTests: /request (the call box)]
  Notes:
- [x] **Full pockets (7 November):** with a satchel and two large things, take off a bought CP uniform; the message should say it's the large-things limit and how to make room. [a test proves it: DisguiseTests: the large-things limit message]
  Notes:
- [ ] **CP disguise model (7 November):** with an HL:Alyx metrocop playermodel installed (or set with lc_pm_metrocop), put on a bought CP uniform as a rebel; you should wear the same model as the units. [needs the real server: Needs the Half-Life: Alyx metrocop model on the server]
  Notes:
- [ ] **Popups (7 November):** make a new character; the cards at the top and the tips on the right should come one at a time, each readable, never piled up. [needs a person: Cards and tips: one at a time, readable]
  Notes:
- [ ] **No ring (7 November):** die and make a new character; no "wedding ring" popup or ring in your pockets. [needs a person: No test found for the ring being gone; a glance at a new character]
  Notes:
- [x] **Your story (7 November):** as a new character, F3 shows no "YOUR STORY" quest until you've finished 2 to 4 ordinary jobs; Union shifts still show from the start. [a test proves it: Stories: Internal Affairs (a story waits for 2 to 4 ordinary jobs)]
  Notes:
- [ ] **Gestures (7 November):** F1 > Gesture > Wave (and the others) with a camera on yourself; the body should play each one. [needs a person: Gestures on your body by eye]
  Notes:
- [ ] **Hands up (7 November):** F1 > 2 with a camera on yourself; the body should not slide forward or back. Get searched by a unit: a tip says to put your hands up. [needs a person: Hands up pose: no sliding]
  Notes:
- [ ] **Administrator (7 November):** become Administrator with a female face (Mossman) and with a male face (Breen); step down and get your own face back. [needs a person: The Administrator's face on you, by eye]
  Notes:
- [ ] **Missing unit (7 November):** the infestation version of "Gone dark" talks about headcrab blood, not shells. [needs a person: Wording of one job text; no test found]
  Notes:
- [x] **The can (7 November):** a cop's "pick up that can" should only happen near a bin, never in the infestation zone or on a job; pick it up and a marker shows the bin. [a test proves it: SlotActTests, Acts: no 'pick up that can' while on a job]
  Notes:

## 7 November, part 2 (the second list)

- [x] **First ration (7 November, part 2):** as a new character near a Resistance attack, your first ration is docked like any other (you said no to the exception). [a test proves it: CityFixTests, Ration lines: a new life's first ration is docked like any other]
  Notes:
- [x] **CP uniform back in your pockets (7 November, part 2):** buy a CP uniform as a rebel, fill your pockets with large things while wearing it, change to plain clothes: the uniform goes back in your pockets, not on the ground. [a test proves it: DisguiseTests: out of the CP uniform, it goes back in your pockets]
  Notes:
- [ ] **Kick, legs only (7 November, part 2):** kick as a unit with the HL:Alyx model: in first person only the legs show, no mask. [needs a person: First person kick: only the legs]
  Notes:
- [x] **Join the sweep (7 November, part 2):** take "Join the sweep" and wait at the edge: the team comes to you ("The sweep team is with you") and goes in with you. If another fight is on, the sweep waits for it; if it can't happen, you're told it's called off. [a test proves it: Playtest fixes, 17 October (evening): the sweep waits, then the team meets you]
  Notes:
- [x] **Rebel food scaling (7 November, part 2):** as the only Resistance player, eat from the supply crate for an hour: about one tin every 40 minutes, and it is often empty. Empty, it says so on screen with where else to find food and when more is due. Look at the crate: meals stored and "More supplies in about N minutes". Donate cooked fish, a headcrab or a bird as a citizen: it goes in. [a test proves it: RebelFoodTests: supplies sized to the Resistance online]
  Notes:
- [x] **Labor Assignment (7 November, part 2):** place "Fixture: Labor Assignment" with the editor. As a new character: register at Civil Intake, try Housing Allocation (it refuses and marks Labor Assignment), get your assignment at the terminal (the job with fewest people), then get a room. F3 shows no job list, only "Go to a Labor Assignment terminal" and a way button. The terminal refuses a change before 30 minutes or 4 shifts, also after a rejoin; after that, pick a new job, with Infestation Cleanup locked below standing 25 and Intake Processor below 50. As superadmin on a map without the terminal, you get one notice. [a test proves it: LaborTests: Labor Assignment, Union work given out in person]
  Notes:
- [x] **Shared dreams (7 November, part 2):** place Point: dream out of the map (and Zone: dream round it), trigger an ending (C > Help > Dreams > dream it now, or a directive), sleep at night with a second player awake: the awake one sees nothing, the sleeper dreams it at the dream point, then wakes in bed with weapons, rounds, ammo, pockets, credits, hunger and clothes as before. Try opting out mid-dream (C > Settings > Shared dreams), disconnecting mid-dream and rejoining, and C > Help > Dreams > Put back. [a test proves it: DreamTests: Shared dreams, the endings as dreams for everyone asleep]
  Notes:
- [x] **Old job gone on becoming a unit (7 November, part 2):** as Infestation Cleanup, become a metrocop, then reconnect after a restart: no job on the card, no suit gloves or skin on any viewmodel, no hoover or sprayer. [a test proves it: UnitLifeTests: the old job's looks and kit go]
  Notes:
- [x] **Ration voucher (7 November, part 2):** as a unit, the duty allocation is a voucher, not a packet; E at the CP Commissary or a dispenser swaps it. [replaced: Owner tried it; the rate was changed and relisted at line 157]
  Notes:working well, but too often, I am getting too may ration vouchers compared to hunger; can the rate be reduced 30%?
- [x] **CP Commissary kit and vest (7 November, part 2):** one health vial and bandage a city day; stand there with low armour and watch it charge (not with the power out). [replaced: Owner tried it; the sound and vial fixes are at line 159]
  Notes: vests charge for CP units at commissary automatically, but the charging sound NEVER STOPS. We seem to ALWAYS have issues with sounds looping eternally and they really need to NEVER to do so. health vial also does not go into pockets if health is full, it instead falls to the floor. If health is full, it needs to go into pockets for later use.
- [x] **Radio away (7 November, part 2):** as a metrocop, raise the radio and press R: it goes away and stays away. [replaced: Owner tried it; the fix is at line 145]
  Notes: yeah stays away too well, I can't pull it out, it glitches the animation and shows out for 1 frame but otherwise is stuck put away.
- [x] **Editor tool and sleep (7 November, part 2):** hold the editor tool for a long while: never exhausted. [replaced: Owner tried it; the fix is at line 196]
  Notes: and the second I put the tool away I am exhausted, can we not have it pile on and catch up the instant I put it away? or maybe it was coincidental timing and this isn't working at all.
- [x] **Baton arrest (7 November, part 2):** arrest a citizen: a unit walks over and walks them to the cells, no teleport. With no unit about, the cuffed NPC follows you; F1 > Walk them to the cells / let go. [a test proves it: ArrestOverhaulTests: Arrests in the open, walked to the cells]
  Notes:
- [x] **Struggle (7 November, part 2):** arrest a player and a rebel: the bar shows on both screens and pressing E fast decides it. Broke free: the officer is shoved back and the NPC runs flat out. Arrested yourself: press E fast to break free, or hands up to go quietly. [replaced: The struggle has no bar now, it is felt (line 1910)]
  Notes:
- [x] **Apprehend job (7 November, part 2):** a failed Authority check: the suspect shoves you back and runs off properly, a real chase. [a test proves it: ArrestOverhaulTests: a shove and a run]
  Notes:
- [x] **Soldiers stay home (7 November, part 2):** with a Combine zone placed, idle Overwatch soldiers stay inside it; a lockdown, red sociostability, a raid or a backup call brings them out. [a test proves it: CombineSoldiersHomeTests: soldiers stay inside the Combine zones unless deployed]
  Notes:
- [x] **Citizens out of Combine zones (7 November, part 2):** no sanitation workers or groundskeepers inside; drop a can inside, wait 5 minutes: a stalker appears out of sight, picks it up and leaves. [a test proves it: CombineCitizensOutTests: citizens stay out; a stalker clears up in there]
  Notes:
- [x] **Rebel warning in the Combine building (7 November, part 2):** in the Combine zone under the rebel zone, no rebel warning or banner; up in the rebel zone, it shows. [a test proves it: CombineRebelWarningTests: no rebel territory warning inside a Combine zone]
  Notes:
- [x] **Dead headcrabs (7 November, part 2):** sanitation workers pick them up, and ones left alone vanish after about 5 minutes when nobody is near. [a test proves it: CrabCarcassCleanupTests: Dead headcrabs get cleared away]
  Notes:
- [x] **Retake the block (7 November, part 2):** every rebel on the ground must go, none respawn while you clear them, then a wave hits while you hold. [a test proves it: RetakeFieldTests: every rebel on the ground, no respawns, the counterattack]
  Notes:
- [x] **Backup armed (7 November, part 2):** call backup with a gun out or after being shot at: they come with pistols and SMGs, not sticks. [a test proves it: RetakeFieldTests: armed backup]
  Notes:
- [x] **Allies on violent jobs (7 November, part 2):** take a violent job as Civil Protection, the Overwatch and the Resistance: two of your own side follow and fight with you. [a test proves it: QuestSquadTests: A squad of your own side on every violent job]
  Notes:
- [x] **Flashbangs (7 November, part 2):** flash rebels: each rubs their eyes and stumbles 4 to 9 seconds, no shooting. [replaced: The blinded pose was redone (line 1872)]
  Notes:
- [x] **Missing Unit part 2 (7 November, part 2):** after the zombies, a zombine appears with a notice and no choice window; kill him, or walk out of the infestation. [a test proves it: MissingZombineTests: a zombine, no choice window]
  Notes:
- [x] **My career (7 November, part 2):** C > My career as a Metrocop shows rank, XP to the next and the way to the Overwatch; a declined candidate can ask again after an hour. [a test proves it: CareerTests: My career, rank, XP and the way to the Overwatch]
  Notes:
- [x] **Contraband sweep (7 November, part 2):** after the stashes: a clue, a witness, then the suspect to find and arrest. [a test proves it: CareerTests: who hid the contraband]
  Notes:
- [x] **Lab damage (7 November, part 2):** shoot a Resistance lab bench: parts blow and smoke, then it's wrecked and the lab shop is shut; a rebel repairs it with the F3 job "Get the lab running". [a test proves it: LabDamageTests: A Resistance lab shot up, wrecked, and repaired]
  Notes:
- [ ] **What you can do here panel (7 November, part 2):** as a unit with the Arrest Baton out, the panel on the right says E on a citizen stops them, R searches, right click arrests. It never covers the quest tracker or a tip card, fades after a few seconds, and C > Settings turns it off. [needs a person: The panel's place on screen and its fade]
  Notes:
- [ ] **Quest trail (7 November, part 2):** take a quest with a far objective: chevrons on the ground flow toward it, points behind you vanish, walking off brings a new trail within a second or two, and it goes at the objective. C > Settings hides it. [needs a person: Chevrons flowing on the ground (rules in GuidanceTests)]
  Notes:
- [ ] **Panting, again (7 November, part 2):** run out of stamina several times: the panting stops each time, with no snd_restart. [needs a person: Ear: the panting stops each time]
  Notes:
- [ ] **Rain (7 November, part 2):** rain outdoors is about 30% quieter. [needs a person: Ear: rain loudness]
  Notes:
- [x] **Sleep warnings (7 November, part 2):** "Getting tired" about 6 minutes before and "Very tired" about 2 minutes before; a bed works from the first; the job box stays visible as your eyes close; your eyes don't close in the middle of a fight; as a citizen you're only tired in the evening and at night. [a test proves it: SleepWarnTests: two warnings, a bed from the first, never mid-fight]
  Notes: 
- [x] **Pacing (7 November, part 2):** an hour of play has far fewer announcements and events, and never two voices at once; stock HL2 Overwatch lines only where you have no recording. [replaced: Announcer pacing redone; listen for line 2054 instead]
  Notes:
- [x] **Combat music for units (7 November, part 2):** as Civil Protection in a sweep, a violent job or a firefight, action music plays. [replaced: Action music rule replaced (line 1940)]
  Notes:
- [x] **Administrator's voice (7 November, part 2):** with nobody as the Administrator, her recordings speak the announcements; become the Administrator and only the Overwatch voice is on the PA, and her recorded addresses stop. [a test proves it: AdminVoiceTests: The Administrator's voice and microphone]
  Notes:
- [x] **Administrator's microphone (7 November, part 2):** as the Administrator, left click with the microphone goes on air without waiting for the transmitter; hold push-to-talk or type in chat. [a test proves it: AdminVoiceTests: The Administrator's voice and microphone]
  Notes:
- [ ] **G-Man set aside (7 November, part 2):** no G-Man in your sleep, no sealed directives; the Administrator's chosen dream plays with no G-Man vote. [unsorted: The tests switch directives on; could not confirm the default (off) is checked]
  Notes:
- [ ] **Flood in a dream (7 November, part 2):** dream The Flood with a dream zone placed: the water fills only the dream zone. [needs a person: Water only inside the dream zone, by eye]
  Notes:
- [x] **Restrictions and the Resistance (7 November, part 2):** restrict 3 goods: 3 more fighters in rebel territory, a refused citizen leans to the Resistance, sociostability isn't moved; the Administrator's market page describes the mood in plain words. [a test proves it: MarketTests and RebelEventTests: restrictions make the parties bigger]
  Notes:
- [ ] **Zone stalkers (7 November, part 2):** place "Point: stalker terminal" in front of a terminal in a Combine zone, standing where the stalker should stand and facing the terminal; the stalker goes there and works it. The debug report's "terminal animation" line says which animation it chose: does it look right? [needs a person: Stalker at a terminal: does the animation look right (owner has not seen it yet)]
  Notes: have not seen a staker stand in front of a terminal, however they are dragging dead bodies in the combine HQ away. Can we have it so there is a rope effect tied between the stalker's hand and the dead body?
- [x] **Stalker repairs (7 November, part 2):** break a streetlight or loudspeaker inside a Combine zone; after about a minute the stalker leaves the terminal, repairs it and goes back. [a test proves it: ZoneStalkerTests: terminals, repairs]
  Notes: 
- [ ] **Stalker replaced (7 November, part 2):** kill a zone's stalker; another appears out of sight about two minutes later. [unsorted: ZoneStalkerTests exists; could not confirm the replacement after a kill]
  Notes:
- [x] **F1 (7 November, part 2):** the same general menu for a citizen, a unit and a rebel; 2 is Hands up; 5 opens pockets. [a test proves it: KeyLayoutTests: F1 quick menu]
  Notes:
- [x] **F2 as a unit (7 November, part 2):** 1 Voice lines, 2 Unit tools, 3 Kick, 4 Backup, 5 BOLO, 6 10-20; look at someone and 7-8 are Search and Cuff. [replaced: Backup, BOLO and 10-20 are only on the radio menu now (line 1860)]
  Notes:
- [x] **F2 for others (7 November, part 2):** as a rebel (clothes, market, squad orders with a squad), as the Administrator, and as a jobless citizen (it says there's nothing). [a test proves it: KeyLayoutTests (F2 your side's quick menu) and QuickMoreTests]
  Notes:
- [x] **F3 (7 November, part 2):** opens your pockets. [a test proves it: KeyLayoutTests: F3 pockets]
  Notes:
- [x] **F4 (7 November, part 2):** opens on Jobs; switch to Career and Factions, close it, and F4 reopens on the last tab; the reassessment button works; !jobs and !faction open their tabs. [a test proves it: KeyLayoutTests: F4 jobs, career and factions in one window]
  Notes:
- [ ] **Kick reminder (7 November, part 2):** at a locked door it reads "press G (or F2 > 3)". [unsorted: The reminder is tested (v2.7 pieces) but not its 'F2 > 3' wording]
  Notes:
- [x] **Commissary controls (7 November, part 2):** as Administrator, tablet > The Commissary and the market: restrict bread, set coffee to 3x, a medical kit to scarce, and check the Commissary window shows each. [a test proves it: MarketTests: the Administrator's Commissary controls]
  Notes:
- [x] **Black market follows (7 November, part 2):** restricted bread appears at the dealer and the quartermaster at a premium, and goes once it's unrestricted. [a test proves it: MarketTests: the black market following shortages]
  Notes:
- [x] **Demand (7 November, part 2):** buy several lockpicks: the price rises, and falls back over time. [a test proves it: MarketTests: demand]
  Notes:
- [ ] **Shortages and the mood (7 November, part 2):** restrict 4 goods: sociostability won't sit at green. [unsorted: MarketTests exists; could not confirm the link to sociostability]
  Notes:
- [x] **Raids are real (7 November, part 2):** on the usual NPC budget, start a raid (C > Help, or lc_skirmish raid). As Resistance, follow the "Our fighters" marker: the fighters reach the target and 2 or 3 units come to fight them. The NPC count doesn't go up. [replaced: Owner tried it; the two faults are relisted at line 194]
  Notes:Raid on the combine HQ was great, 2 issues: 1. metrocops were walking around inside the combine zone holding arrest batons and doing nothing while soldiers and rebels were shooting. and 2: some rebel fighters spawned inside jail/prison cells/zones and were stuck and therefore had no weapons and I had to go in and put them out of their misery. They need to not spawn inside the prison cells when raiding.
- [ ] **Raid timing (7 November, part 2):** as Civil Protection, the "10-20: ANTICITIZEN ATTACK" marker appears when the fight starts; rations are docked only then. [unsorted: RebelEventTests exists; could not confirm when the marker and docking come]
  Notes:
- [x] **Raids and restrictions (7 November, part 2):** restrict 3, then 5 goods: raid parties grow (5, then 6 or more). [a test proves it: RebelEventTests: the Commissary's restrictions make the parties bigger]
  Notes:
- [x] **Territory along path nodes (7 November, part 2):** C > Help > Admin testing tools > The city > Grow rebel ground now, several times: it follows your path nodes out of the zone, 8 feet tall, never onto the floor above (the editor view shows the rectangles). [a test proves it: TerritoryPathTests: grows along the path nodes, eight feet tall]
  Notes:
- [x] **Territory in open areas (7 November, part 2):** grow a territory beside a plaza with linked nodes: it spreads wide and fills in the middle. [a test proves it: TerritoryPathTests: in the open it spreads wide, and fills the gaps]
  Notes:
- [x] **Territory after a restart (7 November, part 2):** grown ground comes back after a map restart. [a test proves it: TerritoryPathTests: grown ground comes back after a restart]
  Notes:
- [x] **Territory push-back (7 November, part 2):** kill 3 rebels in it: the ground furthest out goes first. [a test proves it: TerritoryPathTests: taken back the way it came, the furthest out first]
  Notes:
- [x] **Territory on its own (7 November, part 2):** with rebels in the zone, it grows within about 40 minutes; lc_territory says why if not. [a test proves it: TerritoryTests: Territory spreads when left alone]
  Notes:
- [x] **Manpower (7 November, part 2):** kill a raid party: F2 > Resistance shows them lost, the radio says "We lost N fighters", and they aren't back for minutes. [a test proves it: ManpowerTests: a death draws the reserve down; what each side sees]
  Notes:
- [x] **Manpower, empty (7 November, part 2):** set lc_manpower_cp_max 2 and kill the units: no new patrols until "Next unit" comes; sweeps postponed with a line saying why. [a test proves it: ManpowerTests: an empty reserve stops the top-ups; sweeps wait]
  Notes:
- [x] **Manpower and restrictions (7 November, part 2):** restrict goods at the Commissary: F2 > Resistance says "Recruiting faster (Commissary restrictions)". [a test proves it: ManpowerTests: the Commissary's restrictions speed the Resistance's recruiting]
  Notes:
- [x] **Manpower after a restart (7 November, part 2):** note the reserves, restart the map: they're the same. [a test proves it: ManpowerTests: kept per map across restarts]
  Notes:

## Nightmare dreams you play (7 November)
- [ ] **The Patrol Maze:** as Administrator pick it on the tablet (Nightmare), or C > Help > Dreams: dream it now (with me). Does the maze fit at the dream point, are the walls solid, do the tokens glow and get picked up, do the giant officers run (not slide) and chase you round corners, does a golden token turn them blue and let you send one back to the middle? [needs a person: Maze fit at your dream point, officers running not sliding]
  Notes:
- [ ] **The Barrel Tower:** can you walk up every ramp, do barrels roll down the middle and lanes (not float), does touching one explode it and send you back, can you jump over one, does reaching the red top win? [needs a person: Ramps and rolling barrels: real physics and feel]
  Notes:
- [ ] **The Crumbling Floor (try with two players):** do tiles crack yellow then red then vanish, does the scanner fly over marking tiles, does falling wake you, does the last one standing win? [needs a person: Needs two players; tiles and scanner by eye]
  Notes:
- [ ] **Freeze, Citizen:** does the giant officer turn round and shout, does the screen say FREEZE in red, does moving then send you back, does standing still keep you safe, does the red line win? [needs a person: The giant officer and the red FREEZE by eye (see also line 118)]
  Notes:
- [x] **All four:** after each one, are you back in your bed with everything you had, and is the arena gone from the dream point? [a test proves it: DreamGameTests and DreamTests: back in bed with everything]
  Notes:

## Nightmares, wake or watch, cigarettes, alcohol and stimulants (7 November, part 3)
- [ ] **Out of lives in a dream you play:** does the window ask "Wake up now" or "Watch until it's over"? Watching, can you fly about inside the arena but not leave it? Waking, are you back in bed with everything? [unsorted: DreamGameTests exists; could not confirm the wake or watch window]
  Notes:
- [x] **Bonus and penalty:** win one: 25 credits, a little XP, full health on waking? Lose every life: hurt, thirsty and a shaky grey view for 3 minutes? [replaced: Rewards and penalty changed on 8 November (lines 1073 and 1075)]
  Notes:
- [x] **No opting out of a nightmare:** opted out, asleep, with a nightmare chosen: does it still take you? Does "Wake up" refuse while you're still in it? A happy or neutral dream still skips you? [replaced: Sitting dreams out is earned now (line 1460)]
  Notes:
- [x] **Stimulant:** buy one from the black market, take it (F3): can you not sleep in a bed for 15 minutes, then crash (no running)? A second one hurts? [replaced: A second stimulant is refused now, one a night (line 1220)]
  Notes:
- [ ] **Cigarettes:** Union cigarettes at the Commissary (standing 150), hand-rolled at the black market. Do you and others see smoke? Three quickly: coughing fit? [needs a person: Smoke seen by you and others; the standing is 75 now (line 1079)]
  Notes:
- [ ] **Alcohol:** beer, vodka, moonshine: does the screen sway more as you drink, no running when drunk, throwing up past 7, the empty beer bottle left over? [needs a person: Screen sway and being drunk, by eye (rules in ViceTests)]
  Notes:

## Nightmare rewards and penalty (8 November)
- [x] **Win a dream you play:** no credits or XP? Breen's water does nothing for a day? You run longer before tiring? As a citizen, is a dealer or cache marked on screen for 10 minutes? As Resistance, did something appear in your pockets? [a test proves it: DreamGameTests: a winner wakes Unbroken with a second wind, no credits or XP]
  Notes:
- [x] **Lose every life:** health limit 70 after waking, still 70 after you finish that same night's sleep, back to 100 after the next full night's sleep? [a test proves it: ViceTests: lost, 30 off the health limit until a later night's sleep]
  Notes:
- [x] **Combine-only zone:** asleep inside one when a nightmare starts, are you left alone? [replaced: A unit asleep in the Combine zone does dream the nightmare now (line 104)]
  Notes:
- [ ] **Commissary:** Union cigarettes from standing 75, vodka from 150? [unsorted: ViceTests has the items; could not confirm the standing needed]
## 7 November, part 3
- [x] **Combine manpower on the tablet:** as the Administrator, right click the tablet; "Combine manpower" lists Civil Protection and Overwatch (in reserve, lost today, next unit or soldier), matching F2 > Combine manpower. With `lc_manpower 0` it is gone. [a test proves it: ManpowerTests: the Administrator's tablet shows the Combine's reserves]
- [x] **Manpower on the records terminal:** as a unit, open the records terminal (`!records`); the Manpower tab shows the same lines as F2 > Unit tools. [a test proves it: ManpowerTests: the records terminal shows the Combine's reserves]
- [x] **Headcrab hunt:** as a rebel, empty your camp's supply crate (or wait for it to run out): a notice says a Headcrab hunt is on the Operations board (F4). Take it, kill four headcrabs in the infested ground, pick up the raw meat with E, stand by the crate: one meal each, the job completes, extra pay if the crate was empty. Zombies and city headcrabs don't count. [a test proves it: CrabHuntTests: kill headcrabs, bring the meat to the crate]
- [x] **Evidence burn:** confiscate a few things (search, arrest, raid), check F2 > Unit tools > Evidence lists them; as an admin press "Burn it now": metrocops carry boxes to the loudspeaker or square, the pile forms, the PA calls it, citizens gather, fire and smoke burn out and clean up. None during a curfew, lockdown, ending or dream. [a test proves it: EvidenceTests: carried to the square, the PA calls, it burns, it's gone]
- [x] **Snatching evidence:** as a citizen or rebel, press E on something in the pile before it catches: you get it back, and are wanted if a unit is watching. Once burning: "Too late". [a test proves it: EvidenceTests: before it catches, anyone but a unit can snatch something back]
- [x] **Food scarcity:** the dispenser's next ration is about 25 minutes away (a unit's still 10); a Commissary ration is 15 credits; the second tin from the Resistance crate says come back in 15 minutes; fishing casts take 25 to 45 seconds and mostly come up empty; a killed bird is replaced only after about 90 seconds. [a test proves it: ScarcityTests: slower rations, dearer food, emptier stores]
- [ ] **Network safety:** with about 100 NPCs and territory fights going, reconnect as superadmin with the editor overlay on: no "reliable data too big" kick, and the overlay and territory map fill in once loaded (big panels may take a few seconds). [needs the real server: A real reconnect with 100 NPCs (send sizes are in NetSafetyTests)]
- [ ] **Long laws:** as Administrator, add two long laws (C > The city > The city's laws): every law board shows all of them, and a long broadcast shows whole on the city screens. [needs a person: Long laws shown whole on boards and screens, by eye]
- [ ] **Bug fixes to check:** pickpocketing works right after a map start; prisoners have fists and hands in a cell; dreamers hold their hands; the master interface can be hacked again; the quest trail goes away while your memory is clouded. [needs a person: Five small fixes with no single test; a quick try each]
- [x] **Arrest struggle, officer gone:** have the officer walk 220+ units away (or die) mid-struggle: "The officer is gone: the struggle is over.", not wanted, no "You broke free". [a test proves it: ArrestOverhaulTests: 'The officer is gone: the struggle is over.']
- [ ] **Lab wrecking pay:** as a citizen, wrecking a lab pays nothing; as a unit, 15 XP, 20 credits and the [Civil Protection] line. [unsorted: LabDamageTests exists; could not confirm the pay for wrecking]
- [ ] **AR2 rebel kill:** as a unit holding the AR2, kill a rebel: "30 AR2 rounds", no SMG box. [unsorted: Could not confirm a test for AR2 rounds on a rebel kill]
- [ ] **NPC cap:** a fresh server shows `lc_npc_budget` 100. [needs the real server: Check lc_npc_budget on your own server]
  Notes:

## Propaganda dreams (8 November)

- [ ] **Her music:** put a song or two in `garrysmod/sound/livingcity/dreams/administrator/`, upload, FastDL sync, change map. During one of her dreams it should play, looping, and stop when you wake. [needs the real server: Song files in the dreams sound folder, FastDL sync]
  Notes:
- [ ] **Kneel Before Her:** as the Administrator, Tablet > Tonight's dream > Happy > Kneel Before Her (or C > Help > Dreams to dream it now). Check: the pink hall, her giant figure on the gold pedestal (your own model if you are on), kneeling admirers, hearts. Standing when she looks at you costs a life; crouching and looking at her fills Devotion. [needs a person: The pink hall, her figure, the hearts by eye]
  Notes:
- [x] **Roses for Her:** walk over a glowing rose, cross the gold line crouching, reach her feet. Standing past the line sends you back. Three roses wins. [replaced: Roses for Her was fixed and relisted on 14 November (line 37)]
  Notes:
- [x] **Mirror, Mirror:** crouch and type "you are radiant" in chat: it scores, only dreamers see it, the city does not. Try standing (no score), repeating a word (no score), "old" (a life gone). Check /commands still work in the dream. [a test proves it: PropagandaDreamTests: mirror]
  Notes:
- [ ] **Sizes:** her height, the pedestal, the mirrors (they are guesses at angles) and the admirers' kneeling pose look right; tell me what looks off. [needs a person: Sizes and poses: what looks off]
  Notes:
- [x] **Let them slip, on F2:** as the Insider beside a prisoner being marched: the right-hand panel shows "Let <name> slip away: F2 > 7" (bright); F2 > 7 lets them go (20 s head start, wanted if a unit still sees them, -20 standing, once per 20 min); watched: the line goes faint and the entry is greyed. [a test proves it: InsiderSlipTests: lets a prisoner slip (it says F2 > 7; line 1864 says 5)]
- [x] **Pat-down search:** as a unit, search a citizen (baton R or F2): click Jacket, Waist, Legs, Boots one at a time; only checked spots give things up. As the searched player, press R once to slip something into a checked spot (about 6 in 10); walk off and you are wanted for evading. [a test proves it: PatSearchTests: A unit's search, the pat-down game]
- [x] **F2 for everyone:** Insider (F2 > Inside), Resistance (F2 > Freq 7: message, backup, my position, guide to rebel ground or a lab), plain citizen (F2 > Me: work, rations, home, standing), prisoner (My sentence), Administrator (tablet, laws, tonight's dream, guards, order an arrest), Division Leader and up (Call a sweep). [replaced: Freq 7 page is only Find the way now (line 1878); rest in QuickMoreTests]
- [x] **Administrator's guards:** F2 > Command the guards > Follow distance (Close, Medium, Far) and When there's trouble (As always, Stay with me, Stand between us, Hold fire unless fired on); the menu marks the one in force. [a test proves it: GuardOrdersTests: how close they follow, what they do when there's trouble]
- [x] **Stepping aside, own side only:** walk into a Metrocop or an Overwatch soldier as a unit or as the Administrator (it moves) and as a citizen or rebel (it doesn't); your Elites sidestep and return to their place; never mid-fight. [a test proves it: GuardOrdersTests: stepping aside for their own side]
- [ ] **Raids and sweeps keep coming:** after a Resistance operation succeeds (heist, breakout, screen, ambush, supply), raids and sweeps start again on their usual timers (they used to stop until a restart). [unsorted: Could not confirm a test for raids and sweeps resuming after an operation]
- [x] **Grown territory:** grow rebel ground down a corridor (admin tools > The city > Grow rebel ground now, a few times): barrels and crates along the whole corridor, fighters patrolling and appearing all along it, lower stretches too. [a test proves it: GrownGroundTests: Grown ground is dressed, lived in and cleared by its cells]
- [x] **Save files:** with the server stopped, cut data/livingcity/mail.json short and start it: the mail is all there (from mail.json.bak.txt, a warning in lc_debugreport). Blank the .bak.txt too and restart: a superadmin is told, the file isn't overwritten, and admin tools > The city > "Let the city save over them" allows it. [a test proves it: SafeFileTests: read from its backup, never saved over]
- [x] **NPC name tags on demand:** join with many NPCs: nearby names, jobs and what they're doing show as before; someone far across the square shows within about a second. [a test proves it: NPCStrTests: NPC name tags, sent only near the player]
- [ ] **Frame rate:** with job games on (sweeping, carts, triage), the frame rate should be steadier than before; nothing should look different. [needs a person: Feel: is the frame rate steadier on your machine]
- [x] **Daytime curfew announcement:** it now says a unit warns you three times, then you're wanted. [a test proves it: AnnouncementTests: a curfew says a unit warns you three times]
- [ ] **Pose Recorder 2:** make a 3-keyframe wave, "Play what I'm making on me" (loop, once, hold, speed 2): another player sees it, a late joiner too; C > right click an NPC > Play animation; Mirror them on a right-arm pose: the left arm does the same on its own side. [needs a person: The Pose Recorder addon, with another player watching]
- [ ] **Song names (changed):** songs now go flat in `garrysmod/sound/livingcity/dreams/`, named for their codeword: `admire1.mp3` (the three admiring dreams), `saviour_horde1.mp3` (The Saviour before she comes), `saviour1.mp3` (after her soldiers arrive), `quiz1.mp3`. Anything in `dreams/administrator/` still plays as admire. [needs the real server: Song file names in the dreams sound folder]
  Notes:
- [ ] **Her voice lines:** record `saviour_stop1.wav` ("Stop!"), `saviour_soldiers1.wav` ("Come, my soldiers. Protect them."), `saviour_safe1.wav`, and optionally `adore_hello`, `roses_hello`, `mirror_hello`, `quiz_hello`, `quiz_q1` to `quiz_q10`, `quiz_end`, into `garrysmod/sound/livingcity/dreams/voice/`. A `.txt` with the same name sets the subtitle. Check each plays with its words on screen. [needs the real server: Her lines to record and upload]
  Notes:
- [x] **The Saviour:** the dead come in from the edges about 4 seconds in; you have only your hands. About 30 seconds in, a light, and she comes down glowing; "Stop!" freezes them; "Come, my soldiers" brings 8 Combine soldiers who shoot every one; then everyone still standing is saved. Check the glow, the column of light and the music switch. [replaced: The Saviour was reworked (line 1134)]
  Notes:
- [x] **The Loyalty Quiz:** ten questions on screen (and in her voice, if recorded). Type answers in chat: "the Combine", "obey", "the Union". First right answer counts double; "Freeman" costs a life. Six Loyalty wins. [a test proves it: PropagandaDreamTests: the quiz]
  Notes:
- [ ] **Starring:** as the Administrator, go to bed with at least one other player asleep, then pick a propaganda dream. You should be the giant on the pedestal (your look is your gaze in Kneel Before Her), or wait unseen in the sky and come down yourself in The Saviour. Type in chat: the dreamers see it on screen; the city does not. Wake up: a giant figure of you takes over. Check the tablet switch (Tonight's dream > Star in propaganda dreams yourself) turns it off and on. [needs a person: Needs a second sleeper; you as the giant, by eye]
  Notes:
- [x] **Not skippable:** opt out (C > Settings > Shared dreams), go to bed, and have a propaganda dream chosen: you still dream it, the warning says there is no opting out, and "wake up" is refused until you win or lose every life. A player Unbroken (from beating a nightmare) is left out. [replaced: Sitting dreams out is earned now (line 1460)]
  Notes:
- [x] **Loyalty:** lose a life in one (stand in her gaze, insult her, type "pigs" or "Freeman" in the quiz). On waking you lose 3 loyalty points (Civil Standing) per offence, 5 more if you were thrown out, at most 20, with a notice. No health lost. [a test proves it: PropagandaDreamTests: propaganda dreams you play (lives and loyalty)]
  Notes:
- [ ] **The Saviour (reworked):** the monsters hurt you (watch your health). When anyone is at 25 or less, they all freeze, she comes down from high in the zone and lands between them and you, "Stop!", then the soldiers. A Resistance player in the dream is never shot. If nobody gets that low, she comes at 80 seconds. [needs a person: Her descent, the freeze and the soldiers by eye (rules in PropagandaDreamTests)]
  Notes:

## Ten more propaganda dreams (8 November)

- [x] **On the tablet:** Tablet > Tonight's dream > Happy: all ten listed as "Propaganda: ..." after the first five. Try each with two players asleep. [replaced: The tablet only offers a kind of dream now, no list (line 1298)]
  Notes:
- [x] **Record Harvest:** walk over a gold crate, carry it past the gold line: the quota board (floating by her) climbs. Pick up a green one: crouch throws it away; delivering it costs a life. Five crates: medal line. [a test proves it: PropagandaMoreTests: harvest]
  Notes:
- [x] **The Union Shift:** stand on a green glow, crouch repeatedly: your norm goes up 20% a blow (40% on "Double norm!"). Stand idle 12 s: a life. 1400%: a giant figure of you appears and your name tops the board. [a test proves it: PropagandaMoreTests: shift]
  Notes:
- [x] **Careless Talk:** the tinted citizens look clearly red, green, blue or yellow; clues appear on screen every 14 s; crouch beside one to report. Wrong: a life and they glow green. Right: they vanish, you win. [replaced: Careless Talk is three rounds with E now (line 112)]
  Notes:
- [x] **The Newsreel:** the screen is black and white with flicker lines; the camera prop turns to you; type the word it asks within 5 s. [replaced: The Newsreel changed to a party game (line 1167)]
  Notes:
- [ ] **Two Minutes of Hate:** the "ENEMY OF THE PEOPLE" board is readable (FREEMAN and a crossed-out lambda); type "traitor! scum!"; stay quiet 15 s (a life); type "hero" (a life). [needs a person: Is the board readable]
  Notes:
- [ ] **The Mass Games:** you start on a seat; "Picture 1: your card is GOLD (crouch)"; at FLIP! the right pose scores; the card portrait above the stands fills in row by row. Tell me if the portrait sits too high or faces the wrong way. [needs a person: The card portrait: too high, wrong way round]
  Notes:
- [x] **On-the-Spot Guidance:** she walks between four machines and says a line at each; then "APPLAUD!": jump or type clap. Last to applaud loses a life. As the Administrator asleep with someone: you walk the tour yourself. [a test proves it: PropagandaMoreTests: guidance]
  Notes:
- [x] **The Scrap Drive:** pots and buckets glow blue; walk over them (three at most), into the bins (gold glow); go near the shady man at the side while carrying: a life, scrap gone. [a test proves it: PropagandaMoreTests: scrap]
  Notes:
- [x] **Flowers for the Liberators:** soldiers march down the grey road; "NOW!" shows as one passes you; jump to throw. Step into the road: a life. Let a squad pass without throwing: a life. [a test proves it: PropagandaMoreTests: flowers]
  Notes:
- [x] **Duck and Cover:** a big scanner (Sunny) bobs and gives tips; on the siren the tables glow; crouch beside one before the white flash. Three at one table: the farthest is caught. [replaced: Duck and Cover was slowed and its alarm changed (line 116)]
  Notes:
- [ ] **Sizes and models:** the floating boards (quota, norm, scrap, enemy), the camera, the tables, the factory machines and the trash bins are guesses at sizes and angles: tell me what looks off or missing (an error model means a model your server lacks). [needs a person: Sizes, angles and missing models]
  Notes:
- [ ] **Music and voices:** optional: `harvest1.mp3` (or `propaganda1.mp3` for all ten) in `garrysmod/sound/livingcity/dreams/`; lines like `duck_siren1.wav` in `dreams/voice/`. Upload, FastDL sync, map change. [needs the real server: Optional song and voice files to upload]
  Notes:
- [x] **Careless Talk, as a party game (changed):** with two or three players: four rounds of 30 seconds; crouch beside your suspect (a white glow over them, only for you); change your mind; at 30 s the spy glows red and the notice lists everyone's pick. Reporting nobody costs a life. [replaced: Careless Talk is three rounds with E now (line 112)]
  Notes:
- [x] **The Newsreel, as a party game (changed):** each player gets their own cue at once ("Rolling! Take 1"); type it; at the cut everyone's take is listed on screen. [a test proves it: PropagandaMoreTests: newsreel]
  Notes:
- [x] **Duck and Cover, the rebels' rocket (changed):** a rocket stands in the far corner and climbs on a flame during the siren. If it is a small grey PHX rocket or an RPG missile instead of Magnusson's, your server lacks Episode Two or my guess at its path is wrong: in game, Q menu > Browse > Games > Half-Life 2: Episode Two > models, find the rocket and tell me its path. Tell me if it is too big or small. [replaced: The rocket model was changed (line 1308)]
  Notes:
- [ ] **The Resistance, goofy:** Duck and Cover: a giant red Magnusson (or Kleiner, or a rebel, if your server lacks Episode Two) cackles by the rocket and rides it up. Careless Talk: at the reveal the spy turns red, grows huge and floats up spinning. Two Minutes of Hate: a giant red rebel bobs over the screen. Say if any are too big for your dream zone. [needs a person: The giant figures: too big for your dream zone]
  Notes:
- [ ] **Ravenholm, her version:** with no Free Vortigaunt online: graves, a dark church front and giant cross, a giant red Grigori ranting in a deep, slowed voice; zombies climb out of the graves and hurt you. At 25 health she comes down, her soldiers shoot them, Grigori spins away into the sky. [needs a person: The graves, church front and giant Grigori by eye]
  Notes:
- [ ] **Ravenholm, the truth:** with a Free Vortigaunt player online (asleep in it or not): at the turn a vortigaunt appears, a green ring of light rolls out and the screen flashes green; Grigori loses his red, speaks normally and blasts the zombies with his shotgun; a giant red Administrator hovers, then shrieks and spins away. Check the church front and cross look right, and that Grigori's voice lines play (if not, they have other names on your server: tell me). [needs a person: The green ring, Grigori's lines, the church front by eye]
  Notes:
- [ ] **Ravenholm, freed NPC vortigaunt (changed):** with no Free Vortigaunt player online, cut a street-crew vortigaunt loose (or finish a work-site rescue), then play Ravenholm: the truth version should happen. Kill that vortigaunt and play again: her version. [needs a person: No test found by name for the freed NPC vortigaunt version; try it]
  Notes:
- [ ] **lc_voice_missing (8 November, part 7):** type `lc_voice_missing` in the server's web console: one line per folder (Dream lines, overwatch, administrator, radio, G-Man) naming what has no recording yet. Add a file, change the map, run it again: that line should be gone. [needs the real server: Run lc_voice_missing in the server console]

## 8 November, part 8: the performance debugger (staff)
- [ ] **Opening it:** C > Help > Performance debugger opens a window with tabs (Summary, Hitches, Hooks, Timers, Net in, Net out, Networked values, Entities, Players, Who sends). [needs a person: The window and its tabs by eye]
  Notes:
- [x] **Start and Stop:** Start: every staff member online is told on screen; the figures refresh every two seconds. Stop: told again, with where the report was saved (`garrysmod/data/livingcity/perf/`). [a test proves it: PerfDebugTests: The performance debugger, put back when off]
  Notes:
- [ ] **No harm while on:** with it on for a few minutes on a busy server, nothing breaks (doors, menus, chat, NPCs, ULX or other admin mods still work), and after Stop everything behaves as before. [needs the real server: A busy real server with other admin mods]
  Notes:
- [ ] **What it finds:** the Summary's "What stands out" lines make sense; Hooks lists the gamemode's and other addons' hooks; Net in and Net out list messages; Players shows ping and loss. [needs the real server: Real figures from your server: do they make sense]
  Notes:
- [ ] **Your game:** the "Server / Your game" button shows your own game's figures (your hooks, your frames). [needs a person: Your own game's figures on screen]
  Notes:
- [ ] **Settings:** the two drop-downs set the hitch threshold (30, 60, 100, 250 ms) and when it turns itself off (15 to 120 minutes, or never). [needs a person: The two drop-downs by eye]
  Notes:
- [ ] **Copy report:** pastes both reports (server and your game) as text; `lc_perfdebug report` in the server console prints the server's. [needs the real server: Paste the report; the command in the server console]
  Notes:
- [ ] **From the editor tool:** the last button in the Living City editor tool's panel (under Debugging), "Performance debugger", opens the same window. [needs a person: The button in the editor tool's panel]
  Notes:
- [x] **The Loyalty Quiz forgives (8 November, part 7):** in the quiz, answer with a typo ("adminstrator"), another ending ("I reported him", "terrorist") and a new synonym ("Breen", "surrender", "rat"): each should count. "Freemann" should still be thoughtcrime; "let's dance" should not. [a test proves it: PropagandaDreamTests: the quiz (typos and other endings)]
  Notes:
- [x] **Swears are thoughtcrime in the quiz:** swear in the Loyalty Quiz ("oh shit"): a life gone, like "Freeman". "They are scum" on the Resistance question should still be a right answer. [a test proves it: PropagandaDreamTests: swears, curses and insults are thoughtcrime too]
  Notes:
- [x] **Swearing at the Resistance is fine in the quiz:** "FUCKING TRAITORS!" and "FUCK FREEMAN!" are allowed (the first is also a right answer to #4); "fuck the Combine" and "Freeman is a fucking hero" are thoughtcrime; leet and misspellings (sh1t, fuuuck, shiet, fukc) are caught. [a test proves it: PropagandaDreamTests: the quiz (swears, curses and insults)]
  Notes:
- [ ] **The dreams speak with her voice:** in The Union Shift, Careless Talk, The Newsreel, Two Minutes of Hate and The Mass Games, the lines on screen are labelled "The Administrator" (Duck and Cover keeps Sunny the Scanner). [unsorted: Could not confirm a test for the label on those lines]
  Notes:
- [ ] **No foreman in The Union Shift:** she stands on a gold pedestal at the far end of the factory (check she fits beside the board and the portrait); stand idle 12 seconds: "I see you standing there. Back to work, citizen!" [needs a person: Does she fit beside the board and the portrait]
  Notes:
- [ ] **Quiz stand-ins:** dream the Loyalty Quiz with fewer than four players: a row of the city's people stands before her and answers each question in chat (5 to 12 seconds in). One question between the 3rd and 8th, the rebel (in rebel clothes) shouts thoughtcrime; she orders him removed; two officers with stun batons beat him (check the batons sit in their hands, the swing and cower poses) and drag him to the back; she says "Where were we? Ah, yes." With four players: no stand-ins. [needs a person: Batons in hands, swing and cower poses]
  Notes:

## 8 November, part 11: dream safeguards
- [x] **Stand-ins:** pick a dream you play with one or two asleep: "Also dreaming: ..." in chat, figures running near the start, some flash red and drop out with a puff; the quiz seats up to six. [a test proves it: DreamCrowdTests: stand-ins]
  Notes:
- [x] **Enforcers:** a unit asleep for a nightmare (try the maze): told "You will be in it as an Enforcer", a baton, the blue line on screen, can wake from C > Settings. A dreamer standing still 20 s glows red; hit them: a life gone, +1 XP on waking. A Happy dream: the unit dreams it normally. [a test proves it: DreamCrowdTests: Enforcers]
  Notes:
- [x] **Lights out:** as a rebel and as the Administrator (each), sleep at midday, then watch for "Lights out soon" before 21:00 and the eyes closing after it until you sleep. Get up again before the dream comes: tired again. [a test proves it: DreamCrowdTests: bedtime (the warning words changed, ticked at line 68)]
  Notes:
- [x] **Night shift:** as a unit at dusk, the Night shift is first on F4; take it: no lights out; use a CP Commissary: one stimulant shot, only once that night. [a test proves it: DreamCrowdTests: the night shift]
  Notes:
- [x] **One stimulant:** take a shot before 21:00: no lights out until it wears off, and the dream goes by without you. Try a second: refused. Sleep (and dream) the next night: a shot works again. [a test proves it: DreamCrowdTests: a second stimulant is refused]
  Notes:
- [ ] **Five-minute safeguard:** an ending with a long song as a dream: everyone wakes at five minutes, with everything back. [unsorted: Could not confirm a test for the five minute wake]
  Notes:
- [x] **Foil hat and the chip:** a rebel with fewer than 3 dreams lived through: the lab says not yet. With 3: make a foil hat, put it on (F3), sleep through a nightmare untouched (hat spent). Pull the chip (500): no dreams, sleep ends by itself after 90 s; get searched a few times: now and then "no implant signal". [replaced: The hat only works one night in three now (line 1238); the chip is in DreamCrowdTests]
  Notes:
- [x] **Rebel kill XP:** as a unit, kill a wanted rebel player: +5 XP (as for an NPC rebel). [a test proves it: DreamCrowdTests: a rebel player killed by a unit, 5 XP]
  Notes:
- [x] **Dream rules:** as the Administrator on a clean day, Happy dreams open and Nightmares greyed ("not tonight", and why); after a curfew, Happy greyed; after sociostability red, Nightmares open; after a propaganda night, propaganda greyed. With no Administrator online, a dream comes every night anyway. [replaced: She only picks a kind every few nights now (lines 1298 and 1302)]
  Notes:
- [x] **Woken in your sleep:** while someone dreams, their body lies in their bed; hit it: they wake in bed, hurt. Shoot as a unit near a rebel camp at night: rebels asleep there (players and NPCs) wake. Sleep hungry: no starving damage while asleep. [a test proves it: DreamCrowdTests: woken by violence]
  Notes:
- [x] **No opting out:** C > Settings shows no opt-out; in a Happy dream, "Wake up" says you can't until you're out of it; `/dream off` says there's no opting out. [replaced: Sitting dreams out can be earned now (line 1460)]
  Notes:
- [x] **Stimulant supply:** the dealer sells them at 40, shows how many are left, and after 5 are bought says sold out until one more comes in (20 minutes). [a test proves it: DreamCrowdTests: sold out, more on the way]
  Notes:
- [x] **What wakes a camp:** someone in a rebel camp shot or batoned by a unit (or a zombie), or arrested: the sleepers there wake, groggy (drooping eyelids, blur, no stamina for a bit). A rebel shooting a friend or an NPC there, a burn barrel or a thrown prop: nobody wakes. Hit a dreamer's sleeping body as a rebel: nothing; as a unit: they wake. [a test proves it: DreamCrowdTests: woken by violence, groggy]
  Notes:
- [x] **Foil hat odds:** wear one to bed a few nights: roughly one night in three the dream passes you by ("a static, a distant power... can't quite break in"), the rest "Despite your tin foil hat, you feel a distant power..." and you dream; spent either way. Its description says it only works sometimes. [a test proves it: DreamCrowdTests: the foil hat works a third of the time]
  Notes:
- [x] **Friends can't wake you:** punch a sleeping fellow rebel (or a sleeping citizen as a citizen): nothing, no damage. A unit punching them: they wake, groggy. Same for a sleeping NPC: a rebel shooting a rebel asleep in camp does nothing. [a test proves it: DreamCrowdTests: who can wake a sleeper]
  Notes:
- [x] **Adrenaline:** woken by a unit's hit or a raid: "Adrenaline has you wide awake", full stamina, no tiredness; ten minutes later "The adrenaline has worn off. You need rest." and the groggy minute. Back in bed before that: no crash. [a test proves it: DreamCrowdTests: woken by violence, adrenaline first]
  Notes:

## 8 November, part 12: strange dreams and testing a dream from the editor
- [x] **Testing a dream:** with a Point: dream placed, open the Miscount Editor panel, Dreams: test one. The list fills with every dream (Happy, Neutral, Nightmare). Pick one, Test it now (just me): you go straight in, awake, with stand-ins. Stop the test (wake up) puts you back where you were with everything you had. [a test proves it: StrangeDreamTests: testing a dream from the editor]
  Notes:
- [x] **A test counts for nothing:** win a test dream, stop it: no Unbroken notice, no loyalty lost after a propaganda test, no health lost. Nobody asleep was pulled in. As a Civil Protection unit, a nightmare test lets you play it (not an Enforcer). [a test proves it: StrangeDreamTests and DreamSkipTests: a test doesn't count]
  Notes:
- [ ] **The Cheese Dream:** the screen is black and you are held still; the man's then the woman's "Sometimes I dream about cheese" echo, then both at once, with the words on screen. Then the dream swims up: cheese floor, rainbow colours, rippling picture, giant colourful heads humming the line, wobbly music. Low gravity: can you reach the floating slabs? Gather 10 (golden counts 3 and inverts the colours). Do the wheels roll across and cost a life? Too trippy, or not trippy enough? [needs a person: Too trippy or not enough; can you reach the slabs]
  Notes:
- [x] **Musical Chairs:** chairs drift round while the music plays; it stops, a free chair glows: crouch beside it. No chair, out. One chair fewer each round; the last one sitting wins (alone: three rounds). Do the chairs show (HL2 chair model)? Is 4 seconds to sit fair? [replaced: Only Use sits you down now, in a real seat (lines 1745 and 1750)]
  Notes:
- [ ] **Wings:** jump, then jump in the air to flap. Can you get up to the golden rings comfortably? Do the rings show as gold circles facing you, with clouds and pigeons? 8 rings wins. [needs a person: Feel: flapping up to the rings; how the rings look]
  Notes:
- [ ] **It's Raining Melons:** melons fall with a glow where they land: green catches, red (grey lead melon) costs a life. 12 wins. Too easy or too hard? [needs a person: Too easy or too hard]
  Notes:
- [ ] **Music:** without songs, Half-Life 2's own music plays (the cheese dream's only after the voices). Your own: put cheese1.mp3, chairs1.mp3, flying1.mp3 or melons1.mp3 in garrysmod/sound/livingcity/dreams/ (then FastDL sync and a map change). [needs the real server: Optional song files to upload]
  Notes:

## 9 November: ten more strange dreams, music for every dream
- [ ] **The echo:** in The Cheese Dream and Hooves and All, do the voices in the dark sound far away and dreamy (each echo further off, quieter, lower, from the other side, in a big cavern reverb)? Too quiet, too long? [needs a person: Ear: the echo, far away and dreamy]
  Notes:
- [ ] **The horse line:** is the hungry line (Half-Life 2's vo/npc/male01/question09.wav and the female one) really "I'm so hungry I could eat a horse"? If not, tell Claude the right file, or record horse_intro_male1.mp3 and horse_intro_female1.mp3. [needs a person: Ear: is it the right Half-Life 2 line]
  Notes:
- [ ] **Hooves and All:** black horse statue (red eyes) charges the nearest dreamer; Father Grigori shoots it again and again; each shot stops it: run in and bite (E). Eight bites wins. Does the horse model show, the right size? [needs a person: Does the horse model show, the right size]
  Notes:
- [ ] **The Main Event:** ring, ropes, crowd; Lamarr (giant), the Soda Machine, the Baby. Punch with attack next to it; crouch when it winds up. Do the models show and are three rounds too long? [needs a person: Do the models show; are three rounds too long]
  Notes:
- [x] **The Exam / The Last Train / Where's Lamarr?:** stand on an answer tile (the class majority is right); walk backwards to the train door; catch the hopping headcrabs (Lamarr golden). [replaced: The Exam was reworked (line 1280); the other two are in MoreStrangeDreamTests]
  Notes:
- [x] **Running in Molasses / Hot Potato / Overwatch Says:** half speed and a zombie; pass the grenade by touching someone or a stand-in; only obey "Overwatch says". [a test proves it: MoreStrangeDreamTests: molasses, hot potato, Overwatch says]
  Notes:
- [x] **Dance Marathon / Counting Headcrabs:** jump on every fourth beat (the ring on screen closes in); count headcrabs over the fence and say the number in chat. [a test proves it: MoreStrangeDreamTests: dance, counting headcrabs]
  Notes:
- [ ] **Music and lines:** put horse1.mp3 (or any dream's codeword, even maze1.mp3) in garrysmod/sound/livingcity/dreams/ and it plays in that dream. Recorded lines go in dreams/voice/, named as in VOICE_LINES.md. Dance: dance1.mp3 plus dance1.txt holding its BPM. [needs the real server: Song and line files to upload]
  Notes:
- [ ] **Editor:** Dreams: test one is now the last section of the Miscount Editor panel. [needs a person: Where the section sits in the editor panel]
  Notes:
- [ ] **The Exam, reworked (9 November):** you are stuck at a desk with a paper on it; type A, B, C or D in chat to answer. After six questions Doctor Kleiner walks to each desk, picks up the paper, eats it (loud crunching, head back, shaking, a big gulp), and only then is that person told their score. Does the paper sit on the desk properly, and does the eating look dramatic enough? [needs a person: Paper on the desk; is the eating dramatic enough]
  Notes:

## 9 November, later: nonsense dreams, and nonsense in every strange dream
- [x] **Hooves and All is Neutral now:** no Enforcers, and losing costs no health. [a test proves it: MoreStrangeDreamTests: the horse dream is neutral]
  Notes:
- [x] **Stop the Clocks / The Tea Party / The Headcrab Derby:** touch every melting clock (all stopped at once wins); move to your glowing seat when the host shouts; back a headcrab on its pad before the race (nonsense happens mid-race). [a test proves it: NonsenseDreamTests: clocks, tea party, derby]
  Notes:
- [x] **Say Cheese / The Doors / Splat!:** hide behind the giant things before the flash; stand at the door the music box plays behind; paint the floor your colour. [a test proves it: NonsenseDreamTests: say cheese, doors, splat]
  Notes:
- [x] **Conga! / Shh! / Bubbles / The Watchers:** stay in the glow behind the conga line; gather toys without waking the baby (running and jumping are loud); pop bubbles (big ones lift you); gather keys while the black figures only move when unwatched. [a test proves it: NonsenseDreamTests: conga, shh, bubbles, watchers (bubbles redone, line 120)]
  Notes:Blue bubbles need to initiate low gravity for 4x as long, and there need to be about 4x as many bubbles: I could only get 4 during the whole dream, there weren't enough. The biggest most positive change is that the blue bubbles are more abundant and the low grav jump is stronger and lasts longer.
- [ ] **Warped sounds:** are some sounds higher or lower, some recorded lines slowed or sped up, and does the music lurch slow or fast every so often (but never in Dance Marathon)? Too much, or not enough? [needs a person: Ear: warped sounds, too much or not enough]
  Notes:It shifted too much in the bubbles dream; it just needs to last longer for each pitch, like 2x as long. speed of the music should be altered too.
- [ ] **Performance:** with all the nonsense (12 floating things, faces, effects), does a dream stay smooth? If not, say so and the shares can be turned down. [needs a person: Feel: does a dream stay smooth on your machine]
  Notes:

## 9 November: who chooses tonight's dream
- [x] **As the Administrator:** tablet > Tonight's dream shows only "A Nightmare tonight" and "A propaganda dream tonight" (no list of dreams). Choose one: can you take it back? After it's dreamt, does the tablet say your next choice is in a couple of nights? Is the night after always Happy or Neutral? [a test proves it: DreamPlanTests: she chooses a kind every few nights]
  Notes:
- [x] **Only her own dreams:** on a night she didn't choose, lights out leaves the Administrator alone, and asleep she isn't pulled in. Turn "Dreams I didn't choose" to join: then she is, and can wake whenever she likes. On her own choice she has to go to bed. [a test proves it: DreamPlanTests: only her own dreams for her]
  Notes:
- [x] **No Administrator playing:** a calm day gives a Happy dream, an uneasy one Neutral, a unit murdered a Nightmare, red most of the day a Nightmare or propaganda. Never two Nightmare or propaganda nights in a row. Do the dreams go round in turn (no repeats until each of a kind has had its night)? [a test proves it: DreamPlanTests: the city by sociostability; round robin]
  Notes:
- [ ] **The black screen:** a few seconds before the dream, does the screen fade to black with a line about the day ("Today the city was calm. You slip off into a happy dream.") and then fade into the dream? [needs a person: The fade to black and into the dream, by eye]
  Notes:
- [ ] **NPC murders:** two units killed by NPC rebels within ten minutes turn the city yellow, four red (more with lots of players). A player killing one still only makes them wanted. [unsorted: DreamPlanTests counts NPC murders; could not confirm the yellow and red steps]
  Notes:
- [ ] **Duck and Cover rocket:** is it the rocket_low model now, a sensible size, and does it stay under the dream's ceiling as it climbs? [needs a person: The rocket's model and size under the dream's ceiling]
  Notes:

## 9 November: fair sides, and the Administrator asked at bedtime
- [x] **Bedtime question:** as the Administrator, lie down in the evening on a night you did not choose: a window asks "Dream it with the city, or sleep through it?". Each answer works for that night; "Remember this" changes the tablet setting too. Not asked for a daytime nap or on your own nights. [a test proves it: SideBalanceTests: the Administrator asked as she lies down]
  Notes:
- [x] **Sides kept even:** with 1 Combine player online, can a 7th player still join the Resistance? (They should not: double plus 4 is 6.) Does F4 say why? If Combine players leave, do the Resistance players online stay? [a test proves it: SideBalanceTests: Sides kept even (double plus 4)]
  Notes:
- [x] **Combine reserves grow:** with lots of Resistance players online, does the Combine manpower readout (F2) show bigger reserves that refill faster? [a test proves it: SideBalanceTests: the Combine's reserves growing with Resistance players]
  Notes:

## 9 November: help for the outnumbered side, the reconnect grace, a bigger NPC cap on bigger servers
- [ ] **Outnumbered Combine:** with 15 Resistance players to 5 Combine (or a quiet test with bots), are there more Civil Protection patrols on the streets? Kill a unit as a rebel: about fifteen seconds later, does a reaction squad come running in from out of sight (not pop up next to you)? Does the Combine manpower readout mention the reaction force? [needs the real server: Needs many real players or bots; the reaction force line is in SideBalanceTests]
  Notes:
- [ ] **Reconnect grace:** as a rebel on an uneven server, disconnect and come back within 7 minutes: still a rebel? Later than that, with the Resistance full: a citizen, told why? [needs the real server: A real disconnect and reconnect on an uneven server]
  Notes:
- [ ] **NPC cap:** on your 32-slot server nothing changes (100). The editor slider now says it is for a 32-slot server. [needs a person: The editor slider's wording, a glance]
  Notes:
- [ ] **Reaction squads, later:** with the sides uneven, attack a checkpoint (kill a unit near it, or short its power bank) or the Nexus as a rebel: does a dropship come in nearby and drop an Elite and 5 soldiers who run at you? On an ordinary kill in the street at green, 4 soldiers? Indoors with no sky, do they still come (on foot)? [needs a person: Watch a dropship squad arrive; needs uneven sides]
  Notes:

## 9 November, tougher Combine
- [x] **Health:** a metrocop takes noticeably more shots (70), a soldier 90, an Elite 150. Move the editor sliders (Population): the units out there change too. [replaced: A metrocop's toughness was changed on 14 November (line 1963)]
  Notes:
- [ ] **Desperate Combine:** with 4 or more Resistance players and the Combine at a third of that or less, a notice says the Combine are desperate; over about a minute and a half, metrocops start carrying SMGs, soldiers throw frags, green gas and flashbangs at Resistance fighters (never into their own or citizens), Elites fire more energy balls. Their flashbangs do not blind units. A notice when it ends. [needs the real server: Needs 4 or more Resistance players; could not confirm a test]
  Notes:
- [ ] **NPC cap:** on a 64-slot server the debug report shows a cap of 175 (with lc_npc_budget 100). [needs the real server: Needs a 64-slot server]
  Notes:
- [ ] **Desperation test (editor, "Desperate Combine: test it"):** Start the city, press 100%, then "Send 4 soldiers at me": they come from out of sight and throw frags, gas and flashbangs at you. Try "an Elite and 3 soldiers" (energy balls) and "3 armed metrocops" (SMGs at 100%, pistols at 0%). Compare 20% and 100%. "Back to normal" removes them. [needs a person: Watch the test squads throw and shoot]
  Notes:
- [ ] **Resistance fighters:** they take a few more hits (50 health), the same at home as in your squad. About 1 in 10 carries a crossbow: check they actually shoot it (if they just stand there holding it, tell me). With more Combine NPCs out, more fighters turn up in rebel zones (about 5 for every 4 units). [needs a person: Do crossbow fighters really shoot (health is in SideBalanceTests)]
  Notes:
- [x] **Squads:** alone on your side, recruit 5 rebels (or press E on 5 metrocops as a Metrocop): the 6th says your squad is full and why. F2 > Call for backup shows "(squad N of M)". As a Metrocop, E on a soldier says Overwatch only; E on an Elite says only the Overwatch Commander. [a test proves it: SquadSizeTests: Squad sizes, E on a unit to lead it]
  Notes:
- [x] **Backup by radio:** as the Resistance without a Freq 7 radio, F2 > Freq 7 > Call for backup is greyed ("no Freq 7 radio"). With one, take out the radio transmitter and left click: far from any fighters, a few turn up out of sight (from the rebel territory side) and run to you. As a unit, the radio on the CP net calls Civil Protection backup. [replaced: Freq 7 calls need the transmitter now, off F2 (line 1878)]
  Notes:
- [ ] **The Battle Line (dream, editor > Dreams: test one):** you get a pulse rifle; red rebels charge; shooting them drops them (check hits feel right, aim at the body). Shoot one of her soldiers: manhacks come for you; let them get you: you become a tiny red rebel with no gun, pushed at the line and shot over and over; your F2 voice lines squeak. Near the end giant metal/flesh rebels charge, then three gunships and a helicopter come in and bomb them. Check the gunship, helicopter and bomb models show and the sounds play. [needs a person: Models, sounds and how hits feel (see also line 108)]
  Notes:
- [ ] **Vortigaunt dream warfare (editor > Dreams: test one):** press "Vortigaunts break into the next propaganda dream (for sure)", then test a propaganda dream. A quarter to half way in: purple vortigaunts in rings of purple light, the screen goes purple, her figure flickers to flesh, and a HER / THE VORTIGAUNTS meter appears. Stand in a ring: the meter goes their way, and at the end her figure shatters and you wake. Stay out: she says "Begone!" and the dream carries on. Check the Administrator tablet dream menu shows the freed vortigaunts line when one is freed. [needs a person: Purple rings, her figure flickering, the meter by eye]
  Notes:
- [x] **Joining the Resistance:** a fresh citizen picks the Resistance in the faction menu: "The Resistance doesn't trust you yet." Hand a ration (F3, look at them up close, give) to a Resistance Fighter: "They'll remember that"; the same rebel again counts no more. At 5 sympathy you can join. A current member who reconnects stays in. [a test proves it: SquadSizeTests: a citizen with no sympathy can't walk into the Resistance]
  Notes:
- [ ] **Quartermaster for strangers:** as a citizen, press E on the quartermaster: his window opens with nothing to buy, but your guns, ammo, gun parts, scrap, rags and chemicals listed with "Sell for N" and "Donate". Donate a box of ammo: "We won't forget this." (+1 sympathy). As a member: the same Donate buttons beside your arms. [unsorted: Donating is tested (GettingByTests); the stranger's window is not confirmed]
  Notes:

## 9 November, part 13: the owner's answers, and the collapse
- [x] **Team chat:** press U and type: only your side reads it, marked (Team). Check a citizen and a cop do not see each other's. [a test proves it: TeamChatTests: Team chat (U)]
  Notes:
- [x] **No Half-Life 2 Overwatch voice:** an event with no recording of yours (say rations): the banner and words show, no stock voice. Editor > Events: the "Half-Life 2's own Overwatch voice" box brings it back. [a test proves it: TeamChatTests: no Half-Life 2 Overwatch voice]
  Notes:
- [ ] **Infestation warning posts:** the infestation that starts in a hallway: the sign, floodlight and barrel stand out past the hallway, off to one side, nothing in a wall. (Existing posts stay where they are until the next map start.) [needs a person: Real map: posts out past the hallway, nothing in a wall]
  Notes:
- [x] **The collapse, step by step (editor > The collapse):** place the "Administrator's desk" point in her office first. "Collapse to BLACK now": the purple BLACK readout, and as the Administrator, the G-Man then his window (step down / end it / refuse). Refuse, then "next step" four times: crates, sleeping and waking with a weapon, the city going dark, her last stand. [a test proves it: CollapseTests: sociostability BLACK, the G-Man's offer, her last stand]
  Notes:
- [x] **The last stand:** her bubble shield (purple), the time, health and shield bars, "HER OFFICE" marker for everyone else, 4 Elites round the desk, 8 rebels coming. Get close: the shield throws you back. Sabotage the transformer feeding her office: the bubble goes orange and weak. Civil Protection can't hurt her. [replaced: Her shield now falls with the transformers (lines 1372 and 1384)]
  Notes:
- [x] **Heroes:** "Make me Barney" then "Make me Freeman": you reappear in rebel territory, named in chat, with the weapons (Freeman has the RPG, crossbow, gravity gun), YOU ARE ... on screen; you take far less damage and deal more; Freeman comes back as Freeman when killed. The rebels in the city head for her office. Kill her: credits, back to yourself (name, model, weapons). Freeman's model is a rebel stand-in: send me a Workshop Gordon model to use instead. [a test proves it: CollapseTests: the heroes]
  Notes:

## 10 November: the G-Man in person, her transformer, out of character on F1
- [ ] **The G-Man in person:** editor > The collapse > "collapse to BLACK now" while you are the Administrator. He appears in front of you (nobody else sees him: ask someone), you cannot move while he talks, then his window. His lines: Half-Life 2's "Is it really that time again?" and the offers line, then the words only for the rest until your spliced clips are in (VOICE_LINES.md, rows 11 to 23). Shoot him, walk through him: nothing. [needs a person: The G-Man in front of you, his lines heard; ask someone if they see him]
  Notes:
- [x] **Walking away from him:** press "Walk away" on his window, or walk off: "Get back here...", a 10-second countdown. Go back, look at him, press E: his window again. Do it again and wait out the 10 seconds: a refusal ("Not for long..."), he walks off, and comes back at each of his steps. [a test proves it: CollapseTests: shutting his window is walking away, 10 seconds to come back]
  Notes:
- [ ] **Her transformer:** place "Her last stand: the Administrator's power" (layout list: The Administrator's last stand) and her desk within 100 feet. "Her last stand now": a purple bubble, a faint beam from the transformer to it, the transformer glowing. Shoot her: sparks and ricochets, no damage. Shoot the transformer: sparks each hit, smoke at three quarters, a small blast at half, heavy smoke, a big blast at the end; then she can be killed. Markers: "DESTROY IT" (or "GUARD IT" for the Combine). [needs a person: Bubble, beam, sparks, smoke and blasts by eye]
  Notes:
- [ ] **Out of character on F1:** F1, item 6 "Out of character...": type, Nearby or Everyone; Enter sends nearby. [unsorted: Out of character chat is tested (RPTests); the F1 entry is not confirmed]
  Notes:
- [ ] **Her desk, found by itself:** with the transformer placed within 100 feet of the office desk (even a desk that is part of the map), and no desk point: "Her last stand now" puts her beside that desk. If she lands somewhere else, place the desk point on or beside the desk and try again; tell me which desk model the map uses. [needs the real server: Your map's own desk: does she land beside it]
  Notes:
- [x] **F1 > 6:** "Out of character", then 1 Nearby or 2 Server-wide. [replaced: Same check as line 1374]
  Notes:

## 10 November, later: transformers, guards, squads, the suppression device
- [ ] **Placing the transformers:** re-place any transformer placed before today (it now faces you when placed, and the glass goes on that side). Place 2 or 3 "Her last stand: the Administrator's power" with # 1, 2 and 3 (the editor's number box), each standing where attackers would first see it from: the glass screen appears on your side. Shoot the glass: it stops bullets. [needs the real server: Your layout: re-place the transformers with the editor]
  Notes:
- [ ] **Her last stand with guards:** "Her last stand now". #1: a swarm of manhacks; #2: floor turrets, and metal panels round her office (pick one up with E, hold it in front of you, walk it into a turret to knock it over); #3: hopper mines, rollermines, two gravity guns nearby. The guards ignore Combine players. She floats in her bubble, not into the ceiling. Every 45 to 75 seconds an Overwatch squad runs in from outside. Destroy all the transformers: her shield goes down. [needs a person: Manhacks, turrets, mines, panels and squads: watch the fight]
  Notes:
- [ ] **BLACK: curfew and shelling:** "collapse to BLACK now": a mandatory curfew starts. As a rebel, stand outside under open sky near a Combine zone: a ring fades in on the ground under you, the incoming whistle, then the blast. One at a time. Under a roof: nothing. Place "Fixture: the suppression device" (the Nexus mortar): the shells come from it (a flash and launch sound there); shoot it to pieces and the shelling stops. Does the mortar model show (not an ERROR)? [needs a person: The ring, the whistle, the blast, the mortar model]
  Notes:
- [ ] **Collapse announcements:** record socio_black, black_stand, black_crushed, suppressor_down (both voices) and black_fallen (Overwatch); everything to record, with suggested words, is in VOICE_LINES.md. lc_voice_missing lists what is still missing. [needs the real server: Announcements to record and upload]
  Notes:

## 10 November, latest: scaling, the panels, the voice lines list
- [ ] **Scaling:** with several Resistance players on, "Her last stand now": more manhacks and turrets (8 to 100 and 4 to 25 from 2 to 20 players). The turrets never shoot down the manhacks. Squads arrive faster with more attackers near her office, each led by an Elite. Watch the server: does it hold up with a lot of manhacks? [needs the real server: Real load: does the server hold up with many manhacks]
  Notes:
- [ ] **Shield panels:** when her bubble comes up, a purple flash and jolt, and the panels fall out of the ceiling. Pick one up with E: does it cover you crouched? Do bullets stop on it? Walk it into a turret: does it tip over? (If the door model is too heavy to carry or too small, tell me.) [needs a person: Real physics: carrying a panel, cover, tipping a turret]
  Notes:
- [ ] **VOICE_LINES.md** (in the gamemode folder): every line still to record, in one list. Run lc_voice_missing on the server and paste the output to Claude to tick off what you have. [needs the real server: Run lc_voice_missing on the server and bring back the output]
  Notes:
- [ ] **Last stand sounds:** the flash comes with a white flash and teleport sound; each falling panel zaps and clanks; each transformer gives an electric blast as its guards appear; her bubble hums while it is up, each transformer hums while it powers her and goes quiet when destroyed. [needs a person: Ear: the flash, zaps, clanks and hums]
  Notes:

## 10 November, last: the arrival search

- [x] **Arrival search at the desks:** start a new character. A metrocop should stand beside Civil Intake and beside Housing Allocation. Walk past: he comes to you, you get "Show me how searches work" or "Just search me". Try the lesson: tips for each spot, the practice note in Boots, press R after a spot is checked. At the end: the lesson page and "Try the other side" (search a pretend citizen). [a test proves it: IntakeTutorTests: a unit at the desks, the lesson]
  Notes:
- [x] **Contraband on day one:** give yourself moonshine (or anything illegal) before the search. It should be taken with a warning, and you should not be wanted. [a test proves it: IntakeTutorTests: contraband found is taken, with a warning]
  Notes:
- [x] **Queueing next to him:** stand right beside the desk unit for a minute. He must never tell you to move back or arrest you. [a test proves it: IntakeTutorTests: standing next to the unit is never obstructing him]
  Notes:
- [x] **Leaving unregistered:** walk out of the station (about 1500 units from the desk and arrival point) before registering. The nearest metrocop should stop you, cuff you and walk you back to the Civil Intake terminal, then take the cuffs off. Never the cells. If he gets stuck, you should end up at the desk, uncuffed. [a test proves it: IntakeTutorTests: cuffs, walked back to the desk, never a cell]
  Notes:
- [x] **Leaving unsearched:** register while the desk units are busy, then leave. A unit should come and search you outside, then let you go. [a test proves it: IntakeTutorTests: out of the station unsearched, the nearest unit does it]
  Notes:

## 10 November, last: prison

- [x] **Sentences add up:** commit a petty crime and assault a unit, then get arrested. The chat should say "Your sentence: ... (3), Assaulting Civil Protection (10): 13 minutes". Give yourself up instead and it should be halved. [a test proves it: SentenceTests: Sentences that add up the record]
  Notes:
- [x] **Work detail:** in a cell, F1 > Ask for a work detail. A guard should come to your cell, walk you out (to the "prison work spot" point if you placed one), and there should be 6 bits of trash. E on each: 20 seconds off. Then he walks you back. Try walking far away from him: it should count as an escape. [a test proves it: SentenceTests: the work detail]
  Notes:
- [x] **Probation:** get released after an arrest as a citizen. You should be told you are on probation. F1 > Check in for probation next to a unit. Walk into rebel territory: probation violation. Wait out 15 minutes without checking in (another time): Failure to report. [a test proves it: SentenceTests: probation]
  Notes:
- [x] **Interrogation:** as a Resistance member, get jailed with a bad record. Answer each of the three questions differently (truth, lie, silence, bargain). As a CP player, stand by a prisoner's cell, F2 > Interrogate, ask questions and use the baton. [a test proves it: InterrogationTests: truth, lies, silence, a bargain, a unit asking in person]
## 10 November, citizens show the way
- [x] **Advice from a stranger:** as a new or hungry citizen, E on a citizen and Chat. They say something vague ("Try the bins") and a marker and a trail on the ground go to the nearest one. Chat again: rumours or small talk (advice once a minute). [a test proves it: TalkTests: Citizens who show you the way]
  Notes:
- [x] **A friend walks you there:** share food twice with a citizen (warm), then Chat while you need something. "Come on, I'll show you": the window closes and they walk; fall behind and they wait ("Keep up!"); at the place they say one line. Run far away and they give up and the trail shows the way instead. [a test proves it: TalkTests: Citizens who show you the way]
  Notes:
- [ ] **Settings:** `lc_citizen_lead 0` (everyone only points), `lc_citizen_advice 0` (Chat as before). [unsorted: TalkTests covers the feature; could not confirm the two settings]
  Notes:

## 10 November, last: survival modes

- [x] **Realistic by default:** your name should show "Hardened". Do a Union shift: the pay should be 20% more than before (18 instead of 15). [a test proves it: SurvivalModeTests: everyone starts on Realistic, Hardened, 20% more pay]
  Notes:
- [x] **Switch to Relaxed:** C > Your characters > the Survival button (or F2 > Me). Hunger and thirst should drop much slower; eating raw meat should never give parasites; meat should never go off; no toilet urge. "Hardened" should disappear. [a test proves it: SurvivalModeTests: Relaxed, a third of the hunger, no parasites]
  Notes:
- [x] **The 3 hours:** try switching back straight away: it should say when you can. [a test proves it: SurvivalModeTests: not again for 3 hours]
## 10 November, learning the city by living in it
- [x] **Tips wait:** walk up to a bin as a new character: no card. Walk away, come back after 4 minutes without searching one: now the card. Search a bin first and the card never comes. (`lc_hints_wait 0` is the old way.) [a test proves it: TalkTests, Learning the city: four minutes on, now the card comes]
  Notes:
- [ ] **Body signs:** get hungry (below 25): the colour drains with waves of weakness. Thirsty: warm haze and breathing. Below 35 health: red edges and a heartbeat. Off in C > Settings. [needs a person: Screen effects for hunger, thirst and low health]
  Notes:
- [x] **The dispenser talks:** use it with no ration card: it says "No ration card detected..." low on screen, the full reason in chat, no card at the top. [a test proves it: TalkTests, Learning the city: the dispenser says it, the reason stays in chat]
  Notes:
- [x] **Citizen Information:** place "Fixture: Citizen Information desk" behind a counter. E: the topics, the answers, Where is...? marks a route. Try it wanted (no answers), and with high and low standing (manner). [a test proves it: TalkTests, Learning the city: the clerk's topics, routes, wanted gets no answers]
  Notes:
- [x] **The old-timer:** find the citizen whose job says "Old-timer". E: his window. Bins and the dealer locked at first; visit and share food until he tells you, with the way marked. [a test proves it: TalkTests, Learning the city: the old-timer]
  Notes:
- [x] **Pamphlet:** register at Civil Intake: you get a Civil Orientation pamphlet. Read it from your pockets, pick pages. [a test proves it: TalkTests, Learning the city: a new arrival is handed the pamphlet]
  Notes:
- [x] **Civil notice posters:** place a few: by the dispenser, the Commissary, a sink, Civil Intake, the law board, somewhere empty. Each says the right thing. E reads it. [a test proves it: TalkTests, Learning the city: a poster says what is near it]
  Notes:
- [x] **PA explanations:** the "  > what it means" line in chat stops after the third of each kind. [a test proves it: TalkTests, Learning the city: counted for each kind of announcement]
  Notes:
- [x] **Mentor XP:** a friend you /recognize to a brand-new player: be near them at their first ration or shift: you get 25 XP. [a test proves it: TalkTests, Learning the city: a newcomer's first ration with someone they know]
  Notes:

## 10 November, last: sitting out dreams

- [x] **Happy and Neutral:** live through 2 Happy dreams. As the third comes, the black screen should show a small note under the mood line. F2 > Me (More) > My dreams should then offer "Happy: dreaming them (sit them out)". Choose it: the next Happy dream, you should sleep through it. [a test proves it: DreamSkipTests: two Happy dreams, Happy ones may be sat out]
  Notes:
- [x] **Nightmares and propaganda:** as a citizen with 400 standing, the same note and setting for Nightmares and Propaganda. Drop below 400 and they should come again. [a test proves it: DreamSkipTests: Exemplary (400), nightmares and propaganda may be sat out]
  Notes:

## 10 November, last: where I stand

- [x] **One window for the numbers:** F2 > Me > My standing (or Where I stand) (or C > You > Where I stand). Every number should be there with a line explaining it; wanted, a record or no close calls in red. [a test proves it: StandingPanelTests: Where I stand, every number in one window]
- [x] **The old-timer's troubles:** visit him: his greeting ends with what's troubling him (food first). Offer him food, then water, then tablets or a bandage, a ration card, a radio, each after he mentions it. Each warms him; after all five, "Sit with him a while" gives you his lockpicks. [a test proves it: TalkTests, Learning the city: his troubles, then his old lockpicks]
  Notes:
- [ ] **The pamphlet's new words:** read every page; tell Claude any line that sounds wrong. [needs a person: Reading: any pamphlet line that sounds wrong]
  Notes:
- [x] **Work detail by turns:** ask for a work detail three times in one sentence. First trash, then sweeping (a push broom and grime; hold E on each patch), then, if there are toilets in your Combine zone, unclogging: the guard walks you to each blocked toilet, E on it, water should splash out of the bowl for six seconds. [a test proves it: SentenceTests: the work comes by turns: trash, sweeping, toilets]
  Notes:

## 10 November, last: a unit's shift

- [x] **The quota:** as Civil Protection, F2 > Me > My shift. It should show the time left and searches, papers duty, inspections. Search 3 people (players or NPCs) and watch it count. [a test proves it: CPDutyTests: a unit's shift, the quota]
  Notes:
- [x] **Papers duty:** My shift > Checkpoint papers duty. Travelers walk up; E on each shows their papers. [a test proves it: CPDutyTests: checkpoint papers duty]
  Notes:
- [x] **Inspection:** with a citizen player online who has a room, My shift > Get an inspection order, go to their block, Inspect the residence. Contraband in their stash should be confiscated and they should be told. [a test proves it: CPDutyTests: inspections, contraband in their stash is confiscated]
  Notes:
- [x] **Review:** at the end of 15 minutes, a performance review with a grade and experience. [replaced: A shift is 30 minutes again (line 82); the review is in CPDutyTests]
  Notes:
- [x] **Illness (Realistic):** stand in the rain a while (or `lc_illness_rate 20` to hurry it): a cold, coughing. Buy Union medicine at the Commissary and take it. Eat raw meat: a stomach bug, vomiting; drink clean water. Leave a cold alone: maybe a fever (health stops at 60). On Relaxed: nothing. [a test proves it: TalkTests: Catching something: a cold, a stomach bug, a fever]
  Notes:
- [x] **The old-timer's new troubles:** his cough wants Union medicine (tablets refused), and his last trouble is a smoke (a cigarette), not a radio. [a test proves it: TalkTests, Learning the city: tablets are no good for his cough]
  Notes:
- [ ] **Poster art:** put a test image at `garrysmod/materials/livingcity/posters/curfew.png`, FastDL sync, change map: a curfew poster shows it. [needs the real server: A picture to upload, FastDL sync, map change]
  Notes:

## 10 November, last: snitches and burning

- [x] **Snitches:** draw a gun (or drink moonshine) in front of a few citizens. Now and then one should hurry off to the nearest metrocop, and a moment later you are wanted: "Reported by a citizen". [a test proves it: SnitchTests: seeing something illegal, they head for the nearest unit]
  Notes:
- [x] **Burning:** as a Resistance Member, F2 looking at a citizen > Burn them as an informant. RAT should appear over them for Resistance players; the quartermaster should refuse them. Put their hands up, F2 > Scar them: their description should gain the scar. [a test proves it: SnitchTests: the Resistance burning one; the scar]
  Notes:
- [x] **A wrong guess:** burn someone who never informed: every citizen should be told, and lose sympathy. [a test proves it: SnitchTests: burning someone who never informed, word spreads]
  Notes:
## 10 November: poster pictures
- [ ] **Poster pictures:** upload `materials/livingcity/posters/` (six `.jpg`), FastDL sync, change map. Each civil notice poster shows its picture (dispenser, Commissary, intake, water, law board, curfew elsewhere), sharp enough to read from a few steps away. [needs the real server: Poster pictures to upload, FastDL sync; then sharpness by eye]
  Notes:
- [ ] **Fever:** `lc_illness_rate 20`, catch a cold in the rain and leave it (or wait for a fever). With a fever: you can't sprint, fists don't swing. At 12:00 on the clock (`lc_time 11` to hurry) you drop for a minute into the fever dream: melting colours, rolling view, drifting words, the eye, slow sounds. You come to with it broken. Get someone to hit you during it: you wake, still feverish. [needs a person: The fever dream on screen (illness rules in TalkTests)]
  Notes:

## 10 November: the poster roll
- [x] **Poster roll:** as Director of Propaganda, take out the poster roll (slot 5). Reload: a list of seventeen posters opens; pick one. Left click at a wall: it hangs there with its picture. Right click on it: it comes down. A poster the editor placed does not come down. [replaced: Editor posters do come down now (line 1517); the rest is in TalkTests]
  Notes:
- [ ] **Poster roll, in your hands:** you see your hands and a sheet of paper. If the sheet sits wrong, try `lc_posters_view "20 0 -9"` (forward right up) and tell me the numbers that look right. [needs a person: Hands and sheet in your view]
  Notes:
- [ ] **The eleven new pictures:** work, loyalty, informants, contraband, radio, illness, infestation, housing, vortigaunt, recruit, administrator (she should read as Mossman). [needs a person: The eleven pictures by eye (needs the content zip)]
  Notes:
- [ ] **The carved rat:** scar a burned informant (hands up). A crude red rat should appear on their right cheek, and move with their head. If it floats off the face or sits in the wrong place, tell me what you see: lc_ratscar_pos moves it (forward, right, up, turn). They should never be able to join the Resistance after. [needs a person: The rat on the cheek, moving with the head (rules in SnitchTests)]
  Notes:
- [ ] **Fever aim:** with a fever, hold a pistol or SMG: it sways and drifts on screen; fire at a wall: the holes land where the gun was pointing, scattered. [needs a person: Feel: the gun's sway with a fever]
  Notes:
- [x] **Poster roll, the city's own posters:** right click on a poster the editor placed: it comes down. Hang a different one in its place. After a map change the editor's poster is back. [a test proves it: TalkTests, Learning the city: the roll takes the city's own posters down too]
  Notes:

## 10 November: the pamphlet's look
- [ ] **Pamphlet:** read the Civil Orientation pamphlet from your pockets. It opens as a folded paper leaflet: sections 1 to 8 down the left, a picture and the page on the right. Click each section (the picture changes), then "Fold it away". Tell me if any text runs off the paper or the font looks wrong. [needs a person: The leaflet's look: text on the paper, the font]
  Notes:

## 10 November: the Resistance and the posters
- [x] **Painting over a poster:** with a spray can in your pockets, look at a poster up close and use the can. After a moment the poster shows its painted-over picture, and E on it reads what was painted. Try a few different posters. [a test proves it: TalkTests, Learning the city: a poster can be painted over]
  Notes:
- [x] **A fresh sheet:** as Director, left click with the roll on a painted poster: it is clean again. [a test proves it: TalkTests, Learning the city: hanging over a painted poster pastes a fresh one]
  Notes:
- [x] **Paste-ups:** as a Resistance member holding a poster roll, reload: four Resistance posters are at the top of the list. Hang one. A citizen holding the roll does not see them. [a test proves it: TalkTests, Learning the city: the Resistance's paste-ups aren't for anyone else]
  Notes:
- [x] **The Colonel:** as the Resistance, go to the quartermaster: an old man (Odessa) beside him; "The Colonel, [E] talk". As a citizen or unit: nobody there. Bring a unit into the camp: he's gone; leave: back. Ask "What's the word?" during a sweep, a march, a supply drop. Bring 3 Union medicine, then find the dog tags in Combine ground, then kill the unit he names. Debrief after a Resistance job, clean and messy. Ask for whispers. A citizen next to you should see you "talking quietly to an empty corner". [a test proves it: TalkTests: The Colonel: only the Resistance can see him]
  Notes:

## 10 November: paste-ups
- [x] **Buying and pasting:** buy "Paste-ups (3)" from the Resistance quartermaster (a black market dealer should not list them). Look at a bare wall up close and use one from your pockets: after a moment a Resistance poster is on the wall. Use another on a different street: a different poster. [a test proves it: TalkTests, Learning the city: the paste-up, only the quartermaster sells it]
  Notes:
- [x] **The limits:** try to paste a second one near the first: refused ("There's one of ours close by already"). With `lc_pasteup_max 2`, paste a third somewhere else: the first one comes down. [a test proves it: TalkTests, Learning the city: not beside another; over the limit the oldest comes down]
  Notes:

## 10 November: window styles
- [ ] **Your faction's look:** open a few windows as a citizen (grey concrete), as Civil Protection (black and cyan), as Resistance (rust plate). Titles and text should stay readable everywhere. Tell me any window that looks broken, doubled or unreadable (a screenshot helps). [needs a person: Each side's window style: readable, nothing broken]
  Notes:
- [x] **Interrogation:** being questioned shows the black window with the red bar, whoever you are. [replaced: Interrogation is quick menus now (line 1918)]
  Notes:
- [ ] **Off switch:** `lc_ui_theme 0` in the console, then open a window: it looks as it did before. [needs a person: Windows with the style switched off, by eye]
  Notes:
## 10 November, last: planned operations and bounties

- [x] **Plan an operation:** as a Resistance Lieutenant (or a Fighter with no Lieutenant on), F2 > Resistance > Operations: pick a target, then 2, 5 or 10 minutes. Others in the Resistance should hear it and be able to join on the same page. When it starts, joiners get a waypoint; if it works, joiners there get 25 experience and 15 credits. [a test proves it: OpPlanTests: The Resistance plans its own operations]
  Notes:
- [x] **Bounties:** as the Administrator (or a Division Leader), F2 > Me > Bounties on the wanted: put 50 or 100 on someone wanted. Units and the wanted person should be told; the unit who arrests them gets paid. [a test proves it: OpPlanTests: the Combine puts prices on heads]
  Notes:
- [x] **Shifts back to back:** finish the checklist early, F2 > Me > My shift > Report in now: a review at once and a fresh shift. Try Go on a break, then Back on duty. [a test proves it: CPDutyTests: report in now, a break, back on duty]
  Notes:

## 10 November: the city's minds (watching only)
- [ ] **Leave it running:** with `lc_minds` on (the default), play or leave the server idle for a few hours. Then copy `garrysmod/data/livingcity/minds/` off the server (zip it) and bring it back. [needs the real server: Copy the minds folder off the server after a few hours]
  Notes:
- [x] **Debug report:** it has a section "The city's minds" with the most strained people. [a test proves it: MindsTests: The city's minds, watched and written down]
  Notes:
- [x] **How they seem (optional):** editor panel > NPC budget > tick "Talking to a named person says how they seem", then press E on a citizen: one more grey line. Untick it after. [a test proves it: MindsTests: lc_minds_show 1, how they seem and why]
  Notes:
- [ ] **Lag check:** with it on and off (editor panel, "Watch the city's minds"), is there any difference? (It should cost about 0.01 ms a second.) [needs the real server: Lag with it on and off, on the real server]
  Notes:

## 10 November, last: the state of the city

- [x] **The bulletin:** wait for a city morning (or an hour): a City Bulletin should appear on the screens and in chat with what changed. [a test proves it: LedgerTests: each city morning, a City Bulletin on the screens]
  Notes:
- [x] **F2 > Me (More) > The state of the city:** the five numbers in words and every block with who holds it. [a test proves it: LedgerTests: five numbers, districts with an owner]
  Notes:
- [x] **Her levers:** as Administrator, place a "Point: speech stand", then F2 > Me > The city's levers: go to the stand, give a speech (citizens nearby gain standing), declare an amnesty, order a crackdown on a block (a raid should start there) and extra rations (a ration day). [a test proves it: LedgerTests: her levers: a speech, an amnesty, a crackdown, extra rations]
  Notes:
- [x] **It carries over:** restart the server: the numbers and districts should be as they were, with the days that passed drifted through. [a test proves it: LedgerTests: the state of the city is kept on disk]
  Notes:
## 10 November: window styles, second pass
- [ ] **Terminal screens:** the Commissary, Civil Intake, Housing and Labor screens in the world are black glass with cyan lines and corner brackets, for a citizen too. Buttons light up with a cyan outline under the crosshair. [needs a person: Terminal screens' black glass look]
  Notes:
- [ ] **The quartermaster and the black market:** their window is rust and scrap for anyone. The Resistance lab too. [needs a person: The rust and scrap windows by eye]
  Notes:
- [ ] **Menus:** the C menu and any right-click menu are dark plates in your side's colours, and every line is readable. A drop-down list inside a window too. [needs a person: Menus in your side's colours: every line readable]
  Notes:
- [ ] **F1 / F2 and notices:** the quick menu and the notice card have your side's back. As the Administrator, F2 (her tablet entries) is black glass and cyan. [needs a person: Quick menu and notice card look]
  Notes:
- [ ] **Buttons that had their own colours:** they keep them (green, red, chosen) and gain an edge in your side's style. Tell me any button that looks wrong or any invisible click area that now shows a line. [needs a person: Buttons: any that look wrong]
  Notes:

## 10 November: the HUD in your side's look
- [ ] **HUD panels:** play a while as a citizen, as Civil Protection and as Resistance. The dark panels on screen (needs, tips, timers, job panels, cards) are grey slab, black glass with cyan, or rust with an orange line. Bars and coloured edges look as before. Tell me any panel that looks wrong, any text that became hard to read, or any fade to black that now shows a panel (a screenshot helps). `lc_ui_theme 0` puts it all back. [needs a person: HUD panels in each side's look: readable]
  Notes:

## 10 November: more looks
- [ ] **The lambda:** as Resistance, your windows (and the quartermaster's, and the lab's) have a yellow sprayed lambda bottom right, and the text over it is still readable. The black market dealer's window is plain rust with no lambda. [needs a person: The sprayed lambda; text over it still readable]
  Notes:
- [ ] **Vortigaunts:** a free vortigaunt's windows are green with a glow; a shackled one's are the same green under a cyan line. [needs a person: Vortigaunt window colours]
  Notes:
- [ ] **The Administration:** as the Administrator or her Director, windows are black glass with ivory lines and a red edge. [needs a person: The Administration's window look]
  Notes:
- [ ] **Staff:** the Staff window, admin testing tools and the character screens are plain charcoal marked out of character. [needs a person: Staff windows' plain look]
  Notes:
- [x] **On the streets:** order a crackdown on a block: a metrocop should take up a post in the middle of it and stop people. Win a few rebel operations in one block until it is the Resistance's: units walking there should now and then be ambushed, and the black market there should be cheaper. Watch Commissary prices rise as supply falls. [a test proves it: Ledger2Tests: checkpoints, ambushes, prices]
  Notes:
- [x] **Small-server mode:** with 4 or fewer on, chat should say "A quiet night in the city". Events and rebel operations should come noticeably more often. When a fifth player joins, it should say the city is back to its usual pace. [a test proves it: SmallServerTests: with few players, the city carries more of the story]
- [ ] **Citizens drinking and smoking:** stand near citizens for a few minutes: now and then one lights up (puffs of smoke from their head) or swigs from a bottle in their hand, and stops when they walk off. Does the bottle sit right in the hand? Too often, or too rare? (Editor panel: "Citizens fond of a drink and a smoke" turns it off.) [needs a person: Smoke and bottle in hand: looks right, too often or too rare]

## 10 November: the Cremator

Needs Workshop items 2090972521 (and 3329322225) in the server collection, then a map change.

- [ ] **The model is found:** as an admin, type `lc_cremator_spawn` in the console while looking at the ground. It should say which model and which idle, walk and fire animations it found. Send that line back if anything looks wrong. [needs the real server: Needs the Cremator Workshop items on the server]
  Notes:
- [ ] **How it looks:** the Cremator stands, walks (feet moving, not sliding too badly) and faces the right way. No second figure or stalker visible inside it, no red beam from it. [needs a person: How the Cremator stands and walks (needs the Workshop model)]
  Notes:
- [x] **Bodies:** leave a body lying for 90 seconds near it: it walks over, a green flame plays on the body for about five seconds, the body is gone and a scorch mark is left. A body you are hauling is left alone. [a test proves it: CrematorTests: it walks to the body, turns its flame on it, the body is gone]
  Notes:
- [x] **Enemies:** as a citizen with empty hands it ignores you. With a gun out (not as Civil Protection) it comes at you and burns you when close. Shoot it: it turns on you and nearby units come. Rebel NPCs out in the city get burnt. [a test proves it: CrematorTests: who is an enemy, and who is left alone]
  Notes:
- [x] **Killing it:** it takes about 400 damage, falls (a ragdoll if the model has one), and another turns up some minutes later out of sight. Fire does not hurt it. [a test proves it: CrematorTests: sturdy, fire does nothing to it]
  Notes:
- [ ] **Players who join** download the Cremator addon by themselves and see it (not an ERROR sign). [needs the real server: Joining players downloading the Workshop addon]
  Notes:

## 10 November, last: citizen goals

- [ ] **Status symbols:** buy fine clothes (standing 150) and put them on from F3: you should look better dressed and show "Well dressed". Buy a lamp or cactus and use it in your own block: it should appear where you look and still be there after a restart. A radio set should play music with E. A pet bird should sit on your shoulder (tell me if it floats: lc_petbird_pos moves it). [needs a person: Clothes, lamp and the bird on your shoulder by eye (rules in StatusTests)]
  Notes:
- [x] **Households:** look at another citizen, F1 > Invite into my household; they accept on F2 > Me (More) > My household. They should move to your block, open your storage crate, and get your apartment keys. [a test proves it: HouseholdTests: the same block, shared crates and lockers, keys]
  Notes:
- [x] **A business:** craft a rag doll (3 rags), put it on your stall at about 20. Within a few minutes a passing NPC should buy it. Offer another citizen a job (F1); they accept in F2 > Me > More; they should be able to stock your stall and get 10 credits from the till every 10 minutes they are there. [a test proves it: EmploymentTests: hand-made goods, the city's people buying, hiring a worker]
  Notes:
- [x] **Crime between citizens:** get behind another player, F1 > Pick their pocket. Lend someone money with F1; repay it from F2 > Me > More > Household and business > My debts. Buy from the black market a few times: now and then it should go bad (a brick, or a sting). [a test proves it: StreetCrimeTests: pickpocketing, debts, deals that go bad]
  Notes:
- [x] **Insider, report it clean (10 November):** as an Insider on a shift, get an inspection order on a resident with contraband in their stash, go to their block with nobody else about, F2 > Me > My shift > Report it clean. The quota counts, the stash stays, the resident hears on Freq 7. Then raid that block (a sweep) within 30 minutes: -15 Civil Standing. With someone watching, it refuses. [a test proves it: CPDutyTests: an Insider reports the residence clean]
  Notes:
- [ ] **F2 More for units (10 November):** as a Civil Protection unit, F2 slot 8 reads More: Records terminal, Me...; inside are Records terminal and Me (My shift). [unsorted: Could not confirm a test for F2 slot 8 reading More for units]
- [x] **The Colonel looks like a ghost:** faintly see-through, a cold blue tint, slowly fading in and out with the odd flicker. [replaced: He starts solid and turns ghostly now (lines 1683 and 1685)]
  Notes:
- [x] **Give something (talk window):** E on a citizen: "Give something..." opens a menu of what you carry (food first). Try food, a beer or cigarette (someone fond of it lights up there and then; someone sober refuses), medicine, the Civil Orientation pamphlet, and a gun (refused, frightened; a sympathizer hides it). With nothing to give, the button is greyed out. [a test proves it: GiveTests: Giving a citizen something]
## 10 November: the Resistance pamphlet

- [x] **Buying and reading:** as a Resistance member, buy "Pamphlets (5)" from the quartermaster. Pockets > Resistance pamphlet > Read: a folded sheet in purple ink with an orange lambda opens, six pages on the left, the page typed on the right. Is the typed text easy to read on your screen? [replaced: The pamphlet is handwritten now, not typed (line 1653)]
  Notes:
- [x] **Leaving one:** F1 > Leave a Resistance pamphlet here, in front of a bench or table and on the floor. A sheet of paper lies there. Another player presses E on it and reads it; a citizen can "Pocket it", a Civil Protection player can "Confiscate it". [a test proves it: RebelPamphletTests: left lying about; pocket it, confiscate it]
  Notes:
- [x] **First read:** a citizen who has never read one gets "Sympathy +1" once, and the member who left it is told. [a test proves it: RebelPamphletTests: the first one a citizen ever reads, 1 sympathy]
  Notes:
- [x] **Handing to a player:** F1 > their name > Hand them a Resistance pamphlet: it is in their pockets. [a test proves it: RebelPamphletTests: handed to a player, it's in their pockets]
  Notes:
- [x] **Handing to a citizen NPC:** F1 > This person > Hand them a Resistance pamphlet. Try several people: some take it and become sympathisers, some tuck it away, some push it back. [a test proves it: RebelPamphletTests: handed over; one who won't pushes it back]
  Notes:
- [x] **Risk:** do either in front of a Civil Protection unit: you are wanted for it. Leave one on a patrol route: the unit takes it and the Civil Protection radio says where. [a test proves it: RebelPamphletTests: a unit watching, a crime; a unit walking past takes it]
  Notes:
- [ ] **The handwriting:** the pamphlet's pages and list are in a sloppy hand, not typed. If you see a plain font instead, restart the game once (the font was only just downloaded) and look again. Easy enough to read? [needs a person: Is the handwriting easy to read (needs the font from the content zip)]
  Notes:

### Getting the Cremator information to send back

  1. Add Workshop items 2090972521 and 3329322225 to the server's Workshop collection. Upload the gamemode, press "FastDL sync" in the host panel, change the map, and rejoin.
  2. In game, as an admin, open the console (the key under Esc), look at open ground a few steps away, and type: `lc_cremator_spawn`
  3. The chat shows one line: either "A Cremator, model ...; animations: idle '...', walk '...', fire '...'" or "No Cremator model was found on the server". Copy that line.
  4. The console also shows lines starting `[cremator]`: every model found and every animation the model has. Copy those too (select them in the console, Ctrl+C).
  5. Watch it for a minute and note: does it stand upright, do its legs move when it walks, does it face the way it walks, can you see a second figure inside it or a red beam, does a green flame come out when it burns a body?
  6. Type `lc_debugreport` and copy the line starting "Cremators:" from the People section.
  7. If it said no model was found: in your own Garry's Mod, with the two addons subscribed, hold Q, open the Addons list on the left of the spawn menu, click the Cremator addon, right-click the Cremator model and choose "Copy to clipboard". That is the model's path (it starts with `models/`). Send it, or set it yourself in the server console: `lc_cremator_model models/the/path.mdl` and then run step 2 again.
  8. Paste all of it into the chat.
- [x] **Give menu as Civil Protection:** with a gun in your pockets, E on a citizen > Give something: no guns listed. [a test proves it: GiveTests: a Civil Protection player's Give menu has no guns]
  Notes:
- [ ] **The old-timer's face:** find him: a citizen's clothes with the Lost Coast fisherman's head. Check the head sits right on the neck while he walks, talks and turns. If you see his ordinary face, your game lacks the model: in the spawn menu search "fisherman". [needs a person: The fisherman's head on the neck as he moves]
  Notes:

## 10 November: dreams, easier to live with (the audit)

- [x] **Counting dreams:** dream a Happy dream to its end twice (not waking early). F2 > Me (More) > My dreams should say "Happy dreams lived through: 1 of 2." after the first, and offer sitting Happy dreams out after the second. [a test proves it: DreamSkipTests: each dream lived through is counted by its kind]
  Notes:
- [ ] **Waking from F1:** in a dream you play, lose your lives (or win). The top line should change to "You can wake up now: F1 > Wake up from the dream", and F1 should list it. Before that, F1 should not have it. [unsorted: DreamGameTests knows when you can wake; the F1 entry is not confirmed]
  Notes:
- [x] **Time left:** while dreaming, a small line under the top one says "It ends in M:SS at the latest." and counts down. [a test proves it: DreamGameTests: their screen knows when it ends at the latest]
  Notes:
- [ ] **Admins, C > Help > Dreams:** with a dream going on, it shows the mood, who is in it, and a countdown that moves without pressing Refresh. [needs a person: The staff dream page and its moving countdown]
  Notes:

## 10 November: the Colonel turns ghostly as you get to know him
- [ ] **A new Resistance character:** the Colonel by the quartermaster looks like a solid old man, with a shadow, no flicker. [needs a person: The Colonel solid, with a shadow, by eye]
  Notes:
- [ ] **Give him the three medicines:** over a few seconds he turns a little see-through and loses his shadow. After the tags, more. After the unit, fully ghostly (faint, cold, fading and flickering). [needs a person: The Colonel turning see-through, by eye]
  Notes:
- [ ] **Two Resistance players, one who has done his jobs and one who has not:** each sees him their own way at the same moment. [needs the real server: Needs two real Resistance players at once]
  Notes:
- [ ] **Ask the Colonel "What's happening to you?":** not offered while he looks solid. After the first job it is there once and he brushes it off; it comes back once after each further quarter (a job, or ten visits five minutes apart after all three jobs). Fully ghostly, he tells the truth, and from then on his greeting says it too. [unsorted: The Colonel is tested (TalkTests); this one question is not confirmed]
  Notes:

## 10 November: the minds act, the director and free talk
- [ ] **Minds act:** leave the server running with a few named citizens out. Within the hour somebody should break in the street (a line starting `**` in chat when you are near). Check `data/livingcity/minds/` has `DID` lines after `WOULD` lines. [needs the real server: Leave the server running an hour, then read the minds folder]
  Notes:
- [ ] **Bias:** a hungry or worn down named citizen should be seen queueing or sitting more than working. Does the street still look busy enough? [needs a person: Does the street still look busy enough]
  Notes:
- [x] **Unrest:** after a rough stretch (beatings, arrests) does sociostability go yellow for "the mood of the city", and come back? [replaced: That reason is no longer shown (line 41); unrest is in MindsTests]
  Notes:
- [ ] **Key:** editor panel > "The director and free talk": paste the key, Save, Test. Does the notice say the model answered? [needs the real server: Needs your key for the hosted model]
  Notes:
- [ ] **Free talk:** look at a named citizen within a few steps and say something in chat. Do they turn and answer in a few seconds? Is the voice right for the city? Try a unit too. [needs the real server: Needs the key; then is the voice right for the city]
  Notes:
- [ ] **Director:** play 20 minutes, then read the debug report section "The director and free talk": are its last decisions sensible, and did you see one happen (someone walking up to you with a line)? [needs the real server: Needs the key and 20 minutes of real play]
  Notes:
- [ ] **Cost:** after an evening, compare "requests today" and the tokens in the debug report with the bill on the service. [needs the real server: Compare the debug report with the service's bill]
## 10 November: the dreams stand-ins act

- [ ] **In the maze (few players asleep, so stand-ins appear):** do they keep near you, and bolt when a giant officer comes close? Lose a life near one: does it flinch, and does one say your name in chat? [needs a person: Stand-ins in the maze: keeping near, bolting, flinching]
  Notes:
- [ ] **How the poses look:** cowering (hands over head), cheering, waving, glancing over a shoulder. Say which look wrong (an arm bent the wrong way, a head turned oddly) and for which model (man or woman). [needs a person: Stand-in poses: which look wrong]
  Notes:
- [ ] **A propaganda dream:** do the stand-ins kneel facing her with arms held out or hands together? [needs a person: Stand-ins kneeling to her, by eye]
  Notes:
- [ ] **An ending as a dream (for example the bus):** the stand-ins turn to you and wave or cheer instead of standing like statues. [needs a person: Stand-ins turning to wave or cheer]
  Notes:

## 10 November: falling asleep late, and when the next dream is

- [ ] **Late into a dream:** have one player asleep when the dream starts and another lie down about 20 seconds later. The second should appear in the dream with every life, and the first should see "drifts into the dream, late" in chat. Both wake with everything. [needs the real server: Needs two real players; no test found for the late sleeper]
  Notes:
- [x] **Not twice:** lose all your lives, wake up, and stay in bed. You should not be pulled back into the same dream. [a test proves it: DreamGameTests: they aren't taken into the same dream twice]
  Notes:
- [ ] **Late into an ending (for example the bus):** does the late sleeper see the ending properly (music, dancing) from where it has got to? [needs a person: Needs two players: does the late sleeper see the ending properly]
  Notes:
- [ ] **The Administrator, tablet and F2 > Tonight's dream:** the first line says when the next dream is; at night it counts down. [unsorted: DreamPlanTests exists; could not confirm the 'next dream' line]
  Notes:

## 10 November: staged dreams, and The Midnight Rally

- [ ] **The opening and finish:** start any dream you play (the editor's Dreams: test one). Its name should show between black bars at the start; win it and "You made it through" should show. [needs a person: The name between black bars, the finish line]
  Notes:
- [ ] **Figures acting:** in the maze, lose a life near a giant officer (does he shake a fist?). In Kneel Before Her, does her figure point at you when you lose a life, and do the admirers reach out to her? [needs a person: Figures shaking a fist, pointing, reaching]
  Notes:
- [ ] **Other dreamers' bodies (needs two players):** when one loses a life, does the other see them flinch? Does a winner cheer? After waking, is the body normal again? [needs the real server: Needs two real players: flinch and cheer on each other's screens]
  Notes:
- [ ] **The Midnight Rally, driving:** test it from the editor. Does the buggy accelerate, brake and reverse? Does it feel right in corners (too slidey, too stiff)? Is it smooth or does it stutter? Is the view from behind the buggy good (too close, too far)? [needs a person: Feel: how the buggy drives, the view]
  Notes:
- [ ] **The Midnight Rally, the race:** do laps count as you cross the line? Do the crates give a pickup, and does Jump use it (boost, melon, horn blast)? Do the rival buggies drive the road and finish? Is the race too long or too short? [needs a person: Laps, pickups and length: too long or too short]
  Notes:
- [ ] **The Midnight Rally, looks:** the buggy size, the cones, whether you can tell the road from the grass at a glance. [needs a person: Buggy size, cones, road against grass]
  Notes:

## 10 November: real seats for the chair dreams

- [ ] **Musical Chairs:** when the music stops, crouch (or press Use) at a free chair. Are you really sat in it, at the right height and facing a sensible way? Do you stand up beside it when the next round starts, and can you move normally afterwards? [needs a person: Sat in the chair at the right height (only Use sits you now, line 1750)]
  Notes:
- [ ] **Shalom, lifted on the chair (as a player):** are you sat on the chair as it goes up and round, without your legs looking wrong? Is the chair under you? When you come down, are you back in the ring and dancing? [needs a person: Sat on the lifted chair; legs and place in the ring]
  Notes:
- [ ] **Her office, empty (11 November):** with a key set and nobody elected, wait 15 minutes with a few players on. Does "The City Administrator" announce a decree with a sentence of her own, and does it fit what happened? Get elected: does she stop? [needs the real server: Needs the hosted model's key and 15 minutes with players on]
- [ ] **Musical Chairs, 11 November:** press Use at a chair while the music is still playing: a life gone (of three) and back to the start. When it stops, only Use sits you down; crouching does nothing. [unsorted: StrangeDreamTests covers musical chairs; could not confirm the early Use rule]
  Notes:
- [x] **The G-Man and the city's own (11 November):** with nobody elected, let the city go BLACK a few times (or step it with the staff tools). About two times in three she should step down or end it after one or two refusals; the third, her last stand. [a test proves it: CollapseOwnTests: the city's own Administrator refuses the G-Man one to three times]
- [x] **The close, 11 November:** dream one of the endings to its end (the harpies, the plane, the fire). As you wake in bed, "The dream is over" and a line about that dream should show for five seconds. Lose a dream you play: a closing line too. [a test proves it: DreamCrowdTests: 'The dream is over' goes to a dreamer as the dream ends]
  Notes:
- [ ] **Her voice (11 November, once there is an ElevenLabs key and voice id):** editor panel > "Her voice": paste both, Save, Test her voice. Do you hear her? Tick the box, wait for a decree from the city's own Administrator: is the sentence spoken after the PA, for everyone, in the same voice as her recordings? [needs the real server: Needs an ElevenLabs key and voice id]

## 11 November: the harpies carry you off

- [ ] **Carried off:** in the harpies ending (or as a dream), let them bring you down. Does one lift you over its head and run into the dark with you, the screen going black? Does it look right (your height over it, how fast it goes)? [needs a person: How being carried off looks: height, speed, the black]
  Notes:
- [ ] **Turned:** about six seconds later, are you watching from a mingebag of your own as it goes after the others? Do the others see the two chat lines (carried off; comes back, one of them)? [needs a person: Your view from the mingebag; others see the chat lines]
  Notes:
- [ ] **Not interrupted (changed 11 November):** have someone shoot a mingebag carrying a player, a unit or a citizen. Nothing should stop it: it keeps going, and whoever it has is turned. [needs a person: Needs a helper shooting; carrying is in EndingTests]
  Notes:
- [ ] **The harpies, all of it (11 November):** watch the Combine's units and the citizens: are they carried off too, with no bodies left? At the very end, is the last player snatched up and turned, not killed? Does it still feel like a slaughter is coming, or too slow? [needs a person: Feel: does a slaughter seem to be coming, or too slow]
  Notes:
- [ ] **The harpies, the finale (11 November):** stay alive to the last five seconds: are you killed (a body), then three seconds from the end do you rise out of the ground as a mingebag where you fell, and do all of them run off into the night just before the song ends? Are there enough of them that the scene fills the whole song? Does the server cope with 90? [needs a person: The finale by eye; and does the server cope with 90]
  Notes:
- [ ] **Recorded lines (11 November):** record a handful first (`say_dunno`, `say_greet_plain`, `say_no`, `say_warn_go`, `say_open_listen`, a man and a woman), FastDL sync, change map. Talk to named citizens: do they answer with those lines in that voice, and does an opener run on into the line? Do the words in chat match what is heard? [needs the real server: Lines to record, FastDL sync, map change]
  Notes:
- [ ] **One voice (11 November):** after recording a few `say_` lines for men, do named men stop saying Half-Life 2 lines in the street and the talk window, while unnamed men still do? Is the street too quiet? [needs the real server: Needs recorded lines; then is the street too quiet]
  Notes:
- [ ] **Units' own clips:** run `lc_voice_missing`: which unit lines are listed? Run `lc_hl2_lines` and bring back `data/livingcity/hl2_lines.txt`. [needs the real server: Run lc_voice_missing and lc_hl2_lines on the server]
  Notes:
- [ ] **Replacing Half-Life 2 lines (11 November):** make one (`sound/livingcity/hl2/vo/npc/male01/hi01.mp3`), FastDL sync, change map, `lc_voice_replaced` should say 1. Do citizens say yours instead of the stock "Hi", both when the gamemode plays it and when the game does by itself? Then try one metropolice clip. [needs the real server: A replacement clip to upload, FastDL sync]
  Notes:

## Sound clip audit (run these on the server, any time)

Type them in the server console on the host panel, or in your own game console (the ` key) as a superadmin. Nothing is changed by any of them.

- [ ] **`lc_voice_missing`**: every voice line with no recording on the server yet, by folder (announcements for Overwatch and the Administrator, the radio, dreams, the G-Man, citizens, units, the clerk, the old-timer, machines). It also writes the whole list to `data/livingcity/voice_missing.txt`: download that and give it to `elevenlabs_batch.py --missing` so only what you lack is made. [needs the real server: Run lc_voice_missing on the server]
  Notes:
- [ ] **`lc_announce_clips`**: the announcement recordings it DID find, for each voice and trigger (how many takes of each). Use it to check the Administrator clips already on the server are being seen: a clip that is there but not counted is misnamed or in the wrong folder. [needs the real server: Run lc_announce_clips on the server]
  Notes:
- [ ] **`lc_announce_rescan`**: looks again after you add files without a restart, and says how many it found. [needs the real server: Run lc_announce_rescan on the server]
  Notes:
- [ ] **`lc_voice_replaced`**: how many Half-Life 2 clips have a recording of yours in `sound/livingcity/hl2/`. [needs the real server: Run lc_voice_replaced on the server]
  Notes:
- [ ] **Do this one first: `lc_hl2_lines`** (needed for the two-voices-by-personality plan in `TODO.md`): run it once in the server console, then download `data/livingcity/hl2_lines.txt` from the host panel's file manager and give it to Claude. Open it first: does each clip have its words after its name, or only names? Say which. [needs the real server: Run lc_hl2_lines and bring back the file]
  Notes:
- [x] **`lc_hl2_lines`**: writes `data/livingcity/hl2_lines.txt`, every Half-Life 2 citizen, unit, soldier and Overwatch clip the server has, with its words. Needed once, before making your own versions of them. [replaced: Same command as line 1790]
  Notes:
- [ ] **`lc_sound_check`**: the folders it reads sounds from and what is in them (the older, general check). [needs the real server: Run lc_sound_check on the server]
  Notes:
- [x] **The Cremator's pace (11 November):** watch one walk the streets. It should move about twice as fast as before and its feet should roughly keep up with the ground. Too fast or still too slow: set `lc_cremator_speed` in the server console (2 now; try 2.5 or 1.5) and say which number looked right. [replaced: The Cremator's pace was relisted on 14 November (line 15)]
  Notes:
- [ ] **Editor, "Arrange by what it's for" (11 November):** a "Dreams" folder now holds Point: dream and Zone: dream. Check it is there and that clicking each picks it. [needs a person: The Dreams folder in the editor's list]
  Notes:
- [ ] **Pictures loose in garrysmod/ (11 November):** unzip `livingcity_content.zip` in `garrysmod/`, FastDL sync (it should upload the posters, `ui/`, `pamphlet/` and `lcrebelhand.ttf`, and delete nothing), change the map, join from a clean client: posters show pictures, window backs are textured, the Resistance pamphlet is handwritten. [needs the real server: Unzip livingcity_content.zip, FastDL sync, join from a clean client]
  Notes:
- [ ] **Two voices (11 November):** with a key set, talk to several named citizens. Do they answer with real Half-Life 2 lines, spoken, that fit what you said ("I would not say that too loud", "Know what you mean")? Do units answer with their own clips ("Move along", "Final warning") and do the words on screen match what is said? Note any unit line whose words are wrong. [needs the real server: Needs the key; do spoken lines match the words]
  Notes:
- [ ] **The new name, Miscount:** the server list and the F-menus say Miscount, chat lines start `[Miscount]`, the guide is headed "MISCOUNT: A GUIDE", and with !build the editor is under Q > Tools > Miscount ("Miscount Editor"). Every `lc_` command still works as before. [needs a person: The name Miscount on menus, chat and the server list, a glance]
  Notes:
- [x] **The chronicle (12 November):** play for a while with named citizens and units about (get someone beaten or arrested, wait for a break in the street). Then press E on a citizen and Chat a few times: once the usual rumours run out you should hear a story ("They say ...", or "I saw it myself. ..."). Nobody should ever tell you who informs. As an admin: F1 > What now? > The city's stories (or `!news`) lists the day with the secrets; a non-admin is told it is for staff. [a test proves it: ChronicleTests: what happened, and what led to it]
  Notes:
- [ ] **The two boards (12 November):** with !build, Q > Tools > Miscount Editor, place "Fixture: Civil Protection incident feed" (a Combine monitor) and "Fixture: Resistance notice board" (a corkboard). Check the words sit on the glass and on the board's visible face, the right way up and readable. Arrest someone: `DETAINED: NAME.` appears on the feed within about 20 seconds. Attack a unit: `ASSAULT ON ...` in red. The Resistance board only fills when a sympathizer or a Resistance player saw something, five minutes after. [needs a person: Words on the glass and the board: right way up, readable]
  Notes:
- [ ] **The chronicle, for you:** after a week, copy `garrysmod/data/livingcity/chronicle/` off the server (the `_stories.txt` file is the readable one) and bring it back. [needs the real server: Copy the chronicle folder off the server after a week]
  Notes:
- [ ] **The interrogation chair (12 November):** with !build, place "Fixture: Resistance interrogation chair" somewhere in rebel ground. Check the lamp hangs over it and is dark. As a Resistance fighter, press E on a citizen within about 1200 units of it: "Take them to interrogation chair". They should walk to it and sit, and the lamp should come on: a bright cone straight down on them. Press E on the chair: ask (they refuse), hit them a few times, ask again. Try it on a citizen you saw do something, and on one who did nothing (twice or more: they should turn on you). Walk away for 20 seconds: they get up. Say how the lamp looks and whether they sit properly. [needs a person: The lamp and how they sit (rules in ChairTests)]
  Notes:
- [ ] **The holding cage (12 November):** with !build, place "Fixture: Resistance holding cage" in rebel ground, standing where you want the gate to face. Check: four chain link sides in a tight square, the gate on your side. As a Resistance Fighter or above, press E on a side: the window opens; Open the gate (it should swing out), Shut it. Press E on a citizen within about 1500 units: "Take them prisoner (to the holding cage)": they walk over and are locked in. Take up to four. From the cage window send one to the interrogation chair, then from the chair "Back to the cage with them". A Member or a citizen pressing E on the cage is told it is locked. Say how the fence and gate look and where the prisoners stand. [needs a person: Fence and gate look, where prisoners stand (rules in CageTests)]
  Notes:
- [ ] **The Resistance's prisoners, part 2 (12 November):** take a few citizens prisoner with a chair near the cage, then stand back. Within about 15 seconds the cell should start taking them to the chair one at a time by itself (a voice from behind the lamp, blows, then back to the cage), and after five minutes each is let out. Check the Resistance notice board after someone breaks: "NAME admitted it in the chair: ...". While anyone is held, Father Grigori should be at the cage preaching, a line every 30 to 60 seconds (kill him, or be Father Grigori yourself: a vortigaunt should walk over instead; with none, a rebel). Fill the cage with eight: say whether they fit, and whether they are set straight when one leaves. [needs a person: Do eight fit in the cage; watch it run (rules in CageTests, RebelRuleTests)]
  Notes:

## 12 November: the patdown, lockpicks on cuffs, the cage for players, quick menus
- [ ] **Cuffing a player:** does a list come up at the left by itself (1 Pat them down, 2 walk them along, 3 cuffs off), and do the number keys work while you move? [needs the real server: Needs a second real player; the list and number keys on screen]
  Notes:
- [x] **Patdown:** does it take the weapons, radio and lockpick from their pockets, and leave food? As a rebel, do you get what you found? [a test proves it: PatdownTests: the patdown takes weapons, a rebel gets what was found]
  Notes:
- [ ] **A unit walking you in:** does it search you first, and skip it during a firefight? [unsorted: PatdownTests exists; could not confirm the search before the walk]
  Notes:
- [x] **Pick the cuffs (F1) with a lockpick:** does a watching captor take the pick? Alone, do the cuffs open? [a test proves it: PatdownTests: a lockpick on the cuffs]
  Notes:
- [x] **The cage:** drag a cuffed player to it as a Fighter: are they put inside? Can they walk through the fence? After picking the cuffs and the padlock, does the gate open so they can walk out? [a test proves it: PatdownTests: players in the Resistance's cage]
  Notes:
- [ ] **The chair and the cage menus:** now lists with number keys, what was said written underneath. Readable? In the way of anything? [needs a person: The number key lists: readable, in the way of anything]
  Notes:

## 12 November, later: the evidence locker, the chair for players, the rules and executions
- [ ] **Evidence locker** (editor: Fixture: evidence locker): does it stand right? As a unit, E lists what was confiscated; as a citizen, can you pick it or pry it, and take your things back? [needs a person: Does the locker stand right (its rules are in PatdownTests)]
  Notes:
- [ ] **The right-hand panel:** cuffed, in the cage, in the chair, looking at a prisoner or the locker: does it show what you can do? [needs a person: The right-hand panel on screen in each case]
  Notes:
- [ ] **A player in the chair:** does the prisoner get the three answers on the number keys? Can they see anything but the lamp? Does the asker's menu stay usable? [needs a person: Needs two players: what the prisoner sees under the lamp]
  Notes:
- [ ] **The clipboard:** does the leader get it? How does it look in the hand? Do the boxes tick, and does the Resistance board show the mood and rules as its first lines without crowding out the news? [needs a person: The clipboard in the hand; the board's first lines]
  Notes:
- [x] **Executions:** as a Fighter, ask permission; as a Lieutenant, give or refuse it; kill without permission and answer for it. Does each menu come up for the right person? [a test proves it: RebelRuleTests: executions]
  Notes:
- [x] **Be kind** in the chair: talk, food, ask them to join. [a test proves it: RebelRuleTests: kind options]
  Notes:
- [ ] **A cuffed citizen with a hidden lockpick:** cuff several, skip the patdown, walk ahead with your back to them. Does one slip the cuffs and run? Looking at them, do you sometimes get the "something glints" line? [unsorted: PatdownTests covers lockpicks; could not confirm the slip and the 'glints' line]
  Notes:
- [ ] **How cuffed people look:** cuff a player and a citizen. Are the arms behind the back (not through the body, not out to the sides)? Are the two rings on the wrists, the right size, with the link between? Have the player work at the cuffs: do the hands and fingers fiddle? If the pose is off, try `lc_cuff_pose "24 10 35 -28 20"` with other numbers and send the ones that look right (and a screenshot of what was wrong). [needs a person: Cuffed arms, the rings on the wrists, fingers fiddling]
  Notes:
- [x] **Small things are missed in a patdown:** put three lockpicks and a pistol in a friend's pockets, cuff them, pat them down twice. The pistol should go the first time; the lockpicks only some of the time. Does a rebel NPC usually have one, a plain citizen almost never? [a test proves it: PatdownTests: each lockpick is found or missed by itself]
  Notes:

## 12 November: named citizens recorded
- [ ] **Named citizens speak:** with the recordings in `sound/livingcity/citizens/` (after FastDL sync and a map change), talk to a few named citizens; `lc_voice_missing` lists no citizen lines. The nine reworded lines (for example "Sorry, but no.", "Getting by. That's all I can do.") show the same words that are heard. [needs the real server: Needs the citizens' recordings uploaded]
  Notes:
- [ ] **Citizens speak without the director (12 November):** with the recordings up, talk to named citizens (E): hello by how they feel, Chat says how they are, give food (thanks), walk away (goodbye). Say "hello" and "how are you" in chat facing one. Watch two citizens chat in the street, a unit beating someone with citizens near, and wait near citizens for one to walk up (hungry, a warning, a gift). Too chatty or too quiet? `lc_voice_approach` sets the walk-ups, `lc_voice_cues 0` turns it all off. [needs the real server: Needs the recordings; then too chatty or too quiet]
  Notes:

## 13 November: HQ calls only over the radio, the resupply scanner, gas masks
- [x] **The Radio menu:** as a unit, get the radio out (next to Hands) and right click. Is the menu there with the number keys (Request resupply, Call for backup, Send my 10-20, Issue a BOLO, Records check, My directives)? Does it close when you put the radio away? Are backup, BOLO and 10-20 gone from F2, Unit tools and the C menu? Does F2 > 4 draw the radio and open its menu? [a test proves it: RadioHQTests (HQ only over the radio) and RadioJobsTests (the Radio menu)]
  Notes:
- [x] **Refused without the radio:** type !backup, !bolo something, !records as a unit with your hands out. Each should say to get your radio out. [a test proves it: RadioHQTests: !bolo and !records, not without the radio]
  Notes:
- [ ] **Insider:** with two bands, is Switch frequency on the Radio menu? Is Let them slip now F2 > 5? [unsorted: Switch frequency is tested; InsiderSlipTests still says F2 > 7, not F2 > 5]
  Notes:
- [x] **Request resupply:** outside under open sky, low on ammo or hurt. Does a shield scanner come down from the sky above you, drop a small crate that breaks on landing, then fly back up and away toward the nearest Combine zone? Is what lies on the ground right (ammo for your gun, a vial or battery, cuffs, a grenade for your rank)? Try indoors and underground: it should refuse. [replaced: The scanner's look was relisted at line 31; the rules are in RadioHQTests]
  Notes:
- [ ] **Gas masks:** as a rebel, put a CP uniform in your pockets and press Scavenge gas mask. Search a dead unit (mask whole or broken). Make one from four broken. Walk into chlorine gas: does the mask go on by itself, with the visor edge and breathing, and come off a few seconds after you leave? How does the mask look on a face (lc_gasmask_fit "forward right up scale" to adjust)? [needs a person: The mask on a face and the visor edge (rules in GasMaskTests)]
  Notes:
- [ ] **In the gas:** do citizens and rebels without a mask cover their mouth with their left hand and cough, and run out of it away from units? About 1 in 3 rebels should mask up instead. Tune the arm with lc_handface_mouth. [needs a person: The hand over the mouth pose (running is in GasMaskTests)]
  Notes:
- [ ] **Flashbang:** do blinded rebels hold their left hand over their eyes and stumble, without shooting? Tune with lc_handface_eyes. [needs a person: The hand over the eyes pose and stumble]
  Notes:
- [x] **Ammo limits:** buy or pick up more than 150 pistol rounds (or 30 shells, 225 SMG): does it stop at the limit? Die and respawn, get revived after a close call, sleep through a dream: still no more than the limit? lc_hl2_ammo 0 brings back Garry's Mod's 9999. [replaced: Owner tried it; the fixes are at line 27 (limits in RadioHQTests)]
  Notes: if I have boxes of ammo in my inventory, it lets me, and tells me, that I can load them infinitely no matter if my ammo is already full. ALSO, if it issues me a health vial and my health is full, it now seems to just drop the health vial on the ground? And I press E on it and I just hold it in front of me, never putting it into my pockets: can we please have pressing E on a health vial when pockets are full put it in my pockets?
- [x] **Freq 7 kit:** get promoted to Fighter: are you told you were issued a Freq 7 radio and a transmitter, and can you talk on Freq 7 straight away? Try to sell, drop, stash or give them: refused? As a Member with only a Freq 7 radio: are Call for backup and Send my position greyed "no transmitter"? [a test proves it: Freq7KitTests: a Fighter's issued radio and transmitter]
  Notes:
- [x] **No psychic communication:** as a rebel, is F2's Freq 7 page now Find the way (just the two guides)? With the transmitter put away, are !r, backup and position refused? With it out, does talking, left click (backup) and its right click menu (message, backup, position) all work? [a test proves it: Freq7KitTests: no broadcasting without a transmitter]

## 13 November: Pick Up That Can (a fever dream)

- [ ] **The scene:** test it from the Miscount Editor (Dreams: test one, Pick Up That Can). Does the officer stand by the bin and swing at it about 3 seconds in, with "Pick up that can."? Is the bin the right one, standing on the floor? [needs a person: The officer, his swing and the bin by eye]
  Notes:
- [ ] **Your can:** does it sit on the bin, fall to the floor with a white glow, and can you pick it up with Use? Does it sit well in your view while held? With a second player: do you each see only your own? [needs a person: The can's glow and how it sits in your view]
  Notes:
- [ ] **At him:** throw it at the officer. Does the can grow to a man's height, wobble, and hold the stunstick somewhere sensible? Does the officer shrink onto the bin? Is the next thing you pick up a tiny officer? Hit it again: does another can, bin and tiny officer appear beside the first and knock its own officer off? [needs a person: The living can and the tiny officer by eye]
  Notes:
- [ ] **In the bin:** throw it in (or stand over the bin, look down, click). Does the bin grow, does he chuckle, and does it rain cans around you? [needs a person: The bin growing and the rain of cans]
  Notes:
- [ ] **Anywhere else:** throw it at the floor. Does a coloured can grow where it landed, and does he get taller and deeper each time? [needs a person: The coloured can trees; his height and voice]
  Notes:
- [ ] **The end:** with all three tried, do you wake Unbroken ("Every which way")? Is aiming fair (too easy or too hard to hit him or the bin)? [needs a person: Is aiming fair: too easy or too hard (rules in CanDreamTests)]
  Notes:
- [ ] **The tiny officer's voice:** once the can has swapped with him, does your tiny officer squeak threats and orders (knocked off, picked up, in your hand, thrown, in the bin)? Too often, too loud, too high? Do the other cans' officers squeak from the floor too, and is thirty of them bearable? [needs a person: Ear: the squeaks, too often, too loud, too high]
  Notes:
- [ ] **Which scene is yours:** hit the living can so a new can, bin and officer appear. Is it lit for you (golden beam, pulsing glow, circling lights, "YOURS" over it), and are you told "That one is yours"? Is your next tiny officer knocked off that bin? With a second player: do they see their own lit, not yours? Is the beam too much or too little? [needs a person: Is your own scene lit clearly; beam too much or too little]
  Notes:
- [ ] **Speeches, attended (13 November):** place a speech crowd point in front of the speech stand. As the Administrator, F2 > Me > The city's levers > Give a speech: is Overwatch's call heard, do the NPCs stand in rows facing the stand, does the podium (Breen's console) look right in front of her? Skip it as a citizen: warned, then the stick until you black out, waking in the crowd? With nobody as Administrator, set the city to midday (lc_speech_city_hour) and watch her speak at the podium herself. [needs a person: Rows facing the stand, the podium's look (rules in SpeechTests)]
  Notes:
- [ ] **Sympathizers at parades and speeches:** in the cheering crowd, a few should half salute late and mutter flat (needs spy_flat_male1/spy_flat_female1 recorded; silent without). Does the salute arm pose look right on citizens? [needs a person: The salute arm pose (the mutter needs a recording)]
  Notes:
- [ ] **The harpies dreamt in a forest:** pick the harpies as tonight's dream (F2, as Administrator). Are the pines there (Episode Two) or Half-Life 2's trees? Do the mingebags slip behind trees and rocks and out again? Too many trees for the edict limit? [needs a person: Trees and mingebags hiding by eye; too many trees for the server]
  Notes:
- [ ] **Her own stitched speech:** with nobody as Administrator, on a morning with no exercise, let it reach midday (or set lc_speech_city_hour). Does she say an opening, a few lines about what really happened lately (arrests, a beating, posters...), one about the mood, and a closing, one after another? Are the pauses between pieces right? [needs a person: Ear: the pauses between the pieces of her speech (order in SpeechTests)]
  Notes:
- [x] **The drill at the jogging start:** with no exercise yard placed, run `lc_exercise drill`: does the leader stand at the jogging route's first stop with the rows in front of it? If the rows land in a wall, turn that stop to face open ground (the rows form the way it faces). [replaced: The jog's stops are gone; its start is an exercise yard now (line 55)]
  Notes:

## 13 November, later: the TODO run (felt cuffs, quick menus, the save tool, dream posters, the Fitness Test, Cubbage answers)
- [ ] **Resisting arrest, felt:** get cuffed by a unit player and hammer E. No bar: does the view jolt, do the screen edges close in as you lose and open as you win, does the line change, is the heartbeat there at the end? `lc_struggle_bar 1` brings the bar back. [needs a person: Feel: the jolt, the closing edges, the heartbeat; needs a unit player]
  Notes:
- [ ] **Working at / picking the cuffs, felt:** cuffed, F1 > Work at the cuffs, and with a lockpick Pick the cuffs. Clicks and creaks faster as it goes, small jolts, the line changing; is it clear enough without a bar? [needs a person: Feel: clicks and jolts, clear enough without a bar]
  Notes:
- [ ] **Talking to a citizen is a quick menu:** E on a citizen. Number keys, their words under it, Give something opens a page; F3/F4 shut when it opens; walking off closes it. [needs a person: The talk menu on screen: number keys, their words under it]
  Notes:
- [ ] **A unit's search is a quick menu:** search a citizen (baton reload). Numbers check the spots, found items show in the list, Done searching: check their papers, 0 ends it. The person searched still sees their panel and R. [needs a person: The search menu on screen, for both players]
  Notes:
- [ ] **Interrogation as quick menus:** F2 > Interrogate someone in a cell. The unit: three questions, baton, Done, answers under it. The prisoner (a player): answers by number, seconds left shown. [needs a person: The interrogation menus on screen, for both sides]
  Notes:
- [ ] **Save with the gamemode:** Q > Tools > Miscount > Save with the gamemode. Left click a spawned prop, change map, is it back? Do saved props glow green only while the tool is out? Right click stops saving. [needs a person: The save tool and its green glow; a real map change]
  Notes:
- [x] **Dream posters:** with a few Civil notice posters placed away from machines/desks, do about a quarter show a night-blue "SLEEP WELL, CITIZEN" poster? Different ones the next day? (`lc_dream_posters 1` to make them all show one for testing.) [a test proves it: DreamPosterTests: a quarter of them, a different few the next day]
  Notes:
- [ ] **The Fitness Test:** editor panel, Dreams: test one > The Fitness Test. Hurdles jumpable, stones reachable with a running jump, batons flat and jumpable, falling and being swept send you to the last green flag, gold tile passes. [needs a person: Feel: are the hurdles, stones and batons jumpable]
  Notes:
- [ ] **Colonel Cubbage answers:** after one of her addresses (or `lc_speech_answer_delay 10`), does Odessa Cubbage stand up at the camp and answer point by point, in chat near him and on Freq 7? Does the ghost now have another old man's face (`lc_colonel_model`)? [needs a person: Hearing him near the camp; the ghost's new face (rules in SpeechAnswerTests)]
  Notes:

## 14 November: the dream posters
- [ ] **Dream posters, the pictures:** unzip `livingcity_content.zip` in `garrysmod/`, FastDL sync, change the map. A plain curfew poster hinting at Where's Lamarr?, The Cheese Dream, The Watchers or Mirror, Mirror should carry its picture (a headcrab mugshot, cheese refused, eyes round a bed, her face in a mirror). Any other dream, It's Raining Melons among them, still shows the drawn notice in the city. [needs the real server: Needs livingcity_content.zip and FastDL; then the pictures by eye]
  Notes:
- [ ] **The forecast inside the melons dream:** Miscount Editor > Dreams: test one > It's Raining Melons. A big FORECAST: FAIR, WITH PRODUCE poster should stand at each of the meadow's four sides, facing in; E on one reads it. Are they the right size and height, the right way round, and do they stay in view when you look away from their middle? [needs a person: The four forecast posters: size, height, facing]
  Notes:
- [ ] **One-sentence subtitles:** read a few dream posters with E: the small words should be a single sentence each. [needs a person: Reading: one sentence each on the dream posters]
  Notes:
- [x] **A new life as a vortigaunt:** die permanently (or start a fresh slot): a window asks citizen or vortigaunt. Choose vortigaunt: shackled, a "Laborer VLB-..." designation, no train. F2 > Reach out is refused for the first 4 minutes, then works. Stay shackled 10 minutes: do two rebels come and cut you loose (a Free Vortigaunt)? As a human, the Free Vortigaunt is gone from the Resistance list in F4. [a test proves it: PlaytestNov14Tests: vortigaunts chosen at the start, the rescue]
  Notes:
- [x] **Repel the attack:** does the tracker say "Put down the attackers (2 of 5 down)" and count every attacker, whoever kills them? [a test proves it: PlaytestNov14Tests: every attacker counted]
  Notes:
- [ ] **Action music:** shots into the air or a wall: silence. Hit an enemy twice, or get hit: it starts. [needs a person: Ear: silence when idle, music after two hits (rule in CombineMusicTests)]
  Notes:
- [x] **Squad revive:** down mid-fight with squad units near: do they keep fighting while being shot, and come to get you up once nobody has hit them for 5 seconds? [a test proves it: PlaytestNov14Tests: revive priority]
  Notes:
- [ ] **Chevrons:** watch for any straight line through walls again. If one shows, send the debug report. [needs a person: Real map: any trail line through a wall]
  Notes:
- [ ] **Dreams, less text:** no status cards, hints or sociostability pill in a dream; the goal line goes after 15 seconds (Tab shows it); one short wake line; notices lower down. [needs a person: Is there less on screen in a dream; readable]
  Notes:
- [x] **Collapse:** an hour of yellow should barely move the collapse bar now. [a test proves it: PlaytestNov14Tests: yellow fills the collapse at 5% of what it did]
  Notes:
- [ ] **Nightmare and propaganda dream posters (21 more pictures):** after unzipping `livingcity_content.zip`, FastDL sync and a map change, a curfew poster hinting at any Nightmare or any of her propaganda dreams should carry its own picture. Any picture you would change? [needs the real server: Needs livingcity_content.zip and FastDL; then any picture you would change]
  Notes:
- [ ] **Way marks (the Resistance's arrows):** Miscount Editor > "Mark: Resistance arrow, pointing left" (and right, up, down, and "Mark: FREEDOM THIS WAY"): left click a wall. Does each arrow point the way its name says, the right size, the lambda's orange? Is it still there after a map change, and does right click take it off? Can it be scrubbed (it should not)? On a floor it should refuse. [needs a person: Arrow direction, size and colour (line 1955 says it does scrub off)]
- [ ] **The announcer:** stand around for 5 minutes: at most one of the map's own Overwatch lines in that time, none on top of a city announcement. The debug report's Layout part says how many of the map's lines were let through and silenced, and its log lists every "PA: overwatch says ..." line. [needs a person: Ear: the map's own PA lines over five minutes (rule in MapPATests)]
  Notes:
- [x] **Way marks scrub off and come back:** as a citizen or a unit, E on a painted arrow: it scrubs off like any graffiti. Walk away out of sight: after about 4 minutes it should be back. Stay and watch it: it should not reappear while you can see the wall. [a test proves it: WayMarkTests: scrubbed off, and back with nobody looking]
  Notes:
- [x] **Her slogan:** at her address (the city's own, or test it), just before the closing she says "Love your neighbour, hate the traitor." (words on screen until `speech_slogan1.wav` is recorded in `sound/livingcity/administrator/`). [a test proves it: SpeechTests: her speech has the slogan before the close]
  Notes:
- [ ] **The slogan's poster:** as Director of Propaganda, the poster roll's second poster is LOVE YOUR NEIGHBOUR, HATE THE TRAITOR: hang it, read it with E (the slogan and nothing after it), and spray over it as the Resistance (LIES). [needs a person: No test found for the slogan's poster; hang it, read it, spray it]
  Notes:

## Your 14 November notes and the to-do list: built, please try (14 November, later)
- [x] **Pistol on a metrocop:** about 10 hits now (fewer with head shots). Soldiers as tough as before? [a test proves it: The owner's 14 November notes: a player's shot at a metrocop does half again]
  Notes:
- [ ] **Rations:** after a while, do the stores stay up? `lc_stock` prints where rations went this hour. [needs the real server: An hour on the real server, then lc_stock]
  Notes:
- [ ] **The medic:** one in each rebel territory. E on him hurt: vial 3, medkit 8. Does he stay put, and patch up hurt rebels near him? [needs a person: Prices are tested (14 November notes); watch him stay put and patch rebels]
  Notes:
- [ ] **Lowered gun:** on rebel ground as a rebel, does the gun tip down in your view when lowered, and come back up when raised? [needs a person: The gun tipping down in your view]
  Notes:
- [ ] **Scientist:** no handing-over gesture when you just talk to him; it plays when he hands you something. Eyes open, blinking? [needs a person: His gesture, eyes open and blinking]
  Notes:
- [x] **Filling a can:** a few feet from the water's edge (not in it): does Fill work? [replaced: Redone the same evening (line 2062)]
  Notes:
- [x] **Powered vest:** fully charged when you put it on? [a test proves it: SalvageTests: an armour vest goes on fully charged]
  Notes:
- [x] **Jobs screen:** Union shift and Civil rehabilitation say YOUR JOB; fewer jobs, changing more often; Doctor the records only for a Hacker; Extraction starts in the Combine's city. [a test proves it: The owner's 14 November notes: YOUR JOB, jobs changing, Doctor the records, Extraction]
  Notes:
- [ ] **Commissary screen:** no more shimmering lines? [needs a person: Shimmering lines on the screen]
  Notes:
- [x] **Go to ground:** as a rebel, get to Overwatch response (alert 3): a job comes by itself; reach the other camp: does the hunt stop? [a test proves it: The owner's 14 November notes: Go to ground comes only with a manhunt]
  Notes:
- [ ] **Operations on F4:** as a Lieutenant, plan one straight from the Operations board. [needs a person: No test found for planning from the F4 board; a quick try]
  Notes:
- [ ] **Close call:** as a unit, die once: do you wake at the clinic? [unsorted: Only a rebel's close call is confirmed in the 14 November notes tests]
  Notes:
- [ ] **Loudspeaker boxes:** a box with a cable under every loudspeaker? Where does it sit? As a Hacker, splice one; when the Colonel answers her, is he heard there? As a unit, cut it out. [needs a person: Where the box sits under each loudspeaker (splicing is in the 14 November notes tests)]
  Notes:
- [x] **Get the lab running:** parts from the reclamation yard, the radio repair shop and a loudspeaker box. [replaced: Reworked the same day into searching and the wiring game (line 2023)]
  Notes:
- [ ] **Dream card:** a black card before each dream you play (what it is, rules, win, lose). Long enough? Space skips it. [needs a person: The dream card: long enough to read]
  Notes:

## Your 14 November answers: built, please try
- [x] **Prison guard:** as a Combine Prison Guard, F4 shows Cell inspection (hold E on everything in the cells until the spoon turns up; the bunk and toilet do nothing else meanwhile), Question a prisoner (the quick menu: ask, baton, "Liar.", until the truth), A break for it, Unrest in the cells (order them down or the baton before a door gives). Do four: are you a Combine Soldier? [a test proves it: The owner's 14 November answers: four prison guard jobs, then a Combine Soldier]
  Notes:
- [x] **The infested:** not on F4 Factions. Go down to a zombie or headcrab inside an infestation and bleed out: do you come back infested in the nest? Got up in time: nothing. Killed as infested: a new character (no close call)? [a test proves it: The owner's 14 November answers: nobody chooses the infestation; killed, no close call]
  Notes:
- [ ] **Lamarr:** at a lab run by Dr. Kleiner, is she on the bench? Does she sit right (not floating or sunk)? E on her. Have a unit take Kleiner away: is she gone, and back with him? [needs a person: Does Lamarr sit right on the bench (her comings and goings are tested)]
  Notes:
- [ ] **Dressed dreams:** a ring of props below the edge of each playable dream. Does it look right, and is it out of the way? [needs a person: The ring of props round each dream: looks right, out of the way]
  Notes:
- [ ] **Job board:** place "Fixture: job board" in the city, on rebel ground and on Combine ground. Do the lists show, and does E open your jobs? [needs a person: The board's lists on its glass, on each side's ground]
  Notes:

## The dream flight recorder (14 November, last)

- [ ] **A recorded test:** Q menu > the editor > Dreams: test one. *Record the test (for the code chat)* is ticked. Test any dream, play it, and wake (or Stop the test). A notice and a chat line say where it was saved. [needs the real server: Your own game: a recorded dream test and its notice]
  Notes:
- [ ] **The folder:** on your PC, `~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/livingcity/dreamrec/` has one folder for the test, with `log.txt` and `shot_*.jpg`. Open `log.txt`: the pacing check on top lists the dream's texts with TOO FAST / tight / ok. [needs the real server: Files on your PC: the dreamrec folder and its log]
  Notes:
- [ ] **Notes as you play:** type something in chat during a test ("this bit lost me"): it is in the log as `you typed:` at that second. [needs the real server: Your own game: chat notes written into the log]
  Notes:
- [ ] **Does it slow the dream?** If a recorded test feels choppier than an unrecorded one, say so (and try the screenshot slider at 0). [needs a person: Feel: is a recorded test choppier]
  Notes:
- [ ] **Unticked:** untick *Record the test*, test a dream: no new folder, no notice. [needs the real server: Your own game: no folder when unticked]
  Notes:
- [ ] **Send one:** zip a test's folder and give it to the code chat: `cd ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/livingcity/dreamrec && zip -r ~/dreamrec.zip FOLDER_NAME` [needs the real server: Zip a test's folder from your PC and send it]
- [x] **The lab:** only charge cells, firebombs and the foil hat listed (plus decode, new face, pull the chip). Guns and the rest only at the quartermaster. [a test proves it: The owner's 14 November answers: the lab's list; forged cards not the lab's]
  Notes:
- [ ] **A new face:** forty seconds, black screen, whirring and wet sounds, a clang, a ding at the end. Too long, too short, too gross? [needs a person: The new face scene: too long, too short, too gross]
  Notes:
- [x] **Get the lab running:** the parts are searched for by hand (hold E) at the yard and the shop, and freed from a loudspeaker box with the wiring game; the bench is rewired the same way. [a test proves it: Robot players: every job taken and done (in tests.lua, not yet in the index)]
  Notes:

## 14 November: no more stand-still steps
- [ ] **Hold E jobs:** Bin round (each bin), Graffiti removal (the bucket), The count (three crates), a leaking pipe (the valve), Paper the walls (a see-through flyer at each spot). Does the bar fill, and is the thing easy to find and aim at? [needs a person: Is each thing easy to find and aim at on the real map]
  Notes:
- [x] **Wiring game:** fix a streetlight (work order), Sabotage (the charge at the checkpoint: it blows when wired), Free a vortigaunt > cut the shackles here (the collar). [a test proves it: Robot players: every job taken and done (in tests.lua, not yet in the index)]
  Notes:
- [ ] **Needle game:** Break them out (the cell lock, alarm going), a vortigaunt's A whisper in the vortessence and Read the Combine. Is the window's wording odd for a vortigaunt? [needs a person: Reading: is the window's wording odd for a vortigaunt]
  Notes:
- [ ] **Others:** Address the citizens (speak to 3), The secret mass (bless the three who gather: do they come?), Leak the schedule (dead drop game), Dead drop (note handed over on arrival), Collect your ration (ends at the front of the line), letters (delivered at the door), a stalker's Processing. [needs a person: Watch them: do the three gather; the rest is in Robot players]
## The play study (14 November, last)

- [x] **Start it:** F4 > Factions > *Admin: play study* > *Start: this session counts*. The top right of the screen says STUDY: counting. [a test proves it: The play study: switched on from the window]
  Notes:
- [x] **Pauses:** noclip, take out the editor's tool, alt-tab away, and leave the keys alone for a minute and a half: each time the line says STUDY PAUSED and why, and counts again when you're back. [a test proves it: The play study: paused while flying, out of the window, away from the keys]
  Notes:
- [x] **A job:** take a job and finish it; take one and abandon it. In the window, the last job is named on the *Strike the last job* button. [a test proves it: The play study: the last job can be struck]
  Notes:
- [x] **A dream:** test a dream with the study on. It carries on (as "a dream"), kept apart from the city. [a test proves it: The play study: a dream as its own context]
  Notes:
- [ ] **Stop and save:** a notice says where. On your PC, `~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/livingcity/study/` has a folder with `report.txt` and `log.txt`. Does report.txt name your faction and rank, and the places, as you'd expect? Are the place names (zone, whose ground, "by a ... point") fine-grained enough to tell your activities apart? [needs a person: Read your own report: are the place names fine enough]
  Notes:
- [ ] **Does it slow the game?** If play feels heavier with the study on, say so. [needs a person: Feel: does play get heavier with the study on]
  Notes:
- [ ] **Send one:** `cd ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/livingcity/study && zip -r ~/study.zip FOLDER_NAME` [needs the real server: Zip a study folder from your PC and send it]
  Notes:
- [x] **Bug reports and feedback:** F1 > 6 > 3, type a line, send. Is there a new file in the server's `garrysmod/data/livingcity/feedback/` with your words on top and a debug report under them? Does a second one within a minute get refused? [a test proves it: FeedbackTests: Bug reports and feedback from players]
  Notes:

## 14 November (evening fixes)
- [ ] **Overwatch PA:** play an hour. No two Overwatch or Administrator routine lines within 90 seconds of each other; "ration stores running low" at most once in 20 minutes. [needs a person: Ear, over an hour: no two routine PA lines within 90 seconds (PacingTests has the rule)]
  Notes:
- [ ] **Landing ambush:** take "Ambush the landing". If the door opens and nobody comes out, soldiers appear at the landing zone within about half a minute; the counter always has someone to shoot. [needs a person: No test found for the empty landing; take the job]
  Notes:
- [ ] **Any kill counter** (Ambush a patrol, Back up the raid, Join the sweep, Proof): kill counter short of targets for 10 seconds brings more; nothing at all for 45 seconds, you are paid for what you did. [needs a person: No test found for the kill counters' top-up; try one]
  Notes:
- [ ] **Guns over a restart:** draw a bought pistol and SMG, restart the server, rejoin: both are in your pockets to draw again (not your rank's own guns). [needs the real server: A real server restart; no test found]
  Notes:
- [ ] **Filling a can:** standing near water you can see fills it; ten feet from water hidden under ground or brush does not. [needs a person: Real map water: near water you can see, and hidden water]
  Notes:
- [x] **Collapse:** one checkpoint attack and the red after it leave collapse at about 3%, not 30% (an hour of red adds 20%). [a test proves it: CollapseTests: an hour of red adds 20%]
  Notes:
- [ ] **Clothes button:** reads "Change into citizen clothes". [needs a person: One button's wording, a glance; no test found]
  Notes:
- [ ] **The errors file:** F4 > Factions > Admin: errors (N). A window opens with the list and it is on your clipboard; the same text is in the server's garrysmod/data/livingcity/errors.txt. Leave the server running with you on it for ten minutes, then send that file. "Sent it: start the list again" empties it (the old list stays as errors_previous.txt). [needs the real server: Leave the server running ten minutes, then send errors.txt (ErrorsFileTests has the rules)]
  Notes:
