# What becomes of the Resistance's prisoners, and what the city makes of it

The owner, 12 November: the rebels "would likely imprison, interrogate, then either execute or let go", and executions should have consequences inside the Resistance, among the people, and from the Administrator. Settled then: how the people see the Resistance is "felt and overheard", never a number, a bar or a chat line; only the Resistance's leader has it in words, on their clipboard. Built 19 November ("let's build these now please"; `sv_livingcity_rebelanswer.lua`). The cage, the chair and executions with permission are in `docs/features/patdown-and-cuffs.md`.

**How the people see the Resistance.** One hidden figure for the city (-100 to 100, kept with the state of the city as `rebstanding`), one point back towards nothing every ten minutes.
- Down: a prisoner shot who had done nothing (-8), a unit shot (-3), a confessed informer shot (-1), an executed prisoner's body found (-3), the Resistance refusing her exchange (-3), her taking the high ground (-4).
- Up: the killer answered for (expelled +4, demoted +2, ordered shot +5), a prisoner let go with a warning (+1) or blindfolded (+2), an exchange (+2), the Combine refusing theirs (+1), a member of the Resistance shot by the firing squad (a martyr, +5), a rescue from the wall (+2), a citizen killed by a unit (+1).
- Felt: what citizens say about the Resistance when you talk to them (low: the loyal call it murder, the bitter call it justice; high: kinder words), the leader's clipboard (one sentence: "People are afraid of us, and a few are starting to talk to the units." up to "The people are with us."), how many new citizens turn informer (up to half as many again) and how many sympathize (fewer when low, more when high). A cell that has shot someone in the last half hour frightens informers into silence (the clipboard says so).

**Letting them go** (the cage's quick menu, for one of the city's own; a player held is let go as before):
- **With a warning:** the timid keep quiet; the loyal go straight to a unit and, if they live that long (40 seconds), the Combine learn where the cage is.
- **Blindfolded, walked out:** put down somewhere far off, out of rebel ground and out of sight; nobody learns the way back.
- **Turned: they feed the units lies:** likelier the less loyal they are. Turned, the next thing the Combine think they've learned is a lie; if not, they go to a unit after all. Whoever let them go isn't told which.

**Exchanges.** A Lieutenant or above, at the cage: "Offer them for <name>", one of ours in the Combine's cells (a player, or one of the city's own). It goes to the Administrator: her **F2 > City orders > The Resistance offer X for Y** (Accept or Refuse); with nobody playing her, the city's own decides in two and a half minutes. She can offer one the other way as her answer to a killing: the Resistance hear of it on Freq 7 and answer at the cage ("The Combine offer ..."), a Lieutenant or above; with none online, the cell decides by its mood (calm or wary: yes). Accepted: both walk free. Refusing her costs the Resistance with the people.

**The body.** One of the city's own shot at the cage or the chair leaves a body. Seen by a unit anywhere, or by a citizen outside rebel ground (within 700 units, nothing between), it is evidence: the Combine learn where it came from, the people hear, and the Administrator answers. While someone is hauling it nobody looks twice; hidden, or burned by the Cremator, nothing comes of it. An execution in front of citizens (not the Resistance's own) reaches the Combine within the minute the same way.

**The Administrator answers.** A killing the Combine know of is named over the PA (new trigger `rebel_killing`): "The Resistance murdered <name>. Love your neighbour, hate the traitor." Then she chooses: a player from **F2 > City orders > Answer the killing of <name>** (five minutes), or the city's own after a minute:
- **A reprisal:** a member of the Resistance in the cells to the firing squad (`docs/features/firing-squads.md`); needs the wall and someone to shoot.
- **A raid:** Civil Protection's "Retake the block" on rebel ground, the piece nearest to what they have learned; needs ground the Resistance took.
- **The high ground:** an amnesty, or extra rations if one was declared today (for the city's own: the same in the state of the city).
- **An exchange,** offered to the Resistance (above), when they hold someone and the Combine hold one of theirs.
The city's own picks a reprisal when it can and authority is 45 or more, else a raid, else (half the time) an exchange, else the high ground. One answer at a time, ten minutes apart at least.

**What follows her answer** (21 November; `LC.RebelAftermathFor`). A reprisal angers the cell and puts **Answer the reprisal** on the Resistance's board (F4) for a quarter of an hour: kill two Civil Protection units (45 XP; done, the anger is spent). A raid brings a **counter-raid**: the checkpoint sabotage job is posted (with no checkpoint on the map, Answer the reprisal instead), and the cell grows both warier and angrier. The high ground makes the cell **harder**: angrier, so the atmosphere turns vengeful sooner. An exchange sets nothing more going. Tests `Nov21_RebelAftermathTests`.

Setting: `lc_rebel_answer` (1). Tests: `Nov19_RebelAnswerTests`.
