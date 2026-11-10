--[[
    Living City (gamemode, client)

    No spawn menu or context menu unless you're an admin in build mode, no
    Sandbox hints, and the full menu (C) opens a short guide to the city.
]]

include("shared.lua")
LC_LoadModules("client")

function GM:SpawnMenuOpen() return self:LCBuilder(LocalPlayer()) end
function GM:ContextMenuOpen() return self:LCBuilder(LocalPlayer()) end
function GM:SuppressHint() return true end

-- One camera (cl_livingcity_view.lua): whatever Sandbox makes of the view
-- (vehicles, weapons, drive), then the city's own touches on top of it.
function GM:CalcView(ply, origin, angles, fov, znear, zfar)
    local base = self.BaseClass and self.BaseClass.CalcView
    local view = base and base(self, ply, origin, angles, fov, znear, zfar) or nil
    if not istable(view) then view = { origin = origin, angles = angles, fov = fov, znear = znear, zfar = zfar } end
    if LC_CL and LC_CL.CalcView then view = LC_CL.CalcView(ply, view) or view end
    return view
end

local INK, ACCENT = Color(232, 226, 210), Color(230, 180, 90)

local GUIDE = {
    { "Keys", {
        "F1: the quick menu (what everyone can do)        F2: the same, for your side, rank and job",
        "F2 for a citizen: Me (find work, your rations, your home and rent, your Civil Standing), each marking the way. In a cell, F2 > My sentence says what you're in for and how long is left.",
        "Union work: Sanitation street sweep (push a cart, throw rubbish in), the Factory line (sort out rust-red parts), Intake Processor's papers check (review arrival's paperwork; approve, deny, or call CP Units to arrest).",
        "More: Maintenance rewires circuit boards (redirect a current; don't get shocked), Clinic Medics triage injured patients, Reclamation Crew breaks up rubble with a crowbar.",
        "More (2): Couriers run parcels against the clock, Mortuary processes the dead, Laundry sorts uniforms, Records Clerks file forms and catch mismatches, Radio Repair fixes a radio by ear (and sometimes finds Freq 7.)",
        "Some of the city's rarer moments have flashing lights and strobes: a warning is displayed with an opt-out, and lc_ending_calm 1 in the console stops the flashing for you.",
        "Got a radio? Open your pockets (F3) and press Listen on it. Turn the dial: 96.4 is the city's own station, and somewhere in the static is Freq 7, the Resistance's secret one. It plays out loud, so people near you hear it too, Civil Protection units included.",
        "Want to talk over the radio? A radio only listens. Units have a transmitter on the CP net; for Freq 7 you need a Freq 7 radio and a radio transmitter (contraband, from the black market or the Resistance lab). Then switch to the Radio transmitter (next to your Hands, like a weapon). While it's up, what you type and say goes out on your radio's band instead of to the people around you. Only someone standing right beside you hears it. Press R, or switch to your hands or a gun, to put it away.",
        "Freq 7 isn't one fixed frequency: the Resistance only broadcast on frequencies whose digits add up to seven. When the Combine find the current one they jam it, and the broadcast moves to another. A Resistance radio follows it automatically.",
        "At the Radio Repair bench, if you pick up Freq 7 you can choose Write it down: you get a Freq 7 sheet listing all seven frequencies, to read or give to someone. The sheet is contraband.",
        "Resistance operations: Doctor the records means getting into a terminal (stop the needle inside the marked band, and don't touch the panel while the scanner sweeps past). A dead drop means hiding a message without anyone seeing you. Civil Protection units pat citizens down one pocket at a time, and break down doors in housing block raids. If you close one of these minigame windows by accident, press E on the thing you were working on to bring it back.",
        "Lost? {gm_showhelp} > What now? always shows your next step and how to get there. What now? > Places marks useful spots on your screen (the ration dispenser, water, your housing block, your workplace).",
        "F3: your pockets (and your stash at home)        F4: Jobs (your job board: jobs, stories, Union employment), Career (rank and the way up) and Factions, as tabs",
        "C (when not in build mode): the full menu. Everything you can do, with this guide, your pockets, job board, factions and tips at the top.",
        "E on a person: talk to citizens, or report to Civil Protection units. E on an object: pick it up or use it.",
        "The city's named people have minds of their own: hunger, fear, grudges and friends. Push one too far and they may scream at a unit, turn informer, or side with the Resistance. Where the server has it switched on, say something in chat while looking at one close by and they answer you (what you say to them is read by an outside service).",
        "Sometimes, asleep, a man in a blue suit appears in your dreams and recites a riddle. They're about how the city could change. The City Administrator holds the same riddles, sealed.",
        "Running and jumping tire you: the bar low on the screen. Run it all out and you're out of breath, and can only walk until you get it back. A good night's sleep and a full stomach bring it back faster.",
        "Guns are contraband: a citizen seen by a unit with a gun in hand is wanted at once. On rebel ground everyone carries lowered (hold R): a gun kept up where the fighters can see you for ten seconds and they open fire. Recruits and metrocops carry lowered on the Combine's own ground too: the Overwatch don't trust them.",
        "Everything you can do is in the menus (Civil Protection units: C > Unit tools). Chat commands like !backup still work, but you never need them.",
        "Warnings and announcements appear on screen as well as in chat: people talking to you appear as subtitles, everything else as cards at the top. C > Settings turns the cards off.",
    } },
    { "Death, and close calls", {
        "Each character has three close calls. When you die, you use one up: you wake in the infirmary with your pockets emptied, and your character doesn't remember the fight, so don't go after whoever did it.",
        "A used close call comes back after a few hours of playing that character. If you die with no close calls left, that character is gone for good. !characters shows how many close calls you have left.",
        "When a character is gone for good, you come back as someone new, with a new name and citizen number, and only a little inherited from the old one.",
        "Some things are permanent for a character: the Overwatch conditioning, and being made a stalker. To be someone else, play another character or retire this one (!characters).",
        "The Union taxes hoarded credits: every half hour it takes a tenth of whatever you hold above 2000 credits. Spend them.",
        "When a character is gone for good, the screen goes dark and a card shows who they were: how long they lived, how many people knew their name, and what killed them.",
        "People who knew their name hear about the death a minute or two later (or the next time they're in the city).",
    } },
    { "Arriving: Civil Intake", {
        "In a city with Civil Intake, new characters arrive with nothing: no papers, no room, no ration card.",
        "Every new arrival is searched: a Civil Protection unit stands beside Civil Intake and Housing Allocation. Choose \"Show me how searches work\" to learn the pat-down (press R once to slip something into a spot already checked), then try being the searcher yourself. Contraband found on your first day is taken with a warning. Leave the station without registering and a unit cuffs you and walks you back to the terminal.",
        "Go to Civil Intake (the marker on your screen) and press E on the terminal to open the registration screen. Enter your name, your face and a description strangers will see, submit it, and stay next to the terminal while it processes you. Your identity papers go in your pockets (F3), and the screen sends you on to Housing Allocation.",
        "Terminals (Civil Intake, Housing Allocation, the Civil Protection Commissary) show their menu on a screen in front of them: aim your crosshair at a button and press E. Prefer a window? C > Settings > Terminals' menus.",
        "New here? After Civil Intake, go to Labor Assignment: the Union gives you a job there, and Housing Allocation only houses citizens with work. You stay on it for 30 minutes or 4 shifts, whichever comes first; then a Labor Assignment terminal can change it (Infestation Cleanup needs Civil Standing 25, Intake Processor 50). Jobs are only changed there, in person.",
        "Next, Housing Allocation: press E to open the housing register. Present your papers and apply for a block. Any block is approved at once and gives you the least crowded one; asking for a crowded block needs Civil Standing 50. Your way home is then marked on screen.",
        "Already housed? The same screen shows where you live and how you got it, marks your way home, and takes transfer requests (needs Civil Standing 25; once every half hour).",
        "Your identity papers are kept in your pockets (F3). Civil Protection units ask to see them (having none costs a little Civil Standing). Lost them? Civil Intake replaces them for 10 credits.",
        "Ration cards are earned, not handed out: each Union shift you finish gives you one, and each ration at a dispenser takes one. No work, no rations. Rations don't come with credits.",
        "To show your papers, look at someone and choose F1 > Show them my papers (or F3 > Identity papers > Show). They see your card and learn your name.",
        "Until you're registered: no rations (unless you have a forged ration card), no Union job, no Commissary, and Civil Protection units will ask for your papers. Stay unregistered too long and it becomes a crime.",
        "Each desk serves one person at a time, and new arrivals from the train queue too. F1 > My papers shows where you are in the process.",
    } },
    { "How the city looks and feels", {
        "Your eye level is a little lower than other characters', and your field of view is no wider than in Half-Life 2, so the city feels big around you.",
        "The camera sways a little as you walk and dips when you land. C > Settings > Camera sway turns it off, just for you.",
        "There's no score on screen: your credits and Civil Standing are at the top of your pockets (F3), and your rank and progress are on F4.",
        "Hunger and thirst appear at the top left once they get low, and briefly after you eat or drink.",
    } },
    { "Staying alive", {
        "Eat and drink. Ration dispensers and the ration line give you food; the Commissary (a terminal, or C > Getting by) sells everything else.",
        "Walk into water and press E to drink, but boil it first if you can (on a stove or fire, from F3). To use a sink, stand close and look right at it, with nothing in the way.",
        "Parasites (coughing, hunger, thirst) never go away on their own: antiparasitic tablets from a medic or the black market cure them.",
        "Parasites also mean you'll need the toilet (press E on one). Ignore it and you soil yourself: then you need a toilet, a wash (bathtub or shower) and clean clothes, or people back away from the smell.",
        "Sleep once a day: press E on a bed at night. Without sleep you get drowsy, can't run and are weaker. A good night's sleep leaves you well rested.",
        "You're warned about six and two minutes before you're exhausted; from the first warning a bed lets you sleep. Citizens get tired in the evening and at night.",
        "Shared dreams: if the server has a dream point, the secret endings come at night as a dream for everyone asleep in a bed, about a minute after the Administrator says good night. You wake in your bed with everything you had, exactly as it was. Nobody can opt out, and nobody wakes themselves until they're out of the dream (then F1 > Wake up from the dream, or /dream wake; the line at the top of the screen says when you can, and how long the dream can still last). A nightmare takes everyone asleep outside a Combine-only zone. Only a stimulant shot before bed (or, about one night in three, the lab's foil hat) keeps you out of one.",
        "Lights out: everyone (citizens, the Resistance, Civil Protection, the Administration) is due in bed at the good night (21:00), whatever they slept in the day. You're warned six and two minutes before; after it, out of bed, your eyes keep closing until you sleep. Stay in bed until the night's dream has gone by.",
        "Every dream has at least six dreamers: when fewer players are asleep, the city's own people dream it with you: they keep close to you, run from whatever hunts you, flinch when you lose a life, cheer when you win, and kneel to her in a propaganda dream. Fall asleep after the dream has begun and you join it, as long as it has 45 seconds or more to go. A stimulant shot keeps you up past lights out and you miss the dream, but only one: no second shot until you've slept and dreamt properly. No dream lasts more than five minutes.",
        "Asleep, hunger and thirst wait for you. An enemy's hit wakes you (dreaming, your body stays in your bed: an enemy's hit pulls you out); a friend's does nothing at all. Anyone in a rebel camp attacked by a unit (or arrested) wakes everyone asleep there. Woken by an attack, adrenaline keeps you going for ten minutes; then you're groggy for a minute (blurry, no stamina) and need rest.",
        "Civil Protection and the Administration are Enforcers in nightmares and propaganda dreams: nothing touches them, they can wake when they like, and their baton punishes dreamers who misbehave (they glow red; a life gone, 1 XP for the Enforcer). In Happy and Neutral dreams they dream like anyone.",
        "Civil Protection: most nights your board (F4) has a Night shift from dusk. Take it and there's no lights out for you that night, and a CP Commissary issues you a stimulant shot (once a night).",
        "Cigarettes, alcohol and stimulants (F3, the item's button). A cigarette steadies your nerves and dulls hunger; too many and you cough. Drink and you get drunk: it dulls pain, then the world sways, then you throw up (and one moonshine in five is a bad batch). A stimulant keeps you awake for fifteen minutes (no dream can take you), then you crash.",
        "Nightmare dreams you play: The Patrol Maze (pick up every token while giant officers hunt you), The Barrel Tower (climb to the top, and don't touch the barrels: they explode), The Crumbling Floor (keep moving or the floor gives way) and Freeze, Citizen (move only while the giant officer's back is turned). Out of lives, or won: wake up now, or watch the rest until it's over. Win and you wake Unbroken (a day the Combine can't get into your head) with a second wind, and maybe a Vortigaunt's help; lose every life and you're 30 health down until your next full night's sleep.",
        "Propaganda dreams: Kneel Before Her (kneel, crouching, and gaze up at her to fill your Devotion; never let her catch you standing in her gaze), Roses for Her (carry glowing roses to her feet, on your knees in her half of the hall), Mirror, Mirror (kneel and compliment her in chat; new words count double, insults cost a life), The Saviour (the dead come for you, unarmed, and they hurt: when someone is close to the end, she descends and her soldiers save you), The Loyalty Quiz (answer her questions in chat, in your own words: a small typo is forgiven; beware thoughtcrime, and mind your language; with fewer than four of you, some of the city's people stand in, and one of them may not be as loyal as he looks). Every life you lose, every insult to her or the Combine, costs loyalty points (Civil Standing) when you wake.",
        "More propaganda dreams: Record Harvest (carry glowing crates to the depot; crouch to throw away a green, spoiled one), The Stakhanov Shift (crouch again and again at a work station to beat the norm by 1400%), Careless Talk (four rounds of 30 seconds: listen for clues and crouch beside the one you think is the spy; everyone's pick is revealed together), The Newsreel (as the camera rolls, say the wave, salute or cheer it asks of you; everyone's take is shown at the cut), Two Minutes of Hate (jeer in chat; silence is noticed), The Mass Games (gold card: crouch, red: stand, at FLIP!), On-the-Spot Guidance (jump or say clap when she points), The Scrap Drive (fill the bins; never sell to the shady trader), Flowers for the Liberators (jump as a soldier passes you; stay off the road), Duck and Cover (when the siren wails and the Resistance's rocket goes up, crouch beside a table, two to a table), Ravenholm (the dead rise from the graves and a red Father Grigori rants; hold on until help comes, and if any vortigaunt freed from its shackles is alive in the city, you may see the truth).",
        "The Battle Line (a propaganda dream): you're handed a rifle behind her barricades; shoot the red rebels before they reach the line. Never fire on her soldiers or the APC: the manhacks come for you, and if they get you, you're a tiny unarmed rebel charging the line until the dream ends.",
        "Freed vortigaunts can break into propaganda dreams (the more freed and alive, the more often): purple vortigaunts in rings of light. Stand in their light to side with them (it costs Civil Standing, but the Resistance hears of it), or keep to her. If they win, her figure shatters and the dream ends.",
        "Strange dreams: The Cheese Dream (it starts in the dark, with two voices: gather the glowing cheese, jump onto the floating slabs, and keep out of the way of the rolling wheels; it gets colourful), Musical Chairs (walk round the chairs while the music plays; when it stops, crouch beside a free one), Wings (jump, then jump again in the air to flap, and fly through the golden rings) and It's Raining Melons (stand on a green glow to catch a melon; keep out from under a red one). Win one and you wake Unbroken; losing one costs nothing.",
        "More strange dreams: Hooves and All (Neutral: when Father Grigori's shot stops the black horse, run in and bite it with E; don't get trampled), The Main Event (box: punch with attack next to it, crouch when it winds up), The Exam (stuck at your desk: type A, B, C or D in chat; the right answer is whatever most of the class picks, and you only learn your score once Doctor Kleiner has eaten your paper), The Last Train (the door moves away while anyone looks at it: walk backwards), Where's Lamarr? (catch the hopping headcrabs; the golden one counts three), Running in Molasses (reach the glowing corners in turn, slowly, away from the zombie), Hot Potato (touch someone to pass the grenade before it goes off), Overwatch Says (do it only when he says \"Overwatch says\"), Dance Marathon (jump on the big beat) and Counting Headcrabs (count them, not the watermelons, and say how many in chat).",
        "Nonsense dreams: Stop the Clocks (touch each melting clock to stop it; stop them all at once), The Tea Party (move to the seat that glows when the host shouts), The Headcrab Derby (stand on a lane's pad before the race to back its headcrab), Say Cheese (hide behind something giant before the scanner's flash), The Doors (stand at the door the music box plays behind), Splat! (paint the floor your colour), Conga! (keep in the glow at the tail of the line), Shh! (gather toys quietly: running and jumping wake the baby), Bubbles (pop them; big ones lift you) and The Watchers (they only move while nobody looks at them: gather the keys). In every strange dream, expect nonsense: things floating in the sky, odd textures, faces pulling expressions, sparkles and smoke, and sounds that won't stay at one pitch.",
        "The Midnight Rally (a Happy dream): a buggy race at night. Forward to go, back to brake, look where you want to go; you watch from behind your buggy. Stay between the cones (off the road you crawl), drive every part of the lap in order, and drive through the glowing crates for a pickup: a boost, a melon to drop behind you (whoever hits it spins out) or a horn blast that slows everyone near. Jump uses it. The first three over the line win. When few are asleep, the city's people drive the other buggies, and they can beat you.",
        "Every dream you play opens with its name on screen, and closes a win with who made it through. The dream's own figures act: her figure points at whoever just lost a life and holds out a hand to whoever wins, the giant officers shake a fist or hang their heads, her admirers reach out to her. Other dreamers' bodies flinch, cower and cheer too.",
        "City Administrator: your tablet's Tonight's dream says when the next dream is (a countdown at night) and lets you choose a kind, a Nightmare or a propaganda dream, once every few nights (never the night after one); the city decides which dream. You only have to be in the dreams you chose: on other nights lights out leaves you alone, unless you choose to join them (you're also asked as you lie down). Its Combine manpower shows what Civil Protection and Overwatch have left in reserve. Out of it in a dream? Watch the rest: click to follow another dreamer, Jump to fly about inside the dream.",
        "Tonight's dream follows the day: a unit murdered or a city in uproar can bring a Nightmare or a propaganda dream, a calm day a Happy one, an uneasy day a Neutral one; never two Nightmare or propaganda nights in a row. As the dream comes, the screen goes dark and you get a sense of what's coming.",
        "You can kill birds with your fists. Cook them before you eat them.",
    } },
    { "Staying out of trouble", {
        "Don't crowd Civil Protection units. They warn you first, then hit you with the stunstick.",
        "When a Civil Protection unit stops you, stand still. They may search you and find anything illegal in your pockets.",
        "A unit player searching you pats you down one spot at a time (Jacket, Waist, Legs, Boots): a panel shows which. Stand still. Once a spot has been checked you may press R, once, to try to slip something into it; it works more often than not, but if they feel it, it's found.",
        "Crouch to sneak: a Civil Protection unit only spots you from half the usual distance, even less if you move slowly or stay in the dark, and never from behind. While crouching, a bar shows how visible you are, and each unit's line of sight is drawn in front of him (red means he can see you).",
        "Wanted but haven't hurt anyone? Units chase you down and cuff you. They shoot at violent suspects, and at anyone with a gun in their hand.",
        "Sleeping in a bed, you lie still and heal; press Jump to get up. Rations being handed out during your shift? C menu > Take a ration break: your job waits for you.",
        "Resistance: with fighters following you, C menu > Resistance > Squad tells them to act casual (plain clothes, guns away), get their guns out, or meet you at the job's marker. In a camp, hold E on a mattress, crate or chair to move it (let go to put it down, R rotates it). At your stash, Stash it puts away the weapon you're holding.",
        "Everyone works: the Union gives a registered citizen a job if they don't have one (ask for a different one on F4 > Jobs). Being idle gets noticed.",
        "Curfew: you get one minute to reach your housing block (a fresh minute each time you respawn during curfew). A travel permit gets you past one curfew stop.",
        "Morning exercise (every second dawn; citizens must attend): go where the arrow on your HUD points. The jog: keep jogging and keep up with the pace marker, or the Civil Protection units along the route hit you with the stunstick (which makes you faster for a few seconds). The drill: stay on your ring and copy every move (crouch, jump, turn around, step), and jump on every beat when the rope comes out. The parade: cheer the column as it marches past (/cheer, /salute, chant in chat, jump) and keep your enthusiasm bar up. Skipping it costs Civil Standing and your next ration (a reprimand on screen); doing it well earns some, and a few credits, plus breakfast if your standing is Trusted or better.",
        "Full stomach (hunger 85 or more): 15% more XP from jobs and shifts.",
        "Top left: your credits and Civil Standing, and under them your loyalty, sympathy and corruption (what your choices in jobs and stories have made of you; they open up choices later).",
        "Combine-only areas (the Nexus, offices, armory, prison) are off limits. The doors near the cells are locked.",
        "Raids: Civil Protection units search a housing block, and any contraband they find (guns, TVs, radios...) is traced back to whoever owned it.",
        "Confiscated contraband is burned in public: after a sweep or a raid, or once enough has built up, units carry it to the square, pile it up and set it alight while the citizens watch (units see what's waiting in Unit tools, F2). Before it catches, anyone who isn't a unit can press E on something in the pile to take it back, but a unit who sees you makes you wanted.",
        "When you're wanted, every Civil Protection unit nearby comes after you. If they catch you, you're arrested.",
        "Kill Civil Protection units and the response escalates: armed units, then Overwatch squads. Stay out of sight to let it calm down.",
        "One accidental kill gets a light response; a second one soon after gets the full response. Resistance members lose a rank for every civilian they kill.",
        "To surrender, walk up to a Civil Protection unit and press E. You'll be treated more leniently.",
        "Marked as an anticitizen? Do community service from your job board (F4), or serve your sentence.",
    } },
    { "Getting by", {
        "Take a Union job from your job board (F4) and work shifts to earn credits, Civil Standing and a ration card for each shift.",
        "Your Civil Standing decides what the Commissary will sell you. Crimes lower it.",
        "Rebel territory has a black market (C > Getting by > Black market). To talk on a radio: C > Talk > On my radio.",
        "Press E on a dead body to search it. Dead Civil Protection units carry ammunition, and sometimes a keycard.",
        "To carry a body, look at it and choose F1 > Haul the body (Morticians just press E). Let go of it next to the incinerator and it goes in; attendants are paid for each one.",
        "The Resistance prints pamphlets (their quartermaster sells them). A member can hand one to you (F1 > a person > Hand them a Resistance pamphlet) or leave one lying about (F1 > Leave a Resistance pamphlet here). Press E on one you find to read it. It is contraband, and a unit that sees one handed over or left will come for whoever did it.",
        "A Cremator walks the streets. A body left lying for a minute or two it burns where it lies, so search or haul it first. It also burns anyone the units would shoot, and anyone who attacks it. Fire does nothing to it.",
        "Press E on a citizen to talk: hear the news, give them something (food, a drink or a smoke, medicine, a pamphlet, even a gun to a sympathizer), pick their pocket (uses Guile), or inform on them. They remember how you treat them.",
        "Lost, hungry or thirsty? Chat with a citizen: they may point you the way, and one who likes you will walk you there.",
        "Questions about the rules? The Citizen Information clerk answers them (the official version), and marks the way to Civil Intake, Housing, Labor, the Commissary and the dispenser. Your orientation pamphlet (in your pockets) says the same.",
        "Realistic survival: you can catch a cold in the rain, a stomach bug from raw meat or dirty water, and a fever from a cold left alone (no running, no fists, and at midday it knocks you down into a fever dream that breaks it). Union medicine from the Commissary cures a cold or a fever.",
        "The Resistance: an old fighter they call the Colonel keeps watch at the camp. He knows what's coming before the radio does.",
        "Somewhere in the city is an old man who's seen it all. Find him, visit him, share a meal: the better he knows you, the more he'll tell you.",
        "The Resistance (Member rank and up) can ask a sympathizer to keep watch: they warn everyone on Freq 7 when Civil Protection units approach.",
        "The city runs on a daily schedule: work in the morning, ration lines at midday, quiet evenings, and nearly empty streets at night (only the night shift works).",
        "Trains arrive at the station now and then, bringing new arrivals with suitcases. Anyone leaving the city boards before it departs.",
        "Watch your pockets: someone behind you might pick them (F1, from behind). Lend money with F1 on someone; if they don't pay it back in time, report the debt (F2 > Me > More > My debts). And the black market isn't always honest: sometimes it's a brick in a bag, sometimes a sting.",
        "Run a business: make rag dolls, tin toys and patched coats (F3, crafting) and sell them from your stall; passers-by buy them at a fair price. Hire someone to work your stall (F1, looking at them): their wages come from the till.",
        "Live with someone: look at them and F1 > Invite them into my household. A household shares a block, its crates and lockers, and the head's apartment keys (F2 > Me (More) > My household).",
        "Something to save for: the Commissary sells fine clothes (\"Well dressed\" for everyone to see), decor for your home (set it down in your block from your pockets), a radio set that plays music, and a pet bird that rides on your shoulder.",
        "On a quiet night (4 players or fewer) the city carries more of the story: events and the Resistance's own operations come more often, so there's always something going on.",
        "The city remembers. Supply, morale, the strength of Civil Protection and the Resistance, and the Administrator's authority carry over from day to day, and each housing block is held by one side or contested. Each morning a City Bulletin on the screens says what changed. See it on F2 > Me (More) > The state of the city. The Administrator moves them with speeches, amnesties, crackdowns and extra rations.",
        "The Resistance plans its own operations: a Lieutenant (or a Fighter, with no Lieutenant online) picks a target and a time on F2 > Resistance > Operations, and anyone in the cell can join. Those who were there when it works are rewarded. The Combine answers with bounties: the Administrator or a Division Leader puts a price on a wanted head (F2 > Me).",
        "Careful who sees you: some ordinary citizens are informants. A gun out in the open or contraband used in plain view, and one may walk off to tell the nearest unit. The Resistance can burn a citizen they suspect of informing (F2): RAT over their head for the cell, the quartermaster won't deal with them, and if they're held, a crude rat carved into their cheek for good: no Resistance will ever take them in. Burn an innocent and the whole city thinks less of the Resistance.",
        "Civil Protection works shifts with a quota: searches, checkpoint papers duty and a residence inspection (F2 > More > Me > My shift). A performance review at the end of each shift gives experience toward promotion.",
        "Lost among the numbers? F2 > Me > My standing (or Where I stand) (or C > You > Where I stand) shows every one of them in one window, each explained: standing, credits, rank, loyalty, sympathy, corruption, your record, wanted, probation and more.",
        "Dreams can be sat out once you've earned it: Happy or Neutral ones after living through 2 of that kind, Nightmares and propaganda with Exemplary standing (400). A small note tells you as the dream comes; choose in F2 > Me (More) > My dreams.",
        "Survival: Realistic (every need, 20% more shift pay and experience, the title Hardened) or Relaxed (slow hunger and thirst, no parasites, toilet, washing or spoiling). Choose on the characters screen or F2 > Me; you can switch every 3 hours.",
        "Your sentence adds up the crimes on your record since your last one: 3 minutes for petty things, up to 20 for murdering a unit, 30 at most. In a cell, F1 > Ask for a work detail: a guard walks you out to pick up trash, sweep the floor or unclog the Combine's toilets, by turns, for time off. Released, a citizen is on probation for 15 minutes: check in with a unit (F1), stay away from the Resistance, and anything new counts double.",
        "Interrogated? Each question is your choice: the truth, a lie (he may see through it), silence (the baton wears your resolve down) or a bargain for a shorter sentence. Civil Protection players can interrogate prisoners themselves: F2 > Interrogate, beside the cell.",
        "If a Civil Protection unit arrests you, you're cuffed and two units walk you to the cells. On the way, anyone can free you: take down the unit in front, then you can use {gm_showhelp} > Work at the cuffs.",
        "Rations come from the city's stores (shown under the clock). Kitchen and factory work refills them; when the stores run low, rations shrink too and people get restless.",
        "Each transformer powers its district: lights (including the map's switchable ones), screens and TVs, ration dispensers, vending machines, the Commissary and Combine door locks. Sabotage one (with a multitool) to cause a district-wide blackout and unlock its Combine doors, until Maintenance repairs it. Prison doors stay locked.",
        "If half the transformers are down at once, the whole city blacks out, the map's own lighting included: turn on your flashlight (F).",
        "Checkpoints: a glowing Combine power bank powers the turrets and forcefields cabled to it. A powered turret can be knocked over. Turrets shoot the infected, wanted people and known rebels. Cut the bank's power (with a multitool, or a blackout) and they all shut off; if the checkpoint is next to the infestation, that causes a containment breach.",
        "The infestation: yellow-stained, scorched ground, a thick yellow haze, and a geiger counter that clicks faster the deeper you go.",
        "Union job behind Combine doors? While you're on the job, open the actions menu > Getting by > Ask for a Civil Protection escort. With your escort close by, press E on Combine doors to open them. If someone slips in behind you, the unit goes after them; let it happen twice and nobody will escort you for a while. When the job's done, they walk you out to the release point.",
        "Combine forcefields: Civil Protection units walk straight through. Swiping a keycard (E) opens one briefly; a multitool shorts it out.",
        "Letters: open a note in your pockets and choose Send as a letter while at the post office. A courier delivers it to the recipient's housing block. Civil Protection units can read mail while it waits there.",
        "The city's NPCs work Union jobs too: fixing lights and loudspeakers, scrubbing graffiti, hauling bodies, carrying crates and mail. Look at someone to see what they're doing. Broken things are left for a while first, so players get the first chance to fix them.",
        "Down and bleeding? A Union medic may come running to help, as long as you're not wanted and there's no firefight.",
    } },
    { "The war for the city", {
        "Rebel territory and the infestation spread if nobody fights them (across a floor, or down the stairs to the next floor), and shrink when people fight them.",
        "A message appears on screen when you enter either one. C > The city > Who holds the city (or F4) shows how much each side controls.",
        "When unrest is high (the Resistance is strong): more inspections and raids, and ration cuts. At full compliance, the rebels go quiet.",
        "Civil Protection units: F2, then 4 (Call for backup) brings the nearest units running; 6 (Send my 10-20) marks your location for other units.",
        "Resistance: the quartermaster in rebel territory sells gear. Members and up can press E on fighters to have them follow you.",
        "Fighters following you stick with you above all else. They hold fire until you or the Combine start shooting, then shoot while on the move.",
        "Rebels fight as guerrillas: they let a Civil Protection unit get close before shouting, and out in the city they stay out of sight. Units who see an armed rebel in the street open fire.",
        "In their base, rebels keep busy: patrols, the lab bench, crates, the garden, the fire, sleep. Now and then one or two leave to scavenge and bring supplies back.",
        "Every rebel base needs a lab. Its scientist makes guns, ammunition, armour, jammers, bypass charges, smoke bombs and Freq 7 radios, for the Resistance only. Bring the materials and it's free, or pay him (60% of the black market dealer's price). F2 > Resistance > Find the lab marks it on your screen.",
        "Everyone else buys guns, ammunition and jammers at the black market. If a Civil Protection unit finds the scientist, the lab shuts down for ten minutes.",
        "Citizens pick up rumours. Talk to them (E) now and then.",
        "Ways for the Resistance to make money: write notes on what you see near a checkpoint or a unit (F2 > Resistance, needs paper) and sell them to the quartermaster; steal good parts off the factory line (R while holding one); or have the lab make forged ration cards (but if too many turn up, the camp gets swept).",
        "The Resistance: F2 > Freq 7. Send a message on the band, call for backup (every Resistance player hears it and sees where you are, and a Member or higher gets a couple of idle fighters from nearby, who stay with you), send your position, or follow a trail to the nearest rebel ground or the lab.",
        "Rebel zones that touch count as one camp: one quartermaster, one supply crate. He buys food back for 2 credits at most (food from his crate is free).",
        "A role (Hacker, Father Grigori...) is added on top of your rank: you're still a Fighter working toward Lieutenant, but you carry the role's kit. To give up the role, join the faction again in F4.",
    } },
    { "Getting by, and making things", {
        "Near Resistance activity when the PA announces that ration units are being deducted? You lose your next ration; the dispenser tells you why.",
        "Press E on bins, dumpsters and fridges to search them: scrap, rags, chemicals, tins, seeds, sometimes gun parts.",
        "Fishing line (from the Commissary): stand in the canal or look at it, choose Fish in F3 (or C > Getting by), and keep still: a cast takes up to 45 seconds, and most come up empty. Cook what you catch.",
        "Rebel territory has plant pots (plant seeds, harvest vegetables) and a supply crate the Resistance eat from. C > Resistance > Donate food adds to it.",
        "The supply crate is restocked for how many Resistance are online, about half of what you eat, so it often runs empty: fish, hunt headcrabs or birds, grow vegetables, ask citizens for food, or buy from the quartermaster. Each of you can take one tin every 15 minutes. Look at the crate to see what's in it and when more is due.",
        "Crate running low? Take a Headcrab hunt from the Operations board (F4): kill four headcrabs in the infested ground, pick up their raw meat (E) and stand by the crate. Each headcrab is a meal for the camp, and it pays more while the crate is empty.",
        "F3 > Make: craft bandages and lockpicks by hand, anywhere. Everything else is made by the Resistance lab or sold on the black market.",
        "Hold a crowbar, look straight at a piece of junk (a wrecked car, a radiator, pipes, a crate) and press E to pry out scrap, rags and chemicals. It's loud: the nearest Civil Protection unit comes to check.",
        "A crowbar counts as a weapon: if a Civil Protection unit sees one in your hand, you become wanted. Keep it put away on the street.",
        "Rebels guard their territory: break their crates and they warn you twice, then shove you, then attack you. Leave their supplies alone.",
        "Shoot down one of the city's scanners and it breaks apart into scrap. A scanner with a glowing red eye is being flown by a player: it drops nothing.",
        "Supply drops: a Combine convoy unloads a crate on the street. A soldier guards it (he warns you off twice), and two metrocops carry boxes away down the street and back: sneak in while they're away. Press E on the crate to take a load (gun parts, ammo, medicine) quietly, as long as no unit sees you doing it.",
        "Your vest (VEST on your HUD) is only charged by charge cells (made by the lab; dropped by dead units and downed scanners), batteries and chargers, or a freed vortigaunt (ask it with E). Sleeping doesn't charge it.",
        "The lab's scientist can give you a new face (300 credits): nobody is looking for it, your wanted status and BOLOs are gone, and your old Civil Standing doesn't carry over.",
        "Once you've lived through three of the city's dreams, the lab can help you out of the rest: a foil hat (sleep in it and it keeps the dream out about one night in three: it's a tin foil hat; contraband), or pulling the chip (500 credits: no dreams ever and a short night's sleep, but a unit may notice there's no implant signal).",
        "Wanted, and out of every unit's sight for half a minute? They've lost you: only a unit that actually sees you will come after you.",
        "A radio jammer (from the lab or the black market) blocks Civil Protection radios, request devices and scanner reports nearby for four minutes. Units destroy them with E.",
        "Citizens' Assignments include Union work orders (streetlights, rubble, pipes) that pay in scrap, rags and chemicals.",
        "Union reclamation points buy scrap, cans and bottles for credits and a little Civil Standing.",
        "Homemade guns and ammo sell at the black market, and for more at the quartermaster. The risky part is getting them there.",
        "F3 > Give hands an item to whoever you're looking at. With a lockpick, a prisoner can pick their cell lock.",
        "In a cell with a Combine console? Press E on it to fly a city scanner while your body stays in the cell. Taking a flash photo of a Civil Protection unit adds a minute to your sentence. Photographing rebels, free vortigaunts, wanted people or zombies from about ten feet away earns Civil Standing (never time off your sentence) and marks them for every unit. Scanners can't see into or through smoke.",
        "Spray cans paint the lambda symbol on walls. Civil Protection units and loyal citizens scrub tags off with E.",
        "Civil Protection units: smoke, flashbang and gas grenades unlock as you rank up. The Grenades weapon throws them; R switches type.",
    } },
    { "Disguises", {
        "Resistance: you respawn in plain clothes. C > Resistance > Gear up puts your Resistance gear on; Change into plain clothes takes it off again.",
        "In plain clothes nobody looks twice at you, unless a Civil Protection unit sees a gun in your hand.",
        "You can take clothes from the dead (citizen clothes, CP uniforms, Resistance gear) and find them in bins. Wear them from F3.",
        "A CP uniform fools Civil Protection units on the street, for a while. Resistance gear makes rebel fighters think you're one of them, and makes units shoot at you.",
        "Never change clothes in front of a Civil Protection unit.",
    } },
    { "Carrying and keeping things", {
        "What you can carry is limited by weight and size. A satchel lets you carry more.",
        "While looking at a bin, open F3 to hide items in it. Anyone can find them.",
        "Lockers (E): put something in one and that locker becomes yours. A storage crate bought from the Commissary is placed from F3.",
        "Civil Protection units can open any locker or crate and take anything illegal.",
    } },
    { "Homes, trade and writing", {
        "Apartments: look at a door to see who owns it, or whether it's for rent. With your hands out, right click a free door to rent it (you'll be asked yes or no), and right click your own door to lock or unlock it. Or use C > This door, and C > Home for keys, locking and giving it up.",
        "With a CWU business license you can place a market stall and sell from it. Customers press E on it to buy.",
        "Paper: Write from F3. Leave it as a note, put it up on a wall as a poster, or keep it. Press E on one to read it.",
        "The city's laws are in C > The city > The city's laws. The Administrator speaks to everyone from C > The city > Broadcast.",
    } },
    { "Characters and acts", {
        "C > Me > My characters: all your characters in the city. Switch between them, or create a new one.",
        "C > Me > Pose: sit, kneel, lie down, lean, cower, or one of four standing poses. Move (or choose Stand up) to get up.",
        "C > Me > Gesture: wave, salute, bow, nod, shake, point, beckon, halt, cheer, laugh. C > Me > Put my hands up.",
    } },
    { "Vortigaunts, time and weather", {
        "Shackled vortigaunts work the Union's shifts; their collar stops them using their vortessence powers.",
        "A shackled vortigaunt can reach out through the vortessence (C menu), unseen, to tell the Resistance where it is, and has its own story on the board, The Collar. A free vortigaunt has jobs of its own on the Resistance's board: Free your kin, and Read the Combine. Its bolt (left click) shorts out a power bank, forcefield or turret from a distance for 45 seconds. Its right click mends another vortigaunt (a second to gather, then 25 health; once every 10 seconds for each). With two or more free vortigaunts about, they commune now and then: news of a sweep for the Resistance, or a Combine door code on a scrap.",
        "Loyalty pays: Civil Protection units, and citizens with 200 Civil Standing or more, rent their apartment for free.",
        "More for the loyal: from Trusted (150 standing), fewer stops, better pay, a Commissary discount and the use of a locker; at Exemplary (400), no searches, two ration cards a shift, waved through once a curfew, a minor slip forgiven once a day, praise from the Administrator, MODEL CITIZEN on your papers. (From 100 standing, the Block Warden job.)",
        "Weeds come up through the cracks on open ground and grow into bushes. The Groundskeeper (a Union job) sprays them with weedkiller: look at one and press E. Weedkiller is poison too: F3 > Weedkiller > Poison food or drink, and it looks no different. At the Resistance lab it makes a firebomb: armour doesn't keep out fire, and it burns out Combine machinery. Drop it under a barnacle and the barnacle dies.",
        "The infestation has growths in it that glow green. Spray them with weedkiller (E) and they die; cleared away, the infestation shrinks. Infestation Cleanup (a Union job) does it for a living, in a respirator, guarded by two Overwatch soldiers: spray them dead with the sprayer (hold left click), vacuum them up with the hoover (hold left click), and empty it into an infestation control barrel (E; the last step marks one). Each shift counts double towards joining Civil Protection, and each asks for more growths than the last (3, 5, 7, up to 11).",
        "Your Union tools (the sprayer, the hoover) come back when you rejoin or leave prison, as long as you still have the job. More weedkiller: it comes with each shift and whenever the sprayer runs empty, or buy it at the Union Commissary. You can change Union jobs once every 15 minutes.",
        "Below Trusted standing (150) the ration dispensers give a short ration, a third less food: birds and headcrabs make up the rest. Good standing earns the full packet.",
        "The city keeps shackled vortigaunts sweeping the streets. Resistance (Member and up): look at one up close and unshackle it (C > Resistance, or !unshackle), with no Civil Protection unit watching, and it goes home to rebel ground.",
        "The Resistance (Member rank and up) can free one (look at it, then C): it takes ten seconds, and nobody must see you. Once free, it can attack (left click) and charge vests (right click), and the Combine hunt it.",
        "Armour is the charge stored in a powered vest. Civil Protection units have one built into the uniform, rebel ranks come with one, and anyone else needs one from the lab. Vortigaunts can charge it.",
        "When no player is Father Grigori, he stays in rebel territory: press E on him for a blessing, a sermon, or a few words.",
        "A full day lasts one real hour. Nights are dark, and curfews are more likely. C > The city shows the time and weather.",
        "Stand out in the rain to fill an empty bottle or can. lc_music 0 turns off the city's music.",
        "Need a staff member? Type @ followed by your message.",
    } },
    { "Directives and jobs", {
        "F4 > Jobs is your job board. Events add their own directives: they're posted two minutes before the event and taken down when it's over.",
        "Only rations and curfew are announced in advance. Sweeps, raids and supply convoys happen without warning, and a lockdown only happens after violence.",
        "Several people can take the same job: up to 8 for an event, 6 for containment or retaking ground, 4 for a chase.",
        "Want to join Civil Protection? You need Civil Standing 100 and some shifts as a Records Clerk first (F4 > Jobs): units come up through the records office.",
        "A Civil Protection unit who stays inside as the Resistance's spy (the story The Man Inside) gets a menu only they can see: C > Civil Protection > Inside. Tip off Freq 7, lose a record, take supplies for a dead drop, copy the records, or reveal yourself with the codeword, each only where nobody can see or hear you. Beside a prisoner being marched to the cells, you can let them slip (F2 > 7, while the panel on the right says so; greyed while someone can see you): you take them off the escort's hands and uncuff them, and they have 20 seconds to get out of sight before anyone's after them (it costs you 20 Civil Standing; once every 20 minutes). Get caught, and you're Resistance for good: wanted, with no surrendering.",
        "When the infestation spreads or the Resistance take ground, a directive to deal with it is posted straight away.",
    } },
    { "Civil Protection", {
        "Searching someone (baton reload, !search, F2) opens a pat-down: click Jacket, Waist, Legs and Boots to check each for a second. Only the spots you check give up what's there, so check them all, then press Done. Watch for \"They tried to move something\": that's found too.",
        "Civil Protection units: F2 is your unit's quick menu. 1 to 6: Voice lines, Unit tools, Kick, Call for backup, Issue a BOLO, Send my 10-20. 7 and 8: search, cuff or escort whoever you're looking at. F1 has what everyone has (papers, talking, poses).",
        "The Resistance's man inside also has F2 > Inside (only they see it): the same as C > Civil Protection > Inside. Anything you can't do right now is greyed, with why: someone can see you, not yet, or only at the Commissary.",
        "Division Leaders and up: F2 > Call a sweep orders a contraband sweep or a block raid, when the city allows it: not during another event or a dream, one every 15 minutes across the city, and not too soon after the last event.",
        "Units, Overwatch soldiers and the Administrator's Elites step aside when one of their own side walks into them (a unit, or the City Administrator), never for anyone else, and never mid-fight. The city's citizens make way for anyone.",
        "The City Administrator: F2 also opens her tablet, the laws and tonight's dream, commands her guards (follow me or hold here; how close they follow; and when there's trouble: as always, stay with me, stand between us, or hold fire unless fired on), and orders the arrest of whoever she's looking at: wanted by order of the Administrator, with a BOLO for every unit (once every 5 minutes; never a unit or staff).",
        "Units: C > Unit tools lists everything a unit can do, with what each one does. The records terminal holds violations, notes, loyalty points, BOLOs and requests, and its Manpower tab shows the Combine's reserves.",
        "Civil Protection units don't craft: the Civil Protection Commissary issues grenades, ammunition, armour, bandages and your ration (press E on it; once every two minutes). F3 marks the nearest one on your screen.",
        "Civil Protection units: actions menu > Civil Protection > Deploy a turret here, near a checkpoint's power bank or forcefield (each power bank runs two; press E on a turret to pack it up). Officers can put up power banks.",
        "Union workers can ask for an escort. Actions menu > Civil Protection > Escort requests to take one (or look at a worker > Escort them). Keep them close, open the doors they need, and walk them out to the release point when they're done.",
        "F2 > Voice lines has the mask's most used lines (or just say the words in chat); all of them are in Unit tools > Voice lines.",
        "C opens the full menu (so does 9 on the quick menu): everything you can do right now, based on who you are and what you're looking at, with this guide at the top. No chat commands to remember (though they still work).",
        "A special role (Hacker, Father Grigori...) comes back with you when you rejoin, if there's still a free place in it.",
        "The multitool (the Resistance's two Hackers carry one; the black market sells them; contraband): aim it and left click at a locked Combine door (hacks it open), a city screen (hijacks it), a data terminal (steals its data), a vending machine or ration dispenser (free water or rations), or a shackled vortigaunt (unlocks its shackles and frees it).",
        "The Director of Propaganda's microphone: left click to go on air over every loudspeaker and screen (one minute, once every fifteen minutes). A scanner flies down and films whoever holds it, live on every screen; its eye blinks red while it records. Shoot the scanner down to cut the picture. With no player in the job, the Administrator addresses the city herself now and then; kill her on air and her microphone is yours. Take the microphone off someone (hands up or cuffed, actions menu) and broadcasting with it is a pirate broadcast.",
        "The Director of Propaganda's poster roll: left click hangs the chosen poster on the wall in front of you, right click takes any poster down (the city's own return when the map next starts), reload chooses another (seventeen posters). Eleven of them only ever go up by hand: the city has them when its Director hangs them. They stay up until the map changes.",
        "A spray can used on one of the city's posters paints over it (the same risk as spraying a wall). Left click with a poster roll pastes a fresh sheet over the paint. In a Resistance member's hands a poster roll also has four of their own paste-ups on it.",
        "Resistance paste-ups (from the quartermaster, three for 20): use one from your pockets while looking at a bare wall, up close, and it goes up. Only a few can be up in the city at once: one more and the oldest comes down, and never two close together.",
        "Windows are drawn in your faction's style: black glass and cyan for Civil Protection and the Administration, rust and scrap plate for the Resistance, grey concrete for citizens. The Combine's machines (the Commissary, Civil Intake, Housing, Labor) look like the Combine's whoever uses them, and the quartermaster's and the black market's wares come on rust and scrap whoever buys. Being questioned or searched looks the same whoever you are. Menus, the F1 and F2 lists, notices and the panels on your screen follow your side too. To switch it off: lc_ui_theme 0 in the console.",
        "Streetlights and loudspeakers break when shot or worn out: broken lights go dark, and nobody near a broken loudspeaker hears the PA. Maintenance and Radio Repair crews fix them.",
        "One data terminal gives half a chip (a fragment): hack a second, different terminal and the two fragments make a full data chip. The master terminal is the big prize: one download gives a master data core.",
        "A data chip: sell it to the black market dealer, take it to the lab and have the scientist Decode it (first on his list; marks every Civil Protection unit for five minutes), or Use it at a terminal to wipe your record.",
        "Dead soldiers drop their guns with about half a magazine loaded. The rest of their ammunition is on the body: search it.",
        "Shooting a scanner counts as damaging city property; killing one counts as destroying it. Neither counts as assaulting anyone.",
        "Ambush the landing: get to the landing zone before the dropship arrives, and attack the soldiers it drops off.",
        "Someone you're escorting runs when you run, and when there's shooting. If you climb a ladder, they follow you up it.",
        "Resistance: a small orange lambda over a citizen's head means they're secretly on our side. Members and up can ask them to keep watch (E, then the talk window).",
        "Break your people out of the cells, ambush Overwatch landings, free a vortigaunt: you'll find these in Operations (F4).",
        "Citizens: look at someone and choose F1 > Inform on them. Civil Protection pays you if it's true. If the Resistance see you do it, they'll know you're a traitor.",
        "Trusted citizens: actions menu > Getting by > Become a Union foreman. Then open the actions menu on a citizen > Give them a work order. You get a cut of what they're paid for it.",
        "The worst anticitizens face worse than prison time: interrogation (the interrogator offers 50 social credits if you talk), broken feet (no running), or being made a stalker.",
        "A stalker works down below, in the Combine areas: see The Stalker's Lot on your job board (F4). Units leave stalkers alone, their papers are stamped STALKER, and they can scream but not speak. The only way out of being a stalker is death. At the end of the stalker's story is a Combine ball energizer you built yourself; stepping into it is a way out, and that character is gone for good.",
        "Civil Protection is one career path: Recruit, Metrocop, Division Leader, then the Overwatch ranks (Prison Guard, Soldier, Elite). The Overwatch ranks need the transhuman conditioning, which the Overwatch Candidate story offers to Division Leaders.",
        "Not sure what to do? F1 > What now? > Ways to get by lists everything open to you, and what you need for the rest.",
        "Civil Protection units can kick: G (or F2 > Kick). Doors swing open, locked doors give way on the second kick, and people get knocked back. A Combine Soldier kicks a hinged door off its hinges; an Elite sends it flying and knocks out anyone it hits. Maintenance Technicians rehang fallen doors: E to lift it, carry it to the frame, E again.",
        "Any Civil Protection unit can fly a scanner from a Combine console or from the Nexus (F2 > Unit tools). Reports earn XP; any rebel you photograph gets a BOLO.",
        "Running in front of Civil Protection gets you a beating and sent on your way. Do it a third time within an hour and it's prison.",
        "When you're released from prison, you get your fists back but not your guns or radio. Civil Protection units get their issued gear back.",
        "Rebel territory is deadly for units: a REBEL TERRITORY AHEAD warning appears just before you cross into it. Inside, rebels shoot Civil Protection units.",
        "Supply drop happening? Guard the crate: if anything is left in it when the convoy moves on, every Civil Protection unit nearby gets paid.",
        "RADIO JAMMED on your HUD means a jammer is nearby. Follow the beeping and press E on it to smash it.",
        "Civil Protection units: look at someone and choose F2 > Cuff them. Anyone with cuffs: C > their name > Cuff them. You can cuff someone whose hands are up, who is down, who has been stopped, or from behind. Drag walks them along; hitting them with the baton arrests them.",
        "Sociostability (green, yellow or red) is shown at the top of the screen. Only the Administrator sets it (F2 > Sociostability, or C > The city). Red means a judgment waiver: metrocops have their pistols drawn.",
        "BLACK (purple, the city collapsing): long red fills the city's chaos (the readout shows how close: \"collapse 45%\"). Full, the G-Man offers the Administrator a way out: step down, or end it. Under BLACK: a mandatory curfew, and the Nexus's suppression device shells rebels out under open sky (a ring glows where it will land: move!). Refused, he arms the city until her last stand: she floats in a shield that deflects every bullet, fed by 2 or 3 transformers marked on screen, each behind glass and guarded (manhacks, turrets, mines). Destroy them all and she can be killed. If she holds out, a player of the rebellion comes back as Barney, then as Gordon Freeman, to finish it.",
        "Set off an alarm (with a data chip, or during an escape) and a squad of two metrocops and a soldier comes through the door a few seconds later.",
        "The Nexus and every Combine-only area are guarded: mostly Overwatch soldiers, plus a metrocop or two.",
        "Combine units are tougher than in Half-Life 2 (metrocops 70 health, soldiers 90, Elites 150). When the Resistance far outnumbers the Combine's players, they get desperate, and more so the bigger the gap: metrocops carry SMGs, soldiers throw frags, gas and flashbangs, Elites fire more energy balls, and they hit a little harder. Everyone is told when it starts and stops.",
        "Resistance fighters have no armour (50 health) but there are more of them: at least 5 for every 4 Combine units out on the streets. They carry SMGs, shotguns and now and then a crossbow.",
        "The Resistance doesn't take just anyone: prove yourself first. Help them on jobs and quests, feed their supply crate, sell or give the quartermaster guns, ammunition, gun parts, scrap, rags or chemicals (E on him: strangers can too), hand a ration or arms to one of their fighters, side with the vortigaunts in a dream.",
        "Squads: how many NPCs you can lead depends on how many players are on your side (alone or two: 5 each; 3-4: 3; 5-6: 2; more: 1), so team up with each other. A Resistance Commander or an Overwatch Elite always leads at least 4. F2's Call for backup shows your squad (2 of 3).",
        "Call for backup from F2 or by left clicking with the radio transmitter up. The Resistance needs a Freq 7 radio; with nobody near, fighters come out of rebel territory to you. Civil Protection and Overwatch: press E on one of the city's units to have them follow you, again to send them back (Elites follow only the Overwatch Commander).",
        "Citizens: C > Getting by > Request Civil Protection (needs a request device) calls a Civil Protection unit to you. Use C > Me > Put my hands up when a unit tells you to.",
        "Cuffed? Use C > Me > Work at the cuffs to get free, when nobody's looking. Anyone can uncuff you.",
        "Arresting someone with the baton: they may struggle (both press E fast; the bar shows who's winning). Held, they're cuffed: walk them to the cells yourself (F2 > Walk them to the cells, or F1 > Drag them along) or a unit comes to walk them in. Arrested yourself, press E fast to break free and run, or put your hands up to go quietly.",
        "Your duty allocation is a ration voucher: take it to a Civil Protection Commissary or a ration dispenser. The CP Commissary gives a health vial and a bandage once a day, and charges your vest while you stand at it.",
        "C > My career shows your rank, the XP to the next and the way to the Overwatch. On a violent job, two of your own side come with you. Flashbangs blind people for several seconds.",
        "Overwatch soldiers stay inside the Combine's own buildings unless something serious is going on. Citizens never go in; a stalker clears up in there.",
        "The Combine can wreck a Resistance lab by shooting it; the Resistance fix it with the job \"Get the lab running\".",
        "The Administrator controls the Union Commissary (what's sold, prices, standing, supply). What she restricts or makes scarce turns up at the black market dealer and the quartermaster at a premium; prices there rise with demand. Each shop window says why.",
        "The Administrator's microphone (left click) puts her voice on every loudspeaker whenever she likes; hold push-to-talk or type in chat. While a player is the Administrator, the PA's recorded announcements are Overwatch's.",
        "Each Combine building has its own stalkers: they work its terminals, clean up and fix its lights and loudspeakers. Citizens never go in.",
        "Rebel raids are real: Resistance players see Our fighters on screen; units see 10-20: ANTICITIZEN ATTACK when a raid hits.",
        "Each side has only so many fighters and units. The dead aren't replaced at once: new recruits trickle in. The Resistance see their fighters on F2 > Resistance; units see the Combine's on the unit tools. A side with too few left postpones its raids or sweeps.",
        "Admin testing tools > The city: superadmins can grow rebel ground or the infestation now, and see why a territory hasn't grown.",
    } },
    { "Tips", {
        "The first time you come across something, a card on the right explains what it is and what you can do. Each card only shows once.",
        "C > Tips I've seen lists every tip you've had, to read again. C > Settings turns tips off or on, or starts them over.",
        "A small panel on the right shows what you can do right now: what the tool in your hands does, where you are, and what your quest wants, with your own keys. On a quest, amber chevrons on the ground lead you to the objective. Turn either off in C > Settings.",
    } },
    { "Talking, and knowing people", {
        "Chat is spoken out loud: only people nearby hear it. C > Talk lets you yell so people further away hear (/y), or whisper to whoever is right next to you (/w).",
        "C > Talk: describe what your character does (/me lights a cigarette), describe the scene (/it), or roll 1 to 100 for everyone nearby to see (/roll).",
        "Out of character: F1 > 6 > 1 Nearby (/looc) or 2 Server-wide (//, with a cooldown). Also C > Talk > Out of character.",
        "U (the game's team chat key): talk to your own side only, wherever they are: Civil Protection, Overwatch and the Administrator; the Resistance; citizens; the infested. Marked (Team) in chat.",
        "Voice chat works the same way: people only hear you if they're close enough.",
        "Strangers don't know your name; they see your description instead. Set it in C > Me > Change how strangers see me (\"tall, with a scar over one eye\").",
        "To tell someone your name, look at them and choose F1 > Tell them my name. F1 > Talk > Tell everyone nearby my name tells everyone around you.",
        "While their mask is on, Civil Protection units are known by their designation, not their name.",
    } },
    { "Going down", {
        "A killing blow puts you on the ground, bleeding out, instead of killing you outright. You can still whisper.",
        "Someone can press E on you to get you back up: it takes a few seconds bare-handed, and is quicker and better with a bandage.",
        "If a Civil Protection unit presses E on a downed wanted person, they cuff them where they lie.",
        "Shooting someone who's down kills them. To drag a downed person, look at them and choose F1 > Drag them along; choose it again to let go.",
        "C > Me > Give up lets you die if nobody is coming to help. Explosions and the like kill outright.",
    } },
}

-- The guide: the full menu's first item (C, cl_livingcity_actions.lua), !help,
-- or the console command lc_help. A list of topics on the left, the topic on the
-- right, and a search box that looks through all of it.
local ADMIN_GUIDE = { "Admin", {
    "C > Help > Build mode (or !build) turns build mode on and off: spawn menu, context menu, physgun, toolgun (Living City Editor) and noclip.",
    "Civil Intake: place \"Fixture: Civil Intake (registration)\", \"Fixture: Housing Allocation\" and \"Point: arrival\". Settings: lc_intake, lc_intake_secs (8), lc_intake_grace (10 minutes), lc_papers_fee (10), lc_card_fee (15). Commands: lc_register <name>, lc_unregister <name> (sends them back through all of it, room included). With no desk on the map, people are registered and housed automatically as they arrive.",
    "Labor Assignment: place \"Fixture: Labor Assignment\". Settings: lc_labor_min_minutes (30), lc_labor_min_shifts (4), lc_labor_cleanup_standing (25), lc_labor_porter_standing (50). Without one, the Union assigns work and the board (F4) changes it, as before.",
    "Shared dreams: place \"Point: dream\" in an out-of-map area (and \"Zone: dream\" round it, tall and open for the flying endings). Endings set off in play then come at night as a dream for sleepers only, with no reload. C > Help > Dreams: status, dream it now, wake everyone, put back a player's things. Settings: lc_dreams (1), lc_dream_delay (60), lc_dream_radius (1500), lc_dream_every_night (0), lc_dream_combine (6). Without a dream point, the endings are as before.",
    "Nightmare dreams you play (the Administrator's tablet, under Nightmare; or C > Help > Dreams: dream it now): The Patrol Maze, The Barrel Tower, The Crumbling Floor, Freeze, Citizen. Each builds its own arena at the dream point and removes it afterwards; it fits inside the dream zone (or lc_dream_radius), so give it about 1500 units each way and some headroom for the tower.",
    "Propaganda dreams (her tablet, under Happy, as Propaganda; or C > Help > Dreams): Kneel Before Her, Roses for Her, Mirror, Mirror, The Saviour, The Loyalty Quiz, and ten more (Record Harvest, The Stakhanov Shift, Careless Talk, The Newsreel, Two Minutes of Hate, The Mass Games, On-the-Spot Guidance, The Scrap Drive, Flowers for the Liberators, Duck and Cover, Ravenholm). Asleep for one with someone else, the Administrator stars herself (tablet > Tonight's dream > Star in propaganda dreams yourself: on or off); otherwise a giant figure of her does. Music goes flat in garrysmod/sound/livingcity/dreams/, named admire, saviour_horde, saviour or quiz (admire1.mp3), or for the ten more their codeword (harvest, shift, spy, newsreel, hate, massgames, guidance, scrap, flowers, duck, ravenholm) or propaganda; her voice lines in dreams/voice/ (saviour_stop1.wav, a .txt beside it for the subtitle). Upload, FastDL sync, map change.",
    "Testing a dream: the Living City Editor's panel, Dreams: test one. Pick any dream and Test it now (just me): you play it at once, awake and alone (the city's people stand in), and Stop the test whenever you like. Nobody asleep is pulled in, it isn't tonight's dream, and nothing you win or lose counts.",
    "Civil Protection Commissary (editor fixture): Civil Protection units get grenades, ammunition, armour, bandages and a ration there. lc_cpsupply_cooldown (120), lc_cpsupply_ration (600). If none is placed, the Union Commissary terminal issues them instead.",
    "Resistance lab (editor fixture, formerly the workbench): a lab bench and a scientist who makes the Resistance's guns. Place one in every rebel base. lc_lab_price (0.6 of the dealer's price), lc_lab_shutdown (600 seconds closed after a Civil Protection unit finds it).",
    "How it feels (editor panel, How it feels): lc_fov (75, the widest view anyone gets; 0 leaves it to each player), lc_eye_height (61; GMod's default is 64), lc_view_bob (with lc_view_bob_amount, 100%, for how strong), lc_quiet_hud, lc_respawn_secs (12, how long the death card shows), lc_word_gets_around.",
    "lc_debugreport copies a report to send when something breaks.",
    "C > Help > Admin testing tools (or the button on F4, or !admintools): give yourself XP, a rank, credits and Civil Standing, switch faction, or start over.",
    "Switching faction from F4 changes your uniform and kit on the spot: no need to go back to a spawn point.",
    "Chat commands: !givexp, !setrank, !givecredits, !givestanding <n> [name]; !resetxp, !resetcredits [name]; !resetme.",
    "C > Help > Staff panel (or !staff): logs, tickets, warnings, character bans. !warn <name> <reason>, !charban <name> <reason>.",
    "lc_time <hour>, lc_weather <clear|overcast|fog|rain|storm|auto>.",
    "To black out the whole city for an event: !admintools > The city, or lc_blackout on|off|auto.",
    "Checkpoints in the editor: Combine power bank, Combine turret, Combine barricades. Place one at the edge of the infestation and the infestation stops spreading there, until the checkpoint loses power.",
    "Cell doors not locking? Tag them in the editor with Door: prison or cell. They stay locked during a blackout, and close themselves if anyone other than a Civil Protection unit opens them.",
    "Door: always open keeps a door open permanently: it's locked open, and opens again if anything shuts it.",
    "Your own announcements: put .wav files directly in the server's garrysmod/sound/livingcity/overwatch/ or .../administrator/ folder, named after the trigger (curfew1.wav, ambient2.wav). For the Administrator, the tone goes in the name too (curfew_firm1.wav, curfew_stern1.wav, curfew_furious1.wav; warm has no tone word). Each folder's README lists the triggers. lc_announce_clips lists the files it found (and any the game can't play: an MP3 renamed to .wav is silent, so keep .mp3 files as .mp3; a .wav must be 16-bit 44100 Hz). lc_announce_say <voice> <trigger> [tone] tests one. Each player's own computer plays them, so players get them through FastDL (press FastDL sync after adding one, then change the map). lc_sound_check tests a player's own copy.",
    "Secret endings (keep them secret): the G-Man stops time and everyone votes: 1 lets the city end, 2 skips it (if nobody votes, it ends). Nobody really dies; the map reloads afterwards. Songs go directly in the server's garrysmod/sound/livingcity/endings/ folder, named after the ending: harpies.mp3, bus.mp3, plane.mp3, standup.mp3, water.mp3, bloom.mp3, marrow.mp3, base.mp3, hard.mp3, shalom.mp3, fire.mp3. Father Grigori eating a master data core (Eat it in his pockets, or /eatchip) starts the flood (if an admin starts it, the city's own Father Grigori takes the stage; lc_ending_flood_crowd sets how many others are up there with him). Commands: lc_endings, lc_ending <id> [now], lc_ending_cancel, lc_ending_reset_cooldown. The Endings menu (C > Help > Endings menu, superadmins only, or lc_endings_menu): adjust any ending live while it plays, including its dances bone by bone (the selected bone lights up on the dancers) and all its settings, then copy what you changed. The Harpies (mingebags): lc_ending_minge_swell is the second the song swells, lc_ending_minge_end when it's all over, lc_ending_minge_max how many there are, lc_ending_minge_crowd how many of the city's people stand in the ring, lc_ending_minge_chatter 0 silences the Combine's radio chatter. Bloom (the dance): lc_ending_bloom_speedup, _ramp, _peak, _bpm; lc_bloom_preview and lc_bloom_pose tune the dance. Marrow (the skeletons): lc_ending_marrow_sections lines it up with the song (seconds:dance|rave|attack|outro|end). The Bus: lc_ending_bus_sections (seconds:fly|drive|fast|end), lc_ending_bus_bpm. Base: lc_ending_base_sections, lc_ending_base_lines (the subtitles). Hard (party hard): lc_ending_hard_sections, lc_ending_hard_moment_beats (how often another Combine member joins in), lc_ending_hard_moment_max (how many at once). Plane (numa numa): lc_ending_plane_sections, lc_ending_plane_captions. Standup (the rope): lc_ending_standup_sections, lc_ending_standup_drain. The Flood: lc_ending_flood_attack_from (when the ichthyosaurs start biting), lc_ending_flood_boats (rowboats), each player's lc_headbang_angle (Father Grigori's nod). The Plane: lc_ending_plane_model_yaw (if it flies sideways). Marrow: lc_ending_marrow_crowd. Any ending: lc_ending_bodies (bodies left lying), lc_ending_edict_limit (spawning stops near the server's entity limit). Bloom: each player's lc_bloom_palm (-90 if the palms face backwards). Shalom (the hora): lc_ending_shalom_sections, lc_ending_shalom_candles (when each of the hanukkiah's candles is lit), lc_ending_shalom_lift_beats (how often someone is lifted up on a chair), lc_ending_shalom_sayings (extra sayings shown over heads, separated by |); each player's lc_shalom_pose tunes the dance's arms and lc_shalom_kippah where the kippah sits. Fire (behinds on fire, then flying on them): lc_ending_fire_sections (seconds:ignite|hop|fly|launch|end), lc_ending_fire_hop (how high the hops are), lc_ending_fire_fly_speed, lc_ending_fire_crowd; the flying pose is tuned in the Endings menu (Pelvis tilts the whole body).",
    "Freq 7 (the pirate broadcast): voice lines and songs take turns, and warnings cut in. The Combine jam it every lc_freq7_hold minutes on green (faster on yellow and red, never during a blackout). Recordings go in the sound addon's radio/ folder. lc_freq7_status shows where it is.",
    "Morning exercise: use the editor to place a jogging route (stops in order; the first is the start), an exercise yard (stand where the rows will be, and aim at the leader's spot) and a parade route (stops in order). Every lc_exercise_every dawns (2), one of them runs, taking turns (lc_exercise_kinds). lc_exercise <jog|drill|parade> starts one now, lc_exercise next shows which is next, lc_exercise stop ends it.",
    "NPCs losing track of you in a chase? Path mapping (editor panel, Paths and doors, or !pathmap) places path nodes as you walk the streets, stairs and alleys, links them and saves them with the map. Noclip pauses it; lc_pathmap_undo removes the nodes placed this session.",
    "Every setting in the editor panel is saved with the map as soon as you change it, so your values survive a restart.",
    "Persistent props: spawn a prop, place it, and click it with the editor's Prop: make persistent. It's saved with the layout, frozen, and comes back every time the map loads.",
    "Rebel lookout post (editor point): an armed fighter guards that spot. Place it from the side the Combine would come from, so he faces that way.",
    "Bunk (editor point): a bed rebels sleep on. Mattresses, beds, couches, chairs, workbenches and crates inside rebel territory are found automatically.",
    "lc_rebel_errand sends a scavenging run out of the nearest rebel zone now; lc_rebel_react is how often the fighters go for supply drops and Overwatch landings.",
    "Tag the Combine's doors with Door: Civil Protection only and Civil Protection units are routed through them, even where the map's navigation was cut off by the door.",
    "The Living City Editor places everything: street furniture (bins, streetlights, loudspeakers, big screens, TVs), an incinerator for bodies, and a workplace for each Union job, plus loading docks, graffiti walls, rubble piles and leaky pipes for the jobs that use them.",
} }

local guide
function LC_GuideSections(admin)
    local sections = table.Copy(GUIDE)
    if admin then sections[#sections + 1] = ADMIN_GUIDE end
    return sections
end

local function OpenGuide(admin)
    if IsValid(guide) then guide:Remove() guide = nil return end -- F1 again closes it
    local sections = LC_GuideSections(admin)
    local f = vgui.Create("DFrame")
    guide = f
    f:SetTitle("")
    f:SetSize(math.min(ScrW() - 60, 900), math.min(ScrH() - 60, 600))
    f:Center()
    f:MakePopup()
    f.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(16, 15, 13, 245))
        draw.SimpleText("LIVING CITY: A GUIDE", "DermaLarge", 16, 12, ACCENT)
        draw.SimpleText("C > Guide opens this guide. Tips also pop up the first time something happens (C > Tips I've seen lists them all).", "DermaDefault", 16, 44, Color(150, 145, 130))
    end
    local search = vgui.Create("DTextEntry", f)
    search:SetPos(f:GetWide() - 276, 14)
    search:SetSize(260, 24)
    search:SetPlaceholderText("Search the guide")

    local list = vgui.Create("DScrollPanel", f)
    list:Dock(LEFT)
    list:SetWide(230)
    list:DockMargin(8, 46, 4, 8)
    local body = vgui.Create("DScrollPanel", f)
    body:Dock(FILL)
    body:DockMargin(4, 46, 8, 8)

    local function Line(text, col, font, indent)
        local l = vgui.Create("DLabel", body)
        l:Dock(TOP)
        l:DockMargin(indent or 4, font and 10 or 0, 4, 4)
        l:SetFont(font or "DermaDefault")
        l:SetTextColor(col or INK)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText(text)
        return l
    end

    local function ShowSection(sec)
        body:Clear()
        Line(string.upper(sec[1]), ACCENT, "DermaDefaultBold")
        for _, line in ipairs(sec[2]) do Line(line, INK, nil, 12) end
    end

    local function ShowSearch(q)
        body:Clear()
        q = string.lower(q)
        local found = 0
        for _, sec in ipairs(sections) do
            local head
            for _, line in ipairs(sec[2]) do
                if string.find(string.lower(line), q, 1, true) or string.find(string.lower(sec[1]), q, 1, true) then
                    if not head then head = Line(string.upper(sec[1]), ACCENT, "DermaDefaultBold") end
                    Line(line, INK, nil, 12)
                    found = found + 1
                end
            end
        end
        if found == 0 then Line("Nothing found for \"" .. q .. "\". Try a single word: cuffs, rent, curfew, fish...", Color(150, 145, 130)) end
    end

    for _, sec in ipairs(sections) do
        local b = vgui.Create("DButton", list)
        b:Dock(TOP)
        b:SetTall(26)
        b:DockMargin(0, 0, 0, 2)
        b:SetText(sec[1])
        b.DoClick = function() search:SetValue("") ShowSection(sec) end
    end
    search.OnChange = function(self)
        local q = string.Trim(self:GetValue() or "")
        if q == "" then ShowSection(sections[1]) else ShowSearch(q) end
    end
    ShowSection(sections[1])
end
LC_OpenGuide = OpenGuide
function LC_GuideOpen() return IsValid(guide) end
function LC_CloseGuide() if IsValid(guide) then guide:Remove() guide = nil end end

-- The server's answer to F1 (if it's bound to gm_showhelp) and to !help.
net.Receive("lcg_help", function()
    local admin = net.ReadBool()
    if IsValid(guide) and (guide.lcOpenedAt or 0) > CurTime() - 0.5 then return end -- the key already opened it
    if (LC_CL and LC_CL.ActionsOpenedAt or 0) > CurTime() - 0.5 then return end -- F1 opened a menu; the guide is in the full one
    OpenGuide(admin)
end)

concommand.Add("lc_help", function() OpenGuide(LocalPlayer():IsAdmin()) end)

-- F1 itself opens the quick menu (cl_livingcity_quick.lua); C opens the full menu, which has the
-- guide in it. With the guide open, F1 closes it.

-- Chat shows who people are in the city, not their Steam names.
hook.Add("OnPlayerChat", "LivingCityCharacterNames", function(ply, text, teamOnly, dead)
    if not IsValid(ply) then return end
    local name = ply:GetNW2String("lc_char", "")
    -- team chat (U): marked, so nobody takes it for something the whole street heard
    if teamOnly then
        chat.AddText(Color(120, 200, 140), "(Team) ", Color(150, 170, 200), name ~= "" and name or ply:Nick(), color_white, ": " .. text)
        return true
    end
    if name == "" then return end
    chat.AddText(Color(150, 170, 200), name, color_white, ": " .. text)
    return true
end)
