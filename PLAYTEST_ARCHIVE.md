# Playtest backlog (what still waits for a person)

Cut on 14 November 2026 from the old list of 964 items: everything ticked, proved by a test, replaced, or from before 7 November is gone. The whole old list is in git: `git show 7fc8b61:PLAYTEST_ARCHIVE.md`.
**The list to play from is the card, `PLAYTEST.md`.** What is on the card is not repeated here; when the card is ticked, the next one is cut from this file.
To add an item: `printf '%s\n' '- [ ] **Topic:** what to try. [needs a person: why]' >> PLAYTEST_ARCHIVE.md` (or `[needs the real server: why]`).

## A new character's first hour

- [ ] **A new face:** forty seconds of black screen, whirring and wet sounds, a clang, a ding. Too long, too short, too gross? [needs a person: feel]
- [ ] **The pamphlets:** the Civil Orientation pamphlet opens as a folded leaflet, the Resistance one is in a sloppy hand. Any text off the paper, hard to read, or wrong? [needs a person: reading them]

## Jobs

- [ ] **Housing block inspection:** the trail goes to a door of the block, the door stays shut until you set the charge or kick it in, the furniture stands on the floor inside. [needs a person: the real map's doors and rooms]
- [ ] **Company on a patrol:** on the night shift or a patrol job, a loiterer or somebody following you turns up within a few minutes. Too often, too rare, too easy to lose? [needs a person: feel]
- [ ] **Job board:** place "Fixture: job board" in the city, on rebel ground and on Combine ground. Do the lists show on it, and does E open your jobs? [needs a person: the lists on its glass]
- [ ] **Job steps that replaced standing about:** Address the citizens, The secret mass (do the three gather?), Leak the schedule, Dead drop, letters at the door; the needle game on Break them out and on a vortigaunt's jobs (is its wording odd for a vortigaunt?). [needs a person: watching them happen, and the wording]
- [ ] **Ambush the landing, and any kill counter:** if nobody comes out of the dropship, do soldiers appear within half a minute? Short of targets for 10 seconds brings more; nothing for 45 seconds pays you for what you did. [needs a person: no test yet, take the job]

## Civil Protection

- [ ] **Guns on rebel ground as a unit:** walk into rebel territory: no "LOWER YOUR WEAPON" prompt, and every gun fires, also after !build and after sleeping in their bed. [needs a person: no test yet, try it]
- [ ] **Backup when you are down:** bleeding out with units of your squad near: does one kneel by you and get you up? Called over the radio from far off, do they come in from out of sight? [needs a person: the kneel and the arrival on the real map]
- [ ] **Health vial at full health:** E on a vial on the ground puts it in your pockets; Load on an ammo box with full ammo is refused and the box kept. [needs a person: the vial pickup has no test]
- [ ] **The conditioning:** the Overwatch Candidate story on a Division Leader's board at 1200 XP: a soldier and a stalker wait, black screen, machines, and you are a Combine Prison Guard. [needs a person: the scene by eye]
- [ ] **Commissary screen:** no more shimmering lines? [needs a person: by eye]
- [ ] **Evidence locker:** place "Fixture: evidence locker". Does it stand right? As a unit E lists what was confiscated; as a citizen can you pick or pry it and take your things back? [needs a person: how it stands]
- [ ] **Interrogation:** F2 > Interrogate someone in a cell: three questions, baton, Done, the answers written underneath. Readable, and in the way of anything? [needs a person: the list on screen]
- [ ] **Gas masks and the gas:** in chlorine gas the mask goes on by itself with the visor edge and breathing; people without one cover the mouth, cough and run out. How does the mask sit on a face (`lc_gasmask_fit`)? [needs a person: the mask and the hand over the mouth]

## The Resistance

- [ ] **Firebomb:** the fire is 30% smaller. Better? [needs a person: feel]
- [ ] **Headcrab hunt:** take the meat to a different camp's supply crate: does it take it? [needs a person: no test yet, try it]
- [ ] **The lab scientist:** start something and walk off: does he keep at it, tell you when it is done, and hand it only to you? After a raid, no blood left on him or the bench? [needs a person: blood left behind, by eye]
- [ ] **A vortigaunt charging your vest:** E on a freed one: it turns, raises its hands, a green beam pulses to your chest for three seconds. Is there a charging animation? [needs a person: the animation and beam]
- [ ] **The medic:** one in each rebel territory; E on him when hurt. Does he stay put and patch up hurt rebels near him? [needs a person: watching him]
- [ ] **Operations:** as a Lieutenant, plan one straight from the F4 Operations board. Does the leader get the clipboard, how does it sit in the hand, do its boxes tick? [needs a person: the clipboard by eye]
- [ ] **The interrogation chair:** the lamp hangs over it, dark until someone sits; with prisoners in the cage the cell takes them to the chair one at a time by itself. Are the number key lists readable? [needs a person: the lamp, how they sit, watching it run]
- [ ] **The carved rat:** scar a burned informant: a crude red rat on the right cheek that moves with the head (`lc_ratscar_pos` moves it). [needs a person: where it sits on the face]
- [ ] **Way marks:** Miscount Editor > "Mark: Resistance arrow" (left, right, up, down) and "Mark: FREEDOM THIS WAY" on a wall: the right way, the right size, the lambda's orange, still there after a map change? [needs a person: by eye]
- [ ] **Cuffs, felt:** cuffed, F1 > Work at the cuffs (or Pick the cuffs with a lockpick): clicks and creaks, small jolts, the line changing. Clear enough without a bar? [needs a person: feel]

## The city and its people

- [ ] **The Cremator:** a greener flame with a glow; no burning sound left behind after it kills headcrabs; it comes for carcasses about 90 seconds on; at a barricade it gives up and goes elsewhere. [needs a person: the flame, the ear, its walking on the real map]
- [ ] **The infestation's edge:** zombies scattered round it, most near the middle; the warning sign, lamp and barrel beside the way in, none in a wall or floating. [needs a person: the real map]
- [ ] **Stalkers:** a body they drag hangs on a rope from the hand. [needs a person: the rope by eye]
- [ ] **Overwatch PA over an hour:** no two routine lines within 90 seconds of each other; "ration stores running low" at most once in 20 minutes. [needs a person: ear, over an hour]
- [ ] **The two boards:** place "Fixture: Civil Protection incident feed" and "Fixture: Resistance notice board": are the words on the glass and on the board's face, the right way up and readable? [needs a person: by eye]

## Fights

- [ ] **Rebels' damage:** 20% more against players. A threat now? Do the 1 in 10 with a crossbow really shoot it? [needs a person: feel]
- [ ] **Tougher Combine:** editor > "Desperate Combine: test it" at 100%: soldiers come from out of sight and throw frags, gas and flashbangs; an Elite fires energy balls; metrocops carry SMGs. Compare 20%. [needs a person: watching the squads]

## The Administrator, the collapse and the ending

- [ ] **Speeches:** with a speech crowd point placed, Give a speech: do the NPCs stand in rows facing the stand, does the podium look right? With nobody as Administrator she speaks at midday herself: are the pauses right, and does Colonel Cubbage answer at the camp? [needs a person: the crowd, the podium, the pacing]
- [ ] **Poster roll:** in your hands you see a sheet of paper; if it sits wrong try `lc_posters_view "20 0 -9"` and send numbers that look right. [needs a person: the sheet in your view]
- [ ] **The collapse to BLACK:** editor > The collapse > "collapse to BLACK now": the G-Man in front of you (nobody else sees him), then the curfew; as a rebel under open sky a ring on the ground, the whistle, the blast, one at a time. [needs a person: the scene and the shelling, by eye and ear]
- [ ] **Her last stand:** the purple bubble, the beam from each transformer, sparks, smoke and blasts as it breaks; manhacks, turrets, mines; the shield panels you can carry; the hums, zaps and clanks. [needs a person: watching the fight]
- [ ] **The harpies:** being carried off, turned, and the finale (killed, then rising as a mingebag as they run off). Does a slaughter seem to be coming, or is it too slow? [needs a person: feel]

## Dreams

- [ ] **The dreams' grounds:** after uploading `livingcity_content.zip` and a FastDL sync, test a few dreams from the editor (Freeze, Citizen; Dance Marathon; The Midnight Rally; Ravenholm): is each picture the right size underfoot, not stretched or tiny, and does the mood still fit? [needs a person: how it looks]
- [ ] **Start and finish of a dream:** a fade to black with a line about the day, the dream's name between black bars, "You made it through" at a win. [needs a person: by eye]
- [ ] **Dreams, less text:** no status cards, hints or sociostability pill in a dream; the goal line goes after 15 seconds (Tab shows it); one short wake line. [needs a person: what is on screen]
- [ ] **Dressed dreams:** the ring of props below the edge of each playable dream: does it look right, and is it out of the way? [needs a person: by eye]
- [ ] **Strange dreams:** warped sounds, music that lurches slow or fast, floating nonsense and faces: too much or not enough, and does the dream stay smooth? [needs a person: ear, and the frame rate]
- [ ] **Stand-ins:** with few players asleep, do the city's people in the dream keep near you, cower, cheer, wave and kneel, with no arm or head bent the wrong way? [needs a person: the poses]
- [ ] **A recorded dream test:** editor > Dreams: test one with "Record the test" ticked: play it, then zip the folder in `garrysmod/data/livingcity/dreamrec/` on your PC and send it. Does recording make the dream choppier? [needs the real server: a folder from your own PC]

## Staff tools

- [ ] **Performance debugger:** C > Help > Performance debugger (or the editor panel's last button): on for a few minutes on a busy server nothing breaks, the "What stands out" lines make sense, Copy report pastes both reports. [needs the real server: a busy server with other admin mods]
- [ ] **Save with the gamemode:** Q > Tools > Miscount > Save with the gamemode: left click a spawned prop, change map: is it back? Saved props glow green only while the tool is out. [needs a person: a real map change]

## Needs the real server

- [ ] **Pictures:** unzip `livingcity_content.zip` in `garrysmod/`, FastDL sync, change map, join from a clean client: the civil posters, the dream posters and the spray can's two new marks show their pictures, sharp enough to read. [needs the real server: uploads and FastDL]
- [ ] **Recordings:** run `lc_voice_missing` and `lc_hl2_lines` in the server console and bring back the output and `data/livingcity/hl2_lines.txt`. Songs for dreams go in `sound/livingcity/dreams/` as `<codeword>1.mp3`. [needs the real server: its console and files]
- [ ] **The director, free talk and her voice:** editor panel > "The director and free talk": paste the key, Save, Test. Then say something to a named citizen in chat: do they answer, in a voice right for the city? Compare the debug report's requests with the bill. [needs the real server: your key]
- [ ] **Files to bring back:** `data/livingcity/minds/` after a few hours, `data/livingcity/chronicle/` after a week, and a play study folder (`data/livingcity/study/` on your PC, after Stop and save). Does play feel heavier with the study on? [needs the real server: files only you can copy]
- [ ] **Guns over a restart:** draw a bought pistol and SMG, restart the server, rejoin: both are in your pockets to draw again. [needs the real server: a real restart]
- [ ] **Uneven sides:** with many Resistance players to few Combine: more patrols, a reaction squad about 15 seconds after a kill, a dropship squad at a checkpoint attack, the "Combine are desperate" notice; a rebel who reconnects within 7 minutes is still a rebel. [needs the real server: many real players or bots]
- [ ] **With a second player:** cuffing them brings up the list at the left; resisting arrest is felt, not a bar; a player in the chair gets three answers on the number keys; each sees the Colonel their own way; a second admin gets the "Report from NAME" card. [needs the real server: two players at once]
- [ ] **Her last stand on your layout:** re-place any transformer placed before 10 November (numbered 1, 2, 3); with several Resistance players on, does the server hold up with many manhacks? [needs the real server: your layout and real load]

## Added since the cut
- [ ] **Arriving (a new character, citizen):** walk out of the station. Do the cards and tips come one at a time, each readable, never piled up? [needs a person: pacing of the first minutes]
- [ ] **Talking to a citizen:** E on a citizen. Do the number keys work, are their words under the list, and does walking off close it? [needs a person: the feel of the talk window]
- [ ] **A first job:** a hold E job from F4 (Bin round, Graffiti removal, The count, a leaking pipe). Does the bar fill, and is the thing easy to find and aim at? [needs a person: aim and finding by eye]
- [ ] **Chevrons:** on the way to a job, any straight line of the trail through a wall? [needs the real server: the real map]
- [ ] **The announcer:** over 5 minutes, at most one of the map's own Overwatch lines, and none on top of a city announcement? [needs the real server: the recordings]
- [ ] **Searching:** stop a citizen and search them (baton, reload). Do the numbers check the spots, do found things show, does "Done searching: check their papers" work? [needs a person: the feel of the search]
- [ ] **Cuffed arms:** cuff a citizen. Arms behind the back, wrists together? [needs a person: the pose by eye]
- [ ] **Resupply scanner:** radio out, right click, Request resupply under open sky. Does the scanner come down over about three seconds, the crate twice as big? [needs a person: timing and size by eye]
- [ ] **Heartbeat:** below 35 health it starts; die and respawn. Silent? Any other sound still going? [needs a person: by ear]
- [ ] **Lowered gun (Resistance):** on rebel ground, does the gun tip down in your view when lowered, and come back up when raised? [needs a person: the view model by eye]
- [ ] **The Man Inside, part 2, on the real map:** as a unit, `lcq_startchain inside`, take part 1 from F4 and hear her out, then part 2. Is a prisoner marked in the cells? After E on them, do they follow you out and through the doors? Do the guards leave when you set the fire or call the false report? [needs a person: doors, guards and following only show on the real map]
- [ ] **The counter (Ration Production):** work kitchen shifts until "The counter" comes up. After the forged card, do citizens step up one at a time, and does the card window read well at a ration counter? [needs a person: how the card check looks and reads at the counter]
- [ ] **Rations:** Fill the city's ration stores once; a dispenser gives a ration; an hour later stores well above empty, no announcement after 18:00; send `lc_stock`. [needs a person: the server over an hour]
- [ ] **Asleep in the cells:** jailed with over five minutes left, F1 > Lie down and sleep: body on the floor or bed, a dream after about 20 seconds, wake in the cell? [needs a person: how it looks]
- [ ] **Ranks and the cage:** set yourself Lieutenant (F4 admin tools): career page, the cage opens, Hacker offered; prisoners inside the cage, none in the wall? [needs a person: on the map]
- [ ] **Rebel ground and the Colonel:** way marks as arrows within 20 seconds, pots on tables, the usual music, the Colonel stays put, mouths move on recorded lines? [needs a person: how it looks]
- [ ] **The 21 new dream posters (16 November):** find a few in the city (or look at the sheet sent in chat): does each picture read at a glance, and is any one wrong for its dream? [needs a person: how it looks]
- [ ] **Infestation per district:** leave an infestation alone until its block reads "badly infested" on F2 > The state of the city; does it turn up in the next block after about 20 minutes, and does a powered checkpoint stop it? [needs a person: the pace on the real map]
- [ ] **The tidied F1 and F2:** as a citizen, a unit, a rebel and the Administrator, does every F2 entry sit where you would look for it, and does F1 > What now? > The state of the city read well? [needs a person: whether it feels right]
- [ ] **Stand poses:** F1 > Pose > "Stand: pose 1" and "pose 2": what do they look like, so they can be named for it? [needs a person: to see them]
- [ ] **Testing alone:** F4 > Factions > Admin: testing tools > Testing alone: try the assassination test (her address, the job, the attempt) and the collapse with only you on. [needs a person: the real game]
- [ ] **F4 > Me and settings:** does the new tab read well, and do the settings buttons flip and show the new state? [needs a person: how it looks]
- [ ] **Headcrab shelling:** as superadmin, take a district for the Resistance (or stand in one), F4 > Admin testing tools > Testing alone > Shell a district now: in the open, do three canisters scream down out of the sky, land (not into a ceiling), pop open, hiss, smoke and let out headcrabs, and does the ground turn infested? In a tunnel district, does an empty canister crash on the nearest street and the headcrabs turn up below? If they fly in from below or sideways, say so (the angle is one number). [needs a person: how it looks and sounds in the real game]
- [ ] **The card table's deck and Twenty-one:** sit at a card table on rebel ground and deal a few hands of high card: do the cards show as pictures on four differently tinted suits, sharp enough to tell apart, and do the names fit under them? Then pick Twenty-one: are your fanned cards readable, is 20 seconds for Card or Stay right, and is it fun with the Resistance's own people? [needs a person: how it looks and feels]
