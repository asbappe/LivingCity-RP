# Living City announcement scripts

Draft lines for the Combine Overwatch (cold, terse) and the Administrator (a kindly parent with a dash of the cheerful host, who turns domineering as things get worse). Every trigger is a folder; the same lines are in each folder's README.txt.

## Where the recordings go

Your recordings live in their own addon, so updates to the gamemode never touch them:

- Overwatch: `garrysmod/addons/livingcity_sound/sound/livingcity/announce/overwatch/<trigger>/`. Always the same cold voice.
- The Administrator: `garrysmod/addons/livingcity_sound/sound/livingcity/announce/administrator/<trigger>/`. **The tone is in the file name:** a name with `firm`, `stern` or `furious` in it is that tone (`curfew_firm_01.wav`); any other name is her warm one (`curfew_01.wav`).

`.wav`, `.mp3` or `.ogg`. Put as many in a folder as you like; one is picked each time, never the same twice running. A `.txt` with the same name as a sound is its subtitle. The suggested file names below follow the rule; any name works as long as the tone word is in it.

**How she picks her tone:** each trigger has a usual tone (shown below). It goes up a step while the city is on red sociostability, and up again after a run of violence (three raids, skirmishes, breakouts, outbreaks or rebel gains in ten minutes is a step, six is two; warm triggers only escalate on red). Furious is the ceiling. If the tone she wants has no recordings she uses the nearest calmer one, then the nearest angrier one, so one warm take covers a trigger on its own.

In game (superadmin): `lc_announce_rescan` picks up new files, `lc_announce_clips` lists what it found, `lc_announce_say <overwatch|administrator> <trigger> [warm|firm|stern|furious]` plays one, `lc_announce_tier <trigger>` says which tone she'd use right now.

## rations

*Ration distribution begins at the queue lines.*

**Overwatch** (`overwatch/rations/`):

- `rations_01.wav`: Attention, citizens. Ration distribution is now in effect. Proceed to your nearest distribution point and form an orderly line. Have your identification ready.
- `rations_02.wav`: Citizens, assemble for ration distribution. Compliance ensures your allocation. Disorder forfeits it.

**The Administrator** (`administrator/rations/`), usually **warm**:

*Warm:*
- `rations_01.wav`: Good morning, everyone! Rations are ready, so do come along and queue nicely. There's plenty for those who wait their turn.
- `rations_02.wav`: Come along, lovelies, breakfast is served. Have your papers handy and mind the elbows in the line.

*Firm:*
- `rations_firm_01.wav`: Now, I'm only going to say this once, and I'd like it to stick. Rations are for those who queue. Pushing will be remembered.

*Stern:*
- `rations_stern_01.wav`: Rations will be stopped for any block that cannot behave itself. I mean that. Form a line, and keep it.

## rations_soon

*About two minutes before rations.*

**Overwatch** (`overwatch/rations_soon/`):

- `rations_soon_01.wav`: Advisory. Ration distribution will begin shortly. Prepare your identification.

**The Administrator** (`administrator/rations_soon/`), usually **warm**:

*Warm:*
- `rations_soon_01.wav`: Rations in just a couple of minutes, everyone. Do start making your way over, and be kind to the person in front of you.

*Firm:*
- `rations_soon_firm_01.wav`: Rations soon. Anyone causing trouble in the line can go without. I mean it.

## sweep

*An inspection sweep starts: units stop people and check papers.*

**Overwatch** (`overwatch/sweep/`):

- `sweep_01.wav`: Attention, residents. Civil status inspections are in progress. Present your papers when requested. Evasion will be treated as a violation.
- `sweep_02.wav`: Citizens, remain where you are and confirm your civil status to the nearest unit. Cooperation is noted.

**The Administrator** (`administrator/sweep/`), usually **firm**:

*Firm:*
- `sweep_firm_01.wav`: Good day, everyone. Civil status checks are under way. Papers out, please, and no fuss. It's far quicker for all of us.
- `sweep_firm_02.wav`: A little spring cleaning today. Show the officers what they ask for, and we'll all be home for supper.

*Stern:*
- `sweep_stern_01.wav`: Papers. Now. I won't have anyone making a game of this, and I'm quite sure you don't want me to take it personally.

*Furious:*
- `sweep_furious_01.wav`: I have been patient. I have been generous. Anyone who obstructs these checks will answer to me, and you will not enjoy it.

## sweep_soon

*About two minutes before an inspection sweep.*

**Overwatch** (`overwatch/sweep_soon/`):

- `sweep_soon_01.wav`: Advisory. Civil status inspections will begin shortly. Have your papers prepared.

**The Administrator** (`administrator/sweep_soon/`), usually **warm**:

*Warm:*
- `sweep_soon_01.wav`: A little reminder, everyone: checks will be starting shortly. Have your papers to hand and this will be painless.

*Firm:*
- `sweep_soon_firm_01.wav`: Checks begin in minutes. If your papers are not in order, I suggest you sort that out now, and not when an officer is looking at you.

## curfew

*Curfew begins; everyone must reach their housing block.*

**Overwatch** (`overwatch/curfew/`):

- `curfew_01.wav`: Attention, citizens. Curfew is now in effect. Return to your assigned housing block immediately. Citizens found outside will be detained.
- `curfew_02.wav`: Unrest procedure is now in effect. All residents proceed to their blocks. This is your only notice.

**The Administrator** (`administrator/curfew/`), usually **firm**:

*Firm:*
- `curfew_firm_01.wav`: Right then, everyone, it's time to head home. Curfew begins now. Lights down, doors locked, and no wandering about.
- `curfew_firm_02.wav`: Off you go, now. Curfew is for your own good, and I would so hate to have to send someone to fetch you.

*Stern:*
- `curfew_stern_01.wav`: I asked nicely. Curfew is in force and you are still outside. Go home this instant, or the officers will take you there.

*Furious:*
- `curfew_furious_01.wav`: Is nobody listening? Curfew is in force! Every one of you, inside, NOW. I will not ask a third time.

## curfew_soon

*About two minutes before curfew.*

**Overwatch** (`overwatch/curfew_soon/`):

- `curfew_soon_01.wav`: Advisory. Curfew will be enforced shortly. Begin returning to your housing block now.

**The Administrator** (`administrator/curfew_soon/`), usually **firm**:

*Firm:*
- `curfew_soon_firm_01.wav`: Evening, everyone. Curfew is only a couple of minutes away. Do start heading home, there's a good citizen.

*Stern:*
- `curfew_soon_stern_01.wav`: Curfew is minutes away and I can still see some of you out there. Move. Do not make me say it twice.

## lockdown

*Full lockdown: more units, strict curfew, perimeter held.*

**Overwatch** (`overwatch/lockdown/`):

- `lockdown_01.wav`: Attention. Lockdown is in effect. All citizens proceed to their blocks and remain indoors. Movement outside will be met with force.
- `lockdown_02.wav`: Security alert. The city is sealed. Remain in your residence until the all clear is given.

**The Administrator** (`administrator/lockdown/`), usually **stern**:

*Stern:*
- `lockdown_stern_01.wav`: Everyone listen carefully. The city is closed. You will stay in your homes until I say otherwise, and not one of you will argue.
- `lockdown_stern_02.wav`: This is not a request. Lockdown is in effect. Indoors, doors shut, and quiet. Those who test me will regret it.

*Furious:*
- `lockdown_furious_01.wav`: That is quite enough! The city is locked down because some of you cannot be trusted with your freedom. Inside. Now. All of you.

## lockdown_soon

*About two minutes before lockdown.*

**Overwatch** (`overwatch/lockdown_soon/`):

- `lockdown_soon_01.wav`: Warning. Lockdown procedures are imminent. Proceed indoors.

**The Administrator** (`administrator/lockdown_soon/`), usually **firm**:

*Firm:*
- `lockdown_soon_firm_01.wav`: Everyone, please listen. A lockdown is coming very shortly. Get yourselves indoors and stay there.

*Stern:*
- `lockdown_soon_stern_01.wav`: Lockdown in minutes. If you are outside when it falls, that is entirely your own doing. Get inside.

*Furious:*
- `lockdown_soon_furious_01.wav`: Get off the streets! Lockdown is about to fall, and I will not be responsible for what happens to those still out there!

## raid

*A housing block inspection (block raid) begins.*

**Overwatch** (`overwatch/raid/`):

- `raid_01.wav`: Attention, residents of this block. A housing inspection is in progress. Remain inside your residence and admit all units. Contraband will be confiscated.
- `raid_02.wav`: Block inspection under way. Do not leave your residence. Obstruction will result in detention.

**The Administrator** (`administrator/raid/`), usually **stern**:

*Stern:*
- `raid_stern_01.wav`: Residents of the block concerned, open your doors. This inspection will happen whether you cooperate or not, and I know which you will prefer.
- `raid_stern_02.wav`: Everyone has had ample warning. Whatever you are hiding, I will find it. Step aside and let my officers work.

*Furious:*
- `raid_furious_01.wav`: Do not insult me by pretending. Every drawer, every floorboard. You have brought this on yourselves, and you will sit quietly while it is undone.

## raid_soon

*About two minutes before a block inspection.*

**Overwatch** (`overwatch/raid_soon/`):

- `raid_soon_01.wav`: Advisory. A housing inspection will begin shortly in a nearby block. Remain at your residence.

**The Administrator** (`administrator/raid_soon/`), usually **firm**:

*Firm:*
- `raid_soon_firm_01.wav`: A word to one of our blocks. Inspectors will be calling soon. I'd tidy up if I were you, and perhaps do some thinking.

*Stern:*
- `raid_soon_stern_01.wav`: Inspectors are almost at your door. If there is anything you ought to hand over, this is the last chance to do it quietly.

## supply

*A Combine supply convoy or dropship arrives with stores.*

**Overwatch** (`overwatch/supply/`):

- `supply_01.wav`: Attention. A supply convoy is in transit. Civilians remain clear of the route. Unauthorised contact with Union stores is a violation.
- `supply_02.wav`: Supply movement in progress. Stay clear of the designated drop zone.

**The Administrator** (`administrator/supply/`), usually **warm**:

*Warm:*
- `supply_01.wav`: Good news, everyone! Supplies are on their way. Do keep clear of the route and let the nice drivers get on with it.
- `supply_02.wav`: Deliveries today, lovelies. Stay out from under the wheels, and everyone gets their share.

*Firm:*
- `supply_firm_01.wav`: A reminder that supplies belong to everyone, and taking from them means taking from your neighbours. I'd hate to have to remember who.

*Stern:*
- `supply_stern_01.wav`: Touch those supplies and you will answer for it. Every crate is counted, and so is every person near one.

## supply_soon

*About two minutes before a supply drop.*

**Overwatch** (`overwatch/supply_soon/`):

- `supply_soon_01.wav`: Advisory. A supply convoy will pass through the city shortly. Keep the route clear.

**The Administrator** (`administrator/supply_soon/`), usually **warm**:

*Warm:*
- `supply_soon_01.wav`: Deliveries are due shortly, everyone. Stand back from the road and let them through, please.

*Firm:*
- `supply_soon_firm_01.wav`: Supplies arrive shortly. They are counted, and so are the people nearby. Think on that.

## ended

*A curfew or lockdown is over.*

**Overwatch** (`overwatch/ended/`):

- `ended_01.wav`: Sociostability restored. Curfew is lifted. Resume your assigned activities.
- `ended_02.wav`: The incident is concluded. Citizens may return to normal movement. Remain compliant.

**The Administrator** (`administrator/ended/`), usually **warm**:

*Warm:*
- `ended_01.wav`: There we are. Order is restored, and wasn't that better? Thank you all for your patience. You may go about your day.
- `ended_02.wav`: Lovely. The restrictions are lifted. Well done, everyone. Let's try to keep it this way, shall we?

*Firm:*
- `ended_firm_01.wav`: The restrictions are lifted. I would like it noted that they should never have been needed. Do better.

## socio_green

*The city drops back to green (nominal).*

**Overwatch** (`overwatch/socio_green/`):

- `socio_green_01.wav`: Sociostability is nominal. Continue your assigned activities.

**The Administrator** (`administrator/socio_green/`), usually **warm**:

*Warm:*
- `socio_green_01.wav`: Isn't that nice? The city is calm again. Thank you, everyone. You should be proud of yourselves.
- `socio_green_02.wav`: All is well. You have all been wonderful. Let's keep it up!

## socio_yellow

*The city moves to yellow (marginal): more stops.*

**Overwatch** (`overwatch/socio_yellow/`):

- `socio_yellow_01.wav`: Sociostability is marginal. Expect increased civil status checks.

**The Administrator** (`administrator/socio_yellow/`), usually **firm**:

*Firm:*
- `socio_yellow_firm_01.wav`: Now, I'm starting to notice some restlessness out there, and I'd like it to stop. Let's all take a breath and behave, shall we?
- `socio_yellow_firm_02.wav`: Things are getting a little untidy, everyone. I'd be so disappointed if I had to step in.

*Stern:*
- `socio_yellow_stern_01.wav`: The mood in this city is slipping, and I do not like it. Whoever is stirring things up, stop. You have been warned.

## socio_red

*The city moves to red (judgment waiver).*

**Overwatch** (`overwatch/socio_red/`):

- `socio_red_01.wav`: Sociostability is critical. Judgment waiver is in effect. Units are authorised to use force.

**The Administrator** (`administrator/socio_red/`), usually **stern**:

*Stern:*
- `socio_red_stern_01.wav`: That is enough. The city has slipped into disorder, and I will have it back. My officers are authorised to do whatever is required.
- `socio_red_stern_02.wav`: I am very disappointed in all of you. Order has broken down, and the consequences will not be gentle.

*Furious:*
- `socio_red_furious_01.wav`: You have pushed me too far! Order will be restored, and every one of you who stands in the way will regret it!

## dawn

*Dawn: the light comes up.*

**Overwatch** (`overwatch/dawn/`):

- `dawn_01.wav`: Attention. A new work cycle begins. Report to your assigned workplace.

**The Administrator** (`administrator/dawn/`), usually **warm**:

*Warm:*
- `dawn_01.wav`: Good morning, everyone! A fresh new day. Off to work with you, and do have something to eat first.
- `dawn_02.wav`: Rise and shine, lovelies. Another day ahead of us, and so much to be getting on with.

*Firm:*
- `dawn_firm_01.wav`: Good morning. I do hope everyone has slept on their manners. Work cycle begins.

## day

*Full day begins.*

**Overwatch** (`overwatch/day/`):

- `day_01.wav`: Work cycle in progress. Productivity is expected.

**The Administrator** (`administrator/day/`), usually **warm**:

*Warm:*
- `day_01.wav`: It's a lovely day, everyone, and there is plenty to do. Keep at it, you're doing marvellously.
- `day_02.wav`: Hello again, citizens! Just a gentle reminder that a busy city is a happy city.

*Firm:*
- `day_firm_01.wav`: The work cycle is in full swing. Idle hands are noticed, I'm afraid. Do keep busy.

## dusk

*Dusk: evening falls.*

**Overwatch** (`overwatch/dusk/`):

- `dusk_01.wav`: Advisory. Evening is approaching. Plan your return to your residence.

**The Administrator** (`administrator/dusk/`), usually **warm**:

*Warm:*
- `dusk_01.wav`: Evening is drawing in, everyone. Do think about heading home soon, and take someone's arm if you're walking in the dark.
- `dusk_02.wav`: Another day nearly done. Well done, all of you. Time to think about supper.

*Firm:*
- `dusk_firm_01.wav`: Evening is here. Anyone still out should be making for home. Don't dawdle.

## night

*Night falls: dark streets, curfew likelier.*

**Overwatch** (`overwatch/night/`):

- `night_01.wav`: Attention. Night cycle is in effect. Non-essential movement is discouraged.

**The Administrator** (`administrator/night/`), usually **warm**:

*Warm:*
- `night_01.wav`: Goodnight, everyone. Sleep well and lock your doors. I'll be watching over you all.
- `night_02.wav`: Sweet dreams, lovelies. We'll do it all again tomorrow.

*Firm:*
- `night_firm_01.wav`: It is night. Streets are for officers now. Be indoors, and do not make me come looking for you.

## outbreak

*A parasite or infestation outbreak begins.*

**Overwatch** (`overwatch/outbreak/`):

- `outbreak_01.wav`: Warning. Biological containment breach detected. Avoid the affected area. Report symptoms to a unit immediately.

**The Administrator** (`administrator/outbreak/`), usually **firm**:

*Firm:*
- `outbreak_firm_01.wav`: Now, don't panic, but there has been a little biological trouble in the city. Avoid the area, and tell an officer if you feel unwell.
- `outbreak_firm_02.wav`: A small health matter, everyone. Keep calm and keep away from the affected streets. We will deal with it.

*Stern:*
- `outbreak_stern_01.wav`: There is an outbreak, and I expect sense from every one of you. Stay clear, report symptoms at once, and do not play the hero.

*Furious:*
- `outbreak_furious_01.wav`: This is an outbreak! Stay away from the infested areas and OBEY the officers. Panic will cost lives, and I will not tolerate it!

## blackout

*Power fails across the city.*

**Overwatch** (`overwatch/blackout/`):

- `blackout_01.wav`: Warning. Power grid failure. Remain where you are. Looting will be met with force.

**The Administrator** (`administrator/blackout/`), usually **firm**:

*Firm:*
- `blackout_firm_01.wav`: Oh dear, the lights have gone out. Stay calm and stay where you are. We are working on it, and it will be back before you know it.
- `blackout_firm_02.wav`: A small power problem, everyone. Please be sensible and don't wander about in the dark.

*Stern:*
- `blackout_stern_01.wav`: The power is out and I will not tolerate looting. Stay where you are. Anyone using the dark as cover will be dealt with.

## power_restored

*The power comes back on.*

**Overwatch** (`overwatch/power_restored/`):

- `power_restored_01.wav`: Power restored. Resume your assigned activities.

**The Administrator** (`administrator/power_restored/`), usually **warm**:

*Warm:*
- `power_restored_01.wav`: And there we are! The lights are back on. Thank you for being so patient, everyone. You've been very good.

## skirmish_raid

*Rebels raid a checkpoint or patrol.*

**Overwatch** (`overwatch/skirmish_raid/`):

- `skirmish_raid_01.wav`: Alert. Hostile activity reported. Civilians clear the area. Units, engage.

**The Administrator** (`administrator/skirmish_raid/`), usually **stern**:

*Stern:*
- `skirmish_raid_stern_01.wav`: Fighting has broken out. Civilians, get away from the area at once. To those who started this: you will not enjoy how it ends.

*Furious:*
- `skirmish_raid_furious_01.wav`: This violence will STOP! The people responsible will be hunted down and made to answer. Everyone else, get out of the way!

## skirmish_sweep

*Civil Protection sweeps into rebel territory.*

**Overwatch** (`overwatch/skirmish_sweep/`):

- `skirmish_sweep_01.wav`: Security operation in progress. Avoid the affected sector.

**The Administrator** (`administrator/skirmish_sweep/`), usually **stern**:

*Stern:*
- `skirmish_sweep_stern_01.wav`: Officers are clearing a sector of troublemakers. Keep away from it. This is what happens when one is given every chance and wastes it.

*Furious:*
- `skirmish_sweep_furious_01.wav`: Enough! My officers are going in, and anyone sheltering those inside will go in with them!

## response

*An Overwatch response squad is dispatched.*

**Overwatch** (`overwatch/response/`):

- `response_01.wav`: Alert. Response team deployed. Nonessential personnel clear the area.
- `response_02.wav`: Overwatch response in progress. Compliance is mandatory.

**The Administrator** (`administrator/response/`), usually **stern**:

*Stern:*
- `response_stern_01.wav`: A response team is on its way. I do not enjoy sending them, but you have left me no choice. Clear the area.
- `response_stern_02.wav`: Help is coming, to those who obey, and something rather different to those who do not.

*Furious:*
- `response_furious_01.wav`: I have sent for the response team, and I hope you are all proud of yourselves. Get out of their way!

## breakout

*A prisoner is broken out by the Resistance.*

**Overwatch** (`overwatch/breakout/`):

- `breakout_01.wav`: Alert. Prisoner escape detected. Units, locate and detain. Aiding an escapee is a capital violation.

**The Administrator** (`administrator/breakout/`), usually **furious**:

*Furious:*
- `breakout_furious_01.wav`: A prisoner has escaped, and whoever helped him will answer to me personally. Find him. Hide him, and I will find you.
- `breakout_furious_02.wav`: You have seriously misjudged me. Every one of you who touches this escape will be made to regret it. Bring them back!

## overwatch_drop

*An Overwatch dropship deploys soldiers.*

**Overwatch** (`overwatch/overwatch_drop/`):

- `overwatch_drop_01.wav`: Overwatch deployment in progress. Stand clear of the landing zone.

**The Administrator** (`administrator/overwatch_drop/`), usually **stern**:

*Stern:*
- `overwatch_drop_stern_01.wav`: The Overwatch troops are arriving. Stay clear of them, citizens. They are not as patient as I am.
- `overwatch_drop_stern_02.wav`: Soldiers are landing in the city. I wanted so much to avoid this. Keep indoors and do exactly as they say.

*Furious:*
- `overwatch_drop_furious_01.wav`: Overwatch is on the ground. Anyone who raises a hand to them will be put down. I have warned you, over and over!

## block_raided

*A block raid finishes.*

**Overwatch** (`overwatch/block_raided/`):

- `block_raided_01.wav`: Housing inspection complete. Confiscated items are recorded. Violations will be addressed.

**The Administrator** (`administrator/block_raided/`), usually **firm**:

*Firm:*
- `block_raided_firm_01.wav`: The inspection is finished. I hope those residents have learned something. An open door is so much more comfortable than a broken one.
- `block_raided_firm_02.wav`: All done. Thank you to those who were helpful. As for the others, we shall be having a talk.

*Stern:*
- `block_raided_stern_01.wav`: The block has been searched, and what was found has been taken. I am deeply disappointed. Let this be a lesson to the whole street.

## territory_grew

*The Resistance take more ground.*

**Overwatch** (`overwatch/territory_grew/`):

- `territory_grew_01.wav`: Warning. Unauthorised occupation of a sector reported. Citizens avoid the area.

**The Administrator** (`administrator/territory_grew/`), usually **firm**:

*Firm:*
- `territory_grew_firm_01.wav`: I've been informed that some troublemakers are setting up house in one of our streets. Stay away from them, there's a good citizen.
- `territory_grew_firm_02.wav`: A group of vagrants has staked out a corner. Please don't encourage them. It won't end well for them, and it won't end well for you.

*Stern:*
- `territory_grew_stern_01.wav`: Part of this city has been seized by criminals. If you help them, you are one of them. I want that understood.

*Furious:*
- `territory_grew_furious_01.wav`: They think they can take my streets from me? Anyone who feeds, hides, or helps those rebels will be treated as one of them!

## train_arrival

*A train brings new arrivals.*

**Overwatch** (`overwatch/train_arrival/`):

- `train_arrival_01.wav`: Attention. A transport has arrived. New residents report for processing.

**The Administrator** (`administrator/train_arrival/`), usually **warm**:

*Warm:*
- `train_arrival_01.wav`: Welcome, everyone, to your new home! A train has arrived. New arrivals, please report to the officers and they will get you settled in.
- `train_arrival_02.wav`: Come along, newcomers, don't be shy. It's a big change, I know. We'll look after you.

*Firm:*
- `train_arrival_firm_01.wav`: New arrivals, report for processing. Follow instructions and you'll do very well here.

## welcome

*A few seconds after a player joins, only they hear it.*

**Overwatch** (`overwatch/welcome/`):

- `welcome_01.wav`: Welcome to City 14. Your identification has been registered. Comply and you will be well treated.

**The Administrator** (`administrator/welcome/`), usually **warm**:

*Warm:*
- `welcome_01.wav`: Welcome to the city, dear. I'm the Administrator. Do keep your papers with you, be kind to your neighbours, and you'll get on splendidly.
- `welcome_02.wav`: Hello and welcome! I'm so glad you're here. We all look after each other in this city. Do come to me if there's trouble.

## ambient

*Random city announcements, and what Dr. Breen's periodic addresses are made of.*

**Overwatch** (`overwatch/ambient/`):

- `ambient_01.wav`: Citizens, report any anti-social behaviour to your nearest unit.
- `ambient_02.wav`: Inaction is conspiracy. Report suspicious activity immediately.
- `ambient_03.wav`: Remember: cooperation is the foundation of stability.

**The Administrator** (`administrator/ambient/`), usually **warm**:

*Warm:*
- `ambient_01.wav`: Just a little reminder, everyone: be kind to your neighbours, and tell an officer if something troubles you.
- `ambient_02.wav`: Remember, a tidy home is a happy home. Keep your papers safe and your manners sharper.
- `ambient_03.wav`: A gentle word to anyone feeling low: there is always a place for you, as long as you stay on the right side of the rules.

*Firm:*
- `ambient_firm_01.wav`: Something I've noticed lately: people forgetting their manners. I do hope that's not catching.

*Stern:*
- `ambient_stern_01.wav`: Let me be perfectly clear. I am fond of you, but my patience is not endless. Behave.

## radio

Radios and the repair bench (`radio/static/`, `radio/union/`, `radio/freq7/`). Long files that loop cleanly work best: static between stations, an ordinary Union station, and the Resistance's pirate broadcast on Freq 7.

**freq7** (`radio/freq7/`), a tired, careful voice, a little too close to the mic:

- `freq7_01.wav`: This is Freq 7. They count the rations and they count you. Count them back.
- `freq7_02.wav`: The third shift at the station is short two units on Tuesdays. Freq 7, out.
- `freq7_03.wav`: If you can hear this, you are not alone. Freq 7.
- `freq7_04.wav`: The Administrator's broadcasts are recorded. She is not in the city.
- `freq7_05.wav`: Block 4: the inspection is tomorrow. Whatever you're keeping, keep it somewhere else.
- `freq7_06.wav`: Don't answer this. Just listen. And then turn it back to the Union band.

**static** and **union**: no script. Static is any long, loopable radio hiss; the Union band can be any long, loopable bland station (with none, the Administrator's ambient recordings play there).
