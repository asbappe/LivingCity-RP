# Informing to Civil Protection

Asked for by the owner, 17 November ("When an assassination attempt ends with the assassin neither arrested nor killed, citizens can inform on them ... Build it so more kinds of informing plug into the same Inform list ... the owner wants citizens able to live off informing alone"). Settled 19 November: only someone who saw the assassin "within the last 15 minutes (but the sighting has to be AFTER the assassination attempt)"; failing costs "-10 standing, 10 min wait". Built 19 November (`sv_livingcity_inform.lua`, `cl_livingcity_inform.lua`).

**Who.** A citizen, alive and free (not a unit, the Resistance, the Administrator, a vortigaunt or anyone else). **The assassin who got away** is a player marked for an attempt on the Administrator's life (`lc_regicide`, `docs/features/city.md`), alive, not in the cells and not held by the Combine.

**Seeing them.** Every two seconds: within 2000 units, in front of the citizen, nothing solid between their eyes. A sighting counts for 15 minutes, and only if it came after the attempt. Nothing on screen ever points to the assassin.

**Where.** E on a Civil Protection unit (one of the city's or a player), or **F1 > Inform** while looking at one. Both only appear with something to report. A quick menu (number keys) lists what you can report, each with its reward: today only "I know where the assassin is (250 credits, 250 standing)". While you hold another job it is greyed: "(finish your job first)". Pressing E on a unit to report no longer counts as pestering him.

**The lead.** A job of its own, **"Lead Civil Protection to the traitor"**, five minutes on the job tracker's clock. The unit radios it in (heard on the Civil Protection net; a unit player learns who to follow that way) and follows you; 20 to 40 seconds in, **two Overwatch soldiers** join (ones within 1500 units first, else brought in out of sight). Done when one of them is within **800 units (50 feet) of the assassin, walking**: along the drawn paths or the map's nodes, not a straight line (no way through at all is never near).

**Afterwards.** Done: **250 credits and 250 Civil Standing**, exactly (the usual pay for a finished job is skipped), the units go for the assassin, and the chronicle has it. Out of time, or given up: **-10 standing**, and no new report of it for **10 minutes**. The assassin caught by someone else, gone from the server or no longer free, or the informer dead: the job is simply gone, nothing against anyone.

**The poster.** While an assassin is free, every other plain curfew notice (one not hung by hand) reads "REPORT THE TRAITOR ASSASSIN TO A CIVIL PROTECTION UNIT TODAY!", with "Reward: 250 credits and 250 Civil Standing." (painted over by the Resistance: HERO). They go back to curfew notices when nobody is free.

**More kinds later.** `LC.InformKindAdd({ id, order, label, available(ply), start(ply, unit, what) })` adds a line to the same list (and a poster for it can follow). The older "Inform on them" in the talk window (`docs/features/city-people.md`) is unchanged.

Setting: `lc_inform` (1). Tests: `Nov19_InformTests`.
