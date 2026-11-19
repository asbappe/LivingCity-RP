# The armory, the quartermaster's buying and selling, and barter (19 November)

`sv_livingcity_armory.lua` (all of it), `cl_livingcity_barter.lua` (the barter view), the Barter button in the quartermaster's window (`cl_livingcity_needs.lua`), the lines that send his sales and purchases through it (`sv_livingcity_underground.lua`), the gun run's delivery (`sv_livingcity_quests.lua`), the armory as the issue's first source (`sv_livingcity_fundgear.lua`), the pocket guns (`sh_livingcity_shop.lua`). Tests: `Nov19_ArmoryBarterTests`, the client smoke test.

## A gun you carry already goes in your pockets

The owner: "as it stands now, I can kill a CP/Overwatch unit, but if I already have an SMG or pistol then I can't pick up the SMG/Pistol on the ground: let's make it so they are picked up and placed into the player's inventory".

- Touching a gun on the ground of a class you already hold (pistol, SMG, shotgun, revolver, pulse rifle) puts it in your pockets as that gun's item: **Pistol, SMG, Shotgun, Revolver** (the items the quartermaster has always sold) or **Pulse rifle** (new, `gun_ar2`). The rounds in it are added to yours (up to what you can carry), with the usual pickup sound. Nothing is said.
- As before when: the pockets are full (it stays on the ground); you don't hold that class (you pick it up as a gun); it is not one of those five; a unit touches it (units leave it); a dream, a cell, tied hands, the infested or a stalker (whatever already says no to a pickup still does); the gun is one the game is handing you that moment.
- A pocket gun is contraband, as it is for a citizen: searches and the pat-down find it. Drawing one (F3) works as before.
- How the answer is heard: the gamemode answers GMod's `PlayerCanPickupWeapon` with false once the gun is in the pockets, and nothing otherwise. Before it does, it asks every other answer to that hook itself and does nothing if any says no, so the result is the same whichever the game asks first.

## The armory

The owner: "can we just put the weapons collected directly into a resistance locker/armory? ... if sold to the quartermaster they go into the armory".

- A count of guns by class that belongs to the Resistance, kept with the fund in the ledger (`armory` in `data/livingcity/<map>_city.json`).
- **A gun sold to the quartermaster** (from the pockets or in hand, not one your side issued you) goes on its shelf, and **he pays 5 credits a gun out of the fund** (the owner: "they get like 5 credits from the resistance fund for each weapon"; `GUN_PAY`). A gun given to him (Donate) goes on it too.
- **The fighters' issue takes from it first** (`LC.FundIssue`): each gun of a rank's kit comes off the shelf at no cost when it holds one; the fund buys only what it lacks, and the rounds as before. A cheaper gun in place of one the fund couldn't buy can come off the shelf too (and counts as issued).
- The record (the screen in the camp): "-5  A pistol for the armory (Kerr)", "Guns for the armory (Kerr)", "A pistol from the armory, for a fighter (Kerr)", "A fighter armed from the armory (Kerr)", "A crate of guns, brought in".

## What the quartermaster pays, and what he is paid

The owner: "yes, quartermaster purchases should go into the fund"; "what if the fund is empty? Does the quartermaster just suddenly not have ability to pay people for things?"

- **Credits paid to him for anything go into the fund** ("+40  Sold at the quartermaster's (Kerr)").
- **Everything he buys is paid out of the fund:** guns 5; the gun run's crate 60 (what the job always paid; its guns, a pistol and an SMG, go in the armory); intel, skimmed machine parts, forged ration cards, ammunition, gun parts, scrap, rags, chemicals and the rest at what he paid before ("Bought at the quartermaster's (Kerr)"). Intel still gives its experience, forged cards still heat the search for the forger, a stranger still earns a little sympathy.
- He never pays as much for one as he or the Commissary sells it for (five hand-rolled cigarettes he sells for 6 are worth 1 each to him; paper from the Commissary at 2, 1): buying something and selling it to him can't make credits out of the fund.
- **When the fund can't pay, the sale doesn't fail:** his barter opens with the thing on your side. The gun run: the crate stays in your pockets and his barter opens with it, at 60; the job is done all the same.
- He says nothing in chat about any of it; his window shows your credits.

## Barter

The owner: "the quartermaster, if the resistance fund is empty, can offer to barter/trade things (similar to the Fallout 3, 4, New Vegas trading/bartering system) where items are traded based on their sale value if credits are lacking"; "a button below it all or wherever it fits that says 'Barter' and opens a bartering menu".

- **Barter**, a button under everything in his window, for anyone who can use the window (his own at his post; a stranger, who only gets the arms and the crate he'd buy, and nothing of his: he sells nothing to strangers).
- The view, **BARTER**: on the left **Yours** (what he'd buy from your pockets and guns in hand, at what he pays, each with how many you have, a count and - +), a **Credits** box (from your pocket), and the total ("12 credits"); on the right **His** (his stock at what he charges, a count and - +), a **Fund** row when yours is worth more (what the fund pays you, as far as it can), and the total. Under it all, the **Goodwill** bar and **Trade**. One line above them when a trade was refused ("You don't have that much.", "That's more than you can carry.").
- Credits you put in go into the fund (only what is needed); when yours is worth more, the fund pays you the difference as far as it can. A barter must give something of yours.
- Checked on the server, every time: who, how near him, that everything is really in your pockets or his stock, the totals worked out again from his prices, room in your pockets, the goodwill read and spent there, once a second at most.

## Goodwill

The owner: "there should be a system that takes into account your standing with the resistance and then the quartermaster can be convinced/haggled to be lenient for a few credits"; "a Lieutenant should get like a 10 credit leeway and a Commander like a 20 credit leeway ... the leeway/leniency needs to be it's own hidden value/fund that refills over time, at most once per day or two". On showing it: a thin bar labelled "Goodwill", "Goodwill: N credits" on hovering, a short trade's shortfall shaded on the bar's own scale.

- A hidden allowance each character has: **Commander 20, Lieutenant 10, Fighter 5, Member 3, Sympathizer 1**; anyone else 1 for every 2 sympathy, at most 3 (constants).
- A trade short of his side by no more than what is left of it goes through: he lets the difference go and it comes off the allowance ("Let 3 credits go (Kerr)" in the record, at no cost). Spent across all your barters; closing and opening the window gives nothing back; it never pays out credits.
- It fills again slowly, to full over 24 real hours, worked out from when it was last spent (PData `lc_goodwill`), so it is the same after a reconnect or a restart. Someone new (a new character) starts full.
- The bar: what is left against the full size; hovering shows "Goodwill: 7 credits"; a short trade's shortfall shaded on it (3 short takes 3 of the bar's 7); Trade greyed when the shortfall is more than the bar holds.

## Fencing

The owner: "the resistance member doing the deed/act/work gets a maybe 50% cut ... for selling/smuggling combine gear, etc."

- The five pocket guns carry the dealer's split flag (`resistanceSplit`) and a dealer price (pistol 45, SMG 75, shotgun 80, revolver 90 as before; pulse rifle 150, half the unit counter's 300). One of the Resistance selling one to the dealer keeps half and the fund has half (the dealer's own code); a citizen is paid in full.

## For other code

`LC.Armory()`, `LC.ArmoryCount(cls)`, `LC.ArmoryAdd(cls, n)`, `LC.ArmoryTake(cls, n)`; `LC.PocketGunItem(cls)`, `LC.PocketPickup(ply, wep)`; `LC.QuartermasterDealer(ply)`, `LC.QuartermasterBuyPrice(ply, id)`, `LC.QuartermasterBuy(ply, id, all)`, `LC.QuartermasterPaid(ply, n)`, `LC.QuartermasterGunRun(ply, item)`; `LC.GoodwillFull(ply)`, `LC.Goodwill(ply, now)`, `LC.GoodwillSpend(ply, n, now)`; `LC.BarterOffer(ply)`, `LC.BarterOpen(ply, pre, status)`, `LC.BarterTrade(ply, offer)`. Net: `lc_barter` (both ways). No new setting: the numbers are constants at the top of `sv_livingcity_armory.lua`.
