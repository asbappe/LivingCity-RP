# Playtest checklist

Updated 1 November 2026. **Part 1** is everything new since your 1 November playtest: try those first. **Part 2** is older items (from 8 October on); skip any you've already checked.
Tick a box when you've tried it, and write what you saw after **Notes:** (works, broken, feels off, ideas).

# Part 1: new since your 1 November playtest

## Infestation Cleanup (fixed after your notes: try first)

Players now download both workshop packs when they join (the Alyx hazard props 2043900984, the Infestation Control workers 3185145650). The server needs them too: put both in its workshop collection. Anyone missing a model sees a stand-in, never an ERROR.

- [ ] **Growths:** Xen gunk with the pack (or a stand-in), glowing green, spores drifting up. Still any ERROR? Say where.
  Notes:
- [ ] **A warning post at each infestation's edge:** sign, lamp and a yellow infestation control barrel (cones and an oil drum without the pack). Found it? Standing sensibly?
  Notes:
- [ ] **Your own barrels:** the editor's "Fixture: infestation control barrel" (in the "by use" view: Job: Infestation Cleanup, and Infestation).
  Notes:
- [ ] **Take the job** (F3 > Jobs > Infestation Cleanup): weedkiller, a **sprayer** and a **hoover** in your weapons; own clothes until a shift.
  Notes:
- [ ] **Accept a shift:** the hazmat suit (a woman the female one, a man the male one). Hands nearer than before? If not right yet, try `lc_suit_hands "-6 0 0"` with other numbers (forward right up) and send me what looks right.
  Notes:
- [ ] **Guards:** two come; if one falls behind (stuck, lost) for a few seconds, they're back beside you; after a fight they come back; nobody free, a unit's sent. Do they stay with you now?
  Notes:
- [ ] **Spray:** sprayer out, hold left click on a glowing growth: green mist, a bar, it dies (dark, stays there). E still works too.
  Notes:
- [ ] **Vacuum:** hoover out, hold left click on a dead growth: a bar, gone, "Hoover: 1 of 3". **All three count now** (the job said "2 more" before: fixed).
  Notes:
- [ ] **Do you see the sprayer and the hoover** in first person, and in your hands in third person? Placement: `lc_sprayer_view "18 9 -10"`, `lc_hoover_view "26 11 -15"` (forward right up): send me numbers that look right.
  Notes:
- [ ] **Empty it:** the last step marks the nearest barrel; E on it. No barrel near: right click with the hoover bags it.
  Notes:
- [ ] **The geiger counter** at the edge of a zone: calmer now (40% fewer clicks, quieter)?
  Notes:
- [ ] **Clear every growth in a patch that grew:** the patch goes. Dead growths nobody collects rot after 10 minutes.
  Notes:
- [ ] **Joining Civil Protection:** a cleanup shift counts as two Intake Processor shifts.
  Notes:

## Also fixed from your notes

- [ ] **City Administrator:** C > Me > Run for City Administrator (8 hours played; staff: `lua_run` your hours up, or set `lc_admin_hours 0` to test). A vote window; win it: the tablet, two Elites at your side. Right click the tablet: the office (events, rations, prices, job bonus, commend, pardon, housing, permits). Left click at someone: the Elites kill them.
  Notes:
- [ ] **AFK:** idle 5 minutes: AFK under your name; 15: kicked (not staff).
  Notes:
- [ ] **The Man Inside, part 2:** the choice (transfer order, a fire, a false report): the guards go off to the fire or the report; the order mostly passes.
  Notes:
- [ ] **Guns lowered:** pistol out: pointing down, no crosshair; hold R raises it; click while down raises it; tap R reloads. Does the gun use Half-Life 2's lowered pose?
  Notes:
- [ ] **Wear and legacy:** lockpicks, fishing lines and weedkiller run out after a while; a title under your name after 3 lives; a ring with each new person.
  Notes:
- [ ] **Contraband found** in a street search: a FIGHT / COMPLY box, five seconds. Fight: you keep it, wanted. Comply or wait: taken.
  Notes:
- [ ] **Sleeping rebels** wake when you walk up as a unit. **Multitool:** unshackles street vortigaunts; hacks the CP Commissary; its text low on screen.
  Notes:
- [ ] **Street vortigaunts:** shackled, left alone by the Combine, sweeping when they stop. **Dead vortigaunts:** morticians collect them.
  Notes:
- [ ] **C menu on a citizen:** This person > Ask their name; on rebel ground, Bring them in (Resistance) / Tell them to leave.
  Notes:
- [ ] **Editor:** coloured ticks under used numbers on the number slider.
  Notes:
- [ ] **Cleanup:** one step, "Clear 3 growths": spray one and vacuum it, in any order; all three count. Guards are soldiers, and they kill zombies fast now. Warning posts by a path node at the edge. 
  Notes:
- [ ] **Prison:** two Nova Prospekt guards, tough; no metrocops or soldiers garrisoned there. A prisoner a job's about stays in until the job ends.
  Notes:
- [ ] **Turrets:** knocked over: E as a unit sets it upright where it stood; NPC units right ones they pass.
  Notes:
- [ ] **Firebomb:** a much wider fire. **Lab:** text wraps, no "Homemade", scientists' own voices. **Weeds:** easier to find, one marked on the shift. **Sweep cart:** on the floor.
  Notes:
- [ ] **Poison gas bomb / firebomb:** bought or made, it's on your Grenades weapon (R to pick it, left click throws). No Throw button in F2.
  Notes:
- [ ] **Units in doorways:** walk into one: it shuffles aside and steps clear.
  Notes:
- [ ] **Metrocop with no pistol:** E at the CP Commissary issues it again (or respawning does).
  Notes:
- [ ] **CP Commissary:** no civilian clothes, no fishing line, no cuffs for sale (a unit's own never run out); a Clean uniform (5) that puts right a soiled unit; poison gas only from Division Leader up.
  Notes:
- [ ] **Terminal screens** just below eye level; Next page and Close light up when aimed at.
  Notes:
- [ ] **The "Request device"** is now the "Civil Protection call box" everywhere.
  Notes:
- [ ] **Clinic Medic:** own citizen clothes, no rebel medic outfit, no welding helmet.
  Notes:
- [ ] **Job items** (6-12's belongings, evidence, anything to find): never under stairs or in walled-off space; always somewhere you can walk up to.
  Notes:
- [ ] **Sleeping citizens:** lying flat on the bed, eyes shut, not sitting up through it. Heads at the pillow end? (If at the foot: `lc_bed_head_flip 1`.) Too high or sunk in? `lc_bed_npc_lift` (9). Shoot one: they wake.
  Notes:
- [ ] **Career paths on F3:** jobs grouped (Civil Protection path: Intake Processor, Infestation Cleanup; Administration path: Records Clerk, Block Warden; Union work). F4's Civil Protection bar counts Intake Processor shifts.
  Notes:
- [ ] **Block Warden:** not listed below 100 standing; listed and takeable at 100.
  Notes:
- [ ] **Join Civil Protection:** you spawn in a Combine zone, not the train station.
  Notes:
- [ ] **The radio transmitter** (CP and Freq 7) is well up in view now. Adjust: `lc_radio_view "20 9 -3"`.
  Notes:
- [ ] **Metrocop hands:** fists (or any weapon with hands) as a metrocop: your own sleeves and gloves now, not the soldier's. Anything odd (bits of body floating in view, stretched shapes)? If it's bad, `lc_cp_hands ""` puts Garry's Mod's back.
  Notes:
- [ ] **Records Clerk filing:** the instructions at the top make sense? The register shows a status now; anything different (name, number, status) is a Discrepancy; after each form it says right or wrong and why. The blank form button is red and says it's a crime.
  Notes:
- [ ] **F4:** a header for each faction; click to open its ranks and roles. Free Vortigaunt and Overwatch Commander no longer cut off. No Stalker on it.
  Notes:
- [ ] **Joining the Resistance:** you start as a Member at most, in your own clothes, whatever your XP: do 3 jobs from their board and they trust you (Fighter: the gear and the guns). F4 shows how many.
  Notes:
- [ ] **Boiling water at a burning barrel:** works now? (If not, tell me what the barrel is: a map prop, or the editor's "Fixture: fire".)
  Notes:
- [ ] **Rain** no longer fills bottles or cans.
  Notes:
- [ ] **Sociostability** when it changes: the chat line says why (curfew, a sweep, lockdown, infected loose in the city...). Headcrabs inside an infestation shouldn't change it. If it still drops for no good reason, send me that line.
  Notes:

## Weedkiller as a weapon, and the Combine's gas

- [ ] **Firebomb** (the Resistance lab: 2 weedkiller, an empty bottle, a rag): a burning bottle; it breaks where it lands and burns a while; units in it burn, armour or not; a power bank, forcefield or turret next to it goes down; a growth in it burns away.
  Notes:
- [ ] **Barnacle:** drop weedkiller under one (F2 > Drop): it pulls it up, crunches, dies.
  Notes:
- [ ] **Poison gas bomb** (units only now: the CP Commissary, 40): thrown, a green cloud; citizens choke, units not at all.
  Notes:
- [ ] **A sweep into rebel ground** sometimes opens with a gas bomb; the units walk into it unharmed.
  Notes:
- [ ] **As an Insider,** at the Commissary with weedkiller: Foul the filters, then gas hurts units too (and they're told their filter's no good). Spike the food: other units are poisoned over the next few minutes.
  Notes:
- [ ] **Poison:** F2 > Weedkiller > Poison food or drink: the food looks the same; give it to someone, they're poisoned when they eat it. A unit watching: wanted.
  Notes:

## Weeds and the Groundskeeper

- [ ] **Weeds** come up on open ground and grow (a tuft, weeds, a bush). Which plant shows? (An ERROR model: say so.)
  Notes:
- [ ] **Groundskeeper** (F3 > Jobs): issued weedkiller; E on a weed sprays it; the shift is three weeds. NPC groundskeepers spray them too.
  Notes:

## Rations

- [ ] **A new character:** registering at Civil Intake gives papers but no ration card; a dispenser says "No ration card" and tells you to work a shift.
  Notes:
- [ ] **Finish a Union shift:** "[Rations] You earned a ration card" on screen; F2 shows the card (and how many).
  Notes:
- [ ] **Take a ration:** the dispenser takes one card, and no credits come with it (standing still goes up by 1).
  Notes:
- [ ] **Civil Intake's record screen and your papers** show how many ration cards you have; there's no "Replace my ration card" button any more.
  Notes:
- [ ] **Hungry with no card:** What now? says to work a shift for a ration card.
  Notes:
- [ ] **Short rations:** below 150 standing the dispenser gives a short ration (and says so); at 150+ the full packet.
  Notes:

## Fixes from your 1 November playtest

- [ ] **Infestations:** citizens, units and rebels walk round them, never through.
  Notes:
- [ ] **Rebels on your beds:** at night, rebels lie down on the beds you placed in their camp.
  Notes:
- [ ] **A sweep:** units arrest the lab scientist, smash the pots (the plant gone, a breaking sound) and empty the supply crates.
  Notes:
- [ ] **Rebels at home** go down in about half the shots; your squad as before. Rebels: SMGs and shotguns only. Combine soldiers: pulse rifles and shotguns only.
  Notes:
- [ ] **Triage:** three or four patients going downhill plus one stable (a broken arm stays put); a gunshot wound drops fast.
  Notes:
- [ ] **Top left:** credits, standing, and loyalty, sympathy, corruption.
  Notes:
- [ ] **Medic to another job:** the medkit is gone.
  Notes:
- [ ] **A placed bin:** stand next to it, F2: the bin's section is there.
  Notes:
- [ ] **The jog:** units say "Move it!"; finishing says what you earned (standing and 5 credits); skipping shows a reprimand and the next ration is withheld.
  Notes:

## Terminals on their own screens

- [ ] **Civil Intake / Housing Allocation:** E shows the menu on a screen in front of the terminal; the button under your crosshair lights up; E presses it. Is the screen in a good spot (not inside the terminal, readable, not upside down or mirrored)?
  Notes:
- [ ] **CP Commissary (as a unit):** the counter's goods on its screen; buying works.
  Notes:
- [ ] **C > Settings > Terminals' menus:** switch to a window and back.
  Notes:

## The Resistance Insider, the loyalty test, and more

- [ ] **Recruited:** as a kind unit, The Man Inside on F3; stay inside at the crossroads.
  Notes:
- [ ] **C > Civil Protection > Inside** appears (and only for you). Each action refuses with someone nearby, works alone.
  Notes:
- [ ] **Tip off Freq 7:** a Resistance player hears "A friend inside: ...".
  Notes:
- [ ] **Lose a record:** a wanted player isn't wanted; your standing drops 25.
  Notes:
- [ ] **At the Commissary:** bandages and pistol rounds you can give away. **Copy the records:** the quartermaster pays 60.
  Notes:
- [ ] **Reveal myself:** the person you look at is told.
  Notes:
- [ ] **Caught in the Mole Hunt:** Resistance, wanted, no surrendering; Civil Protection and Union jobs refused.
  Notes:
- [ ] **The loyalty test** (suspicion 3 as an Insider): the cell, the prisoner, fists only, two shotgun guards beside you. Beat him, kill him: weapons back. Refuse or walk out: shot down, bleeding, then made a stalker.
  Notes:
- [ ] **The reckoning** starts by itself after it (no choosing it): pay the debt (starts at once) and the Inside menu comes back; take off the mask (Resistance, never a unit again); or done with the Resistance (the forced soldier conversion).
  Notes:
- [ ] **The stalker's end:** the frame is built beside a power transformer; once charged, an arc jumps the gap; walking into it kills at once.
  Notes:
- [ ] **Joining Civil Protection:** refused until 5 Intake Processor shifts (and 100 standing), and told so; F4 shows both as progress bars.
  Notes:
- [ ] **The loyalty test with a Resistance player online:** the Insider waits; units near the Resistance player keep stopping them; once the rebel's in a cell, both are put in the scene, with the on-screen prompts.
  Notes:
- [ ] **Done with the Resistance:** Proof (a sweep, two of their fighters down), then the conversion.
  Notes:
- [ ] **No Union radio**: radios are Freq 7 radios (black market); the lab's transmitter needs one.
  Notes:
- [ ] **Shackled vortigaunts** sweeping the streets (2); as Resistance, cut one loose (look at it, unshackle): it walks to rebel ground and stays. Playing a vortigaunt: no fists. If there's still no freed one in rebel ground, send the debug report's "vortigaunts" line.
  Notes:
- [ ] **Secret endings** three hours apart.
  Notes:
- [ ] **She, not he:** a job about a woman (a patient, a neighbour, a prisoner) says her.
  Notes:

## What loyalty earns

- [ ] **At 150+ standing:** fewer stops, shifts pay a bit more, the Commissary is cheaper, and lockers open (refused below 150).
  Notes:
- [ ] **At 400+:** stops are a papers glance; two ration cards a shift; waved through once a curfew; a curfew slip is a warning; the Administrator names you on screen now and then; MODEL CITIZEN on your papers; Block Warden on F3 > Jobs (refused below 400).
  Notes:

## Vortigaunts, and rent

- [ ] **As a shackled vortigaunt:** C > Reach out through the vortessence: Resistance players and free vortigaunts are told where you are; with a unit watching, the collar bites. The Collar on F3: sweep, the crate, the quiet corner.
  Notes:
- [ ] **As a free vortigaunt:** right click another vortigaunt: a second's glow, then +25 health (not again for 10 seconds, by anyone). A freed NPC vortigaunt walks over and mends you when you're hurt. Left click a power bank, forcefield or turret from a distance: it goes down for 45 seconds, then comes back. Free your kin (a street vortigaunt, marked) and Read the Combine (watch a checkpoint, get intel) on the Resistance's board.
  Notes:
- [ ] **Freed vortigaunts in rebel ground** walk about the camp and the fire; free a street one and the two talk in their own tongue now and then.
  Notes:
- [ ] **The hive mind:** with two free vortigaunts about, within 15 minutes a Freq 7 line about a sweep, or a door code on a scrap by them; the code opens a Combine door once.
  Notes:
- [ ] **Rent:** 50 credits for an ordinary citizen; as a unit, or a citizen with 200+ standing, nothing (the question says so).
  Notes:

## Beds

- [ ] **Citizens at curfew or night** walk into the habitation blocks and lie down on the beds you placed, asleep (eyes shut), and get up in the morning. Heads at the foot end? `lc_bed_head_flip 1`.
  Notes:
- [ ] **You in a bed:** E on it at night: you lie on it, others see you lying there, your view is from the pillow. Jump: back beside the bed.
  Notes:

# Part 2: older items (from 8 October on)

## Knowing what to do

- [ ] **What now? (F1, slot 1):** always one next step (register, a room, your block, eat, drink, a job, a shift), and Places with waypoints (dispenser, water, bins, home, work, Commissary, toilet, bath, bed).
  Notes:
- [ ] **Ways to get by (F1 > What now? > Ways to get by, or !ways):** everything you could do right now, what's missing, and a "Show me" button.
  Notes:

## Jobs you actually do (mini-games)

- [ ] **Sanitation:** street sweep with a cart.
  Notes:
- [ ] **Factory:** the conveyor line (bin the rust-red parts, pocket the rattling one).
  Notes:
- [ ] **Intake Processor:** the papers check.
  Notes:
- [ ] **Maintenance:** rewiring panels.
  Notes:
- [ ] **Clinic Medic:** triage.
  Notes:
- [ ] **Reclamation:** breaking rubble.
  Notes:
- [ ] **Courier:** parcel runs.
  Notes:
- [ ] **Mortician** (renamed from Mortuary Attendant): searching the dead, and the Headcrab collection shift.
  Notes:
- [ ] **Records Clerk:** filing.
  Notes:
- [ ] **Laundry:** sorting uniforms.
  Notes:
- [ ] **Radio Repair:** find the station on the dial, then set the three screws by ear.
  Notes:
- [ ] **Resistance:** the terminal hack, and dead drops.
  Notes:
- [ ] **Civil Protection:** pat-downs and breach raids.
  Notes:
- [ ] **Block raid you can see:** `lc_event raid`, go to the block it names: units are there within a minute, walk it stop by stop, and leave when it's over. A sweep (`lc_skirmish sweep`): the team really reaches rebel territory and fights.
  Notes:
- [ ] **Editor tool in hand (admin):** hunger and thirst stay put, and units don't stop, frisk or chase you.
  Notes:
- [ ] **Ration Production** (was Ration Kitchen): the sealing line, supply runs, the count against the register, forged ration cards at the counter.
  Notes:
- [ ] **Every job staffed:** the city's NPCs cover every job, more of them as the city grows.
  Notes:

## Radios

- [ ] **Listening to a radio:** the dial, static between stations, the Union station and Freq 7 (its frequency moves). Heard within about 20 feet, quieter further away. Listening to Freq 7 is a crime.
  Notes:

- [ ] **Freq 7, one station:** a voice line, then a song, back and forth; every radio on it hears the same thing. A warning cuts in before a sweep, raid, curfew or convoy (and for an incursion, a lockdown or a dropship).
  Notes:
- [ ] **Freq 7, the hunt:** it only ever sits on 100.6, 101.5, 102.4, 103.3, 104.2, 105.1 or 106.0. The Combine find it and jam it (a whine, units told), it goes dark, then comes back on another. A Resistance radio follows it; a Union radio has to search. A blackout stops the jamming.
  Notes:

## The city and the Combine

- [ ] **Data chips:** decoded only at the Resistance lab, by the scientist. The lab bench is Kleiner's now.
  Notes:
- [ ] **Forcefields:** take damage, recharge, break; a Maintenance crew (NPC or player) repairs them.
  Notes:
- [ ] **Power banks:** a forcefield needs one, and a bank powers only two things. HL2's forcefield texture.
  Notes:
- [ ] **Rain:** thinner, twice as many drops, fog only under open sky.
  Notes:
- [ ] **CP Commissary:** a separate counter for units; the Union Commissary doesn't sell to them.
  Notes:
- [ ] **Nova Prospekt:** soldiers near the prison wear the prison guard uniform.
  Notes:
- [ ] **Dropships:** the container stays in the claws, the door opens and soldiers jump out; on red alert the first one out is an Elite.
  Notes:
- [ ] **Surprise events:** only rations and curfew are announced two minutes ahead. Sweeps, raids and supply convoys come without warning (units still get their directive early; the Resistance hear a whisper on Freq 7). A lockdown only follows violence.
  Notes:
- [ ] **Alyx Combine models:** used automatically if the Workshop pack is installed (lc_combine_models_list shows what was found).
  Notes:

## Body and daily life

- [ ] **Toilets and parasites:** parasites mean toilet trips (they dehydrate you).
  Notes:
- [ ] **Soiling yourself:** a stain on the ground, clean clothes and a bath needed; you stink, flies follow you, people back away. Sanitation crews clean the stains.
  Notes:
- [ ] **Sleep:** beds, and sleep at night.
  Notes:
- [ ] **Tiredness:** skip a day's sleep and your eyelids droop, less health, no running.
  Notes:
- [ ] **Powered vests:** the VEST bar replaces SUIT; vortigaunts charge them.
  Notes:
- [ ] **Father Grigori:** an NPC in rebel territory with blessings and sermons; a player Grigori's shotgun holds 2 shells.
  Notes:

## Stalkers

- [ ] **Stalker playermodel:** worn by stalkers (Workshop 268895264).
  Notes:
- [ ] **Stalkers for life:** no way out but death.
  Notes:
- [ ] **The Stalker's Lot (F3):** ends at an energizer you build; step in (that person ends) or turn away (still a stalker; E twice on it later to step in).
  Notes:

## Civil Protection career

- [ ] **Ranks:** Recruit > Metrocop > Division Leader > Combine Prison Guard > Combine Soldier > Elite Soldier.
  Notes:
- [ ] **The conditioning:** the Overwatch ranks need it; the Overwatch Candidate story offers it to Division Leaders.
  Notes:
- [ ] **Overwatch Commander:** one at a time, calls in a dropship squad every 15 minutes (F1 > Unit tools).
  Notes:
- [ ] **Scanner Operator:** flies a scanner from a terminal; photos earn XP; rebels photographed become BOLOs.
  Notes:
- [ ] **Squads:** units hunting the same person stick together behind a leader, watch outward, call contact on the radio.
  Notes:

## The kick (G, or F1 > Kick)

- [ ] **Metrocop:** doors bang open fast; a locked door gives on the second kick.
  Notes:
- [ ] **Combine Soldier:** tips a hinged door off its hinges.
  Notes:
- [ ] **Elite:** sends the door flying 5 to 10 feet; whoever it hits is knocked out (never killed).
  Notes:
- [ ] **Breaking things:** kicks break crates and planks.
  Notes:
- [ ] **Brush doors:** sliding doors and shutters don't budge.
  Notes:
- [ ] **Rehanging:** a Maintenance Technician lifts the fallen door (E), carries it to its frame and presses E there.
  Notes:
- [ ] **The leg animation:** how it looks in first and third person (it may need tuning).
  Notes:

- [ ] **The Endings menu (C > Help > Endings menu, as superadmin):** opens with the ending playing already picked (or pick one and press Play it now). On The dance tab: pick a move and a bone on the body map; is the bone lit up yellow on the dancers, and does the close-up at the top show them (drag to turn round, wheel to zoom)? Do the three sliders turn the bone the way their labels say, live, on everyone (ask another player to watch), with the other side mirrored? Tick the stand-in with no ending playing: does someone do the move in front of you? Settings: do the sliders change the ending as it plays, and does "back to the default" work? Changes: does "Copy it all" give you a list to paste me? After a map change, is the tuning still there?
  Notes:

## Fixes from the 17 October playtest (what to check)

- [ ] **Warn the block:** in the block, residents come out to be warned (any wing of it); if the raid ends before you've warned three, it's not paid.
- [ ] **Changing jobs:** the old shift goes from your HUD and the new job's shifts can be taken.
- [ ] **The two voices:** the two-minute warnings and the "it's over" announcements: the Administrator waits till Overwatch has finished.
- [ ] **Curfew:** a unit that sees you out (even one at a post) warns you and comes over; three warnings and you're wanted.
- [ ] **Your apartment door:** E opens it, E again shuts it, locked again.
- [ ] **Pickpocketing / talking:** nobody ends up stuck inside you.
- [ ] **Arrested:** walked to the cells (a unit pausing on the way doesn't end the walk; only a long hold-up brings the van).
- [ ] **Sinks:** E on the map's sinks works again (and not through walls).
- [ ] **Ration line:** during a ration event people queue and move up to the dispenser. If not: copy the debug report and look at the "line" line (it says if the dispenser has no power, or the line was placed from the back).
- [ ] **Factory line:** every red part can be picked up with E; no part rolls off the belt. The loading dock run is the Intake Processor's now; the factory gets "Overtime on the line".
- [ ] **Carrying boxes:** citizens' hands stay on the box as they walk.
- [ ] **The bed fixture** is the bed with a mattress (Counter-Strike: Source's; HL2's if the server hasn't CS:S. Players without CS:S see an ERROR: tell me if that happens and I'll pick another). **The toilet** flushes after the splash. **Your fridge** at home opens your stash. The stash button no longer says searches don't reach it.
- [ ] **"Civil Protection unit"** everywhere players read "unit" (say if one reads oddly).
- [ ] **The sweep cart:** the smaller cart, the right way round, pushed up stairs, and it doesn't hurt you.
- [ ] **Debug report:** the "people who left" lines.
- [ ] **The editor:** "Arrange by what it's for" (each job, the rebels, the prison...), "Show the editor's markers", "See markers through walls".
- [ ] **Helmets:** a pack's battle helmet or welding mask only on rebels in the open.
- [ ] **Everyone works:** a new registered citizen is assigned a job (a notice says which); rebels aren't. The "What now?" line when you've nothing on is stern now.
- [ ] **Sneaking:** crouch: the bar at the bottom, the units' sight on the ground (red when you're in it), creeping behind a unit's back unseen, the dark helping. A supply drop raided crouched from behind the crates.
- [ ] **Vortigaunts:** one lives in rebel territory from the start (`lc_rebel_vorts`).
- [ ] **The body cart** (Mortician): F1 > Take a body cart by the incinerator; bodies let go beside it go on; push it; E on the incinerator burns them all.
  Notes:

## Fixes from the 17 October evening playtest (what to check)

- [ ] **Announcements:** only one voice for each thing (Overwatch or the Administrator, at random), never two at once (Half-Life 2's lines, your Overwatch and the Administrator wait for each other), fewer of them (the time of day, trains and skirmishes left out right after another), and no "new day" during a curfew.
- [ ] **Small things:** a running tap when you fill a bottle at a sink; Father Grigori quiet but for a line a minute; clinic medics without helmets; the HUD's left side never overlapping (the needs box, the line under it, the What now? card, then the rest).
- [ ] **Rebel territory:** fewer fighters in a small camp; nothing set down in a corridor or the sewer channel; fighters on dry ground first; sleepers lying on their mattresses with their eyes shut (if they still float or sink, `lc_rebel_bed_height`); hold E on a mattress, crate or chair to carry it and let go to set it down (R turns it); after a map change it's where you left it.
- [ ] **Prices:** the quartermaster's radio costs what the lab's does; a forged ration card is 10.
- [ ] **Stash:** at your stash, "On you: crowbar / pistol... Stash it", and Take to get it back (magazine and all).
- [ ] **The law:** run from a search: units and soldiers chase and cuff you, no shooting, unless you hurt someone or draw a gun. A curfew about you: the unit knows you (no warnings). A daytime curfew only with unrest, and it says so.
- [ ] **Sleep:** in bed you can't move; Jump gets you up; you heal as you sleep; the eyelids fade softly; tiredness kept over a restart.
- [ ] **Sneaking:** the sight shown in 3D (walls and a lid), visible from below a slope.
- [ ] **A squad:** C menu > Resistance > Squad: act casual (plain clothes, guns away: walk past units), guns out, and "meet me at the job's marker" (they go ahead and wait). Fired on while casual: guns out.
- [ ] **Free a vortigaunt:** it waits shackled and harmless; the choice to cut the shackles or walk it out shackled; a unit may stop you; any rebel territory counts; it no longer hops up and down ladders.
- [ ] **The labs:** Dr. Kleiner, Eli Vance and Dr. Magnusson, one at each.
- [ ] **Factory line:** every part grabbable, none spinning through or falling off the back; workers at the line facing the belt, quieter; nothing left clanking after.
- [ ] **Intake Processor** (was Station Porter): travelers walk up from the platform and away out of sight; the old woman's line reads right; the papers window gone when the shift's done; rations out mid-shift: Take a ration break.
- [ ] **Raids:** a minute and a half before the Resistance hit the Combine, a notice and "Back up the raid" on your board (F3), with a waypoint.
- [ ] **Sweeps (as Civil Protection or Overwatch):** a minute and a half before a sweep moves into rebel territory, a notice and "Join the sweep" on your board (F3), with a waypoint; when the Resistance raid the Combine, "Repel the attack" goes up at once.
- [ ] **Rewiring (Maintenance):** the board of circuit tiles: click turns a tile, right-click turns it back; the current lights up as far as it gets; a sparking tile bites; beat par for a bonus. Hard enough now?
  Notes:

## Fixes from the 20 October playtest (what to check)

- [ ] **Announcements:** never two voices over each other (Overwatch's own lines, your recordings, the Administrator).
- [ ] **Spawning:** put back where you left off with someone standing there: you're moved beside them, not stuck.
- [ ] **Rebel camp:** hold E on a mattress or crate, look down at your feet while carrying it, let go: pick it up again (it never sinks into the floor).
- [ ] **One territory:** rebel zones that touch are one camp: one quartermaster, one supply crate, one fire. A quartermaster left from a deleted zone is gone.
- [ ] **Rebels standing:** fighters stand up straight when there's nothing to crouch for (if you still see bent legs, tell me where and what they were doing).
- [ ] **The quartermaster's words** show under his window, not behind it.
- [ ] **Food at the quartermaster:** beans and rations sell for 2 at most.
- [ ] **The vest:** sleeping doesn't charge it. Charge cells (the lab makes them; dead units and downed scanners drop them) do, and a freed vortigaunt does when you press E on it.
- [ ] **Hacker:** F4 says a role sits on top of your rank (still a Fighter, its XP, the role's kit); the HUD shows "Hacker (Fighter)".
- [ ] **A new face** (the lab, 300 credits): wake with another face, not wanted, standing up to -50.
- [ ] **The corner of the screen** with a rank (Resistance, Civil Protection...): faction and rank, credits, standing, WANTED.
- [ ] **Losing them:** wanted, out of every unit's sight 30 seconds: step out and only a unit who sees you comes.
- [ ] **Cuffed only when subdued:** three blows of the baton (dazed between), or standing still for them; never in noclip.
- [ ] **Walked to the cells:** doors stay open for you; the unit leading you down, another takes your arm; a unit alone is joined by another; timed out: "struck from behind ... you come to in a cell" (no van).
- [ ] **Stalkers:** only a rebel who has killed (or is in for murder). The cell door, the blows, black, machinery, waking as one. Then: no talking (E), no hunger or tiredness, nothing in your pockets, your board only the Stalker's Lot, no F4, no !characters.
- [ ] **The tired eyelids** shut all the way.
- [ ] **Father Grigori** moves between camps now and then when nobody's about.
- [ ] **The jog:** the pace marker green while you keep up, red when behind; the city's joggers keep up; fall behind and a unit comes; joining late counts.
- [ ] **Radio repair:** two minutes a set (counting down), a moment between sets (fixed, or out of time), screws turned round and round.
- [ ] **Supply drop:** one soldier turning to look about (warns you off twice, then wanted), two metrocops carrying boxes off down the street and back; prying a load is quiet, but a unit seeing you at it stops you.
- [ ] **The courier's clipboard** the right way up (if not: `lc_clipboard_angle`, pitch yaw roll).
- [ ] **Job outfits** button in the editor opens the window.
- [ ] **Rainwater** drinkable as it is.
- [ ] **Endings menu:** "Changes" lists only what you changed; Bloom's hands right on people, and "The dance, on the Combine's units only" to tune theirs.
- [ ] **Shalom twice as loud, the Harpies twice as loud again; the Harpies' title on screen is THEY RETURN.**
  Notes:

## The Resistance's money (what to check)

- [ ] **Intel:** F1 > Resistance > Write down what you see, near a checkpoint, a unit or the Combine's ground (with paper): notes the quartermaster buys (20 to 35). A unit seeing you takes the paper.
- [ ] **Skimming:** on the factory line, R while holding a good part: Union machine parts in your coat (dealer 8, quartermaster 12). Take several and the foreman may find the count short.
- [ ] **Forged cards:** the lab makes five at a time. Sell enough (or use them) and a sweep comes for the camp nearest the lab.
  Notes:

## Fixes from the 21 October playtest (what to check)

- [ ] **Stalker scream:** half as loud. The job text no longer says their mouths are sewn shut.
- [ ] **Stalker spawn:** wakes in the Combine's ground (a Combine-only zone), never at the station.
- [ ] **Stalkers left alone:** no "restricted area" in the Combine's ground; no unit warns, searches, beats, books or tells it to pick up a can; contraband on it doesn't matter.
- [ ] **Stalker papers:** a red STALKER stamp across them.
- [ ] **Stalker jobs:** a technician walks up and fits the harness; the floors are a push broom and patches of grime (E each); cable is the rewiring board at two power banks; the frame is four cells to carry in and four seams to weld; the charge is the board again.
- [ ] **Scanner far from its console:** the NPCs around it walk normally (no hopping or floating); the camera doesn't keep tipping up or rolling.
- [ ] **Combine HQ:** mostly soldiers; metrocops on their beat don't wander in.
- [ ] **Infested:** the Zombie and Zombine are no faster than a citizen; no picking up or holding guns; joining from F4 puts you in a nest; your kills don't make you wanted or bring announcements.
- [ ] **The jog:** the city's joggers keep to lanes and don't circle round each other; miss the start, then join the route anywhere: your own marker, and time to finish.
- [ ] **Radio repair:** "Write it down" on Freq 7 leaves the dial where it was and gives a Freq 7 sheet (Read it from your pockets: the seven frequencies; contraband).
- [ ] **Radio repair NPCs:** put the work points on a table or bench: a radio sits there and the repairer stands at it working (nothing in their hands).
  Notes:

## Safeguards (29 October: what to check)

- [ ] **Nothing normal is held back:** play as usual (menus, the radio dial, the rewiring board, shops, chat): nothing ignored, no "Slow down" unless you really type fast.
- [ ] **Chat:** seven lines in a row as fast as you can: "Slow down" on the seventh.
- [ ] **Dropping things:** drop more than 30 things from your pockets: the oldest on the ground disappears.
- [ ] **Tickets:** two `@` messages in a row: the second asks you to wait a moment.
- [ ] **Rent:** an apartment door says 15 credits.
- [ ] **Lab prices:** nothing at the lab is cheaper than the quartermaster pays for it (gun parts 13, not 11).
- [ ] **Cuffs** (once zip ties) sell for 1 at the black market; every menu and message says cuffs; `!cuff` works.
- [ ] **Couriers:** a parcel run opens with the sender's window: take it, hand it back, report (only when they won't say or own up), or open it (standing down, 1 credit a delivery instead of 3). A sender who owns up pays 8 extra when it's delivered.
- [ ] **Smuggler** (Resistance, F4): smuggling runs on the board (F3), from the quartermaster to three drops; pays far better.
- [ ] **Radio transmitter:** a radio alone only listens (`!r` says so); nobody transmits on the Union band. Units, and anyone with a Freq 7 radio and a radio transmitter (black market or lab): a Radio transmitter next to Hands. A unit with both: right click switches between the CP net and Freq 7. Switch to it: what you type and say goes over the band (others on it read and hear you anywhere; someone right beside you hears you; nobody else). R or switching away puts it down. A soft static hiss plays (just for you) while it's up.
- [ ] **Freq 7:** no music: a voice line, then static for a couple of minutes; warnings still cut in.
- [ ] **Healing:** no mending on your own while awake (even well fed); eating food mends a little; sleeping in a bed, medkits, bandages, the clinic still heal.
- [ ] **Your apartment door, locked:** E rattles the handle, even for you; right click with your hands out (or !unlock) to unlock it.
- [ ] **Ration line:** the person at the front walks up to the dispenser, takes the ration, and steps away.
- [ ] **Rain:** blood and marks on open ground near you fade while it rains; graffiti stays.
- [ ] **Hacking** a vending machine or ration dispenser: a handful (5 to 8) comes out, not 3.
- [ ] **A unit's issued grenades:** can't be sold, dropped, stashed or given to a citizen; can be given to another unit.
- [ ] **BOLOs:** a second one straight away says to wait.
- [ ] **Wanted:** the character form won't take a new name or face.
  Notes:

## Morning exercise and more (from the other session)

- [ ] **Morning exercise:** every second dawn, the jog (keep up with the pace marker), the drill (copy the leader on your ring, then the skipping rope) or the parade (cheer the column). Needs its editor points: jogging route, exercise yard, parade route.
  Notes:
- [ ] **A full stomach:** hunger 85+ gives 15% more XP and slow healing.
  Notes:
- [ ] **The Harpies (lc_ending harpies now):** lights out, everyone at the LZ, mingebags gathering in the dark, the rush at the swell, the leaping, spectating the dead. Does the timing line up with the song? Does the pose look right? Citizens and other NPCs (no rebels) in the ring between you and the Combine? The Combine chattering out loud, opening fire as they leap, and actually dropping some? No "pick up that can"? The mingebags stay outside the ring until they leap; the Combine open fire 3 seconds before; they go for the Combine first, you have about 30 seconds to run, then it gets brutal; spawned citizens stand normally (no T pose). The song loud enough (lc_ending_song_volume); the citizens standing normally (not arms out).
  Notes:
- [ ] **Bloom (lc_ending bloom now):** everyone dancing (NPCs too), the camera circling you, the coloured lights and sparkles, the speed-up at 2:01, the launches one at a time. Does the dance look right? (lc_bloom_preview to check it on yourself; lc_bloom_pose_print to send me the numbers.) Everyone at the landing zone with the Combine round them; hands clear of the head (higher still for the Combine's helmets); the body swaying in a curve from the waist with the feet on the floor (nobody hovering), the knees dipping in turn, palms facing forward (if they face back, `lc_bloom_palm -90`) and hands flapping at the wrist like ears; the burst when each dancer spins up is a big flash and confetti everyone can see, and only a soft pink tint on your own screen; no city music over the song (in any ending); no inspections, wanted notices or lost standing during any ending.
  Notes:
- [ ] **Marrow (lc_ending marrow now):** skeletons dancing their way in, the drops (everyone dancing, the Combine's units too, strobes), the attacks in between, turning into a skeleton, the outro. Do the sections line up with the song? Doors locked open? More and more skeletons (15 at first, 80 by two thirds through); the kicks in the dance; the Combine shooting them in the fights; you can always outrun one, but the crowd gets everyone by the last fight. Skeletons in sight from the very start; purple and orange spotlights sweeping in the dances; the song loud enough over the fights; the Combine not mowing them down too easily.
  Notes:
- [ ] **The Bus (lc_ending bus now):** the bus driving about, everyone seated on the drop, the rainbow trail, the rings popping, the speed on the beat, the landing at 2:29 and the faster take-off. How does the seated pose look? It roams the open air from one far-off spot to the next (never circling one spot, never up into the sky); on the ground it still drives through anything. The light rig on the roof: spotlights sweeping every colour, strobes on the beat, the underglow.
  Notes:
- [ ] **The Flood (lc_ending water now):** the stage at the LZ, the storm, the water rising, the waves knocking people off, swimming back, the ichthyosaurs, drowning, Father Grigori on the mic, headbanging the heavy parts and dancing the rest,, and going last. Does the water surface look like water? Does the headbang nod the right way (lc_headbang_angle)? The stage's deck above the water, rising smoothly with you on it (no getting stuck, no jerking up); Father Grigori there even when an admin starts it; a crowd headbanging with him, swept off by the big waves. Grigori's whole upper body banging on the beat (lc_headbang_angle "0 0 -30" if it's backwards); the swept crowd floundering under the surface (not through the ground) and eaten; holding Jump at the edge climbs you back on; jump to fly free once you're out.
  Notes:
- [ ] **Base (lc_ending base now):** the subtitles lining up with the spoken lines (move them with lc_ending_base_lines), the bombs, CATS in the sky, the ZIG fleet, the explosions, the white, Engrish chat. Every subtitle on its line, "What !" included (each was a line late before), not drifting behind; the fleet never up in the sky; lots of bombs (the debug report's log says how many were set up); the fleet in open sky.
  Notes:
- [ ] **Hard (lc_ending hard now):** everyone at the LZ doing the mirror-flip dance, PARTY HARD everywhere, the strobe, the freeze at the break, people passing out one at a time. The Combine going for it all through (crowd surfs, spins, backflips with confetti), two or three at once.
  Notes:
- [ ] **The Shalom song:** upload shalom1.mp3 (delete the old shalom.mp3), FastDL sync, change the map, reconnect, then `lc_sound_check`: it lists each ending song and says "plays" or why not.
  Notes:
- [ ] **Everyday fixes:** citizens delivering boxes or crates carry them out in front in both hands (not swinging from one hand like a suitcase); switching faction from F4 keeps you where you are; if Civil Protection or citizens stop turning up, a superadmin gets an "NPC cap" notice (`lc_npc_budget` was 10 on the server: set it back to 60).
  Notes:
- [ ] **Pose Recorder (the separate addon, pose_recorder.zip):** Tools, Poser, Pose Recorder. Spawn a mannequin from the panel: is it your model, standing, limbs frozen? Pose an arm with the physgun, right click: "Keyframe 1". Pose it differently, right click again. Reload: does the blue ghost beside it play the loop, and do its poses match the mannequin's exactly (that's the test of the maths)? Try "Record / stop" while moving a limb. Copy, and paste the result to me; Save and Load. Then pose a real dance (Bloom's, Grigori's headbang, the hora) and send it over.
  Notes:
- [ ] **Fixes from the last playtest (bone axes worked out from what you saw: tell me which still look wrong):**
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
- [ ] **Shalom (lc_ending shalom now; the song is shalom.mp3):** the flags running up their poles one after another on the intro's hit, and waving (the star and stripes the right way up); the hanukkiah in the middle facing you wherever you stand, the shamash lit from the start and a candle lit each phrase (with a little whoosh), all eight by the key change. Do the kippahs sit on top of every head, a little towards the back (each player can move them with `lc_shalom_kippah "6.5 0 -1"`: forward right up)? Are the Hebrew sayings readable and the right way round (right to left), on your Linux machine and on Windows? Do the arms look like they're on the neighbours' shoulders (tune with `lc_shalom_pose R_UpperArm -30 -75 0` and so on, then `lc_shalom_pose_print` to send me the numbers)? Does the grapevine step look right (if a leg goes the wrong way, say which)? The rings walking round smoothly, opposite ways; the Combine dropping their guns and joining at 1:02; the chair lifts: the chair is now drawn right under the rider's hips (if it's too high or low, or faces the wrong way, `lc_shalom_chair "21 0"`: how far below the hips, and a turn); if the rider's legs don't look sat down, tune them live with `lc_shalom_pose chair R_Thigh 0 -85 0` (and L_Thigh, R_Calf, L_Calf) and send me `lc_shalom_pose_print`, or pose a sitting mannequin with the Pose Recorder and paste me the JSON; the rush into the middle and back on the breakdowns; the giant flag in the sky and the Star of David fireworks at 3:25; Am Yisrael chai, then Shalom at the end.
  Notes:
- [ ] **Fire (new; lc_ending fire now; put the song in garrysmod/sound/livingcity/endings/fire.mp3):** the sputtering and smoke through the intro; every behind lighting up at the drop (0:12), flames going out the back and down; the bent-over dance; the hops from 1:00; the liftoff at 1:41 and everyone flying round the ring, bodies flat out Superman style with the flames trailing behind (if anyone flies on their back or upright, open the Endings menu, pick Fire, the "fly" move, and turn the Pelvis); the camera behind you in the air; the rockets up and the fireworks at 2:27. Do the sections line up with the song?
  Notes:
- [ ] **Plane (lc_ending plane now):** everyone on the wings doing the webcam dance and mouthing the words, the webcam box in the corner, the captions, the barrel rolls, the fireworks, the climb into the clouds. Do the captions line up (lc_ending_plane_captions)? Do the wings look right? The plane (and the bus, and the ZIG fleet) stays in open sky, never through a building, and the camera never ends up in the void?
  Notes:
- [ ] **Standup (lc_ending standup now):** someone strung up every other beat, where the ropes go (overhead, walls, sky), the struggling and going limp, the view from the rope. Hanging still on the rope, not running in place; the white cone hats showing; and everyone limp before the song ends, even the last to go up. On the rope you can look about (the camera moves; your body's head doesn't turn after it); the white cone hats on everyone strung up (real props now); hanging in a standing pose, not arms out.
  Notes:
- [ ] **Flashing warning:** before an ending with strobes, the popup stays up 15 seconds (counting down) before keeping the flashing; Reduce flashing turns it off for you.
- [ ] **Running sway:** running looks like a grown-up's stride (about three steps a second), not a toddler's bounce; walking unchanged.
- [ ] **Secret endings:** the G-Man stops time and everyone votes (he's right in front of you whichever way you were looking, your view held on him, and the city's announcements stop); Father Grigori eating a master data core (Eat it in his pockets, or /eatchip) starts the flood (admins: lc_ending <id> now). Once you're out of an ending, left/right click watches someone else and jump flies free (in every ending). The G-Man moves: his idle, straightening his tie now and then, his mouth going as he speaks (each player sees their own, in front of them).
  Notes:

## Death and progression

- [ ] **Close calls:** three per person; you wake in the infirmary with empty pockets; a used one comes back with time.
  Notes:
- [ ] **Final deaths:** a stalker's death, the energizer, or retiring a character (!characters).
  Notes:
- [ ] **For life:** the Overwatch conditioning and being a stalker can't be undone.
  Notes:
- [ ] **Inheritance:** the next person gets 25% of the savings, up to 200.
  Notes:
- [ ] **Union levy:** anything over 2000 credits is taxed every half hour.
  Notes:
- [ ] **Legacy:** !characters shows your past lives.
  Notes:

## Looks

- [ ] **Black Mesa faces:** with the pack (534130993) on the server, about half the jobless NPCs wear its citizens and refugees (women in the women's models); the character creator also offers its citizen and refugee looks; no ERROR models.
- [ ] **Outfit designer:** editor panel > Job outfits (or !outfits). No job is dressed by default (the Clinic Medic is in their own clothes now).
  Notes:
- [ ] **Welcome announcement:** plays when an unregistered person joins (or a new character arrives), and not when someone already registered rejoins.
- [ ] **Sound files:** `lc_sound_check` (your console) counts the city's sounds on your computer and test-plays one; a sound you can't hear shows a "Sound missing" notice. `lc_announce_clips` shows no CAN'T PLAY lines (an MP3 renamed .wav, or a WAV that isn't 16-bit 44100 Hz), and a superadmin gets a notice on joining if there are any. MP3 announcements queue properly (the Administrator, then Overwatch, for the welcome).
- [ ] **Character creator:** installed citizen packs, face skins, clothes and accessories. On a dedicated server, a joining player downloads the Workshop citizen packs and sees no ERROR models.
  Notes:
- [ ] **Variety:** NPCs are slightly different heights, and citizen shirts have their own drab colours.
  Notes:

## Anything else you noticed

Notes:
