# Living City announcement scripts

Draft lines for the Combine Overwatch (cold, terse) and the Administrator (a kindly parent with a dash of the cheerful host, who turns domineering as things get worse).

## Where the recordings go

Three flat folders in their own addon, so updates to the gamemode never touch them: `garrysmod/addons/livingcity_sound/sound/livingcity/announce/`

- `overwatch/`: the file's name starts with its trigger (`curfew1.wav`, `ambient2.wav`). Always the same cold voice.
- `administrator/`: the same, plus the tone: `firm`, `stern` or `furious` anywhere in the name is that tone (`curfew_firm1.wav`); no tone word is her warm one (`curfew1.wav`).
- `radio/`: `static1.wav`, `union1.wav`, `freq7_1.wav`.

`.wav`, `.mp3` or `.ogg`. One is picked each time, never the same twice running. A `.txt` with the same name is its subtitle. The longest trigger that fits wins, so `curfew_soon1.wav` is curfew_soon, not curfew.

**Only the routine is announced ahead.** Rations and curfew get a two-minute warning (`rations_soon`, `curfew_soon`). A sweep, a raid or a supply convoy is a surprise: the PA says nothing until it starts. A lockdown is never scheduled; it answers violence (the escalation reaching red alert, or the city falling into unrest).

**How she picks her tone:** each trigger has a usual tone (shown below). It goes up a step while the city is on red sociostability, and up again after a run of violence (three raids, skirmishes, breakouts, outbreaks or rebel gains in ten minutes is a step, six is two; warm triggers only escalate on red). Furious is the ceiling. If the tone she wants has no recordings she uses the nearest calmer one, then the nearest angrier one, so one warm take covers a trigger on its own.

In game (superadmin): `lc_announce_rescan` picks up new files, `lc_announce_clips` lists what it found, `lc_announce_say <overwatch|administrator> <trigger> [warm|firm|stern|furious]` plays one, `lc_announce_tier <trigger>` says which tone she'd use right now.

## rations

*Ration distribution begins at the queue lines.*

**Overwatch** (`overwatch/`):

- `rations1.wav`: Attention, citizens. Ration distribution is now in effect. Proceed to your nearest distribution point and form an orderly line. Have your identification ready.
- `rations2.wav`: Citizens, assemble for ration distribution. Compliance ensures your allocation. Disorder forfeits it.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `rations1.wav`: Good morning, everyone! Rations are ready, so do come along and queue nicely. There's plenty for those who wait their turn.
- `rations2.wav`: Come along, lovelies, your allocation is ready. Have your papers handy and mind the elbows in the line.

*Firm:*
- `rations_firm1.wav`: Now, I'm only going to say this once, and I'd like it to stick. Rations are for those who queue. Pushing will be remembered.

*Stern:*
- `rations_stern1.wav`: Rations will be stopped for any block that cannot behave itself. I mean that. Form a line, and keep it.

## rations_soon

*About two minutes before rations.*

**Overwatch** (`overwatch/`):

- `rations_soon1.wav`: Advisory. Ration distribution will begin shortly. Prepare your identification.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `rations_soon1.wav`: Rations in just a couple of minutes, everyone. Do start making your way over, and be kind to the person in front of you.

*Firm:*
- `rations_soon_firm1.wav`: Rations soon. Anyone causing trouble in the line can go without. I mean it.

## sweep

*An inspection sweep starts: units stop people and check papers.*

**Overwatch** (`overwatch/`):

- `sweep1.wav`: Attention, residents. Civil status inspections are in progress. Present your papers when requested. Evasion will be treated as a violation.
- `sweep2.wav`: Citizens, remain where you are and confirm your civil status to the nearest unit. Cooperation is noted.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `sweep_firm1.wav`: Good day, everyone. Civil status checks are under way. Papers out, please, and no fuss. It's far quicker for all of us.
- `sweep_firm2.wav`: A little spring cleaning today. Show the officers what they ask for, and we'll all be home for supper.

*Stern:*
- `sweep_stern1.wav`: Papers. Now. I won't have anyone making a game of this, and I'm quite sure you don't want me to take it personally.

*Furious:*
- `sweep_furious1.wav`: I have been patient. I have been generous. Anyone who obstructs these checks will answer to me, and you will not enjoy it.

## curfew

*Curfew begins; everyone must reach their housing block.*

**Overwatch** (`overwatch/`):

- `curfew1.wav`: Attention, citizens. Curfew is now in effect. Return to your assigned housing block immediately. Citizens found outside will be detained.
- `curfew2.wav`: Unrest procedure is now in effect. All residents proceed to their blocks. This is your only notice.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `curfew_firm1.wav`: Right then, everyone, it's time to head home. Curfew begins now. Lights down, doors locked, and no wandering about.
- `curfew_firm2.wav`: Off you go, now. Curfew is for your own good, and I would so hate to have to send someone to fetch you.

*Stern:*
- `curfew_stern1.wav`: I asked nicely. Curfew is in force and you are still outside. Go home this instant, or the officers will take you there.

*Furious:*
- `curfew_furious1.wav`: Is nobody listening? Curfew is in force! Every one of you, inside, NOW. I will not ask a third time.

## curfew_soon

*About two minutes before curfew.*

**Overwatch** (`overwatch/`):

- `curfew_soon1.wav`: Advisory. Curfew will be enforced shortly. Begin returning to your housing block now.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `curfew_soon_firm1.wav`: Evening, everyone. Curfew is only a couple of minutes away. Do start heading home, there's a good citizen.

*Stern:*
- `curfew_soon_stern1.wav`: Curfew is minutes away and I can still see some of you out there. Move. Do not make me say it twice.

## lockdown

*Full lockdown: more units, strict curfew, perimeter held.*

**Overwatch** (`overwatch/`):

- `lockdown1.wav`: Attention. Lockdown is in effect. All citizens proceed to their blocks and remain indoors. Movement outside will be met with force.
- `lockdown2.wav`: Security alert. The city is sealed. Remain in your residence until the all clear is given.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `lockdown_stern1.wav`: Everyone listen carefully. The city is closed. You will stay in your homes until I say otherwise, and not one of you will argue.
- `lockdown_stern2.wav`: This is not a request. Lockdown is in effect. Indoors, doors shut, and quiet. Those who test me will regret it.

*Furious:*
- `lockdown_furious1.wav`: That is quite enough! The city is locked down because some of you cannot be trusted with your freedom. Inside. Now. All of you.

## raid

*A housing block inspection (block raid) begins.*

**Overwatch** (`overwatch/`):

- `raid1.wav`: Attention, residents of this block. A housing inspection is in progress. Remain inside your residence and admit all units. Contraband will be confiscated.
- `raid2.wav`: Block inspection under way. Do not leave your residence. Obstruction will result in detention.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `raid_stern1.wav`: Residents of the block concerned, open your doors. This inspection will happen whether you cooperate or not, and I know which you will prefer.
- `raid_stern2.wav`: Everyone has had ample warning. Whatever you are hiding, I will find it. Step aside and let my officers work.

*Furious:*
- `raid_furious1.wav`: Do not insult me by pretending. Every drawer, every floorboard. You have brought this on yourselves, and you will sit quietly while it is undone.

## supply

*A Combine supply convoy or dropship arrives with stores.*

**Overwatch** (`overwatch/`):

- `supply1.wav`: Attention. A supply convoy is in transit. Civilians remain clear of the route. Unauthorised contact with Union stores is a violation.
- `supply2.wav`: Supply movement in progress. Stay clear of the designated drop zone.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `supply1.wav`: Good news, everyone! Supplies are on their way. Do keep clear of the route and let the nice drivers get on with it.
- `supply2.wav`: Deliveries today, lovelies. Stay out from under the wheels, and everyone gets their share.

*Firm:*
- `supply_firm1.wav`: A reminder that supplies belong to everyone, and taking from them means taking from your neighbours. I'd hate to have to remember who.

*Stern:*
- `supply_stern1.wav`: Touch those supplies and you will answer for it. Every crate is counted, and so is every person near one.

## ended

*A curfew or lockdown is over.*

**Overwatch** (`overwatch/`):

- `ended1.wav`: Sociostability restored. Curfew is lifted. Resume your assigned activities.
- `ended2.wav`: The incident is concluded. Citizens may return to normal movement. Remain compliant.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `ended1.wav`: There we are. Order is restored, and wasn't that better? Thank you all for your patience. You may go about your day.
- `ended2.wav`: Lovely. The restrictions are lifted. Well done, everyone. Let's try to keep it this way, shall we?

*Firm:*
- `ended_firm1.wav`: The restrictions are lifted. I would like it noted that they should never have been needed. Do better.

## jog

*The morning jog begins (every second dawn, in turn): citizens report to the start of the route.*

**Overwatch** (`overwatch/`):

- `jog1.wav`: Attention, citizens. Morning conditioning is now in effect. Report to the designated route. Maintain pace. Noncompliance will be corrected.
- `jog2.wav`: Physical readiness cycle in progress. Assemble at the starting point. Falling behind is a violation.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `jog1.wav`: Rise and shine, everyone! It's time for our morning jog. Make your way to the start, and do try to keep up. The officers will be cheering you on!
- `jog2.wav`: Good morning, lovelies! A brisk jog to start the day. Healthy bodies, healthy city. Off we go!

*Firm:*
- `jog_firm1.wav`: Jogging, everyone, not strolling. I can see who's dawdling. Pick up those feet.

*Stern:*
- `jog_stern1.wav`: I will not have this city crawling round its own streets. Run. Every one of you. The officers have their instructions.

## drill

*The morning drill begins: citizens report to the exercise yard and copy the leader.*

**Overwatch** (`overwatch/`):

- `drill1.wav`: Attention, citizens. Assume your positions in the exercise yard. Mirror all instruction. Errors are recorded.
- `drill2.wav`: Morning drill is in effect. Assemble. Comply with every movement. Deviation will be corrected.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `drill1.wav`: Good morning, everyone! Into the yard for our morning drill. Find your place, watch your leader, and copy every move. Isn't this fun?
- `drill2.wav`: Arms up, chins up! It's drill time, lovelies. A little skipping today, too. I do love a bit of skipping.

*Firm:*
- `drill_firm1.wav`: Concentrate, please. Crouch means crouch. Jump means jump. It isn't difficult, and I'm watching.

*Stern:*
- `drill_stern1.wav`: If you cannot follow a simple instruction in the yard, I wonder what else you cannot follow. Do it properly.

## parade

*The morning parade begins: citizens line the route and cheer the column.*

**Overwatch** (`overwatch/`):

- `parade1.wav`: Attention, citizens. A ceremonial procession is in effect. Line the designated route. Express your gratitude. Enthusiasm is mandatory.
- `parade2.wav`: Overwatch procession in progress. Citizens will display appropriate appreciation. Silence will be noted.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `parade1.wav`: Oh, what a morning! Our brave protectors are on parade today. Line the route, everyone, and let them hear how much you love them!
- `parade2.wav`: Flags out, voices up! The parade is coming through. Cheer loudly, lovelies. They do so like to be appreciated.

*Firm:*
- `parade_firm1.wav`: I'm hearing some very quiet cheering out there. Our protectors deserve better. Louder, please.

*Stern:*
- `parade_stern1.wav`: Silence on parade day is a statement, and I hear it very clearly. Cheer. Now. I want to hear you from my office.

## socio_green

*The city drops back to green (nominal).*

**Overwatch** (`overwatch/`):

- `socio_green1.wav`: Sociostability is nominal. Continue your assigned activities.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `socio_green1.wav`: Isn't that nice? The city is calm again. Thank you, everyone. You should be proud of yourselves.
- `socio_green2.wav`: All is well. You have all been wonderful. Let's keep it up!

## socio_yellow

*The city moves to yellow (marginal): more stops.*

**Overwatch** (`overwatch/`):

- `socio_yellow1.wav`: Sociostability is marginal. Expect increased civil status checks.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `socio_yellow_firm1.wav`: Now, I'm starting to notice some restlessness out there, and I'd like it to stop. Let's all take a breath and behave, shall we?
- `socio_yellow_firm2.wav`: Things are getting a little untidy, everyone. I'd be so disappointed if I had to step in.

*Stern:*
- `socio_yellow_stern1.wav`: The mood in this city is slipping, and I do not like it. Whoever is stirring things up, stop. You have been warned.

## socio_red

*The city moves to red (judgment waiver).*

**Overwatch** (`overwatch/`):

- `socio_red1.wav`: Sociostability is critical. Judgment waiver is in effect. Units are authorised to use force.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `socio_red_stern1.wav`: That is enough. The city has slipped into disorder, and I will have it back. My officers are authorised to do whatever is required.
- `socio_red_stern2.wav`: I am very disappointed in all of you. Order has broken down, and the consequences will not be gentle.

*Furious:*
- `socio_red_furious1.wav`: You have pushed me too far! Order will be restored, and every one of you who stands in the way will regret it!

## dawn

*Dawn: the light comes up.*

**Overwatch** (`overwatch/`):

- `dawn1.wav`: Attention. A new work cycle begins. Report to your assigned workplace.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `dawn1.wav`: Good morning, everyone! A fresh new day. Off to work with you. Quotas first, and the Union will see to the rest.
- `dawn2.wav`: Rise and shine, lovelies. Another day ahead of us, and so much to be getting on with.

*Firm:*
- `dawn_firm1.wav`: Good morning. I do hope everyone has slept on their manners. Work cycle begins.

## day

*Full day begins.*

**Overwatch** (`overwatch/`):

- `day1.wav`: Work cycle in progress. Productivity is expected.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `day1.wav`: It's a lovely day, everyone, and there is plenty to do. Keep at it, you're doing marvellously.
- `day2.wav`: Hello again, citizens! Just a gentle reminder that a busy city is a happy city.

*Firm:*
- `day_firm1.wav`: The work cycle is in full swing. Idle hands are noticed, I'm afraid. Do keep busy.

## dusk

*Dusk: evening falls.*

**Overwatch** (`overwatch/`):

- `dusk1.wav`: Advisory. Evening is approaching. Plan your return to your residence.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `dusk1.wav`: Evening is drawing in, everyone. Do think about heading home soon, and take someone's arm if you're walking in the dark.
- `dusk2.wav`: Another day nearly done. Well done, all of you. Time to think about supper.

*Firm:*
- `dusk_firm1.wav`: Evening is here. Anyone still out should be making for home. Don't dawdle.

## night

*Night falls: dark streets, curfew likelier.*

**Overwatch** (`overwatch/`):

- `night1.wav`: Attention. Night cycle is in effect. Non-essential movement is discouraged.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `night1.wav`: Goodnight, everyone. Sleep well and lock your doors. I'll be watching over you all.
- `night2.wav`: Sweet dreams, lovelies. We'll do it all again tomorrow.

*Firm:*
- `night_firm1.wav`: It is night. Streets are for officers now. Be indoors, and do not make me come looking for you.

## outbreak

*A parasite or infestation outbreak begins.*

**Overwatch** (`overwatch/`):

- `outbreak1.wav`: Warning. Biological containment breach detected. Avoid the affected area. Report symptoms to a unit immediately.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `outbreak_firm1.wav`: Now, don't panic, but there has been a little biological trouble in the city. Avoid the area, and tell an officer if you feel unwell.
- `outbreak_firm2.wav`: A small health matter, everyone. Keep calm and keep away from the affected streets. We will deal with it.

*Stern:*
- `outbreak_stern1.wav`: There is an outbreak, and I expect sense from every one of you. Stay clear, report symptoms at once, and do not play the hero.

*Furious:*
- `outbreak_furious1.wav`: This is an outbreak! Stay away from the infested areas and OBEY the officers. Panic will cost lives, and I will not tolerate it!

## blackout

*Power fails across the city.*

**Overwatch** (`overwatch/`):

- `blackout1.wav`: Warning. Power grid failure. Remain where you are. Looting will be met with force.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `blackout_firm1.wav`: Oh dear, the lights have gone out. Stay calm and stay where you are. We are working on it, and it will be back before you know it.
- `blackout_firm2.wav`: A small power problem, everyone. Please be sensible and don't wander about in the dark.

*Stern:*
- `blackout_stern1.wav`: The power is out and I will not tolerate looting. Stay where you are. Anyone using the dark as cover will be dealt with.

## power_restored

*The power comes back on.*

**Overwatch** (`overwatch/`):

- `power_restored1.wav`: Power restored. Resume your assigned activities.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `power_restored1.wav`: And there we are! The lights are back on. Thank you for being so patient, everyone. You've been very good.

## skirmish_raid

*Rebels raid a checkpoint or patrol.*

**Overwatch** (`overwatch/`):

- `skirmish_raid1.wav`: Alert. Hostile activity reported. Civilians clear the area. Units, engage.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `skirmish_raid_stern1.wav`: Fighting has broken out. Civilians, get away from the area at once. To those who started this: you will not enjoy how it ends.

*Furious:*
- `skirmish_raid_furious1.wav`: This violence will STOP! The people responsible will be hunted down and made to answer. Everyone else, get out of the way!

## skirmish_sweep

*Civil Protection sweeps into rebel territory.*

**Overwatch** (`overwatch/`):

- `skirmish_sweep1.wav`: Security operation in progress. Avoid the affected sector.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `skirmish_sweep_stern1.wav`: Officers are clearing a sector of troublemakers. Keep away from it. This is what happens when one is given every chance and wastes it.

*Furious:*
- `skirmish_sweep_furious1.wav`: Enough! My officers are going in, and anyone sheltering those inside will go in with them!

## response

*An Overwatch response squad is dispatched.*

**Overwatch** (`overwatch/`):

- `response1.wav`: Alert. Response team deployed. Nonessential personnel clear the area.
- `response2.wav`: Overwatch response in progress. Compliance is mandatory.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `response_stern1.wav`: A response team is on its way. I do not enjoy sending them, but you have left me no choice. Clear the area.
- `response_stern2.wav`: Help is coming, to those who obey, and something rather different to those who do not.

*Furious:*
- `response_furious1.wav`: I have sent for the response team, and I hope you are all proud of yourselves. Get out of their way!

## breakout

*A prisoner is broken out by the Resistance.*

**Overwatch** (`overwatch/`):

- `breakout1.wav`: Alert. Prisoner escape detected. Units, locate and detain. Aiding an escapee is a capital violation.

**The Administrator** (`administrator/`), usually **furious**:

*Furious:*
- `breakout_furious1.wav`: A prisoner has escaped, and whoever helped him will answer to me personally. Find him. Hide him, and I will find you.
- `breakout_furious2.wav`: You have seriously misjudged me. Every one of you who touches this escape will be made to regret it. Bring them back!

## overwatch_drop

*An Overwatch dropship deploys soldiers.*

**Overwatch** (`overwatch/`):

- `overwatch_drop1.wav`: Overwatch deployment in progress. Stand clear of the landing zone.

**The Administrator** (`administrator/`), usually **stern**:

*Stern:*
- `overwatch_drop_stern1.wav`: The Overwatch troops are arriving. Stay clear of them, citizens. They are not as patient as I am.
- `overwatch_drop_stern2.wav`: Soldiers are landing in the city. I wanted so much to avoid this. Keep indoors and do exactly as they say.

*Furious:*
- `overwatch_drop_furious1.wav`: Overwatch is on the ground. Anyone who raises a hand to them will be put down. I have warned you, over and over!

## block_raided

*A block raid finishes.*

**Overwatch** (`overwatch/`):

- `block_raided1.wav`: Housing inspection complete. Confiscated items are recorded. Violations will be addressed.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `block_raided_firm1.wav`: The inspection is finished. I hope those residents have learned something. An open door is so much more comfortable than a broken one.
- `block_raided_firm2.wav`: All done. Thank you to those who were helpful. As for the others, we shall be having a talk.

*Stern:*
- `block_raided_stern1.wav`: The block has been searched, and what was found has been taken. I am deeply disappointed. Let this be a lesson to the whole street.

## territory_grew

*The Resistance take more ground.*

**Overwatch** (`overwatch/`):

- `territory_grew1.wav`: Warning. Unauthorised occupation of a sector reported. Citizens avoid the area.

**The Administrator** (`administrator/`), usually **firm**:

*Firm:*
- `territory_grew_firm1.wav`: I've been informed that some troublemakers are setting up house in one of our streets. Stay away from them, there's a good citizen.
- `territory_grew_firm2.wav`: A group of vagrants has staked out a corner. Please don't encourage them. It won't end well for them, and it won't end well for you.

*Stern:*
- `territory_grew_stern1.wav`: Part of this city has been seized by criminals. If you help them, you are one of them. I want that understood.

*Furious:*
- `territory_grew_furious1.wav`: They think they can take my streets from me? Anyone who feeds, hides, or helps those rebels will be treated as one of them!

## train_arrival

*A train brings new arrivals.*

**Overwatch** (`overwatch/`):

- `train_arrival1.wav`: Attention. A transport has arrived. New residents report for processing.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `train_arrival1.wav`: Welcome, everyone, to your new home! A train has arrived. New arrivals, please report to the officers and they will get you settled in.
- `train_arrival2.wav`: Come along, newcomers, don't be shy. It's a big change, I know. We'll look after you.

*Firm:*
- `train_arrival_firm1.wav`: New arrivals, report for processing. Follow instructions and you'll do very well here.

## welcome

*A few seconds after a player joins (or starts a new character), only they hear it, always. The Administrator speaks first, then Overwatch as soon as she finishes.*

**Overwatch** (`overwatch/`):

- `welcome1.wav`: Welcome to City 14. Your identification has been registered. Comply and you will be well treated.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `welcome1.wav`: Welcome to the city, dear. I'm the Administrator. Do keep your papers with you, be kind to your neighbours, and you'll get on splendidly.
- `welcome2.wav`: Hello and welcome! I'm so glad you're here. We all look after each other in this city. Do come to me if there's trouble.

## ambient

*Random city announcements, and what Dr. Breen's periodic addresses are made of.*

**Overwatch** (`overwatch/`):

- `ambient1.wav`: Citizens, report any anti-social behaviour to your nearest unit.
- `ambient2.wav`: Inaction is conspiracy. Report suspicious activity immediately.
- `ambient3.wav`: Remember: cooperation is the foundation of stability.

**The Administrator** (`administrator/`), usually **warm**:

*Warm:*
- `ambient1.wav`: Just a little reminder, everyone: be kind to your neighbours, and tell an officer if something troubles you.
- `ambient2.wav`: Remember, a tidy home is a happy home. Keep your papers safe and your manners sharper.
- `ambient3.wav`: A gentle word to anyone feeling low: there is always a place for you, as long as you stay on the right side of the rules.

*Firm:*
- `ambient_firm1.wav`: Something I've noticed lately: people forgetting their manners. I do hope that's not catching.

*Stern:*
- `ambient_stern1.wav`: Let me be perfectly clear. I am fond of you, but my patience is not endless. Behave.

## radio

**Freq 7** (`radio/`), a tired, careful voice, a little too close to the mic:

- `freq7_1.wav`: This is Freq 7. They count the rations and they count you. Count them back.
- `freq7_2.wav`: The third shift at the station is short two units on Tuesdays. Freq 7, out.
- `freq7_3.wav`: If you can hear this, you are not alone. Freq 7.
- `freq7_4.wav`: The Administrator's broadcasts are recorded. She is not in the city.
- `freq7_5.wav`: Block 4: the inspection is tomorrow. Whatever you're keeping, keep it somewhere else.
- `freq7_6.wav`: Don't answer this. Just listen. And then turn it back to the Union band.
- `freq7_7.wav`: Good evening to everyone the Combine says doesn't exist. This one's for you.
- `freq7_8.wav`: A reminder from the people keeping this signal alive: never carry anything you can't explain. Papers in your pocket. The rest under the floor.
- `freq7_9.wav`: They tell you the ration is generous. Count the grams. Then count the guards. Then you'll know who it's really for.
- `freq7_10.wav`: If a friend stops showing up at the dispenser, don't ask about them out loud. Ask us. Freq Seven remembers names.
- `freq7_11.wav`: Scanners photograph faces, not hearts. Keep your head down, and keep your heart where it is.
- `freq7_12.wav`: To whoever keeps leaving bread by the canal: we see you. Thank you.
- `freq7_13.wav`: Somebody once owned these records. Somebody once danced to them. We'll keep playing them until they make us stop.
- `freq7_14.wav`: Stay off the main roads after dusk. And if a unit asks where you heard that, you didn't.
- `freq7_15.wav`: We're moving the transmitter again tonight. If the signal drops, wait. We always come back.
- `freq7_16.wav`: They count everything. Grams. Hours. People. Here's one thing they can't count: how many of us are listening right now.
- `freq7_17.wav`: Here's one from before the sky went grey. Close your eyes. Three minutes. They can't take that.
- `freq7_18.wav`: Something from the old world. Mind the volume, and mind the window.
- `freq7_19.wav`: Still here. Still broadcasting. Still not sorry. Here's a song.
- `freq7_20.wav`: Frequency Seven. You know the rule. Add it up, and you'll always find us.

Voice lines and songs take turns, so every voice line is followed by a song (several of these introduce one).

**Freq 7's songs** (`radio/`): `freq7_song_<anything>.ogg`, as many as you like. Public domain recordings only: a modern performance of an old tune is still protected, so look for recordings published before 1926 (public domain in the US and in Ireland/the EU) on the Internet Archive (the Great 78 Project), the Library of Congress National Jukebox, or Wikimedia Commons. Scott Joplin piano rolls, 1910s parlour ballads, early jazz and Caruso all suit it. Save them as `.ogg` or `.wav`.

**Freq 7's warnings** (`radio/`), cutting in at once, even mid-song:

- `freq7_sweep1.wav` (two minutes before a papers sweep): Heads up. Units are gearing up for papers checks. If it isn't yours or it isn't legal, it shouldn't be on you. Move it now.
- `freq7_sweep2.wav`: Inspection teams heading out. Clean pockets, clean story.
- `freq7_raid1.wav` (two minutes before a block raid): Housing block inspection coming. They'll go through every room, and anything they find gets traced back. Get it out, or get out.
- `freq7_curfew1.wav` (two minutes before curfew): Curfew's coming. Runners, this is your window. Everyone else, get home.
- `freq7_supply1.wav` (two minutes before a supply convoy): Combine convoy coming through. Lots of crates, not many guards. Just saying.
- `freq7_incursion1.wav` (Civil Protection sweeping into rebel territory): They're coming into our streets. Fighters to the barricades. Everyone else, get below ground. Now.
- `freq7_incursion2.wav`: Boots on our side of the line. This is not a drill. Go.
- `freq7_lockdown1.wav` (a lockdown declared): That's a lockdown. Get indoors, keep off this frequency for a while, and wait for us. We'll be back.
- `freq7_dropship1.wav` (an Overwatch dropship coming in): Dropship inbound. That's Overwatch, not the metrocops. Don't be a hero. Be gone.

**The jamming** (`radio/jam1.wav`): no script. A harsh, looping electronic whine, heard where the Combine found Freq 7 while it's dark.

**Static** (`static1.wav`...) and **the Union band** (`union1.wav`...): no script. Static is any long, loopable radio hiss; the Union band can be any long, loopable bland station (with none, the Administrator's ambient recordings play there).
